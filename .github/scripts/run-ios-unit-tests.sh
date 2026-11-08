#!/usr/bin/env bash
# Run the iOS unit tests with a start-up watchdog.
#
# On hosted macOS runners the test host app sometimes never connects to
# testmanagerd: xcodebuild then waits minutes (and once more than 19) before any test
# runs, although the 200+ tests take ~2 minutes. If no test has started within
# START_TIMEOUT seconds, kill xcodebuild, reset the simulator and try again.
#
# Usage: run-ios-unit-tests.sh "<device name>" [extra xcodebuild arguments...]
# Env:   START_TIMEOUT (default 120)  MAX_ATTEMPTS (default 3)
#        PROJECT (default weather.xcodeproj)  SCHEME (default weather)
#        TEST_PLAN (default UnitTests)  RESULT_BUNDLE (default TestResults.xcresult)
set -uo pipefail

DEVICE="${1:?device name required}"
shift
EXTRA_ARGS=("$@")

START_TIMEOUT="${START_TIMEOUT:-120}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-3}"
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

ensure_booted() {
  xcrun simctl boot "$UDID" >/dev/null 2>&1 || true # already booted is fine
  xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
}

reset_simulator() {
  xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
  ensure_booted
}

# bootstatus -b waits until SpringBoard is ready; without it the test host can be refused
# with "Busy (Application failed preflight checks)".
ensure_booted

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
  for ((waited = 0; waited < START_TIMEOUT; waited += 2)); do
    if grep -Eq "$START_MARKER" "$LOG"; then
      started=true
      break
    fi
    kill -0 "$runner" 2>/dev/null || break # xcodebuild already exited
    sleep 2
  done

  # It may have exited before any test started. A launch failure is retried; anything else
  # (build error, bad arguments) is a real failure and stands.
  if ! $started && ! kill -0 "$runner" 2>/dev/null; then
    wait "$runner"
    code=$?
    if [ "$code" -ne 0 ] && grep -Eq "$LAUNCH_FAILURE" "$LOG" && [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
      echo "::warning::Test host failed to launch (attempt ${attempt}/${MAX_ATTEMPTS}); resetting the simulator"
      echo "- Attempt ${attempt}/${MAX_ATTEMPTS}: test host failed to launch, retried" >>"$summary"
      reset_simulator
      continue
    fi
    echo "::group::Raw xcodebuild output (tail)"
    tail -n 60 "$LOG"
    echo "::endgroup::"
    exit "$code"
  fi

  if $started; then
    echo "Tests started after ~${waited}s (attempt ${attempt}/${MAX_ATTEMPTS})"
    echo "- Tests started after ~${waited}s (attempt ${attempt}/${MAX_ATTEMPTS})" >>"$summary"
    wait "$runner"
    exit $?
  fi

  echo "::warning::No test started within ${START_TIMEOUT}s (attempt ${attempt}/${MAX_ATTEMPTS}); resetting the simulator"
  echo "- Attempt ${attempt}/${MAX_ATTEMPTS}: no test started within ${START_TIMEOUT}s, retried" >>"$summary"
  pkill -f "xcodebuild test-without-building" || true
  wait "$runner" 2>/dev/null || true
  reset_simulator
done

echo "::error::Test host never started after ${MAX_ATTEMPTS} attempts"
exit 1
