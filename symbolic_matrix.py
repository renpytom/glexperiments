from __future__ import print_function
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


matrix_names = [
    "xdx",
    "xdy",
    "xdz",
    "xdw",

    "ydx",
    "ydy",
    "ydz",
    "ydw",

    "zdx",
    "zdy",
    "zdz",
    "zdw",

    "wdx",
    "wdy",
    "wdz",
    "wdw",
    ]


def prefixed_matrix(prefix):
    """
    Returns a matrix where each entry is of the for prefix___name.
    """

    return Matrix(4, 4, [ symbols(prefix + "___" + i) for i in matrix_names ])


def print_matrix(m):

    print()

    for name, value in zip(matrix_names, m):
        if value == 0.0:
            continue

        print("rv.{} =".format(name), str(value).replace("___", "."))


def matrix_mult():
    print()

    multiplied = prefixed_matrix("self") * prefixed_matrix("other")

    for name, value in zip(matrix_names, multiplied):
        print("rv.{} =".format(name), str(value).replace("___", "."))


def renpy_projection_matrix():

    w, h, n, p, f = symbols('w h n p f')

    offset = Matrix(4, 4, [
        1.0, 0.0, 0.0, -w / 2.0,
        0.0, 1.0, 0.0, -h / 2.0,
        0.0, 0.0, 1.0, -p,
        0.0, 0.0, 0.0, 1.0,
    ])

    projection = Matrix(4, 4, [
        2.0 * p / w, 0.0, 0.0, 0.0,
        0.0, -2.0 * p / h, 0.0, 0.0,
        0.0, 0.0, -(f+n)/(f-n), -2 * f * n / (f - n),
        0.0, 0.0, -1.0, 0.0,
    ])

    print_matrix(offset)
    print_matrix(projection)
    print_matrix(offset * projection)


renpy_projection_matrix()
