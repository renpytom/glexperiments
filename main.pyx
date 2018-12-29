from __future__ import print_function

import time

from pygame_sdl2 cimport *
import pygame_sdl2
import_pygame_sdl2()

from array import array
from shaders import Program
from mesh import Mesh
from matrix import Matrix, renpy_matrix

from uguugl cimport *

import glm

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
    gl_Position = vec4(aPosition.xyz, 1) * uTransform;
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

attribute vec4 aPosition;

void main() {
    gl_Position = vec4(aPosition.xyz, 1) * uTransform;
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
        0.0, 0.0, 0.0, 1.0, 0.0, 0.0,
          w, 0.0, 0.0, 1.0, 1.0, 0.0,
          w,   h, 0.0, 1.0, 1.0, 1.0,
        0.0,   h, 0.0, 1.0, 0.0, 1.0,
        ])

#     rv.add_polygon([
#         0.0, h/2.0, 0.0, 1.0, 0.0, 0.5,
#           w, h/2.0, 0.0, 1.0, 1.0, 0.5,
#           w,   h, 0.0, 1.0, 1.0, 1.0,
#         0.0,   h, 0.0, 1.0, 0.0, 1,0,
#         ])

    return rv

class Main(object):

    def init(self):

        ftl.init_ftl()

        global program
        self.blit_program = Program(VERTEX_SHADER, FRAGMENT_SHADER)
        self.blit_program.load()

        self.logo_tex = ftl.load_texture("logo base.png")
        self.blue_tex = ftl.load_texture("blue.png")

        self.poly_program = Program(POLYGON_VERTEX, POLYGON_FRAGMENT)
        self.poly_program.load()

        self.logo_mesh = texture_mesh(234, 360)
        self.offset_mesh = self.logo_mesh.copy()
        self.offset_mesh.offset(100, 100, 0)

        self.triangle_mesh = Mesh()
        self.triangle_mesh.add_polygon([
            217, 50, 0, 1,
            334, 510, 0, 1,
            100, 510, 0, 1,
        ])

        self.combined_mesh = self.offset_mesh.intersect(self.triangle_mesh)


        self.transform = renpy_matrix(800, 800, 100, 990, 4000)

        self.unity_transform = Matrix(4, [
            1.0 / 400.0, 0.0, 0.0, -1.0,
            0.0, -1.0 / 400.0, 0.0, 1.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
        ])


    def draw_unity_mesh(self, mesh, tex):

        uColorMatrix = Matrix(4, [
            1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
            ])

        glEnable(GL_BLEND)
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)

        glActiveTexture(GL_TEXTURE0)
        glBindTexture(GL_TEXTURE_2D, tex)


        self.blit_program.draw(
            mesh,
            uTransform=self.unity_transform,
            uTex0=0,
            uColorMatrix=uColorMatrix,
            )


    def draw_mesh(self, mesh, tex):

        uColorMatrix = Matrix(4, [
            1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
            ])

        glEnable(GL_BLEND)
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)

        glActiveTexture(GL_TEXTURE0)
        glBindTexture(GL_TEXTURE_2D, tex)


        self.blit_program.draw(
            mesh,
            uTransform=self.transform,
            uTex0=0,
            uColorMatrix=uColorMatrix,
            )

    def draw_polygon(self, mesh, color):

        self.poly_program.draw(
            mesh,
            uTransform=self.transform,
            uColor=color,
            )

    def draw_simple(self):

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

    start = time.time()

    def draw(self):
        glClearColor(0.7, 0.8, 0.8, 1.0)
        glClear(GL_COLOR_BUFFER_BIT)

        glViewport(0, 0, 800, 800)

        mesh = self.logo_mesh.copy()

        from math import sin, cos, radians

        a = time.time() - self.start

        mesh.offset(-116, -180, 0)
        mesh.multiply_matrix("aPosition", 3, Matrix(
            3, [ 1, 0, 0,
                 0, cos(a), -sin(a),
                 0, sin(a), cos(a),
                 ]))
        mesh.offset(400, 400, 0)

        self.draw_mesh(mesh, self.logo_tex)


main = Main()
init = main.init
draw = main.draw
