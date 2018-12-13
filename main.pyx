from __future__ import print_function

from pygame_sdl2 cimport *
import pygame_sdl2
import_pygame_sdl2()

from array import array
from shaders cimport Program
from polygon cimport Polygon
from polygon import polygon, intersect
from uguugl cimport *

import ftl

cdef GLuint logoTex
cdef GLuint blueTex


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


POLYGON_VERTEX = b"""\
#ifdef GL_ES
precision highp float;
#endif

uniform mat4 uTransform;

attribute float aX;
attribute float aY;

void main() {
    gl_Position = vec4(aX, aY, 0, 1) * uTransform;
}
"""

POLYGON_FRAGMENT = b"""\
#ifdef GL_ES
precision highp float;
#endif

uniform vec4 uColor;

void main() {
    gl_FragColor = uColor;
}
"""



def init():

    ftl.init_ftl()

    global program
    program = Program(VERTEX_SHADER, FRAGMENT_SHADER)
    program.load()

    global logoTex
    global blueTex

    logoTex = ftl.load_texture("logo base.png")
    blueTex = ftl.load_texture("blue.png")

    global poly_program
    poly_program = Program(POLYGON_VERTEX, POLYGON_FRAGMENT)
    poly_program.load()

    global polygon1
    polygon1 = polygon([
            (200, 200),
            (400, 200),
            (400, 400),
            (200, 400),
        ])

    global polygon2
    polygon2 = polygon([
        (300, 150),
        (400, 450),
        (200, 450),
        ])

    global polygon3
    polygon3 = intersect(polygon1, polygon2)


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

def draw_polygon(Polygon p, color):

    transform = array('f', [
        1.0 / 400.0, 0.0, 0.0, -1.0,
        0.0, -1.0 / 400.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
    ])

    poly_program.setup(
        uTransform=transform,
        uColor=color,
        aX=p.xarray,
        aY=p.yarray,
        )

    poly_program.draw(GL_TRIANGLE_FAN, 0, p.points)


def draw():
    glClearColor(0.8, 0.8, 0.8, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)

    glViewport(0, 0, 800, 800)

    blit(logoTex, 0, 0, 234/2, 360/2)
    blit(logoTex, 800-234, 0, 234, 360)
#     blit(blueTex, 0, 0, 234/2, 360/2)
#     blit(blueTex, 234/2, 0, 234, 360)

    draw_polygon(polygon1, [0.5, 0.0, 0.0, 1.0])
    draw_polygon(polygon2, [0.0, 0.5, 0.0, 1.0])
    draw_polygon(polygon3, [0.5, 0.5, 0.0, 1.0])

