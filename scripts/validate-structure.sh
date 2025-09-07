#!/bin/bash
# Docker Learning Path - Structure Validation Script
# Validates repository structure against curriculum requirements

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'
BOLD='\033[1m'

# Global validation counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${RESET} $1"; ((PASSED_CHECKS++)); }
log_fail() { echo -e "${RED}[FAIL]${RESET} $1"; ((FAILED_CHECKS++)); }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; ((WARNING_CHECKS++)); }

# Increment total check counter
check() { ((TOTAL_CHECKS++)); }

# Validate root directory structure
validate_root_structure() {
    log_info "Validating root directory structure..."
    
    local required_files=(
        "README.md"
        "CLAUDE.md"
        "Makefile"
        ".github"
        "docs"
        "scripts"
        "labs"
        "solutions"
    )
    
    for item in "${required_files[@]}"; do
        check
        if [[ -e "$PROJECT_ROOT/$item" ]]; then
            log_pass "Root structure: $item exists"
        else
            log_fail "Root structure: Missing required $item"
        fi
    done
    
    # Check for unexpected files at root level
    local unexpected_files=(
        "package.json"
        "yarn.lock"
        "node_modules"
        ".DS_Store"
        "Thumbs.db"
        "desktop.ini"
    )
    
    for item in "${unexpected_files[@]}"; do
        if [[ -e "$PROJECT_ROOT/$item" ]]; then
            log_warn "Root structure: Unexpected file/directory: $item"
        fi
    done
}

# Validate phase directory structure
validate_phase_structure() {
    log_info "Validating phase directory structure..."
    
    local expected_phases=(00 01 02 03 04 05 06 07 08 09 10 11)
    local required_phase_files=(
        "README.md"
        "lab.md" 
        "verify.rules.md"
        "cleanup.rules.md"
        "visuals.md"
    )
    
    for phase_num in "${expected_phases[@]}"; do
        local phase_dir=$(find "$PROJECT_ROOT" -name "$phase_num-*" -type d | head -1)
        
        check
        if [[ -z "$phase_dir" ]]; then
            log_fail "Phase structure: Phase $phase_num directory not found"
            continue
        else
            log_pass "Phase structure: Phase $phase_num directory exists"
        fi
        
        # Check phase directory naming convention
        local dir_name=$(basename "$phase_dir")
        if [[ ! "$dir_name" =~ ^[0-9]{2}-[a-z-]+$ ]]; then
            log_warn "Phase structure: $dir_name doesn't follow naming convention (XX-lowercase-with-dashes)"
        fi
        
        # Check required files in each phase
        for file in "${required_phase_files[@]}"; do
            check
            if [[ -f "$phase_dir/$file" ]]; then
                log_pass "Phase $phase_num: $file exists"
                
                # Basic content validation
                if [[ ! -s "$phase_dir/$file" ]]; then
                    log_warn "Phase $phase_num: $file is empty"
                fi
                
                # Check for minimum content requirements
                case "$file" in
                    "README.md")
                        if ! grep -q "^# " "$phase_dir/$file"; then
                            log_warn "Phase $phase_num: README.md missing main heading"
                        fi
                        if ! grep -qi "learning objective" "$phase_dir/$file"; then
                            log_warn "Phase $phase_num: README.md missing learning objectives"
                        fi
                        ;;
                    "lab.md")
                        if ! grep -q "^# " "$phase_dir/$file"; then
                            log_warn "Phase $phase_num: lab.md missing main heading"
                        fi
                        if ! grep -q '```' "$phase_dir/$file"; then
                            log_warn "Phase $phase_num: lab.md missing code blocks"
                        fi
                        ;;
                    "verify.rules.md")
                        if ! grep -qi "verification\|success\|criteria" "$phase_dir/$file"; then
                            log_warn "Phase $phase_num: verify.rules.md missing verification criteria"
                        fi
                        ;;
                esac
            else
                log_fail "Phase $phase_num: Missing required file $file"
            fi
        done
        
        # Check for optional but recommended files
        local optional_files=("scripts" "examples" "assets")
        for optional in "${optional_files[@]}"; do
            if [[ -e "$phase_dir/$optional" ]]; then
                log_pass "Phase $phase_num: Optional $optional directory present"
            fi
        done
        
        # Check for unexpected files
        find "$phase_dir" -maxdepth 1 -type f | while read -r file; do
            local filename=$(basename "$file")
            case "$filename" in
                *.md|*.sh|*.yml|*.yaml|*.json|*.txt|*.dockerfile|Dockerfile)
                    # These are acceptable
                    ;;
                *)
                    log_warn "Phase $phase_num: Unexpected file: $filename"
                    ;;
            esac
        done
    done
}

