from cpython.array cimport array

cdef class Polygon:
    cdef array x
    cdef array y
    cdef int points
