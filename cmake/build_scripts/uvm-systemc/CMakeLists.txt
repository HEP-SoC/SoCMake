cmake_minimum_required(VERSION 3.25)
project(uvm-systemc_build)

include("../../utils/option.cmake")

set(UVM-SYSTEMC_VERSIONS 1.0-beta6 1.0-beta5 1.0-beta3 1.0-beta1 1.0-alpha1)
option_enum(VERSION "Version of UVM-SystemC to build" "${UVM-SYSTEMC_VERSIONS}" "1.0-beta6")
option_enum(CMAKE_CXX_STANDARD "C++ Standard" "98;11;14;17;20;23;26" "17")
option_string(SYSTEMC_HOME "SystemC install directory" " ")

if(SYSTEMC_HOME STREQUAL " ")
    message(FATAL_ERROR "Please specify SYSTEMC_HOME variable")
endif()


include(GNUInstallDirs)
include(ExternalProject)

# UVM-SystemC configure script is searching SystemC library in lib${LIB_ARCH_SUFFIX},
# while SystemC install lib folder depends on CMAKE_INSTALL_LIBDIR which is set to
# lib or lib64 according to GNUInstallDirs
set(SYSTEMC_INSTALL_LIBDIR ${CMAKE_INSTALL_LIBDIR})
if(NOT SYSTEMC_INSTALL_LIBDIR MATCHES "^lib")
    message(FATAL_ERROR "SYSTEMC_INSTALL_LIBDIR (${SYSTEMC_INSTALL_LIBDIR}) does not start with 'lib'")
endif()
string(REGEX REPLACE "^lib" "" LIB_ARCH_SUFFIX "${SYSTEMC_INSTALL_LIBDIR}")

ExternalProject_Add(uvm-systemc
        URL https://www.accellera.org/images/downloads/drafts-review/uvm-systemc-${VERSION}.tar.gz
        PREFIX ${PROJECT_BINARY_DIR}
        INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
        CONFIGURE_COMMAND autoreconf -fiv <SOURCE_DIR> &&
                          <SOURCE_DIR>/configure
                              CC=${CMAKE_C_COMPILER}
                              CXX=${CMAKE_CXX_COMPILER}
                              CXXFLAGS=-std=c++${CMAKE_CXX_STANDARD}
                              --with-systemc=${SYSTEMC_HOME}
                              --with-arch-suffix=${LIB_ARCH_SUFFIX}
                              --prefix=${CMAKE_INSTALL_PREFIX}
        )


file(MAKE_DIRECTORY "${CMAKE_INSTALL_PREFIX}/include")
set(libdir "lib${LIB_ARCH_SUFFIX}")

add_library(uvm-systemc_shared INTERFACE)
target_link_libraries(uvm-systemc_shared INTERFACE "${CMAKE_INSTALL_PREFIX}/${libdir}/libuvm-systemc.so")
target_include_directories(uvm-systemc_shared INTERFACE "${CMAKE_INSTALL_PREFIX}/include")
set_property(TARGET uvm-systemc_shared PROPERTY EXPORT_NAME shared)

add_library(uvm-systemc_static INTERFACE)
target_link_libraries(uvm-systemc_static INTERFACE "${CMAKE_INSTALL_PREFIX}/${libdir}/libuvm-systemc.a")
target_include_directories(uvm-systemc_static INTERFACE "${CMAKE_INSTALL_PREFIX}/include")
set_property(TARGET uvm-systemc_static PROPERTY EXPORT_NAME static)

install(TARGETS uvm-systemc_shared uvm-systemc_static
    EXPORT UVM-SystemCTargets
    FILE_SET HEADERS
    LIBRARY DESTINATION ${libdir}
    ARCHIVE DESTINATION ${libdir}
    RUNTIME DESTINATION bin
    )

include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "UVM-SystemCConfigVersion.cmake"
    VERSION ${VERSION}
    COMPATIBILITY AnyNewerVersion)

install(EXPORT UVM-SystemCTargets
    FILE UVM-SystemCTargets.cmake
    NAMESPACE UVM-SystemC::
    DESTINATION ${CMAKE_INSTALL_PREFIX}/${libdir}/cmake/UVM-SystemC)

install(FILES "UVM-SystemCConfig.cmake" "${CMAKE_CURRENT_BINARY_DIR}/UVM-SystemCConfigVersion.cmake"
    DESTINATION ${CMAKE_INSTALL_PREFIX}/${libdir}/cmake/UVM-SystemC)
