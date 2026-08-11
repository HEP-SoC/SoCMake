# Since SoCMake is just a fetcher, any version is compatible
set(PACKAGE_VERSION_COMPATIBLE TRUE)
set(PACKAGE_VERSION_EXACT FALSE)

# If a specific version was requested, check if we can provide it
if(PACKAGE_FIND_VERSION)
    # We always fetch the exact version requested, so we're always compatible
    set(PACKAGE_VERSION "${PACKAGE_FIND_VERSION}")
    set(PACKAGE_VERSION_EXACT TRUE)
else()
    # No version requested, we're compatible
    set(PACKAGE_VERSION "0.0.0")
endif()

# We support all versions since we fetch on-demand
set(PACKAGE_VERSION_UNSUITABLE FALSE)
