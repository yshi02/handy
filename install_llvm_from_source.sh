#!/bin/bash

# record the path to the curent working directory
working_dir=$(pwd)

# default args
build_type="RelWithDebInfo"

# array for extra arguments
declare -a cmake_defines

# print help message then exit
help()
{
    echo ""
    echo "Usage: $0 -i install_dir -v version [-t build_type] [additional CMake defines]"
    echo -e "\t-i\t[REQUIRED] path to the directory to install LLVM"
    echo -e "\t  \t\tthis directory need not exist"
    echo -e "\t-v\t[REQUIRED] version of LLVM to install"
    echo -e "\t  \t\tthis should be in the format of x.x.x"
    echo -e "\t-t\t[OPTIONAL] LLVM build type (default: RelWithDebInfo)"
    echo -e "\t  \t\tthis can be one of {Release, Debug, RelWithDebInfo, MinSizeRel}"
    echo -e "\t  \t[OPTIONAL] all additional CMake defines should be in the key=val format seperated by space"
    echo -e "\t  \t\tsee https://llvm.org/docs/CMake.html#options-and-variables for available CMake variables"
    exit 1
}

# get commandline arguments
while getopts "i:v:t:" opt
do
    case "$opt" in
        i ) if [[ "$OPTARG" = /* ]]; then
                install_dir="$OPTARG"
            else
                install_dir="$working_dir/$OPTARG"
            fi;;
        v ) version="$OPTARG" ;;
        t ) build_type="$OPTARG" ;;
        ? ) help ;;
    esac
done

# shift off the options and optional --
shift $((OPTIND-1))
# any remaining arguments are treated as additional CMake defines
cmake_defines=("$@")

# print help if any of the required argument is missing
if [ -z "$install_dir" ] || [ -z "$version" ]
then
    echo "[$0] Some or all of the required arguments are missing";
    help
fi

# create the install directory
mkdir -p $install_dir

# try to download the LLVM project compressed tarball from GitHub
LLVM_SRC_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${version}/llvm-project-${version}.src.tar.xz"
echo "[$0] Downloading LLVM ${version} from ${LLVM_SRC_URL}"
wget -q $LLVM_SRC_URL
if [ $? -ne 0 ]; then
    echo "Failed to downlowd LLVM source from ${LLVM_SRC_URL}"
    exit 1
fi

# try to extract LLVM source from the downloaded tarball to the install dir
LLVM_SRC_TARBALL_PATH="${working_dir}/llvm-project-${version}.src.tar.xz"
LLVM_SRC_EXTRACT_PATH="${install_dir}/llvm-project-${version}.src"
echo "[$0] Extracting LLVM source from ${LLVM_SRC_TARBALL_PATH} to ${LLVM_SRC_EXTRACT_PATH}"
tar -xf $LLVM_SRC_TARBALL_PATH -C $install_dir
if [ $? -ne 0 ]; then
    echo "Failed to extract LLVM source from ${LLVM_SRC_TARBALL_PATH} to ${LLVM_SRC_EXTRACT_PATH}"
    exit 1
fi

# move to the install dir and build LLVM from source
LLVM_SRC_ROOT="${LLVM_SRC_EXTRACT_PATH}/llvm"
cd $install_dir
cmake_cmd=("cmake $LLVM_SRC_ROOT")
cmake_cmd+=(-D"CMAKE_BUILD_TYPE=${build_type}")
cmake_cmd+=(-D"CMAKE_INSTALL_PREFIX=${install_dir}")
for define in "${cmake_defines[@]}"; do
    cmake_cmd+=(-D"$define")
done
echo "[$0] Running ${cmake_cmd[@]}"
eval "${cmake_cmd[@]}"
echo "[$0] Building LLVM using $(nproc) threads"
cmake --build . -j `nproc`

# test LLVM build
echo "[$0] Checking LLVM build"
make check-all -j `nproc`

# install LLVM
echo "[$0] Installing LLVM to $install_dir"
cmake --build . --target install -j `nproc`

# create LLVM_ENV
touch LLVM_ENV
echo '#!/bin/bash' >> LLVM_ENV
echo "" >> LLVM_ENV
echo "LLVM_HOME=$(pwd)" >> LLVM_ENV
echo -e "PATH=\"\${LLVM_HOME}/bin:\$PATH\"" >> LLVM_ENV
echo -e "LD_LIBRARY_PATH=\"\${LLVM_HOME}/lib:\$LD_LIBRARY_PATH\"" >> LLVM_ENV
echo "[$0] Created LLVM_ENV at $(pwd)/LLVM_ENV, source it to use LLVM"

# cleanup
cd $working_dir
rm $LLVM_SRC_TARBALL_PATH
echo "[$0] Cleaned up $LLVM_SRC_TARBALL_PATH"

# done!
echo "[$0] LLVM ${version} installed at ${install_dir}"
echo "[$0] All done!"
