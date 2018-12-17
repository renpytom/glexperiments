from libc.stdlib cimport malloc, free
from libc.string cimport memcpy

from polygon cimport Polygon

cdef class Mesh:

    def __init__(self):
        """
        Represents a mesh consisting of one or more polygons.

        This needs to be created in the correct order.

        First, use add_attribute to add attributes. Then call add_polygon
        to add polygons with attributes. After that, it is possible to call
        methods like offset to manipulate the mesh.

        Once get_data is called (by Shader.draw), the mesh becomes immutable.
        """

        self.points = 0
        self.stride = 3
        self.polygons = [ ]
        self.attributes = { "aPosition" : 0 }
        self.data = NULL

    def __dealloc__(self):
        if self.data:
            free(self.data)

    def add_attribute(self, name, size):
        """
        Adds an attribute to this mesh.

        `name`
            The name of the attribute.

        `size`
            The number of floats per vertex that make up the attribute.
        """

        self.attributes[name] = self.stride
        self.stride += size

    def add_polygon(self, data):
        """
        Adds a polygon.

        `data`
            This is an iterable. It should have self.stride data for each
            vertex, and the number of vertices is derived from the length
            of the data.
        """

        cdef Polygon p = Polygon(self.stride, len(data) // self.stride, data)
        self.points += p.points

        self.polygons.append(p)

    cdef float *get_data(self, name):
        cdef Polygon p
        cdef int i

        if len(self.polygons) == 1:

            p = self.polygons[0]
            return p.data + <int> self.attributes[name]

        if not self.data:
            self.data = <float *> malloc(self.points * self.stride * sizeof(float))

            i = 0

            for p in self.polygons:
                memcpy(&self.data[i], p.data, p.points * self.stride * sizeof(float))
                i += p.points * self.stride

        return self.data + <int> self.attributes[name]

    def copy(self):
        """
        Returns a copy of this mesh.
        """

        rv = Mesh()
        rv.stride = self.stride
        rv.points = self.points
        rv.polygons = [ i.copy() for i in self.polygons ]
        rv.attributes = self.attributes

        return rv

    def offset(self, float x, float y, float z):
        """
        Applies an offset to the position of every
        """

        cdef Polygon p

        for p in self.polygons:
            p.offset(x, y, z)
