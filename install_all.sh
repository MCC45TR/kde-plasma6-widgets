#!/usr/bin/env bash
set -Eeuo pipefail

IFS=$'\n\t'

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids"
readonly NOTIFY_DIR="$HOME/.local/share/knotifications6"

available_widgets=(
    "digital-clock"
    "analog-clock"
    "music-player"
    "calendar"
    "events"
    "weather"
    "battery"
    "photos"
    "spotify"
    "world-clock"
    "alarms"
    "aur-updates"
    "notes"
    "control-center"
    "system-monitor"
    "plasma-mselectivereboot"
    "minimal-analog-clock"
    "file-search"
    "browser-search"
    "app-menu"
    "msi-control"
    "AFAD-earthquick-reports"
    "dynamic-color-scheme"
)

install_targets=()
test_target=""
use_prasmoid_build=false
compile_translations=true
dry_run=false

ok_widgets=()
failed_widgets=()
skipped_widgets=()
warn_count=0

if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    bold="$(tput bold)"
    dim="$(tput dim)"
    red="$(tput setaf 1)"
    green="$(tput setaf 2)"
    yellow="$(tput setaf 3)"
    blue="$(tput setaf 4)"
    reset="$(tput sgr0)"
else
    bold=""
    dim=""
    red=""
    green=""
    yellow=""
    blue=""
    reset=""
fi

usage() {
    cat <<EOF
${bold}Plasma 6 Widgets installer${reset}

Usage:
  ./${SCRIPT_NAME} [options] [widget...]

Options:
  -h, --help             Show this help text
  -l, --list             List available widgets
  -t, --test <widget>    Install widget, then launch it with plasmawindowed
      --prasmoid         Run 'prasmoid build' before installing each widget
      --no-translations  Skip .po -> .mo compilation
      --dry-run          Validate and print planned actions without installing

Examples:
  ./${SCRIPT_NAME}
  ./${SCRIPT_NAME} weather battery
  ./${SCRIPT_NAME} --prasmoid file-search
  ./${SCRIPT_NAME} --test msi-control
  ./${SCRIPT_NAME} --dry-run file-search

Available widgets:
EOF
    printf '  - %s\n' "${available_widgets[@]}"
}

log() {
    printf '%b\n' "$*"
}

info() {
    log "${blue}==>${reset} $*"
}

success() {
    log "  ${green}✓${reset} $*"
}

warn() {
    warn_count=$((warn_count + 1))
    log "  ${yellow}!${reset} $*" >&2
}

error() {
    log "  ${red}✗${reset} $*" >&2
}

join_words() {
    local IFS=" "
    printf '%s' "$*"
}

die() {
    error "$*"
    exit 1
}

has_widget() {
    local candidate="$1"
    local widget
    for widget in "${available_widgets[@]}"; do
        [[ "$widget" == "$candidate" ]] && return 0
    done
    return 1
}

append_unique_target() {
    local candidate="$1"
    local existing
    for existing in "${install_targets[@]}"; do
        [[ "$existing" == "$candidate" ]] && return 0
    done
    install_targets+=("$candidate")
}

list_widgets() {
    log "${bold}Available widgets (${#available_widgets[@]}):${reset}"
    printf '  %s\n' "${available_widgets[@]}"
}

require_command() {
    local command_name="$1"
    local package_hint="${2:-}"
    if ! command -v "$command_name" >/dev/null 2>&1; then
        if [[ -n "$package_hint" ]]; then
            die "Required command '$command_name' was not found. Install $package_hint and try again."
        fi
        die "Required command '$command_name' was not found."
    fi
}

plugin_id_for() {
    local metadata_file="$1"
    python3 - "$metadata_file" <<'PY'
import json
import sys
from pathlib import Path

metadata = Path(sys.argv[1])
try:
    data = json.loads(metadata.read_text(encoding="utf-8"))
    plugin_id = data.get("KPlugin", {}).get("Id", "")
except Exception:
    plugin_id = ""

print(plugin_id)
PY
}

