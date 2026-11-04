# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Clean-room rules, MIT license, product spec, contribution docs and PR/issue templates.
- Repository scaffold: SwiftPM package, `TimerCore` + app skeleton, Makefile, `AGENTS.md`.
- Original app icon generated from code (`scripts/make-icon.swift`, `make icon`) with provenance entry.
- `TimerCore` input parser (`TimerInputParser`): durations, clock times and `+/-` adjustments, with table-driven tests and `docs/INPUT_SYNTAX.md`.
- CI workflow: Linux `TimerCore` tests, macOS build + tests, lint (forbidden names, `TimerCore` imports), guarded app/preview steps.
