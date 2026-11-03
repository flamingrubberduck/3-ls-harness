# Stack kit: PHP / Laravel

Version: 0.1.0 · Owner: Engineering practice group

Sample kit: review and adapt before use. Rules for every Laravel project. The project's AGENTS.md lists exact commands and anything that differs.

## Commands

- Install: `composer install`
- Tests: `php artisan test`
- Formatting check: `vendor/bin/pint --test` (if the project uses Pint)
- Static analysis: `vendor/bin/phpstan analyse` (if the project uses PHPStan or Larastan)

## Structure

- Controllers stay thin: validate with a Form Request, call a service or action class, return a response or API resource.
- Business logic does not live in controllers, Blade views or route closures.
- API responses go through API Resources, not raw models.
- Configuration is read with `config()`. Call `env()` only inside `config/` files; it returns null once configuration is cached.

## Rules agents often break

- Protect models from mass assignment with `$fillable` (or `$guarded`); never pass unfiltered request input to `create()` or `update()`.
- Avoid N+1 queries: eager-load relations with `with()` when looping over models.
- Never interpolate input into raw SQL (`DB::raw`, `whereRaw`); use bindings.
- Never edit a migration that has already run. Add a new migration instead.
- No secrets in committed config or `.env.example`; real values belong in `.env`, which is never committed.
- Do not add, remove or upgrade Composer packages without approval (company baseline).

## Checks this kit provides

Ready-made files are in this kit's `checks/` folder; projects get a copy in `.harness/kit/checks/`.

- [ ] Pint for formatting; PHPStan or Larastan at the level the project agrees on
- [ ] Architecture tests (e.g. Pest's arch testing): controllers do not use the `DB` facade directly
- [ ] CI steps: install, format check, static analysis, tests, protected-test check from the company baseline

## Changelog

| Version | Change |
| --- | --- |
| 0.1.0 | Sample kit |
