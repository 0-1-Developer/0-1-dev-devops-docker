#!/bin/bash
# Docker Learning Path - Content Linting Script
# Checks markdown files for common issues and consistency

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

# Global counters
TOTAL_FILES=0
TOTAL_ISSUES=0
TOTAL_WARNINGS=0

log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[PASS]${RESET} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${RESET} $1"; ((TOTAL_WARNINGS++)); }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; ((TOTAL_ISSUES++)); }

# Check if a file has required front matter
check_frontmatter() {
    local file=$1
    local filename=$(basename "$file")
    
    # Skip certain files that don't need front matter
    case "$filename" in
        "README.md"|"CHANGELOG.md"|"CONTRIBUTING.md"|"LICENSE.md"|"FAQ.md"|"GLOSSARY.md")
            return 0
            ;;
    esac
    
    # Check for basic structure indicators
    if ! head -20 "$file" | grep -q "^#"; then
        log_warning "$file: No main heading found in first 20 lines"
    fi
}

# Check for broken internal links
check_internal_links() {
    local file=$1
    local dir=$(dirname "$file")
    
    # Find markdown links: [text](path)
    grep -n "\\[.*\\](\\./[^)]*)" "$file" 2>/dev/null | while IFS: read -r line_num line; do
        # Extract the link path
        local link=$(echo "$line" | sed -n 's/.*\[.*\](\.\([^)]*\)).*/\1/p')
        
        if [[ -n "$link" ]]; then
            # Remove anchors for file existence check
            local file_path="${link%%#*}"
            local full_path="$PROJECT_ROOT$file_path"
            
            if [[ ! -e "$full_path" ]]; then
                log_error "$file:$line_num: Broken internal link: $link"
            fi
        fi
    done
    
    # Check relative links: [text](../path)
    grep -n "\\[.*\\]([^http][^)]*)" "$file" 2>/dev/null | while IFS: read -r line_num line; do
        local link=$(echo "$line" | sed -n 's/.*\[.*\](\([^)]*\)).*/\1/p')
        
        if [[ "$link" =~ ^\.\./ ]]; then
            local resolved_path=$(cd "$dir" && realpath "$link" 2>/dev/null || echo "")
            
            if [[ -n "$resolved_path" && ! -e "$resolved_path" ]]; then
                log_error "$file:$line_num: Broken relative link: $link"
            fi
        fi
    done
}

