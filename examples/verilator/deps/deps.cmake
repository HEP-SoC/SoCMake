set(CPM_DOWNLOAD_VERSION 0.38.1)             # Define CPM version to be downloaded
include(${CMAKE_CURRENT_LIST_DIR}/CPM.cmake) # Include the CPM.cmake downloader

CPMAddPackage(              # Add SoCMake as a package
    NAME SoCMake
    GIT_TAG verilator_system_path         # You can define GIT_TAG or VERSION for versioning
    GIT_REPOSITORY "ssh://git@gitlab.cern.ch:7999/socmake/SoCMake.git"  # GIT_REPOSITORY or URL
    )
