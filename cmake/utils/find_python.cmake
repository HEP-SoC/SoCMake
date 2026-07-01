#[[[ @module find_python
#]]

include_guard(GLOBAL)

#[[[
# This function can be used to find a python3 interpreter and will set a variable, ``Python3_EXECUTABLE``, to be used in cmake file, to create command for example.
#]]
macro(find_python3)
    if(NOT DEFINED Python3_EXECUTABLE)
        find_package(Python3 COMPONENTS Interpreter REQUIRED)
        set(Python3_EXECUTABLE
            "${Python3_EXECUTABLE}"
            CACHE FILEPATH
            "Path to Python3 interpreter"
        )
    endif()
endmacro()
