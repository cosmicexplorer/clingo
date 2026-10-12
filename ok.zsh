#!/usr/bin/env zsh

set -euo pipefail

declare -rgx _me=`realpath -e $0`

function _mepath {
  realpath -e "$_me" --relative-to=`pwd`
}

declare -rgx _medir=`realpath -e "$(dirname "$(_mepath)")"`

function _initialize-rundir {
  cd "$_medir"
}

function _declare-globals {
  declare -rgx _build_rev=`./build-aux/structured-version-gen --quiet --base-version spack -v2r p --require-routed 2>>(grep -vF 'is ambiguous' >&2)`
  declare -rgx _build_type="${CMAKE_BUILD_TYPE:-Release}"
  declare -rgx _py_ver="${PY_VER:-3.14}"

  declare -rgx _cc=`which gcc`
  declare -rgx _cxx=`which g++`
  declare -rgx _ld=`which ld.bfd`
  declare -rgx _ar=`which gcc-ar`
  declare -rgx _ranlib=`which gcc-ranlib`
  declare -rgx _nm=`which gcc-nm`
  declare -rgx _make=`which gmake`

  declare -rgx _build_dir="`pwd`/build"
  declare -rgx _install_dir="`pwd`/install"
  declare -rgx _py_install_dir="`pwd`/install/py/${_py_ver}"

  declare -rgx MAKE_JOBS="${MAKE_JOBS:-12}"
  declare -rgx MAKE_LOAD="${MAKE_LOAD:-14}"
}

function _clean {
  setopt local_options
  set -x
  rm -rf "$_py_install_dir"
  rm -rf "$_build_dir" "$_install_dir"
  if [[ -v DEINIT && -d .git/modules ]]; then
    git submodule deinit --all -f
    rm -rfv .git/modules/
  fi
  git clean -xfd
  if [[ -v RESET ]]; then
    git checkout -- .
  fi
}

function _prepare-build {
  setopt local_options
  set -x
  if [[ -v UPDATE ]]; then
    git submodule update --init --recursive
  fi
  find . -name CMakeLists.txt -type f \
    -execdir sed -i '/cmake_minimum_required/ s#(VERSION.*)#(VERSION 3.10)#' '{}' '+'
  mkdir -vp "$_build_dir" "$_install_dir" "$_py_install_dir"
}

declare -ra opt_flags=(
  -march=native
  -O3
  -pipe
)
declare -ra lto_flags=(
  -flto=auto
  -flto-partition=balanced
  -fuse-linker-plugin
  -fno-fat-lto-objects
)
declare -ra warning_flags=(
  -Wno-deprecated-declarations
  -Wno-error
)
declare -ra ld_flags=(
  -flto=auto
  -flto-partition=balanced
)

function _configure-build {
  setopt local_options
  set -x
  pushd "$_build_dir" \
    && cmake -S.. \
      -DCLINGO_BUILD_WITH_PYTHON=ON -DCLINGO_BUILD_WITH_LUA=OFF -DCLINGO_BUILD_APPS=ON -DCLINGO_MANAGE_RPATH=ON \
      -DCLINGO_REQUIRE_PYTHON=ON -DCLINGO_BUILD_SHARED=ON -DCLINGO_BUILD_PY_SHARED=ON -DCLINGO_INSTALL_LIB=ON -DPYCLINGO_USE_CFFI=OFF -DPYCLINGO_DYNAMIC_LOOKUP=OFF \
      -DCLINGO_BUILD_REVISION="$_build_rev" \
      -DCLINGO_PYTHON_VERSION":LIST=${_py_ver};EXACT" \
      -DCMAKE_C_COMPILER:FILEPATH="$_cc" -DCMAKE_CXX_COMPILER:FILEPATH="$_cxx" \
      -D{CLINGO_,}CMAKE_AR:FILEPATH="$_ar" -D{CLINGO_,}CMAKE_RANLIB:FILEPATH="$_ranlib" \
      -DCMAKE_LINKER:FILEPATH="$_ld" \
      -DCMAKE_NM:FILEPATH="$_nm" \
      -DCMAKE_MAKE_PROGRAM:FILEPATH="$_make" \
      -DCMAKE_BUILD_TYPE="$_build_type" \
      -DCMAKE_INSTALL_PREFIX="$_install_dir" -DPYCLINGO_INSTALL_DIR="$_py_install_dir" \
      -DCMAKE_C_FLAGS="${(j: :)opt_flags[@]} ${(j: :)lto_flags[@]} ${(j: :)warning_flags[@]}" \
      -DCMAKE_CXX_FLAGS="${(j: :)opt_flags[@]} ${(j: :)lto_flags[@]} ${(j: :)warning_flags[@]}" \
      -DCMAKE_EXE_LINKER_FLAGS="${(j: :)ld_flags[@]}" \
      -DCMAKE_SHARED_LINKER_FLAGS="${(j: :)ld_flags[@]}" \
      -DCMAKE_STATIC_LINKER_FLAGS="${(j: :)ld_flags[@]}" \
      -DCMAKE_MODULE_LINKER_FLAGS="${(j: :)ld_flags[@]}" \
    && popd
}

function _make {
  pushd "$_build_dir" \
    && make "-j${MAKE_JOBS}" "-l${MAKE_LOAD}" "$@" \
    && popd
}

function warning-stream {
  cat >&2
}

function warn {
  printf '%s\n' "$@" | warning-stream
}

function die {
  warn "$@"
  exit "${RC:-1}"
}

function help {
  local -r qq=`printf '%q' "$(_mepath)"`
  cat <<EOF
Usage: ${qq} [clean|setup|configure|build|install]
EOF
  if [[ -v MORE ]]; then
    cat <<EOF

- The form 'RESET=y ${qq} clean' will additionally perform a 'git checkout -- .'.
- The form 'DEINIT=y ${qq} clean' will additionally hard remove git submodules
  (including from .git/modules!!!).
Be careful!

- The form 'UPDATE=y ${qq} setup' will additionall perform a 'git submodule update --init --recursive'.
EOF
  fi
}

if [[ $# -eq 0 ]]; then
  help | warning-stream
  exit 1
elif [[ $# -gt 1 ]]; then
  help | warning-stream
  RC=2 die "too many args ($#)"
elif [[ $1 = '-h' || $1 = '--help' ]]; then
  MORE=y help
  exit 0
fi

_initialize-rundir
_declare-globals

case "$1" in
  clean)
    _clean
    ;;
  setup)
    _prepare-build
    ;;
  configure)
    _configure-build
    ;;
  build)
    _make
    ;;
  install)
    _make install
    ;;
  *)
    help | warning-stream
    RC=3 die "unrecognized argument: ${1}"
    ;;
esac
exit 0
