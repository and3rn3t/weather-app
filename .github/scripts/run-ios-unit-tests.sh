#!/usr/bin/env bash
# Run the iOS unit tests with a start-up watchdog.
#
# On a freshly booted simulator the test host intermittently never connects to testmanagerd
# ("The test runner hung before establishing connection"). When it does connect, tests start
# within seconds; when it hangs, xcodebuild only recovers after several minutes (4-6 on a
# hosted runner, and once 19+). So watch for the first test and, if none starts within
# START_TIMEOUT seconds, kill xcodebuild and try again. Phase timings are printed.
#
# Usage: run-ios-unit-tests.sh "<device name>" [extra xcodebuild arguments...]
# Env:   START_TIMEOUT (default 90)  MAX_ATTEMPTS (default 4)  RESET_MODE (light|full)  PRIME (0|1, default 0)
#        PROJECT (default weather.xcodeproj)  SCHEME (default weather)
#        TEST_PLAN (default UnitTests)  RESULT_BUNDLE (default TestResults.xcresult)
set -uo pipefail

DEVICE="${1:?device name required}"
shift
EXTRA_ARGS=("$@")

START_TIMEOUT="${START_TIMEOUT:-90}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-4}"
RESET_MODE="${RESET_MODE:-light}"
PRIME="${PRIME:-0}"
PROJECT="${PROJECT:-weather.xcodeproj}"
SCHEME="${SCHEME:-weather}"
TEST_PLAN="${TEST_PLAN:-UnitTests}"
RESULT_BUNDLE="${RESULT_BUNDLE:-TestResults.xcresult}"

# xcodebuild reports these when SpringBoard refuses the test host ("Busy ... failed preflight
# checks") or the host never connects. Such an early exit is retried like a timeout.
LAUNCH_FAILURE="Failed to launch app|failed to launch|preflight checks|never began executing|Early unexpected exit"

# A started test run prints one of these (XCTest suite header, or Swift Testing's run header).
START_MARKER="Test Suite 'Selected tests' started|Test run started|Test Case '.*' started"

