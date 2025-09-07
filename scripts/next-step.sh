#!/bin/bash
# Docker Learning Path - Next Step Recommendation Script
# Analyzes progress and recommends the next learning step

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROGRESS_FILE="$PROJECT_ROOT/docs/PROGRESS.json"

# Colors for output
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Check dependencies
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required but not installed.${RESET}"
        echo "Install jq: sudo apt-get install jq (Ubuntu) or brew install jq (macOS)"
        exit 1
    fi
    
    if [[ ! -f "$PROGRESS_FILE" ]]; then
        echo -e "${RED}Error: Progress file not found.${RESET}"
        echo "Run 'make setup' to initialize progress tracking."
        exit 1
    fi
}

# Find the next incomplete lesson
find_next_lesson() {
    jq -r '
        .phases[] as $phase | 
        $phase.lessons[] as $lesson |
        select($lesson.status != "completed") |
        {
            phase_id: $phase.phase_id,
            phase_name: $phase.name,
            lesson_id: $lesson.lesson_id, 
            lesson_title: $lesson.title,
            estimated_time: ($lesson.estimated_minutes // 60)
        } | 
        "\(.phase_id)|\(.phase_name)|\(.lesson_id)|\(.lesson_title)|\(.estimated_time)"
    ' "$PROGRESS_FILE" | head -1
}

# Get phase directory name
get_phase_directory() {
    local phase_id=$1
    find "$PROJECT_ROOT" -name "$(printf "%02d" $phase_id)-*" -type d | head -1 | xargs basename
}

# Check if this is the first lesson of a new phase
is_new_phase() {
    local phase_id=$1
    local completed_in_phase=$(jq -r "[.phases[$phase_id].lessons[] | select(.status == \"completed\")] | length" "$PROGRESS_FILE")
    [[ $completed_in_phase -eq 0 ]]
}

# Get completion statistics for context
get_completion_stats() {
    local total_lessons=$(jq -r '.phases | length * 4' "$PROGRESS_FILE")
    local completed_lessons=$(jq -r '[.phases[].lessons[] | select(.status == "completed")] | length' "$PROGRESS_FILE")
    local completion_percentage=$(( (completed_lessons * 100) / total_lessons ))
    
    echo "$completed_lessons,$total_lessons,$completion_percentage"
}

# Display motivational message based on progress
display_motivation() {
    local stats=$(get_completion_stats)
    local percentage=$(echo $stats | cut -d',' -f3)
    
    case $percentage in
        0)
            echo -e "${BLUE}🚀 Ready to start your Docker journey? Every expert was once a beginner!${RESET}"
            ;;
        1-25)
            echo -e "${GREEN}🌱 Great start! You're building a solid foundation in Docker fundamentals.${RESET}"
            ;;
        26-50)
            echo -e "${GREEN}🏗️ Excellent progress! You're becoming proficient with core Docker concepts.${RESET}"
            ;;
        51-75) 
            echo -e "${GREEN}⚡ Outstanding work! You're mastering advanced Docker techniques.${RESET}"
            ;;
        76-99)
            echo -e "${GREEN}🏆 Almost there! You're on the path to Docker mastery.${RESET}"
            ;;
        100)
            echo -e "${GREEN}🎉 Congratulations! You've completed the entire curriculum!${RESET}"
            ;;
    esac
}

# Display current progress context
display_progress_context() {
    local stats=$(get_completion_stats)
    local completed=$(echo $stats | cut -d',' -f1)
    local total=$(echo $stats | cut -d',' -f2)
    local percentage=$(echo $stats | cut -d',' -f3)
    
    echo -e "${DIM}Progress: $completed/$total lessons ($percentage%) complete${RESET}"
    
    # Show progress bar
    local bar_length=30
    local filled_length=$(( (percentage * bar_length) / 100 ))
    local empty_length=$(( bar_length - filled_length ))
    
    printf "${DIM}["
    printf "%0.s█" $(seq 1 $filled_length)
    printf "%0.s░" $(seq 1 $empty_length)
    printf "] %d%%${RESET}\n" $percentage
    echo
}

