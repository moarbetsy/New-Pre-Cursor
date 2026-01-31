---
description: Python 3.14 rules with strict typing, Ruff, mypy, and safe string practices
alwaysApply: false
globs:
  - "**/*.py"
  - "pyproject.toml"
---

# Role
You are an expert Python developer specialized in Python 3.14.

# 1. Version and tooling
- Target version: Python 3.14.
- Optimize code for Ruff linter/formatter.
- Use mypy strict mode standards for type checking.
- Prefer pyproject.toml for all configuration.

# 2. Type annotations (PEP 649 / 749)
- Always annotate all functions, methods, and public attributes.
- Do not assume __annotations__ contains resolved values.
- When inspecting types at runtime, use:
  annotationlib.get_annotations(obj, format=annotationlib.Format.VALUE)
- Avoid from __future__ import annotations if 3.14 semantics are active.

# 3. Concurrency and parallelism
- Default: use asyncio for I/O-bound tasks.
- Free-threading (PEP 703):
  - If the user specifies a CPU-bound context, suggest the free-threaded (no-GIL) build.
  - Prefer thread-safe data structures (queue.Queue over manual locking).
  - Verify that imported C-extensions (NumPy, etc.) are compatible with free-threading.
- Subinterpreters (PEP 734):
  - Use concurrent.interpreters only for strict component isolation or actor-model architectures.
  - Pass data between interpreters using serialized messages (JSON/bytes), never shared mutable objects.

# 4. String and security (PEP 750)
- Use template string literals for structured DSLs (SQL/HTML/etc.) where appropriate.
- Prohibit ad-hoc string concatenation (+ or f-strings) for SQL queries or shell commands.

# 5. Error handling and control flow
- Use specific exception types; never except Exception:.
- Use except* only when handling ExceptionGroup from concurrent tasks.
- Prefer logging with structured output/tracebacks over print.

# 6. Performance and libraries
- Prefer compression.zstd over gzip or zipfile for internal data processing if available.
- Use asyncio introspection tools to identify leaked tasks in long-running services.

# 7. Code style
- Keep business logic decoupled from I/O (HTTP, CLI, DB).
- Follow strict PEP 8 naming conventions.
- Prefer immutable data structures (frozen dataclasses) to simplify thread safety.

# Python execution contract for this repo
- Use uv for environments and execution:
  - uv sync
  - uv run <command>
- Do not recommend pip install or python -m venv.
