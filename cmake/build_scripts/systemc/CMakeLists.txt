cmake_minimum_required(VERSION 3.25)
project(systemc_build)

include("../../utils/option.cmake")

set(SYSTEMC_VERSIONS 3.0.0 2.3.4 2.3.3 2.3.2 2.3.1a 2.3.0a)
option_enum(VERSION "Version of SystemC to build" "${SYSTEMC_VERSIONS}" "3.0.0")
option_enum(CMAKE_CXX_STANDARD "C++ Standard" "98;11;14;17;20;23;26" "17")

include(GNUInstallDirs)
include(ExternalProject)

ExternalProject_Add(systemc
        URL https://github.com/accellera-official/systemc/archive/refs/tags/${VERSION}.tar.gz
        PREFIX ${PROJECT_BINARY_DIR}
        INSTALL_DIR ${PREFIX}
        CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
            -DCMAKE_INSTALL_LIBDIR=${CMAKE_INSTALL_LIBDIR}
            -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}
            -DENABLE_PHASE_CALLBACKS_TRACING=OFF
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
        )
