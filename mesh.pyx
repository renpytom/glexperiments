from __future__ import print_function

from libc.stdlib cimport malloc, free
from libc.math cimport hypot

# Represents a point in three dimensional space.
cdef struct Point:
    float x
    float y
    float z


# Information used when cropping.
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
        double pl, double pb, double pr, double pt
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
        double pl, double pb, double pr, double pt,
        double tl, double tb, double tr, double tt
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

################################################################################

DEF SPLIT_CACHE_LEN = 4

# Stores the information learned about a point when cropping it.
cdef struct CropPoint:
    bint inside
    int replacement

# This is used to indicate that splitting the line between p0 and
# p1 has created point np.
cdef struct CropSplit:
    int p0idx
    int p1idx
    int npidx

# This stores information about the crop operation.
cdef struct CropInfo:

    double x0
    double y0

    double x1
    double y1

    # The number of splits.
    int splits

    # The last four line segment splits.
    CropSplit split[SPLIT_CACHE_LEN]

    # The information learned about the points when cropping them. This
    # is actually created to be
    CropPoint point[0]


cdef void copy_point(Data old, int op, Data new, int np):
    """
    Copies the point at index `op` in ci.old to index `np` in ci.new.
    """

    cdef int i
    cdef int stride = old.layout.stride

    new.point[np] = old.point[op]

    for 0 <= i < stride:
        new.attribute[np * stride + i] = old.attribute[op * stride + i]

cdef void intersectLines(
    float x1, float y1,
    float x2, float y2,
    float x3, float y3,
    float x4, float y4,
    float *px, float *py,
    ):
    """
    Given a line that goes through (x1, y1) to (x2, y2), and a second line
    that goes through (x3, y3) and (x4, y4), find the point where the two
    lines intersect.
    """

    cdef float denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)

    px[0] = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / denom
    py[0] = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / denom

cdef int split_line(Data old, Data new, CropInfo *ci, int p0idx, int p1idx):

    cdef int i

    for 0 <= i < SPLIT_CACHE_LEN:
        if (ci.split[i].p0idx == p0idx) and (ci.split[i].p1idx == p1idx):
            return ci.split[i].npidx
        elif (ci.split[i].p0idx == p1idx) and (ci.split[i].p1idx == p0idx):
            return ci.split[i].npidx

    cdef Point p0 # old point 0
    cdef Point p1 # old point 1
    cdef Point np # new point.

    p0 = old.point[p0idx]
    p1 = old.point[p1idx]

    # Find the location of the new point.
    intersectLines(p0.x, p0.y, p1.x, p1.y, ci.x0, ci.y0, ci.x1, ci.y1, &np.x, &np.y)

    # The distance between p0 and p1.
    cdef float p1dist2d = hypot(p1.x - p0.x, p1.y - p0.y)
    cdef float npdist2d = hypot(np.x - p0.x, np.y - p0.y)

    # The z coordinate is interpolated.
    np.z = p0.z + (npdist2d / p1dist2d) * (p1.z - p0.z)

    # Use the distance with z to interpolate attributes.
    cdef float p1dist3d = hypot(p1dist2d, p1.z - p0.z)
    cdef float npdist3d = hypot(npdist2d, np.z - p0.z)
    cdef float d = npdist3d / p1dist3d

    # Allocate a new point.
    cdef int npidx = new.points
    new.point[npidx] = np
    new.points += 1

    # Interpolate the attributes.
    cdef int stride = old.layout.stride
    cdef float a
    cdef float b

    for 0 <= i <= stride:
        a = old.attribute[p0idx * stride + i]
        b = old.attribute[p1idx * stride + i]
        new.attribute[npidx * stride + i] = a + d * (b - a)

    ci.split[ci.splits % SPLIT_CACHE_LEN].p0idx = p0idx
    ci.split[ci.splits % SPLIT_CACHE_LEN].p1idx = p1idx
    ci.split[ci.splits % SPLIT_CACHE_LEN].npidx = npidx

    return npidx


cdef void triangle1(Data old, Data new, CropInfo *ci, int p0, int p1, int p2):
    """
    Processes a triangle where only one point is inside the line.
    """

    cdef int a = split_line(old, new, ci, p0, p1)
    cdef int b = split_line(old, new, ci, p0, p2)

    cdef int t = new.triangles

    new.triangle[t * 3 + 0] = ci.point[p0].replacement
    new.triangle[t * 3 + 1] = a
    new.triangle[t * 3 + 2] = b

    new.triangles += 1


