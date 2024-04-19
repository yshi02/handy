#!/bin/bash

# record the path to the curent working directory
working_dir=$(pwd)

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

# print help if any of the required argument is missing
if [ -z "$install_dir" ] || [ -z "$version" ]
then
    echo "Some or all of the required arguments are missing";
    help
fi

# create the install directory
mkdir -p $install_dir

# try to download the LLVM project compressed tarball from GitHub
LLVM_SRC_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${version}/llvm-project-${version}.src.tar.xz"
echo -n "Downloading LLVM ${version} from ${LLVM_SRC_URL}... "
wget -q $LLVM_SRC_URL
if [ $? -ne 0 ]; then
    echo "Failed to downlowd LLVM source from ${LLVM_SRC_URL}"
    exit 1
fi
echo "Done!"

# try to extract LLVM source from the downloaded tarball to the install dir
LLVM_SRC_TARBALL_PATH="${working_dir}/llvm-project-${version}.src.tar.xz"
LLVM_SRC_EXTRACT_PATH="${install_dir}/llvm-project-${version}.src"
echo -n "Extracting LLVM source from ${LLVM_SRC_TARBALL_PATH} to ${LLVM_SRC_EXTRACT_PATH}... "
tar -xf $LLVM_SRC_TARBALL_PATH -C $install_dir
echo "Done!"

# move to the install dir and build LLVM from source
LLVM_SRC_ROOT="${LLVM_SRC_EXTRACT_PATH}/llvm"
cd $install_dir
cmake $LLVM_SRC_ROOT -DCMAKE_BUILD_TYPE=${build_type} -DCMAKE_INSTALL_PREFIX=${install_dir}
cmake --build . -j `nproc`

# test LLVM build
make check-all -j `nproc`

# install LLVM
cmake --build . --target install -j `nproc`

# create LLVM_ENV
touch LLVM_ENV
echo '#!/bin/bash' >> LLVM_ENV
echo "" >> LLVM_ENV
echo "LLVM_HOME=$(pwd)" >> LLVM_ENV
echo -e "PATH=\"\${LLVM_HOME}/bin:\$PATH\"" >> LLVM_ENV
echo -e "LD_LIBRARY_PATH=\"\${LLVM_HOME}/lib:\$LD_LIBRARY_PATH\"" >> LLVM_ENV
echo "Created LLVM_ENV at $(pwd)/LLVM_ENV, source it to use LLVM"

# cleanup
cd $working_dir
rm $LLVM_SRC_TARBALL_PATH
echo "Cleaned up $LLVM_SRC_TARBALL_PATH"

# done!
echo "LLVM ${version} installed at ${install_dir}"
echo "All done!"
