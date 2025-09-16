# Main source tree.

`src/` contains code that's compiled into the ecs editor and game executables. 

## Source tree summary.
(as of 2025/15/09)

* `asset/`
  The `Asset` type, and the `AssetMgr` which manages them.

* `build/`
  ecs' asset build system.

* `core/`
  Important core types, systems and utilities that are more or less expected
  to be used everywhere. One of the most important things in here is ecs'
  logging system.

* `editor/`
  All code related to the editor build of ecs.

* `event/`
  Currently, just the broadcast event bus. Will either be removed eventually
  or more stuff will be put here.

* `external/`
  To be moved to the third_party/ directory.

* `game/`
  All code related to the game running in ecs' engine. Entity stuff, 
  entity systems, components, the Client and Server, etc.

* `graphics/`
  ecs' graphics front and backend stuff. Vulkan is currently the only supported
  backend (and its expected to stay that way for awhile).
  Also in here is the `AssetMgr`'s sister, `ResourceMgr`.

* `input/`
  Definitions of types relating to input as well as the `InputState` type
  and the `InputMgr` that handles altering state from one frame to the next.

* `math/`
  Common math types and utilities. Should maybe be moved into `core/`.

* `net/`
  The networking api, used by `Client`s and `Server`s (defined in `game/`) to
  talk to each other.

* `reflect/`
  Systems/types/apis/and such used to generate reflected compile time code
  as well as an api for getting runtime type information.

* `sdata/`
  All types/apis/stuff relating to our custom SourceData format.

* `ui/`
  ecs' ui system.

* `window/`
  The Window type and platform specific stuff related to windows.
