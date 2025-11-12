---
tags:
  - game
  - map
---
The **map state** is the actual data that represents the state of the [[game]] [[map]]. Originally the data was stored directly on the [[map_entity_system|MapSys]], but in order to be able to display the map in something like the [[map_editor|map editor document]] without setting up all of the [[entity_system_manager|game systems]], we needed to pull it out.