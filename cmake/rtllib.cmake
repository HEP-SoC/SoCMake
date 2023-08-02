include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/utils/safe_get_target_property.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/hwip.cmake")

function(get_rtl_target_property OUT_VAR TARGET PROPERTY)

    if((${PROPERTY} STREQUAL SOURCES) OR (${PROPERTY} STREQUAL INTERFACE_SOURCES))
        message(WARNING "Use function get_rtl_target_sources(OUT_VAR TARGET) to get verilog sources")
    endif()

    flatten_graph(${TARGET})
    get_target_property(DEPS ${TARGET} FLAT_GRAPH)

    set(OUT_LIST "")
    foreach(d ${DEPS})
        safe_get_target_property(PROP ${d} ${PROPERTY} "")
        list(APPEND OUT_LIST ${PROP})
    endforeach()

    set(${OUT_VAR} ${OUT_LIST} PARENT_SCOPE)
endfunction()

# Sources get added to different properties depending if they are added with add_library(TARGET INTERFACE ...) or target_sources(TARGET INTERFACE ...)
function(get_rtl_target_sources OUT_VAR TARGET)
    flatten_graph(${TARGET})
    get_target_property(DEPS ${TARGET} FLAT_GRAPH)
    foreach(d ${DEPS})
        safe_get_target_property(INTERFACE_SOURCES ${d} INTERFACE_SOURCES "")
        safe_get_target_property(SOURCES ${d} SOURCES "")
        list(APPEND V_SOURCES ${SOURCES} ${INTERFACE_SOURCES})
    endforeach()

    set(${OUT_VAR} ${V_SOURCES} PARENT_SCOPE)
endfunction()

function(get_rtl_target_incdirs OUT_VAR TARGET)
    flatten_graph(${TARGET})
    get_target_property(DEPS ${TARGET} FLAT_GRAPH)
    foreach(d ${DEPS})
        safe_get_target_property(INTERFACE_INCLUDE_DIRECTORIES ${d} INTERFACE_INCLUDE_DIRECTORIES "")
        safe_get_target_property(INCLUDE_DIRECTORIES ${d} INCLUDE_DIRECTORIES "")
        list(APPEND INCDIRS ${INCLUDE_DIRECTORIES} ${INTERFACE_INCLUDE_DIRECTORIES})
    endforeach()

    set(${OUT_VAR} ${INCDIRS} PARENT_SCOPE)
endfunction()

# ========================================================== #
# ======== Print all RTL sources =========================== #
# ========================================================== #

function(print_rtl_sources RTLLIB)
    get_rtl_target_sources(SOURCES ${RTLLIB})
    message(STATUS "------------ RTL sources for ${RTLLIB}: ")
    foreach(source ${SOURCES})
        message(${source})
    endforeach()

endfunction()

# ========================================================== #
# ======== Internal graph flattening functions ============= #
# ========================================================== #

function(flatten_graph NODE)
    alias_dereference(NODE ${NODE}) # TODO provide set_property function that dereferences alias

    set_property(GLOBAL PROPERTY __GLOBAL_STACK "")
    set(FOUND_ROOT -1)
    while(FOUND_ROOT EQUAL -1)
        __flatten_graph_recursive(${NODE} FOUND_ROOT)
        list(FIND STACK ${NODE} FOUND_ROOT)
        get_property(STACK GLOBAL PROPERTY __GLOBAL_STACK)
    endwhile()

    foreach(lib ${STACK}) # CLear __RM_LIST
        alias_dereference(lib ${lib})
        set_property(TARGET ${lib} PROPERTY __RM_LIST "")
    endforeach()
    set_property(TARGET ${NODE} PROPERTY FLAT_GRAPH ${STACK})

endfunction()

function(__flatten_graph_recursive NODE RET)
    alias_dereference(NODE ${NODE})
    if(NOT TARGET ${NODE}) # If its not a target e.g. not interface library but maybe -pthread
        set(${RET} 1 PARENT_SCOPE)
        return()
    endif()
    __all_vertices_removed(${NODE} ALL_VERTICES_REMOVED)
    if(ALL_VERTICES_REMOVED EQUAL 1) # IF there is not DEPS on this node
        
        get_property(STACK GLOBAL PROPERTY __GLOBAL_STACK)
        list(FIND STACK ${NODE} ALREADY_ADDED)

        if(ALREADY_ADDED EQUAL -1)  # If the node is not in stack append it to stack
            list(APPEND STACK ${NODE})
            set_property(GLOBAL PROPERTY __GLOBAL_STACK ${STACK})
        endif()

        set(${RET} 1 PARENT_SCOPE)
        return()
    endif()

    get_target_property(LINK_LIBS ${NODE} INTERFACE_LINK_LIBRARIES)
    if(LINK_LIBS STREQUAL "LINK_LIBS-NOTFOUND") # Not needed
        set(LINK_LIBS "")
    endif()
    # message("LINK LIBS for lib: ${NODE} are: ${LINK_LIBS}")
    foreach(lib ${LINK_LIBS})
        __flatten_graph_recursive(${lib} LIB_ADDED)
        if(LIB_ADDED EQUAL 1)
            __append_rm_list_unique(${NODE} ${lib})
            get_target_property(_RM_LIST ${NODE} __RM_LIST )
        endif()
    endforeach()

    set(${RET} 0 PARENT_SCOPE)
endfunction()

function(__append_rm_list_unique NODE RM_EL) # Append if element not already in list
    alias_dereference(NODE ${NODE})
    get_target_property(RM_LIST ${NODE} __RM_LIST )

    list(FIND RM_LIST ${RM_EL} FOUND)
    if(FOUND EQUAL -1)
        set_property(TARGET ${NODE} APPEND PROPERTY __RM_LIST ${RM_EL})
    endif()
endfunction()

function(compare_lists L1 L2 RET)
    list(LENGTH L1 L1_LEN)
    list(LENGTH L2 L2_LEN)

    if(NOT (L1_LEN EQUAL L2_LEN))
        set(${RET} -1 PARENT_SCOPE)
        return()
    endif()

    foreach(el ${L1})
        list(FIND L2 ${el} FOUND)
        if(FOUND EQUAL -1)
            set(${RET} -1 PARENT_SCOPE)
            return()
        endif()
    endforeach()

    set(${RET} 1 PARENT_SCOPE)
endfunction()

function(__all_vertices_removed NODE RET)
    if(NOT TARGET ${NODE})
        message(FATAL_ERROR "Node is not defined ${NODE}")
    endif()
    get_target_property(RM_LIST ${NODE} __RM_LIST)
    get_target_property(LINK_LIBS ${NODE} INTERFACE_LINK_LIBRARIES)
    if(RM_LIST STREQUAL "RM_LIST-NOTFOUND")
        set(RM_LIST "")
    endif()
    if(LINK_LIBS STREQUAL "LINK_LIBS-NOTFOUND")
        set(LINK_LIBS "")
    endif()

    compare_lists("${RM_LIST}" "${LINK_LIBS}" L_EQ)
    set(${RET} ${L_EQ} PARENT_SCOPE)
endfunction()



