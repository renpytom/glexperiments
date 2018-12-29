from __future__ import print_function

cdef class Matrix:
    """
    Represents a `dimension` x `dimension` matrix, where 0 < `dimension` <= 5.
    """

    def __init__(Matrix self, int dimension, l):

        self.dimension = dimension

        if l is None:
            return

        cdef int i = 0
        cdef int limit = dimension * dimension

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
                for 0 <= i  < self.dimension:
                    rv.m[x + y * d] += a[x + i * d] * b[i + y * d]

        return rv


    def apply(self, x, y, z=0.0, w=1.0):
        """
        Applies this matrix to a vector.
        """

        cdef float *m = self.m

        return (
            x * m[0] + y * m[1] + z * m[2] + w * m[3],
            x * m[4] + y * m[5] + z * m[6] + w * m[7],
            x * m[8] + y * m[9] + z * m[10] + w * m[11],
            x * m[12] + y * m[13] + z * m[14] + w * m[15],
            )

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




def renpy_matrix(w, h, n, p, f):
    """
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

    return Matrix(4, [
        2 * p / w, 0, 0, 0,
        0, -2 * p / h, 0, -1,
        0, 0, -(f+n)/(f-n), -2 * f * n / (f - n),
        0, 0, -1.0, 0,
        ])

def from_glm(mat):
    """
    Converts a glm matrix (mat2, mat3, or mat4) to a Matrix.
    """

    data = [ ]
    for i in mat:
        data.extend(i)

    return Matrix(len(mat), data)
#
# # n = 500.0
# # f = 10000.0
# #
# # m = Matrix(4, [
# #     0, 0, 0, 0,
# #     0, 0, 0, 0,
# #     0, 0, -(f+n)/(f-n), (-2) * f * n / (f - n),
# #     0, 0, -1, 0,
# #     ])

# m = renpy_matrix(800, 800, 500, 1000, 10000)
# print(m)
#
# def test(xa, ya, za, wa=1.0):
#     x, y, z, w = m.apply(xa, ya, za, 1.0)
#
#     print("XXX", w)
#     print((xa, ya, za, wa), "* m =", (x, y, z, w), " -> ", (x/w, y/w, z/w, w/w))
#
# for i in range(100, 2100, 100):
#     # test(-400, -400, -1.0 * i)
#     test(400, 400, -1.0 * i)
#
#
# import sys
# sys.exit(0)
