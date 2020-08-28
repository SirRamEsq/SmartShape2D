SmartShape2D
---
![sample image](addons/rmsmartshape/sample/sample_screen.PNG)


# About
This plugin allows you to create nicely textured 2D polys.
Simply place a few points then create / assign the shape material and you should have a good looking polygon.

The textures used are similar to what you would use if producing your levels with tilesets.

## Support
- Supported and Tesetd on Godot 3.2
- Should work with later versions of Godot 3.x

# Shapes
Each shape consists of a set of points.
There are two kinds of shapes:
- Closed Shapes
  - The last point is connected to the first, forming a closed polygon
- Open Shapes
  - The last point is NOT connected to the first

# Shape Materials
Shape materials provide all the texture and collision information needed by the SmartShape nodes.
Once a shape material is defined, it can be easily reused by any number of SmartShape2D nodes.

A shape material consists of pairs of **Edge Materials** and **Normal Ranges**
## Edge Materials
### Taper Textures
### Corner Textures
## Normal Range

# Anchoring Nodes to Sections of the Shape Node
You might have a desire to anchor nodes to various sections of the SmartShape2D node.  This is helpful in the level design by helping to automatically move other nodes in relation to the edited shape node.  Or, in the future, it might be useful adjust a shape dynamically and have the surrounding objects be affected by adjustments in the shape's contour.

This is done by use of the SmartShapeAnchor2D node.

# Keyboard Controls
- Cycle through texture indices of a vertex
  - Mouseover a vertex and MOUSEWHEEL up or down to increment / decrement the texture index

- Flip texture
  - Mouseover a vertex and press SPACE

- Move Edge
  - While in MOVE mode, mouseover an edge, hold SHIFT, then click and drag to move the two points that makeup the edge

- Add Bezier curve
  - Mouseover a vertex, hold SHIFT, then click and drag to create control points on the vertex

- Change texture width property
  - Mouseover a vertex, hold SHIFT, then MOUSEWHEEL up or down to increment / decrement the texture width

# Contibuting
If you have any suggestions, feel free to add an issue.
Please include the following three bits of information in each issue posted:
- Bug / Enhancement / Suggestion
- Godot Version
- SmartShape2D Version

We have a set of tests we run against the code (courtesy of [GUT](https://github.com/bitwes/Gut)).
If making a merge request, please ensure that the tests pass (or have been updated appropriately to pass)

# Version History
## 2.0
### Changes from 1.0
### New Features
