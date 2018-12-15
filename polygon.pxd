from cpython.array cimport array

cdef class Polygon:
    cdef public array xarray
    cdef public array yarray
    cdef public array zarray
    cdef public dict data
    cdef public int points
