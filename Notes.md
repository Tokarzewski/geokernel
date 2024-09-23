Geometry kernel by default has Float64 precision. In certain calcs it should use arbitrary precision.
Visualisation could use Float32.

Libraries and algorithms needed:
GUID/UUID
IsPlanar?

Q: How to define BREP? Why not just Polygons?
I have seen implementations that have 3 arguments: 
Faces, Edges, Vertices
Faces
A: Topology!

Q: Should move create new point or update the exisitng one?
A: Don't know. Implemented both. 

E: Geometry Kernel build on lists? Lol!
A: Emm, will improve as I go.

TODO:
matrix and quaternion structs
move, scale, rotate by matrix
rotate by quaternion
push-pull polygon on brep
sweep polygon by line or polyline
cap
slice
boolean operations
Struct BoundingBox