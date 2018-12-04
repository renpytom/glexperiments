from uguugl cimport *

class ShaderError(Exception):
    pass

GLSL_PRECISIONS = {
    "highp",
    "mediump",
    "lowp",
    }

GLSL_TYPES = {
    "float",
    "vec2", "vec3", "vec4",
    "mat2", "mat3", "mat4",
    "sampler2D"
    }


cdef class Program(object):
    """
    Represents an OpenGL program.
    """

    def __init__(self, vertex, fragment):
        self.vertex = vertex
        self.fragment = fragment

        # A map from attribute or uniform name to its type.
        self.type = { }

        # A map from a uniform to its number.
        self.uniform = { }

        # A map from an attribute to its number.
        self.attribute = { }



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
            elif token == "attribute":
                storage = "attribute"
            else:
                continue

            token = advance()

            if token in ( "highp", "mediump", "lowp"):
                token = advance()
                continue

            if token not in GLSL_TYPES:
                raise ShaderError("Unsupported type {} in '{}'. Only float, vec<2-4>, mat<2-4>, and sampler2D are supported.".format(token, l))

            type = token

            name = advance()
            if name is None:
                raise ShaderError("Couldn't finds name in {}".format(l))
                continue

            if tokens:
                raise ShaderError("Spurious tokens after the name in '{}'. Arrays are not supported in Ren'Py.".format(l))
                continue

            self.type[name] = type

            if storage == "uniform":
                self.uniform[name] = glGetUniformLocation(self.program, name)
            else:
                self.attribute[name] = glGetAttribLocation(self.program, name)

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