parse_args() {
    while (($# > 0)); do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -l|--list)
                list_widgets
                exit 0
                ;;
            -t|--test)
                [[ $# -ge 2 ]] || die "$1 requires a widget name."
                test_target="$2"
                append_unique_target "$2"
                shift 2
                ;;
            --prasmoid)
                use_prasmoid_build=true
                shift
                ;;
            --no-translations)
                compile_translations=false
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --)
                shift
                while (($# > 0)); do
                    append_unique_target "$1"
                    shift
                done
                ;;
            -*)
                die "Unknown option: $1"
                ;;
            *)
                append_unique_target "$1"
                shift
                ;;
        esac
    done
}

validate_targets() {
    local validated=()
    local widget

    if ((${#install_targets[@]} == 0)); then
        info "No widgets specified; installing all widgets."
        install_targets=("${available_widgets[@]}")
    else
        info "Requested widgets: $(join_words "${install_targets[@]}")"
    fi

    for widget in "${install_targets[@]}"; do
        if ! has_widget "$widget"; then
            warn "Unknown widget '$widget'; skipping. Use --list to see valid names."
            skipped_widgets+=("$widget")
            continue
        fi

        if [[ ! -d "$BASE_DIR/$widget" ]]; then
            warn "Directory not found for '$widget'; skipping."
            skipped_widgets+=("$widget")
            continue
        fi

        if [[ ! -f "$BASE_DIR/$widget/metadata.json" ]]; then
            warn "metadata.json not found for '$widget'; skipping."
            skipped_widgets+=("$widget")
            continue
        fi

        validated+=("$widget")
    done

    install_targets=("${validated[@]}")
    ((${#install_targets[@]} > 0)) || die "No valid widgets to install."
}

check_dependencies() {
    require_command python3 "Python 3"
    require_command kpackagetool6 "Plasma SDK / kpackage tools"

    if [[ "$use_prasmoid_build" == true ]]; then
        require_command prasmoid "prasmoid"
    fi

    if [[ -n "$test_target" ]]; then
        require_command plasmawindowed "plasmawindowed"
    fi

    if [[ "$compile_translations" == true && "$dry_run" == false ]] && ! command -v msgfmt >/dev/null 2>&1; then
        warn "msgfmt was not found; translation compilation will be skipped. Install gettext to enable it."
        compile_translations=false
    fi
}

run_prasmoid_build() {
    local widget_dir="$1"

    [[ "$use_prasmoid_build" == true ]] || return 0

    if [[ "$dry_run" == true ]]; then
        success "Would run: prasmoid build"
        return 0
    fi

    info "Running prasmoid build..."
    (cd "$widget_dir" && prasmoid build)
}

compile_widget_translations() {
    local widget_dir="$1"
    local plugin_id="$2"
    local translations_dir="$widget_dir/translations"
    local po_file
    local lang
    local mo_name
    local count=0

    [[ "$compile_translations" == true ]] || return 0
    [[ -d "$translations_dir" ]] || return 0

    shopt -s nullglob
    local po_files=("$translations_dir"/*.po)
    shopt -u nullglob

    ((${#po_files[@]} > 0)) || return 0

    mo_name="plasma_applet_${plugin_id}.mo"

    if [[ "$dry_run" == true ]]; then
        success "Would compile ${#po_files[@]} translation file(s)."
        return 0
    fi

    for po_file in "${po_files[@]}"; do
        lang="$(basename "$po_file" .po)"
        [[ "$lang" == "template" ]] && continue

        mkdir -p "$widget_dir/contents/locale/$lang/LC_MESSAGES"
        msgfmt "$po_file" -o "$widget_dir/contents/locale/$lang/LC_MESSAGES/$mo_name"
        count=$((count + 1))
    done

    ((count == 0)) || success "Compiled $count translation file(s)."
}

install_notification_configs() {
    local widget_dir="$1"
    local notify_files

    shopt -s nullglob
    notify_files=("$widget_dir"/contents/notifications/*.notifyrc)
    shopt -u nullglob

    ((${#notify_files[@]} > 0)) || return 0

    if [[ "$dry_run" == true ]]; then
        success "Would install ${#notify_files[@]} notification config file(s)."
        return 0
    fi

    mkdir -p "$NOTIFY_DIR"
    cp -- "${notify_files[@]}" "$NOTIFY_DIR/"
    success "Installed ${#notify_files[@]} notification config file(s)."
}

install_widget() {
    local widget="$1"
    local widget_dir="$BASE_DIR/$widget"
    local metadata_file="$widget_dir/metadata.json"
    local plugin_id
    local install_path
    local action
    local action_done
    local output

    info "Processing ${bold}${widget}${reset}"

    plugin_id="$(plugin_id_for "$metadata_file")"
    [[ -n "$plugin_id" ]] || {
        error "Could not determine plugin ID."
        failed_widgets+=("$widget")
        return 1
    }

    install_path="$PLASMOID_DIR/$plugin_id"

    if ! run_prasmoid_build "$widget_dir"; then
        error "prasmoid build failed."
        failed_widgets+=("$widget")
        return 1
    fi

    if ! compile_widget_translations "$widget_dir" "$plugin_id"; then
        error "Translation compilation failed."
        failed_widgets+=("$widget")
        return 1
    fi

    if [[ -d "$install_path" ]]; then
        action="upgrade"
        action_done="Upgraded"
    else
        action="install"
        action_done="Installed"
    fi

    if [[ "$dry_run" == true ]]; then
        success "Would $action plugin '$plugin_id'."
        ok_widgets+=("$widget")
        return 0
    fi

    if output="$(kpackagetool6 --type Plasma/Applet "--$action" "$widget_dir" 2>&1)"; then
        success "$action_done plugin '$plugin_id'."
    elif [[ "$action" == "upgrade" ]]; then
        warn "Upgrade failed; retrying with a clean install."
        rm -rf -- "$install_path"
        if output="$(kpackagetool6 --type Plasma/Applet --install "$widget_dir" 2>&1)"; then
            success "Installed plugin '$plugin_id'."
        else
            error "Install failed for '$plugin_id'."
            log "${dim}${output}${reset}" >&2
            failed_widgets+=("$widget")
            return 1
        fi
    else
        error "Install failed for '$plugin_id'."
        log "${dim}${output}${reset}" >&2
        failed_widgets+=("$widget")
        return 1
    fi

    install_notification_configs "$widget_dir"
    ok_widgets+=("$widget")
}

launch_test_target() {
    local widget_dir="$BASE_DIR/$test_target"
    local plugin_id

    [[ -n "$test_target" ]] || return 0

    plugin_id="$(plugin_id_for "$widget_dir/metadata.json")"
    [[ -n "$plugin_id" ]] || die "Could not determine plugin ID for test target '$test_target'."

    if [[ "$dry_run" == true ]]; then
        info "Would launch plasmawindowed '$plugin_id'."
        return 0
    fi

    info "Launching ${bold}${test_target}${reset} with plasmawindowed."
    log "${dim}Press Ctrl+C to stop the test.${reset}"
    plasmawindowed "$plugin_id"
}

print_summary() {
    log ""
    log "${bold}Summary${reset}"
    log "  Installed/planned: ${#ok_widgets[@]}"
    log "  Skipped:           ${#skipped_widgets[@]}"
    log "  Failed:            ${#failed_widgets[@]}"
    log "  Warnings:          $warn_count"

    ((${#ok_widgets[@]} == 0)) || log "  ${green}OK:${reset} $(join_words "${ok_widgets[@]}")"
    ((${#skipped_widgets[@]} == 0)) || log "  ${yellow}Skipped:${reset} $(join_words "${skipped_widgets[@]}")"
    ((${#failed_widgets[@]} == 0)) || log "  ${red}Failed:${reset} $(join_words "${failed_widgets[@]}")"
}

main() {
    parse_args "$@"
    validate_targets
    check_dependencies

    if [[ "$dry_run" == true ]]; then
        info "Dry run enabled; no files will be installed."
    fi

    local widget
    for widget in "${install_targets[@]}"; do
        install_widget "$widget" || true
    done

    print_summary

    if ((${#failed_widgets[@]} > 0)); then
        exit 1
    fi

    launch_test_target
}

main "$@"
