from sympy import symbols, Matrix


def generate_rotations():

    sinx, cosx = symbols('sinx cosx')
    siny, cosy = symbols('siny cosy')
    sinz, cosz = symbols('sinz cosz')

    rx = Matrix(4, 4, [
        1, 0, 0, 0,
        0, cosx, -sinx, 0,
        0, sinx, cosx, 0,
        0, 0, 0, 1 ])

    ry = Matrix(4, 4, [
        cosy, 0, siny, 0,
        0, 1, 0, 0,
        -siny, 0, cosy, 0,
        0, 0, 0, 1])

    rz = Matrix(4, 4, [
        cosz, -sinz, 0, 0,
        sinz, cosz, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1, ])

    rotate = rx * ry * rz

    for i, expr in enumerate(rotate):
        if expr == 0:
            continue

        print("rv.m[{}] = {}".format(i, expr))


generate_rotations()
