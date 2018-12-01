#!/usr/bin/env python

import subprocess
import sys


def main():

    subprocess.check_call([ "python", "setup.py", "build_ext", "-q", "-i" ])

    import pygame_sdl2
    import uguu

    sys.argv.pop(0)
    m = __import__(sys.argv[0])

    pygame_sdl2.init()
    pygame_sdl2.display.set_mode((800, 800), pygame_sdl2.OPENGL)
    uguu.load()

    init = getattr(m, "init", None)
    if init is not None:
        init()

    while True:

        draw = getattr(m, "draw", None)
        if draw is not None:
            draw()

        pygame_sdl2.display.flip()

        ev = pygame_sdl2.event.wait()

        if ev.type == pygame_sdl2.QUIT:
            break


if __name__ == "__main__":
    main()
