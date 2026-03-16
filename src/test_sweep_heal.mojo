"""test_sweep_heal.mojo — tests for sweep_along_wire and close_shell_gaps."""
from geokernel import Point, Wire, Vector3, Shell, Face
from geokernel import merge_coincident_vertices, close_shell_gaps
from math import abs


fn assert_true(cond: Bool, name: String):
    if cond:
        print("  PASS:", name)
    else:
        print("  FAIL:", name)


fn assert_equal(val: Int, expected: Int, name: String):
    if val == expected:
        print("  PASS:", name, "=", val)
    else:
        print("  FAIL:", name, "expected", expected, "got", val)


fn assert_close(val: Float64, expected: Float64, atol: Float64, name: String):
    if abs(val - expected) <= atol:
        print("  PASS:", name, "=", val)
    else:
        print("  FAIL:", name, "expected", expected, "got", val)


fn main():
    print("=== test_sweep_heal ===")

    # ── Test 1: sweep_along_wire with L-shaped path ──────────────────────
    print("\n[1] sweep_along_wire: L-shaped path")
    # Profile: a simple 2-point wire (single segment) along x
    var profile_pts = List[Point]()
    profile_pts.append(Point(0.0, 0.0, 0.0))
    profile_pts.append(Point(0.0, 1.0, 0.0))
    var profile = Wire(profile_pts)

    # Path: go right 2 units, then up 3 units (L-shape, 2 segments)
    var path_pts = List[Point]()
    path_pts.append(Point(0.0, 0.0, 0.0))
    path_pts.append(Point(2.0, 0.0, 0.0))
    path_pts.append(Point(2.0, 0.0, 3.0))
    var path = Wire(path_pts)

    var shell = profile.sweep_along_wire(path)
    # 1 profile segment x 2 path segments = 2 faces
    assert_equal(len(shell.faces), 2, "num faces from L-path sweep")

    # ── Test 2: sweep_along_wire with single-point path → empty shell ────
    print("\n[2] sweep_along_wire: degenerate path (1 point)")
    var degen_pts = List[Point]()
    degen_pts.append(Point(0.0, 0.0, 0.0))
    var degen_path = Wire(degen_pts)
    var degen_shell = profile.sweep_along_wire(degen_path)
    assert_equal(len(degen_shell.faces), 0, "degenerate path → 0 faces")

    # ── Test 3: sweep_along_wire with multi-segment profile ──────────────
    print("\n[3] sweep_along_wire: multi-segment profile")
    var mp_pts = List[Point]()
    mp_pts.append(Point(0.0, 0.0, 0.0))
    mp_pts.append(Point(0.0, 1.0, 0.0))
    mp_pts.append(Point(0.0, 1.0, 1.0))
    var multi_profile = Wire(mp_pts)  # 2 segments

    var straight_pts = List[Point]()
    straight_pts.append(Point(0.0, 0.0, 0.0))
    straight_pts.append(Point(5.0, 0.0, 0.0))
    var straight_path = Wire(straight_pts)  # 1 path segment

    var shell3 = multi_profile.sweep_along_wire(straight_path)
    # 2 profile segments x 1 path segment = 2 faces
    assert_equal(len(shell3.faces), 2, "2-seg profile x 1-seg path = 2 faces")

    # ── Test 4: close_shell_gaps — merge near-coincident vertices ────────
    print("\n[4] close_shell_gaps: merge near-coincident vertices")
    # Create two quads sharing an edge, but with a tiny gap (1e-8)
    var f1_pts = List[Point]()
    f1_pts.append(Point(0.0, 0.0, 0.0))
    f1_pts.append(Point(1.0, 0.0, 0.0))
    f1_pts.append(Point(1.0, 1.0, 0.0))
    f1_pts.append(Point(0.0, 1.0, 0.0))

    var f2_pts = List[Point]()
    f2_pts.append(Point(1.0 + 1e-8, 0.0, 0.0))  # tiny gap
    f2_pts.append(Point(2.0, 0.0, 0.0))
    f2_pts.append(Point(2.0, 1.0, 0.0))
    f2_pts.append(Point(1.0 + 1e-8, 1.0, 0.0))  # tiny gap

    var faces = List[Face]()
    faces.append(Face(f1_pts))
    faces.append(Face(f2_pts))
    var gapped_shell = Shell(faces)

    var healed = close_shell_gaps(gapped_shell, 1e-6)
    assert_equal(len(healed.faces), 2, "healed shell still has 2 faces")

    # After healing, shared edge vertices should be identical
    # Face1 vertex at (1,0,0) and Face2 vertex at (1+1e-8,0,0) should merge
    var f1_v1 = healed.faces[0].get_vertex(1)  # was (1,0,0)
    var f2_v0 = healed.faces[1].get_vertex(0)  # was (1+1e-8,0,0)
    var dx = f1_v1.x - f2_v0.x
    var dy = f1_v1.y - f2_v0.y
    var dz = f1_v1.z - f2_v0.z
    var dist = dx * dx + dy * dy + dz * dz
    assert_true(dist < 1e-12, "merged vertices are coincident after healing")

    print("\n=== done ===")
