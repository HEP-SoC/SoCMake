include_guard(GLOBAL)

function(verible_obfuscate IP_LIB)
    cmake_parse_arguments(ARG "NO_DEPS" "OUTDIR" "FILE_SETS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    if(ARG_FILE_SETS)
        set(FILE_SETS_FUNC_ARG FILE_SETS ${ARG_FILE_SETS})
    endif()

    if(ARG_NO_DEPS)
        set(ips ${IP_LIB})
    else()
        get_ip_links(ips ${IP_LIB})
    endif()

    unset(all_gen_files)
    foreach(ip IN LISTS ips)
        get_property(filesets TARGET ${ip} PROPERTY LANG_FILE_SETS)

        set(languages VERILOG SYSTEMVERILOG)

        foreach(fileset IN LISTS filesets)
            string(REPLACE "::" ";" fileset_list "${fileset}")
            list(GET fileset_list 0 fileset_language)
            list(GET fileset_list 1 fileset_name)
            if(fileset_language IN_LIST languages)
                get_ip_sources(sources ${ip} ${fileset_language} FILE_SETS ${fileset_name} NO_DEPS)
                unset(replace_sources)
                foreach(source ${sources})
                    cmake_path(GET source FILENAME source_fn)
                    set(source_new "${OUTDIR}/${source_fn}")

                    list(APPEND replace_sources "${source_new}")

                    add_custom_command(
                        OUTPUT ${source_new}
                        COMMAND verible-verilog-obfuscate < ${source} > ${source_new}
                        DEPENDS ${source}
                        COMMENT "Obfuscate ${source_fn} of ${IP_LIB} with Verible"
                        )
                    list(APPEND all_gen_files ${source_new})
                endforeach()
                ip_sources(${ip} ${fileset_language} FILE_SET ${fileset_name} REPLACE "${replace_sources}")

            endif()
        endforeach()
    endforeach()

    
    set(DESCRIPTION "Obfuscating Verilog/SV files of ${IP_LIB} with Verible obfuscate")
    add_custom_target(${IP_LIB}_verible_obfuscate
        DEPENDS ${all_gen_files}
    )
    set_property(TARGET ${IP_LIB}_verible_obfuscate PROPERTY DESCRIPTION ${DESCRIPTION})

endfunction()

