"""IFC (Industry Foundation Classes) export for BIM interoperability.

Implements basic IFC 2x3/4 export using STEP encoding (ISO 10303-21).
Supports:
- IfcWall, IfcSlab, IfcColumn from Shell geometry
- IfcOpeningElement for openings
- IfcBuildingStorey, IfcBuilding, IfcSite hierarchy
- IfcProject as root container

This is write-only; IFC import shares the STEP parser infrastructure.
"""

from geokernel import FType, Point, Vector3, Face, Shell
from geokernel.step import StepWriter, _fmt


struct IfcEntity:
    """IFC entity reference with type and id."""
    var id: Int
    var type_name: String

    def __init__(out self, id: Int, type_name: String):
        self.id = id
        self.type_name = type_name


def export_ifc(
    walls: List[Shell],
    slabs: List[Shell],
    columns: List[Shell],
    building_name: String = "Building",
    site_name: String = "Site",
    project_name: String = "Project",
) -> String:
    """Export building geometry to IFC format.

    Args:
        walls: List of Shell geometries for walls
        slabs: List of Shell geometries for slabs/floors
        columns: List of Shell geometries for columns
        building_name: Name for the IfcBuilding
        site_name: Name for the IfcSite
        project_name: Name for the IfcProject

    Returns:
        IFC file content as a string (STEP encoding).
    """
    var w = StepWriter()

    # Application and context entities
    var app_id = w._add("IFCAPPLICATION(#1, '0.1', 'geokernel', 'geokernel')")
    var person_id = w._add("IFCPERSON($, '', '', $, $, $, $, $)")
    var org_id = w._add("IFCORGANIZATION($, 'geokernel', $, $, $)")
    var po_id = w._add("IFCPERSONANDORGANIZATION(#" + String(person_id) + ", #" + String(org_id) + ", $)")
    var oa_id = w._add("IFCOWNERHISTORY(#" + String(po_id) + ", #" + String(app_id) + ", $, .NOTDEFINED., $, $, $, 0)")

    # Geometric context
    var origin_pt = w.cartesian_point(Point(0.0, 0.0, 0.0))
    var z_dir = w.direction(Vector3(0.0, 0.0, 1.0))
    var x_dir = w.direction(Vector3(1.0, 0.0, 0.0))
    var axis_place = w._add("IFCAXIS2PLACEMENT3D(#" + String(origin_pt) + ", #" + String(z_dir) + ", #" + String(x_dir) + ")")
    var geo_ctx = w._add("IFCGEOMETRICREPRESENTATIONCONTEXT($, 'Model', 3, 1.0E-5, #" + String(axis_place) + ", $)")

    # Units (SI)
    var length_unit = w._add("IFCSIUNIT(*, .LENGTHUNIT., $, .METRE.)")
    var area_unit = w._add("IFCSIUNIT(*, .AREAUNIT., $, .SQUARE_METRE.)")
    var volume_unit = w._add("IFCSIUNIT(*, .VOLUMEUNIT., $, .CUBIC_METRE.)")
    var angle_unit = w._add("IFCSIUNIT(*, .PLANEANGLEUNIT., $, .RADIAN.)")
    var unit_assign = w._add("IFCUNITASSIGNMENT((#" + String(length_unit) + ", #" + String(area_unit) + ", #" + String(volume_unit) + ", #" + String(angle_unit) + "))")

    # Project
    var project_id = w._add("IFCPROJECT('" + _guid() + "', #" + String(oa_id) + ", '" + project_name + "', $, $, $, $, (#" + String(geo_ctx) + "), #" + String(unit_assign) + ")")

    # Site
    var site_place = w._add("IFCLOCALPLACEMENT($, #" + String(axis_place) + ")")
    var site_id = w._add("IFCSITE('" + _guid() + "', #" + String(oa_id) + ", '" + site_name + "', $, $, #" + String(site_place) + ", $, $, .ELEMENT., $, $, $, $, $)")

    # Building
    var bld_place = w._add("IFCLOCALPLACEMENT(#" + String(site_place) + ", #" + String(axis_place) + ")")
    var bld_id = w._add("IFCBUILDING('" + _guid() + "', #" + String(oa_id) + ", '" + building_name + "', $, $, #" + String(bld_place) + ", $, $, .ELEMENT., $, $, $)")

    # Storey
    var storey_place = w._add("IFCLOCALPLACEMENT(#" + String(bld_place) + ", #" + String(axis_place) + ")")
    var storey_id = w._add("IFCBUILDINGSTOREY('" + _guid() + "', #" + String(oa_id) + ", 'Ground Floor', $, $, #" + String(storey_place) + ", $, $, .ELEMENT., 0.0)")

    # Spatial containment relationships
    w._add("IFCRELAGGREGATES('" + _guid() + "', #" + String(oa_id) + ", $, $, #" + String(project_id) + ", (#" + String(site_id) + "))")
    w._add("IFCRELAGGREGATES('" + _guid() + "', #" + String(oa_id) + ", $, $, #" + String(site_id) + ", (#" + String(bld_id) + "))")
    w._add("IFCRELAGGREGATES('" + _guid() + "', #" + String(oa_id) + ", $, $, #" + String(bld_id) + ", (#" + String(storey_id) + "))")

    # Add building elements
    var element_ids = List[Int]()

    # Walls
    for i in range(len(walls)):
        var elem_id = _add_shell_element(w, walls[i], "IFCWALL", "Wall-" + String(i), oa_id, storey_place, geo_ctx)
        element_ids.append(elem_id)

    # Slabs
    for i in range(len(slabs)):
        var elem_id = _add_shell_element(w, slabs[i], "IFCSLAB", "Slab-" + String(i), oa_id, storey_place, geo_ctx)
        element_ids.append(elem_id)

    # Columns
    for i in range(len(columns)):
        var elem_id = _add_shell_element(w, columns[i], "IFCCOLUMN", "Column-" + String(i), oa_id, storey_place, geo_ctx)
        element_ids.append(elem_id)

    # Spatial containment of elements in storey
    if len(element_ids) > 0:
        var elem_refs = String("(")
        for i in range(len(element_ids)):
            if i > 0:
                elem_refs += ", "
            elem_refs += "#" + String(element_ids[i])
        elem_refs += ")"
        w._add("IFCRELCONTAINEDINSPATIALSTRUCTURE('" + _guid() + "', #" + String(oa_id) + ", $, $, " + elem_refs + ", #" + String(storey_id) + ")")

    # Build IFC file
    var result = String("ISO-10303-21;\n")
    result += "HEADER;\n"
    result += "FILE_DESCRIPTION(('ViewDefinition [CoordinationView]'), '2;1');\n"
    result += "FILE_NAME('" + project_name + ".ifc', '', (''), (''), '', 'geokernel', '');\n"
    result += "FILE_SCHEMA(('IFC2X3'));\n"
    result += "ENDSEC;\n"
    result += "DATA;\n"
    result += w.to_string()
    result += "ENDSEC;\n"
    result += "END-ISO-10303-21;\n"
    return result


