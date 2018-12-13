from cpython.array cimport array

cdef class Polygon:
    cdef array xarray
    cdef array yarray
    cdef float *x
    cdef float *y
    cdef int points
