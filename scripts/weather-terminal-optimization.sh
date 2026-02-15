#!/bin/bash

# Weather App Terminal Optimizations
# Advanced terminal integration for better development experience

# Terminal detection and optimization
weather_optimize_terminal() {
    # Detect terminal type
    local term_program="${TERM_PROGRAM:-}"
    local term_type="${TERM:-}"
    
    # Color support detection
    if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && tput setaf 1 >/dev/null 2>&1; then
        export WEATHER_COLORS_ENABLED=true
    else
        export WEATHER_COLORS_ENABLED=false
    fi
    
    # Set weather-specific color scheme
    if [[ "$WEATHER_COLORS_ENABLED" == "true" ]]; then
        export WEATHER_APP_RED='\033[0;31m'
        export WEATHER_APP_GREEN='\033[0;32m'
        export WEATHER_APP_YELLOW='\033[1;33m'
        export WEATHER_APP_BLUE='\033[0;34m'
        export WEATHER_APP_PURPLE='\033[0;35m'
        export WEATHER_APP_CYAN='\033[0;36m'
        export WEATHER_APP_WHITE='\033[1;37m'
        export WEATHER_APP_BOLD='\033[1m'
        export WEATHER_APP_DIM='\033[2m'
        export WEATHER_APP_NC='\033[0m' # No Color
        
        # Weather-themed emoji indicators
        export WEATHER_EMOJI_SUCCESS="☀️"
        export WEATHER_EMOJI_WARNING="🌤️"
        export WEATHER_EMOJI_ERROR="⛈️"
        export WEATHER_EMOJI_INFO="🌈"
        export WEATHER_EMOJI_BUILD="🔨"
        export WEATHER_EMOJI_TEST="🧪"
        export WEATHER_EMOJI_DEPLOY="🚀"
    else
        # Fallback to plain text
        export WEATHER_APP_RED=''
        export WEATHER_APP_GREEN=''
        export WEATHER_APP_YELLOW=''
        export WEATHER_APP_BLUE=''
        export WEATHER_APP_PURPLE=''
        export WEATHER_APP_CYAN=''
        export WEATHER_APP_WHITE=''
        export WEATHER_APP_BOLD=''
        export WEATHER_APP_DIM=''
        export WEATHER_APP_NC=''
        
        export WEATHER_EMOJI_SUCCESS="[OK]"
        export WEATHER_EMOJI_WARNING="[WARN]"
        export WEATHER_EMOJI_ERROR="[ERROR]"
        export WEATHER_EMOJI_INFO="[INFO]"
        export WEATHER_EMOJI_BUILD="[BUILD]"
        export WEATHER_EMOJI_TEST="[TEST]"
        export WEATHER_EMOJI_DEPLOY="[DEPLOY]"
    fi
    
    # Terminal-specific optimizations
    case "$term_program" in
        "iTerm.app")
            weather_optimize_iterm
            ;;
        "Terminal.app"|"Apple_Terminal")
            weather_optimize_terminal_app
            ;;
        "Hyper")
            weather_optimize_hyper
            ;;
        *)
            weather_optimize_generic
            ;;
    esac
}

# iTerm2-specific optimizations
weather_optimize_iterm() {
    # Enable iTerm2 shell integration if available
    if [[ -f "${HOME}/.iterm2_shell_integration.${SHELL##*/}" ]]; then
        source "${HOME}/.iterm2_shell_integration.${SHELL##*/}"
    fi
    
    # iTerm2 badge support for weather app status
    weather_set_iterm_badge() {
        local badge_text="${1:-Weather}"
        printf "\e]1337;SetBadgeFormat=%s\a" "$(echo -n "$badge_text" | base64)"
    }
    
    # Set badge when in weather project
    if weather_project_root >/dev/null 2>&1; then
        local branch=""
        if git rev-parse --git-dir > /dev/null 2>&1; then
            branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
            weather_set_iterm_badge "☀️ $branch"
        fi
    fi
    
    # iTerm2 tab title optimization
    weather_set_iterm_title() {
        local title="Weather App"
        if weather_project_root >/dev/null 2>&1; then
            title="☀️ Weather App"
        fi
        printf "\e]1;%s\a" "$title"
    }
    
    weather_set_iterm_title
}