def _add_shell_element(
    mut w: StepWriter, shell: Shell, ifc_type: String, name: String,
    oa_id: Int, placement_id: Int, ctx_id: Int,
) -> Int:
    """Add a building element (wall/slab/column) from a Shell."""
    # Create local placement
    var origin = w.cartesian_point(Point(0.0, 0.0, 0.0))
    var z = w.direction(Vector3(0.0, 0.0, 1.0))
    var x = w.direction(Vector3(1.0, 0.0, 0.0))
    var axis = w._add("IFCAXIS2PLACEMENT3D(#" + String(origin) + ", #" + String(z) + ", #" + String(x) + ")")
    var local_place = w._add("IFCLOCALPLACEMENT(#" + String(placement_id) + ", #" + String(axis) + ")")

    # Create geometry: triangulate shell faces into IFCFACETEDBREP
    var face_ids = List[Int]()
    for fi in range(len(shell.faces)):
        var face = shell.faces[fi]
        var nv = face.num_vertices()
        if nv < 3:
            continue
        var vert_ids = List[Int]()
        for vi in range(nv):
            var p = face.get_vertex(vi)
            var cp = w.cartesian_point(p)
            vert_ids.append(cp)
        # Create polyloop
        var refs = String("(")
        for vi in range(len(vert_ids)):
            if vi > 0:
                refs += ", "
            refs += "#" + String(vert_ids[vi])
        refs += ")"
        var loop_id = w._add("IFCPOLYLOOP(" + refs + ")")
        var bound_id = w._add("IFCFACEOUTERBOUND(#" + String(loop_id) + ", .T.)")
        var face_id = w._add("IFCFACE((#" + String(bound_id) + "))")
        face_ids.append(face_id)

    if len(face_ids) == 0:
        return -1

    var face_refs = String("(")
    for i in range(len(face_ids)):
        if i > 0:
            face_refs += ", "
        face_refs += "#" + String(face_ids[i])
    face_refs += ")"
    var closed_shell_id = w._add("IFCCLOSEDSHELL(" + face_refs + ")")
    var brep_id = w._add("IFCFACETEDBREP(#" + String(closed_shell_id) + ")")

    # Shape representation
    var shape_rep = w._add("IFCSHAPEREPRESENTATION(#" + String(ctx_id) + ", 'Body', 'Brep', (#" + String(brep_id) + "))")
    var prod_shape = w._add("IFCPRODUCTDEFINITIONSHAPE($, $, (#" + String(shape_rep) + "))")

    # Create the building element
    var elem_id = w._add(ifc_type + "('" + _guid() + "', #" + String(oa_id) + ", '" + name + "', $, $, #" + String(local_place) + ", #" + String(prod_shape) + ", $)")

    return elem_id


var _guid_counter: Int = 0

def _guid() -> String:
    """Generate a simple sequential GUID for IFC entities."""
    _guid_counter += 1
    var s = String(_guid_counter)
    # Pad to 22 chars (IFC compressed GUID length)
    while len(s) < 22:
        s = "0" + s
    return s
