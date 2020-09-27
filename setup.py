import sys
import site
from skbuild import setup

site.ENABLE_USER_SITE = "--user" in sys.argv[1:]

setup(
    version = '5.5.0',
    name = 'clingo',
    description = 'A grounder and solver for logic programs.',
    author = 'Roland Kaminski',
    license = 'MIT',
    cmake_args=['-DPYCLINGO_USER_INSTALL=OFF', '-DPYCLINGO_USE_INSTALL_PREFIX=ON', '-DPYCLINGO_INSTALL_DIR=.'],
)
