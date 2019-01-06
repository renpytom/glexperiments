from __future__ import print_function

import time

from pygame_sdl2 cimport *
import pygame_sdl2
import_pygame_sdl2()

from array import array
from shaders import Program
import shadergen
from mesh import Mesh
from matrix import Matrix, renpy_projection_matrix, offset_matrix
import matrix

from uguugl cimport *

import ftl

cdef GLuint logoTex
cdef GLuint blueTex


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

        self.logo_tex = ftl.load_texture("logo base.png")
        self.blue_tex = ftl.load_texture("blue.png")

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

    def draw_mesh(self, mesh, tex, transform):

        uColorMatrix = Matrix([
            1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
            ])

        glEnable(GL_BLEND)
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)

        glActiveTexture(GL_TEXTURE0)
        glBindTexture(GL_TEXTURE_2D, tex)

        program = shadergen.get(("renpy.geometry", "renpy.texture"))

        program.draw(
            mesh,
            uTransform=transform,
            uTex0=0,
            uColorMatrix=uColorMatrix,
            )

    start = time.time()

    def draw(self):
        glClearColor(0.7, 0.8, 0.8, 1.0)
        glClear(GL_COLOR_BUFFER_BIT)

        glViewport(0, 0, 800, 800)

        mesh = self.logo_mesh.copy()

        from math import sin, cos, radians

        st = time.time() - self.start

        self.draw_mesh(mesh, self.logo_tex, matrix.screen_projection(800, 800))


main = Main()
init = main.init
draw = main.draw
