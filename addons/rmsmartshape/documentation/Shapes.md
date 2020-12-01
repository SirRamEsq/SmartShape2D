SmartShape2D - Shapes
---

Each shape consists of a set of points. You can directly edit either the points or the edges between the points in the viewport.

Shapes are configured to use a [Shape Material]( ./Resources.md#ShapeMaterial ) which determines how the shape is rendered.

There are three kinds of shapes:
- ![OpenShapeImg]( ./../assets/open_shape.png  ) **Open Shape**
  - This shape's final point **doesn't** connect to its first point.
  - This shape **doesn't** make use of the "Fill Textures" parameter in the ShapeMaterial.
- ![ClosedShapeImg]( ./../assets/closed_shape.png  ) **Closed Shape**
  - This shape's final point **does** connect to its first point.
  - This shape **does** make use of the "Fill Textures" parameter in the ShapeMaterial.
- ![MetaShapeImg]( ./../assets/meta_shape.png  ) **Meta Shape**
  - This shape sets the points of all children shapes.
  - Changing the points of any children shapes will also change the meta shape along with all the meta shapes children.
  - Can be edited directly if contains only Open shapes.
  - If children include Closed shapes, should only edit the closed shapes.

# Properties
## Editor Debug
- Will show the bounding box for each quad in the mesh of edges.
- Can be helpful to illustrate why a shape doesn't look the way you expect.
## Flip Edges
- Will flip the edges of the shape (invert y).
## Render Edges
- Whether or not the edges of the shape should be rendered.
## Collision Size
- Size of the collision shape.
## Collision Offset
- Offset of where the collision shape starts and ends.
- A **positive** value offsets the collision shape **outwards**.
- A **negative** value offsets the collision shape **inwards**.
## Tessellation Stages
- Number of stages in the curve tessellation process (Uses Curve2D Internally).
- First Param in Curve2D.tessellate.
- See [Curve2D Documentation](https://docs.godotengine.org/en/3.2/classes/class_curve2d.html#class-curve2d-method-tessellate).
## Tessellation Tolerence
- Tolerence Degrees in the curve tessellation process (Uses Curve2D Internally).
- Second Param in Curve2D.tessellate.
- See [Curve2D Documentation](https://docs.godotengine.org/en/3.2/classes/class_curve2d.html#class-curve2d-method-tessellate).
## Curve Bake Interval
- Bake interval value for Curve2D.
- See [Curve2D Documentation](https://docs.godotengine.org/en/3.2/classes/class_curve2d.html#class-curve2d-property-bake-interval).
## Collision Polygon Node Path
- The path to the CollisionShape that the SmartShape will use for collision.
- Is Autoset when pressing the generate collision button.
## Shape Material
- The material that this shape will use to render itself.
## Points
- **There is no need to edit this property by hand, but you can if you'd like.**
- Contains all of the points and meta-data for the points contained in this shape.
- This data structure is updated as you manipulate the shape.
## Material Overrides
- **There is no need to edit this property by hand, but you can if you'd like.**
- When an edge is given a "Material Override" the data for that edge is stored here.
- This data structure is updated as you manipulate the shape.
![EdgeData Popup]( ./imgs/EdgeEdit-MaterialOverride.png )

