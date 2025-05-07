cmake_minimum_required(VERSION 3.25)
project(verilator_build)

include("../../utils/option.cmake")

set(VERILATOR_VERSIONS 5.012)
option_enum(VERSION "Version of Verilator to build" "${VERILATOR_VERSIONS}" "5.012")
# option_enum(CMAKE_CXX_STANDARD "C++ Standard" "98;11;14;17;20;23;26" "17")

include(GNUInstallDirs)
include(ExternalProject)

ExternalProject_Add(verilator
    URL https://github.com/verilator/verilator/archive/refs/tags/v${VERSION}.tar.gz
    PREFIX ${PROJECT_BINARY_DIR}/v${VERSION}
    BINARY_DIR ${PROJECT_BINARY_DIR}/v${VERSION}/build
    INSTALL_DIR ${PROJECT_BINARY_DIR}/v${VERSION}/install
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
        -DCMAKE_INSTALL_LIBDIR=${CMAKE_INSTALL_LIBDIR}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DCMAKE_BUILD_TYPE=Release
        -DPACKAGE_VERSION_NUMBER=${VERSION}
        BUILD_COMMAND ${CMAKE_COMMAND} --build . --config Release
        INSTALL_COMMAND ${CMAKE_COMMAND} --install . --prefix ${PROJECT_BINARY_DIR}/v${VERSION}/install
)

# cd verilator  # directory containing source files of verilator
# mkdir build
# cmake .. -DCMAKE_BUILD_TYPE=Release --install-prefix $PWD/../install
# cmake --build . --config Release
# cmake --install . --prefix $PWD/../install