set(CPM_DOWNLOAD_VERSION 0.40.2)
include(${CMAKE_CURRENT_LIST_DIR}/CPM.cmake)

CPMAddPackage(
    NAME SoCMake
    GIT_TAG master
    GIT_REPOSITORY "https://github.com/HEP-SoC/SoCMake.git"
    )
