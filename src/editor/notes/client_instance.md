---
instance-of: editor-doc
tags:
  - editor
  - editor-doc
---
A **client instance** is an [[editor]] [[editor_document|document]] that runs a [[client|game client]] on a [[thread]].

Currently:
* The client is ticked every 3 milliseconds. 
* [[input|Inputs]] are accumulated into the thread every `ClientInstance::update`, then reset by the thread after it finishes a tick.
* [[render_pass|Rendering]] is synchronized by a [[mutex]] that the thread locks during a tick, and which the `ClientInstance` locks in `render()`.  We also don't try to render until the thread sets `new_frame`, which it does after each tick. Rendering sets this back to false. This should probably be done better!
* The client can be paused and reset.
* The client's log can be dumped to the [[editor_log|editor's]].
* The client is rendered into a [[texture|Texture]] which is then displayed in a [[ui]] quad.


A bunch of clients random walking around but with the [[editor_doc_tree|tree style document layout]] and using the basic [[collision_sys|collision system]] (apparently they can push the tables for some reason).
2025-10-09
![[client-walk.gif]] 

A bunch of clients random walking around (not connected to a server or anything) 2025-10-01: 
![[Peek 2025-10-01 22-14.gif]]