# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2026-08-17

### Added

- In-panel settings accordion (pills for metrics, look, click, disk, poll, alerts)
- `barStyle` Icons / Text so the bar can show `CPU` `MEM` `GPU` instead of glyphs
- Hover tooltips and one-line hints on every settings group
- Labeled poll / warn / hot steppers

### Changed

- Settings stay collapsed so the dropdown is stats-first

## [1.1.0] - 2026-08-17

### Added

- Top processes for CPU, memory, and GPU VRAM while the panel is open
- Cached top-level directory sizes for each disk

### Fixed

- Fake CPU spikes from two monitors sampling `/proc/stat` a few milliseconds apart

## [1.0.0] - 2026-08-17

### Added

- Native Omarchy bar widget for CPU, memory, GPU, disk, and temperatures
- Detail panel with meters
- NVIDIA (`nvidia-smi`) and AMD (sysfs) GPU support

[Unreleased]: https://github.com/thehamsti/omarchy-vitals/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/thehamsti/omarchy-vitals/releases/tag/v1.2.0
[1.1.0]: https://github.com/thehamsti/omarchy-vitals/releases/tag/v1.1.0
[1.0.0]: https://github.com/thehamsti/omarchy-vitals/releases/tag/v1.0.0
