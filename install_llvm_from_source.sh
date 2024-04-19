#!/bin/bash

# default args
build_type="RelWithDebInfo"

# print help message then exit
help()
{
    echo ""
    echo "Usage: $0 -i install_dir -v version -t build_type"
    echo -e "\t-i\tREQUIRED path to the directory to install LLVM"
    echo -e "\t  \tthis directory need not exist"
    echo -e "\t-v\tREQUIRED version of LLVM to install"
    echo -e "\t  \tthis should be in the format of x.x.x"
    echo -e "\t-t\tOPTIONAL LLVM build type (default: RelWithDebInfo)"
    echo -e "\t  \tthis can be one of {Release, Debug, RelWithDebInfo, MinSizeRel}"
    exit 1
}

# get commandline arguments
while getopts "i:v:t:" opt
do
    case "$opt" in
        i ) install_dir="$OPTARG" ;;
        v ) version="$OPTARG" ;;
        t ) build_type="$OPTARG" ;;
        ? ) help ;;
    esac
done

# print help if any of the required argument is missing
if [ -z "$install_dir" ] || [ -z "$version" ]
then
    echo "Some or all of the required arguments are empty";
    help
fi

# try to download the LLVM project compressed tarball from GitHub
LLVM_SRC_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${version}/llvm-project-${version}.src.tar.xz"
echo -n "Downloading LLVM ${version} from ${LLVM_SRC_URL}... "
wget -q $LLVM_SRC_URL
if [ $? -ne 0 ]; then
    echo "Failed to downlowd LLVM source from ${LLVM_SRC_URL}"
    exit 1
fi
echo "Done!"

# try to untar and decomproess LLVM source
LLVM_TARBALL_PATH="$(pwd)/llvm-project-${version}.src.tar.xz"
LLVM_SRC_PATH="$(pwd)/llvm-project-${version}.src"
echo -n "Untaring ${LLVM_TARBALL_PATH} to ${LLVM_SRC_PATH}... "
tar -xf $LLVM_TARBALL_PATH
echo "Done!"

# create the install directory and cd into it
mkdir -p $install_dir
cd $install_dir
echo "Now in ${install_dir}"

# build LLVM from source
LLVM_SRC_ROOT="${LLVM_SRC_PATH}/llvm"
cmake $LLVM_SRC_ROOT -DCMAKE_BUILD_TYPE=${build_type}
cmake --build . -j `nproc`

# test LLVM build
make check-all -j `nproc`

# create LLVM_ENV
touch LLVM_ENV
echo '#!/bin/bash' >> LLVM_ENV
echo "" >> LLVM_ENV
echo "LLVM_HOME=$(pwd)" >> LLVM_ENV
echo -e "PATH=\"\${LLVM_HOME}/bin:\$PATH\"" >> LLVM_ENV
echo -e "LD_LIBRARY_PATH=\"\${LLVM_HOME}/lib:\$LD_LIBRARY_PATH\"" >> LLVM_ENV
echo "Created LLVM_ENV at $(pwd)/LLVM_ENV, source it to use the built LLVM"

# cleanup
cd ..
rm $LLVM_TARBALL_PATH
echo "Cleaned up $LLVM_TARBALL_PATH"
rm -r $LLVM_SRC_PATH
echo "Cleaned up $LLVM_SRC_PATH"

# done!
echo "All done!"
