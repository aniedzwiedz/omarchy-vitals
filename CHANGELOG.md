# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions are calendar-based: `YYYY.MM.DD`, with an extra `.N` if we ship
more than once on the same day.

## [Unreleased]

## [2026.08.17] - 2026-08-17

### Added

- Native Omarchy bar widget for CPU, memory, GPU, disk, and temperatures
- Detail panel with meters, top processes, and cached disk directories
- NVIDIA (`nvidia-smi`) and AMD (sysfs) GPU support
- In-panel settings accordion (pills for metrics, look, click, disk, poll, alerts)
- `barStyle` Icons / Text so the bar can show `CPU` `MEM` `GPU` instead of glyphs
- Hover tooltips and one-line hints on every settings group

### Changed

- Settings stay collapsed so the dropdown is stats-first

### Fixed

- Fake CPU spikes from two monitors sampling `/proc/stat` a few milliseconds apart

[Unreleased]: https://github.com/thehamsti/omarchy-vitals/compare/v2026.08.17...HEAD
[2026.08.17]: https://github.com/thehamsti/omarchy-vitals/releases/tag/v2026.08.17
