import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "hamsti.vitals"
  ipcTarget: ""
  manageIpc: false

  property var snapshot: Model.emptySnapshot()
  property var extras: Model.emptyExtras()
  property bool settingsOpen: false
  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.4)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property int refreshSec: Math.max(1, parseInt(setting("refreshIntervalSec", 2), 10) || 2)
  readonly property int warnPercent: Math.max(1, parseInt(setting("warnPercent", 90), 10) || 90)
  readonly property int warnTempC: Math.max(1, parseInt(setting("warnTempC", 85), 10) || 85)
  readonly property string tempUnit: setting("tempUnit", "C")
  readonly property string displayMode: setting("display", "All")
  readonly property string clickAction: setting("clickAction", "Panel")
  readonly property string diskMount: setting("diskMount", "/")
  readonly property bool compactBar: Model.isOn(setting("compact", false), false)
  readonly property bool showCpu: Model.isOn(setting("showCpu", true), true)
  readonly property bool showMemory: Model.isOn(setting("showMemory", true), true)
  readonly property bool showGpu: Model.isOn(setting("showGpu", true), true)
  readonly property bool showDisk: Model.isOn(setting("showDisk", false), false)
  readonly property bool showTemp: Model.isOn(setting("showTemp", true), true)
  readonly property var cpu: snapshot && snapshot.cpu ? snapshot.cpu : {}
  readonly property var memory: snapshot && snapshot.memory ? snapshot.memory : {}
  readonly property var gpu: Model.primaryGpu(snapshot)
  readonly property var disks: snapshot && snapshot.disks ? snapshot.disks : []
  readonly property var temps: snapshot && snapshot.temps ? snapshot.temps : []
  readonly property var cpuRows: Model.processCpuRows(extras)
  readonly property var memoryRows: Model.processMemoryRows(extras)
  readonly property var gpuRows: Model.processGpuRows(extras)
  readonly property string collector: Model.fileUrlToPath(Qt.resolvedUrl("collect.py"))
  readonly property string phrase: Model.statusPhrase(snapshot, warnPercent, warnTempC)
  readonly property string heroTemp: snapshot && snapshot.hottest
    ? Model.formatTempFull(snapshot.hottest.celsius, tempUnit)
    : Model.formatTempFull(cpu.tempC, tempUnit)
  readonly property string heroTempLabel: snapshot && snapshot.hottest && snapshot.hottest.label
    ? String(snapshot.hottest.label)
    : "CPU"

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function applyExtras(raw) {
    var next = Model.parseExtras(raw)
    if (next) root.extras = next
  }

  function refreshExtras() {
    if (extrasProc.running) return
    extrasProc.running = true
  }

  function persist(patch) {
    var entry = { id: root.moduleName }
    var src = root.settings || {}
    var key
    for (key in src) if (key !== "id") entry[key] = src[key]
    for (key in patch) entry[key] = patch[key]
    root.settings = entry
    if (root.hostWidget) root.hostWidget.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function persistOne(key, value) {
    var patch = {}
    patch[key] = value
    persist(patch)
  }

  function toggleFlag(key, current) {
    persistOne(key, current ? "Off" : "On")
  }

  function stepInt(key, fallback, delta, min, max) {
    var current = parseInt(setting(key, fallback), 10)
    if (!isFinite(current)) current = fallback
    persistOne(key, Math.max(min, Math.min(max, current + delta)))
  }

  function openMonitor() {
    if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
    root.close()
  }

  onOpenedChanged: {
    if (root.opened) root.refreshExtras()
    else root.settingsOpen = false
  }

  Process {
    id: extrasProc
    command: ["python3", root.collector, "--extras"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyExtras(text)
    }
  }

  Timer {
    interval: 3000
    running: root.opened
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshExtras()
  }

  function meterColor(warned) {
    return warned ? root.urgent : root.foreground
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem ? root.anchorItem : root
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(440))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: root.openMonitor()
      onTextKey: function(t) {
        if (t === "b" || t === "o") root.openMonitor()
      }

      Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

      Column {
        id: column
        width: scroll.width
        spacing: Style.space(14)

        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, heroTempCol.implicitHeight)

          Text {
            id: heroIcon
            text: "󰈐"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: heroTempCol.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Vitals"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              text: root.phrase.toUpperCase()
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }

          Column {
            id: heroTempCol
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(1)

            Text {
              text: root.heroTemp
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.displayLarge
              font.bold: true
              horizontalAlignment: Text.AlignRight
              anchors.right: parent.right
            }

            Text {
              text: root.heroTempLabel.toUpperCase()
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.1
              horizontalAlignment: Text.AlignRight
              anchors.right: parent.right
            }
          }
        }

        MetricBlock {
          icon: "󰍛"
          title: "CPU"
          value: Model.formatPercent(root.cpu.percent)
          fraction: Number(root.cpu.percent) / 100
          warned: Model.metricWarned("cpu", root.snapshot, root.warnPercent, root.warnTempC)
          meta: [
            Model.formatTempFull(root.cpu.tempC, root.tempUnit),
            root.cpu.cores ? (root.cpu.cores + " cores") : "",
            root.cpu.load1 !== null && root.cpu.load1 !== undefined ? ("load " + Model.formatLoad(root.cpu.load1)) : ""
          ].filter(function(part) { return part && part !== "—" }).join("  ·  ")
          rows: root.cpuRows
        }

        MetricBlock {
          icon: "󰘚"
          title: "Memory"
          value: Model.formatPercent(root.memory.percent)
          fraction: Number(root.memory.percent) / 100
          warned: Model.metricWarned("memory", root.snapshot, root.warnPercent, root.warnTempC)
          meta: Model.formatBytes(root.memory.usedBytes) + " / " + Model.formatBytes(root.memory.totalBytes)
            + (root.memory.swapTotalBytes > 0
              ? ("  ·  swap " + Model.formatBytes(root.memory.swapUsedBytes))
              : "")
          rows: root.memoryRows
        }

        MetricBlock {
          visible: root.gpu !== null
          icon: "󰢮"
          title: root.gpu && root.gpu.name ? String(root.gpu.name).replace(/^NVIDIA GeForce /, "") : "GPU"
          value: Model.formatPercent(root.gpu ? root.gpu.percent : null)
          fraction: root.gpu ? Number(root.gpu.percent) / 100 : 0
          warned: Model.metricWarned("gpu", root.snapshot, root.warnPercent, root.warnTempC)
          meta: {
            if (!root.gpu) return ""
            var parts = []
            if (root.gpu.memUsedBytes && root.gpu.memTotalBytes)
              parts.push(Model.formatBytes(root.gpu.memUsedBytes) + " / " + Model.formatBytes(root.gpu.memTotalBytes))
            var temp = Model.formatTempFull(root.gpu.tempC, root.tempUnit)
            if (temp !== "—") parts.push(temp)
            if (root.gpu.powerW !== null && root.gpu.powerW !== undefined)
              parts.push(Math.round(Number(root.gpu.powerW)) + " W")
            return parts.join("  ·  ")
          }
          rows: root.gpuRows
        }

        Repeater {
          model: root.disks

          MetricBlock {
            required property var modelData
            icon: "󰋊"
            title: modelData.mount === "/" ? "Storage" : modelData.mount
            value: Model.formatPercent(modelData.percent)
            fraction: Number(modelData.percent) / 100
            warned: Number(modelData.percent) >= root.warnPercent
            meta: Model.formatBytes(modelData.usedBytes) + " / " + Model.formatBytes(modelData.totalBytes)
              + (modelData.fstype ? ("  ·  " + modelData.fstype) : "")
            rows: Model.directoryRows(root.extras, modelData.mount)
          }
        }

        Column {
          visible: root.temps.length > 0
          width: parent.width
          spacing: Style.space(10)

          PanelSeparator { foreground: root.foreground }

          PanelSectionHeader {
            text: "TEMPERATURES"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Flow {
            width: parent.width
            spacing: Style.space(8)

            Repeater {
              model: root.temps

              BorderSurface {
                required property var modelData
                implicitWidth: tempLabel.implicitWidth + Style.space(12)
                implicitHeight: tempLabel.implicitHeight + Style.space(8)
                color: "transparent"
                borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)
                radius: Style.cornerRadius

                Text {
                  id: tempLabel
                  anchors.centerIn: parent
                  text: modelData.label + "  " + Model.formatTempFull(modelData.celsius, root.tempUnit)
                  color: Number(modelData.celsius) >= root.warnTempC ? root.urgent : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
              }
            }
          }
        }

        PanelSeparator { foreground: root.foreground }

        Column {
          width: parent.width
          spacing: root.settingsOpen ? Style.space(10) : 0

          Item {
            width: parent.width
            implicitHeight: settingsLabel.implicitHeight + Style.space(8)

            Text {
              id: settingsLabel
              text: "SETTINGS"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: root.settingsOpen ? "▾" : "▸"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.settingsOpen = !root.settingsOpen
            }
          }

          Column {
            visible: root.settingsOpen
            width: parent.width
            spacing: Style.space(10)

            Flow {
              width: parent.width
              spacing: Style.space(6)
              SettingPill {
                label: "CPU"
                active: root.showCpu
                enabled: root.displayMode === "All"
                onClicked: root.toggleFlag("showCpu", root.showCpu)
              }
              SettingPill {
                label: "RAM"
                active: root.showMemory
                enabled: root.displayMode === "All"
                onClicked: root.toggleFlag("showMemory", root.showMemory)
              }
              SettingPill {
                label: "GPU"
                active: root.showGpu
                enabled: root.displayMode === "All"
                onClicked: root.toggleFlag("showGpu", root.showGpu)
              }
              SettingPill {
                label: "Disk"
                active: root.showDisk
                enabled: root.displayMode === "All"
                onClicked: root.toggleFlag("showDisk", root.showDisk)
              }
              SettingPill {
                label: "Temp"
                active: root.showTemp
                enabled: root.displayMode === "All"
                onClicked: root.toggleFlag("showTemp", root.showTemp)
              }
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)
              Repeater {
                model: ["All", "CPU", "Memory", "GPU", "Disk", "Temp"]
                SettingPill {
                  required property string modelData
                  label: modelData
                  active: root.displayMode === modelData
                  onClicked: root.persistOne("display", modelData)
                }
              }
            }

            Row {
              width: parent.width
              spacing: Style.space(6)
              SettingPill { label: "Compact"; active: root.compactBar; onClicked: root.toggleFlag("compact", root.compactBar) }
              SettingPill { label: "°C"; active: root.tempUnit !== "F"; onClicked: root.persistOne("tempUnit", "C") }
              SettingPill { label: "°F"; active: root.tempUnit === "F"; onClicked: root.persistOne("tempUnit", "F") }
              SettingPill { label: "Panel"; active: String(root.clickAction).toLowerCase() !== "btop"; onClicked: root.persistOne("clickAction", "Panel") }
              SettingPill { label: "btop"; active: String(root.clickAction).toLowerCase() === "btop"; onClicked: root.persistOne("clickAction", "btop") }
            }

            Row {
              visible: root.disks.length > 0
              width: parent.width
              spacing: Style.space(6)
              Repeater {
                model: root.disks
                SettingPill {
                  required property var modelData
                  label: modelData.mount
                  active: root.diskMount === modelData.mount
                  onClicked: root.persistOne("diskMount", modelData.mount)
                }
              }
            }

            Row {
              width: parent.width
              spacing: Style.space(6)
              SettingPill { label: "−"; onClicked: root.stepInt("refreshIntervalSec", 2, -1, 1, 30) }
              SettingPill { label: root.refreshSec + "s"; active: true }
              SettingPill { label: "+"; onClicked: root.stepInt("refreshIntervalSec", 2, 1, 1, 30) }
              SettingPill { label: "−"; onClicked: root.stepInt("warnPercent", 90, -5, 50, 100) }
              SettingPill { label: root.warnPercent + "%"; active: true }
              SettingPill { label: "+"; onClicked: root.stepInt("warnPercent", 90, 5, 50, 100) }
              SettingPill { label: "−"; onClicked: root.stepInt("warnTempC", 85, -5, 50, 110) }
              SettingPill { label: root.warnTempC + "°"; active: true }
              SettingPill { label: "+"; onClicked: root.stepInt("warnTempC", 85, 5, 50, 110) }
            }
          }
        }

        Text {
          width: parent.width
          text: "Click or press Enter for btop"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
      }
    }
  }

  component MetricBlock: Column {
    property string icon: ""
    property string title: ""
    property string value: ""
    property real fraction: 0
    property bool warned: false
    property string meta: ""
    property var rows: []

    width: parent ? parent.width : implicitWidth
    spacing: Style.space(6)

    Item {
      width: parent.width
      implicitHeight: Math.max(metricTitle.implicitHeight, metricValue.implicitHeight)

      Text {
        id: metricTitle
        text: (icon ? icon + "  " : "") + title
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        elide: Text.ElideRight
        anchors.left: parent.left
        anchors.right: metricValue.left
        anchors.rightMargin: Style.space(10)
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        id: metricValue
        text: value
        color: warned ? root.urgent : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Item {
      width: parent.width
      implicitHeight: Style.space(8)

      Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
      }

      Rectangle {
        anchors.left: track.left
        anchors.verticalCenter: track.verticalCenter
        height: track.height
        radius: track.radius
        color: warned ? root.urgent : root.foreground
        width: Math.max(track.height, track.width * Math.max(0, Math.min(1, fraction)))

        Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 180 } }
      }
    }

    Text {
      visible: meta !== ""
      width: parent.width
      text: meta
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
    }

    Column {
      visible: rows && rows.length > 0
      width: parent.width
      spacing: Style.space(3)

      Repeater {
        model: rows

        Row {
          required property var modelData
          width: parent.width
          spacing: Style.space(8)

          Text {
            width: Math.max(0, parent.width - rowValue.implicitWidth - parent.spacing)
            text: modelData.name
            color: root.foreground
            opacity: 0.62
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }

          Text {
            id: rowValue
            text: modelData.value
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
      }
    }
  }

  component SettingPill: Button {
    property string label: ""

    text: label
    fontSize: Style.font.bodySmall
    foreground: root.foreground
    fontFamily: root.fontFamily
    horizontalPadding: Style.spacing.controlPaddingX
    verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
    bordered: true
    opacity: enabled ? 1 : 0.4
  }

}
