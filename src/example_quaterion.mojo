from geokernel import FType, Vector3, Quaternion
from math import pi, cos, sin
from geokernel import Units


fn print_separator():
    print("\n" + "-----------------------------" + "\n")


fn main() raises:
    print("Quaternion Functionality Showcase")
    print_separator()

    # Creation
    print("1. Creating Quaternions")

    # Identity quaternion
    var q1 = Quaternion(1, 0, 0, 0)

    # 45-degree rotation around Y-axis
    var q2 = Quaternion.from_axis_angle(Vector3(0, 1, 0), pi / 4)

    # From Euler angles
    var q3 = Quaternion.from_euler_angles(pi / 6, pi / 4, pi / 3)

    print("q1 (Identity):", repr(q1))
    print("q2 (45° around Y):", repr(q2))
    print("q3 (from Euler angles 30°, 45°, 60°):", repr(q3))

    print_separator()

    # Basic operations
    print("2. Basic Operations")
    var q_sum = q1 + q2
    var q_diff = q2 - q1
    var q_mult = q2 * q3
    var q_scaled = q2 * 2.0

    print("q1 + q2:", repr(q_sum))
    print("q2 - q1:", repr(q_diff))
    print("q2 * q3:", repr(q_mult))
    print("q2 * 2.0:", repr(q_scaled))

    print_separator()

    # Normalization and Inverse
    print("3. Normalization and Inverse")
    var q_normalized = q3.normalize()
    var q_inverse = q3.inverse()

    print("q3 normalized:", repr(q_normalized))
    print("q3 inverse:", repr(q_inverse))
    print("q3 * q3_inverse:", repr(q3 * q_inverse))  # Close to identity

    print_separator()

    # Rotations
    print("4. Rotations")
    var v = Vector3.unitX()  # Vector pointing along X-axis
    var rotated_v = q2.rotate_vector(v)

    print("Original vector:", repr(v))
    print("Vector rotated by q2:", repr(rotated_v))

    print_separator()

    # Conversions
    print("5. Conversions")
    axis, angle = q2.to_axis_angle()
    roll, pitch, yaw = q2.to_euler_angles()

    print("q2 as axis-angle: axis =", repr(axis), "angle =", angle)
    print(String("q2 as Euler angles (radians):"))
    print(String("roll, pitch, yaw = {}, {}, {}").format(roll, pitch, yaw))
    print(String("q2 as Euler angles (degrees):"))

    print_separator()

    # Interpolation
    print("6. Interpolation (NLERP)")
    var q_start = Quaternion.from_axis_angle(Vector3(1, 0, 0), 0)
    var q_end = Quaternion.from_axis_angle(Vector3(1, 0, 0), pi / 2)

    print("Start quaternion:", repr(q_start))
    print("End quaternion:", repr(q_end))

    for t in range(0, 11, 2):
        var t_float = FType(t) / 10
        var q_interp = Quaternion.nlerp(q_start, q_end, t_float)
        print("Interpolated at t=0." + str(t) + ", " + repr(q_interp))
