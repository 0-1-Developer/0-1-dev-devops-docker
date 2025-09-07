#!/bin/bash
# Docker Learning Path - Progress Update Script
# Updates progress tracking from completed anchors and manual inputs

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

log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }

# Initialize progress file if it doesn't exist
initialize_progress_file() {
    log_info "Initializing progress file..."
    
    local learner_id=$(whoami 2>/dev/null || echo "learner")
    local current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat > "$PROGRESS_FILE" << EOF
{
  "version": "2.0",
  "learner_id": "$learner_id",
  "start_date": "$current_date",
  "last_updated": "$current_date",
  "total_lessons": 48,
  "completed_lessons": 0,
  "completion_percentage": 0,
  "phases": [
$(for i in $(seq 0 11); do
    local phase_name=""
    case $i in
        0) phase_name="Foundations" ;;
        1) phase_name="Dockerfile Basics" ;;
        2) phase_name="BuildKit Advanced" ;;
        3) phase_name="Container Operations" ;;
        4) phase_name="Networking" ;;
        5) phase_name="Storage & Volumes" ;;
        6) phase_name="Compose" ;;
        7) phase_name="Security" ;;
        8) phase_name="CI/CD & Buildx" ;;
        9) phase_name="Registries" ;;
        10) phase_name="Observability" ;;
        11) phase_name="Advanced Images" ;;
    esac
    
    echo "    {"
    echo "      \"phase_id\": $i,"
    echo "      \"name\": \"$phase_name\","
    echo "      \"status\": \"not_started\","
    echo "      \"completion_percentage\": 0,"
    echo "      \"lessons\": ["
    
    for j in $(seq 1 4); do
        echo "        {"
        echo "          \"lesson_id\": \"p$(printf '%02d' $i)-m01-l$(printf '%02d' $j)\","
        echo "          \"title\": \"Lesson $j\","
        echo "          \"status\": \"not_started\","
        echo "          \"estimated_minutes\": 60,"
        echo "          \"started_at\": null,"
        echo "          \"completed_at\": null"
        if [[ $j -eq 4 ]]; then
            echo "        }"
        else
            echo "        },"
        fi
    done
    
    echo "      ]"
    if [[ $i -eq 11 ]]; then
        echo "    }"
    else
        echo "    },"
    fi
done)
  ],
  "badges": {
    "phase_badges": [],
    "skill_badges": [],
    "milestone_badges": []
  },
  "statistics": {
    "total_time_minutes": 0,
    "average_lesson_time": 0,
    "fastest_lesson_time": null,
    "slowest_lesson_time": null,
    "streak_days": 0,
    "last_activity_date": null
  }
}
EOF
    
    log_success "Progress file initialized"
}

