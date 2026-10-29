# Screenshot/recording tool behind the Print bind in ./binds.lua. Packaged
# by ./home.nix with writeShellApplication, which supplies the shebang, strict
# mode and PATH (grim, slurp, wl-screenrec, satty, quickshell, ...), and runs
# ShellCheck on it at build time. ./home.nix also prepends `capture_qml` and
# `capture_icon_font`, the store paths of ./capture.qml and noctalia's Tabler
# icon font.
#
#   hypr-capture                         stop a recording, else open the dialog
#   hypr-capture shot   region|window|screen
#   hypr-capture record region|window|screen [audio]
#   hypr-capture stop
#
# The dialog (./capture.qml) only collects the choices and runs the `shot` or
# `record` form, so everything that actually captures lives here.

pictures="$HOME/Pictures"
videos="$HOME/Videos"
pidfile="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr-capture.pid"
logfile="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr-capture.log"

recording() {
  [[ -f $pidfile ]] && kill -0 "$(cat "$pidfile")" 2>/dev/null
}

# The focused monitor's name, for grim -o / wl-screenrec -o.
focused_output() {
  hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'
}

# slurp box list of every mapped window on a visible workspace (each monitor's
# active one plus any open special workspace), in slurp's "x,y wxh" format.
# `slurp -r` then only accepts a click on one of these boxes.
window_boxes() {
  local visible
  visible=$(hyprctl monitors -j | jq -c '[.[] | .activeWorkspace.id, .specialWorkspace.id] | map(select(. != 0))')
  hyprctl clients -j | jq -r --argjson ws "$visible" '
    .[]
    | select(.mapped and (.hidden | not) and (.workspace.id as $id | $ws | index($id)))
    | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1]) \(.class)"'
}

# Prints a slurp geometry for the chosen target, or an output name prefixed
# with "output:". Fails if the selection is cancelled.
pick_target() {
  local geom
  case "$1" in
    region) geom=$(slurp -d) || return 1 ;;
    window) geom=$(window_boxes | slurp -r) || return 1 ;;
    screen) geom="output:$(focused_output)" ;;
    *) return 1 ;;
  esac
  printf '%s\n' "$geom"
}

screenshot() {
  local target file
  target=$(pick_target "$1") || exit 0
  mkdir -p "$pictures"
  file="$pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"

  # Let the dialog's layer finish closing so it is not in a full-screen
  # shot.
  sleep 0.2
  if [[ $target == output:* ]]; then
    grim -o "${target#output:}" "$file"
  else
    grim -g "$target" "$file"
  fi
  wl-copy --type image/png <"$file"

  # Backgrounded so the script does not hold the bind while the notification
  # waits for a click. Clicking the notification itself shows the file in its
  # folder; "Annotate" edits the saved file in place.
  (
    action=$(notify-send --app-name=Screenshot --icon="$file" \
      --action=default="Show in folder" --action=open="Show in folder" \
      --action=edit=Annotate --wait \
      "Screenshot saved" "$file (copied to clipboard)") || true
    case "$action" in
      default | open) show_in_folder "$file" ;;
      edit)
        satty --filename "$file" --output-filename "$file" \
          --copy-command wl-copy --early-exit
        ;;
    esac
  ) &
  disown
}

# Opens the file manager on the file's folder with the file selected, through
# the FileManager1 D-Bus interface (nautilus here, d-bus activated).
show_in_folder() {
  busctl --user call org.freedesktop.FileManager1 /org/freedesktop/FileManager1 \
    org.freedesktop.FileManager1 ShowItems ass 1 "file://$1" ""
}

record() {
  local target file pid action
  target=$(pick_target "$1") || exit 0
  mkdir -p "$videos"
  file="$videos/recording-$(date +%Y%m%d-%H%M%S).mp4"

  local args=(-f "$file")
  if [[ $target == output:* ]]; then
    args+=(-o "${target#output:}")
  else
    args+=(-g "$target")
  fi
  if [[ ${2:-} == audio ]]; then
    # The default sink's monitor source is what is playing, not the mic.
    args+=(--audio --audio-device "$(pactl get-default-sink).monitor")
  fi

  # Notifications stay out of the video: noctalia's Do Not Disturb is on for
  # the length of the recording, and restored afterwards only if this turned
  # it on. Our own heads-up has to be shown before DND hides it, and turning
  # DND on pops a ~1.4s OSD, so recording starts once both have cleared.
  #
  # This script's own pid stands in for the recorder's during the countdown,
  # so Print in that window cancels instead of opening another dialog.
  local dnd_was
  dnd_was=$(noctalia msg notification-dnd-status 2>/dev/null) || dnd_was=on
  echo "$$" >"$pidfile"
  trap 'rm -f "$pidfile"' EXIT
  if [[ $dnd_was == off ]]; then
    trap 'rm -f "$pidfile"; noctalia msg notification-dnd-set off >/dev/null 2>&1 || true' EXIT
    notify-send --app-name=Recorder --expire-time=3000 \
      "Recording in 3 seconds" "Notifications are paused until you press Print to stop"
    sleep 1.2
    noctalia msg notification-dnd-set on >/dev/null
    sleep 2
  else
    sleep 0.2
  fi

  wl-screenrec "${args[@]}" >"$logfile" 2>&1 &
  pid=$!
  echo "$pid" >"$pidfile"

  local status=0
  wait "$pid" || status=$?
  rm -f "$pidfile"

  # Back on before the result is announced, or DND would swallow it.
  trap - EXIT
  if [[ $dnd_was == off ]]; then
    noctalia msg notification-dnd-set off >/dev/null 2>&1 || true
  fi

  # wl-screenrec exits 130 on the SIGINT the stop path sends.
  if [[ $status -eq 0 || $status -eq 130 ]] && [[ -s $file ]]; then
    action=$(notify-send --app-name=Recorder \
      --action=default="Show in folder" --action=open="Show in folder" --wait \
      "Recording saved" "$file") || true
    if [[ $action == default || $action == open ]]; then
      show_in_folder "$file"
    fi
  else
    notify-send --app-name=Recorder --urgency=critical \
      "Recording failed" "$(tail -n 5 "$logfile")"
  fi
}

stop() {
  local pid
  recording || return 0
  pid=$(cat "$pidfile")
  # SIGINT is what makes wl-screenrec finish the file. During the countdown
  # the pid is this script's, which may have been started with SIGINT
  # ignored (bash does that to background jobs), so it gets SIGTERM instead.
  if [[ $(cat "/proc/$pid/comm" 2>/dev/null) == wl-screenrec ]]; then
    kill -INT "$pid"
  else
    kill -TERM "$pid"
  fi
}

case "${1:-}" in
  "")
    if recording; then
      stop
    else
      # -n: a second Print while the dialog is up does not open another.
      HYPR_CAPTURE_ICON_FONT=$capture_icon_font exec quickshell -n -p "$capture_qml"
    fi
    ;;
  shot) screenshot "${2:-}" ;;
  record) record "${2:-}" "${3:-}" ;;
  stop) stop ;;
  *)
    echo "usage: hypr-capture [shot TARGET | record TARGET [audio] | stop]" >&2
    exit 2
    ;;
esac
