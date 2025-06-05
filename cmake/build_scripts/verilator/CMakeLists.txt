cmake_minimum_required(VERSION 3.25)
project(verilator_build)

include("../../utils/option.cmake")

set(VERILATOR_VERSIONS 5.012 5.014 5.016 5.018 5.020 5.022 5.024)
option_enum(VERSION "Version of Verilator to build" "${VERILATOR_VERSIONS}" "5.012")
option_enum(CMAKE_CXX_STANDARD "C++ Standard" "98;11;14;17;20;23;26" "17")

include(GNUInstallDirs)
include(ExternalProject)

ExternalProject_Add(verilator-v${VERSION}
    URL https://github.com/verilator/verilator/archive/refs/tags/v${VERSION}.tar.gz
    PREFIX ${PROJECT_BINARY_DIR}
    INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
        -DCMAKE_INSTALL_LIBDIR=${CMAKE_INSTALL_LIBDIR}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_CXX_FLAGS="-pthread"
        -DPACKAGE_VERSION_NUMBER=${VERSION}
)
