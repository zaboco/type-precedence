{any, all, first, find, filter, map, sort-by, sort-with, values, zip-with} = require \prelude-ls
{parse-type, parsed-type-check, type-check} = require \type-check

__ = -> true # wildcard, matches anything in check-order

# checks order using predicates
check-order = (of: [a, b], using: [pa, pb]) ->
  | a is b => 0
  | pa a and pb b => -1
  | pa b and pb a => 1
  | _ => false

compare = (a, b) ->
  | a < b => -1
  | a > b => 1
  | _ => 0

compare-by = (comparator, a, b) -->
  compare (comparator a), (comparator b)

minimum-with = (comparator, list) -->
  first sort-with comparator, list

# assumes lists same size
compare-lists-with = (comparator, la, lb) -->
  [la, lb] = map (sort-with comparator), [la, lb]
  (find (!= 0), zip-with comparator, la, lb) ? 0

n-keys = (obj) ->
  Object.keys obj .length

different-size-subsets = (a, b) ->
  a.subset? and b.subset? and (n-keys a.of) isnt (n-keys b.of)

both-are-arrays = (a, b) ->
  (typeof! a) is (typeof! b) is \Array

both = (a, b, have: property, value) ->
  a[property] is b[property] is (value ? a[property])

both-are-structure = (structure, a, b) ->
  both a, b, have: \structure, structure

compare-all-fields-values = (a, b) ->
  compare-lists-with compare-parsed, (values a.of), (values b.of)

compare-all-tuple-items = (a, b) ->
  compare-lists-with compare-parsed, a.of, b.of

best-parsed-type = (in: parsed-types, matching: target) ->
  parsed-types = filter (-> parsed-type-check [it], target), parsed-types if target
  minimum-with compare-parsed, parsed-types

compare-bests = (la, lb, matching: target) ->
  sign = compare-parsed (best-parsed-type in: la, matching: target), (best-parsed-type in: lb, matching: target)
  return if sign then sign else false  # compare otherwise if equal

index-of-match = (list, target) ->
  list.index-of find (-> parsed-type-check [it], target), list

compare-indexes = (la, lb, matching: target) ->
  indexes = map (index-of-match _, target), [la, lb]
  compare ...indexes

compare-parsed = (a, b, target) ->
  | both-are-arrays a, b and both a, b, have: \length, 1 => compare-parsed a.0, b.0
  | both-are-arrays a, b and sign = compare-bests a, b, matching: target => sign
  | both-are-arrays a, b => compare-indexes a, b, matching: target
  | a.type? and b.type? => compare-parsed a.type, b.type
  | sign = check-order of: [a, b], using: [(.structure?), (.type? and not it.structure?)] => sign
  | sign = check-order of: [a, b], using: [(not) << (.subset), (.subset)] => sign
  | sign = check-order of: [a, b], using: [(is \Null), (is \Undefined)] => sign
  | sign = check-order of: [a, b], using: [__, (is \*)] => sign
  | different-size-subsets a, b => compare-by (-> -n-keys it.of), a, b
  | both-are-structure \array, a, b => compare-parsed a.of, b.of
  | both-are-structure \fields, a, b => compare-all-fields-values a, b
  | both-are-structure \tuple, a, b => compare-all-tuple-items a, b
  | _ => 0

type-mismatch = (t, target) ->
  not type-check t, target

throw-mismatch-error = (t, target) ->
  throw new Error "<#target> does not match <#t>"

validate-types = (types, against: target) ->
  for t in types then throw-mismatch-error t, target if type-mismatch t, target

compare-types = (ta, tb, target) ->
  validate-types [ta, tb], against: target if target
  [pa, pb] = map parse-type, [ta, tb]
  compare-parsed pa, pb, target

sort-types = (types, {matching}={}) ->
  types = filter (-> type-check it, matching), types if matching
  sort-with (compare-types _, _, matching), types

best-type = (in: types, matching: target) ->
  first sort-types types, matching: target

module.exports = {compare-types, best-type, sort-types}
