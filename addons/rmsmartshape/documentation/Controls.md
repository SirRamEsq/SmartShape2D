# SmartShape2D - Controls and Hotkeys

<!-- TODO: Likely, outdated. Should this even be covered in such detail? -->

## Controls - Point Create

- Add Point
  - Left Click Anywhere in the viewport

- Leave Point Create Mode
  - ESCAPE

## Controls - Point Edit

- Add Point
  - Either:
    - Hold ALT and Left Click Anywhere in the viewport
    - Click on an edge between two points

- Grab closest point
  - Hold CTRL

- Cycle through texture indices of a point
  - Mouseover a point and MOUSEWHEEL up or down to increment / decrement the texture index

- Flip texture
  - Mouseover a point and press SPACE

- Change texture width property
  - Mouseover a point, hold SHIFT, then MOUSEWHEEL up or down to increment / decrement the texture width

- Add Bezier curve
  - Mouseover a point, hold SHIFT, then click and drag to create control points on the point

- Create New Shape
  - Hold SHFT + ALT and click
    - The location of the click will be the the first point of a newly created Shape Node

### Overlap

When multiple points and edges overlap, it can be ambiguous what clicking will do.
SmartShape adheres the following rules:
- If a control point overlaps a vertex, the control point takes priority
- If a control point or vertex overlaps an edge:
  - Clicking will move the control point or vert
  - Clicking while holding ALT will create new point on the edge

