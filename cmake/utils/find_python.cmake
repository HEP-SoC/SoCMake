include_guard(GLOBAL)

macro(find_python3)
    if(NOT DEFINED Python3_EXECUTABLE)
        find_package(Python3 COMPONENTS Interpreter REQUIRED)
        set(Python3_EXECUTABLE "${Python3_EXECUTABLE}" CACHE FILEPATH "Path to Python3 interpreter")
    endif()
endmacro()
