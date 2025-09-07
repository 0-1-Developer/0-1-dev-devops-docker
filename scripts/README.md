# Docker Learning Path - Utility Scripts

> **Purpose**: Automation and utility scripts for managing the Docker learning path  
> **Scope**: Progress tracking, validation, reporting, and maintenance tools

## 📁 Script Directory

| Script | Purpose | Usage |
|--------|---------|-------|
| **progress-summary.sh** | Display detailed learning progress | `./progress-summary.sh` |
| **verify-progress.sh** | Verify completed phases and validate achievements | `./verify-progress.sh [--phase N]` |
| **next-step.sh** | Show recommended next learning step | `./next-step.sh` |
| **update-progress.sh** | Update progress tracking from anchors or manual input | `./update-progress.sh [command]` |
| **generate-report.sh** | Generate learning progress reports | `./generate-report.sh [format] [file]` |
| **lint-content.sh** | Check markdown files for issues | `./lint-content.sh [options]` |
| **check-links.sh** | Verify internal links and references | `./check-links.sh [options]` |
| **validate-structure.sh** | Validate repository structure | `./validate-structure.sh [section]` |

## 🚀 Quick Start

```bash
# Make all scripts executable
chmod +x scripts/*.sh

# Check your current progress
./scripts/progress-summary.sh

# Get next step recommendation
./scripts/next-step.sh

# Verify completed work
./scripts/verify-progress.sh
```

## 📊 Progress Management

### `progress-summary.sh`
Displays comprehensive learning progress with visual indicators.

```bash
./scripts/progress-summary.sh
```

**Features:**
- Overall completion percentage with progress bar
- Phase-by-phase breakdown with status icons
- Recent activity tracking
- Next step recommendations
- Badge progress tracking
- Time estimates and learning velocity

**Output Example:**
```
Overall Progress
================
Completed Lessons: 24 / 48
Progress: 50%
Progress Bar: [████████████████░░░░░░░░░░░░░░░░░] 50%

Phase-by-Phase Progress
=======================
Phase 00: ✅ Foundations           ──────── 4/4 (100%)
Phase 01: ✅ Dockerfile Basics     ──────── 4/4 (100%)
Phase 02: 🔄 BuildKit Advanced     ──────── 2/4 (50%)
...
```

### `next-step.sh`
Provides intelligent recommendations for continued learning.

```bash
./scripts/next-step.sh
```

**Features:**
- Identifies next incomplete lesson
- Provides context about current phase
- Shows navigation commands
- Offers motivational messages based on progress
- Suggests relevant labs when ready

### `update-progress.sh`
Manages progress tracking with multiple update methods.

```bash
# Interactive lesson completion
./scripts/update-progress.sh

# Mark specific lesson complete
./scripts/update-progress.sh complete p04-m01-l02

# Scan files for progress anchors
./scripts/update-progress.sh scan

# Initialize progress file
./scripts/update-progress.sh init
```

**Commands:**
- `interactive` (default) - Interactive lesson completion
- `complete <lesson-id>` - Mark specific lesson complete
- `scan` - Scan files for progress anchor comments
- `stats` - Update statistics only
- `init` - Initialize progress file
- `reset` - Reset all progress (with confirmation)

## ✅ Validation & Quality

### `verify-progress.sh`
Comprehensive verification of learning achievements.

```bash
# Verify all completed phases
./scripts/verify-progress.sh

# Verify specific phase
./scripts/verify-progress.sh --phase 4
```

**Validation Checks:**
- Progress file integrity
- Phase directory structure
- Docker environment readiness
- Phase completion criteria
- Verification script execution

### `lint-content.sh`
Content quality and consistency checker.

```bash
# Check all files
./scripts/lint-content.sh

# Check specific file
./scripts/lint-content.sh --file README.md

# Check specific phase
./scripts/lint-content.sh --phase 4

# Check docs only
./scripts/lint-content.sh --docs
```

**Lint Checks:**
- Markdown structure and headings
- Code block formatting and language tags
- Internal link validity
- Terminology consistency
- Progress anchor format
- Line length recommendations

### `check-links.sh`
Link validation and cross-reference checking.

```bash
# Check internal links only (fast)
./scripts/check-links.sh

# Include external link checking (slow)
./scripts/check-links.sh --external

# Check specific phase
./scripts/check-links.sh --phase 4
```

**Link Checks:**
- Internal markdown links
- Cross-references between phases
- Anchor existence validation
- Documentation index consistency
- Optional external link validation

