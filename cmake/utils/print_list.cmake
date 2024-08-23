include_guard(GLOBAL)

macro(print_list LIST)
    foreach(item ${LIST})
        message(${item})
    endforeach()
endmacro()