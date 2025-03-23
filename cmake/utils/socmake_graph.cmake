include_guard(GLOBAL)

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

    # Workaround a mechanism described in (https://cmake.org/cmake/help/v3.30/prop_tgt/INTERFACE_LINK_LIBRARIES.html)
    list(FILTER LINK_LIBS EXCLUDE REGEX "::@")

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
    # Workaround a mechanism described in (https://cmake.org/cmake/help/v3.30/prop_tgt/INTERFACE_LINK_LIBRARIES.html)
    list(FILTER LINK_LIBS EXCLUDE REGEX "::@")

    compare_lists("${RM_LIST}" "${LINK_LIBS}" L_EQ)
    set(${RET} ${L_EQ} PARENT_SCOPE)
endfunction()



