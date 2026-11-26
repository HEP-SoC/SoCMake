# Checks the optimization flags used to compile a verilated model.
#
# Run with cmake -P once the model is built. The verilator() ExternalProject must be configured
# with CMAKE_EXPORT_COMPILE_COMMANDS so that its compile_commands.json is available.
#
# The sources of the model are split into the groups of the Verilator generated
# <DIRECTORY>/verilate/<PREFIX>.cmake file:
#   FAST:   <PREFIX>_CLASSES_FAST and <PREFIX>_SUPPORT_FAST (code running on every evaluation)
#   SLOW:   <PREFIX>_CLASSES_SLOW and <PREFIX>_SUPPORT_SLOW (code running rarely)
#   GLOBAL: <PREFIX>_GLOBAL (Verilator runtime library)
# For each source of a group, the effective optimization option (the last -O option of its
# compile command) must be the expected one.
#
# -DDIRECTORY=<dir>     verilator() ExternalProject build directory
# -DPREFIX=<prefix>     Verilator prefix of the model (default: Vtb)
# -DFAST=<opt>          expected optimization option of the FAST sources, "none" for no -O option
# -DSLOW=<opt>          expected optimization option of the SLOW sources, "none" for no -O option
# -DGLOBAL=<opt>        expected optimization option of the GLOBAL sources, "none" for no -O option

if(NOT PREFIX)
    set(PREFIX Vtb)
endif()
foreach(group FAST SLOW GLOBAL)
    if(NOT ${group})
        message(FATAL_ERROR "FAIL: -D${group}=<opt> is not given")
    endif()
endforeach()

set(compile_db "${DIRECTORY}/compile_commands.json")
set(verilator_cmake "${DIRECTORY}/verilate/${PREFIX}.cmake")
foreach(file ${compile_db} ${verilator_cmake})
    if(NOT EXISTS ${file})
        message(FATAL_ERROR "FAIL: ${file} not found, is the model built?")
    endif()
endforeach()

# Sources of each group, as listed by Verilator
include(${verilator_cmake})
set(sources_FAST ${${PREFIX}_CLASSES_FAST} ${${PREFIX}_SUPPORT_FAST})
set(sources_SLOW ${${PREFIX}_CLASSES_SLOW} ${${PREFIX}_SUPPORT_SLOW})
set(sources_GLOBAL ${${PREFIX}_GLOBAL})

# Compile command of each source, indexed by the hash of its real path
file(READ ${compile_db} db)
string(JSON n_entries LENGTH "${db}")
math(EXPR last "${n_entries} - 1")
foreach(i RANGE ${last})
    string(JSON src GET "${db}" ${i} file)
    string(JSON cmd GET "${db}" ${i} command)
    file(REAL_PATH "${src}" src)
    string(MD5 key "${src}")
    set(command_${key} "${cmd}")
endforeach()

set(errors 0)
foreach(group FAST SLOW GLOBAL)
    if(NOT sources_${group})
        continue()
    endif()
    foreach(src ${sources_${group}})
        file(REAL_PATH "${src}" src)
        get_filename_component(name ${src} NAME)
        string(MD5 key "${src}")
        if(NOT DEFINED command_${key})
            message(
                SEND_ERROR
                "FAIL: ${group} ${name}: no compile command found"
            )
            math(EXPR errors "${errors} + 1")
            continue()
        endif()

        # The compiler uses the last -O option of the command line
        string(REGEX MATCHALL "(^| )-O[^ ]*" opts "${command_${key}}")
        if(opts)
            list(GET opts -1 used)
            string(STRIP "${used}" used)
        else()
            set(used none)
        endif()

        if(used STREQUAL "${${group}}")
            message(STATUS "OK: ${group} ${name}: ${used}")
        else()
            message(
                SEND_ERROR
                "FAIL: ${group} ${name}: ${used} is used, expected ${${group}}"
            )
            math(EXPR errors "${errors} + 1")
        endif()
    endforeach()
endforeach()

if(errors EQUAL 0)
    message(STATUS "PASS: verilated model compiler flags")
endif()
