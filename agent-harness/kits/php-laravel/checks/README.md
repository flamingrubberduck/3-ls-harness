# Checks: PHP / Laravel

| File | Put it in | Needs | Run |
| --- | --- | --- | --- |
| `phpstan.neon` | Repository root | `larastan/larastan` | `vendor/bin/phpstan analyse` |
| `pint.json` | Repository root | `laravel/pint` | `vendor/bin/pint --test` |
| `ArchTest.php` | `tests/` | Pest | `php artisan test` |

PHPStan with Larastan catches type and Eloquent mistakes; raise `level` as the codebase allows. Pint enforces the Laravel code style. The Pest arch tests fail when a controller uses the `DB` facade, when `env()` is called outside `config/`, or when debugging calls are left in.

Projects on PHPUnit instead of Pest can skip `ArchTest.php` and keep the same rules as review points.
