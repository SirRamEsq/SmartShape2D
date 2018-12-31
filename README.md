# RMSmartShape2D
---
![sample image](addons/rmsmartshape/sample/sample_screen.PNG)

## Changes in 0.91
- edges are calculated in relationship to object space instead of screen space
- added option to allow user to let the object recalculate edges based on screen space.
- fixed uv calculations for flipped textures.
- fixed uv bug for edge sections less than half the size of texture width
- added option to allow for a RMSmartShapeAnchor to mimic scale of monitored node
- removed sections of code related to clockwise versus clockwise checks, very specifically regarding the direction of texture edges.
- corrected normal texture bug for fill and edge rendering  


## About
This plugin, currently aimed at the Godot Game Engine 3.1+, provides the ability create non-uniform shaped objects using assets very similar to what you would use if producing your levels with tilesets.

## Shape Materials
Shape materials, known as RMSmartShapeMaterial, provides all the texture and collision information needed by the RMSmartShape2D node.  The shape material focuses on rendering of the non-uniform shape as if it was a nine-patch image (minus the corners).  Once a shape material is defined, it can be easily reused by any number of RMSmartShape2D nodes.

## Rendering the Shape Material
In order to show your fancy shape material you must first create a RMSmartShape2D node.  Then do the following two things:
1. Assign the material to the Shape Material property of the node.
2. Plot your points within the editor to represent your shape.

## Anchoring Nodes to Sections of the Shape Node
You might have a desire to anchor nodes to various sections of the RMSmartShape2D node.  This is helpful in the level design by helping to automatically move other nodes in relation to the edited shape node.  Or, in the future, it might be useful adjust a shape dynamically and have the surrounding objects be affected by adjustments in the shape's contour.

This is done by use of the RMSmartShapeAnchor2D node.

## Current State of the Tool
The tool already appears to be quite useful, and is mostly complete.  However, until it is being utilized by others it is difficult to say.  Therefore, I would consider this tool to be beta at the moment.

## Hidden Features
Currently the editor support the ability to modify the texture index on a control point handle by simply hovering over the control point and moving your mouse wheel up or down.  You can also change the direction of the texture being displayed by hovering over the control point and clicking the space bar.  This will probably change though as it doesn't consider the differences in mouse wheel speed.  Suggestions are welcome.

