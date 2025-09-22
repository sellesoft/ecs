---
tags:
  - graphics-object
  - graphics
---
A **graphics object** is some data that is used by the [[vulkan|graphics backend]] to do some kind of [[graphics]] stuff.

ecs provides a low-level api for interacting with these objects, however they are typically managed by a higher-level api. These objects are:
* [[buffer|Buffers]]
* [[descriptor_set|Descriptor sets]] and [[descriptor_set_layout|descriptor set layouts]]
* [[image|Images]], [[image_view|image views]] and [[sampler|samplers]].
* [[shader|Shaders]] and [[pipeline|pipelines]].
