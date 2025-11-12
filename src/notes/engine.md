---
tags:
  - system
  - engine
---
All of [[ecs]] runs under the **Engine**, which is continuously updated by the main loop.

The engine handles command line arguments, owns the [[code_hot_reloading|hreload Reloader instance]], and, depending on the build, owns the [[editor]] or the [[client]] or [[server]] (depending on command line arguments).