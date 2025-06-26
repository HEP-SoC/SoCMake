include_guard(GLOBAL)

function(make_outdir_path OUTVAR IP_LIB)
    alias_dereference(_reallib ${IP_LIB})
    string(REPLACE "__" "/" outpath "${_reallib}")

    set(${OUTVAR} ${outpath} PARENT_SCOPE)
endfunction()

function(ip_install IP_LIB)
    cmake_parse_arguments(ARG "" "" "LANGUAGES;FILE_SETS;EXCLUDE_FILE_SETS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    # Set properties to export
    set_property(TARGET ${IP_LIB} APPEND PROPERTY EXPORT_PROPERTIES DESCRIPTION)
    set_property(TARGET ${IP_LIB} APPEND PROPERTY EXPORT_PROPERTIES VENDOR)
    set_property(TARGET ${IP_LIB} APPEND PROPERTY EXPORT_PROPERTIES LIBRARY)
    set_property(TARGET ${IP_LIB} APPEND PROPERTY EXPORT_PROPERTIES IP_NAME)
    set_property(TARGET ${IP_LIB} APPEND PROPERTY EXPORT_PROPERTIES VERSION)

    set_property(TARGET ${IP_LIB} APPEND PROPERTY EXPORT_PROPERTIES LANG_FILE_SETS)
    get_property(export_sources TARGET ${IP_LIB} PROPERTY EXPORT_PROPERTIES)
    
    # Get file sets that were set on the IP block
    # This is a combination of {LANGUAGE}::{FILE_SET}
    get_property(filesets TARGET ${IP_LIB} PROPERTY LANG_FILE_SETS)

    # list(FILTER export_sources INCLUDE REGEX "(_SOURCES|_HEADERS|_INCLUDE_DIRECTORIES)$")

    make_outdir_path(OUTDIR ${IP_LIB})

    set(sources_list ${export_sources})
    list(FILTER sources_list INCLUDE REGEX "_SOURCES$")

    set(headers_list ${export_sources})
    list(FILTER headers_list INCLUDE REGEX "_HEADERS$")

    set(inc_dirs_list ${export_sources})
    list(FILTER inc_dirs_list INCLUDE REGEX "_INCLUDE_DIRECTORIES$")

    foreach(fileset ${filesets})
        string(REPLACE "::" ";" fileset_list "${fileset}")
        list(GET fileset_list 0 fileset_language)
        list(GET fileset_list 1 fileset_name)

        set(fileset_property ${fileset_language}_${fileset_name})
        set_property(TARGET ${IP_LIB} APPEND PROPERTY EXPORT_PROPERTIES ${fileset_property}_SOURCES)
        set_property(TARGET ${IP_LIB} APPEND PROPERTY EXPORT_PROPERTIES ${fileset_property}_HEADERS)
        set_property(TARGET ${IP_LIB} APPEND PROPERTY EXPORT_PROPERTIES ${fileset_property}_INCLUDE_DIRECTORIES)
        set_property(TARGET ${IP_LIB} APPEND PROPERTY EXPORT_PROPERTIES ${fileset_property}_COMPILE_DEFINITIONS)
        # string(REGEX REPLACE "_SOURCES$" "" fileset ${fileset})
        # message("fileset is: ${fileset}")
        get_ip_sources(${fileset} ${IP_LIB} ${fileset_language} FILE_SETS ${fileset_name})

        unset(${fileset}_copy)
        foreach(source ${${fileset}})
            cmake_path(GET source FILENAME filename)
            list(APPEND ${fileset}_copy "\${_IMPORT_PREFIX}/${OUTDIR}/${fileset_language}/${fileset_name}/${filename}")
        endforeach()
        
        ip_sources(${IP_LIB} ${fileset_language} FILE_SET ${fileset_name} REPLACE
            ${${fileset}_copy}
            )

        install(FILES ${${fileset}}
            DESTINATION "${OUTDIR}/${fileset_language}/${fileset_name}"
            )
    endforeach()

    get_property(IP_NAME TARGET ${IP_LIB} PROPERTY IP_NAME)
    get_property(IP_VERSION TARGET ${IP_LIB} PROPERTY VERSION)
    set(VERSION_USED FALSE)
    if(NOT IP_VERSION)
        set(VERSION 0.0.1)
    else()
        set(VERSION ${IP_VERSION})
        set(VERSION_USED TRUE)
    endif()

    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
        "${PROJECT_BINARY_DIR}/${IP_NAME}ConfigVersion.cmake"
        VERSION ${VERSION}
        COMPATIBILITY AnyNewerVersion
    )

    install(TARGETS ${IP_LIB}
        EXPORT ${IP_NAME}Targets
    )

    include(CMakePackageConfigHelpers)
    configure_package_config_file(
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/ipConfig.cmake.in"
        "${PROJECT_BINARY_DIR}/${IP_NAME}Config.cmake"
        INSTALL_DESTINATION "${OUTDIR}/lib/cmake/${IP_NAME}"
    )

    install(EXPORT ${IP_NAME}Targets 
        DESTINATION "${OUTDIR}/lib/cmake/${IP_NAME}"
    )

    install(FILES "${PROJECT_BINARY_DIR}/${IP_NAME}ConfigVersion.cmake"
                  "${PROJECT_BINARY_DIR}/${IP_NAME}Config.cmake"
                  DESTINATION "${OUTDIR}/lib/cmake/${IP_NAME}"
        )

endfunction()
