SmartShape2D - Controls
---

# Controls - Point Edit
- Add Point
  - Hold ALT and Left Click Anywhere in the viewport

- Cycle through texture indices of a point
  - Mouseover a point and MOUSEWHEEL up or down to increment / decrement the texture index

- Flip texture
  - Mouseover a point and press SPACE

- Change texture width property
  - Mouseover a point, hold SHIFT, then MOUSEWHEEL up or down to increment / decrement the texture width

- Add Bezier curve
  - Mouseover a point, hold SHIFT, then click and drag to create control points on the point

## Overlap
When multiple points and edges overlap, in can be ambiguous what clicking will do.
SmartShape adheres the following rules:
- If a control point overlaps a vertex, the control point takes priority
- If a control point or vertex overlaps an edge:
  - Clicking will move the control point or vert
  - Clicking while holding ALT will create new point on the edge

