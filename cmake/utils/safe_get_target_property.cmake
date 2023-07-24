include_guard(GLOBAL)

function(safe_get_target_property OUT_VAR TARGET PROPERTY WARNING_LEVEL)
    get_target_property(TMP_VAR ${TARGET} ${PROPERTY})
    if(TMP_VAR STREQUAL "TMP_VAR-NOTFOUND")
        if(WARNING_LEVEL STREQUAL "FATAL")
            message(FATAL_ERROR "${PROPERTY} for target ${lib} is not defined")
        elseif(WARNING_LEVEL STREQUAL "WARNING")
            message(WARNING "${PROPERTY} for target ${lib} is not defined")
            set(TMP_VAR "")
        elseif(WARNING_LEVEL STREQUAL "")
            set(TMP_VAR "")
        elseif(WARNING_LEVEL STREQUAL "KEEP_NO_FOUND")
            set(TMP_VAR ${OUT_VAR}-NOTFOUND)
        endif()
    endif()

    set(${OUT_VAR} ${TMP_VAR} PARENT_SCOPE)
endfunction()

function(get_interface_sources OUT_VAR TARGET)
    safe_get_target_property(srcs ${TARGET} SOURCES "")
    safe_get_target_property(isrcs ${TARGET} INTERFACE_SOURCES "")
    list(PREPEND srcs ${isrcs})
    list(REMOVE_DUPLICATES srcs)

    set(${OUT_VAR} ${srcs} PARENT_SCOPE)
endfunction()




