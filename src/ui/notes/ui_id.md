---
tags:
  - ui
---


A **ui id** is some integer value uniquely identifying something in the [[ui|ui system]]. Typically an id is associated with some [[ui_item|Item]], but also see more general use in some cases.

Ids in are either plain, an `ItemId`, or combined, a `CombinedItemId`. The api typically takes in `ItemId`s, which it then forms a `CombinedItemId` from by [[hashing|hash]] merging the id with the last id stored in ui's **id stack**.

This behavior is meant to make uniquely identifying ui elements easy. At the lowest level, you may use `UI::pushId()` and `UI::popId()` to manipulate the id stack. For example, if you wanted to place UI for multiple game objects that might have some buttons to interact with them, you can do so like this:
```cpp
void putObjectUI(ui::UI& ui, u64 obj_id)
{
	ui.pushId(ui.generateIdFromInteger(obj_id));
	defer { ui.popId(); };
	
	if (ui.putButton("reset-button"_fid, ...)) { ... }
	
	if (ui.putButton("kill-button"_fid, ...)) { ... }
	
	...
}
```
Pushing an id using the object's id makes any id used before its popped unique to that object (given that the game assigns each object a unique id!). 

Some low level ui objects do this automatically, [[ui_panel|Panels]] (and so, [[ui_layer|Layers]]) push their provided id when they are begun and pop then when they are ended. 