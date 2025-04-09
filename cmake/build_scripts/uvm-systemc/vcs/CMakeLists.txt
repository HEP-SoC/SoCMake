cmake_minimum_required(VERSION 3.25)
project(uvm-systemc_build)

include("../../../utils/option.cmake")

set(UVM-SYSTEMC_VERSIONS 1.0-beta6 1.0-beta5 1.0-beta3 1.0-beta1 1.0-alpha1)
option_enum(VERSION "Version of UVM-SystemC to build" "${UVM-SYSTEMC_VERSIONS}" "1.0-beta6")
option_enum(CMAKE_CXX_STANDARD "C++ Standard" "98;11;14;17;20;23;26" "11")
option_string(SYSTEMC_HOME "SystemC install directory" " ")

if(SYSTEMC_HOME STREQUAL " ")
    message(FATAL_ERROR "Please specify SYSTEMC_HOME variable")
endif()


include(GNUInstallDirs)
include(ExternalProject)

include("../../../sim/synopsys/vcs.cmake")
__find_vcs_home(vcs_home)
set(libsystemc_vcs "${vcs_home}/linux64/lib/libsystemc232-gcc7-64.a")
set(SYSTEMC_HOME "${vcs_home}/include/systemc232")

ExternalProject_Add(uvm-systemc
        URL https://www.accellera.org/images/downloads/drafts-review/uvm-systemc-${VERSION}.tar.gz
        PREFIX ${PROJECT_BINARY_DIR}
        INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
        PATCH_COMMAND sed -i s|SYSTEMC_LIBS=.*|SYSTEMC_LIBS=\\\"${libsystemc_vcs}\\\"| "<SOURCE_DIR>/configure.ac" && 
                      sed -i s|SYSTEMC_INC_PREFIX=.*|SYSTEMC_INC_PREFIX=\\\"${SYSTEMC_HOME}\\\"| "<SOURCE_DIR>/configure.ac"

        CONFIGURE_COMMAND autoreconf -fiv <SOURCE_DIR> &&
                                    <SOURCE_DIR>/configure 
                                    "CC=${CMAKE_C_COMPILER}" 
                                    "CXX=${CMAKE_CXX_COMPILER}" 
                                    "CXXFLAGS=-std=c++${CMAKE_CXX_STANDARD}"
                                    # "LDFLAGS=-m32"
                                    "--with-systemc=${SYSTEMC_HOME}"
                                    "--with-arch-suffix=" 
                                    "--prefix=${CMAKE_INSTALL_PREFIX}"
        )


file(MAKE_DIRECTORY "${CMAKE_INSTALL_PREFIX}/include")

add_library(uvm-systemc_shared INTERFACE)
target_link_libraries(uvm-systemc_shared INTERFACE "${CMAKE_INSTALL_PREFIX}/lib/libuvm-systemc.so")
target_include_directories(uvm-systemc_shared INTERFACE "${CMAKE_INSTALL_PREFIX}/include")
set_property(TARGET uvm-systemc_shared PROPERTY EXPORT_NAME shared)

add_library(uvm-systemc_static INTERFACE)
target_link_libraries(uvm-systemc_static INTERFACE "${CMAKE_INSTALL_PREFIX}/lib/libuvm-systemc.a")
target_include_directories(uvm-systemc_static INTERFACE "${CMAKE_INSTALL_PREFIX}/include")
set_property(TARGET uvm-systemc_static PROPERTY EXPORT_NAME static)

install(TARGETS uvm-systemc_shared uvm-systemc_static
    EXPORT UVM-SystemCTargets
    FILE_SET HEADERS
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
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
    DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/cmake/UVM-SystemC)

install(FILES "${CMAKE_CURRENT_LIST_DIR}/UVM-SystemCConfig.cmake" "${CMAKE_CURRENT_BINARY_DIR}/UVM-SystemCConfigVersion.cmake"
    DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/cmake/UVM-SystemC)

