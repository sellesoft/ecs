---
tags:
  - graphics
  - resource
instance-of: system
---
The **resource manager** is a subsystem that owns and manages access to [[graphics]] [[resource|resources]]. Currently these are:
* [[texture|Textures]]
* [[shader|Shaders]]
* [[font|Fonts]]
* [[pipeline|Pipelines]]

Each loaded resource is assigned a unique name, and attempting to load that resource again results in the same, already loaded resource. A resource manager is an important half of [[asset_hot_reloading|asset hot reloading]], the other being an [[asset_manager|asset manager]].