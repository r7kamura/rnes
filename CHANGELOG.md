# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 0.2.1 - 2018-11-24

### Changed

- Decrease terminal renderer brightness threshold for better visibility.

### Fixed

- Fix PPU unnecessary vertical offset on rendering sprites.
- Fix PPU background unused palette address redirection.
- Fix PPU sprite rendering about transparent color.

## 0.2.0 - 2018-11-17

### Added

- Add CLI options and help message.

### Fixed

- Fix PPU sprite reverse.
- Fix PPU sprites rendering.
- Fix PPU sprite pattern addressing.
- Fix PPU background pattern attribute addressing.

## 0.1.1 - 2018-11-12

### Added

- Allow break-less input on key input.

### Changed

- Improve logger format for compatibility with nestest.log.

### Fixed

- Fix CPU ADC instruction.
- Fix CPU ASL instruction.
- Fix CPU JMP instruction (for the NMOS 6502 overlap bug).
- Fix CPU PHP instruction.
- Fix CPU PLP instruction
- Fix CPU RLA instruction.
- Fix CPU ROL instruction.
- Fix CPU SBC instruction.
- Fix CPU SLO instruction.
- Fix CPU stack pointer behavior on overflow (must be looped, e.g. $100 -> $1FF).
- Fix CPU indirect addressing overlap & overflow.
- Fix CPU cycle calculation on branch instruction and page cross.
- Fix PPU bus mirroring.
- Fix PPU sprit hit check.
- Fix PPU behaviors after reading $2002.
- Fix PPU buffer read on VRAM read from CPU.
- Fix PPU sprite RAM read on PPU 0x2004 from CPU.
- Fix PPU palette mirroring on $3F10, $3F14, $3F18, and $3F1C.

## 0.1.0 - 2018-11-09

### Added

- Add iNES header parser.
- Add ROM loader.
- Add CPU.
- Add PPU.
- Add terminal renderer.
- Add character RAM.
- Add DMA.
- Add logger for debug use.
- Add NMI interruption.
- Add keypad.