cdef void triangle2(Data old, Data new, CropInfo *ci, int p0, int p1, int p2):
    """
    Processes a triangle where two points are inside the line.
    """

    cdef int a = split_line(old, new, ci, p1, p2)
    cdef int b = split_line(old, new, ci, p0, p2)

    cdef int t = new.triangles

    new.triangle[t * 3 + 0] = ci.point[p0].replacement
    new.triangle[t * 3 + 1] = ci.point[p1].replacement
    new.triangle[t * 3 + 2] = a

    t += 1

    new.triangle[t * 3 + 0] = ci.point[p0].replacement
    new.triangle[t * 3 + 1] = a
    new.triangle[t * 3 + 2] = b

    new.triangles += 2


cdef void triangle3(Data old, Data new, CropInfo *ci, int p0, int p1, int p2):
    """
    Processes a triangle that's entirely inside the line.
    """

    cdef int t = new.triangles

    new.triangle[t * 3 + 0] = ci.point[p0].replacement
    new.triangle[t * 3 + 1] = ci.point[p1].replacement
    new.triangle[t * 3 + 2] = ci.point[p2].replacement

    new.triangles += 1


def crop_data(Data old, double x0, double y0, double x1, double y1):

    cdef int i
    cdef int op, np

    cdef CropInfo *ci = <CropInfo *> malloc(sizeof(CropInfo) + old.points * sizeof(CropPoint))

    ci.x0 = x0
    ci.y0 = y0
    ci.x1 = x1
    ci.y1 = y1

    # Step 1: Determine what points are inside and outside the line.

    cdef bint all_inside
    cdef bint all_outside

    # The vector corresponding to the line.
    cdef double lx = x1 - x0
    cdef double ly = y1 - y0

    # The vector corresponding to the point.
    cdef double px
    cdef double py

    all_outside = True
    all_inside = True

    for 0 <= i < old.points:
        px = old.point[i].x - x0
        py = old.point[i].y - y0

        if (lx * py + ly * px) < 0.000001:
            all_outside = False
            ci.point[i].inside = True
        else:
            all_inside = False
            ci.point[i].inside = False

    # Step 1a: Short circuit if all points are inside or out, otherwise
    # allocate a new object.

    if all_outside:
        free(ci)
        return Data(old.layout, 0, 0)

    if all_inside:
        free(ci)
        return old

    cdef Data new = Data(old.layout, old.points + old.triangles * 2, old.triangles * 2)

    # Step 2: Copy points that are inside.

    for 0 <= i < old.points:
        if ci.point[i].inside:
            copy_point(old, i, new, new.points)
            ci.point[i].replacement = new.points
            new.points += 1
        else:
            ci.point[i].replacement = -1


    ci.splits = 0

    for 0 <= i < SPLIT_CACHE_LEN:
        ci.split[i].p0idx = -1
        ci.split[i].p1idx = -1

    # Step 3: Triangles.

    # Indexes of the three points that make up a triangle.
    cdef int p0
    cdef int p1
    cdef int p2

    # Are the points inside the triangle?
    cdef bint p0in
    cdef bint p1in
    cdef bint p2in

    for 0 <= i < old.triangles:
        p0 = old.triangle[3 * i + 0]
        p1 = old.triangle[3 * i + 1]
        p2 = old.triangle[3 * i + 2]

        p0in = ci.point[p0].inside
        p1in = ci.point[p1].inside
        p2in = ci.point[p2].inside

        if p0in and p1in and p2in:
            triangle3(old, new, ci, p0, p1, p2)

        elif (not p0in) and (not p1in) and (not p2in):
            continue

        elif p0in and (not p1in) and (not p2in):
            triangle1(old, new, ci, p0, p1, p2)
        elif (not p0in) and p1in and (not p2in):
            triangle1(old, new, ci, p1, p2, p0)
        elif (not p0in) and (not p1in) and p2in:
            triangle1(old, new, ci, p2, p0, p1)

        elif p0in and p1in and (not p2in):
            triangle2(old, new, ci, p0, p1, p2 )
        elif (not p0in) and p1in and p2in:
            triangle2(old, new, ci, p1, p2, p0)
        elif p0in and (not p1in) and p2in:
            triangle2(old, new, ci, p2, p0, p1)

    free(ci)
    return new



cdef Mesh tr = texture_rectangle_mesh(0, 0, 100, 100, 0, 0, 1, 1)
print("Original", repr(tr))

cdef Mesh cropped = Mesh()
cropped.data = crop_data(tr.data, 50, 0, 50, 100)

print("Cropped", repr(cropped))
