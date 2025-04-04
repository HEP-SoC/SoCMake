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
