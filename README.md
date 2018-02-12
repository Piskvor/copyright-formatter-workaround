# copyright-formatter-workaround
## What is this?
A workaround for [WI-30420](https://youtrack.jetbrains.com/issue/WI-30420): **Copyright plugin should insert block comment, not phpdoc block**

PHPStorm is IMHO *the* best IDE for PHP, yet currently has a minor bug: the copyright updater insists on double-asterisk commenting, even though it ought not, according to its own preview:

Settings » Editor » Copyright » Formatting » PHP » Preview (with default settings):

```php
/*
 * Copyright Foo Bar 2018. Baz quux quuux etc.
 */
```

Code » Update Copyright:
```php
/**
 * Copyright Foo Bar 2018. Baz quux quuux etc.
 */
```

## Why is this an issue?
Not everyone is in charge of their coding style, and the phpdoc-style comment might not be appreciated. Hence this workaround - until this is fixed in PHPStorm itself, it's better than updating the copyrights by hand.

## How it works?
Run this script either in your pre-commit hook, or with the [Pre Commit Hook Plugin](https://github.com/yahely/PreCommitHookPlugin).

It relies on a particular order of operations:
1. Commit dialog is brought up and `Update Copyrights` checked
2. `Commit` is pressed
3. builtin Update Copyrights runs
4. pre-commit hook runs

This order does work for me in PhpStorm 2018.1 EAP, I have no idea if the ordering could change. 

## Caveats
I did not test this beyond [Shellcheck](https://github.com/koalaman/shellcheck) or outside my usual environment - that is, it works with current Linux and bash, and assuming a rather conventional environment (no whitespace in names etc; should work with diacritics, probably). Uses `git status` at one point - should be adaptable to another VCS easily.

In other words, this *should* work, and it *#worksforme*; yet YMMV: if it breaks, you can keep both parts.
