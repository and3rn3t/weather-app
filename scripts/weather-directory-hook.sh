#!/bin/bash

# Weather App Directory Hook
# Automatically configures shell when entering/leaving project directory

# Directory hook for zsh users
if [[ -n "${ZSH_VERSION:-}" ]]; then
    # Array to track previous directory state
    typeset -g WEATHER_PROJECT_LOADED=""
    
    # Function to check if we're in weather project
    _weather_check_project() {
        local dir="$PWD"
        while [[ "$dir" != "/" ]]; do
            if [[ -f "$dir/weather.xcodeproj/project.pbxproj" ]] || [[ -f "$dir/weather/weather.xcodeproj/project.pbxproj" ]]; then
                echo "$dir"
                return 0
            fi
            dir=$(dirname "$dir")
        done
        return 1
    }
    
    # Hook function that runs on directory change
    _weather_chpwd_hook() {
        local project_root
        project_root=$(_weather_check_project 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            # We're in the weather project
            if [[ "$WEATHER_PROJECT_LOADED" != "$project_root" ]]; then
                # Just entered the project
                WEATHER_PROJECT_LOADED="$project_root"
                
                # Load weather shell integration if not already loaded
                if ! command -v wbuild >/dev/null 2>&1; then
                    local integration_script=""
                    [[ -f "$project_root/weather/scripts/weather-shell-integration.sh" ]] && integration_script="$project_root/weather/scripts/weather-shell-integration.sh"
                    [[ -f "$project_root/scripts/weather-shell-integration.sh" ]] && integration_script="$project_root/scripts/weather-shell-integration.sh"
                    
                    if [[ -n "$integration_script" ]]; then
                        source "$integration_script"
                    fi
                fi
                
                # Load completions if not already loaded
                local completions_script=""
                [[ -f "$project_root/weather/scripts/weather-zsh-completions.zsh" ]] && completions_script="$project_root/weather/scripts/weather-zsh-completions.zsh"
                [[ -f "$project_root/scripts/weather-zsh-completions.zsh" ]] && completions_script="$project_root/scripts/weather-zsh-completions.zsh"
                
                if [[ -n "$completions_script" ]]; then
                    source "$completions_script"
                fi
                
                # Show project welcome message
                echo ""
                if command -v wstatus >/dev/null 2>&1; then
                    wstatus
                else
                    echo "🌤️ Entered Weather App project directory"
                    echo "📁 Project root: $project_root"
                fi
                echo ""
            fi
        else
            # We're not in the weather project anymore
            if [[ -n "$WEATHER_PROJECT_LOADED" ]]; then
                WEATHER_PROJECT_LOADED=""
                echo "👋 Left Weather App project directory"
            fi
        fi
    }
    
    # Register the hook
    add-zsh-hook chpwd _weather_chpwd_hook
    
    # Run the hook for the current directory
    _weather_chpwd_hook

elif [[ -n "${BASH_VERSION:-}" ]]; then
    # Bash doesn't have built-in directory change hooks, but we can simulate it
    # with PROMPT_COMMAND
    
    WEATHER_PROJECT_LOADED=""
    WEATHER_LAST_PWD=""
    
    _weather_bash_hook() {
        # Only run if directory changed
        if [[ "$PWD" != "$WEATHER_LAST_PWD" ]]; then
            WEATHER_LAST_PWD="$PWD"
            
            local dir="$PWD"
            local project_root=""
            while [[ "$dir" != "/" ]]; do
                if [[ -f "$dir/weather.xcodeproj/project.pbxproj" ]] || [[ -f "$dir/weather/weather.xcodeproj/project.pbxproj" ]]; then
                    project_root="$dir"
                    break
                fi
                dir=$(dirname "$dir")
            done
            
            if [[ -n "$project_root" ]]; then
                # We're in the weather project
                if [[ "$WEATHER_PROJECT_LOADED" != "$project_root" ]]; then
                    # Just entered the project
                    WEATHER_PROJECT_LOADED="$project_root"
                    
                    # Load weather shell integration if not already loaded
                    if ! command -v wbuild >/dev/null 2>&1; then
                        local integration_script=""
                        [[ -f "$project_root/weather/scripts/weather-shell-integration.sh" ]] && integration_script="$project_root/weather/scripts/weather-shell-integration.sh"
                        [[ -f "$project_root/scripts/weather-shell-integration.sh" ]] && integration_script="$project_root/scripts/weather-shell-integration.sh"
                        
                        if [[ -n "$integration_script" ]]; then
                            source "$integration_script"
                        fi
                    fi
                    
                    # Show project welcome message
                    echo ""
                    if command -v wstatus >/dev/null 2>&1; then
                        wstatus
                    else
                        echo "🌤️ Entered Weather App project directory"
                        echo "📁 Project root: $project_root"
                    fi
                    echo ""
                fi
            else
                # We're not in the weather project anymore
                if [[ -n "$WEATHER_PROJECT_LOADED" ]]; then
                    WEATHER_PROJECT_LOADED=""
                    echo "👋 Left Weather App project directory"
                fi
            fi
        fi
    }
    
    # Add to PROMPT_COMMAND
    if [[ -z "$PROMPT_COMMAND" ]]; then
        PROMPT_COMMAND="_weather_bash_hook"
    else
        PROMPT_COMMAND="$PROMPT_COMMAND; _weather_bash_hook"
    fi
    
    # Run for current directory
    _weather_bash_hook
fi

# Universal function to manually load weather integration
weather_load() {
    local dir="$PWD"
    local project_root=""
    
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/weather.xcodeproj/project.pbxproj" ]] || [[ -f "$dir/weather/weather.xcodeproj/project.pbxproj" ]]; then
            project_root="$dir"
            break
        fi
        dir=$(dirname "$dir")
    done
    
    if [[ -n "$project_root" ]]; then
        local integration_script=""
        [[ -f "$project_root/weather/scripts/weather-shell-integration.sh" ]] && integration_script="$project_root/weather/scripts/weather-shell-integration.sh"
        [[ -f "$project_root/scripts/weather-shell-integration.sh" ]] && integration_script="$project_root/scripts/weather-shell-integration.sh"
        
        if [[ -n "$integration_script" ]]; then
            source "$integration_script"
            echo "🌤️ Weather App integration loaded manually"
        else
            echo "❌ Weather integration script not found"
        fi
        
        # Load completions for zsh
        if [[ -n "${ZSH_VERSION:-}" ]]; then
            local completions_script=""
            [[ -f "$project_root/weather/scripts/weather-zsh-completions.zsh" ]] && completions_script="$project_root/weather/scripts/weather-zsh-completions.zsh"
            [[ -f "$project_root/scripts/weather-zsh-completions.zsh" ]] && completions_script="$project_root/scripts/weather-zsh-completions.zsh"
            
            if [[ -n "$completions_script" ]]; then
                source "$completions_script"
                echo "🎯 Zsh completions loaded"
            fi
        fi
    else
        echo "❌ Not in Weather App project directory"
        return 1
    fi
}

# Universal function to unload weather integration (cleanup)
weather_unload() {
    # Remove functions
    unset -f wbuild wtest wlint wsim wdev wstatus wclean warchive wcd wrelease whelp 2>/dev/null
    
    # Remove aliases
    unalias wcode wedit wgit wfastlane 2>/dev/null
    
    # Clean up variables
    unset WEATHER_PROJECT_LOADED WEATHER_LAST_PWD 2>/dev/null
    
    echo "👋 Weather App integration unloaded"
}