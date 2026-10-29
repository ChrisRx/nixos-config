// Capture dialog for hypr-capture (./capture.sh), run on demand with
// `quickshell -n -p <this file>` and gone again once a choice is made. It only
// collects mode, target and audio, then hands them to `hypr-capture shot|record`
// detached, so the capture itself outlives this process.
//
// Keys: 1/2 screenshot or video, r/w/s region, window or screen, a desktop
// audio, Enter to capture, Esc (or a click outside the card) to cancel.
// Colours come from noctalia's current palette: the `hypr-capture` user
// template in ./home.nix renders ./capture-colors.json to
// ~/.cache/hypr-capture/colors.json each time noctalia regenerates its theme
// (e.g. on a wallpaper change). Until that file exists, or for any key it
// lacks, catppuccin mocha with the mauve accent is used instead.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root

  property string mode: "shot"
  property string target: "region"
  property bool audio: false

  property var palette: ({})

  readonly property color base: palette.surface ?? "#1e1e2e"
  readonly property color surface0: palette.control ?? "#313244"
  readonly property color surface1: palette.control_hover ?? "#45475a"
  readonly property color outline: palette.outline ?? "#45475a"
  readonly property color text: palette.text ?? "#cdd6f4"
  readonly property color subtext: palette.subtext ?? "#a6adc8"
  readonly property color accent: palette.accent ?? "#cba6f7"
  readonly property color crust: palette.on_accent ?? "#11111b"

  // Read once, synchronously, so the first frame already has the right
  // colours. A missing or malformed file leaves the fallbacks above.
  FileView {
    path: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/hypr-capture/colors.json"
    blockLoading: true
    printErrors: false
    onLoaded: {
      try {
        root.palette = JSON.parse(text());
      } catch (e) {
        console.warn("hypr-capture: ignoring bad colors.json:", e);
      }
    }
  }

  function capture() {
    const args = ["hypr-capture", mode === "shot" ? "shot" : "record", target];
    if (mode === "video" && audio)
      args.push("audio");
    Quickshell.execDetached(args);
    Qt.quit();
  }

  // noctalia's own Tabler icon font, so the glyphs match the bar's. The path
  // comes from capture.sh; without it the icons are left out rather than
  // drawn as missing-glyph boxes.
  FontLoader {
    id: iconFont
    source: Quickshell.env("HYPR_CAPTURE_ICON_FONT") ? "file://" + Quickshell.env("HYPR_CAPTURE_ICON_FONT") : ""
  }

  // A Tabler glyph by codepoint (see noctalia's assets/fonts/tabler.json).
  component Icon: Text {
    property int glyph
    visible: iconFont.status === FontLoader.Ready
    text: String.fromCodePoint(glyph)
    font.family: iconFont.name
    font.pixelSize: 18
  }

  // One pill in a segmented row. `hint` is the key that selects it.
  component Option: Rectangle {
    id: option

    property string label
    property string hint
    property int icon
    property bool selected
    signal picked

    Layout.fillWidth: true
    implicitHeight: 40
    radius: 8
    color: selected ? root.accent : (area.containsMouse ? root.surface1 : root.surface0)

    Row {
      anchors.centerIn: parent
      spacing: 8

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: option.icon
        color: option.selected ? root.crust : root.text
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: option.label + "  <font color='" + (option.selected ? root.surface0 : root.subtext) + "'>" + option.hint + "</font>"
        textFormat: Text.StyledText
        color: option.selected ? root.crust : root.text
        font.pixelSize: 14
      }
    }

    MouseArea {
      id: area
      anchors.fill: parent
      hoverEnabled: true
      onClicked: option.picked()
    }
  }

  PanelWindow {
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    color: "#66000000"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "hypr-capture"

    // Click outside the card cancels.
    MouseArea {
      anchors.fill: parent
      onClicked: Qt.quit()
    }

    Rectangle {
      anchors.centerIn: parent
      width: 420
      height: column.implicitHeight + 40
      radius: 14
      color: root.base
      border.color: root.outline
      border.width: 1

      // Swallow clicks on the card so they do not reach the cancel area.
      MouseArea {
        anchors.fill: parent
      }

      focus: true
      Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Escape: Qt.quit(); break;
        case Qt.Key_1: root.mode = "shot"; break;
        case Qt.Key_2: root.mode = "video"; break;
        case Qt.Key_R: root.target = "region"; break;
        case Qt.Key_W: root.target = "window"; break;
        case Qt.Key_S: root.target = "screen"; break;
        case Qt.Key_A: root.audio = !root.audio; break;
        case Qt.Key_Return:
        case Qt.Key_Enter: root.capture(); break;
        default: return;
        }
        event.accepted = true;
      }

      ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        Text {
          text: "Capture"
          color: root.text
          font.pixelSize: 18
          font.bold: true
        }

        RowLayout {
          spacing: 8
          // camera, video
          Option { label: "Screenshot"; hint: "1"; icon: 0xEA54; selected: root.mode === "shot"; onPicked: root.mode = "shot" }
          Option { label: "Video"; hint: "2"; icon: 0xED22; selected: root.mode === "video"; onPicked: root.mode = "video" }
        }

        RowLayout {
          spacing: 8
          // marquee-2, app-window, device-desktop
          Option { label: "Region"; hint: "R"; icon: 0xEEAE; selected: root.target === "region"; onPicked: root.target = "region" }
          Option { label: "Window"; hint: "W"; icon: 0xEFE6; selected: root.target === "window"; onPicked: root.target = "window" }
          Option { label: "Screen"; hint: "S"; icon: 0xEA89; selected: root.target === "screen"; onPicked: root.target = "screen" }
        }

        RowLayout {
          visible: root.mode === "video"
          spacing: 8
          // volume, volume-off
          Option { label: "Desktop audio"; hint: "A"; icon: root.audio ? 0xEB51 : 0xF1C3; selected: root.audio; onPicked: root.audio = !root.audio }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.topMargin: 4
          implicitHeight: 44
          radius: 8
          color: go.containsMouse ? Qt.lighter(root.accent, 1.1) : root.accent

          Row {
            anchors.centerIn: parent
            spacing: 8

            // screenshot, player-record
            Icon {
              anchors.verticalCenter: parent.verticalCenter
              glyph: root.mode === "shot" ? 0xF201 : 0xED47
              color: root.crust
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: (root.mode === "shot" ? "Take screenshot" : "Start recording") + "  ⏎"
              color: root.crust
              font.pixelSize: 15
              font.bold: true
            }
          }

          MouseArea {
            id: go
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.capture()
          }
        }
      }
    }
  }
}
