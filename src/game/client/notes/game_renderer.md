---
aliases:
tags:
  - graphics
  - game
  - client
instance-of: system
---
The **GameRenderer** is a [[client|client-side]] [[game]] system that handles rendering the state of the game. Currently this specifically involves rendering the [[map]] and any [[sprite_component|sprite components]].

The game is rendered to a [[render_target|RenderTarget]] via the [[renderer|Renderer]]. It either renders the game from the client's [[eye]] or from a [[view]] if one is provided. 