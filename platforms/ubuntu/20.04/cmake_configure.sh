#!/bin/bash

cd "$(dirname "$0")"

INSTALL_FOLDER=$PWD/build/install

BUILD_TYPE=full
if [[ $# -gt 0 ]]; then
    if [ "$1" == "core" ]; then
	BUILD_TYPE=core
    fi
fi

EMGUCV_CMAKE_SHARED_OPTIONS=( -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON -DCMAKE_BUILD_TYPE:STRING="Release" -DCMAKE_INSTALL_PREFIX:STRING="$INSTALL_FOLDER" -DCMAKE_FIND_ROOT_PATH:STRING="$INSTALL_FOLDER" -DCMAKE_CXX_STANDARD:String="11" )

cd ../../..

cd eigen
mkdir -p build
cd build
cmake ${EMGUCV_CMAKE_SHARED_OPTIONS[@]} ..
cmake --build . --config Release --parallel --target install
cd ../..

if [ "$BUILD_TYPE" == "core" ]; then
    echo "Performing a core build"
    TESSERACT_OPTION=-DEMGU_CV_WITH_TESSERACT:BOOL=FALSE
    VTK_OPTION=
    CONTRIB_OPTION=
else
    echo "Performing a full build"
    TESSERACT_OPTION=-DEMGU_CV_WITH_TESSERACT:BOOL=TRUE

    cd hdf5
    mkdir -p build
    cd build
    cmake ${EMGUCV_CMAKE_SHARED_OPTIONS[@]} -DBUILD_SHARED_LIBS:BOOL=OFF -DBUILD_TESTING:BOOL=FALSE -DHDF5_BUILD_EXAMPLES:BOOL=FALSE -DHDF5_BUILD_TOOLS:BOOL=FALSE -DHDF5_BUILD_UTILS:BOOL=FALSE ..
    cmake --build . --config Release --parallel --target install
    cd ../..
    
    cd vtk
    mkdir -p build
    cd build
    cmake ${EMGUCV_CMAKE_SHARED_OPTIONS[@]} -DBUILD_TESTING:BOOL=FALSE -DBUILD_SHARED_LIBS:BOOL=FALSE -DVTK_MODULE_ENABLE_VTK_RenderingFreeType:STRING="NO" -DVTK_MODULE_ENABLE_VTK_png:STRING="NO" ..
    cmake --build . --config Release --parallel --target install
    VTK_OPTION=-DVTK_DIR:String="$INSTALL_FOLDER"
    cd ../..

    CONTRIB_OPTION=-DOPENCV_EXTRA_MODULES_PATH=../../../../opencv_contrib/modules 
fi

cd platforms/ubuntu/20.04

mkdir -p build
cd build
cmake \
      ${EMGUCV_CMAKE_SHARED_OPTIONS[@]} \
      $TESSERACT_OPTION \
      -DBUILD_TESTS:BOOL=FALSE \
      -DBUILD_PNG:BOOL=TRUE \
      -DBUILD_JPEG:BOOL=TRUE \
      -DBUILD_JASPER:BOOL=TRUE \
      -DBUILD_TIFF:BOOL=TRUE \
      -DBUILD_OPENEXR:BOOL=TRUE \
      -DBUILD_PERF_TESTS:BOOL=FALSE \
      -DBUILD_opencv_apps:BOOL=FALSE \
      -DBUILD_DOCS:BOOL=FALSE \
      $CONTRIB_OPTION \
      -DBUILD_opencv_ts:BOOL=FALSE \
      -DBUILD_opencv_java:BOOL=FALSE \
      -DBUILD_opencv_python2:BOOL=FALSE \
      -DBUILD_opencv_python3:BOOL=FALSE \
      -DBUILD_SHARED_LIBS:BOOL=FALSE \
      $VTK_OPTION \
      -DWITH_EIGEN:BOOL=TRUE \
      -DEigen3_DIR:String="$INSTALL_FOLDER" \
      $PWD/../../../..

#      -DWITH_TBB:BOOL=TRUE \
#      -DWITH_CUDA:BOOL=FALSE \
    
C_INCLUDE_PATH=$PWD/../../../../eigen/:$INSTALL_FOLDER/include/vtk-8.2 CPLUS_INCLUDE_PATH=$PWD/../../../../eigen/:$INSTALL_FOLDER/include/vtk-8.2 make

cd ..
