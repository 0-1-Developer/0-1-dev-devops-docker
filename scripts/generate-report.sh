#!/bin/bash
# Docker Learning Path - Report Generation Script
# Generates detailed learning progress reports in multiple formats

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

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing dependencies: ${missing_deps[*]}${RESET}" >&2
        exit 1
    fi
    
    if [[ ! -f "$PROGRESS_FILE" ]]; then
        echo -e "${RED}Error: Progress file not found at $PROGRESS_FILE${RESET}" >&2
        exit 1
    fi
}

# Generate markdown report
generate_markdown_report() {
    local learner_id=$(jq -r '.learner_id' "$PROGRESS_FILE")
    local start_date=$(jq -r '.start_date' "$PROGRESS_FILE" | cut -d'T' -f1)
    local last_updated=$(jq -r '.last_updated' "$PROGRESS_FILE" | cut -d'T' -f1)
    local completed_lessons=$(jq -r '.completed_lessons' "$PROGRESS_FILE")
    local total_lessons=$(jq -r '.total_lessons' "$PROGRESS_FILE")
    local completion_percentage=$(jq -r '.completion_percentage' "$PROGRESS_FILE")
    
    cat << EOF
# Docker Learning Path - Progress Report

**Learner:** $learner_id  
**Report Date:** $(date +"%Y-%m-%d")  
**Learning Period:** $start_date to $last_updated  

---

## 📊 Overall Progress

- **Completion:** $completed_lessons / $total_lessons lessons ($completion_percentage%)
- **Learning Duration:** $(( ($(date -d "$last_updated" +%s) - $(date -d "$start_date" +%s)) / 86400 )) days
- **Average Progress:** $(( completion_percentage > 0 ? completed_lessons * 100 / completion_percentage : 0 ))% of available time utilized

### Progress Visualization

\`\`\`
$(printf "%-20s" "Progress:")
$(printf "%0.s█" $(seq 1 $((completion_percentage / 3))))$(printf "%0.s░" $(seq 1 $((33 - completion_percentage / 3)))) $completion_percentage%
\`\`\`

---

## 🎯 Phase Completion Status

| Phase | Name | Progress | Status | Badge |
|-------|------|----------|--------|-------|
EOF

    # Generate phase table
    for i in $(seq 0 11); do
        local phase_name=$(jq -r ".phases[$i].name" "$PROGRESS_FILE")
        local phase_completion=$(jq -r ".phases[$i].completion_percentage" "$PROGRESS_FILE")
        local phase_status=$(jq -r ".phases[$i].status" "$PROGRESS_FILE")
        local completed_count=$(jq -r "[.phases[$i].lessons[] | select(.status == \"completed\")] | length" "$PROGRESS_FILE")
        
        local status_icon=""
        local badge_status=""
        
        case $phase_status in
            "completed")
                status_icon="✅ Complete"
                badge_status="🏆 Earned"
                ;;
            "in_progress")
                status_icon="🔄 In Progress"
                badge_status="🔒 Pending"
                ;;
            *)
                status_icon="❌ Not Started" 
                badge_status="🔒 Locked"
                ;;
        esac
        
        printf "| %02d | %-25s | %d/4 (%3d%%) | %s | %s |\n" \
            $i "$phase_name" $completed_count $phase_completion "$status_icon" "$badge_status"
    done
    
    cat << EOF

---

## 🏆 Achievements & Badges

### Phase Badges Earned
EOF
    
    local earned_badges=$(jq -r '.badges.phase_badges[]?' "$PROGRESS_FILE" 2>/dev/null)
    if [[ -n "$earned_badges" ]]; then
        echo "$earned_badges" | while read -r badge; do
            echo "- 🏆 **$badge**"
        done
    else
        echo "- *No phase badges earned yet*"
    fi
    
    cat << EOF

### Progress Milestones

EOF
    
    if [[ $completion_percentage -ge 25 ]]; then
        echo "- ✅ **25% Milestone** - Docker Fundamentals (Earned)"
    else
        echo "- 🔒 **25% Milestone** - Docker Fundamentals ($(( 25 - completion_percentage ))% remaining)"
    fi
    
    if [[ $completion_percentage -ge 50 ]]; then
        echo "- ✅ **50% Milestone** - Production Ready (Earned)" 
    else
        echo "- 🔒 **50% Milestone** - Production Ready ($(( 50 - completion_percentage ))% remaining)"
    fi
    
    if [[ $completion_percentage -ge 75 ]]; then
        echo "- ✅ **75% Milestone** - Advanced Practitioner (Earned)"
    else
        echo "- 🔒 **75% Milestone** - Advanced Practitioner ($(( 75 - completion_percentage ))% remaining)"
    fi
    
    if [[ $completion_percentage -eq 100 ]]; then
        echo "- ✅ **100% Milestone** - Docker Master (Earned)"
    else
        echo "- 🔒 **100% Milestone** - Docker Master ($(( 100 - completion_percentage ))% remaining)"
    fi
    
    cat << EOF

---

## 📈 Learning Analytics

### Completion Timeline

EOF
    
    # Show lessons completed by date
    jq -r '
        [.phases[].lessons[] | select(.status == "completed" and .completed_at != null)]
        | group_by(.completed_at[:10])
        | .[]
        | "**" + .[0].completed_at[:10] + ":** " + (length | tostring) + " lessons completed"
    ' "$PROGRESS_FILE" 2>/dev/null | head -10
    
    cat << EOF

### Learning Velocity

EOF
    
    # Calculate learning velocity
    local days_learning=$(( ($(date +%s) - $(date -d "$start_date" +%s)) / 86400 ))
    if [[ $days_learning -gt 0 ]]; then
        local lessons_per_day=$(echo "scale=2; $completed_lessons / $days_learning" | bc -l 2>/dev/null || echo "0")
        local estimated_completion_days=$(echo "scale=0; (48 - $completed_lessons) / $lessons_per_day" | bc -l 2>/dev/null || echo "∞")
        
        echo "- **Current pace:** $lessons_per_day lessons/day"
        echo "- **Days learning:** $days_learning days"
        if [[ "$estimated_completion_days" != "∞" && "$estimated_completion_days" != "" ]]; then
            echo "- **Estimated completion:** $estimated_completion_days days at current pace"
        fi
    fi
    
    cat << EOF

### Focus Areas

EOF
    
    # Identify areas needing attention
    local incomplete_phases=$(jq -r '.phases[] | select(.completion_percentage < 100 and .completion_percentage > 0) | "- **Phase \(.phase_id | tostring | if length == 1 then "0" + . else . end)**: \(.name) (\(.completion_percentage)% complete)"' "$PROGRESS_FILE")
    
    if [[ -n "$incomplete_phases" ]]; then
        echo "**In Progress Phases:**"
        echo "$incomplete_phases"
    fi
    
    local next_phases=$(jq -r '.phases[] | select(.completion_percentage == 0) | "- **Phase \(.phase_id | tostring | if length == 1 then "0" + . else . end)**: \(.name)"' "$PROGRESS_FILE" | head -3)
    
    if [[ -n "$next_phases" ]]; then
        echo
        echo "**Next Recommended Phases:**"
        echo "$next_phases"
    fi
    
    cat << EOF

---

## 🎯 Recommendations

### Immediate Next Steps

EOF
    
    # Find next lesson to complete
    local next_lesson=$(jq -r '
        .phases[] as $phase |
        $phase.lessons[] |
        select(.status != "completed") |
        "**Continue with:** \(.title)\n**Phase:** \($phase.name)\n**Command:** \`cd \($phase.phase_id | tostring | if length == 1 then "0" + . else . end)-* && cat lab.md\`"
    ' "$PROGRESS_FILE" | head -3)
    
    if [[ -n "$next_lesson" && "$next_lesson" != "null" ]]; then
        echo "$next_lesson"
    else
        echo "🎉 **All lessons completed!** Consider exploring:"
        echo "- Integration labs in \`./labs/integration/\`"
        echo "- Challenge labs in \`./labs/challenges/\`"
        echo "- Contributing to the repository"
    fi
    
    cat << EOF

### Study Tips Based on Progress

EOF
    
    if [[ $completion_percentage -lt 25 ]]; then
        echo "- Focus on understanding Docker fundamentals thoroughly"
        echo "- Practice each command multiple times before moving on"
        echo "- Don't rush - foundation concepts are crucial for advanced topics"
    elif [[ $completion_percentage -lt 50 ]]; then
        echo "- Start connecting concepts to real-world applications"
        echo "- Begin thinking about how Docker fits into your projects"
        echo "- Consider starting the integration labs alongside phase work"
    elif [[ $completion_percentage -lt 75 ]]; then
        echo "- Focus on production patterns and best practices"
        echo "- Challenge yourself with complex scenarios"
        echo "- Start exploring advanced labs and experiments"
    else
        echo "- Apply knowledge to real projects outside the curriculum"
        echo "- Consider contributing improvements or creating content"
        echo "- Share knowledge with the community"
    fi
    
    cat << EOF

---

## 📚 Resources for Continued Learning

### Based on Your Progress

EOF
    
    if [[ $completion_percentage -ge 50 ]]; then
        echo "- **Official Docker Documentation**: Advanced topics and latest features"
        echo "- **Kubernetes Learning**: Natural next step for container orchestration"
        echo "- **Cloud Provider Container Services**: AWS ECS, Azure ACI, Google Cloud Run"
    fi
    
    if [[ $completion_percentage -ge 75 ]]; then
        echo "- **Container Security**: Advanced security patterns and compliance"
        echo "- **Service Mesh**: Istio, Linkerd for microservices communication"
        echo "- **GitOps**: ArgoCD, Flux for continuous deployment"
    fi
    
    cat << EOF

### Community Resources

- **Docker Community**: https://www.docker.com/community/
- **CNCF Landscape**: https://landscape.cncf.io/
- **Container Training**: Additional resources and workshops

---

## 📝 Notes

*This report was generated automatically from your progress data. For questions or issues with progress tracking, run \`make troubleshoot\` or check the FAQ.*

**Report generated:** $(date)  
**Progress file:** $(basename "$PROGRESS_FILE")  
**Learning path version:** $(jq -r '.version' "$PROGRESS_FILE")
EOF
}

# Generate CSV export
generate_csv_report() {
    echo "Phase,Name,Lesson_ID,Title,Status,Started_At,Completed_At"
    
    jq -r '
        .phases[] as $phase |
        $phase.lessons[] |
        "\($phase.phase_id),\($phase.name),\(.lesson_id),\(.title),\(.status),\(.started_at // ""),\(.completed_at // "")"
    ' "$PROGRESS_FILE"
}

# Generate JSON summary
generate_json_summary() {
    local report_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq --arg report_date "$report_date" '{
        report_metadata: {
            generated_at: $report_date,
            report_version: "1.0",
            learner_id: .learner_id
        },
        progress_summary: {
            total_lessons: .total_lessons,
            completed_lessons: .completed_lessons, 
            completion_percentage: .completion_percentage,
            learning_duration_days: ((now | strftime("%Y-%m-%d") | strptime("%Y-%m-%d")[0]) - (.start_date | strptime("%Y-%m-%d")[0])) / 86400 | floor
        },
        phase_progress: [
            .phases[] | {
                phase_id: .phase_id,
                name: .name,
                completion_percentage: .completion_percentage,
                status: .status,
                completed_lessons: [.lessons[] | select(.status == "completed")] | length
            }
        ],
        badges: .badges,
        next_steps: [
            .phases[] as $phase | 
            $phase.lessons[] | 
            select(.status != "completed") | 
            {
                phase_id: $phase.phase_id,
                phase_name: $phase.name,
                lesson_id: .lesson_id,
                lesson_title: .title
            }
        ] | .[0:3]
    }' "$PROGRESS_FILE"
}

# Main function
main() {
    local output_format="${1:-markdown}"
    local output_file="${2:-}"
    
    check_dependencies
    
    case "$output_format" in
        markdown|md)
            if [[ -n "$output_file" ]]; then
                generate_markdown_report > "$output_file"
                echo -e "${GREEN}Markdown report generated: $output_file${RESET}" >&2
            else
                generate_markdown_report
            fi
            ;;
        csv)
            if [[ -n "$output_file" ]]; then
                generate_csv_report > "$output_file"
                echo -e "${GREEN}CSV report generated: $output_file${RESET}" >&2
            else
                generate_csv_report
            fi
            ;;
        json)
            if [[ -n "$output_file" ]]; then
                generate_json_summary > "$output_file" 
                echo -e "${GREEN}JSON report generated: $output_file${RESET}" >&2
            else
                generate_json_summary
            fi
            ;;
        help|--help|-h)
            echo "Docker Learning Path - Report Generator"
            echo
            echo "Usage:"
            echo "  $0 [format] [output_file]"
            echo
            echo "Formats:"
            echo "  markdown, md    # Detailed markdown report (default)"
            echo "  csv            # CSV export for external analysis" 
            echo "  json           # JSON summary for programmatic use"
            echo
            echo "Examples:"
            echo "  $0                              # Output markdown to stdout"
            echo "  $0 markdown report.md          # Save markdown report"
            echo "  $0 csv progress.csv            # Export CSV data"
            echo "  $0 json summary.json           # Generate JSON summary"
            ;;
        *)
            echo -e "${RED}Unknown format: $output_format${RESET}" >&2
            echo "Use: markdown, csv, json, or --help for usage" >&2
            exit 1
            ;;
    esac
}

main "$@"