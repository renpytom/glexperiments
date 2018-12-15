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
        self.zarray = array_copy(template)
        self.data = { }

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

    cdef float *px = p.xarray.data.as_floats
    cdef float *py = p.yarray.data.as_floats

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
        vecpx = px[i] - a0x
        vecpy = py[i] - a0y

        inside[i] = vecax * vecpy >= vecay * vecpx
        allin = allin and inside[i]

    # If all the points are inside, just return the polygon intact.
    if allin:
        return p

    rv = Polygon()

    cdef float *rvx = rv.xarray.data.as_floats
    cdef float *rvy = rv.yarray.data.as_floats


    j = p.points - 1

    for 0 <= i < p.points:
        if inside[i]:
            if not inside[j]:
                intersectLines(
                    a0x, a0y, a1x, a1y,
                    px[j], py[j], px[i], py[i],
                    &rvx[rv.points], &rvy[rv.points])

                rv.points += 1

            rvx[rv.points] = px[i]
            rvy[rv.points] = py[i]
            rv.points += 1

        else:
            if inside[j]:
                intersectLines(
                    a0x, a0y, a1x, a1y,
                    px[j], py[j], px[i], py[i],
                    &rvx[rv.points], &rvy[rv.points])

                rv.points += 1

        j = i

    return rv

def intersect(Polygon a, Polygon b):
    """
    Given two Polygons, returns a Polygon that is the intersection of the
    points in the two.

    This assumes that both polygons are convex and wound clockwise.
    """

    cdef float *ax = a.xarray.data.as_floats
    cdef float *ay = a.yarray.data.as_floats

    cdef int i
    cdef float a0x, a0y, a1x, a1y

    a0x = ax[a.points-1]
    a0y = ay[a.points-1]

    cdef Polygon rv = b

    for 0 <= i < a.points:
        a1x = ax[i]
        a1y = ay[i]

        rv = intersectOnce(a0x, a0y, a1x, a1y, rv)
        if rv.points < 3:
            return None

        a0x = a1x
        a0y = a1y

    return rv


def barycentric(
    Polygon a,
    Polygon b):

    cdef int i
    cdef int j
    cdef int k

    cdef float *ax = a.xarray.data.as_floats
    cdef float *ay = a.yarray.data.as_floats
    cdef float *az = a.zarray.data.as_floats

    cdef float *bx = b.xarray.data.as_floats
    cdef float *by = b.yarray.data.as_floats
    cdef float *bz = b.zarray.data.as_floats

    cdef int datapoints = 0

    cdef float *adata[128]
    cdef float *bdata[128]

    cdef array aa
    cdef array ba

    datapoints = 0

    for attribute, aa in a.data.iteritems():
        ba = array_copy(b.zarray)
        b.data[attribute] = ba
        adata[datapoints] = aa.data.as_floats
        bdata[datapoints] = ba.data.as_floats
        datapoints += 1


    cdef float v0x = ax[1] - ax[0]
    cdef float v0y = ay[1] - ay[0]
    cdef float v0z = az[1] - az[0]

    cdef float v1x, v1y, v1z, v2x, v2y, v2z
    cdef float d00, d01, d11, d20, d21
    cdef float d003, d013, d113, d203, d213
    cdef float denom
    cdef float u, v, w


    for 2 <= i < a.points:

        v1x = ax[i] - ax[0]
        v1y = ay[i] - ay[0]
        v1z = az[i] - az[0]

        d00 = v0x * v0x + v0y * v0y
        d01 = v0x * v1x + v0y * v1y
        d11 = v1x * v1x + v1y * v1y

        d003 = d00 + v0z * v0z
        d013 = d01 + v0z * v1z
        d113 = d11 + v1z * v1z

        denom = d00 * d11 - d01 * d01
        denom3 = d003 * d113 - d013 * d013

        if denom and denom3:

            for 0 <= j < b.points:

                v2x = bx[j] - ax[0]
                v2y = by[j] - ay[0]

                d20 = v2x * v0x + v2y * v0y
                d21 = v2x * v1x + v2y * v1y

                v = (d11 * d20 - d01 * d21) / denom
                w = (d00 * d21 - d01 * d20) / denom

                if not (0.0 <= v <= 1.0) and (0.0 <= w <= 1.0):
                    continue

                u = 1.0 - v - w

                bz[j] = u * az[0] + v * az[i-1] + w * az[i]

                v2z = bz[j] - az[0]

                d203 = d20 + v2z * v0z
                d213 = d21 + v2z * v1z

                v = (d113 * d203 - d013 * d213) / denom3
                w = (d003 * d213 - d013 * d203) / denom3
                u = 1.0 - v - w

                for 0 <= k < datapoints:
                    bdata[k][j] = u * adata[k][0] + v * adata[k][i-1] + w * adata[k][i]

        v0x = v1x
        v0y = v1y

