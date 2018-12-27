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

        cdef Matrix rv = Matrix(self.dimension)

        for 0 <= y < self.dimension:
            for 0 <= x < self.dimension:
                for 0 <= i  < self.dimension:
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

def frustum_matrix(l, r, t, b, n, f):
    return Matrix(4, [
        2 * n / (r - l), 0, (r + l) / (r - l), 0,
        0, 2 * n / (t - b), (t + b) / (t - b), 0,
        0, 0, -(f + n)/(f - n), -(2*f*n)/(f - n),
        0, 0, -1, 0 ])

from math import radians, tan

def renpy_frustum_matrix(fov, near, far, width, height):
    tanfov = tan(radians(fov / 2))

    a = -(width / 2.0 / tanfov)
    print("a", a)

    i = 1.0 - ( near / a )
    print(i)


    # Half the width at the near plane, and half the height of the near plane.
    hnw = i * width / 2.0
    hnh = i * height / 2.0

    return frustum_matrix(-hnw, hnw, -hnh, hnh, near, far)

def from_glm(mat):
    """
    Converts a glm matrix (mat2, mat3, or mat4) to a Matrix.
    """

    data = [ ]
    for i in mat:
        data.extend(i)

    return Matrix(len(mat), data)

