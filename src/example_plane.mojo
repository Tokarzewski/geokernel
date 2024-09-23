from geokernel import Point, Plane, Vector


# Example usage
fn main():
    var point = Point(0, 0, 0)
    var vector = Vector(0, 0, 1)
    var plane = Plane(point, vector)
    var test_point = Point(1, 2, 3)

    print("Point:", repr(point))
    print("Vector:", repr(vector))
    print("Plane:", repr(plane))
    print("Test Point:", repr(test_point))

    var distance = plane.distance_to_point(test_point)
    print("Distance from test point to plane:", distance)

    var projected_point = plane.project_point(test_point)
    print("Projected test point:", repr(projected_point))

    var p1 = Point(0, 0, 1)
    var p2 = Point(1, 0, 0)
    var p3 = Point(0, 1, 1)
    var plane_from_points = Plane.from_points(p1, p2, p3)
    print("Plane from points:", repr(plane_from_points))
