SmartShape2D
---
![Sample Image]( ./addons/rmsmartshape/documentation/imgs/sample.png )

# About
This plugin allows you to create nicely textured 2D polys.
Simply place a few points then create / assign the shape material and you should have a good looking polygon.

The textures used are similar to what you would use if making terrain using TileMaps/TileSets

## Support
- Supported and Tested on Godot 3.2
- Should work with later versions of Godot 3.x

# Documentation
- [How To Install]( ./addons/rmsmartshape/documentation/Install.md )
- [Quick Start]( ./addons/rmsmartshape/documentation/Quickstart.md )
- [Shapes]( ./addons/rmsmartshape/documentation/Shapes.md )
- [Toolbar]( ./addons/rmsmartshape/documentation/Toolbar.md )
- [Resources]( ./addons/rmsmartshape/documentation/Resources.md )
- [Controls]( ./addons/rmsmartshape/documentation/Controls.md )
- [Best Practicies]( ./addons/rmsmartshape/documentation/BestPraticies.md )

# Shapes


## Properties
# Shape Materials
Shape materials provide all the texture and collision information needed by the SmartShape nodes.
Once a shape material is defined, it can be easily reused by any number of SmartShape2D nodes.

A shape material consists of **Edge Meta Materials**
## Edge Meta Materials
An Edge Meta Material consists of pairs of **Edge Materials** and **Normal Ranges**
### Normal Range
The Normal Range indicates when a texture should be rendered
- If the normal range is 0 - 360 or 0 - 0, then any angle is considered in range and the edge will always render
- Angle "0" is Facing directly Right
- Angle "90" is Facing directly Up
- Angle "180" is Facing directly Left
- Angle "270" is Facing directly Down
### Edge Materials
The actual textures used to define an edge

For all cases, using texture normals is completely optional
#### Textures / Normals
- The primary textures used for the edge
- At least one texture must be defined
- ![Grass]( ./readme-imgs/grass.png )
#### Taper Textures / Normals
These textures will be used as the first or last quad in an edge.
They're named "Taper Textures" because the purpose is to show the edge "tapering off"
- Textures_Taper_Left is the first quad in an edge
  - ![Grass Taper Left]( ./readme-imgs/grass-taper-left.png )
- Textures_Taper_Right is the final quad in an edge
  - ![Grass Taper Right]( ./readme-imgs/grass-taper-right.png )
#### Corner Textures / Normals
These textures will be used when the edge forms a sharp corner (80 degrees - 100 degrees)
These are used because corners can look warped when using only regular textures
- Texture_Corner_Inner is used when the corner forms an inner corner
  - ![Grass Corner Inner]( ./readme-imgs/grass-corner-inner.png )
- Texture_Corner_Outer is used when the corner forms an outer angle
  - ![Grass Corner Outer]( ./readme-imgs/grass-corner-outer.png )

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
