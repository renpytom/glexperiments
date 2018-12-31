from __future__ import print_function

from libc.string cimport memset


cdef class Matrix:
    """
    Represents a `dimension` x `dimension` matrix, where 0 < `dimension` <= 5.
    """

    def __init__(Matrix self, int dimension, l):

        self.dimension = dimension

        cdef int limit = dimension * dimension

        memset(self.m, 0, sizeof(float) * limit)

        if l is None:
            return

        cdef int i = 0

        for j in l:
            self.m[i] = j
            i += 1

            if i == limit:
                break


    def __mul__(Matrix self, Matrix other):

        cdef float *a = self.m
        cdef float *b = other.m

        cdef int x, y, i

        cdef int d = self.dimension

        cdef Matrix rv = Matrix(self.dimension, None)

        for 0 <= y < self.dimension:
            for 0 <= x < self.dimension:
                rv.m[x + y * d] = 0.0
                for 0 <= i < self.dimension:
                    rv.m[x + y * d] += a[x + i * d] * b[i + y * d]

        return rv


    def __getitem__(Matrix self, int index):
        if (index < 0) or (index >= self.dimension * self.dimension):
            raise IndexError("Matrix index out of range.")

        return self.m[index]

    def __setitem__(Matrix self, int index, float value):
        if (index < 0) or (index >= self.dimension * self.dimension):
            raise IndexError("Matrix index out of range.")

        self.m[index] = value

    def __repr__(self):

        cdef int x, y
        cdef int d = self.dimension

        rv = "Matrix(["

        for 0 <= y < d:
            if y:
                rv += "\n        "
            for 0 <= x < d:
                rv += "{:8.5f}, ".format(self.m[x + y * d])

        return rv + "])"

    def apply(self, x, y, z=0.0, w=1.0):
        """
        Applies this matrix to a vertex, and returns the transformed
        point. (This is more intended for debug usage, as it can be slow
        for normal use.)
        """

        cdef float *m = self.m

        return (
            x * m[0] + y * m[1] + z * m[2] + w * m[3],
            x * m[4] + y * m[5] + z * m[6] + w * m[7],
            x * m[8] + y * m[9] + z * m[10] + w * m[11],
            x * m[12] + y * m[13] + z * m[14] + w * m[15],
            )


def identity_matrix(int dimension):
    """
    Returns a `dimension` x `dimension` identity matrix.
    """

    cdef Matrix rv = Matrix(dimension, None)

    cdef int i

    for 0 <= i < dimension:
        rv.m[i * dimension + i] = 1.0

    return rv


def renpy_projection_matrix(w, h, n, p, f):
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

    w *= 1.0
    h *= 1.0
    n *= 1.0
    p *= 1.0
    f *= 1.0

    offset = Matrix(4, [
        1.0, 0.0, 0.0, -w / 2.0,
        0.0, 1.0, 0.0, -h / 2.0,
        0.0, 0.0, 1.0, -p,
        0.0, 0.0, 0.0, 1.0,
        ])

    # Projection. Note how this inverts y as well.
    project = Matrix(4, [
        2.0 * p / w, 0, 0, 0,
        0, -2.0 * p / h, 0, 0.0,
        0, 0, -(f+n)/(f-n), -2 * f * n / (f - n),
        0, 0, -1.0, 0,
        ])

    return offset * project
