cmake_minimum_required(VERSION 3.28)
project(verisc)

set(DEPS "SYSTEMC;UVM-SYSTEMC;VERILATOR;FC4SC;ICSC_COMPILER;GCC")

foreach(dep ${DEPS})
    if(${dep}_VERSION)
        list(APPEND VERISC_CFG -D${dep}_VERSION=${${dep}_VERSION})
    endif()
endforeach()

include(ExternalProject)
ExternalProject_Add(verisc
    GIT_REPOSITORY https://github.com/Risto97/verisc.git
    GIT_TAG v${VERISC_VERSION}
    PREFIX ${VERISC_BUILD_DIR}
    INSTALL_DIR ${VERISC_INSTALL_DIR}

    CMAKE_ARGS
    -DCMAKE_INSTALL_PREFIX=${VERISC_INSTALL_DIR}
    ${VERISC_CFG}
    -DCMAKE_VERBOSE_MAKEFILE=TRUE
    )
set_target_properties(verisc PROPERTIES EXCLUDE_FROM_ALL TRUE)
