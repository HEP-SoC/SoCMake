include_guard(GLOBAL)

function(safe_get_target_property OUT_VAR TARGET PROPERTY)
    get_target_property(TMP_VAR ${TARGET} ${PROPERTY})
    if(NOT TMP_VAR)
        set(TMP_VAR "")
    endif()
    set(${OUT_VAR} ${TMP_VAR} PARENT_SCOPE)
endfunction()
