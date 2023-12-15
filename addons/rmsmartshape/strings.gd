@tool
extends Resource
class_name SS2D_Strings

const EN_TOOLTIP_CREATE_VERT := "Create Vertices Tool\nLMB: Add vertex\nShift+LMB: Create Bezier curve using Control Points\nControl+LMB: Set Pivot Point\nLMB+Drag: Move Point\nLMB: Click on edge to split\nRMB: Delete Point"
const EN_TOOLTIP_EDIT_VERT := "Edit Vertices Tool\nShift+LMB: Create Bezier curve using Control Points\nAlt+LMB: Add vertex\nControl+LMB: Set Pivot Point\nLMB+Drag: Move Point\nLMB: Click on edge to split\nRMB: Delete Point"
const EN_TOOLTIP_EDIT_EDGE := "Edit Edge Tool\nSelect each edge's properties"
const EN_TOOLTIP_CUT_EDGE := "Cut Edge Tool\nRemoves the edge between vertices, opening the shape.\nCan be used to split the shape into two separate shapes."
const EN_TOOLTIP_FREEHAND := "Freehand Tool\nHold LMB: Add vertices along the drag line.\nControl+LMB: remove vertices inside the circle while dragging.\nShift+Mousewheel: Change circle size for drawing.\nShift+Control+Mousewheel: Change circle size for eraser."
const EN_TOOLTIP_PIVOT := "Set Pivot Tool\nSets the origin of the shape"
const EN_TOOLTIP_CENTER_PIVOT := "Center Pivot\nSets the origin to the centroid of the shape"
const EN_TOOLTIP_COLLISION := "Collision Tool\nAdds a static body parent and collision polygon sibling\nUse this to auto-generate collision nodes"
const EN_TOOLTIP_SNAP := "Snapping Options"
const EN_TOOLTIP_MORE_OPTIONS := "More Options"

const EN_OPTIONS_DEFER_MESH_UPDATES := "Defer Mesh Updates"
