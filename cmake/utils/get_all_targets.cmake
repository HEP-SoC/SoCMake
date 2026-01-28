include_guard(GLOBAL)

function(get_all_targets OUTVAR)
    set(targets)
    __get_all_targets_recursive(targets ${CMAKE_CURRENT_SOURCE_DIR})
    set(${OUTVAR} ${targets} PARENT_SCOPE)
endfunction()

macro(__get_all_targets_recursive targets dir)
    get_property(subdirectories DIRECTORY ${dir} PROPERTY SUBDIRECTORIES)
    foreach(subdir ${subdirectories})
        __get_all_targets_recursive(${targets} ${subdir})
    endforeach()

    get_property(current_targets DIRECTORY ${dir} PROPERTY BUILDSYSTEM_TARGETS)
    list(APPEND ${targets} ${current_targets})
endmacro()


function(get_all_ips OUTVAR)
    get_all_targets(ALL_TARGETS)

    unset(targets)
    foreach(target ${ALL_TARGETS})
        get_target_property(ip_name ${target} IP_NAME)
        if(ip_name) # IP_NAME property is always set for SoCMakes IP library, to differentiate from INTERFACE_LIBRARIES
            list(APPEND targets ${target})
        endif()
    endforeach()

    set(${OUTVAR} ${targets} PARENT_SCOPE)
endfunction()
