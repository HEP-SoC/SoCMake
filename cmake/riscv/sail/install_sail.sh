#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

DEFAULT_OPAM_VERSION="2.1.5"
DEFAULT_OCAML_VERSION="4.08.0"
DEFAULT_SAIL_VERSION="0.15"
DEFAULT_RISCV_SAIL_VERSION="58cac61"
DEFAULT_PREFIX=${SCRIPT_DIR}/sail_install
DEFAULT_BUILD_DIR=${SCRIPT_DIR}

print_help() {
    echo "Usage: $0 [--opam-version <version>] [--ocaml-version <version>] [--riscv-sail-version <version>] [--prefix <path>] [--build-dir <dir>]"
    echo "Options:"
    echo "  --opam-version     Set the OPAM version (default: $DEFAULT_OPAM_VERSION)"
    echo "  --ocaml-version    Set the OCaml version (default: $DEFAULT_OCAML_VERSION)"
    echo "  --sail-version     Set the sail version (default: $DEFAULT_SAIL_VERSION)"
    echo "  --riscv-sail-version     Set the sail-riscv.git version (default: $DEFAULT_RISCV_SAIL_VERSION)"
    echo "  --disable-sandboxing     Use --disable-sandboxing in opam init, useful for docker (default: false"
    echo "  --prefix           Set the installation prefix (default: $DEFAULT_PREFIX)"
    echo "  --build-dir        Set the build directory (default: $DEFAULT_BUILD_DIR)"
    exit 1
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --opam-version)
            OPAM_VERSION="$2"
            shift
            shift
            ;;
        --ocaml-version)
            OCAML_VERSION="$2"
            shift
            shift
            ;;
        --sail-version)
            SAIL_VERSION="$2"
            shift
            shift
            ;;
        --riscv-sail-version)
            RISCV_SAIL_VERSION="$2"
            shift
            shift
            ;;
        --disable-sandboxing)
            DISABLE_SANDBOXING="true"
            shift
            ;;
        --prefix)
            PREFIX="$2"
            shift
            shift
            ;;
        --build-dir)
            BUILD_DIR="$2"
            shift
            shift
            ;;
        *)
            print_help
            ;;
    esac
done

OPAM_VERSION="${OPAM_VERSION:-$DEFAULT_OPAM_VERSION}"
OCAML_VERSION="${OCAML_VERSION:-$DEFAULT_OCAML_VERSION}"
RISCV_SAIL_VERSION="${RISCV_SAIL_VERSION:-$DEFAULT_RISCV_SAIL_VERSION}"
SAIL_VERSION="${SAIL_VERSION:-$DEFAULT_SAIL_VERSION}"
PREFIX="${PREFIX:-$DEFAULT_PREFIX}"
BUILD_DIR="${BUILD_DIR:-$DEFAULT_BUILD_DIR}"

if [ "$DISABLE_SANDBOXING" = "true" ]; then
    SANDBOX_ARGUMENT="--disable-sandboxing"
else
    SANDBOX_ARGUMENT=""
fi

echo "Setting up OPAM version $OPAM_VERSION, OCaml version $OCAML_VERSION, sail-riscv.git version $RISCV_SAIL_VERSION,"
echo "installation prefix: $PREFIX, and build directory: $BUILD_DIR..."

# Rest of the script remains the same
OS=linux
HOST_ARCH=$(uname -m)
OPAMROOT=${BUILD_DIR}/opam_install

mkdir -p ${BUILD_DIR}

wget -P ${BUILD_DIR} https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/opam-${OPAM_VERSION}-${HOST_ARCH}-${OS}
chmod +x ${BUILD_DIR}/opam-${OPAM_VERSION}-${HOST_ARCH}-${OS}
mv ${BUILD_DIR}/opam-${OPAM_VERSION}-${HOST_ARCH}-${OS} ${BUILD_DIR}/opam

export PATH=${BUILD_DIR}:$PATH
export PATH=${BUILD_DIR}/opam_install/${OCAML_VERSION}/bin:$PATH
export PATH=${OPAMROOT}/${OCAML_VERSION}/bin:$PATH

opam init --no ${SANDBOX_ARGUMENT} --root ${OPAMROOT}
eval $(opam env --root=${OPAMROOT} --switch=default)

opam switch --root ${OPAMROOT} create ${OCAML_VERSION}
eval $(opam env --root=${OPAMROOT} --switch=default)

opam pin add --yes --root ${OPAMROOT} sail ${SAIL_VERSION}

git clone https://github.com/riscv/sail-riscv.git ${BUILD_DIR}/sail-riscv
cd ${BUILD_DIR}/sail-riscv
git checkout ${RISCV_SAIL_VERSION}
PATH=${BUILD_DIR}:$PATH OPAMROOT=${OPAMROOT} ARCH=RV32 make csim -j$(nproc)

mkdir -p ${PREFIX}/riscv-sail/bin
cp ${BUILD_DIR}/sail-riscv/c_emulator/riscv_sim_RV32 ${PREFIX}/riscv-sail/bin

echo "Setup complete."
