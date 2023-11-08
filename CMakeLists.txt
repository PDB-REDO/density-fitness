cmake_minimum_required(VERSION 3.24)

# set(CMAKE_PROJECT_TOP_LEVEL_INCLUDES cmake/provider.cmake)

project(density-fitness-builder VERSION 1.0.0 LANGUAGES CXX)

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" AND ${CMAKE_CXX_COMPILER_VERSION} LESS 9.4)
	message(FATAL_ERROR "You are using a GNU GCC compiler that is too old")
endif()

include(ExternalProject)

set_property(DIRECTORY PROPERTY EP_BASE Dependencies)

ExternalProject_Add(
	boost
	URL https://boostorg.jfrog.io/artifactory/main/release/1.83.0/source/boost_1_83_0.tar.gz
	URL_HASH SHA1=eb5e17350b5ccd5926fd6bad9f09385c742a3352
	DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}
	BUILD_IN_SOURCE 1
	CONFIGURE_COMMAND ./bootstrap.sh --with-libraries=headers --prefix=${CMAKE_CURRENT_BINARY_DIR}/external
	BUILD_COMMAND ""
	INSTALL_COMMAND ./b2 install
)

ExternalProject_Add(
	libmcfp
	GIT_REPOSITORY https://github.com/mhekkel/libmcfp
	GIT_TAG trunk
	CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
)

ExternalProject_Add(
	mrc
	DEPENDS libmcfp
	GIT_REPOSITORY https://github.com/mhekkel/mrc
	GIT_TAG trunk
	CMAKE_ARGS -DCMAKE_PREFIX_PATH=${CMAKE_CURRENT_BINARY_DIR}/external -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
)

ExternalProject_Add(
	fftw-single
	DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}
	URL http://ftp.fftw.org/pub/fftw/fftw-2.1.5.tar.gz
	URL_HASH SHA1=12020b58edc1b0490a83db4aa912fac5dfdfb26b
	UPDATE_COMMAND ""
	PATCH_COMMAND ${CMAKE_COMMAND}
		-Din_file:FILEPATH=<SOURCE_DIR>/fftw/fftw.h.in
		-Dout_file:FILEPATH=<SOURCE_DIR>/fftw/fftw.h
		-Dpatch_file:FILEPATH=${PROJECT_SOURCE_DIR}/cmake/fftw-h.patch
		-P ${PROJECT_SOURCE_DIR}/cmake/Patch.cmake
	CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_CURRENT_BINARY_DIR}/external --enable-float --enable-type-prefix
	BUILD_COMMAND ${MAKE_EXE}
)

ExternalProject_Add(
	fftw-double
	DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}
	URL http://ftp.fftw.org/pub/fftw/fftw-2.1.5.tar.gz
	URL_HASH SHA1=12020b58edc1b0490a83db4aa912fac5dfdfb26b
	UPDATE_COMMAND ""
	PATCH_COMMAND ""
	CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_CURRENT_BINARY_DIR}/external
	BUILD_COMMAND ${MAKE_EXE}
)

ExternalProject_Add(
	libccp4
	DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}
	URL https://ftp.ccp4.ac.uk/opensource/libccp4-8.0.0.tar.gz
	URL_HASH SHA1=71b2b3e9879feee4257a6d7705e0804c8858d162
	UPDATE_COMMAND ""
	PATCH_COMMAND ""
	CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_CURRENT_BINARY_DIR}/external --disable-fortran
	BUILD_COMMAND ${MAKE_EXE}
)

ExternalProject_Add(
	clipper
	DEPENDS fftw-single fftw-double libccp4
	DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}
	URL http://ftp.ccp4.ac.uk/opensource/clipper-2.1.20201109.tar.gz
	URL_HASH SHA1=4b22318cb33d91b3a1ebe4e2afeddfad91255936
	UPDATE_COMMAND ""
	PATCH_COMMAND ""

	# CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=<INSTALL_DIR>
	CONFIGURE_COMMAND ${CMAKE_COMMAND}
		-E env CPPFLAGS=-I${CMAKE_CURRENT_BINARY_DIR}/external/include
		LDFLAGS=-L${CMAKE_CURRENT_BINARY_DIR}/external/lib
		<SOURCE_DIR>/configure --prefix=${CMAKE_CURRENT_BINARY_DIR}/external --enable-ccp4
	BUILD_COMMAND ${MAKE_EXE}
)

ExternalProject_Add(
	Eigen3
	GIT_REPOSITORY https://gitlab.com/libeigen/eigen.git
	GIT_TAG 3.4.0
	CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
)

ExternalProject_Add(
	zlib-dev
	URL https://www.zlib.net/zlib-1.3.tar.gz
	URL_HASH SHA1=04d053e4d4064a0fb8f0cbd127f0bfb5fe4eb554
	CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
)

ExternalProject_Add(
	libcifpp
	DEPENDS Eigen3 boost zlib-dev
	GIT_REPOSITORY https://github.com/PDB-REDO/libcifpp.git
	GIT_TAG trunk
	CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
		-DCIFPP_CACHE_DIR=/var/cache/libcifpp
		-DCIFPP_DATA_DIR=/usr/share/libcifpp
		-DBUILD_TESTING=OFF
		-DCIFPP_DOWNLOAD_CCD=OFF
		-DCIFPP_INSTALL_UPDATE_SCRIPT=OFF
		-DWRITE_DATA_FILES=OFF
)

ExternalProject_Add(
	newuoa
	GIT_REPOSITORY https://github.com/elsid/newuoa-cpp
	GIT_TAG v0.1.2
	CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
)

ExternalProject_Add(
	libpdb-redo
	DEPENDS libcifpp newuoa clipper
	GIT_REPOSITORY https://github.com/PDB-REDO/libpdb-redo.git
	GIT_TAG trunk
	CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external -DBUILD_TESTING=OFF -DBUILD_MINIMIZER=OFF
)

ExternalProject_Add(
	date
	GIT_REPOSITORY https://github.com/HowardHinnant/date
	GIT_TAG v3.0.1
	CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
)

ExternalProject_Add(
	libzeep
	DEPENDS boost date mrc
	GIT_REPOSITORY https://github.com/mhekkel/libzeep
	GIT_TAG trunk
	CMAKE_ARGS -DCMAKE_PREFIX_PATH=${CMAKE_CURRENT_BINARY_DIR}/external
	-DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
	-DBUILD_TESTING=OFF
)

ExternalProject_Add_StepDependencies(libzeep build boost date)

ExternalProject_Add(density-fitness
	DEPENDS libzeep libpdb-redo libmcfp
	GIT_REPOSITORY https://github.com/pdb-redo/density-fitness
	GIT_TAG trunk
	CMAKE_ARGS -DBUILD_LOCAL_DEPENDENCIES=OFF -DCMAKE_PREFIX_PATH=${CMAKE_CURRENT_BINARY_DIR}/external
		-DCIFPP_SHARE_DIR=${CMAKE_CURRENT_BINARY_DIR}/Dependencies/Source/libcifpp/rsrc
	BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/density-fitness)