# Display next step recommendation
display_next_step() {
    local next_lesson=$(find_next_lesson)
    
    if [[ -z "$next_lesson" || "$next_lesson" == "null" ]]; then
        echo -e "${GREEN}🎉 Congratulations! You've completed all 48 lessons!${RESET}"
        echo
        echo -e "${BOLD}What's next?${RESET}"
        echo "• Explore integration labs: ${YELLOW}cd labs/integration${RESET}"
        echo "• Try challenge labs: ${YELLOW}cd labs/challenges${RESET}" 
        echo "• Experiment with cutting-edge features: ${YELLOW}cd labs/experiments${RESET}"
        echo "• Contribute to the repository: ${YELLOW}cat CLAUDE.md${RESET}"
        echo "• Share your experience with others"
        return
    fi
    
    # Parse lesson details
    IFS='|' read -r phase_id phase_name lesson_id lesson_title estimated_time <<< "$next_lesson"
    local phase_dir=$(get_phase_directory $phase_id)
    
    echo -e "${BOLD}${GREEN}Next Step:${RESET}"
    echo -e "Phase $(printf "%02d" $phase_id): ${BOLD}$phase_name${RESET}"
    echo -e "Lesson: ${YELLOW}$lesson_title${RESET}"
    echo -e "Estimated time: ~$estimated_time minutes"
    echo
    
    # Special handling for new phase
    if is_new_phase $phase_id; then
        echo -e "${BLUE}📚 Starting a new phase!${RESET}"
        echo "Read the phase overview first:"
        echo -e "  ${YELLOW}cd $phase_dir && cat README.md${RESET}"
        echo
    fi
    
    echo -e "${BOLD}Commands to continue:${RESET}"
    echo -e "  ${YELLOW}cd $phase_dir${RESET}"
    echo -e "  ${YELLOW}cat lab.md${RESET}    ${DIM}# Read the hands-on exercises${RESET}"
    echo
    
    # Show verification command
    echo -e "${BOLD}After completing the lesson:${RESET}"
    echo -e "  ${YELLOW}make verify-phase PHASE=$(printf "%02d" $phase_id)${RESET}    ${DIM}# Verify your work${RESET}"
    echo
}

# Display helpful tips based on progress
display_tips() {
    local stats=$(get_completion_stats)
    local percentage=$(echo $stats | cut -d',' -f3)
    
    echo -e "${BOLD}💡 Tips:${RESET}"
    
    case $percentage in
        0-25)
            echo "• Take your time with fundamentals - they're the foundation of everything else"
            echo "• Practice each command multiple times until it feels natural"
            echo "• Don't hesitate to ask questions using GitHub issues"
            ;;
        26-50)
            echo "• Start thinking about real-world applications for what you're learning"
            echo "• Try the exercises with your own projects when possible"
            echo "• Document your own notes and discoveries"
            ;;
        51-75)
            echo "• Focus on understanding the 'why' behind each pattern"
            echo "• Consider how these concepts apply to your specific use cases"
            echo "• Start exploring the integration labs for hands-on practice"
            ;;
        76-99)
            echo "• You're ready for advanced challenges - try the challenge labs"
            echo "• Consider contributing improvements or sharing your experience"
            echo "• Apply these skills to real projects to solidify understanding"
            ;;
        100)
            echo "• Share your knowledge by helping others in the community"
            echo "• Consider contributing advanced content or improvements"
            echo "• Stay updated with Docker's latest features and best practices"
            ;;
    esac
}

# Display recent achievements
display_achievements() {
    local recent_completions=$(jq -r '
        [.phases[].lessons[] | select(.status == "completed" and .completed_at != null)]
        | sort_by(.completed_at)
        | reverse
        | .[0:3]
        | length
    ' "$PROGRESS_FILE" 2>/dev/null || echo "0")
    
    if [[ $recent_completions -gt 0 ]]; then
        echo -e "${BOLD}🏆 Recent achievements:${RESET}"
        
        jq -r '
            [.phases[].lessons[] | select(.status == "completed" and .completed_at != null)]
            | sort_by(.completed_at)
            | reverse
            | .[0:3]
            | .[]
            | "• \(.title) (\(.completed_at[:10]))"
        ' "$PROGRESS_FILE" 2>/dev/null || echo "  No recent activity tracked"
        echo
    fi
}

# Check for available labs based on progress
suggest_labs() {
    local stats=$(get_completion_stats)
    local percentage=$(echo $stats | cut -d',' -f3)
    
    if [[ $percentage -ge 25 ]]; then
        echo -e "${BOLD}🧪 Ready for labs?${RESET}"
        
        if [[ $percentage -ge 25 && $percentage -lt 50 ]]; then
            echo "• Try Integration Lab 01: Full-Stack Deployment"
            echo -e "  ${YELLOW}cd labs/integration/01-fullstack-deployment${RESET}"
        elif [[ $percentage -ge 50 && $percentage -lt 75 ]]; then
            echo "• Ready for Integration Lab 02: CI/CD Pipeline"
            echo -e "  ${YELLOW}cd labs/integration/02-cicd-multiarch${RESET}"
        elif [[ $percentage -ge 75 ]]; then
            echo "• Challenge yourself with advanced labs:"
            echo -e "  ${YELLOW}cd labs/challenges/01-ecommerce-microservices${RESET}"
            echo -e "  ${YELLOW}cd labs/experiments/01-buildkit-advanced${RESET}"
        fi
        echo
    fi
}

# Main function
main() {
    check_dependencies
    
    echo -e "${BOLD}${BLUE}Docker Learning Path - Next Steps${RESET}"
    echo "=================================="
    echo
    
    display_motivation
    echo
    
    display_progress_context
    display_next_step
    display_achievements
    display_tips
    echo
    suggest_labs
    
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}Need help?${RESET} Run ${YELLOW}make help${RESET} or check ${YELLOW}docs/FAQ.md${RESET}"
}

main "$@"