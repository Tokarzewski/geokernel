from geokernel import Point, Shell, box_faces
from viewer import run_viewer


def main() raises:
    """Create a box shell and view it in the interactive 3D viewer."""
    print("Creating a box from (0,0,0) to (2,1,1.5)...")
    var faces = box_faces(Point(0, 0, 0), Point(2, 1, 1.5))
    var shell = Shell(faces)
    print("Box shell with", len(shell.faces), "faces, area:", shell.area())

    run_viewer(shell, "geokernel - Box Viewer")
