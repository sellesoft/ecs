---
tags:
  - graphics
---

A **render pass** is currently just an interface to executing render commands during a [[graphics_frame|frame]]. It is what was left of [[renderer]] after ownership of [[vulkan]] was removed from it. Will probably be pulled out into a free function api eventually.