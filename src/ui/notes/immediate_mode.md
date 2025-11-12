---
tags:
  - ui
---
**Immediate mode** drawing is an api style in [[graphics]] libraries in which the content drawn to the screen is generated every frame via either calls or some kind of data from the api user. More specifically, the drawn 'scene' is stored externally to the graphics api drawing it, rather than the graphics api storing some persistent information about the scene internally.

The [[ui|ui system]] is an immediate style ui api, and the [[game_renderer|GameRenderer]] can probably also be considered to use the graphics api in an immediate fashion.