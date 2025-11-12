---
tags:
  - asset
---

An **asset** is some data loaded by ecs at runtime.  They are things like [[font|fonts]], [[texture|textures]], [[shader|shaders]], [[compiled_data|compiled data]], etc, loaded by something like the [[editor]] or the [[game]].

Assets are managed by the [[asset_manager|AssetMgr]], and are typically referred to via [[linking|links]] to facilitate [[asset_hot_reloading|asset hot reloading]].

Most assets are referred to by [[resource|resources]], which are [[graphics]] objects that are managed by the [[resource_manager|ResourceMgr]].