# Validate documentation structure
validate_docs_structure() {
    log_info "Validating docs directory structure..."
    
    local required_docs=(
        "PROGRESS.json"
        "FAQ.md"
        "GLOSSARY.md"
        "CHANGELOG.md"
        "platform-notes.md"
        "badges"
    )
    
    for doc in "${required_docs[@]}"; do
        check
        if [[ -e "$PROJECT_ROOT/docs/$doc" ]]; then
            log_pass "Docs: $doc exists"
            
            # Validate JSON structure
            if [[ "$doc" == "PROGRESS.json" ]]; then
                if command -v jq &> /dev/null; then
                    if jq . "$PROJECT_ROOT/docs/$doc" &> /dev/null; then
                        log_pass "Docs: PROGRESS.json is valid JSON"
                    else
                        log_fail "Docs: PROGRESS.json is invalid JSON"
                    fi
                fi
            fi
        else
            log_fail "Docs: Missing required $doc"
        fi
    done
    
    # Validate badges directory structure
    if [[ -d "$PROJECT_ROOT/docs/badges" ]]; then
        check
        if [[ -f "$PROJECT_ROOT/docs/badges/README.md" ]]; then
            log_pass "Docs: badges/README.md exists"
        else
            log_fail "Docs: badges/README.md missing"
        fi
    fi
}

# Validate GitHub templates
validate_github_structure() {
    log_info "Validating GitHub templates structure..."
    
    local required_templates=(
        "ISSUE_TEMPLATE"
        "PULL_REQUEST_TEMPLATE.md"
    )
    
    for template in "${required_templates[@]}"; do
        check
        if [[ -e "$PROJECT_ROOT/.github/$template" ]]; then
            log_pass "GitHub: $template exists"
        else
            log_fail "GitHub: Missing $template"
        fi
    done
    
    # Check issue templates
    if [[ -d "$PROJECT_ROOT/.github/ISSUE_TEMPLATE" ]]; then
        local issue_templates=(
            "bug_report.yml"
            "lesson_improvement.yml"
            "question.yml"
            "visual_request.yml"
        )
        
        for template in "${issue_templates[@]}"; do
            check
            if [[ -f "$PROJECT_ROOT/.github/ISSUE_TEMPLATE/$template" ]]; then
                log_pass "GitHub: Issue template $template exists"
            else
                log_warn "GitHub: Missing issue template $template"
            fi
        done
    fi
}

# Validate labs structure
validate_labs_structure() {
    log_info "Validating labs directory structure..."
    
    local required_lab_dirs=(
        "integration"
        "challenges" 
        "experiments"
        "industry"
    )
    
    check
    if [[ -d "$PROJECT_ROOT/labs" ]]; then
        log_pass "Labs: Directory exists"
        
        check
        if [[ -f "$PROJECT_ROOT/labs/README.md" ]]; then
            log_pass "Labs: README.md exists"
        else
            log_fail "Labs: README.md missing"
        fi
        
        for lab_dir in "${required_lab_dirs[@]}"; do
            check
            if [[ -d "$PROJECT_ROOT/labs/$lab_dir" ]]; then
                log_pass "Labs: $lab_dir directory exists"
            else
                log_warn "Labs: $lab_dir directory missing"
            fi
        done
    else
        log_fail "Labs: Directory missing"
    fi
}

