---
layout: default
title: "Language: Type Aliases"
canonical: "/puppet/latest/reference/lang_type_aliases.html"
---

[reserved]: ./lang_reserved.html


Type aliases allow you to create reusable and descriptive types.

## Syntax

Type aliases are written as `type <NAME> = <TYPE DEFINITION>`, the alias name beginning with a capital letter. The alias name must not be a [reserved word][reserved]. 

As an example:

~~~
type MyType = Integer
~~~

Would make `MyType` equivalent to `Integer`.

This mechanism is used for several reasons:

* Shortening complex type expressions and moving them "out of the way".
* Giving a type a descriptive name; e.g. `IPv6Addr` rather than just using a complex pattern based type.
* Reuse of types increases the quality as not everyone has to invent types like `IPv6Addr`.
* Type definitions can be tested separately.


## Type loading

Type aliases are auto loaded using the same loading rules and restrictions as functions except for what is noted here:

* Compared to functions which are loaded from `<root>/functions/`, types are loaded from `<root>/types/`.
* The name of the `.pp` file defining the alias must be the alias name in lower case without underscore separators inserted at "camel case" positions. Thus `MyType` is expected to be loaded from a file named `"mytype.pp"`.


## Recursive types

Creating recursive types is allowed:

~~~
type Tree = Array[Variant[Data, Tree]]
~~~

This type definition allows a tree that is built out of arrays that contain data, or a tree 

~~~
[1,2 [3], [4, [5, 6], [[[[1,2,3]]]]]]
~~~

A recursive alias may refer to the alias being declared, or other types.

This is a very powerful mechanism that allows higher quality type definitions. Earlier references like these were impossible, the only option was to use `Any`.


## Aliasing resource types

It is also possible to create aliases to resource types.

~~~
type MyFile = File
~~~

When doing this, it is recommended to use the short form such as `File` instead of `Resource[File]`.


## Type aliases and type references are transparent

The Puppet language aliases are transparent such as:

~~~
type MyInteger = Integer
notice MyInteger == Integer
~~~

notices `true`.

The internal type system types TypeReference and TypeAlias are never values in a puppet program.


## Best Practice

* Use autoloading of type aliases
* It is ok to use type aliases in manifests when showing examples, when doing experiments etc.
* Always namespace type aliases with module name



