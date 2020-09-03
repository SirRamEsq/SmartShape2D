SmartShape2D - Resources
---

# Shape Materials
Shape materials provide all the texture and collision information needed by the SmartShape nodes.
Once a shape material is defined, it can be easily reused by any number of SmartShape2D nodes.

A shape material consists of **Edge Meta Materials**

# Edge Meta Materials
An Edge Meta Material consists of pairs of **Edge Materials** and **Normal Ranges**

# Normal Range
The Normal Range indicates when a texture should be rendered
- If the normal range is 0 - 360 or 0 - 0, then any angle is considered in range and the edge will always render
- Angle "0" is Facing directly Right
- Angle "90" is Facing directly Up
- Angle "180" is Facing directly Left
- Angle "270" is Facing directly Down

# Edge Materials
The actual textures used to define an edge

For all cases, using texture normals is completely optional
## Textures / Normals
- The primary textures used for the edge
- At least one texture must be defined
- ![Grass]( ./imgs/grass.png )
## Taper Textures / Normals
These textures will be used as the first or last quad in an edge.
They're named "Taper Textures" because the purpose is to show the edge "tapering off"
- Textures_Taper_Left is the first quad in an edge
  - ![Grass Taper Left]( ./imgs/grass-taper-left.png )
- Textures_Taper_Right is the final quad in an edge
  - ![Grass Taper Right]( ./imgs/grass-taper-right.png )
## Corner Textures / Normals
These textures will be used when the edge forms a sharp corner (80 degrees - 100 degrees)
These are used because corners can look warped when using only regular textures
- Texture_Corner_Inner is used when the corner forms an inner corner
  - ![Grass Corner Inner]( ./imgs/grass-corner-inner.png )
- Texture_Corner_Outer is used when the corner forms an outer angle
  - ![Grass Corner Outer]( ./imgs/grass-corner-outer.png )