# Validate solutions structure  
validate_solutions_structure() {
    log_info "Validating solutions directory structure..."
    
    check
    if [[ -d "$PROJECT_ROOT/solutions" ]]; then
        log_pass "Solutions: Directory exists"
        
        check
        if [[ -f "$PROJECT_ROOT/solutions/README.md" ]]; then
            log_pass "Solutions: README.md exists"
        else
            log_fail "Solutions: README.md missing"
        fi
        
        # Check for phase-specific solution directories
        local phase_solutions=0
        for i in $(seq 0 11); do
            local phase_solution_dir=$(find "$PROJECT_ROOT/solutions" -name "phase-$(printf "%02d" $i)-*" -type d | head -1)
            if [[ -n "$phase_solution_dir" ]]; then
                ((phase_solutions++))
            fi
        done
        
        if [[ $phase_solutions -gt 0 ]]; then
            log_pass "Solutions: $phase_solutions phase solution directories found"
        else
            log_warn "Solutions: No phase solution directories found"
        fi
    else
        log_fail "Solutions: Directory missing"
    fi
}

# Validate scripts structure
validate_scripts_structure() {
    log_info "Validating scripts directory structure..."
    
    check
    if [[ -d "$PROJECT_ROOT/scripts" ]]; then
        log_pass "Scripts: Directory exists"
        
        local expected_scripts=(
            "progress-summary.sh"
            "verify-progress.sh"
            "next-step.sh"
            "update-progress.sh"
            "generate-report.sh"
            "lint-content.sh"
            "check-links.sh"
            "validate-structure.sh"
        )
        
        for script in "${expected_scripts[@]}"; do
            check
            if [[ -f "$PROJECT_ROOT/scripts/$script" ]]; then
                log_pass "Scripts: $script exists"
                
                # Check if script is executable
                if [[ -x "$PROJECT_ROOT/scripts/$script" ]]; then
                    log_pass "Scripts: $script is executable"
                else
                    log_warn "Scripts: $script is not executable"
                fi
                
                # Check shebang
                if head -1 "$PROJECT_ROOT/scripts/$script" | grep -q "^#!/bin/bash"; then
                    log_pass "Scripts: $script has bash shebang"
                else
                    log_warn "Scripts: $script missing or incorrect shebang"
                fi
            else
                log_warn "Scripts: Missing utility script $script"
            fi
        done
    else
        log_fail "Scripts: Directory missing"
    fi
}

# Validate file naming conventions
validate_naming_conventions() {
    log_info "Validating naming conventions..."
    
    # Check phase directory names
    find "$PROJECT_ROOT" -maxdepth 1 -name "[0-9][0-9]-*" -type d | while read -r dir; do
        local dirname=$(basename "$dir")
        check
        if [[ "$dirname" =~ ^[0-9]{2}-[a-z][a-z0-9-]*$ ]]; then
            log_pass "Naming: $dirname follows phase naming convention"
        else
            log_fail "Naming: $dirname violates phase naming convention"
        fi
    done
    
    # Check for spaces in filenames (not allowed)
    find "$PROJECT_ROOT" -name "* *" -type f | while read -r file; do
        log_warn "Naming: File with spaces: $(basename "$file")"
    done
    
    # Check for uppercase in directory names
    find "$PROJECT_ROOT" -name "*[A-Z]*" -type d | while read -r dir; do
        local dirname=$(basename "$dir")
        case "$dirname" in
            "README.md"|"CHANGELOG.md"|"FAQ.md"|"GLOSSARY.md"|"CLAUDE.md"|"ISSUE_TEMPLATE"|"PULL_REQUEST_TEMPLATE")
                # These are acceptable
                ;;
            *)
                log_warn "Naming: Uppercase in directory name: $dirname"
                ;;
        esac
    done
}

# Check file permissions
validate_permissions() {
    log_info "Validating file permissions..."
    
    # Scripts should be executable
    find "$PROJECT_ROOT/scripts" -name "*.sh" -type f | while read -r script; do
        check
        if [[ -x "$script" ]]; then
            log_pass "Permissions: $(basename "$script") is executable"
        else
            log_warn "Permissions: $(basename "$script") should be executable"
        fi
    done
    
    # Markdown files should not be executable
    find "$PROJECT_ROOT" -name "*.md" -type f | while read -r md_file; do
        if [[ -x "$md_file" ]]; then
            log_warn "Permissions: $(basename "$md_file") should not be executable"
        fi
    done
}

