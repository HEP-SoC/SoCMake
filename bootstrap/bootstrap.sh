#!/bin/bash
set -e

# TODO We should fix this to a tag that we know contains these scripts
# These scripts should not change in the future, as there is no version information
SOCMAKE_VERSION="${SOCMAKE_VERSION:-bootstrap}"
INSTALL_DIR="${HOME}/.local/lib/cmake/socmake"
# TODO change this once merged to main repo
REPO_URL="${SOCMAKE_REPO_URL:-https://raw.githubusercontent.com/risto97/socmake}"

echo "Installing SoCmake bootstrap files..."
echo "  Git tag: ${SOCMAKE_VERSION}"
echo "  Install directory: ${INSTALL_DIR}"
echo "  Repository: ${REPO_URL}"

# Create installation directory
mkdir -p "${INSTALL_DIR}"

# Download bootstrap files
echo "Downloading bootstrap files..."
curl -fsSL "${REPO_URL}/${SOCMAKE_VERSION}/bootstrap/socmake-config.cmake" \
  -o "${INSTALL_DIR}/socmake-config.cmake"

curl -fsSL "${REPO_URL}/${SOCMAKE_VERSION}/bootstrap/socmake-config-version.cmake" \
  -o "${INSTALL_DIR}/socmake-config-version.cmake"

echo "✓ SoCmake bootstrap installed successfully! in ${INSTALL_DIR}"
echo ""
echo "To use in your CMakeLists.txt add the following:"
echo "  find_package(socmake)"