# Check for consistent heading structure
check_heading_structure() {
    local file=$1
    local prev_level=0
    local line_num=0
    
    while IFS= read -r line; do
        ((line_num++))
        
        if [[ "$line" =~ ^(#+)[[:space:]] ]]; then
            local current_level=${#BASH_REMATCH[1]}
            
            # Check for skipped heading levels (H1 -> H3)
            if [[ $prev_level -gt 0 && $current_level -gt $((prev_level + 1)) ]]; then
                log_warning "$file:$line_num: Skipped heading level (H$prev_level to H$current_level)"
            fi
            
            prev_level=$current_level
        fi
    done < "$file"
}

# Check for consistent code block formatting
check_code_blocks() {
    local file=$1
    local line_num=0
    local in_code_block=false
    local code_block_lang=""
    
    while IFS= read -r line; do
        ((line_num++))
        
        if [[ "$line" =~ ^\`\`\`(.*)$ ]]; then
            if [[ "$in_code_block" == "true" ]]; then
                # End of code block
                in_code_block=false
                code_block_lang=""
            else
                # Start of code block
                in_code_block=true
                code_block_lang="${BASH_REMATCH[1]}"
                
                # Check for language specification on bash/shell blocks
                if [[ -z "$code_block_lang" ]]; then
                    # Read next few lines to see if it's likely bash/shell
                    local next_lines=$(tail -n +$((line_num + 1)) "$file" | head -5)
                    if echo "$next_lines" | grep -q "^[[:space:]]*[#$] \|^[[:space:]]*docker \|^[[:space:]]*make "; then
                        log_warning "$file:$line_num: Code block should specify language (likely bash)"
                    fi
                fi
            fi
        fi
    done < "$file"
    
    # Check if we ended with an unclosed code block
    if [[ "$in_code_block" == "true" ]]; then
        log_error "$file: Unclosed code block"
    fi
}

# Check for consistent terminology
check_terminology() {
    local file=$1
    local line_num=0
    
    while IFS= read -r line; do
        ((line_num++))
        
        # Check for inconsistent Docker terminology
        if echo "$line" | grep -qi "docker container" && echo "$line" | grep -qi "docker image" && echo "$line" | grep -v "docker container\|docker image"; then
            if echo "$line" | grep -q "docker containers\|docker images"; then
                log_warning "$file:$line_num: Consider consistent terminology: 'containers' vs 'docker containers'"
            fi
        fi
        
        # Check for outdated terminology
        if echo "$line" | grep -q "docker-compose" && ! echo "$line" | grep -q "\`docker-compose\`\|docker-compose\.yml"; then
            log_warning "$file:$line_num: Consider using 'docker compose' (v2) instead of 'docker-compose'"
        fi
        
        # Check for inconsistent command formatting
        if echo "$line" | grep -q "docker [a-z]" && ! echo "$line" | grep -q "\`docker [a-z]"; then
            # Make sure it's not already in a code block context
            if ! echo "$line" | grep -q "^\`\`\`\|^[[:space:]]*docker "; then
                log_warning "$file:$line_num: Docker commands should be in code blocks or inline code"
            fi
        fi
    done < "$file"
}

# Check for proper progress anchor format
check_progress_anchors() {
    local file=$1
    local line_num=0
    
    while IFS= read -r line; do
        ((line_num++))
        
        # Look for progress anchor comments
        if echo "$line" | grep -q "PROGRESS_ANCHOR"; then
            # Check format: <!-- PROGRESS_ANCHOR: pXX-mXX-lXX -->
            if ! echo "$line" | grep -q "<!-- PROGRESS_ANCHOR: p[0-9][0-9]-m[0-9][0-9]-l[0-9][0-9] -->"; then
                log_error "$file:$line_num: Invalid progress anchor format. Use: <!-- PROGRESS_ANCHOR: pXX-mXX-lXX -->"
            fi
        fi
    done < "$file"
}

# Check for file naming consistency
check_file_naming() {
    local file=$1
    local filename=$(basename "$file")
    local dir=$(basename "$(dirname "$file")")
    
    # Check phase directory naming
    if [[ "$dir" =~ ^[0-9]{2}- ]]; then
        # This is a phase directory
        case "$filename" in
            "README.md"|"lab.md"|"verify.rules.md"|"cleanup.rules.md"|"visuals.md")
                # These are expected files
                ;;
            *)
                log_warning "$file: Unexpected file in phase directory: $filename"
                ;;
        esac
    fi
    
    # Check for proper markdown extension
    if [[ "$filename" =~ \.(txt|doc|docx)$ ]]; then
        log_error "$file: Documentation should use .md extension, not .${filename##*.}"
    fi
}

# Check for line length (soft limit)
check_line_length() {
    local file=$1
    local line_num=0
    local max_length=120  # Soft limit for readability
    
    while IFS= read -r line; do
        ((line_num++))
        
        # Skip code blocks and links
        if [[ ${#line} -gt $max_length ]] && ! echo "$line" | grep -q "^\`\`\`\|^[[:space:]]*\`\|http\|^\|"; then
            log_warning "$file:$line_num: Line length ${#line} exceeds $max_length characters"
        fi
    done < "$file"
}

# Check specific file for all issues
lint_file() {
    local file=$1
    ((TOTAL_FILES++))
    
    log_info "Checking $(basename "$file")..."
    
    check_frontmatter "$file"
    check_internal_links "$file" 
    check_heading_structure "$file"
    check_code_blocks "$file"
    check_terminology "$file"
    check_progress_anchors "$file"
    check_file_naming "$file"
    check_line_length "$file"
}

# Find all markdown files to check
find_markdown_files() {
    find "$PROJECT_ROOT" -name "*.md" -type f \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*" \
        ! -path "*/build/*" \
        ! -path "*/dist/*" \
        | sort
}

# Generate summary report
generate_summary() {
    echo
    echo -e "${BOLD}${BLUE}Content Linting Summary${RESET}"
    echo "======================="
    echo -e "Files checked: $TOTAL_FILES"
    echo -e "Issues found: ${RED}$TOTAL_ISSUES${RESET}"
    echo -e "Warnings: ${YELLOW}$TOTAL_WARNINGS${RESET}"
    
    if [[ $TOTAL_ISSUES -eq 0 && $TOTAL_WARNINGS -eq 0 ]]; then
        echo -e "${GREEN}🎉 All content checks passed!${RESET}"
        return 0
    elif [[ $TOTAL_ISSUES -eq 0 ]]; then
        echo -e "${YELLOW}✅ No critical issues, but some warnings to address${RESET}"
        return 0
    else
        echo -e "${RED}❌ Critical issues found that should be addressed${RESET}"
        return 1
    fi
}

# Main function
main() {
    echo -e "${BOLD}${BLUE}Docker Learning Path - Content Linter${RESET}"
    echo "======================================"
    echo
    
    local files_to_check=()
    
    case "${1:-all}" in
        --file|-f)
            if [[ -z "$2" ]]; then
                echo -e "${RED}Error: --file requires a file path${RESET}"
                exit 1
            fi
            files_to_check=("$2")
            ;;
        --phase|-p)
            if [[ -z "$2" ]]; then
                echo -e "${RED}Error: --phase requires a phase number${RESET}"
                exit 1
            fi
            local phase_dir=$(find "$PROJECT_ROOT" -name "$(printf "%02d" "$2")-*" -type d | head -1)
            if [[ -z "$phase_dir" ]]; then
                echo -e "${RED}Error: Phase $2 not found${RESET}"
                exit 1
            fi
            mapfile -t files_to_check < <(find "$phase_dir" -name "*.md" -type f)
            ;;
        --docs|-d)
            mapfile -t files_to_check < <(find "$PROJECT_ROOT/docs" -name "*.md" -type f 2>/dev/null || true)
            ;;
        all|"")
            mapfile -t files_to_check < <(find_markdown_files)
            ;;
        help|--help|-h)
            echo "Docker Learning Path - Content Linter"
            echo
            echo "Usage:"
            echo "  $0                    # Check all markdown files"
            echo "  $0 --file <path>      # Check specific file"
            echo "  $0 --phase <num>      # Check specific phase"
            echo "  $0 --docs            # Check docs directory only"
            echo
            echo "Examples:"
            echo "  $0 --file README.md"
            echo "  $0 --phase 4"
            echo "  $0 --docs"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
    
    if [[ ${#files_to_check[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No markdown files found to check${RESET}"
        exit 0
    fi
    
    # Check each file
    for file in "${files_to_check[@]}"; do
        if [[ -f "$file" ]]; then
            lint_file "$file"
        fi
    done
    
    # Generate summary and exit with appropriate code
    generate_summary
}

main "$@"