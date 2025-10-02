---
instance-of: directory
tags: game
---

This directory contains all code related to the game running in the engine. It is separated into three directories, [[client]], [[server]], and `shared`. Client and server may both use code from `shared/`, but must never use code from each other.

ecs is inspired by the entity-component-system architecture popular in game development. The style of ecs used is largely inspired by that of [Space Station 14](https://github.com/space-wizards/space-station-14). 

An [[entity]] is a named bag of [[component|components]]. Components are just data, and [[entity_system|entity systems]] update components, either via an `update()`  (if they define one) or by handling signals raised on entities containing a certain type of component.