# macOS Terminal.app optimizations
weather_optimize_terminal_app() {
    # Set window title
    weather_set_terminal_title() {
        local title="Weather App Development"
        printf "\e]2;%s\a" "$title"
    }
    
    weather_set_terminal_title
}

# Hyper terminal optimizations
weather_optimize_hyper() {
    # Hyper-specific settings
    weather_set_hyper_title() {
        local title="☀️ Weather App"
        printf "\e]2;%s\a" "$title"
    }
    
    weather_set_hyper_title
}

# Generic terminal optimizations
weather_optimize_generic() {
    # Basic terminal title setting
    if [[ "$TERM" =~ screen|tmux ]]; then
        # Screen/tmux environment
        printf "\ek%s\e\\" "Weather"
    else
        printf "\e]2;%s\a" "Weather App"
    fi
}

# Enhanced output functions with spinner support
weather_spinner() {
    local pid=$1
    local message="${2:-Processing...}"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    # Hide cursor
    tput civis 2>/dev/null || true
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r${WEATHER_APP_CYAN}${spin:$i:1} %s${WEATHER_APP_NC}" "$message"
        sleep 0.1
    done
    
    # Show cursor
    tput cnorm 2>/dev/null || true
    printf "\r"
}

# Progress bar function
weather_progress_bar() {
    local current=$1
    local total=$2
    local message="${3:-Progress}"
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${WEATHER_APP_CYAN}%s [" "$message"
    printf "%*s" $filled | tr ' ' '▉'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%%${WEATHER_APP_NC}" $percentage
    
    if [[ $current -eq $total ]]; then
        printf "\n"
    fi
}

# Better command logging with timestamps
weather_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%H:%M:%S')
    
    case "$level" in
        "INFO"|"info")
            echo -e "${WEATHER_APP_DIM}[$timestamp]${WEATHER_APP_NC} ${WEATHER_APP_CYAN}${WEATHER_EMOJI_INFO}${WEATHER_APP_NC} $message"
            ;;
        "SUCCESS"|"success")
            echo -e "${WEATHER_APP_DIM}[$timestamp]${WEATHER_APP_NC} ${WEATHER_APP_GREEN}${WEATHER_EMOJI_SUCCESS}${WEATHER_APP_NC} $message"
            ;;
        "WARNING"|"warning"|"warn")
            echo -e "${WEATHER_APP_DIM}[$timestamp]${WEATHER_APP_NC} ${WEATHER_APP_YELLOW}${WEATHER_EMOJI_WARNING}${WEATHER_APP_NC} $message"
            ;;
        "ERROR"|"error")
            echo -e "${WEATHER_APP_DIM}[$timestamp]${WEATHER_APP_NC} ${WEATHER_APP_RED}${WEATHER_EMOJI_ERROR}${WEATHER_APP_NC} $message"
            ;;
        "BUILD"|"build")
            echo -e "${WEATHER_APP_DIM}[$timestamp]${WEATHER_APP_NC} ${WEATHER_APP_BLUE}${WEATHER_EMOJI_BUILD}${WEATHER_APP_NC} $message"
            ;;
        "TEST"|"test")
            echo -e "${WEATHER_APP_DIM}[$timestamp]${WEATHER_APP_NC} ${WEATHER_APP_PURPLE}${WEATHER_EMOJI_TEST}${WEATHER_APP_NC} $message"
            ;;
        *)
            echo -e "${WEATHER_APP_DIM}[$timestamp]${WEATHER_APP_NC} $level $message"
            ;;
    esac
}

# Command execution with better output formatting
weather_exec() {
    local command="$1"
    local description="${2:-Executing command}"
    
    weather_log "info" "$description"
    
    if [[ "$WEATHER_VERBOSE" == "true" ]]; then
        weather_log "info" "Command: $command"
    fi
    
    # Execute command and capture output
    local start_time
    start_time=$(date +%s)
    
    if eval "$command"; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        weather_log "success" "Completed in ${duration}s"
        return 0
    else
        local exit_code=$?
        weather_log "error" "Command failed with exit code $exit_code"
        return $exit_code
    fi
}

