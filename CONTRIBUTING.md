# Contributing

Use the current stable D compiler and DUB where possible. Run dub test, build
the examples, and build the DDoc API reference before opening a pull request.
Keep the core deterministic and dependency-free; calendar topology must not
depend on the system clock or local time zone.

Add tests for date-boundary behavior and compile-time use when changing a
public calculation. Document public symbols with DDoc comments. Performance
claims must include a reproducible command and measured environment.

By contributing, you agree that your contributions are licensed under the
project's MIT license.
