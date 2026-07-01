#[[[ @module colours
#]]
include("${CMAKE_CURRENT_LIST_DIR}/socmake_message.cmake")

if(NOT WIN32)
    string(ASCII 27 Esc)
    set(ColourReset "${Esc}[m")
    set(ColourBold "${Esc}[1m")
    set(Red "${Esc}[31m")
    set(Green "${Esc}[32m")
    set(Yellow "${Esc}[33m")
    set(Blue "${Esc}[34m")
    set(Magenta "${Esc}[35m")
    set(Cyan "${Esc}[36m")
    set(White "${Esc}[37m")
    set(BoldRed "${Esc}[1;31m")
    set(BoldGreen "${Esc}[1;32m")
    set(BoldYellow "${Esc}[1;33m")
    set(BoldBlue "${Esc}[1;34m")
    set(BoldMagenta "${Esc}[1;35m")
    set(BoldCyan "${Esc}[1;36m")
    set(BoldWhite "${Esc}[1;37m")
endif()

set(__Colours
    Red
    Green
    Yellow
    Blue
    Magenta
    Cyan
    White
    BoldRed
    BoldGreen
    BoldYellow
    BoldBlue
    BoldMagenta
    BoldCyan
    BoldWhite
)

#[[[
# This function allows you to easily display a text in a colour.
#
# The available colors are the following:
#
# - Red
# - Green
# - Yellow
# - Blue
# - Magenta
# - Cyan
# - White
# - BoldRed
# - BoldGreen
# - BoldYellow
# - BoldBlue
# - BoldMagenta
# - BoldCyan
# - BoldWhite
#
# :param TEXT: Text to be displayed.
# :type TEXT: string
# :param COLOUR: Colour for the text to be displayed.
# :type COLOUR: string
#]]
function(msg TEXT COLOUR)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    socmake_message(STATUS "${${COLOUR}}${TEXT}${ColourReset}")
endfunction()
