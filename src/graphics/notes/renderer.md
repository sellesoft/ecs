---
tags:
  - graphics
---
**Renderer** is, currently, what owns the [[vulkan]] instance and what provides an interface to beginning and ending a [[render_pass|render pass]] on a [[render_target|render target]] and for emitting commands for a render pass.

Eventually, ownership of the vulkan instance will be moved out of renderer and it will likely become more of a single render pass object.

Reworked into [[render_pass|RenderPass]] sometime around 2025-10-01 and [[vulkan]] was moved to the [[editor]].