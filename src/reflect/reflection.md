---
instance-of: directory
tags:
  - reflection
---
ecs makes very heavy use of reflection to generate code. The majority of this reflection is attained via [[lppclang]], a plugin for [[lpp]] that provides a lua interface to clang. This directory, `reflect/`, contains utilities and types directly related to reflection.

## AST
---
While we have an interface to clang, we don't actually use it outside of this directory. The [[ast.lua]] module defines our own AST representation that we use instead. The AST is created by and stored in an AstContext. Our representation is much like clang's, however with some qol differences that make the AST easier to use in code generation. It is also done this way because using the [[lppclang]] interface directly is *very* annoying, trust me!

## Runtime reflection
---
Runtime reflection, or `rtr`, is an api providing information about types at runtime. It is defined in [[rtr.lh]]. The type, `TypeId`, is also a part of runtime reflection and is how types are referred to at runtime. All it is is a hash of a given type's name. A user-defined literal is provided to make getting compile-time `TypeId`s easy: `"Apple"_typeid` will give a `TypeId` and `"Apple"_typeid_val` will give its numerical hash value.