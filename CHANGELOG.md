# Changelog

## 0.15.0
### Features
* Added `assert_raise/1`, which is essentially a less strict version of the
    builtin assertions `assert_raise/2` and `assert_raise/3`.

## 0.14.1
### Bugs
* We had a bug where `assert_map_in_list/3` would always pass and would never
    fail when it should have failed, and this is now fixed.

### Features

## 0.14.0
### Bugs

### Features
* Added ability to use assertions that raise an error instead of just returning
    `false` as comparison functions, so assertions can now be composed much more
    easily.

