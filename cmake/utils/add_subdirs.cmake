# Does not work for ../ TODO
macro(add_subdirs)
    foreach(dir ${ARGN})
        add_subdirectory(${dir} ${dir})
    endforeach()
endmacro()
