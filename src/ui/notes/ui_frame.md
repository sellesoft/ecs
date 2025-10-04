---
tags:
  - ui
---
The [[ui|ui system]] operates around beginning `UI::beginFrame()` and ending `UI::endFrame()` a frame, during which ui elements may be placed.

A frame tracks a several important objects:
* [[ui_layer|Layers]]
  Stores a list of panels in the order they were begun in the layer as well as a command list and command list stack. Currently, pushing a layer also begins a new panel in that layer.
* [[ui_panel|Panels]]
  Stores a list of groups, a parent panel, and the next panel of the layer this one was begun in. Panels are currently associated with an item, and so have a unique id. 
* [[ui_group|Groups]]
  Stores bounds in local-space, screen-space scissor bounds, the extents of the group's contents, a list of items created in the group, and the way the group's contents should be scissored.
* [[ui_item|Items]]
  Associated with a unique identifier as well as some bounds in local-space, the next item occurring in this item's group, and the id of the popup the item was placed in (if any).
* [[ui_cmd|Commands]]
  A draw command stored in command stacks which are stored on layers. These are organized during a frame then executed in `render()`.

When ui begins a frame, it creates a root **panel**, **group**, and **layer** encompassing the provided viewport area. The root and current layers are tracked on the UI state. During the frame, layers may be pushed or popped and panels/groups may be begun or ended. 
