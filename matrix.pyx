from __future__ import print_function

from libc.string cimport memset


cdef class Matrix:
    """
    Represents a 4x4 matrix.
    """

    def __init__(Matrix self, l):

        memset(self.m, 0, sizeof(float) * 16)

        if l is None:
            return

        cdef int lenl = len(l)

        if lenl == 4:
            (self.xdx, self.xdy,
             self.ydx, self.ydy) = l
            self.ydy = 1.0
            self.wdw = 1.0

        elif lenl == 9:
            (self.xdx, self.xdy, self.xdz,
             self.ydx, self.ydy, self.ydz,
             self.zdx, self.zdy, self.zdz) = l
            self.wdw = 1.0

        elif lenl == 16:
            (self.xdx, self.xdy, self.xdz, self.xdw,
             self.ydx, self.ydy, self.ydz, self.ydw,
             self.zdx, self.zdy, self.zdz, self.zdw,
             self.wdx, self.wdy, self.wdz, self.wdw) = l

        else:
            raise Exception("Unsupported matrix length {} (must be 4, 9, or 16).".format(len(l)))


    def __mul__(Matrix self, Matrix other):

        cdef Matrix rv = Matrix(None)

        rv.xdx = other.wdx*self.xdw + other.xdx*self.xdx + other.ydx*self.xdy + other.zdx*self.xdz
        rv.xdy = other.wdy*self.xdw + other.xdy*self.xdx + other.ydy*self.xdy + other.zdy*self.xdz
        rv.xdz = other.wdz*self.xdw + other.xdz*self.xdx + other.ydz*self.xdy + other.zdz*self.xdz
        rv.xdw = other.wdw*self.xdw + other.xdw*self.xdx + other.ydw*self.xdy + other.zdw*self.xdz

        rv.ydx = other.wdx*self.ydw + other.xdx*self.ydx + other.ydx*self.ydy + other.zdx*self.ydz
        rv.ydy = other.wdy*self.ydw + other.xdy*self.ydx + other.ydy*self.ydy + other.zdy*self.ydz
        rv.ydz = other.wdz*self.ydw + other.xdz*self.ydx + other.ydz*self.ydy + other.zdz*self.ydz
        rv.ydw = other.wdw*self.ydw + other.xdw*self.ydx + other.ydw*self.ydy + other.zdw*self.ydz

        rv.zdx = other.wdx*self.zdw + other.xdx*self.zdx + other.ydx*self.zdy + other.zdx*self.zdz
        rv.zdy = other.wdy*self.zdw + other.xdy*self.zdx + other.ydy*self.zdy + other.zdy*self.zdz
        rv.zdz = other.wdz*self.zdw + other.xdz*self.zdx + other.ydz*self.zdy + other.zdz*self.zdz
        rv.zdw = other.wdw*self.zdw + other.xdw*self.zdx + other.ydw*self.zdy + other.zdw*self.zdz

        rv.wdx = other.wdx*self.wdw + other.xdx*self.wdx + other.ydx*self.wdy + other.zdx*self.wdz
        rv.wdy = other.wdy*self.wdw + other.xdy*self.wdx + other.ydy*self.wdy + other.zdy*self.wdz
        rv.wdz = other.wdz*self.wdw + other.xdz*self.wdx + other.ydz*self.wdy + other.zdz*self.wdz
        rv.wdw = other.wdw*self.wdw + other.xdw*self.wdx + other.ydw*self.wdy + other.zdw*self.wdz

        return rv

    def __getitem__(Matrix self, int index):
        if 0 <= index < 16:
            return self.m[index]

        raise IndexError("Matrix index out of range.")

    def __setitem__(Matrix self, int index, float value):
        if 0 <= index < 16:
            self.m[index] = value
            return

        raise IndexError("Matrix index out of range.")

    def __repr__(Matrix self):
        cdef int x, y

        rv = "Matrix(["

        for 0 <= y < 4:
            if y:
                rv += "\n        "
            for 0 <= x < 4:
                rv += "{:8.5f}, ".format(self.m[x + y * 4])

        return rv + "])"

    def transform(Matrix self, float x, float y, float z=0.0, float w=1.0, int components=2):
        cdef float ox, oy, oz, ow

        self.transform4(&ox, &oy, &oz, &ow, x, y, z, w)

        if components == 2:
            return (ox, oy)
        elif components == 3:
            return (ox, oy, oz)
        elif components == 4:
            return (ox, oy, oz, ow)


def identity_matrix(int dimension):
    """
    Returns a `dimension` x `dimension` identity matrix.
    """

    cdef Matrix rv = Matrix(None)

    rv.xdx = 1.0
    rv.ydy = 1.0
    rv.zdz = 1.0
    rv.wdw = 1.0

    return rv


def renpy_projection_matrix(float w, float h, float n, float p, float f):
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

    # This is the combination of two matrices multiplied together:

    # The offset matrix:
    #    1.0, 0.0, 0.0, -w / 2.0
    #    0.0, 1.0, 0.0, -h / 2.0
    #    0.0, 0.0, 1.0, -p
    #    0.0, 0.0, 0.0, 1.0

    # The projection matrix:
    #    2.0 * p / w,          0.0,          0.0,                 0.0
    #            0.0, -2.0 * p / h,          0.0,                 0.0
    #            0.0,          0.0, -(f+n)/(f-n), -2 * f * n / (f - n)
    #            0.0,          0.0,         -1.0,                 0.0,

    offset = Matrix([
        1.0, 0.0, 0.0, -w / 2.0,
        0.0, 1.0, 0.0, -h / 2.0,
        0.0, 0.0, 1.0, -p,
        0.0, 0.0, 0.0, 1.0,
        ])

    projection = Matrix([
        2.0 * p / w,          0.0,          0.0,                 0.0,
        0.0, -2.0 * p / h,          0.0,                 0.0,
        0.0,          0.0, -(f+n)/(f-n), -2 * f * n / (f - n),
        0.0,          0.0,         -1.0,                 0.0,
    ])

    rv = projection * offset

#     rv = Matrix(None)
#
#     rv.xdx = 2.0*p/w
#     rv.xdz = 0.5*w
#     rv.ydy = -2.0*p/h
#     rv.ydz = 0.5*h
#     rv.zdz = 1.0*p + 1.0*(-f - n)/(f - n)
#     rv.zdw = -2.0*f*n/(f - n)
#     rv.wdz = -1.00000000000000


    return rv
