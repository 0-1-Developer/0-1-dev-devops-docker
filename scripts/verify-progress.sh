#!/bin/bash
# Docker Learning Path - Progress Verification Script
# Verifies all completed phases and validates learning achievements

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

# Global counters
TOTAL_VERIFICATIONS=0
PASSED_VERIFICATIONS=0
FAILED_VERIFICATIONS=0

log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $1"; ((PASSED_VERIFICATIONS++)); }
log_warning() { echo -e "${YELLOW}[WARNING]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; ((FAILED_VERIFICATIONS++)); }

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing_deps=()
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        echo "Install missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                jq)
                    echo "  - Ubuntu/Debian: sudo apt-get install jq"
                    echo "  - macOS: brew install jq"
                    echo "  - Windows: choco install jq"
                    ;;
                docker)
                    echo "  - Visit: https://docs.docker.com/get-docker/"
                    ;;
            esac
        done
        exit 1
    fi
    
    log_success "All dependencies available"
}

# Verify progress file exists and is valid
verify_progress_file() {
    log_info "Verifying progress file..."
    ((TOTAL_VERIFICATIONS++))
    
    if [[ ! -f "$PROGRESS_FILE" ]]; then
        log_error "Progress file not found: $PROGRESS_FILE"
        return 1
    fi
    
    if ! jq . "$PROGRESS_FILE" &> /dev/null; then
        log_error "Progress file is not valid JSON"
        return 1
    fi
    
    local required_fields=("learner_id" "start_date" "last_updated" "phases")
    for field in "${required_fields[@]}"; do
        if ! jq -e ".$field" "$PROGRESS_FILE" &> /dev/null; then
            log_error "Missing required field in progress file: $field"
            return 1
        fi
    done
    
    log_success "Progress file is valid"
}

# Verify phase directory structure
verify_phase_structure() {
    log_info "Verifying phase directory structure..."
    
    for i in $(seq 0 11); do
        ((TOTAL_VERIFICATIONS++))
        local phase_dir=$(find "$PROJECT_ROOT" -name "$(printf "%02d" $i)-*" -type d | head -1)
        
        if [[ -z "$phase_dir" ]]; then
            log_error "Phase $i directory not found"
            continue
        fi
        
        local required_files=("README.md" "lab.md" "verify.rules.md" "cleanup.rules.md")
        local phase_valid=true
        
        for file in "${required_files[@]}"; do
            if [[ ! -f "$phase_dir/$file" ]]; then
                log_error "Missing file in $(basename "$phase_dir"): $file"
                phase_valid=false
            fi
        done
        
        if $phase_valid; then
            log_success "Phase $(printf "%02d" $i) structure is valid"
        fi
    done
}

# Verify Docker environment
verify_docker_environment() {
    log_info "Verifying Docker environment..."
    ((TOTAL_VERIFICATIONS++))
    
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        return 1
    fi
    
    local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    local min_version="20.10.0"
    
    if ! printf '%s\n%s\n' "$min_version" "$docker_version" | sort -V -C; then
        log_warning "Docker version $docker_version is older than recommended minimum $min_version"
    else
        log_success "Docker environment is ready (version: $docker_version)"
    fi
}

# Verify specific phase completion
verify_phase_completion() {
    local phase_id=$1
    local phase_dir=$2
    
    log_info "Verifying phase $phase_id completion..."
    ((TOTAL_VERIFICATIONS++))
    
    # Check if all lessons are marked complete in progress file
    local completed_lessons=$(jq -r "[.phases[$phase_id].lessons[] | select(.status == \"completed\")] | length" "$PROGRESS_FILE")
    
    if [[ $completed_lessons -ne 4 ]]; then
        log_warning "Phase $phase_id: Only $completed_lessons/4 lessons marked complete"
        return 1
    fi
    
    # Check if verification rules file exists and run basic checks
    local verify_file="$phase_dir/verify.rules.md"
    if [[ ! -f "$verify_file" ]]; then
        log_error "Phase $phase_id: Verification rules file missing"
        return 1
    fi
    
    # Run phase-specific verification if script exists
    local verify_script="$phase_dir/scripts/verify.sh"
    if [[ -f "$verify_script" && -x "$verify_script" ]]; then
        log_info "Running phase $phase_id verification script..."
        
        if cd "$phase_dir" && ./scripts/verify.sh &> /dev/null; then
            log_success "Phase $phase_id verification script passed"
        else
            log_error "Phase $phase_id verification script failed"
            return 1
        fi
        cd "$PROJECT_ROOT"
    fi
    
    log_success "Phase $phase_id completion verified"
}

