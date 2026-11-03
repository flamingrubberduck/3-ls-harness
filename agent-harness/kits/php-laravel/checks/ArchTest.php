<?php

// Architecture rules from the Laravel stack kit (Pest arch testing).
// Put this in tests/ and run it with the rest of the suite: php artisan test

arch('controllers do not query the database directly')
    ->expect('App\Http\Controllers')
    ->not->toUse('Illuminate\Support\Facades\DB');

arch('env() is only called in config files')
    ->expect('env')
    ->not->toBeUsedIn('App');

arch('no debugging calls are left in')
    ->expect(['dd', 'dump', 'ray', 'var_dump'])
    ->not->toBeUsed();
