#[[[
# Script mode helper for ``generate_sv_sources_list()``'s ``SPLIT_FILE_SETS`` support.
#
# Reads a slang-generated depfile (``RAW_FILE``, one path per line, dependency-ordered, paths possibly relative to
# ``BASE_DIR``) and classifies each line into either ``MAIN_OUT`` or ``SPLIT_OUT`` depending on whether it matches an
# entry in ``ALLOWLIST_FILE`` (one absolute path per line — the files belonging to the caller's ``SPLIT_FILE_SETS``).
#
# Both sides of the comparison are normalized with ``REALPATH`` (which also resolves symlinks) after resolving
# ``RAW_FILE``'s entries against ``BASE_DIR``, since slang's depfile output is written relative to its own process
# CWD regardless of whether it was given absolute paths on the command line, while SoCMake's ``get_ip_sources()`` /
# ``get_ip_include_directories()`` always return absolute paths. A plain string/``IN_LIST`` comparison between the
# two forms would never match.
#
# Expected variables (passed via ``-D``): RAW_FILE, ALLOWLIST_FILE, BASE_DIR, MAIN_OUT, SPLIT_OUT.
#]]

# Run via `cmake -P`, this script gets none of the calling project's policy settings (script mode always starts from
# CMake's compatibility defaults) — CMP0057 (IN_LIST as an if() operator) must be set explicitly rather than assumed.
cmake_minimum_required(VERSION 3.20)

foreach(_required_var RAW_FILE ALLOWLIST_FILE BASE_DIR MAIN_OUT SPLIT_OUT)
    if(NOT DEFINED ${_required_var})
        message(FATAL_ERROR "classify_sources_list.cmake requires ${_required_var} to be defined")
    endif()
endforeach()

# Build the REALPATH-normalized allow-list (the SPLIT_FILE_SETS members).
set(_allowlist_raw)
if(EXISTS "${ALLOWLIST_FILE}")
    file(STRINGS "${ALLOWLIST_FILE}" _allowlist_raw)
endif()
set(_allowed_realpaths)
foreach(_entry IN LISTS _allowlist_raw)
    if(NOT "${_entry}" STREQUAL "")
        get_filename_component(_entry_abs "${_entry}" REALPATH)
        list(APPEND _allowed_realpaths "${_entry_abs}")
    endif()
endforeach()

# Classify each line of the raw, slang-generated depfile.
set(_raw_lines)
if(EXISTS "${RAW_FILE}")
    file(STRINGS "${RAW_FILE}" _raw_lines)
endif()

file(WRITE "${MAIN_OUT}" "")
file(WRITE "${SPLIT_OUT}" "")

foreach(_line IN LISTS _raw_lines)
    if("${_line}" STREQUAL "")
        continue()
    endif()
    get_filename_component(_line_abs "${_line}" ABSOLUTE BASE_DIR "${BASE_DIR}")
    get_filename_component(_line_abs "${_line_abs}" REALPATH)
    if(_line_abs IN_LIST _allowed_realpaths)
        file(APPEND "${SPLIT_OUT}" "${_line}\n")
    else()
        file(APPEND "${MAIN_OUT}" "${_line}\n")
    endif()
endforeach()
