---
tags:
  - resource
  - graphics
---

A **resource** is a [[graphics]] object (or objects) managed by the [[resource_manager|ResourceMgr]]. They consist of one or more [[asset|assets]], which they [[linking|link]] to, and are generally linked to themselves.

Currently the resources supported by ecs are:
* [[texture|Textures]]
* [[font|Fonts]]
* [[shader|Shaders]]
* [[pipeline|Pipelines]]
Shaders and pipelines are sort of a grey area at the moment though. Its likely that shaders wont be considered a resource soon, since we [[asset_hot_reloading|hot reload]] pipelines to change shaders at runtime, and not the shaders themselves.