#[[[ @module print_list
#]]

include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/socmake_message.cmake")

#[[[
# Macro to print all the item in a given list.
#
# :param LIST: list that need to be printed.
# :type LIST: list[string]
#]]
macro(print_list LIST)
    foreach(item ${LIST})
        socmake_message(STATUS ${item})
    endforeach()
endmacro()
