include_guard(GLOBAL)

macro(find_python3)
    if(NOT Python3_EXECUTABLE)
        find_package (Python3 COMPONENTS Interpreter Development)
    endif()
endmacro()
