from uguugl cimport *

class ShaderError(Exception):
    pass

cdef class Program(object):
    """
    Represents an OpenGL program.
    """

    def __init__(self, vertex, fragment):
        self.vertex = vertex
        self.fragment = fragment

    # Loads a shader and returns its number.
    cdef GLuint load_shader(self, GLenum shader_type, source) except? 0:

        cdef GLuint shader
        cdef GLchar *source_ptr = <char *> source
        cdef GLint length
        cdef GLint status

        cdef char error[1024]


        shader = glCreateShader(shader_type)
        length = len(source)

        glShaderSource(shader, 1, <const GLchar * const *> &source_ptr, &length)
        glCompileShader(shader)

        glGetShaderiv(shader, GL_COMPILE_STATUS, &status)

        if status == GL_FALSE:
            glGetShaderInfoLog(shader, 1024, NULL, error)
            raise ShaderError((<object> error).decode("utf-8"))

        return shader

    def load(self):
        cdef GLuint fragment
        cdef GLuint vertex
        cdef GLuint program
        cdef GLint status

        cdef char error[1024]

        vertex = self.load_shader(GL_VERTEX_SHADER, self.vertex)
        fragment = self.load_shader(GL_FRAGMENT_SHADER, self.fragment)

        program = glCreateProgram()
        glAttachShader(program, vertex)
        glAttachShader(program, fragment)
        glLinkProgram(program)

        glGetProgramiv(program, GL_LINK_STATUS, &status)

        if status == GL_FALSE:
            glGetProgramInfoLog(program, 1024, NULL, error)
            raise ShaderError((<object> error).decode("utf-8"))

        glDeleteShader(vertex)
        glDeleteShader(fragment)

        self.program = program