### `validate-structure.sh`
Repository structure validation against requirements.

```bash
# Validate entire structure
./scripts/validate-structure.sh

# Validate specific sections
./scripts/validate-structure.sh --phases
./scripts/validate-structure.sh --docs
./scripts/validate-structure.sh --github
```

**Structure Validation:**
- Root directory requirements
- Phase directory structure and naming
- Documentation completeness
- GitHub template existence
- Labs and solutions organization
- File naming conventions
- Permission validation

## 📈 Reporting

### `generate-report.sh`
Multi-format progress reporting for analysis and sharing.

```bash
# Generate markdown report (default)
./scripts/generate-report.sh

# Save to file
./scripts/generate-report.sh markdown progress-report.md

# Generate CSV export
./scripts/generate-report.sh csv progress.csv

# Generate JSON summary
./scripts/generate-report.sh json summary.json
```

**Report Formats:**
- **Markdown**: Detailed human-readable report
- **CSV**: Tabular data for spreadsheet analysis
- **JSON**: Machine-readable summary for APIs

**Report Content:**
- Overall progress statistics
- Phase-by-phase completion status
- Achievement badges and milestones
- Learning analytics and velocity
- Time estimates and recommendations
- Recent activity timeline

## 🛠️ Integration with Makefile

All scripts integrate with the main Makefile for easy access:

```bash
# Progress management
make progress          # Run progress-summary.sh
make next             # Run next-step.sh
make verify           # Run verify-progress.sh

# Quality assurance
make lint             # Run lint-content.sh
make check-links      # Run check-links.sh
make validate-structure  # Run validate-structure.sh

# Maintenance
make update-progress  # Run update-progress.sh interactive
make generate-report  # Run generate-report.sh
```

## 🔧 Script Dependencies

### Required Tools
- **bash** 4.0+ - Shell scripting environment
- **jq** - JSON processing (`sudo apt install jq` or `brew install jq`)
- **find** - File system navigation (standard on Unix systems)
- **grep** - Text searching (standard on Unix systems)

### Optional Tools
- **curl** - External link checking (for `check-links.sh --external`)
- **bc** - Mathematical calculations for advanced statistics
- **realpath** - Path resolution (standard on modern systems)

### Dependency Checking
All scripts include automatic dependency checking and will provide installation instructions for missing tools.

## 📝 Script Development

### Adding New Scripts
1. Follow the existing naming convention: `action-target.sh`
2. Include proper shebang: `#!/bin/bash`
3. Use consistent color coding and logging functions
4. Add help text with `--help` flag support
5. Include dependency checking
6. Make executable: `chmod +x scripts/new-script.sh`
7. Update this README and the main Makefile

### Common Patterns

```bash
#!/bin/bash
set -e  # Exit on error

# Standard color definitions
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'
BOLD='\033[1m'

# Standard logging functions
log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }

# Dependency checking template
check_dependencies() {
    local missing_deps=()
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

# Help text template
show_help() {
    echo "Script Name - Brief Description"
    echo
    echo "Usage:"
    echo "  $0 [options]"
    echo
    echo "Options:"
    echo "  --help, -h    Show this help"
    echo
    echo "Examples:"
    echo "  $0           # Default behavior"
}
```

## 🐛 Troubleshooting

### Common Issues

**Permission Denied**
```bash
# Fix: Make scripts executable
chmod +x scripts/*.sh
```

**jq Not Found**
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# Windows (with Chocolatey)
choco install jq
```

**Progress File Missing**
```bash
# Initialize progress tracking
./scripts/update-progress.sh init
```

**Script Won't Run**
```bash
# Check shebang and line endings
head -1 scripts/script-name.sh
file scripts/script-name.sh
```

### Debug Mode
Most scripts support verbose output for debugging:

```bash
# Enable debug mode
BASH_DEBUG=1 ./scripts/script-name.sh

# Or use bash debugging
bash -x ./scripts/script-name.sh
```

## 🔄 Maintenance

### Regular Tasks
- Run `./scripts/validate-structure.sh` after major changes
- Use `./scripts/lint-content.sh` before committing content
- Update progress tracking with `./scripts/update-progress.sh scan`
- Generate reports periodically for progress tracking

### Script Updates
Scripts are designed to be self-maintaining but may need updates when:
- New phases are added
- Progress tracking format changes
- New validation requirements are added
- Dependencies change

---

💡 **Tip**: Use `make help` to see all available commands, including script shortcuts integrated into the main Makefile.