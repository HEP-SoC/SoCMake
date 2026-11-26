#[[[ @module socmake_ctest_parallel_level
#]]

include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/socmake_message.cmake")

#[[[
# Number of tests a ``check`` target runs in parallel.
#
# :param OUTVAR: variable set in the caller's scope.
# :type OUTVAR: string
# :param PARALLEL_LEVEL: value given by the caller, used if not empty.
# :type PARALLEL_LEVEL: string
#
# Otherwise uses the ``CTEST_PARALLEL_LEVEL`` environment variable (read when
# cmake configures), else the number of host CPUs (``ProcessorCount()``),
# else 1. A value of ``0`` is replaced by ``1``. A value that is not a
# non-negative integer is a fatal error.
#]]
function(socmake_ctest_parallel_level OUTVAR PARALLEL_LEVEL)
    if(NOT "${PARALLEL_LEVEL}" STREQUAL "")
        set(level "${PARALLEL_LEVEL}")
    elseif(NOT "$ENV{CTEST_PARALLEL_LEVEL}" STREQUAL "")
        set(level "$ENV{CTEST_PARALLEL_LEVEL}")
    else()
        include(ProcessorCount)
        ProcessorCount(level)
    endif()
    if(NOT level MATCHES "^[0-9]+$")
        socmake_message(FATAL_ERROR "Invalid ctest parallel level: '${level}'")
    endif()
    if(level EQUAL 0)
        set(level 1)
    endif()
    set(${OUTVAR} ${level} PARENT_SCOPE)
endfunction()