# Terminal notification support
weather_notify() {
    local title="${1:-Weather App}"
    local message="${2:-Task completed}"
    local type="${3:-info}"
    
    # Terminal bell
    if [[ "$WEATHER_BELL_ENABLED" != "false" ]]; then
        printf "\a"
    fi
    
    # System notification
    if command -v osascript >/dev/null 2>&1; then
        # macOS notification
        osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true
    elif command -v notify-send >/dev/null 2>&1; then
        # Linux notification
        notify-send "$title" "$message" 2>/dev/null || true
    fi
    
    # Terminal title flash
    if [[ "$type" == "success" ]]; then
        printf "\e]2;✅ %s\a" "$title"
        sleep 1
        printf "\e]2;%s\a" "$title"
    elif [[ "$type" == "error" ]]; then
        printf "\e]2;❌ %s\a" "$title"
        sleep 1
        printf "\e]2;%s\a" "$title"
    fi
}

# Smart pager for weather commands
weather_pager() {
    local content="$1"
    local lines
    lines=$(echo "$content" | wc -l)
    local term_height
    term_height=$(tput lines 2>/dev/null || echo "24")
    
    if [[ $lines -gt $((term_height - 5)) ]]; then
        if command -v bat >/dev/null 2>&1; then
            echo "$content" | bat --paging=auto --style=plain
        elif command -v less >/dev/null 2>&1; then
            echo "$content" | less -RF
        else
            echo "$content" | more
        fi
    else
        echo "$content"
    fi
}

# Terminal multiplexer integration
weather_tmux_integration() {
    if [[ -n "$TMUX" ]]; then
        # Set tmux window name
        tmux rename-window "Weather" 2>/dev/null || true
        
        # Set tmux status bar info
        if weather_project_root >/dev/null 2>&1; then
            local branch=""
            if git rev-parse --git-dir > /dev/null 2>&1; then
                branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
                tmux set-option -g status-right "☀️ $branch #[default]" 2>/dev/null || true
            fi
        fi
    fi
}

# Screen integration
weather_screen_integration() {
    if [[ -n "$STY" ]]; then
        # Set screen title
        printf "\ek%s\e\\" "Weather"
    fi
}

# Directory-based terminal customization
weather_terminal_context() {
    local project_root
    project_root=$(weather_project_root 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        # In weather project - apply context
        case "${PWD#$project_root}" in
            */Sources/*|*/weather/Sources/*)
                export WEATHER_CONTEXT="source"
                ;;
            */Tests/*|*/weatherTests/*)
                export WEATHER_CONTEXT="test"
                ;;
            */docs/*)
                export WEATHER_CONTEXT="docs"
                ;;
            */scripts/*)
                export WEATHER_CONTEXT="scripts"
                ;;
            *)
                export WEATHER_CONTEXT="root"
                ;;
        esac
    else
        unset WEATHER_CONTEXT
    fi
}

# Enhanced prompt integration
weather_prompt_command() {
    # Update terminal context
    weather_terminal_context
    
    # Update multiplexer integration
    weather_tmux_integration
    weather_screen_integration
}

# Initialize terminal optimizations
weather_init_terminal() {
    # Basic optimization
    weather_optimize_terminal
    
    # Add prompt command if not already added
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        # Zsh hook
        if ! [[ "${precmd_functions[*]}" =~ weather_prompt_command ]]; then
            precmd_functions+=(weather_prompt_command)
        fi
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        # Bash prompt command
        if [[ "$PROMPT_COMMAND" != *"weather_prompt_command"* ]]; then
            if [[ -z "$PROMPT_COMMAND" ]]; then
                PROMPT_COMMAND="weather_prompt_command"
            else
                PROMPT_COMMAND="$PROMPT_COMMAND; weather_prompt_command"
            fi
        fi
    fi
    
    # Set initial context
    weather_prompt_command
}

# Auto-initialize if we're in a weather project
if weather_project_root >/dev/null 2>&1; then
    weather_init_terminal
fi

# Export useful variables
export WEATHER_TERMINAL_OPTIMIZED=true
export WEATHER_VERBOSE=${WEATHER_VERBOSE:-false}
export WEATHER_BELL_ENABLED=${WEATHER_BELL_ENABLED:-true}