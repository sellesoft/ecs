---
tags:
  - game
  - client
---
A `Client` manages all systems needed to run the [[game]] (as a client!) as well as establish a connection to a [[server]]. Currently these are:
* [[net_manager|NetMgr]]
  For handling connection and communication with a [[server]].
* [[game_manager|GameMgr]] 
  Handles the highest level states of the game as viewed by a client, like the main menu, a server browser, the actual game, etc. as well as the transitions between them.
* [[game_log|GameLog]]
  Currently just collects all log entries made through it.

At the moment clients can only be made by spawning a [[client_instance|ClientInstance]].

The client used to control a [[src/game/client/notes/game_sim|game sim]], but that has been merged into `Client`, since much of that separation was only needed to how the [[editor]] used to be organized.