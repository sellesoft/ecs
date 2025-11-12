---
tags:
  - graphics
  - resource
---
**Shaders** in ecs are currently written in glsl, but could be written in any language that compiles to SPIRV, probably. 

Currently shaders are a [[resource]], but that might change soon as there's really no reason for them to be with [[pipeline|pipelines]] being a resource.

The structure of shaders (vertex format, push constants, etc.) is very restricted atm, but ideally this changes as pipelines become more friend to being parameterized in [[source_data|data]].