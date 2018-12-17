from cpython.array cimport array

cdef class Polygon:
    cdef int points
    cdef int stride
    cdef float *data

    cdef Polygon copy(self, int stride)
