from geokernel import Point, Shell, Face, import_obj
from geokernel.stl import import_stl_ascii
from viewer import run_viewer


def main() raises:
    """View an OBJ or STL file in the 3D viewer.
    
    Usage: pixi run mojo view_file.mojo <path.obj|path.stl>
    """
    from std.sys import argv

    if len(argv()) < 2:
        print("Usage: pixi run mojo view_file.mojo <file.obj|file.stl>")
        return

    var path = String(argv()[1])
    print("Loading:", path)

    var faces: List[Face]

    if path.endswith(".obj"):
        var content = open(path, "r").read()
        faces = import_obj(content)
    elif path.endswith(".stl"):
        var content = open(path, "r").read()
        faces = import_stl_ascii(content)
    else:
        print("Unsupported format. Use .obj or .stl")
        return

    var shell = Shell(faces)
    print("Loaded", len(shell.faces), "faces")
    run_viewer(shell, "geokernel - " + path)
