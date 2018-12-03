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

from shaders cimport Program

cdef int root_fbo
cdef int texture_fbo


VERTEX_SHADER = b"""\
#ifdef GL_ES
precision highp float;
#endif

uniform mat4 uTransform;

attribute vec4 aPosition;
attribute vec2 aTexCoord;

varying vec2 vTexCoord;

void main() {
    vTexCoord = aTexCoord;
    gl_Position = aPosition * uTransform;
}
"""

FRAGMENT_SHADER = b"""\
#ifdef GL_ES
precision highp float;
#endif

uniform sampler2D uTex0;
varying vec2 vTexCoord;

void main() {
    gl_FragColor = texture2D(uTex0, vTexCoord.xy);
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

cdef GLuint blitProgram

cdef GLuint uTransform
cdef GLuint aPosition
cdef GLuint aTexCoord
cdef GLuint uTex0

cdef GLuint logoTex
cdef GLuint blueTex

cdef GLuint load_texture(fn):
    """
    Loads a texture.
    """

    surf = pygame_sdl2.image.load(fn)
    surf = surf.convert_alpha(sample_alpha)

    cdef SDL_Surface *s
    s = PySurface_AsSurface(surf)

    cdef unsigned char *pixels = <unsigned char *> s.pixels
    cdef unsigned char *data = <unsigned char *> malloc(s.h * s.w * 4)
    cdef unsigned char *p = data

    for 0 <= i < s.h:
        memcpy(p, pixels, s.w * 4)
        pixels[40 + 0] = 255
        pixels[40 + 1] = 255
        pixels[40 + 2] = 255
        pixels[40 + 3] = 255

        pixels += s.pitch
        p += (s.w * 4)

    cdef GLuint tex

    glGenTextures(1, &tex)

    glBindTexture(GL_TEXTURE_2D, tex)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, s.w, s.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, data)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)

    glGenerateMipmap(GL_TEXTURE_2D)

    free(data)

    return tex

def set_rgba_masks():
    """
    This rebuilds the sample surfaces, to ones that use the given
    masks.
    """

    # Annoyingly, the value for the big mask seems to vary from
    # platform to platform. So we read it out of a surface.

    global sample_alpha

    # Create a sample surface.
    s = pygame_sdl2.Surface((10, 10), 0, 32)
    sample_alpha = s.convert_alpha()

    # Sort the components by absolute value.
    masks = list(sample_alpha.get_masks())
    masks.sort(key=lambda a : abs(a))

    # Choose the masks.
    import sys
    if sys.byteorder == 'big':
        masks = ( masks[3], masks[2], masks[1], masks[0] )
    else:
        masks = ( masks[0], masks[1], masks[2], masks[3] )

    # Create the sample surface.
    sample_alpha = pygame_sdl2.Surface((10, 10), 0, 32, masks)

def init():

    set_rgba_masks()

    global blitProgram

    cdef Program p
    p = Program(VERTEX_SHADER, FRAGMENT_SHADER)
    p.load()

    blitProgram = p.program

    global uTransform
    global aPosition
    global aTexCoord
    global uTex0

    uTransform = glGetUniformLocation(blitProgram, "uTransform")
    aPosition = glGetAttribLocation(blitProgram, "aPosition")
    aTexCoord = glGetAttribLocation(blitProgram, "aTexCoord")
    uTex0 = glGetUniformLocation(blitProgram, "uTex0")

    print(blitProgram, uTransform, aTexCoord, uTex0)

    global logoTex
    global blueTex

    logoTex = load_texture("logo base.png")
    blueTex = load_texture("blue.png")


cdef void blit(GLuint tex, float x, float y, float w, float h):
    cdef float x1 = x + w
    cdef float y1 = y + h


    cdef float transform[16]

    transform[:] = [
        1.0 / 400.0, 0.0, 0.0, -1.0,
        0.0, -1.0 / 400.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
    ]

    cdef float positions[16]
    positions[:] =  [
        x, y, 0.0, 1.0,
        x1, y, 0.0, 1.0,
        x, y1, 0.0, 1.0,
        x1, y1, 0.0, 1.0,
        ]

    cdef float texture_coordinates[8]
    texture_coordinates[:] = [
                  0.0, 0.0,
                  1.0, 0.0,
                  0.0, 1.0,
                  1.0, 1.0,
                  ]

    glEnable(GL_BLEND)
    glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    glUseProgram(blitProgram)

    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, tex)
    glUniform1i(uTex0, 0)

    glUniformMatrix4fv(uTransform, 1, GL_FALSE, transform)
    glVertexAttribPointer(aPosition, 4, GL_FLOAT, GL_FALSE, 0, positions)
    glEnableVertexAttribArray(aPosition)
    glVertexAttribPointer(aTexCoord, 2, GL_FLOAT, GL_FALSE, 0, texture_coordinates)
    glEnableVertexAttribArray(aTexCoord)
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)



def draw():
    glClearColor(0.5, 0.5, 0.5, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)

    glViewport(0, 0, 800, 800)

    blit(logoTex, 0, 0, 234/2, 360/2)
    blit(logoTex, 234/2, 0, 234, 360)


    blit(blueTex, 0, 0, 234/2, 360/2)
    blit(blueTex, 234/2, 0, 234, 360)
