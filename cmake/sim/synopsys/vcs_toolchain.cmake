set(CMAKE_LINKER ${VCS_HOME}/gnu/linux64/binutils-64/bin/ld)
set(CMAKE_C_COMPILER ${VCS_HOME}/gnu/linux64/gcc-64/bin/gcc)
set(CMAKE_CXX_COMPILER ${VCS_HOME}/gnu/linux64/gcc-64/bin/g++)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -L${VCS_HOME}/gnu/linux64/gcc-64/lib64/ ")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -L${VCS_HOME}/gnu/linux64/gcc-64/lib64/ ")


if(NOT TARGET vcs__libs)
    add_library(vcs__libs INTERFACE)
    add_library(vcs::libs ALIAS vcs__libs)

    target_include_directories(vcs__libs INTERFACE
        ${VCS_HOME}/etc/systemc/accellera_install/systemc233-gcc9/include
        ${VCS_HOME}/include/systemc233
        ${VCS_HOME}/include/scv-2.0
        ${VCS_HOME}/lib
        ${VCS_HOME}/include
        ${VCS_HOME}/include/cosim/bf
        )
endif()

find_program(VCS_EXECUTABLE vcs REQUIRED
    HINTS ${VCS_HOME} $ENV{VCS_HOME}
    )

set(CMAKE_SHARED_LIBRARY_RUNTIME_CXX_FLAG "-LDFLAGS -Wl,-rpath,")
set(CMAKE_CXX_LINK_EXECUTABLE "${VCS_EXECUTABLE} -full64 -nc -sysc=scv20 sc_main -timescale=1ns/1ps <OBJECTS> <CMAKE_CXX_LINK_FLAGS> <LINK_LIBRARIES> -o <TARGET>")

unset(CMAKE_CXX_COMPILER_WORKS CACHE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)

