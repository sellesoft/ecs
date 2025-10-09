---
tags:
  - editor
---
At the moment (2025-10-09), [[editor]] [[editor_document|documents]] are displayed in a tiled layout via the [[document_manager|DocMgr]]. 

When the DocMgr was first implemented, docs were displayed as [[editor_doc_windows|windows]], but that wound up being somewhat annoying as the primary display mode. One night I remembered that I had really enjoyed [[blender|blender's]] tiling of.. whatever they call their equivalent of documents. After trying it again I decided that I wanted the editor's document tiling to work like that.

So far, documents can be split and resized via the mouse. The resizing was an especially interesting fun thing to get working like blender as they do this thing where only adjacent tiles are resized rather than entire adjacent splits. It looks like this: 
![[doc-tiled-resize-example.gif]]
The behavior where the file explorer and client instance in top-middle make room for the tiles being resized to their left and right. This is opposed to the top-middle 'split' resizing every tile in it (as in the split itself would be getting resized, not its children).

A more complete example of the tiling can be seen here:
![[doc-tiled-resize-add-remove-example.gif]]

I want to eventually support the neat dragging that blender supports, where you can move/merge/replace other tiles with one being dragged around. 