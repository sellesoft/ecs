---
tags:
  - ui
---
A ui **layer** is a [[ui_frame|frame]] scoped object that is used to separate command lists. [[ui_cmd|Commands]] from layers are emitted starting from the root layer, such that they represent separation of UI elements across the z-axis.