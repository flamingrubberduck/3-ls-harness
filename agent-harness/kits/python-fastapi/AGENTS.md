# Stack kit: Python / FastAPI

Version: 0.1.0 · Owner: Engineering practice group

Sample kit: review and adapt before use. Rules for every FastAPI service. The project's AGENTS.md lists exact commands and anything that differs.

## Commands

Run everything inside the project's virtual environment, using the dependency tool it already uses (pip with requirements files, Poetry or uv).

- Tests: `pytest`
- Lint: `ruff check .`
- Formatting check: `ruff format --check .`
- Type check: `mypy .` (if the project uses it)

## Structure

- Routers stay thin: declare the request and response models, call a service, return the result.
- Request and response bodies are Pydantic models; do not return ORM objects directly.
- Shared resources (database sessions, clients, settings) come through FastAPI dependencies (`Depends`).
- Settings are loaded once through the project's settings class, not read with `os.environ` throughout the code.

## Rules agents often break

- Inside `async def` endpoints, never call blocking code (`requests`, `time.sleep`, synchronous database drivers). Use async libraries, or make the endpoint a plain `def`.
- Check which Pydantic major version is installed before using its API; v1 and v2 differ.
- No mutable default arguments (`def f(items=[])`).
- No bare `except:`; catch specific exceptions.
- Never edit an Alembic migration that has already been applied. Generate a new one.
- Add type hints to new functions.
- Do not add, remove or upgrade dependencies without approval (company baseline), and keep them pinned in the project's lock or requirements file.

## Checks this kit provides

Ready-made files are in this kit's `checks/` folder; projects get a copy in `.harness/kit/checks/`.

- [ ] Ruff for lint and formatting; mypy where the project is typed
- [ ] Import boundaries (e.g. import-linter): routers do not import the database layer directly
- [ ] CI steps: lint, format check, type check, tests, protected-test check from the company baseline

## Changelog

| Version | Change |
| --- | --- |
| 0.1.0 | Sample kit |
