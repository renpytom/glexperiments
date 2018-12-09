from uguugl cimport *
from libc.stdlib cimport malloc, free

from cpython.array cimport array

def shader_data(l):
    return array('f', l)

class ShaderError(Exception):
    pass


GLSL_PRECISIONS = {
    "highp",
    "mediump",
    "lowp",
    }


def uniform_float(uniform, data):
    glUniform1f(uniform, data)

def uniform_vec2(uniform, data):
    a, b = data
    glUniform2f(uniform, a, b)

def uniform_vec3(uniform, data):
    a, b, c = data
    glUniform3f(uniform, a, b, c)

def uniform_vec4(uniform, data):
    a, b, c, d = data
    glUniform4f(uniform, a, b, c, d)

def uniform_mat2(uniform, array data):
    glUniformMatrix2fv(uniform, 1, GL_FALSE, data.data.as_floats)

def uniform_mat3(uniform, array data):
    glUniformMatrix3fv(uniform, 1, GL_FALSE, data.data.as_floats)

def uniform_mat4(uniform, array data):
    glUniformMatrix4fv(uniform, 1, GL_FALSE, data.data.as_floats)

def uniform_sampler2d(uniform, data):
    glUniform1i(uniform, data)

UNIFORM_TYPES = {
    "float" : uniform_float,
    "vec2" : uniform_vec2,
    "vec3" : uniform_vec3,
    "vec4" : uniform_vec4,
    "mat2" : uniform_mat2,
    "mat3" : uniform_mat3,
    "mat4" : uniform_mat4,
    "sampler2D" : uniform_sampler2d,
    }

def attribute_float(attribute, array data):
    glVertexAttribPointer(attribute, 1, GL_FLOAT, GL_FALSE, 0, data.data.as_floats)
    glEnableVertexAttribArray(attribute)

def attribute_vec2(attribute, array data):
    glVertexAttribPointer(attribute, 2, GL_FLOAT, GL_FALSE, 0, data.data.as_floats)
    glEnableVertexAttribArray(attribute)

def attribute_vec3(attribute, array data):
    glVertexAttribPointer(attribute, 3, GL_FLOAT, GL_FALSE, 0, data.data.as_floats)
    glEnableVertexAttribArray(attribute)

def attribute_vec4(attribute, array data):
    glVertexAttribPointer(attribute, 4, GL_FLOAT, GL_FALSE, 0, data.data.as_floats)
    glEnableVertexAttribArray(attribute)

ATTRIBUTE_TYPES = {
    "float" : attribute_float,
    "vec2" : attribute_vec2,
    "vec3" : attribute_vec3,
    "vec4" : attribute_vec4,
}


cdef class Program:
    """
    Represents an OpenGL program.
    """

    def __init__(self, vertex, fragment):
        self.vertex = vertex
        self.fragment = fragment

        # A list of (name, location, data_function) tuples.
        self.variables = [ ]

    def find_variables(self, source):

        for l in source.split("\n"):

            l = l.strip()
            l = l.rstrip("; ")
            tokens = l.split()

            def advance():
                if not tokens:
                    return None
                else:
                    return tokens.pop(0)

            token = advance()

            if token == "invariant":
                token = advance()

            if token == "uniform":
                storage = "uniform"
                types = UNIFORM_TYPES
            elif token == "attribute":
                storage = "attribute"
                types = ATTRIBUTE_TYPES
            else:
                continue

            token = advance()

            if token in ( "highp", "mediump", "lowp"):
                token = advance()
                continue

            if token not in types:
                raise ShaderError("Unsupported type {} in '{}'. Only float, vec<2-4>, mat<2-4>, and sampler2D are supported.".format(token, l))

            type = token

            name = advance()
            if name is None:
                raise ShaderError("Couldn't finds name in {}".format(l))

            if tokens:
                raise ShaderError("Spurious tokens after the name in '{}'. Arrays are not supported in Ren'Py.".format(l))

            if storage == "uniform":
                location = glGetUniformLocation(self.program, name)
            else:
                location = glGetAttribLocation(self.program, name)

            data_function = types[type]
            self.variables.append((name, location, data_function))


    cdef GLuint load_shader(self, GLenum shader_type, source) except? 0:
        """
        This loads a shader into the GPU, and returns the number.
        """

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
        """
        This loads the program into the GPU.
        """

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

        self.find_variables(self.vertex)
        self.find_variables(self.fragment)

    def setup(self, **kwargs):
        glUseProgram(self.program)

        for name, attribute, data_function in self.variables:
            data_function(attribute, kwargs[name])

    def draw(self, mode, start, count):
        glDrawArrays(mode, start, count)
