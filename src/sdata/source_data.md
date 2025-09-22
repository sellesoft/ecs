---
aliases: SourceData
instance-of: datatype
tags:
  - asset
---

**Source data** is ecs' custom data format. It is primarily used for defining asset data that will be [[packing|packed]] into [[compiled_data|CompiledData]]. However it can be used standalone as well for stuff like config files.

Source data is somewhat like json or lua tables. A source 'datum' may have a name, a type, and either a value or a number of child source data. For example, 
```lua
count = 1
```
is a source datum. This one has a name, `count`, and a value `1`. It has no type, and no children. 
```lua
player = { health = 100, name = "Mark" }
```
This is also a source datum, its name is `player` and it has 2 children. `player` still has no type, and also has no value. It is internally considered to represent 'object' data.

Any source data may omit its name. `"Hello"` is a source datum, as is `1`. `{ count = 1 }` is also a source datum. This is how lists work, for example
```lua
colors = { "blue", "red", "green", "yellow", }
```
Sort of like how they work in lua. However, unlike lua, source data objects cannot contain both named and unnamed children.

As mentioned above, the primary use of source data is packing it into compiled data. A source data file typically returns a source datum with some type. For example, the current definition of `assets/shaders/UI.frag.shader` is: 
```lua
return gfx::ShaderDef
{
	stage = "Fragment",
	source = "assets/shaders/UI.frag",
}
```
A source data file is expected to return a datum, and when that data is to be compiled it is expected to specify the type of data it is returning (unless it is returning a non-object value). Here we are specifying a `gfx::ShaderDef`, which looks like this:
```cpp
struct ShaderDef
{
	iro::String source;
	ShaderStage stage;
};
```
Packing takes the source data and turns it into binary data of type `gfx::ShaderDef`. This data is usually then compiled to disk such that we may quickly load it later on and, eventually, package it.