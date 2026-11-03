# Checks: Python / FastAPI

| File | Put it in | Needs | Run |
| --- | --- | --- | --- |
| `ruff.toml` | Repository root | `ruff` | `ruff check .` and `ruff format --check .` |
| `mypy.ini` | Repository root | `mypy`, `pydantic` | `mypy .` |
| `.importlinter` | Repository root | `import-linter` | `lint-imports` |

Ruff catches bare `except`, mutable default arguments, blocking calls inside `async def` functions and common security issues. mypy checks types, with the Pydantic plugin. import-linter fails when routers import the database layer or SQLAlchemy directly.

If the project keeps tool settings in `pyproject.toml`, move them there instead of adding files.
