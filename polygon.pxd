from cpython.array cimport array

cdef class Polygon:

    # The number of points in the polygon.
    cdef int points

    # The stride of the polygon - the number of floats comprising a data
    # point.
    cdef int stride

    # The data in a polygon.
    cdef float *data

    cdef Polygon copy(self, int stride)


cdef class Mesh:

    # The total number of points.
    cdef public int points

    # The stride - the amount of data per point, in floats.
    cdef public int stride

    # A map from an attribute to the offset of that attribute.
    cdef public dict attributes

    # A list of polygons that comprise the mesh.
    cdef public list polygons

    cdef float *get_data(self, name)
