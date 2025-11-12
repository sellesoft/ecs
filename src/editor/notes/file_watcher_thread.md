---
tags:
  - editor
---
The **file watcher thread** is an [[src/editor/editor]] thread that uses [[iro|iro's]] [[iro_file_watcher|FileWatcher]] api to monitor changes in directories that the editor cares about. Currently this includes the [[source_asset_dir|source asset]] and [[compiled_asset_dir|compiled asset]] directories. 

The primary reason for this being on its own thread is that it allows us to block when asking the OS for file change events as well as sanitize them before the editor emits them as events. 

Most programs will do several things on the file system when modifying a file. For example, [[neovim|nvim]] will perform several actions upon saving a text file:
![[nvim-file-actions.png]]
`test~` is, I believe, a swap file used by neovim to prevent data loss in the event that something goes wrong while saving the file. However the only even we actually care about is that `test` was modified. The thread attempts to filter out irrelevant events before the editor iterates them to raise events. [[aseprite]] has similar odd behavior when exporting as well.

The way it does this at the moment (2025-10-09) is very heauristical and tied to how certain programs I use behave. It will probably break as other programs are used. Though, I don't think anything actually listens to file events atm.