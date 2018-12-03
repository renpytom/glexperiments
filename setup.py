from distutils.core import setup, Extension
from Cython.Build import cythonize
import os
import sys

if "VIRTUAL_ENV" in os.environ:
    venv = os.environ["VIRTUAL_ENV"]
else:
    venv = "/usr"

print(venv)


def extension(name):
    return Extension(name, [ name + ".pyx" ], include_dirs=[
        venv + "/include/python{}.{}".format(sys.version_info.major, sys.version_info.minor),
        "/usr/include/SDL2" ],
        libraries=[ "SDL2" ],
        )


setup(
    name='glexperiments',
    ext_modules=cythonize([
        extension("uguugl"),
        extension("uguu"),
        extension("shaders"),
        extension("ftl"),
        ],
        include_path=[ ".." ])
)
