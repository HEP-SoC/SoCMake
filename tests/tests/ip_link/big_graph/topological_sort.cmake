# Usage:
#   topological_sort(TARGETS <target> [<target> ...]
#                    PROPERTY_NAME <property>
#                    RESULT <out-variable>)
#
# This function performs topological sorting of CMake targets using a specific
# <property>, which dictates target dependencies. A fatal error occurs if the
# provided dependencies cannot be met, e.g., if they contain cycles.
#
# TARGETS:       List of target names.
# PROPERTY_NAME: Name of the target property to be used when sorting. For every
#                target listed in TARGETS, this property must contain a list
#                (possibly empty) of other targets, which this target depends on
#                for a particular purpose. The property must not contain any
#                target which is not also found in TARGETS.
# RESULT:        Output variable, where the topologically sorted list of target
#                names will be returned.
#
function(topological_sort)
  cmake_parse_arguments(TS "" "RESULT;PROPERTY_NAME" "TARGETS" ${ARGN})

  set(dep_targets)
  set(start_targets)
  set(sorted_targets)

  foreach(target ${TS_TARGETS})
    get_target_property(${target}_dependencies ${target} ${TS_PROPERTY_NAME})

    if(${target}_dependencies)
      list(APPEND dep_targets ${target})
    else()
      list(APPEND start_targets ${target})
    endif()
  endforeach()

  while(TRUE)
    list(POP_FRONT start_targets node)
    list(APPEND sorted_targets ${node})
    set(to_remove)
    foreach(target ${dep_targets})
      if("${node}" IN_LIST ${target}_dependencies)
        list(REMOVE_ITEM ${target}_dependencies ${node})
        if(NOT ${target}_dependencies)
          list(APPEND start_targets ${target})
          list(APPEND to_remove ${target})
        endif()
      endif()
    endforeach()

    foreach(target ${to_remove})
      list(REMOVE_ITEM dep_targets ${target})
    endforeach()
    if(NOT start_targets)
      break()
    endif()
  endwhile()

  if(dep_targets)
    foreach(target ${dep_targets})
      get_target_property(deps ${target} ${TS_PROPERTY_NAME})
      list(JOIN deps " " deps)
      list(APPEND dep_string "${target} depends on: ${deps}")
    endforeach()
    list(JOIN dep_string "\n" dep_string)
    message(FATAL_ERROR "Unmet or cyclic dependencies:\n${dep_string}")
  endif()

  set(${TS_RESULT} "${sorted_targets}" PARENT_SCOPE)
endfunction()


function(get_all_dependencies RESULT IP_LIB)
    __get_all_dependencies(${RESULT} ${IP_LIB})
    set(${RESULT} "${IP_LIB};${deps}" PARENT_SCOPE)
endfunction()

function(__get_all_dependencies RESULT IP_LIB)
    get_target_property(deps ${IP_LIB} INTERFACE_LINK_LIBRARIES)
    if(NOT deps)
        set(deps "")
    endif()
    foreach(dep ${deps})
        __get_all_dependencies(subdeps ${dep})
        list(APPEND deps ${subdeps})
    endforeach()

    set(${RESULT} "${deps}" PARENT_SCOPE)
endfunction()
