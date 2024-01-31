
cmake_minimum_required(VERSION 3.25)
project(SoCMake LANGUAGES NONE)

include(${CMAKE_CURRENT_LIST_DIR}/SoCMakeConfig.cmake)

option(SOCMAKE_BUILD_TESTING "Enable SoCMake unit testing" OFF)

if("${SOCMAKE_BUILD_TESTING}")
    include(CTest)
    add_subdirectory(tests)
endif()
