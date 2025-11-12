---
tags:
  - editor
---

The **editor** is a specific build of ecs with special tools for editing [[asset|assets]] and running a [[game]] [[server]] with one more [[client|clients]].

When in an editor build, the `Editor` is owned and updated by the [[engine]]. It uses several subsystems:
* [[editor_log|EditorLog]]
  The editor's log channel which gets fed to the [[editor_console|console]] and stdout.
* [[input_mgr|InputMgr]]
  For tracking input state.
* [[window|Window]]
  For displaying stuff in a window! And updating the input state.
* [[vulkan|Vulkan]]
  Currently owns the vulkan device handle because I wanted to get it out of the old [[renderer]]. Its possible it might be moved up to [[engine|Engine]] again, but not sure yet.
* [[resource_manager|ResourceMgr]]
  For tracking graphics resources.
* [[asset_manager|AssetMgr]]
  For loading assets.
* [[build_system|BuildSystem]]
  For building assets. There is also a thread for asynchronously building assets at runtime.
* [[ui|UI]]
  For drawing the editor and its documents' UI.
* [[file_watcher_thread|A file watcher]]
  On a thread, for notifying systems about file changes.
* [[document_manager|DocMgr]]
  A system which manages [[editor_document|documents]]. Documents are displayed in a [[editor_doc_tree|tiled style]]. Originally they were displayed as [[editor_doc_windows|windows]], but that has been disabled for now until popping out docs seems useful.
* [[editor_console|Console]]
  For displaying logs and accepting commands from the user.
* [[command_bus|CommandBus]]
  For tracking what commands have been registered with the editor. Probably split up soon.
* [[editor_menu_bar|MenuBar]] 
  The editor's menu bar which displays across the top of the window.

The editor is currently capable of spawning multiple [[server|servers]] and [[client|clients]] via [[server_instance|ServerInstance]] and [[client_instance|ClientInstance]]. Client instances run on their own thread.