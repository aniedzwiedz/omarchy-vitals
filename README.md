# Vitals

An [Omarchy](https://omarchy.org/) bar widget for live machine stats:

- CPU usage, load, and package temperature
- Memory and swap
- GPU usage, VRAM, temperature, and power (NVIDIA via `nvidia-smi`, AMD via sysfs)
- Filesystem usage
- The rest of the interesting hwmon temperatures

The bar shows a compact strip of the metrics you care about. Left click opens a
native Omarchy panel with meters; right click (or Enter in the panel) launches
`btop`.

## Install

```bash
omarchy plugin add https://github.com/thehamsti/omarchy-vitals.git --enable
```

That clones the plugin into `~/.config/omarchy/plugins/hamsti.vitals/`, validates
the manifest, and places the widget on the right side of the bar. Move it
afterward with:

```bash
omarchy bar move hamsti.vitals --section right --before omarchy.power
```

Update later with `omarchy plugin update hamsti.vitals`.

## What you get

**Bar**

`󰍛 12% 51°  󰘚 34%  󰢮 4% 45°`

GPU hides itself when no supported GPU is found. Disk is off by default so the
strip stays short; turn it on if you want capacity in the bar.

**Panel**

Usage bars for CPU, memory, each GPU, and each real filesystem, plus a
temperature chip list. Values flip to the theme urgent color at the warning
thresholds.

**Clicks**

| Input | Action |
| --- | --- |
| Left | Open the panel (or `btop`, if you change **Left click**) |
| Right | Open `btop` |
| Middle | Refresh now |
| Hover | Tooltip with the current snapshot |

## Settings

All settings live inline on the bar entry in `~/.config/omarchy/shell.json`.

```json
{
  "id": "hamsti.vitals",
  "display": "All",
  "showCpu": "On",
  "showMemory": "On",
  "showGpu": "On",
  "showDisk": "Off",
  "showTemp": "On",
  "compact": "Off",
  "tempUnit": "C",
  "refreshIntervalSec": 2,
  "warnPercent": 90,
  "warnTempC": 85,
  "diskMount": "/",
  "clickAction": "Panel"
}
```

`display` can be `All`, `CPU`, `Memory`, `GPU`, `Disk`, or `Temp`. The plugin
allows multiple instances, so you can split the strip:

```bash
omarchy plugin enable hamsti.vitals --section right
omarchy bar set hamsti.vitals display CPU
```

Then enable another copy and set that one to `Memory`.

## How it reads the machine

`collect.py` is a no-dependency Python 3 snapshot:

- `/proc/stat` for CPU percent (previous sample kept in `$XDG_RUNTIME_DIR`)
- `/proc/meminfo` for memory and swap
- `nvidia-smi` for NVIDIA GPUs, `/sys/class/drm` for AMD
- `/proc/self/mounts` + `statvfs` for real disks
- `/sys/class/hwmon` for temperatures

The first CPU sample after login has no previous counter, so usage shows `—`
for one refresh interval.

## Develop

```bash
omarchy plugin validate .
python3 collect.py --pretty
```

Saving files under `~/.config/omarchy/plugins/hamsti.vitals/` reloads the
widget automatically. Force a rescan with `omarchy-shell shell rescanPlugins`.
