---
tags:
  - asset
  - reflection
---

[[asset|Asset]] and [[resource]] **linking** is how assets/resources refer to each other in ecs, and is a major part of how [[asset_hot_reloading|asset hot reloading]] functions.

Currently 'linking' just involves a ridiculous amount of double pointers to whatever the link refers to so that the referenced data may be swapped out at any time w/o needing to update every reference to it (that is the hope at least!).