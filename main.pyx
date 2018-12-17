from __future__ import print_function

from pygame_sdl2 cimport *
import pygame_sdl2
import_pygame_sdl2()

from array import array
from shaders cimport Program
from polygon import Mesh

from uguugl cimport *

import ftl

cdef GLuint logoTex
cdef GLuint blueTex


VERTEX_SHADER = b"""\
#ifdef GL_ES
precision highp float;
#endif

uniform mat4 uTransform;

attribute vec3 aPosition;
attribute vec2 aTexCoord;


varying vec2 vTexCoord;

void main() {
    vTexCoord = aTexCoord;
    gl_Position = vec4(aPosition, 1.0) * uTransform;
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

attribute vec3 aPosition;

void main() {
    gl_Position = vec4(aPosition, 1) * uTransform;
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

def texture_mesh(w, h):

    rv = Mesh()
    rv.add_attribute("aTexCoord", 2)

    rv.add_polygon([
        0.0, 0.0, 0.0, 0.0, 0.0,
          w, 0.0, 0.0, 1.0, 0.0,
          w,   h/2.0, 0.0, 1.0, 0.5,
        0.0,   h/2.0, 0.0, 0.0, 0.5,
        ])

    rv.add_polygon([
        0.0, h/2.0, 0.0, 0.0, 0.5,
          w, h/2.0, 0.0, 1.0, 0.5,
          w,   h, 0.0, 1.0, 1.0,
        0.0,   h, 0.0, 0.0, 1,0,
        ])

    return rv


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

    global logo_mesh
    logo_mesh = texture_mesh(234, 360)


def draw_mesh(tex, mesh):

    transform = array('f', [
        1.0 / 400.0, 0.0, 0.0, -1.0,
        0.0, -1.0 / 400.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
    ])

    uColorMatrix = array('f', [
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
        ])

    glEnable(GL_BLEND)
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)

    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, tex)


    program.draw(
        mesh,
        uTransform=transform,
        uTex0=0,
        uColorMatrix=uColorMatrix,
        )

def draw_polygon(mesh, color):

    transform = array('f', [
        1.0 / 400.0, 0.0, 0.0, -1.0,
        0.0, -1.0 / 400.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
    ])

    poly_program.draw(
        mesh,
        uTransform=transform,
        uColor=color,
        )

def draw_simple():

    vertex = """\
attribute vec3 aPosition;

void main() {
    gl_Position = vec4(aPosition, 1.0);
}
"""
    fragment = """\
void main() {
    gl_FragColor = vec4(0.0, 0.0, 1.0, 1.0);
}
"""

    p = Program(vertex, fragment)
    p.load()

    m = Mesh()
    m.add_polygon([
        -0.5, -0.5, 0.0,
         0.5, -0.5, 0.0,
         0.5, 0.5, 0.0,
        -0.5, 0.5, 0.0,
        ])

    p.draw(m)


def draw():
    glClearColor(0.7, 0.8, 0.8, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)

    glViewport(0, 0, 800, 800)


    draw_simple()
    draw_polygon(logo_mesh, [ 1.0, 0.0, 0.0, 1.0 ])

    # draw_mesh(logoTex, logo_mesh)

    offset = logo_mesh.copy()
    offset.offset(50, 100, 0)

    draw_mesh(logoTex, offset)
