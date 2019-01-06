from __future__ import print_function
from sympy import symbols, Matrix

import argparse


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

        print("    rv.{} =".format(name), str(value).replace("___", "."))


def matrix_mult():
    print()

    multiplied = prefixed_matrix("self") * prefixed_matrix("other")

    print_matrix(multiplied)


class Generator(object):

    def __init__(self, name, docs):
        self.name = name
        self.docs = docs

    def parameters(self, params):
        print()
        print()

        print("def {}({}):".format(
            self.name,
            ", ".join("float " + i for i in params.split())))

        if self.docs:
            print('    """' + self.docs + '"""')

        print()

        if params.split():
            return symbols(params)

    def matrix(self, m):

        print("    cdef Matrix rv = Matrix(None)")
        print()

        for name, value in zip(matrix_names, m):
            if value == 0.0:
                continue

            print("    rv.{} =".format(name), str(value).replace("___", "."))

        print()
        print("    return rv")


def generate(func):
    g = Generator(func.__name__, func.__doc__)
    func(g)
    return func


@generate
def identity(g):
    """
    Returns an identity matrix.
    """

    g.parameters("")

    g.matrix(Matrix(4, 4, [
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
        ]))


@generate
def offset(g):
    """
    Returns a matrix that offsets the vertex by a fixed amount.
    """

    x, y, z = g.parameters("x y z")

    g.matrix(Matrix(4, 4, [
        1.0, 0.0, 0.0, x,
        0.0, 1.0, 0.0, y,
        0.0, 0.0, 1.0, z,
        0.0, 0.0, 0.0, 1.0,
        ]))


@generate
def perspective(g):
    """
    Returns the Ren'Py projection matrix. This is a view into a 3d space
    where (0, 0) is the top left corner (`w`/2, `h`/2) is the center, and
    (`w`,`h`) is the bottom right, when the z coordinate is 0.

    `w`, `h`
        The width and height of the input plane, in pixels.

    `n`
        The distance of the near plane from the camera.

    `p`
        The distance of the 1:1 plane from the camera. This is where 1 pixel
        is one coordinate unit.

    `f`
        The distance of the far plane from the camera.
    """

    w, h, n, p, f = g.parameters('w h n p f')

    offset = Matrix(4, 4, [
        1.0, 0.0, 0.0, -w / 2.0,
        0.0, 1.0, 0.0, -h / 2.0,
        0.0, 0.0, 1.0, -p,
        0.0, 0.0, 0.0, 1.0,
    ])

    projection = Matrix(4, 4, [
        2.0 * p / w, 0.0, 0.0, 0.0,
        0.0, 2.0 * p / h, 0.0, 0.0,
        0.0, 0.0, -(f+n)/(f-n), -2 * f * n / (f - n),
        0.0, 0.0, -1.0, 0.0,
    ])

    reverse_offset = Matrix(4, 4, [
        1.0, 0.0, 0.0, w / 2.0,
        0.0, 1.0, 0.0, h / 2.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
    ])

    g.matrix(reverse_offset * projection * offset)


@generate
def screen_projection(g):
    """
    Generates the matrix that projects the Ren'Py screen to the OpenGL screen.
    """

    w, h = g.parameters("w h")

    m = Matrix(4, 4, [
        2.0 / w, 0.0, 0.0, -1.0,
        0.0, -2.0 / h, 0.0, 1.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
        ])

    g.matrix(m)