# Validate content consistency
validate_content_consistency() {
    log_info "Validating content consistency..."
    
    # Check that phase count matches in various places
    local actual_phases=$(find "$PROJECT_ROOT" -name "[0-9][0-9]-*" -type d | wc -l)
    
    if [[ -f "$PROJECT_ROOT/README.md" ]]; then
        check
        if grep -q "12.*phase" "$PROJECT_ROOT/README.md" || grep -q "Phase.*11" "$PROJECT_ROOT/README.md"; then
            log_pass "Content: README.md mentions correct number of phases"
        else
            log_warn "Content: README.md may have incorrect phase count"
        fi
    fi
    
    if [[ -f "$PROJECT_ROOT/docs/PROGRESS.json" ]] && command -v jq &> /dev/null; then
        check
        local json_phases=$(jq -r '.phases | length' "$PROJECT_ROOT/docs/PROGRESS.json" 2>/dev/null || echo "0")
        if [[ "$json_phases" -eq "$actual_phases" ]]; then
            log_pass "Content: PROGRESS.json has correct number of phases"
        else
            log_fail "Content: PROGRESS.json has $json_phases phases, expected $actual_phases"
        fi
    fi
}

# Generate validation report
generate_validation_report() {
    echo
    echo -e "${BOLD}${BLUE}Structure Validation Summary${RESET}"
    echo "============================"
    echo -e "Total checks: $TOTAL_CHECKS"
    echo -e "Passed: ${GREEN}$PASSED_CHECKS${RESET}"
    echo -e "Failed: ${RED}$FAILED_CHECKS${RESET}"
    echo -e "Warnings: ${YELLOW}$WARNING_CHECKS${RESET}"
    
    local success_rate=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
    echo -e "Success rate: $success_rate%"
    
    echo
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        if [[ $WARNING_CHECKS -eq 0 ]]; then
            echo -e "${GREEN}🎉 Repository structure is perfect!${RESET}"
            return 0
        else
            echo -e "${GREEN}✅ Repository structure is valid with minor warnings${RESET}"
            return 0
        fi
    else
        echo -e "${RED}❌ Repository structure has critical issues that need to be addressed${RESET}"
        echo
        echo "Common fixes:"
        echo "• Run 'make setup' to initialize missing files"
        echo "• Check phase directory naming: XX-lowercase-with-dashes"
        echo "• Ensure all required markdown files exist in each phase"
        echo "• Validate JSON files with 'jq . filename.json'"
        return 1
    fi
}

# Main validation function
main() {
    echo -e "${BOLD}${BLUE}Docker Learning Path - Structure Validator${RESET}"
    echo "==========================================="
    echo
    
    case "${1:-all}" in
        --root|-r)
            validate_root_structure
            ;;
        --phases|-p)
            validate_phase_structure
            ;;
        --docs|-d)
            validate_docs_structure
            ;;
        --github|-g)
            validate_github_structure
            ;;
        --labs|-l)
            validate_labs_structure
            ;;
        --solutions|-s)
            validate_solutions_structure
            ;;
        --scripts)
            validate_scripts_structure
            ;;
        all|"")
            validate_root_structure
            validate_phase_structure
            validate_docs_structure
            validate_github_structure
            validate_labs_structure
            validate_solutions_structure
            validate_scripts_structure
            validate_naming_conventions
            validate_permissions
            validate_content_consistency
            ;;
        help|--help|-h)
            echo "Docker Learning Path - Structure Validator"
            echo
            echo "Usage:"
            echo "  $0 [section]         # Validate specific section or all"
            echo
            echo "Sections:"
            echo "  --root, -r           # Root directory structure"
            echo "  --phases, -p         # Phase directories"
            echo "  --docs, -d          # Documentation structure"
            echo "  --github, -g        # GitHub templates"
            echo "  --labs, -l          # Labs directory"
            echo "  --solutions, -s     # Solutions directory"
            echo "  --scripts           # Scripts directory"
            echo
            echo "Examples:"
            echo "  $0                  # Validate everything"
            echo "  $0 --phases         # Only validate phase structure"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown section: $1${RESET}"
            echo "Use --help for available sections"
            exit 1
            ;;
    esac
    
    generate_validation_report
}

main "$@"