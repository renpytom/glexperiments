from cpython.array cimport array
from cpython.array cimport copy as array_copy

# The maximum number of points a polygon can have.

DEF MAX_POINTS = 32

cdef array template = array('f', [ 0 ] * MAX_POINTS)

cdef class Polygon:
    def __init__(self):
        self.x = array_copy(template)
        self.y = array_copy(template)
        self.points = 0

def polygon(l):

    cdef Polygon rv = Polygon()

    for i, (x, y) in enumerate(l):
        rv.x[i] = x
        rv.y[i] = y

    rv.points = len(l)

    return rv


def intersect(Polygon a, Polygon b):
    """
    Given two Polygons, returns a Polygon that is the intersection of the
    points in the two.

    This assumes that both polygons are convex and wound clockwise.
    """



