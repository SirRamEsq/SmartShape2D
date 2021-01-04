Version History
---

# 2.x
## 2.2
January 4th 2021
## Fix
- Fix for crash that would occur when points were aligned *just* right
- See issue 66
  + https://github.com/SirRamEsq/SmartShape2D/issues/66
## Features
- Each Edge Material can now have a Material (Shader)
- Each Edge Material Meta can have a z-index and z-as-relative set
- See issue 64
  + https://github.com/SirRamEsq/SmartShape2D/issues/64

## 2.1
December 14th 2020
### Significant Changes from 2.0
- Improved Width handling
- Improved Welding
- Rendering is now achieved by having multiple child-nodes each render a piece of the shape
  + Previously, all the rendering was done by the shape node
  + Improves performance
  + Fixes lighting bugs
- Point Creation mode reimplemented
  + Mode active by default
  + Can be exited by pressing ESC
- Several usability additions
  + Hotkey for grabbing closest point
  + Hotkey for creating new shape at point
  + Width Grabber for closest point
  + Preview for adding points
- Several Bug fixes and issues closed
### New Features
- Meta Shapes Introduced
- "Fit mode" added to edge material
  + Can either squash and stretch the texture or crop it
### Minor Changes
- Changes to GUI Theme
  + More in line with standard Godot
- Add windows scripts for running unit tests
- Changed default snap settings to 8x8 pixels


## 2.0
September 7th 2020
### Significant Changes from 1.0
- Edge Textures are no longer determined by a cardinal direction (UP, DOWN, LEFT, RIGHT)
  - Instead, a starting and ending normal angle is specified for each edge
- Textures are now defined per-edge instead of per-shape
### New Features
- Taper textures
  - Instead of simply ending, the user can have an edge "taper-off"
- Editing by Edges
- Material Overrides
### Internal Changes
- Completely overhauled everything
- A rudimentary constraint system is in place
  - Closed shapes will add a point when closing, then constrain the added point's position to the first point
- Points are no longer refered to by index, they are refered to by keys
  - This enables points to have relationships that aren't affected when:
    - Adding/Removing a point
    - Changing orientation of the poly
- Many Unit and Integration tests
  - Refactored original working code to better support testing
- Kept original scripts and classes from version 1.0 to ease importing

# 1.x
## Changes in 1.3
This update primarily fixes bugs and improves existing features to be more usable.
### Changes
- Merged top/left/right/bottom offset into one variable. render offset
### Fixes
- Input bugs
- Edge Flipping
- Polygon orientation bugs
- Quad Welding
- Corer quad generation and welding
- Collision variables in the RMSmartShapeMaterial working as intended

## Changes in 1.2
### Tweaks
- Refactoring
- Toolbar takes less space
- Minor bug fixes

### New Features
- Bezier Curves!
  - Hold shift on a control point to create a curve
- Corner Quads!
  - Both inner and outer corner quads are now generated
  - Textures can be speciied for each direction of both inner and outer quads
- Edge Moving!
  - Can move an edge (two points) by pressing SHIFT in move mode and dragging the edge

## Changes in 1.1
- Refactoring
- Fixed Errors Occuring when Texture Arrays are size '0' but not null
- Fixed sync between texture, flip, and width indicies
    - Would sometimes share a single array between the 3 vars
    - Are all unique now

- Snapping
- More informative toolbar

## Changes in 1.0
- Fixed many debug errors reported related to indexing beyond array sizes
- Fixed control point wrapping of RMSmartShapeAnchor2D nodes anchored to RMSmartShape2D nodes.
- Tested on newly released 3.2 Godot.

## Changes in 0.91
- Edges are calculated in relationship to object space instead of screen space
- Added option to allow user to let the object recalculate edges based on screen space.
- Fixed uv calculations for flipped textures.
- Fixed uv bug for edge sections less than half the size of texture width
- Added option to allow for a RMSmartShapeAnchor to mimic scale of monitored node
- Removed sections of code related to clockwise versus clockwise checks, very specifically regarding the direction of texture edges.
- Corrected normal texture bug for fill and edge rendering
