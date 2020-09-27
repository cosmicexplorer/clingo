from skbuild import setup

setup(
    version = '5.5.0',
    name = 'clingo',
    description = 'A grounder and solver for logic programs.',
    author = 'Roland Kaminski',
    license = 'MIT',
    cmake_args=['-DPYCLINGO_USER_INSTALL=OFF', '-DPYCLINGO_USE_INSTALL_PREFIX=ON'],
)
