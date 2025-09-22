---
up: "[[reflection]]"
instance-of: directory
tags:
  - directory
---

Here in `tools/` are various independent *tools* that perform work outside of the main ecs executable. 

Its important to note that code in `tools/` may freely use code from `src/`, but code in `src/` must never use anything from `tools/`.

## Tools
---
* [[loggen]]
  Used to generate logging code used by ecs.