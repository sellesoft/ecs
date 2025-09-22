---
tags:
  - game
instance-of: system
---
The **game manager** is a [[client|client-side]] system which manages the state of the game as viewed by the user. It tracks the highest level state of the [[game]] which is apparent to the user, such as being in the main menu, server browser, the actual game, and all of the transitions between those things. 

It owns the client's [[entity_system_manager|EntitySysMgr]] as well as the [[game_renderer|GameRenderer]].

It is owned by the client-side [[src/game/client/notes/game_sim|GameSim]], and thus, should be [[record_and_replay|replayable]].