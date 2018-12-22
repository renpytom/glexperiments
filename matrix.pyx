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
