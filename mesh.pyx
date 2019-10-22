from libc.stdlib cimport malloc, free

cdef struct Point:
    # Represents a point in three dimensional space.

    float x
    float y
    float z

cdef class AttributeLayout:
    """
    This represents the layout of attributes inside a mesh.
    """

    # A map from a string giving the name of the attribute to the
    # offset of the attribute.
    cdef dict offset

    # The number of floats that make up the attributes for a single
    # point.
    cdef int stride


    def __cinit__(self):
        self.offset = { }
        self.stride = 0

    def add_attribute(self, name, length):
        self.offset[name] = self.stride
        self.stride += length


cdef class Data:
    """
    This represents the polygon and vertex data that is stored within
    a mesh. This allows Python's garbage collection system to take care
    of collecting data that can be shared between multiple Meshes.
    """

    # The number of points that space has been allocated for.
    cdef int allocated_points

    # The number of points that are in use.
    cdef int points

    # The geometry of the points.
    cdef Point *point

    # An AttributeLayout object controlling how attributes are stored.
    cdef AttributeLayout layout

    # The non-geometry attribute data. This is allocated_points * attribute_per_point in size.
    cdef float *attribute

    # The number of triangles that spaces has been allocated for.,
    cdef int allocated_triangles

    # The number of triangles that are in use.
    cdef int triangles

    # The triangle data, where each triangle consists of the index of three
    # points. This is 3 * allocated_triangles in size.
    cdef int *triangle

    def __cinit__(Data self, AttributeLayout layout, int points, int triangles):
        """
        `layout`
            An object that contains information about how non-geometry attributes
            are laid out.

        `points`
            The number of points for which space should be allocated.

        `triangles`
            The number of triangles for which space should be allocated.
        """

        self.allocated_points = points
        self.points = 0
        self.point = <Point *> malloc(points * sizeof(Point))

        self.layout = layout
        self.attribute = <float *> malloc(points * layout.stride * sizeof(float))

        self.allocated_triangles = triangles
        self.triangles = 0
        self.triangle = <int *> malloc(triangles * 3 * sizeof(int))

    def __dealloc__(Data self):
        free(self.point)
        free(self.attribute)
        free(self.triangle)
