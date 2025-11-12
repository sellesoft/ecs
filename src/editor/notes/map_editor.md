---
tags:
  - editor
  - editor-doc
---
The **map editor** is an [[editor_document|editor document]] that will handle editing the [[game]] [[map]]. 

It is currently (2025-10-09) being implemented in the [[test_document|test document]].

At the moment, it works much like the very early initial attempt at making a map editor for ecs. It stores a [[map_state|MapState]], a [[linking|link]] to a map def, a [[game_renderer|GameRenderer]], an [[entity_manager|EntityMgr]] and a view (to be moved hopefully). 

It loads the map def into the map state (this is actually what map state was pulled out for) and uses the game renderer to render it. 