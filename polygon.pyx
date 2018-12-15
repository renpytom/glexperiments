from __future__ import print_function

from cpython.array cimport array
from cpython.array cimport copy as array_copy

# The maximum number of points a polygon can have.

DEF MAX_POINTS = 32

cdef array template = array('f', [ 0 ] * MAX_POINTS)

cdef class Polygon:
    def __init__(self):
        self.xarray = array_copy(template)
        self.yarray = array_copy(template)
        self.x = self.xarray.data.as_floats
        self.y = self.yarray.data.as_floats
        self.points = 0

def polygon(l):

    cdef Polygon rv = Polygon()

    for i, (x, y) in enumerate(l):
        rv.xarray[i] = x
        rv.yarray[i] = y

    rv.points = len(l)

    return rv


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

cdef Polygon intersectOnce(float a0x, float a0y, float a1x, float a1y, Polygon p):

    # The vector from a0 to a1.
    cdef float vecax = a1x - a0x
    cdef float vecay = a1y - a0y

    # The vector from a0 to each point.
    cdef float vecpx
    cdef float vexpx

    # For each point, are we inside or outside?
    cdef bint inside[MAX_POINTS]

    cdef int i
    cdef int j
    cdef bint allin = True

    # Figure out which points are 'inside' the wound line.
    for 0 <= i < p.points:
        vecpx = p.x[i] - a0x
        vecpy = p.y[i] - a0y

        inside[i] = vecax * vecpy >= vecay * vecpx
        allin = allin and inside[i]

    # If all the points are inside, just return the polygon intact.
    if allin:
        return p

    rv = Polygon()

    j = p.points - 1

    for 0 <= i < p.points:
        if inside[i]:
            if not inside[j]:
                intersectLines(
                    a0x, a0y, a1x, a1y,
                    p.x[j], p.y[j], p.x[i], p.y[i],
                    &rv.x[rv.points], &rv.y[rv.points])

                rv.points += 1

            rv.x[rv.points] = p.x[i]
            rv.y[rv.points] = p.y[i]
            rv.points += 1

        else:
            if inside[j]:
                intersectLines(
                    a0x, a0y, a1x, a1y,
                    p.x[j], p.y[j], p.x[i], p.y[i],
                    &rv.x[rv.points], &rv.y[rv.points])

                rv.points += 1

        j = i

    return rv

def intersect(Polygon a, Polygon b):
    """
    Given two Polygons, returns a Polygon that is the intersection of the
    points in the two.

    This assumes that both polygons are convex and wound clockwise.
    """

    cdef int i
    cdef float a0x, a0y, a1x, a1y

    a0x = a.x[a.points-1]
    a0y = a.y[a.points-1]

    cdef Polygon even = Polygon()
    cdef Polygon odd = Polygon()
    cdef Polygon rv

    for 0 <= i < a.points:
        a1x = a.x[i]
        a1y = a.y[i]

        if i & 1:
            rv = odd
        else:
            rv = even

        print((a0x, a0y), "->", (a1x, a1y))

        intersectOnce(a0x, a0y, a1x, a1y, b, rv)
        b = rv

        a0x = a1x
        a0y = a1y


    return rv
