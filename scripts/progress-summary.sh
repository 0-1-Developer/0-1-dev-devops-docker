#!/bin/bash
# Docker Learning Path - Progress Summary Script
# Analyzes PROGRESS.json and displays detailed learning progress

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROGRESS_FILE="$SCRIPT_DIR/../docs/PROGRESS.json"

# Colors for output
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'
BOLD='\033[1m'

# Check if jq is available
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required but not installed.${RESET}"
        echo "Install jq:"
        echo "  - Ubuntu/Debian: sudo apt-get install jq"
        echo "  - macOS: brew install jq"
        echo "  - Windows: choco install jq"
        exit 1
    fi
}

# Check if progress file exists
check_progress_file() {
    if [[ ! -f "$PROGRESS_FILE" ]]; then
        echo -e "${RED}Error: Progress file not found at $PROGRESS_FILE${RESET}"
        echo "Run 'make setup' to initialize progress tracking."
        exit 1
    fi
}

# Calculate completion statistics
calculate_stats() {
    local total_lessons=$(jq -r '.phases | length * 4' "$PROGRESS_FILE")
    local completed_lessons=$(jq -r '[.phases[].lessons[] | select(.status == "completed")] | length' "$PROGRESS_FILE")
    local completion_percentage=$(( (completed_lessons * 100) / total_lessons ))
    
    echo "$completed_lessons,$total_lessons,$completion_percentage"
}

# Display overall progress
display_overall_progress() {
    local stats=$(calculate_stats)
    local completed=$(echo $stats | cut -d',' -f1)
    local total=$(echo $stats | cut -d',' -f2)
    local percentage=$(echo $stats | cut -d',' -f3)
    
    echo -e "${BOLD}${BLUE}Overall Progress${RESET}"
    echo "==============="
    echo -e "Completed Lessons: ${GREEN}$completed${RESET} / $total"
    echo -e "Progress: ${GREEN}$percentage%${RESET}"
    
    # Progress bar
    local bar_length=40
    local filled_length=$(( (percentage * bar_length) / 100 ))
    local empty_length=$(( bar_length - filled_length ))
    
    printf "Progress Bar: ["
    printf "%0.s█" $(seq 1 $filled_length)
    printf "%0.s░" $(seq 1 $empty_length)
    printf "] %d%%\n" $percentage
    echo
}

# Display phase-by-phase progress
display_phase_progress() {
    echo -e "${BOLD}${BLUE}Phase-by-Phase Progress${RESET}"
    echo "======================="
    
    for i in $(seq 0 11); do
        local phase_num=$(printf "%02d" $i)
        local phase_name=$(jq -r ".phases[$i].name" "$PROGRESS_FILE")
        local phase_completed=$(jq -r "[.phases[$i].lessons[] | select(.status == \"completed\")] | length" "$PROGRESS_FILE")
        local phase_total=$(jq -r ".phases[$i].lessons | length" "$PROGRESS_FILE")
        local phase_percentage=$(( (phase_completed * 100) / phase_total ))
        
        # Determine status icon
        local status_icon=""
        if [[ $phase_percentage -eq 100 ]]; then
            status_icon="${GREEN}✅${RESET}"
        elif [[ $phase_percentage -gt 0 ]]; then
            status_icon="${YELLOW}🔄${RESET}"
        else
            status_icon="${RED}❌${RESET}"
        fi
        
        printf "Phase %s: %s %-25s %s %2d/4 (%3d%%)\n" \
            "$phase_num" "$status_icon" "$phase_name" \
            "$(printf "%0.s─" $(seq 1 $((25 - ${#phase_name}))))" \
            "$phase_completed" "$phase_percentage"
    done
    echo
}

# Display recent activity
display_recent_activity() {
    echo -e "${BOLD}${BLUE}Recent Activity${RESET}"
    echo "==============="
    
    # Get last 5 completed lessons sorted by completion date
    jq -r '
        [.phases[].lessons[] | select(.status == "completed" and .completed_at != null)] 
        | sort_by(.completed_at) 
        | reverse 
        | .[0:5] 
        | .[] 
        | "✅ \(.lesson_id): \(.title) (completed: \(.completed_at[:10]))"
    ' "$PROGRESS_FILE" 2>/dev/null || echo "No recent activity tracked."
    echo
}

