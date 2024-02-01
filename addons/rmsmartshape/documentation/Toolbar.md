# SmartShape2D - Toolbar

![Toolbar Default State](./imgs/Toolbar-PointEdit.png)

<!-- TODO: Incomplete set of tools presented here. -->

## Create Mode

- In this mode you can start creating a new shape.
- Left-Click anywhere to add a new point.
- Press ESCAPE to exit create mode.
- Hold down ALT and Left-Click to create a point between the two points closest to your mouse.

## Point Mode

- In this mode you can add, delete, and move all of the points that make up a shape
- To **Add** a new point to the shape:
  - Hold down ALT and Left-Click anywhere on the viewport to add a point between the two points closest to your mouse.
  - Left-Click on an edge between two points.
- To **Move** a point, Left-Click on any point and drag
- To **Delete** a point, Right-Click on any point
- To set the **Control Points** of a point (for curves), hold **Shift**, Left Click on any point and drag
  - After the Control Points have been set, you can edit them individually by Left-Clicking and dragging
  - You can delete control points by right clicking them
 - To make an empty clone SmartShape2D, hold down ALT + SHIFT and Left-Click anywhere in the viewport.

## Edge Mode

- In this mode you can Move Eges and choose how specific edges are rendered
- To **Move** an Edge, Left Click and Drag the Edge
- To **Change an Edges Rendering**, right click the edge and press "**Material Override**"
![EdgeData Popup](./imgs/EdgeEdit-MaterialOverride.png)

- This popup allows you to **change how edges are rendered**
  - **Render** will toggle whether or not this edge will be drawn with Edge Materials
  - **Set Material** allows you to choose a specific Edge Material to use to render this edge

## Origin Set

- This tool allows you to set the origin of any SmartShape
- To **Set the Origin** Left Click anywhere on the viewport

## Generate Collision

- If you want your shape to have collision, press this button to autogenerate the collision nodes
- The shape will be made a child of a newly created **StaticBody2D**
- A sibling node, **CollisionPolygon2D** will also be created and added to the SceneTree
  - The "Collision Polygon" parameter of the Shape will be set to this sibling **CollisionPolygon2D**

## Snapping

When Moving / Adding points, snapping will cause the positions of the points to snap to the grid. This works the same as Godot's built-in snapping.
You can have snapping either use Global Space, or space relative to the shape's origin.
