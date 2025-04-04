set(CPM_DOWNLOAD_VERSION 0.40.2)             # Define CPM version to be downloaded
include(${CMAKE_CURRENT_LIST_DIR}/CPM.cmake) # Include the CPM.cmake downloader

CPMAddPackage(              # Add SoCMake as a package
    NAME SoCMake
    GIT_TAG v0.3.0          # You can define GIT_TAG or VERSION for versioning
    GIT_REPOSITORY "https://github.com/HEP-SoC/SoCMake.git"  # GIT_REPOSITORY or URL
    )
