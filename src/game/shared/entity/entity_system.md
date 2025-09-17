---
subclass-of: system
---

An **entity system** is a system which manages updating [[component|components]], either in an `update()` method, by handling events raised on [[entity|entities]] with a certain type of component, or both. 

Entity systems are singletons, that is, they only exist in data once. They are created and managed by the [[entity_system_manager|EntitySysMgr]]. They are expected to define an `init()` method in which they can subscribe to events and initialize any state they may need to. If a system defines an `update()` method, it will be called during the `EntitySysMgr`'s update. Constraints on the order that entity systems are updated have yet to be implemented.