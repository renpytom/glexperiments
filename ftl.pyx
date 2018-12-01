# Fast texture loading experiment.

from __future__ import print_function

from uguugl cimport *
import uguugl

cdef int root_fbo
cdef int texture_fbo


VERTEX_SHADER = b"""\
#ifdef GL_ES
precision highp float;
#endif

attribute vec4 aPosition;
attribute vec3 aColor;

varying vec3 vColor;

void main() {
    vColor = aColor;
    gl_Position = aPosition;
}
"""

FRAGMENT_SHADER = b"""\
#ifdef GL_ES
precision highp float;
#endif

// uniform sampler2D uTex0;
varying vec3 vColor;

void main() {
    gl_FragColor = vec4(vColor.r, vColor.g, vColor.b, 1.0);
}
"""

class ShaderError(Exception):
    pass

cdef GLuint load_shader(GLenum shader_type, source):

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

cdef GLuint program
cdef GLuint aPosition
cdef GLuint aColor

def init():

    global program
    global aPosition
    global aColor

    cdef GLuint vertex
    cdef GLuint fragment
    cdef GLint status

    cdef char error[1024]

    vertex = load_shader(GL_VERTEX_SHADER, VERTEX_SHADER)
    fragment = load_shader(GL_FRAGMENT_SHADER, FRAGMENT_SHADER)

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

    aPosition = glGetAttribLocation(program, "aPosition")
    aColor = glGetAttribLocation(program, "aColor")

    print(aPosition)
    print(aColor)




def draw():
    glClearColor(0.1, 0.0, 0.0, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)

    glViewport(0, 0, 800, 800)

    cdef float positions[6]
    positions[:] = [ 0.0, -0.5, -0.5, 0.5, 0.5, 0.5 ]
#     cdef float texture_coordinates[8]
#     texture_coordinates[:] = [ 0.0, 0.0, .1, 0.0, .1, .1, 0.0, .1 ]

    cdef float colors[9]
    colors[:] = [ 1.0, 0.0, 0.0,
                  0.0, 1.0, 0.0,
                  0.0, 0.0, 1.0,
                  ]

    glUseProgram(program)
    glVertexAttribPointer(aPosition, 2, GL_FLOAT, GL_FALSE, 0, positions)
    glEnableVertexAttribArray(aPosition)
    glVertexAttribPointer(aColor, 3, GL_FLOAT, GL_FALSE, 0, colors)
    glEnableVertexAttribArray(aColor)
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 3)
