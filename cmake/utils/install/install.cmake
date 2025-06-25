include_guard(GLOBAL)

function(ip_install IP_LIB)
    message("+++++++++++++ INSTALLING  ${IP_LIB}")
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    alias_dereference(IP_LIB ${IP_LIB})
    set_property(TARGET ${IP_LIB} APPEND PROPERTY EXPORT_PROPERTIES FILE_SETS) # TODO don't add if already there

    ###################################
    ########## NEW WAY ################
    ###################################

    get_property(export_sources2 TARGET ${IP_LIB} PROPERTY FILE_SETS2)
    message("export_sources2: ${export_sources2}")

    foreach(fileset ${export_sources2})
        string(REPLACE "|" ";" fileset "${fileset}")
        list(GET fileset 0 language)
        list(GET fileset 1 fileset)

        # message("Language: ${language} Fileset: ${fileset}")

        set_property(TARGET ${IP_LIB} APPEND PROPERTY EXPORT_PROPERTIES ${language}_${fileset}_SOURCES) # TODO don't add if already there
        get_ip_sources(files ${IP_LIB} ${language} FILE_SETS ${fileset} NO_DEPS)
        # message("FILES: ${files}")

        unset(${language}_${fileset}_copy)
        foreach(source ${files})
            cmake_path(GET source FILENAME filename)
            list(APPEND ${language}_${fileset}_copy "\${_IMPORT_PREFIX}/${language}/${fileset}/${filename}")
            message("SOURCE: ${source} filename: ${filename}")
            message("    Replace with: \${_IMPORT_PREFIX}/${language}/${fileset}/${filename}")
        endforeach()

        ip_sources(${IP_LIB} ${language} FILE_SET ${fileset} REPLACE
            ${${language}_${fileset}_copy}
            )
        # message("REPLACE: ${language}_${fileset}_copy")
        # message("REPLACE: ${${language}_${fileset}_copy}")
        message("FILES: ${files}")

        install(FILES ${files}
            DESTINATION ${language}/${fileset})
    endforeach()

    get_property(export_sources TARGET ${IP_LIB} PROPERTY EXPORT_PROPERTIES)
    # message("export_source: ${export_sources}")
    # list(FILTER export_sources INCLUDE REGEX "(_SOURCES|_HEADERS|_INCLUDE_DIRECTORIES)$")


    ###################################
    ########## OLD WAY ################
    ###################################
    # set(sources_list ${export_sources})
    # list(FILTER sources_list INCLUDE REGEX "_SOURCES$")
    #
    # set(headers_list ${export_sources})
    # list(FILTER headers_list INCLUDE REGEX "_HEADERS$")
    #
    # set(inc_dirs_list ${export_sources})
    # list(FILTER inc_dirs_list INCLUDE REGEX "_INCLUDE_DIRECTORIES$")
    #
    # message("SOURCES_LIST: ${sources_list}")
    #
    # foreach(fileset ${sources_list})
    #     string(REGEX REPLACE "_SOURCES$" "" fileset ${fileset})
    #     message("fileset is: ${fileset}")
    #     # get_ip_sources(${fileset} ${IP_LIB} ${fileset})
    #     get_ip_property(${fileset} ${IP_LIB} ${fileset}_SOURCES NO_DEPS)
    #
    #     unset(${fileset}_copy)
    #     foreach(source ${${fileset}})
    #         cmake_path(GET source FILENAME filename)
    #         list(APPEND ${fileset}_copy "\${_IMPORT_PREFIX}/${fileset}/${filename}")
    #     endforeach()
    #     
    #     # ip_sources(${IP_LIB} ${fileset} REPLACE
    #     #     ${${fileset}_copy}
    #     #     )
    #
    #     set_property(TARGET ${IP_LIB} PROPERTY ${fileset}_SOURCES
    #         ${${fileset}_copy})
    #
    #     install(FILES ${${fileset}}
    #                   DESTINATION ${fileset}
    #         )
    #     # get_ip_sources(sources ${IP_LIB} ${fileset})
    # endforeach()
    ###################################
    ###################################
    ###################################

    get_property(IP_NAME TARGET ${IP_LIB} PROPERTY IP_NAME)
    get_property(IP_VERSION TARGET ${IP_LIB} PROPERTY VERSION)
    if(NOT IP_VERSION)
        set(VERSION 0.0.1)
    else()
        set(VERSION ${IP_VERSION})
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
        INSTALL_DESTINATION lib/cmake/${IP_NAME}
    )

    install(EXPORT ${IP_NAME}Targets 
        DESTINATION lib/cmake/${IP_NAME})

    install(FILES "${PROJECT_BINARY_DIR}/${IP_NAME}ConfigVersion.cmake"
                  "${PROJECT_BINARY_DIR}/${IP_NAME}Config.cmake"
                  DESTINATION lib/cmake/${IP_NAME}
        )

endfunction()
