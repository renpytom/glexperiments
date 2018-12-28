from __future__ import print_function

from matrix cimport Matrix
from libc.stdlib cimport malloc, free
from libc.string cimport memcpy

DEF MAX_POINTS = 128

DEF X = 0
DEF Y = 1
DEF Z = 2
DEF W = 3

cdef class Polygon:

    def __init__(Polygon self, int stride, int points, data):
        """
        Allocates a new Polygon.

        `stride`
            The number of floats per vertex. This should be at least 3, for the
            default aPosition vec3.

        `points`
            The number of vertices in the polygon that space is allocated for.
            If `data` is given, this is also the number of points in the polygon.

        `data`
            If not None, an iterable of length stride * points, that gives the
            vertex data for each of the points.
        """

        cdef int i

        self.stride = stride

        self.data = <float *> malloc(sizeof(float) * points * stride)

        if data is None:
            self.points = 0
        else:
            self.points = points

            for 0 <= i < stride * points:
                self.data[i] = data[i]

    def __dealloc__(Polygon self):
        free(self.data)

    cpdef Polygon copy(Polygon self):
        """
        Returns a copy of this polygon.
        """

        cdef Polygon rv = Polygon(self.stride, self.points, None)
        rv.points = self.points
        memcpy(rv.data, self.data, sizeof(float) * self.stride * self.points)
        return rv

    cpdef void offset(Polygon self, float x, float y, float z):
        """
        Apply an offset to the position of each vertex
        """

        cdef float *p = self.data
        cdef int i


        for 0 <= i < self.points:
            p[X] += x
            p[Y] += y
            p[Z] += z

            p += self.stride

    cpdef void multiply_matrix(Polygon self, int offset, int size, Matrix matrix):
        """
        Multiplies the location of the vertex by `matrix`, which can be 2, 3, or 4
        elements wide. This always updates the 3 elements of the vertex -
        for a 4-element one, the vector is expected to be [x y z 1].

        `offset`
            The offset of the attribute to use.
        """

        cdef int i, x, y
        cdef float *p = self.data + offset
        cdef float *m = matrix.m
        cdef int d = matrix.dimension

        cdef float py

        cdef float vec[5]

        vec[0] = 1.0
        vec[1] = 1.0
        vec[2] = 1.0
        vec[3] = 1.0
        vec[4] = 1.0

        for 0 <= i < self.points:

            for 0 <= y < size:
                vec[y] = p[y]

            for 0 <= y < size:
                py = 0

                for 0 <= x < d:
                    py += m[y * d + x] * vec[x]

                p[y] = py

            p += self.stride


    def print_points(self, prefix):
        cdef int i
        cdef int p

        for 0 <= p < self.points:
            print(prefix, p, end=':')
            for 0 <= i < self.stride:
                print(self.data[p * self.stride + i], end=' ')
            print()


cdef inline float get(Polygon p, int index, int offset):
    return p.data[index * p.stride + offset]

cdef inline float *ref(Polygon p, int index, int offset):
    return &p.data[index * p.stride + offset]

cdef inline float set(Polygon p, int index, int offset, float value):
    p.data[index * p.stride + offset] = value
    return value



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

cdef Polygon intersectOnce(float a0x, float a0y, float a1x, float a1y, Polygon p, int rvstride):

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
        vecpx = get(p, i, X) - a0x
        vecpy = get(p, i, Y) - a0y

        inside[i] = vecax * vecpy >= vecay * vecpx
        allin = allin and inside[i]

    # If all the points are inside, just return the polygon intact.
    if allin:
        return p

    rv = Polygon(rvstride, p.points * 2, None)

    j = p.points - 1

    for 0 <= i < p.points:
        if inside[i]:
            if not inside[j]:
                intersectLines(
                    a0x, a0y, a1x, a1y,
                    get(p, j, X), get(p, j, Y), get(p, i, X), get(p, i, Y),
                    ref(rv, rv.points, X), ref(rv, rv.points, Y))

                rv.points += 1

            set(rv, rv.points, X, get(p, i, X))
            set(rv, rv.points, Y, get(p, i, Y))
            rv.points += 1

        else:
            if inside[j]:
                intersectLines(
                    a0x, a0y, a1x, a1y,
                    get(p, j, X), get(p, j, Y), get(p, i, X), get(p, i, Y),
                    ref(rv, rv.points, X), ref(rv, rv.points, Y))

                rv.points += 1

        j = i

    return rv


cdef Polygon restride_polygon(Polygon src, int new_stride):

    cdef Polygon rv = Polygon(new_stride, src.points, None)

    cdef float *ap = src.data
    cdef float *bp = rv.data

    cdef int i

    for 0 <= i < src.points:
        bp[X] = ap[X]
        bp[Y] = ap[Y]
        bp[Z] = ap[Z]

        ap += src.stride
        bp += rv.stride

    return rv



cpdef intersect(Polygon a, Polygon b, int rvstride):
    """
    Given two Polygons, returns a Polygon that is the intersection of the
    points in the two.

    This assumes that both polygons are convex and wound clockwise.
    """

    cdef int i
    cdef float a0x, a0y, a1x, a1y

    a0x = get(a, a.points-1, X)
    a0y = get(a, a.points-1, Y)

    cdef Polygon rv = b

    for 0 <= i < a.points:
        a1x = get(a, i, X)
        a1y = get(a, i, Y)

        rv = intersectOnce(a0x, a0y, a1x, a1y, rv, rvstride)

        if rv.points < 3:
            return None

        a0x = a1x
        a0y = a1y

    # This always has to copy the polygon, so if it's entirely inside, do so.
    if rv is b:
        rv = restride_polygon(rv, rvstride)

    return rv


cpdef barycentric(Polygon a, Polygon b, int offset):

    cdef int i
    cdef int j
    cdef int k

    cdef float ax0 = get(a, 0, X)
    cdef float ay0 = get(a, 0, Y)
    cdef float az0 = get(a, 0, Z)

    cdef float v0x = get(a, 1, X) - ax0
    cdef float v0y = get(a, 1, Y) - ay0
    cdef float v0z = get(a, 1, Z) - az0

    cdef float v1x, v1y, v1z, v2x, v2y, v2z
    cdef float d00, d01, d11, d20, d21
    cdef float d003, d013, d113, d203, d213
    cdef float denom
    cdef float u, v, w


    for 2 <= i < a.points:

        v1x = get(a, i, X) - ax0
        v1y = get(a, i, Y) - ay0
        v1z = get(a, i, Z) - az0

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

                v2x = get(b, j, X) - ax0
                v2y = get(b, j, Y) - ay0

                d20 = v2x * v0x + v2y * v0y
                d21 = v2x * v1x + v2y * v1y

                v = (d11 * d20 - d01 * d21) / denom
                w = (d00 * d21 - d01 * d20) / denom

                if not (0.0 <= v <= 1.0) and (0.0 <= w <= 1.0):
                    continue

                u = 1.0 - v - w

                z = u * az0 + v * get(a, i-1, Z) + w * get(a, i, Z)
                set(b, j, Z, z)
                set(b, j, W, 1.0)

                v2z = z - az0

                d203 = d20 + v2z * v0z
                d213 = d21 + v2z * v1z

                v = (d113 * d203 - d013 * d213) / denom3
                w = (d003 * d213 - d013 * d203) / denom3
                u = 1.0 - v - w

                for 3 <= k < a.stride:
                    set(b, j, k + offset,
                        u * get(a, 0, k) +
                        v * get(a, i-1, k) +
                        w * get(a, i, k))

        v0x = v1x
        v0y = v1y

