---
tags:
  - game
  - map
---
A [[game]] **map** consists of an array of layers, which contain an array of tiles. Layers exist at some offset from the map's origin and have some size. Tiles occupy a flat array on each layer, and have a `kind`, which is a [[linking|link]] to some [[compiled_data|data]] defining how the tile looks. 
  
Currently the internal representation of maps is likely to change!

On [[client|client-side]], maps are loaded by the [[game_mgr|GameMgr]] once the client connects to a [[server]], while on server-side there will likely be several maps loaded at a time.    

The actual data of a game map is stored in a [[map_state|MapState]], which in normal gameplay is owned by the [[map_entity_system|MapSys]], but may be loaded to be displayed for other purposes such as [[map_editor|map editing]].