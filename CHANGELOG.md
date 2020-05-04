# Changelog

## 0.16.1
### Bugs
* Fixed bug with interfaces and unions not showing correctly in
    `Assertions.Absinthe.fields_for/2,3` and `Assertions.Absinthe.document_for/2,3`.

## 0.16.0
### Features
* Added `Assertions.AbsintheCase`
* Added `Assertions.Absinthe.fields_for/2,3` to generate a list of fields for a type and all
    sub-types to a given depth of nesting.
* Added `Assertions.Absinthe.document_for/2,3` to generate a document with all fields for a type 
    and all sub-types to a given depth of nesting.
* Added `Assertions.Absinthe.assert_response_equals/2,3,4` to assert the response of sending a
    document equals a given expected result.
* Added `Assertions.Absinthe.assert_response_matchess/2,3,4` to assert the response of sending a
    document matches a given pattern.

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

