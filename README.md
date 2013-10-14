# type-precedence [![Build Status](https://travis-ci.org/zaboco/type-precedence.png?branch=master)](https://travis-ci.org/zaboco/type-precedence)

`type-precedence` is a library used to determine precedence of types that can be checked with [`type-check`](https://github.com/gkz/type-check). So, if a value mathes more types, you can find the most specific one. Used, for example in [`defn`](https://github.com/zaboco/defn), to choose the best signature of an overloaded function.
> For reference on how a type can be specfied, please see [Type Format](https://github.com/gkz/type-check#type-format) or [Quick Examples](https://github.com/gkz/type-check#quick-examples) for `type-check`

```sh
$ npm install type-precedence
```
## Type Precedence

* `__ <= *` - * is the most general type _(`__` stands for any type)_
* `{x: __} < Object` - an explicit object is more specific than `Object`
* `[__] < Array` - same as for object
* `{x: __} < {...}` - a subset is more general
* `{x: __, y: __, ...} < {x: __, ...}` - a subset with more keys specified is more specific
* `TypeA < TypeA | TypeB`
* `TypeA < Maybe TypeA`
* `Number | String < String | Number` for value `1`
* `String | Number < Number | String` for value `'s'`
* everything\* above applied recursively for `[arrays]`, `{fields}` or `(tuples)` (e.g `{x: [Number]} < {x: [*]}`)

_\*actually __almost__ everything - `(String | Number, *)` and `(Number | String, *)` would be equal for any value. So ambiguous `|` (i.e. where you need a target value to decide which is best) will not work recursively._

## Usage
> _the following examples are written in [LiveScript](http://livescript.net/), but, of course, the library can be used for javascript too_

```ls
{best-type, sort-types, compare-types} = require \type-precedence
```
### .best-type in: types[, matching: target]
Gets the most specific type from a list of types, optionally matching a target value
```ls
best-type in: <[Array [*] *]> # [*]
best-type in: ['Number | String', 'String | Number'], matching: 1 # 'Number | String', since the value is a Number
```

### .sort-types types[, matching: target]
Sorts the types by precedence - the most specific will be first in the sorted list. It optionally checks against a target value
```ls
sort-types <[Array [*] *]> # <[[*] Array *]>
sort-types ['{x: Number, ...}' '{...}' '{x: *}' '*' 'Object'] # ['{x: *}' '{x: Number, ...}' '{...}' 'Object' '*']
```

### .compare-types type-a, type-b[, matching: target]
Compare two types, optionally checking against a target value. It returns -1, 0, or 1.
```ls
compare-types '{x: String, ...}', '{x: *, ...}' # -1
compare-types '(*)', '(Object)' # 1
compare-types '{x: *, ...}', '{y: *, ...}' # 0 - two subsets with same number of specified keys
```

### ... matching: target
Providing the optional argument `matching: target` to any of the functions above will do the following:

* help choosing the best type when ambiguous
```ls
compare-types 'Number | String', 'String | Number' # 0, because there is no clear winner
compare-types 'Number | String', 'String | Number', matching: \string # 1, because 'String | Number' is more specific in this case
```

* validate the types against the target value, throwing an Error if one of the types doesn't match
```ls
compare-types 'Number', 'String' # 0
compare-types 'Number', 'String', matching: 1 # throws '<1> does not match <String>'
```
