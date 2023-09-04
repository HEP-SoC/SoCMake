set(CPM_DOWNLOAD_VERSION 0.38.1)
include(${CMAKE_CURRENT_LIST_DIR}/CPM.cmake)

CPMAddPackage(
    NAME SoCMake
    GIT_TAG master
    GIT_REPOSITORY "ssh://git@gitlab.cern.ch:7999/socmake/SoCMake.git"
    )
