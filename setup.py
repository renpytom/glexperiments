from distutils.core import setup, Extension
from Cython.Build import cythonize
import os
import sys
import symbolic_matrix

if "VIRTUAL_ENV" in os.environ:
    venv = os.environ["VIRTUAL_ENV"]
else:
    venv = "/usr"

print(venv)

symbolic_matrix.write("matrix_functions.pxi")


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
        extension("main"),
        ],
        include_path=[ ".." ])
)