# Several devices can share a name (one per installed iOS runtime): use the newest runtime,
# the one the app was built against.
UDID=$(xcrun simctl list devices available -j | jq -r --arg n "$DEVICE" '
  [.devices | to_entries[]
   | select(.key | test("SimRuntime\\.iOS-"))
   | {v: (.key | capture("iOS-(?<v>[0-9-]+)").v | split("-") | map(tonumber)), d: .value}
   | .d[] as $dev | select($dev.name == $n) | {v: .v, udid: $dev.udid}]
  | sort_by(.v) | last | .udid // empty')
if [ -z "$UDID" ]; then
  echo "::error::No available simulator named '$DEVICE'"
  exit 1
fi

if command -v xcbeautify >/dev/null 2>&1; then
  FORMATTER=(xcbeautify --renderer github-actions)
else
  FORMATTER=(cat)
fi

now() { date +%s; }
phase() { echo "[$(date -u +%H:%M:%S)] $*"; }

ensure_booted() {
  xcrun simctl boot "$UDID" >/dev/null 2>&1 || true # already booted is fine
  xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
}

reset_simulator() {
  xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
  ensure_booted
}

# Between attempts: "light" only stops the stuck test host (a simulator reboot costs ~100 s on a
# hosted runner); "full" reboots the simulator.
recover() {
  pkill -f "xcodebuild test-without-building" || true
  if [ "$RESET_MODE" = "full" ]; then
    reset_simulator
  else
    [ -n "$HOST_ID" ] && xcrun simctl terminate "$UDID" "$HOST_ID" >/dev/null 2>&1 || true
    sleep 2
  fi
}

# bootstatus -b waits until SpringBoard is ready; without it the test host can be refused
# with "Busy (Application failed preflight checks)".
device_state() {
  xcrun simctl list devices -j | jq -r --arg u "$UDID" '[.devices[][] | select(.udid==$u)][0].state // "unknown"'
}

state=$(device_state)
phase "Simulator $UDID state: $state"
t_boot=$(now)
if [ "$state" != "Booted" ]; then
  ensure_booted
fi
phase "Simulator ready after $(( $(now) - t_boot ))s"

# Optional (PRIME=1): launch the app once before the first attempt. On a developer Mac this made
# the real launch connect in ~4 s (4/4 cold trials), but on a hosted runner the install + first
# launch alone took 437 s, so it only moved the cost and is off by default.
HOST_APP="${HOST_APP:-$(find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 6 -type d \
  -path '*Build/Products/Debug-iphonesimulator/weather.app' -print0 2>/dev/null | xargs -0 ls -dt 2>/dev/null | head -1)}"
HOST_ID=""
if [ -n "$HOST_APP" ] && [ -f "$HOST_APP/Info.plist" ]; then
  HOST_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$HOST_APP/Info.plist" 2>/dev/null || true)
fi

if [ "$PRIME" = "1" ] && [ -n "$HOST_ID" ]; then
  t_prime=$(now)
  xcrun simctl install "$UDID" "$HOST_APP" >/dev/null 2>&1 || true
  xcrun simctl launch "$UDID" "$HOST_ID" >/dev/null 2>&1 || true
  sleep 3
  xcrun simctl terminate "$UDID" "$HOST_ID" >/dev/null 2>&1 || true
  phase "Primed test host $HOST_ID in $(( $(now) - t_prime ))s"
fi

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
summary="${GITHUB_STEP_SUMMARY:-/dev/null}"

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  : >"$LOG"
  rm -rf "$RESULT_BUNDLE"

  (
    set -o pipefail
    xcodebuild test-without-building \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -testPlan "$TEST_PLAN" \
      -destination "id=$UDID" \
      -resultBundlePath "$RESULT_BUNDLE" \
      ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"} 2>&1 |
      tee "$LOG" |
      "${FORMATTER[@]}"
  ) &
  runner=$!

  started=false
  t_launch=$(now)
  phase "xcodebuild launched (attempt ${attempt}/${MAX_ATTEMPTS})"
  while [ $(( $(now) - t_launch )) -lt "$START_TIMEOUT" ]; do
    if grep -Eq "$START_MARKER" "$LOG"; then
      started=true
      break
    fi
    kill -0 "$runner" 2>/dev/null || break # xcodebuild already exited
    sleep 2
  done
  waited=$(( $(now) - t_launch ))

  # It may have exited before any test started. A launch failure is retried; anything else
  # (build error, bad arguments) is a real failure and stands.
  if ! $started && ! kill -0 "$runner" 2>/dev/null; then
    wait "$runner"
    code=$?
    if [ "$code" -ne 0 ] && grep -Eq "$LAUNCH_FAILURE" "$LOG" && [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
      echo "::warning::Test host failed to launch (attempt ${attempt}/${MAX_ATTEMPTS}); retrying (${RESET_MODE} reset)"
      echo "- Attempt ${attempt}/${MAX_ATTEMPTS}: test host failed to launch, retried" >>"$summary"
      recover
      continue
    fi
    echo "::group::Raw xcodebuild output (tail)"
    tail -n 60 "$LOG"
    echo "::endgroup::"
    exit "$code"
  fi

  if $started; then
    phase "Tests started ${waited}s after xcodebuild launched (attempt ${attempt}/${MAX_ATTEMPTS})"
    echo "- Tests started ${waited}s after xcodebuild launched (attempt ${attempt}/${MAX_ATTEMPTS})" >>"$summary"
    wait "$runner"
    exit $?
  fi

  echo "::warning::No test started within ${START_TIMEOUT}s (attempt ${attempt}/${MAX_ATTEMPTS}); retrying (${RESET_MODE} reset)"
  echo "- Attempt ${attempt}/${MAX_ATTEMPTS}: no test started within ${START_TIMEOUT}s, retried" >>"$summary"
  recover
  wait "$runner" 2>/dev/null || true
done

echo "::error::Test host never started after ${MAX_ATTEMPTS} attempts"
exit 1
