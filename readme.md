## Source tree summary.
(as of 2025-09-16)

Here is a summary of the top level source tree of ecs. Most sub-directories (should) have their own readme, which explain their content in more detail or links to other notes explaining specific things.

* assets/
  Contains source assets used in ecs' engine, game, and editor. These are typically either binary source assets (such as a `.png`, `.bdf`, etc.) or are our custom [[SourceData]] format.
* bin/
  External tool binaries used by ecs in one way or another. The primary tools being `lake`, the build system, and `lpp`, the preprocessor ecs was originally started to test.
* include/
  `iro`, and various other definitions from internal, `enosi` tools that are useful for IDEs.
* lib/
  `enosi` libraries used by ecs. Currently only [[lppclang]].
* [[src/readme|src/]]
  The main source tree of ecs. Contains the code that builds the game and editor.
* tests/
  Various isolated tests, mainly for getting something working outside of the main source tree before trying to fully integrate it. Eventually, unit tests that are run regularly should go here as well.
* third_party/
  Any code or libraries that do not come from enosi. This includes things like clang/llvm, luajit, shaderc, etc.
* tools/
  Various tools used to do things related to ecs, whether it be a custom tool run as a build step, tools for manipulating assets and their compiled data, etc. Each thing in here (probably) compiles to its own exe that can be used independently of ecs.

There are also a couple of generated directories that will show up after compiling ecs, as well as after running the editor/game/build tool (when that's a thing). These are:

* \_build
  Build objects generated while building ecs or its tools. These are kept for incremental building, but this folder may be deleted at any time if you wish; you will just have to rebuild all of ecs. This folder may also be removed by using `lake clean`.
* \_data
  Compiled assets, which appear after the game, editor, or build tool (eventually) have run. These are also cached and compiled incrementally. 
  `TODO(sushi) add a way to clean this with lake`
* \_trash
  A special folder used by ecs' asset build system to move files that it would otherwise decide to delete. This is primarily a safety thing, but it can also be nice for debugging. The build system will never outright delete a file and will always move it to \_trash instead.
  `TODO(sushi) also need a way to clean this`