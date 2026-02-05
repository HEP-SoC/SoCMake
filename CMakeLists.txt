
cmake_minimum_required(VERSION 3.28)

# Version is set first to reuse it across the SoCMake project
# For example, docs/CMakeLists.txt includes this file to retrieve the version
# and build the documentation
set(SOCMAKE_VERSION 0.2.18)

project(SoCMake
        VERSION ${SOCMAKE_VERSION}
        DESCRIPTION "SoCMake building system to generate SoC platforms."
        LANGUAGES NONE
)

include(${CMAKE_CURRENT_LIST_DIR}/SoCMakeConfig.cmake)

# SoCMake build system testing
option(SOCMAKE_BUILD_TESTING "Enable SoCMake unit testing" OFF)

if("${SOCMAKE_BUILD_TESTING}")
    include(CTest)
    add_subdirectory(tests/tests)
endif()

# This is to prevent a warning
if(NOT PROJECT_IS_TOP_LEVEL)
    set(SOCMAKE_VERSION ${SOCMAKE_VERSION} PARENT_SCOPE)
endif()