# Verify all completed phases
verify_completed_phases() {
    log_info "Verifying all completed phases..."
    
    for i in $(seq 0 11); do
        local phase_dir=$(find "$PROJECT_ROOT" -name "$(printf "%02d" $i)-*" -type d | head -1)
        local completed_lessons=$(jq -r "[.phases[$i].lessons[] | select(.status == \"completed\")] | length" "$PROGRESS_FILE" 2>/dev/null || echo "0")
        
        if [[ $completed_lessons -eq 4 ]]; then
            verify_phase_completion $i "$phase_dir"
        fi
    done
}

# Verify lab directory structure
verify_lab_structure() {
    log_info "Verifying lab directory structure..."
    ((TOTAL_VERIFICATIONS++))
    
    local labs_dir="$PROJECT_ROOT/labs"
    if [[ ! -d "$labs_dir" ]]; then
        log_error "Labs directory not found"
        return 1
    fi
    
    local required_subdirs=("integration" "challenges" "experiments")
    for subdir in "${required_subdirs[@]}"; do
        if [[ ! -d "$labs_dir/$subdir" ]]; then
            log_error "Missing lab subdirectory: $subdir"
        else
            log_success "Lab subdirectory exists: $subdir"
        fi
    done
}

# Verify documentation completeness
verify_documentation() {
    log_info "Verifying documentation completeness..."
    ((TOTAL_VERIFICATIONS++))
    
    local docs_dir="$PROJECT_ROOT/docs"
    local required_docs=("FAQ.md" "GLOSSARY.md" "platform-notes.md" "CHANGELOG.md")
    
    for doc in "${required_docs[@]}"; do
        if [[ ! -f "$docs_dir/$doc" ]]; then
            log_error "Missing documentation: $doc"
        else
            # Check if file is not empty
            if [[ ! -s "$docs_dir/$doc" ]]; then
                log_warning "Documentation file is empty: $doc"
            else
                log_success "Documentation complete: $doc"
            fi
        fi
    done
}

# Verify GitHub templates
verify_github_templates() {
    log_info "Verifying GitHub templates..."
    ((TOTAL_VERIFICATIONS++))
    
    local github_dir="$PROJECT_ROOT/.github"
    local template_files=(
        "ISSUE_TEMPLATE/bug_report.yml"
        "ISSUE_TEMPLATE/lesson_improvement.yml" 
        "ISSUE_TEMPLATE/question.yml"
        "PULL_REQUEST_TEMPLATE.md"
    )
    
    for template in "${template_files[@]}"; do
        if [[ ! -f "$github_dir/$template" ]]; then
            log_error "Missing GitHub template: $template"
        else
            log_success "GitHub template exists: $template"
        fi
    done
}

# Generate verification report
generate_report() {
    echo
    echo -e "${BOLD}${BLUE}Verification Summary${RESET}"
    echo "==================="
    echo -e "Total verifications: $TOTAL_VERIFICATIONS"
    echo -e "Passed: ${GREEN}$PASSED_VERIFICATIONS${RESET}"
    echo -e "Failed: ${RED}$FAILED_VERIFICATIONS${RESET}"
    
    local success_rate=$(( (PASSED_VERIFICATIONS * 100) / TOTAL_VERIFICATIONS ))
    echo -e "Success rate: $success_rate%"
    
    if [[ $FAILED_VERIFICATIONS -eq 0 ]]; then
        echo
        echo -e "${GREEN}🎉 All verifications passed! Your learning path is in excellent condition.${RESET}"
    else
        echo
        echo -e "${YELLOW}⚠️  Some verifications failed. Review the errors above.${RESET}"
        return 1
    fi
}

# Main verification function
main() {
    echo -e "${BOLD}${BLUE}Docker Learning Path - Progress Verification${RESET}"
    echo "============================================="
    echo
    
    check_dependencies
    verify_progress_file
    verify_phase_structure
    verify_docker_environment
    verify_completed_phases
    verify_lab_structure
    verify_documentation
    verify_github_templates
    
    generate_report
}

# Handle script arguments
case "${1:-}" in
    --phase)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 --phase <phase_number>"
            exit 1
        fi
        phase_id=$2
        phase_dir=$(find "$PROJECT_ROOT" -name "$(printf "%02d" $phase_id)-*" -type d | head -1)
        if [[ -z "$phase_dir" ]]; then
            echo "Phase $phase_id not found"
            exit 1
        fi
        verify_phase_completion "$phase_id" "$phase_dir"
        ;;
    --help|-h)
        echo "Docker Learning Path - Progress Verification"
        echo
        echo "Usage:"
        echo "  $0                    # Verify all progress"
        echo "  $0 --phase <num>      # Verify specific phase"
        echo "  $0 --help            # Show this help"
        echo
        echo "Examples:"
        echo "  $0 --phase 4         # Verify phase 04"
        echo "  $0                   # Full verification"
        ;;
    *)
        main "$@"
        ;;
esac