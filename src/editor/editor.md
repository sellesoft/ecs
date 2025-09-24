---
tags:
  - editor
---

The **editor** is a specific build of ecs with special tools for editing [[asset|assets]] and running a [[game]] [[server]] with one more [[client|clients]].

When in an editor build, the `Editor` is owned and updated by the [[engine]]. It uses several subsystems:
* [[input_mgr|InputMgr]]
  For tracking input state.
* [[window|Window]]
  For displaying stuff in a window! And updating the input state.
* [[renderer|Renderer]] 
  For [[vulkan]]. Should be reorganized soon.
* [[asset_manager|AssetMgr]]
  For loading assets!
* [[build_system|BuildSystem]]
  For building assets.
* [[file_watcher_thread|A file watcher]]
  On a thread, for notifying systems about file changes.

And eventually.. a [[server]] and perhaps several [[client|clients]].