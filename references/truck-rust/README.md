# truck (Rust) — porting reference for geokernel

Source files from [ricosjp/truck](https://github.com/ricosjp/truck) and
[ricosjp/ruststep](https://github.com/ricosjp/ruststep), both Apache-2.0,
mirrored from crates.io as a porting reference for the Mojo geokernel
implementation. Not built or linked from this repo — purely for reading.

Truck's full LICENSE (Apache-2.0) sits next to this README.

## What's here, and what it maps to

| Crate (Rust) | Lines | Maps to in geokernel |
|---|---|---|
| `truck-base` | small | foundational types: `Point3`, `Vector3`, `BoundingBox` — already in `point.mojo` / `vector3.mojo` / `aabb.mojo` |
| `truck-geometry` | medium | NURBS surfaces, B-spline curves, planar surfaces — see `nurbs_curve.mojo` / `nurbs_surface.mojo` / `planar_surface.mojo` |
| `truck-geotrait` | small | trait abstractions (`ParametricCurve`, `ParametricSurface`) used by the rest of truck — Mojo equivalents would be parametric-curve / -surface trait conformances |
| `truck-polymesh` | medium | triangle / polygon mesh container with positions + normals + UVs + face indices — see `obj.mojo` / `triangulation.mojo` |
| `truck-meshalgo` | medium | tessellation algorithms (`tessellation::*`, `robust_triangulation`) plus mesh post-processing (welding duplicates, removing degenerate faces) — see `triangulation.mojo` |
| `truck-stepio` | medium | high-level `Table::from_step()` API + `step_to_mesh` example — directly relevant to your `step.mojo` / `step_import.mojo` |
| `ruststep` | medium | low-level AP21 wire-format parser and EXPRESS schema runtime — what `truck-stepio` is built on |
| `ruststep-derive` | small | proc macros that turn EXPRESS schema definitions into Rust types — Mojo would not need this; instead emit Mojo structs directly from the EXPRESS schema |

## Recommended reading order when porting STEP support

1. `truck-stepio/examples/step-to-mesh.rs` — the canonical end-to-end pipeline (parse → assembly traversal → tessellate → write OBJ). Tightest entry-point for understanding the API surface.
2. `truck-stepio/src/in.rs` — the `Table::from_step` parser and `to_compressed_shell` API exposed to consumers.
3. `ruststep/src/parser.rs` — AP21 wire format (the textual `#NN=ENTITY(...)` syntax). geokernel's `step_import.mojo` is doing this part by hand; this is the reference for an EXPRESS-aware version.
4. `truck-meshalgo/src/tessellation/` — the BREP-to-mesh algorithm. Heavier reading; relevant for `triangulation.mojo`.

## License

Apache-2.0 (see `LICENSE` next to this README). Including these source
files as a *reading reference* is fine under that license. Code-structure
ports require no extra attribution in the derivative Mojo source; literal
Rust source reused verbatim must keep its original Apache-2.0 attribution
header.