# Display current learning path recommendations
display_recommendations() {
    echo -e "${BOLD}${BLUE}Next Steps${RESET}"
    echo "=========="
    
    # Find first incomplete lesson
    local next_lesson=$(jq -r '
        .phases[] as $phase | 
        $phase.lessons[] | 
        select(.status != "completed") | 
        "\($phase.phase_id)-\(.lesson_id): \(.title)"
    ' "$PROGRESS_FILE" | head -1)
    
    if [[ -n "$next_lesson" && "$next_lesson" != "null" ]]; then
        echo -e "Continue with: ${GREEN}$next_lesson${RESET}"
        
        # Extract phase from lesson ID
        local phase_id=$(echo $next_lesson | cut -d'-' -f1)
        local phase_dir=$(printf "%02d-" $phase_id)$(find . -name "${phase_id}*" -type d | head -1 | sed 's/.*\///' | sed 's/^[0-9][0-9]-//')
        
        echo "Commands to continue:"
        echo -e "  ${YELLOW}cd $phase_dir${RESET}"
        echo -e "  ${YELLOW}cat lab.md${RESET}"
    else
        echo -e "${GREEN}🎉 Congratulations! All phases completed!${RESET}"
        echo "Consider exploring:"
        echo "  - Integration labs in ./labs/integration/"
        echo "  - Challenge labs in ./labs/challenges/"
        echo "  - Contributing to the repository"
    fi
    echo
}

# Display badge progress
display_badge_progress() {
    echo -e "${BOLD}${BLUE}Badge Progress${RESET}"
    echo "=============="
    
    local badges_earned=0
    local total_badges=12
    
    for i in $(seq 0 11); do
        local phase_completed=$(jq -r "[.phases[$i].lessons[] | select(.status == \"completed\")] | length" "$PROGRESS_FILE")
        local phase_name=$(jq -r ".phases[$i].name" "$PROGRESS_FILE")
        
        if [[ $phase_completed -eq 4 ]]; then
            echo -e "🏆 ${GREEN}Phase $(printf "%02d" $i): $phase_name Badge${RESET}"
            ((badges_earned++))
        else
            echo -e "🔒 ${YELLOW}Phase $(printf "%02d" $i): $phase_name Badge${RESET} ($phase_completed/4 lessons)"
        fi
    done
    
    echo
    echo -e "Badges Earned: ${GREEN}$badges_earned${RESET} / $total_badges"
}

# Display time estimates
display_time_estimates() {
    local stats=$(calculate_stats)
    local completed=$(echo $stats | cut -d',' -f1)
    local total=$(echo $stats | cut -d',' -f2)
    local remaining=$(( total - completed ))
    
    echo -e "${BOLD}${BLUE}Time Estimates${RESET}"
    echo "=============="
    
    # Assuming average 1 hour per lesson
    local hours_completed=$completed
    local hours_remaining=$remaining
    local total_hours=$total
    
    echo -e "Time invested: ${GREEN}~$hours_completed hours${RESET}"
    echo -e "Time remaining: ${YELLOW}~$hours_remaining hours${RESET}"
    echo -e "Total curriculum: ~$total_hours hours"
    
    if [[ $hours_remaining -gt 0 ]]; then
        echo
        echo "At different paces:"
        echo "  - 1 hour/day:  $(( hours_remaining )) days"
        echo "  - 2 hours/day: $(( (hours_remaining + 1) / 2 )) days"
        echo "  - 5 hours/week: $(( (hours_remaining + 4) / 5 )) weeks"
    fi
}

# Main function
main() {
    check_dependencies
    check_progress_file
    
    display_overall_progress
    display_phase_progress
    display_recent_activity
    display_recommendations
    display_badge_progress
    display_time_estimates
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}Need help?${RESET} Check docs/FAQ.md or run 'make troubleshoot'"
}

main "$@"