from geokernel import Point, Plane, Vector3


# Example usage
fn main():
    point = Point(0, 0, 0)
    vector = Vector3(0, 0, 1)
    plane = Plane(point, vector)
    test_point = Point(1, 2, 3)

    print("Point:", repr(point))
    print("Vector3:", repr(vector))
    print("Plane:", repr(plane))
    print("Test Point:", repr(test_point))

    distance = plane.distance_to_point(test_point)
    print("Distance from test point to plane:", distance)

    projected_point = plane.project_point(test_point)
    print("Projected test point:", repr(projected_point))

    p1 = Point(0, 0, 1)
    p2 = Point(1, 0, 0)
    p3 = Point(0, 1, 1)
    plane_from_points = Plane.from_points(p1, p2, p3)
    print("Plane from points:", repr(plane_from_points))
