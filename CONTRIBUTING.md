# Contributing to RenLocalizer

Thanks for your interest in contributing to RenLocalizer.

This project sits at the intersection of parsing, localization, UI, packaging, and translation-engine integration. Good contributions are welcome in all of those areas, but the most important rule is simple:

> Preserve Ren'Py compatibility first. Convenience comes second.

## Before You Start

Please read these first:

- [README.md](README.md)
- [CHANGELOG.md](CHANGELOG.md)
- [docs/DETAILS.md](docs/DETAILS.md)
- [docs/wiki/Developer-Guide.md](docs/wiki/Developer-Guide.md)

For architecture-aware work, also check:

- `src/core/translation_pipeline.py`
- `src/core/parser.py`
- `src/core/translator.py`
- `src/core/ai_translator.py`
- `src/core/syntax_guard.py`
- `src/core/output_formatter.py`

## Development Setup

```bash
git clone https://github.com/Lord0fTurk/RenLocalizer.git
cd RenLocalizer
python -m venv .venv
```

Windows:

```bash
.venv\Scripts\activate
pip install -r requirements.txt
```

Linux / macOS:

```bash
source .venv/bin/activate
pip install -r requirements.txt
```

Run the application:

```bash
python run.py
python run_cli.py
```

## Project Structure

```text
run.py                  GUI launcher
run_cli.py              CLI launcher
src/core/               translation pipeline, parser, syntax safety, translators
src/backend/            Python <-> QML bridge
src/gui/qml/            interface
src/utils/              config, IO, logging, packaging helpers
src/tools/              optional helper tools
tests/                  regression and feature tests
docs/                   documentation
```

Important architectural notes:

- GUI and CLI both rely on the same core pipeline.
- Parser correctness and syntax protection are more critical than raw translation throughput.
- Backward compatibility matters. Avoid changing existing behavior without a strong reason.
- Additive changes are preferred over broad rewrites.

## Code Style

### Python

- Target Python `3.10+`.
- Use type hints in function signatures.
- Prefer readable, maintainable code over clever shortcuts.
- Keep functions focused and cohesive.
- Use constants/config for repeated or meaningful values.
- Avoid adding dependencies unless the gain is clearly worth it.

### Practical expectations

- Preserve existing module boundaries where possible.
- Avoid rewriting large files unless necessary.
- Prefer surgical edits.
- Keep comments short and useful.
- Do not hardcode secrets, API keys, or tokens.

## Testing

Run the test suite before opening a PR:

```bash
python -m pytest tests
```

Useful narrower runs:

```bash
python -m pytest tests/test_parser.py
python -m pytest tests/test_false_positives.py
python -m pytest tests/test_qt_runtime.py
python -m pytest tests/test_external_tm.py
```

If you change behavior in one of these areas, add or update tests:

- parser / extraction
- syntax guard / placeholder safety
- output formatting / false-positive filtering
- translation pipeline orchestration
- settings sanitization
- packaging or startup logic

## Contribution Types

High-value contribution areas include:

- Ren'Py parsing and extraction accuracy
- false-positive reduction
- placeholder and syntax protection
- AI / web translator stability
- runtime hook reliability
- external translation memory improvements
- GUI usability and settings clarity
- packaging and platform compatibility
- documentation improvements

## Bug Reports

When opening an issue, include:

- operating system
- Python version or packaged app version
- RenLocalizer version
- translation engine used
- whether the issue happens in GUI, CLI, or both
- steps to reproduce
- expected result
- actual result
- logs, screenshots, or a minimal sample file if possible

For parser or formatting bugs, a tiny reproducible `.rpy` snippet is extremely valuable.

## Feature Requests

For feature proposals:

1. Search existing issues first.
2. Explain the real workflow problem.
3. Describe the expected behavior, not just the implementation idea.
4. Mention compatibility or migration concerns if the change touches output format or parser behavior.

Large feature work should ideally be discussed before implementation.

## Pull Requests

### Before submitting

- Create a branch from `main`
- Keep the scope focused
- Run relevant tests
- Update docs if behavior changes
- Update `CHANGELOG.md` when appropriate

### PR description should include

- what changed
- why it changed
- how it was tested
- any compatibility or migration risk

### Commit message style

Use clear, conventional commit messages, for example:

```text
fix(parser): handle multiline textbutton edge case
docs(readme): rewrite project overview
test(runtime): cover Windows Qt graphics bootstrap
```

## Review Guidelines

Changes are more likely to be accepted when they:

- reduce breakage risk
- improve determinism
- preserve existing output compatibility
- include regression coverage
- keep the implementation understandable

## Documentation Changes

If your change affects user-facing behavior, update at least one of these:

- [README.md](README.md)
- [CHANGELOG.md](CHANGELOG.md)
- relevant file under `docs/`
- relevant page under `docs/wiki/`

Please keep documentation chronological and structured instead of appending scattered notes.

## Security and Sensitive Reports

Do not post secrets, private game files, or sensitive API material in public issues.

For sensitive matters, prefer private maintainer contact methods available through GitHub rather than a public issue thread.

## License

By contributing, you agree that your contributions will be licensed under the [GPL-3.0 License](LICENSE).
