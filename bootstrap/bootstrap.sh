#!/bin/sh
set -e

# Configuration
# TODO change develop to a fixed TAG
SOCMAKE_VERSION="${SOCMAKE_VERSION:-develop}"
INSTALL_DIR="${HOME}/.local/lib/cmake/socmake"
REPO_URL="${SOCMAKE_REPO_URL:-https://raw.githubusercontent.com/HEP-SoC/SoCMake}"

echo "Installing SoCMake bootstrap files..."
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

echo "✓ SoCMake bootstrap installed successfully in ${INSTALL_DIR}"
echo ""
echo "----------------------------------------------------------------"
echo "                       Final STEPS                              "
echo "----------------------------------------------------------------"
echo "To allow CMake to find 'SoCMake', please add the following block"
echo "to your shell configuration file (e.g., ~/.bashrc or ~/.zshrc):"
echo ""
echo "\`\`\`"
echo "if [[ \":\$CMAKE_PREFIX_PATH:\" != *\":\$HOME/.local/lib/cmake:\"* ]]; then"
echo "    export CMAKE_PREFIX_PATH=\"\$HOME/.local/lib/cmake:\$CMAKE_PREFIX_PATH\""
echo "fi"
echo "\`\`\`"
echo ""
echo "Then, restart your terminal or run 'source ~/.bashrc'."
echo ""
echo "----------------------------------------------------------------"
echo ""
echo "To use SoCMake in your CMakeLists.txt add the following:"
echo "  find_package(socmake)"
echo ""
echo "----------------------------------------------------------------"
