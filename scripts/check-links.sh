#!/bin/bash
# Docker Learning Path - Link Checker Script  
# Verifies internal links and references across all documentation

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
TOTAL_LINKS=0
BROKEN_LINKS=0
EXTERNAL_LINKS=0
INTERNAL_LINKS=0

log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[PASS]${RESET} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; ((BROKEN_LINKS++)); }

# Extract all markdown links from a file
extract_links() {
    local file=$1
    
    # Find all markdown links: [text](url)
    grep -oE '\[([^\]]*)\]\(([^)]+)\)' "$file" 2>/dev/null | while read -r match; do
        local url=$(echo "$match" | sed -n 's/.*](\([^)]*\)).*/\1/p')
        echo "$url"
    done
}

# Check if an internal link exists
check_internal_link() {
    local file=$1
    local link=$2
    local line_num=$3
    
    ((INTERNAL_LINKS++))
    ((TOTAL_LINKS++))
    
    # Handle different types of internal links
    local target_path=""
    local anchor=""
    
    # Split link into path and anchor
    if [[ "$link" =~ ^([^#]*)#(.*)$ ]]; then
        target_path="${BASH_REMATCH[1]}"
        anchor="${BASH_REMATCH[2]}"
    else
        target_path="$link"
    fi
    
    # Resolve relative paths
    local file_dir=$(dirname "$file")
    local resolved_path=""
    
    case "$target_path" in
        "")
            # Anchor-only link (same file)
            resolved_path="$file"
            ;;
        ./*)
            # Relative to current directory
            resolved_path="$PROJECT_ROOT/${target_path#./}"
            ;;
        ../*)
            # Relative to parent directory
            resolved_path=$(cd "$file_dir" && realpath "$target_path" 2>/dev/null || echo "")
            ;;
        /*)
            # Absolute path from project root
            resolved_path="$PROJECT_ROOT$target_path"
            ;;
        *)
            # Relative path
            resolved_path="$file_dir/$target_path"
            ;;
    esac
    
    # Check if target file exists
    if [[ -n "$resolved_path" && ! -e "$resolved_path" ]]; then
        log_error "$(basename "$file"):$line_num: Broken link: $link -> $resolved_path"
        return 1
    fi
    
    # If there's an anchor, check if it exists (basic check for headers)
    if [[ -n "$anchor" && -f "$resolved_path" ]]; then
        # Convert anchor to possible header formats
        local header_variations=(
            "# $anchor"
            "## $anchor"  
            "### $anchor"
            "#### $anchor"
            "# ${anchor//-/ }"
            "## ${anchor//-/ }"
            "### ${anchor//-/ }"
            "#### ${anchor//-/ }"
        )
        
        local anchor_found=false
        for header in "${header_variations[@]}"; do
            if grep -qi "^$header" "$resolved_path" 2>/dev/null; then
                anchor_found=true
                break
            fi
        done
        
        # Also check for HTML anchors and IDs
        if ! $anchor_found; then
            if grep -qi "id=[\"']$anchor[\"']\|name=[\"']$anchor[\"']" "$resolved_path" 2>/dev/null; then
                anchor_found=true
            fi
        fi
        
        if ! $anchor_found; then
            log_warning "$(basename "$file"):$line_num: Anchor not found: $anchor in $target_path"
        fi
    fi
    
    return 0
}

# Check if external link is reachable (optional)
check_external_link() {
    local file=$1
    local link=$2
    local line_num=$3
    
    ((EXTERNAL_LINKS++))
    ((TOTAL_LINKS++))
    
    # Skip external link checking by default (can be slow)
    if [[ "${CHECK_EXTERNAL:-false}" == "true" ]]; then
        if command -v curl &> /dev/null; then
            if ! curl -s --head --fail "$link" &> /dev/null; then
                log_warning "$(basename "$file"):$line_num: External link may be unreachable: $link"
            fi
        fi
    fi
}

# Check all links in a file
check_file_links() {
    local file=$1
    local line_num=0
    
    log_info "Checking links in $(basename "$file")..."
    
    while IFS= read -r line; do
        ((line_num++))
        
        # Find all markdown links in this line
        echo "$line" | grep -oE '\[([^\]]*)\]\(([^)]+)\)' 2>/dev/null | while read -r match; do
            local url=$(echo "$match" | sed -n 's/.*](\([^)]*\)).*/\1/p')
            
            if [[ "$url" =~ ^https?:// ]]; then
                # External link
                check_external_link "$file" "$url" "$line_num"
            elif [[ "$url" =~ ^mailto: ]]; then
                # Email link - skip
                ((TOTAL_LINKS++))
            else
                # Internal link
                check_internal_link "$file" "$url" "$line_num"
            fi
        done
    done < "$file"
}

# Check for common reference patterns
check_reference_patterns() {
    local file=$1
    local line_num=0
    
    while IFS= read -r line; do
        ((line_num++))
        
        # Check for phase references like "Phase 04" without links
        if echo "$line" | grep -q "Phase [0-9][0-9]" && ! echo "$line" | grep -q "\[.*Phase [0-9][0-9].*\]"; then
            local phase_num=$(echo "$line" | grep -o "Phase [0-9][0-9]" | grep -o "[0-9][0-9]")
            local phase_dir=$(find "$PROJECT_ROOT" -name "$phase_num-*" -type d | head -1)
            
            if [[ -n "$phase_dir" ]]; then
                log_info "$(basename "$file"):$line_num: Consider linking Phase $phase_num reference"
            fi
        fi
        
        # Check for file references that could be linked
        if echo "$line" | grep -qE '`[^`]*\.md`' && ! echo "$line" | grep -q '\[.*\.md.*\]'; then
            log_info "$(basename "$file"):$line_num: Consider linking markdown file reference"
        fi
    done < "$file"
}

# Verify cross-references between phases
check_cross_references() {
    log_info "Checking cross-references between phases..."
    
    # Find all phase directories
    local phase_dirs=($(find "$PROJECT_ROOT" -name "[0-9][0-9]-*" -type d | sort))
    
    for phase_dir in "${phase_dirs[@]}"; do
        local phase_num=$(basename "$phase_dir" | grep -oE '^[0-9]{2}')
        
        # Check if this phase references other phases
        for md_file in "$phase_dir"/*.md; do
            if [[ -f "$md_file" ]]; then
                # Look for references to other phases
                grep -n "Phase [0-9][0-9]" "$md_file" 2>/dev/null | while IFS: read -r line_num line; do
                    local ref_phase=$(echo "$line" | grep -o "Phase [0-9][0-9]" | grep -o "[0-9][0-9]")
                    
                    if [[ "$ref_phase" != "$phase_num" ]]; then
                        # Check if the referenced phase exists
                        local ref_phase_dir=$(find "$PROJECT_ROOT" -name "$ref_phase-*" -type d | head -1)
                        
                        if [[ -z "$ref_phase_dir" ]]; then
                            log_error "$(basename "$md_file"):$line_num: Reference to non-existent Phase $ref_phase"
                        fi
                    fi
                done
            fi
        done
    done
}

# Check documentation index consistency
check_doc_index() {
    log_info "Checking documentation index consistency..."
    
    local readme_file="$PROJECT_ROOT/README.md"
    if [[ ! -f "$readme_file" ]]; then
        log_error "Main README.md not found"
        return
    fi
    
    # Check if all phases are mentioned in main README
    local phase_dirs=($(find "$PROJECT_ROOT" -name "[0-9][0-9]-*" -type d | sort))
    
    for phase_dir in "${phase_dirs[@]}"; do
        local phase_num=$(basename "$phase_dir" | grep -oE '^[0-9]{2}')
        local phase_name=$(basename "$phase_dir" | sed 's/^[0-9][0-9]-//' | tr '-' ' ')
        
        if ! grep -q "Phase.*$phase_num\|$phase_name" "$readme_file"; then
            log_warning "Main README may be missing reference to Phase $phase_num"
        fi
    done
}

# Generate link report
generate_report() {
    echo
    echo -e "${BOLD}${BLUE}Link Check Summary${RESET}"
    echo "=================="
    echo -e "Total links checked: $TOTAL_LINKS"
    echo -e "Internal links: $INTERNAL_LINKS"  
    echo -e "External links: $EXTERNAL_LINKS"
    echo -e "Broken links: ${RED}$BROKEN_LINKS${RESET}"
    
    if [[ $BROKEN_LINKS -eq 0 ]]; then
        echo -e "${GREEN}🎉 All links are valid!${RESET}"
        return 0
    else
        echo -e "${RED}❌ $BROKEN_LINKS broken links found${RESET}"
        return 1
    fi
}

# Main function
main() {
    echo -e "${BOLD}${BLUE}Docker Learning Path - Link Checker${RESET}"
    echo "===================================="
    echo
    
    local files_to_check=()
    local check_external=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --external|-e)
                check_external=true
                export CHECK_EXTERNAL=true
                shift
                ;;
            --file|-f)
                if [[ -z "$2" ]]; then
                    echo -e "${RED}Error: --file requires a file path${RESET}"
                    exit 1
                fi
                files_to_check=("$2")
                shift 2
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
                shift 2
                ;;
            --docs|-d)
                mapfile -t files_to_check < <(find "$PROJECT_ROOT/docs" -name "*.md" -type f 2>/dev/null || true)
                shift
                ;;
            help|--help|-h)
                echo "Docker Learning Path - Link Checker"
                echo
                echo "Usage:"
                echo "  $0 [options]"
                echo
                echo "Options:"
                echo "  --external, -e        Also check external links (slow)"
                echo "  --file <path>, -f     Check specific file"
                echo "  --phase <num>, -p     Check specific phase"
                echo "  --docs, -d           Check docs directory only"
                echo
                echo "Examples:"
                echo "  $0                    # Check all internal links"
                echo "  $0 --external         # Check all links including external"
                echo "  $0 --file README.md   # Check specific file"
                echo "  $0 --phase 4         # Check phase 4 files"
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${RESET}"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # If no specific files specified, check all markdown files
    if [[ ${#files_to_check[@]} -eq 0 ]]; then
        mapfile -t files_to_check < <(find "$PROJECT_ROOT" -name "*.md" -type f \
            ! -path "*/node_modules/*" \
            ! -path "*/.git/*" \
            | sort)
    fi
    
    if [[ ${#files_to_check[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No markdown files found to check${RESET}"
        exit 0
    fi
    
    if [[ "$check_external" == "true" ]]; then
        log_info "External link checking enabled (this may take longer)"
    fi
    
    # Check links in each file
    for file in "${files_to_check[@]}"; do
        if [[ -f "$file" ]]; then
            check_file_links "$file"
            check_reference_patterns "$file"
        fi
    done
    
    # Additional checks
    check_cross_references
    check_doc_index
    
    # Generate final report
    generate_report
}

main "$@"