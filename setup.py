import sys
import site
from setuptools import find_packages
from skbuild import setup

if not site.ENABLE_USER_SITE and "--user" in sys.argv[1:]:
    site.ENABLE_USER_SITE = True

setup(
    version = '5.5.0',
    name = 'clingo',
    description = 'A grounder and solver for logic programs.',
    author = 'Roland Kaminski',
    license = 'MIT',
    cmake_args=['-DPYCLINGO_USER_INSTALL=OFF', '-DPYCLINGO_USE_INSTALL_PREFIX=ON', '-DPYCLINGO_INSTALL_DIR=.'],
    packages=['clingo']
)
