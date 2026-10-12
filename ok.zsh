#!/usr/bin/env zsh

set -euxo pipefail

readonly _me="$0"
readonly _medir=`realpath -e "$(dirname "$(realpath -e "$_me")")"`

cd "$_medir"

readonly _build_rev=`git rev-parse HEAD`

function _clean {
  rm -rf build install
  git submodule deinit --all -f
  git clean -xfd
  git checkout -- .
}

function _prepare-build {
  git submodule update --init --recursive
  mkdir -vp build install/py
  find . -name CMakeLists.txt -type f \
    -execdir sed -i '/cmake_minimum_required/ s#(VERSION.*)#(VERSION 3.5)#' '{}' '+'
}

function _configure-build {
  local -r pfx="$1"
  local -r py_pfx="${2:-${pfx}/py}"
  local -r py_ver="${3:-3.16}"
  local -r build_rev=`git rev-parse HEAD`
  pushd build
  cmake -S.. \
    -DCLINGO_BUILD_WITH_PYTHON=ON -DCLINGO_BUILD_WITH_LUA=OFF -DCLINGO_BUILD_APPS=ON -DCLINGO_MANAGE_RPATH=ON -DCLINGO_REQUIRE_PYTHON=ON -DCLINGO_BUILD_SHARED=ON -DCLINGO_BUILD_PY_SHARED=ON -DCLINGO_INSTALL_LIB=ON -DPYCLINGO_USE_CFFI=OFF -DPYCLINGO_DYNAMIC_LOOKUP=OFF \
    -DCLINGO_BUILD_REVISION=`git rev-parse HEAD` -DCLINGO_PYTHON_VERSION':LIST=3.16;EXACT' \
    -DCLINGO_CMAKE_AR=`which gcc-ar` -DCLINGO_CMAKE_RANLIB=`which gcc-ranlib` -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=`realpath -e ../install` -DPYCLINGO_INSTALL_DIR=`realpath -e ../install/py` \
    -DCMAKE_C_FLAGS='-march=native -O3 -pipe -flto=auto -fuse-linker-plugin -fno-fat-lto-objects -Wno-error' -DCMAKE_CXX_FLAGS='-Wno-deprecated-declarations -march=native -O3 -pipe -flto=auto -fuse-linker-plugin -fno-fat-lto-objects -Wno-error' -DCMAKE_{EXE,SHARED,STATIC,MODULE}_LINKER_FLAGS='-flto=auto'
  popd
}

  make -j12 -l14):q
