# Weather App - Zsh Completions
# Advanced tab completion for all weather app commands

# Enable completion system
autoload -U compinit
compinit

# Weather App make targets completion
_weather_make_targets() {
    local context state state_descr line
    local -a targets
    
    # Find project root and makefile
    local project_root=""
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/weather.xcodeproj/project.pbxproj" ]] || [[ -f "$dir/weather/weather.xcodeproj/project.pbxproj" ]]; then
            project_root="$dir"
            break
        fi
        dir=$(dirname "$dir")
    done
    
    if [[ -n "$project_root" ]]; then
        local makefile="$project_root/Makefile"
        [[ -f "$project_root/weather/Makefile" ]] && makefile="$project_root/weather/Makefile"
        
        if [[ -f "$makefile" ]]; then
            targets=(${(f)"$(grep "^[a-zA-Z][a-zA-Z0-9_-]*:" "$makefile" | cut -d':' -f1 | sort -u)"})
            _describe 'make targets' targets
        fi
    fi
}

# Register make completion
compdef _weather_make_targets make

# Weather shell function completions
_wtest_completion() {
    local -a test_types
    test_types=(
        'unit:Run unit tests (default)'
        'coverage:Run tests with code coverage'
        'performance:Run performance tests'
        'all:Run all test types'
        'u:Unit tests (short)'
        'cov:Coverage (short)'
        'c:Coverage (short)'
        'perf:Performance (short)'
        'p:Performance (short)'
        'a:All tests (short)'
    )
    _describe 'test types' test_types
}

_wlint_completion() {
    local -a lint_actions
    lint_actions=(
        'check:Check code style (default)'
        'fix:Auto-fix style issues'
        'format:Format code'
        'c:Check (short)'
        'f:Fix (short)'
        'fmt:Format (short)'
    )
    _describe 'lint actions' lint_actions
}

_wdev_completion() {
    local -a dev_actions
    dev_actions=(
        'start:Clean, build, and launch simulator'
        'status:Show project status'
        'clean:Clean build artifacts'
        'reset:Full environment reset'
        'deps:Check dependencies'
        's:Start (short)'
        'st:Status (short)'
        'c:Clean (short)'
        'r:Reset (short)'
        'd:Dependencies (short)'
    )
    _describe 'dev actions' dev_actions
}

_wcd_completion() {
    local -a directories
    directories=(
        'root:Project root directory'
        'sources:Source code directory'
        'tests:Test files directory'
        'docs:Documentation directory'
        'scripts:Scripts directory'
        'build:Build output directory'
        'r:Root (short)'
        'src:Sources (short)'
        's:Sources (short)'
        'test:Tests (short)'
        't:Tests (short)'
        'doc:Docs (short)'
        'd:Docs (short)'
        'sc:Scripts (short)'
        'b:Build (short)'
    )
    _describe 'project directories' directories
}

_wrelease_completion() {
    local -a release_actions
    case $words[2] in
        prepare|prep|p)
            local -a release_types
            release_types=(
                'patch:Patch version increment'
                'minor:Minor version increment'
                'major:Major version increment'
            )
            _describe 'release types' release_types
            ;;
        *)
            release_actions=(
                'prepare:Prepare release'
                'notes:Generate release notes'
                'security:Run security scan'
                'quality:Run quality checks'
                'prep:Prepare (short)'
                'p:Prepare (short)'
                'n:Notes (short)'
                'sec:Security (short)'
                's:Security (short)'
                'qual:Quality (short)'
                'q:Quality (short)'
            )
            _describe 'release actions' release_actions
            ;;
    esac
}

_wsim_completion() {
    local -a simulators
    # Get available simulators
    if command -v xcrun >/dev/null 2>&1; then
        simulators=(${(f)"$(xcrun simctl list devices available | grep -E 'iPhone|iPad' | grep -v 'unavailable' | sed 's/.*(\([^)]*\)).*/\1/' | head -10)"})
        
        # Add common device names
        simulators+=(
            'iPhone\ 15\ Pro:iPhone 15 Pro'
            'iPhone\ 15\ Pro\ Max:iPhone 15 Pro Max'
            'iPhone\ 15:iPhone 15'
            'iPad\ Pro:iPad Pro'
            '--list:Show available devices'
        )
        
        _describe 'iOS simulators' simulators
    fi
}

# Register completions
compdef _wtest_completion wtest
compdef _wlint_completion wlint
compdef _wdev_completion wdev
compdef _wcd_completion wcd
compdef _wrelease_completion wrelease
compdef _wsim_completion wsim

# Git-aware completions for weather project
_weather_git_completion() {
    # Only provide git completions when in weather project
    local project_root=""
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/weather.xcodeproj/project.pbxproj" ]] || [[ -f "$dir/weather/weather.xcodeproj/project.pbxproj" ]]; then
            project_root="$dir"
            break
        fi
        dir=$(dirname "$dir")
    done
    
    if [[ -n "$project_root" ]]; then
        # Enhance git completion with weather-specific branches/tags
        _git
    fi
}

# Custom completion for weather-specific git commands
alias wgit='git'
compdef _weather_git_completion wgit

# Completion for fastlane (if available)
if command -v fastlane >/dev/null 2>&1; then
    _wfastlane_completion() {
        local -a lanes
        local project_root=""
        local dir="$PWD"
        while [[ "$dir" != "/" ]]; do
            if [[ -f "$dir/weather.xcodeproj/project.pbxproj" ]] || [[ -f "$dir/weather/weather.xcodeproj/project.pbxproj" ]]; then
                project_root="$dir"
                break
            fi
            dir=$(dirname "$dir")
        done
        
        if [[ -n "$project_root" && -f "$project_root/fastlane/Fastfile" ]]; then
            lanes=(${(f)"$(grep "lane :" "$project_root/fastlane/Fastfile" | sed 's/.*lane :\([a-zA-Z_]*\).*/\1/' | sort -u)"})
            _describe 'fastlane lanes' lanes
        fi
    }
    
    alias wfastlane='fastlane'
    compdef _wfastlane_completion wfastlane
fi

# Context-aware completion for file operations
_weather_file_completion() {
    local project_root=""
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/weather.xcodeproj/project.pbxproj" ]] || [[ -f "$dir/weather/weather.xcodeproj/project.pbxproj" ]]; then
            project_root="$dir"
            break
        fi
        dir=$(dirname "$dir")
    done
    
    if [[ -n "$project_root" ]]; then
        # Prioritize Swift files and common project files
        local -a weather_files
        weather_files=(
            ${(f)"$(find "$project_root" -name "*.swift" -not -path "*/DerivedData/*" -not -path "*/build/*" | head -20)"}
            ${(f)"$(find "$project_root" -name "*.md" | head -10)"}
        )
        
        _path_files && _describe 'weather project files' weather_files
    else
        _path_files
    fi
}

# Enhanced file completion for common commands in weather project
alias wcode='code'
alias wedit='open -a "Xcode"'
compdef _weather_file_completion wcode
compdef _weather_file_completion wedit

# Smart completion caching (improves performance)
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Weather-specific completion styling
zstyle ':completion:*:*:w*:*' group-name ''
zstyle ':completion:*:*:w*:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:w*:*' menu select
zstyle ':completion:*:*:w*:*' rehash true