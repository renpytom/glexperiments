# Fast texture loading experiment.

from __future__ import print_function

from libc.string cimport memcpy
from libc.stdlib cimport malloc, free

from uguugl cimport *
import uguugl

from sdl2 cimport *

from pygame_sdl2 cimport *
import pygame_sdl2
import_pygame_sdl2()

cdef int root_fbo
cdef int texture_fbo


VERTEX_SHADER = b"""\
#ifdef GL_ES
precision highp float;
#endif

attribute vec4 aPosition;
attribute vec2 aTexCoord;

varying vec2 vTexCoord;

void main() {
    vTexCoord = aTexCoord;
    gl_Position = aPosition;
}
"""

FRAGMENT_SHADER = b"""\
#ifdef GL_ES
precision highp float;
#endif

varying vec2 vTexCoord;

void main() {
    gl_FragColor = vec4(vTexCoord.x, vTexCoord.y, vTexCoord.y, 1.0);
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
cdef GLuint aTexCoord

def load_texture(fn):
    """
    Loads a texture.
    """

    surf = pygame_sdl2.image.load(fn)
    surf = surf.convert_alpha()

    cdef SDL_Surface *s
    s = PySurface_AsSurface(surf)

    cdef unsigned char *pixels = <unsigned char *> s.pixels
    cdef unsigned char *data = <unsigned char *> malloc(s.h * s.w * 4)
    cdef unsigned char *p = data

    for 0 <= i < s.h:
        memcpy(p, pixels, s.w * 4)
        pixels += s.pitch
        p += (s.w * 4)

    cdef GLuint tex
    glGenTextures(1, &tex)

    glBindTexture(GL_TEXTURE_2D, tex)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, s.w, s.h, 0, GL_RGBA, GL_BYTE, data)

    free(data)


def init():

    global program
    global aPosition
    global aTexCoord

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
    aTexCoord = glGetAttribLocation(program, "aTexCoord")

    load_texture("logo base.png")


def draw():
    glClearColor(0.1, 0.0, 0.0, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)

    glViewport(0, 0, 800, 800)

    cdef float positions[8]
    positions[:] =  [
        -1.0, -1.0,
        1.0, -1.0,
        -1.0, 1.0,
        1.0, 1.0,
        ]

#     cdef float texture_coordinates[8]
#     texture_coordinates[:] = [ 0.0, 0.0, .1, 0.0, .1, .1, 0.0, .1 ]

    cdef float texture_coordinates[8]
    texture_coordinates[:] = [ 0.0, 0.0,
                  1.0, 0.0,
                  0.0, 1.0,
                  1.0, 1.0,
                  ]

    glUseProgram(program)
    glVertexAttribPointer(aPosition, 2, GL_FLOAT, GL_FALSE, 0, positions)
    glEnableVertexAttribArray(aPosition)
    glVertexAttribPointer(aTexCoord, 2, GL_FLOAT, GL_FALSE, 0, texture_coordinates)
    glEnableVertexAttribArray(aTexCoord)
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)