# Scan for progress anchors in phase files
scan_progress_anchors() {
    log_info "Scanning for progress anchors in phase files..."
    
    local found_anchors=()
    
    for phase_dir in $(find "$PROJECT_ROOT" -name "[0-9][0-9]-*" -type d | sort); do
        local phase_num=$(basename "$phase_dir" | grep -oE '^[0-9]{2}')
        
        # Search for progress anchors in markdown files
        for md_file in "$phase_dir"/*.md; do
            if [[ -f "$md_file" ]]; then
                # Look for anchor patterns like: <!-- PROGRESS_ANCHOR: p04-m01-l02 -->
                local anchors=$(grep -o "PROGRESS_ANCHOR: p[0-9][0-9]-m[0-9][0-9]-l[0-9][0-9]" "$md_file" 2>/dev/null || true)
                for anchor in $anchors; do
                    local lesson_id=$(echo "$anchor" | grep -o "p[0-9][0-9]-m[0-9][0-9]-l[0-9][0-9]")
                    found_anchors+=("$lesson_id")
                done
            fi
        done
    done
    
    log_info "Found ${#found_anchors[@]} progress anchors"
    
    # Mark found anchors as completed
    for lesson_id in "${found_anchors[@]}"; do
        mark_lesson_complete "$lesson_id"
    done
}

# Mark a specific lesson as complete
mark_lesson_complete() {
    local lesson_id=$1
    local current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Extract phase ID from lesson ID (e.g., p04-m01-l02 -> 4)
    local phase_id=$(echo "$lesson_id" | grep -o "p[0-9][0-9]" | grep -o "[0-9][0-9]" | sed 's/^0//')
    
    # Update the lesson status in progress file
    local updated=$(jq --arg lesson_id "$lesson_id" --arg date "$current_date" '
        .phases['"$phase_id"'].lessons |= map(
            if .lesson_id == $lesson_id then
                .status = "completed" |
                .completed_at = $date |
                (if .started_at == null then .started_at = $date else . end)
            else . end
        )
    ' "$PROGRESS_FILE")
    
    echo "$updated" > "$PROGRESS_FILE"
    log_success "Marked lesson as complete: $lesson_id"
}

# Update overall statistics
update_statistics() {
    log_info "Updating overall statistics..."
    
    local current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Calculate completion statistics
    local updated=$(jq --arg date "$current_date" '
        .last_updated = $date |
        .completed_lessons = ([.phases[].lessons[] | select(.status == "completed")] | length) |
        .completion_percentage = ((.completed_lessons * 100) / .total_lessons) |
        
        # Update phase statistics
        .phases = (.phases | map(
            .completion_percentage = (([.lessons[] | select(.status == "completed")] | length) * 100 / (.lessons | length)) |
            .status = if .completion_percentage == 100 then "completed"
                     elif .completion_percentage > 0 then "in_progress" 
                     else "not_started" end
        )) |
        
        # Update badge progress
        .badges.phase_badges = [.phases[] | select(.status == "completed") | "phase-" + (.phase_id | tostring | if length == 1 then "0" + . else . end)] |
        
        # Update activity streak (simplified)
        .statistics.last_activity_date = $date
    ' "$PROGRESS_FILE")
    
    echo "$updated" > "$PROGRESS_FILE"
    log_success "Statistics updated"
}

# Interactive lesson completion
interactive_complete() {
    echo -e "${BOLD}${BLUE}Interactive Lesson Completion${RESET}"
    echo "============================="
    echo
    
    # Show current progress
    local completed=$(jq -r '.completed_lessons' "$PROGRESS_FILE")
    local total=$(jq -r '.total_lessons' "$PROGRESS_FILE")
    local percentage=$(jq -r '.completion_percentage' "$PROGRESS_FILE")
    
    echo -e "Current progress: ${GREEN}$completed${RESET}/$total lessons (${GREEN}$percentage%${RESET})"
    echo
    
    # Find next incomplete lesson
    local next_lesson=$(jq -r '
        .phases[] as $phase | 
        $phase.lessons[] | 
        select(.status != "completed") | 
        "\($phase.phase_id)|\($phase.name)|\(.lesson_id)|\(.title)" 
    ' "$PROGRESS_FILE" | head -1)
    
    if [[ -z "$next_lesson" || "$next_lesson" == "null" ]]; then
        echo -e "${GREEN}🎉 All lessons completed!${RESET}"
        return
    fi
    
    IFS='|' read -r phase_id phase_name lesson_id lesson_title <<< "$next_lesson"
    
    echo -e "Next lesson: ${YELLOW}$lesson_title${RESET} (Phase $(printf "%02d" $phase_id): $phase_name)"
    echo -e "Lesson ID: ${BLUE}$lesson_id${RESET}"
    echo
    
    read -p "Mark this lesson as complete? [y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mark_lesson_complete "$lesson_id"
        update_statistics
        echo
        echo -e "${GREEN}✅ Lesson marked as complete!${RESET}"
        
        # Show updated progress
        local new_completed=$(jq -r '.completed_lessons' "$PROGRESS_FILE")
        local new_percentage=$(jq -r '.completion_percentage' "$PROGRESS_FILE")
        echo -e "Updated progress: ${GREEN}$new_completed${RESET}/$total lessons (${GREEN}$new_percentage%${RESET})"
        
        # Check for phase completion
        local phase_completion=$(jq -r ".phases[$phase_id].completion_percentage" "$PROGRESS_FILE")
        if [[ $phase_completion -eq 100 ]]; then
            echo -e "${GREEN}🏆 Phase $(printf "%02d" $phase_id) completed! Badge earned!${RESET}"
        fi
    else
        echo "No changes made."
    fi
}

# Manual lesson marking
manual_complete() {
    local lesson_id=$1
    
    if [[ ! "$lesson_id" =~ ^p[0-9]{2}-m[0-9]{2}-l[0-9]{2}$ ]]; then
        log_error "Invalid lesson ID format. Use: pXX-mXX-lXX (e.g., p04-m01-l02)"
        return 1
    fi
    
    # Check if lesson exists in progress file
    local exists=$(jq -r --arg lesson_id "$lesson_id" '
        any(.phases[].lessons[]; .lesson_id == $lesson_id)
    ' "$PROGRESS_FILE")
    
    if [[ "$exists" != "true" ]]; then
        log_error "Lesson ID not found: $lesson_id"
        return 1
    fi
    
    mark_lesson_complete "$lesson_id"
    update_statistics
    
    echo
    echo -e "${GREEN}✅ Lesson marked as complete: $lesson_id${RESET}"
    
    # Show current progress
    local completed=$(jq -r '.completed_lessons' "$PROGRESS_FILE")
    local total=$(jq -r '.total_lessons' "$PROGRESS_FILE")
    local percentage=$(jq -r '.completion_percentage' "$PROGRESS_FILE")
    echo -e "Progress: ${GREEN}$completed${RESET}/$total lessons (${GREEN}$percentage%${RESET})"
}

# Reset progress (with confirmation)
reset_progress() {
    echo -e "${RED}⚠️ WARNING: This will reset ALL progress data!${RESET}"
    echo "You will lose all completed lesson records, timestamps, and statistics."
    echo
    read -p "Are you sure you want to reset all progress? Type 'RESET' to confirm: " -r
    
    if [[ "$REPLY" == "RESET" ]]; then
        if [[ -f "$PROGRESS_FILE" ]]; then
            mv "$PROGRESS_FILE" "$PROGRESS_FILE.backup.$(date +%s)"
            log_info "Previous progress backed up"
        fi
        
        initialize_progress_file
        log_success "Progress reset complete"
    else
        log_info "Reset cancelled"
    fi
}

# Usage information
show_usage() {
    echo "Docker Learning Path - Progress Update Script"
    echo
    echo "Usage:"
    echo "  $0                          # Interactive lesson completion"
    echo "  $0 scan                     # Scan for progress anchors"
    echo "  $0 complete <lesson-id>     # Mark specific lesson complete"
    echo "  $0 stats                    # Update statistics only"
    echo "  $0 init                     # Initialize progress file"
    echo "  $0 reset                    # Reset all progress (with confirmation)"
    echo
    echo "Examples:"
    echo "  $0 complete p04-m01-l02     # Mark Phase 4, Module 1, Lesson 2 complete"
    echo "  $0 scan                     # Scan all files for progress anchors"
    echo
    echo "Lesson ID format: pXX-mXX-lXX (phase-module-lesson)"
}

# Main function
main() {
    # Check dependencies
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
        echo "Install: sudo apt-get install jq (Ubuntu) or brew install jq (macOS)"
        exit 1
    fi
    
    # Create progress file if it doesn't exist
    if [[ ! -f "$PROGRESS_FILE" ]]; then
        initialize_progress_file
    fi
    
    case "${1:-interactive}" in
        scan)
            scan_progress_anchors
            update_statistics
            ;;
        complete)
            if [[ -z "$2" ]]; then
                log_error "Lesson ID required for complete command"
                show_usage
                exit 1
            fi
            manual_complete "$2"
            ;;
        stats)
            update_statistics
            ;;
        init)
            initialize_progress_file
            ;;
        reset)
            reset_progress
            ;;
        interactive|"")
            interactive_complete
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"