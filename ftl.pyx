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
from array import array


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
uniform mat4 uColorMatrix;
varying vec2 vTexCoord;

void main() {
    gl_FragColor = texture2D(uTex0, vTexCoord.xy) * uColorMatrix;
}
"""



FTL_VERTEX_SHADER = b"""\
#ifdef GL_ES
precision highp float;
#endif

attribute vec2 aPosition;
attribute vec2 aTexCoord;

varying vec2 vTexCoord;

void main() {
    vTexCoord = aTexCoord;
    gl_Position = vec4(aPosition, 0.0, 1.0);
}
"""

FTL_FRAGMENT_SHADER = b"""\
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

cdef GLuint logoTex
cdef GLuint blueTex

cdef GLuint root_fbo
cdef GLuint texture_fbo

def init_ftl():

    global ftl_program
    ftl_program = Program(FTL_VERTEX_SHADER, FTL_FRAGMENT_SHADER)
    ftl_program.load()

    global root_fbo
    global texture_fbo

    glGetIntegerv(GL_FRAMEBUFFER_BINDING, <GLint *> &root_fbo);
    glGenFramebuffers(1, &texture_fbo)


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

    cdef GLuint premultiplied
    glGenTextures(1, &premultiplied)

    glBindTexture(GL_TEXTURE_2D, premultiplied)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, s.w, s.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL)

    glBindFramebuffer(GL_FRAMEBUFFER, texture_fbo)

    glFramebufferTexture2D(
        GL_FRAMEBUFFER,
        GL_COLOR_ATTACHMENT0,
        GL_TEXTURE_2D,
        premultiplied,
        0)

    glViewport(0, 0, s.w, s.h)
    glClearColor(0, 0, 0, 0)
    glClear(GL_COLOR_BUFFER_BIT)

    aPosition = array('f', [
        -1.0, -1.0,
        -1.0, 1.0,
        1.0, 1.0,
        1.0, -1.0,
        ])

    aTexCoord = array('f', [
        0.0, 0.0,
        0.0, 1.0,
        1.0, 1.0,
        1.0, 0.0,
        ])

    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, tex)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, s.w, s.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, data)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)

    glEnable(GL_BLEND)
    glBlendFuncSeparate(GL_SRC_ALPHA, GL_ZERO, GL_ONE, GL_ZERO)

    ftl_program.setup(aPosition=aPosition, aTexCoord=aTexCoord, uTex0=0)
    ftl_program.draw(GL_TRIANGLE_FAN, 0, 4)

    glDeleteTextures(1, &tex)

    glBindTexture(GL_TEXTURE_2D, premultiplied)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
    glGenerateMipmap(GL_TEXTURE_2D)

    glBindFramebuffer(GL_FRAMEBUFFER, root_fbo)

    free(data)

    return premultiplied

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

    init_ftl()

    global program
    program = Program(VERTEX_SHADER, FRAGMENT_SHADER)
    program.load()


    global logoTex
    global blueTex

    logoTex = load_texture("logo base.png")
    blueTex = load_texture("blue.png")

def blit(tex, x, y, w, h):
    x1 = x + w
    y1 = y + h

    transform = array('f', [
        1.0 / 400.0, 0.0, 0.0, -1.0,
        0.0, -1.0 / 400.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
    ])

    positions = array('f', [
        x, y, 0.0, 1.0,
        x1, y, 0.0, 1.0,
        x, y1, 0.0, 1.0,
        x1, y1, 0.0, 1.0,
        ])

    texture_coordinates=array('f', [
                  0.0, 0.0,
                  1.0, 0.0,
                  0.0, 1.0,
                  1.0, 1.0,
                  ])

    uColorMatrix = array('f', [
        .2126, .7152, .0722, 0.0,
        .199844, .672288, .067868, 0.0,
        .161576, .543552, .054872, 0.0,
        0.0, 0.0, 0.0, 1.0,
        ])

    glEnable(GL_BLEND)
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)

    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, tex)

    program.setup(
        uTransform=transform,
        uTex0=0,
        uColorMatrix=uColorMatrix,
        aPosition=positions,
        aTexCoord=texture_coordinates)

    program.draw(GL_TRIANGLE_STRIP, 0, 4)



def draw():
    glClearColor(0.8, 0.8, 0.8, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)

    glViewport(0, 0, 800, 800)

    blit(logoTex, 0, 0, 234/2, 360/2)
    blit(logoTex, 234/2, 0, 234, 360)


#     blit(blueTex, 0, 0, 234/2, 360/2)
#     blit(blueTex, 234/2, 0, 234, 360)
