SmartShape2D - Migration
---

You can continue to use the Deprecated 1.x RMSmartShape2D nodes in your projects, but you cannot edit them with
the 2.x version of the plugin.

If you want to migrate them to a 2.x SmartShape2D node then you can:
- Select a 1.x RMSmartShape2D node in the Scene tree
- This will add a a single icon in the toolbar
- Pressing this icon will recreate the node as a new 2.x SmartShape2D node.
- All the points, control points, and properties will be intact

Note, Materials from 1.x cannot be automatically updated. You'll need to create new
2.x Shape Materials. After updating a RMSmartShape2D node, the new shape's material will be set to NULL.
