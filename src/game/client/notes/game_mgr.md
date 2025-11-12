---
tags:
  - game
  - client
instance-of: system
---
The **game manager** handles the highest level game states as seen by a [[client]], such as the main menu, a server browser, settings, the actual game, etc. as well as the transitions between them.

It owns several systems:
* [[entity_manager|EntityMgr]]
  For managing [[entity|entities]].
* [[entity_system_manager|EntitySysMgr]]
  For creating and updating the client side [[entity_system|entity systems]].
* [[game_renderer|GameRenderer]]
  For rendering the game when asked to.

