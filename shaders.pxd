from uguugl cimport *

cdef class Program(object):

    # The number of the OpenGL program created.
    cdef GLuint program

    # The text of the vertex and fragment shaders.
    cdef object vertex
    cdef object fragment

    cdef GLuint load_shader(self, GLenum shader_type, source) except? 0
