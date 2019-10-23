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

SOLID_LAYOUT = AttributeLayout()
TEXTURE_LAYOUT = AttributeLayout()
TEXTURE_LAYOUT.add_attribute("aTexCoord", 2)

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

    def __init__(Data self, AttributeLayout layout, int points, int triangles):
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

    def crop(Data self, double x0, double y0, double x1, double y1):
        """
        Returns mesh data containing the points on the left side of the line that
        goes through (x0, y0) and (x1, y1).
        """

        cdef int i
        cdef bint all_inside
        cdef bint all_outside

        # This is set to true if the point is inside (to the left of) the
        # line, and False otherwise.
        cdef bint *inside = <bint *> malloc(self.points * sizeof(bint))

        # The vector corresponding to the line.
        cdef double lx = x1 - x0
        cdef double ly = y1 - y0

        # The vector corresponding to the point.
        cdef double px
        cdef double py

        all_outside = True
        all_inside = True

        for 0 <= i < self.points:
            px = self.point[i].x - x0
            py = self.point[i].y - y0

            inside[i] = (lx * px + ly * py) < 0.000001

            if inside[i]:
                all_outside = False
            else:
                all_inside = False

        if all_outside:
            free(inside)
            return Data(self.layout, 0, 0)

        if all_inside:
            free(inside)
            return self

        cdef Data rv = Data(self.layout, self.points + self.triangles * 2, self.triangles)








cdef class Mesh:

    cdef Data data

    def __repr__(Mesh self):

        cdef Data data = self.data
        cdef int i
        cdef int j

        rv = "<Mesh {!r}".format(data.layout.offset)

        for 0 <= i < data.points:
            rv += "\n    {}: {: >8.3f} {:> 8.3f} {:> 8.3f} | ".format(chr(i + 65), data.point[i].x, data.point[i].y, data.point[i].z)
            for 0 <= j < data.layout.stride:
                rv += "{:> 8.3f} ".format(data.attribute[i * data.layout.stride + j])

        rv += "\n    "

        for 0 <= i < data.triangles:
            rv += "{}-{}-{} ".format(
                chr(data.triangle[i * 3 + 0] + 65),
                chr(data.triangle[i * 3 + 1] + 65),
                chr(data.triangle[i * 3 + 2] + 65),
                )

        rv += ">"

        return rv


cpdef Mesh untextured_rectangle_mesh(
        double pl, double pt, double pr, double pb
        ):

    cdef Data data = Data(SOLID_LAYOUT, 4, 2)

    data.points = 4

    data.point[0].x = pl
    data.point[0].y = pb
    data.point[0].z = 0

    data.point[1].x = pr
    data.point[1].y = pb
    data.point[1].z = 0

    data.point[2].x = pr
    data.point[2].y = pt
    data.point[2].z = 0

    data.point[3].x = pl
    data.point[3].y = pt
    data.point[3].z = 0

    data.triangles = 2

    data.triangle[0] = 0
    data.triangle[1] = 1
    data.triangle[2] = 2

    data.triangle[3] = 0
    data.triangle[4] = 2
    data.triangle[5] = 3

    cdef Mesh rv = Mesh()
    rv.data = data

    return rv

cpdef Mesh texture_rectangle_mesh(
        double pl, double pt, double pr, double pb,
        double tl, double tt, double tr, double tb
        ):

    cdef Data data = Data(TEXTURE_LAYOUT, 4, 2)

    data.points = 4

    data.point[0].x = pl
    data.point[0].y = pb
    data.point[0].z = 0

    data.point[1].x = pr
    data.point[1].y = pb
    data.point[1].z = 0

    data.point[2].x = pr
    data.point[2].y = pt
    data.point[2].z = 0

    data.point[3].x = pl
    data.point[3].y = pt
    data.point[3].z = 0

    data.attribute[0] = tl
    data.attribute[1] = tb

    data.attribute[2] = tr
    data.attribute[3] = tb

    data.attribute[4] = tr
    data.attribute[5] = tt

    data.attribute[6] = tl
    data.attribute[7] = tt

    data.triangles = 2

    data.triangle[0] = 0
    data.triangle[1] = 1
    data.triangle[2] = 2

    data.triangle[3] = 0
    data.triangle[4] = 2
    data.triangle[5] = 3

    cdef Mesh rv = Mesh()
    rv.data = data

    return rv

cdef Mesh tr = texture_rectangle_mesh(0, 0, 100, 100, 0, 0, 1, 1)
print(repr(tr))
