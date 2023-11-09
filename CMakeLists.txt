cmake_minimum_required(VERSION 3.20)

project(density-fitness-builder VERSION 1.0.0 LANGUAGES CXX)

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" AND ${CMAKE_CXX_COMPILER_VERSION} LESS 9.4)
	message(FATAL_ERROR "You are using a GNU GCC compiler that is too old")
endif()

include(ExternalProject)

set_property(DIRECTORY PROPERTY EP_BASE Dependencies)

find_package(Boost 1.74 COMPONENTS headers QUIET)

if(NOT Boost_FOUND)
	ExternalProject_Add(
		local_boost
		URL https://boostorg.jfrog.io/artifactory/main/release/1.83.0/source/boost_1_83_0.tar.gz
		URL_HASH SHA1=eb5e17350b5ccd5926fd6bad9f09385c742a3352
		DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}
		BUILD_IN_SOURCE 1
		CONFIGURE_COMMAND ./bootstrap.sh --with-libraries=headers --prefix=${CMAKE_CURRENT_BINARY_DIR}/external
		BUILD_COMMAND ""
		INSTALL_COMMAND ./b2 install
	)
	set(BOOST_D local_boost)
endif()

find_package(libmcfp 1.2.4 QUIET)

if(NOT libmcfp_FOUND)
	ExternalProject_Add(
		local_libmcfp
		DEPENDS ${BOOST_D}
		GIT_REPOSITORY https://github.com/mhekkel/libmcfp
		GIT_TAG trunk
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
	)
	set(LIBMCFP_D local_libmcfp)
endif()

find_package(Mrc QUIET)

if(NOT Mrc_FOUND)
	ExternalProject_Add(
		local_mrc
		DEPENDS ${LIBMCFP_D}
		GIT_REPOSITORY https://github.com/mhekkel/mrc
		GIT_TAG trunk
		CMAKE_ARGS -DCMAKE_PREFIX_PATH=${CMAKE_CURRENT_BINARY_DIR}/external -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
	)
	set(MRC_D local_mrc)
endif()

find_package(CCP4 QUIET COMPONENTS ccp4c clipper-core clipper-ccp4 clipper-contrib)

if(NOT CCP4_FOUND)
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
		local_clipper
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
	set(CCP4_D local_clipper)
endif()

find_package(Eigen3 QUIET)

if(NOT Eigen3_FOUND)
	ExternalProject_Add(
		local_Eigen3
		GIT_REPOSITORY https://gitlab.com/libeigen/eigen.git
		GIT_TAG 3.4.0
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
	)

	set(EIGEN3_D local_Eigen3)
endif()

find_package(pdb-redo 3.0.1 QUIET)

if(NOT pdb-redo_FOUND)
	find_package(cifpp 5 QUIET)

	if(NOT cifpp_FOUND)
		ExternalProject_Add(
			zlib-dev
			URL https://www.zlib.net/zlib-1.3.tar.gz
			URL_HASH SHA1=04d053e4d4064a0fb8f0cbd127f0bfb5fe4eb554
			CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
		)

		ExternalProject_Add(
			local_cifpp
			DEPENDS ${EIGEN3_D} ${BOOST_D} zlib-dev
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

		set(CIFPP_D local_cifpp)
	endif()

	find_package(newuoa QUIET)

	if(NOT newuoa_FOUND)
		ExternalProject_Add(
			local_newuoa
			GIT_REPOSITORY https://github.com/elsid/newuoa-cpp
			GIT_TAG v0.1.2
			CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
		)
		set(NEWUOA_D local_newuoa)
	endif()

	ExternalProject_Add(
		local_libpdb-redo
		DEPENDS ${CIFPP_D} ${NEWUOA_D} ${CCP4_D}
		GIT_REPOSITORY https://github.com/PDB-REDO/libpdb-redo.git
		GIT_TAG trunk
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external -DBUILD_TESTING=OFF -DBUILD_MINIMIZER=OFF
	)
	set(PDB_REDO_D local_libpdb-redo)
endif()

find_package(zeep 6 QUIET)

if(NOT zeep_FOUND)
	ExternalProject_Add(
		local_date
		GIT_REPOSITORY https://github.com/HowardHinnant/date
		GIT_TAG v3.0.1
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
	)

	ExternalProject_Add(
		local_libzeep
		DEPENDS ${BOOST_D} local_date ${MRC_D}
		GIT_REPOSITORY https://github.com/mhekkel/libzeep
		GIT_TAG trunk
		CMAKE_ARGS -DCMAKE_PREFIX_PATH=${CMAKE_CURRENT_BINARY_DIR}/external
		-DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/external
		-DBUILD_TESTING=OFF
	)

	ExternalProject_Add_StepDependencies(local_libzeep build ${BOOST_D} local_date)

	set(ZEEP_D local_libzeep)
endif()

find_package(Git REQUIRED)

set(DF_TRUNK_SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/density-fitness)

if(EXISTS ${DF_TRUNK_SOURCE_DIR}/.git)
	execute_process(
		COMMAND ${CMAKE_COMMAND} -E env ${GIT_EXECUTABLE} pull
		WORKING_DIRECTORY ${DF_TRUNK_SOURCE_DIR}
		COMMAND_ECHO STDOUT
	)
else()
	execute_process(
		COMMAND ${CMAKE_COMMAND} -E remove_directory ${DF_TRUNK_SOURCE_DIR}
		COMMAND ${CMAKE_COMMAND} -E env ${GIT_EXECUTABLE} clone file://${CMAKE_CURRENT_SOURCE_DIR}/ ${DF_TRUNK_SOURCE_DIR} -b trunk
		COMMAND_ECHO STDOUT
	)
endif()


ExternalProject_Add(density-fitness
	DEPENDS ${ZEEP_D} ${PDB_REDO_D} ${LIBMCFP_D}
	SOURCE_DIR ${DF_TRUNK_SOURCE_DIR}
	CMAKE_ARGS
	-DCMAKE_PREFIX_PATH=${CMAKE_CURRENT_BINARY_DIR}/external
	-DCIFPP_SHARE_DIR=${CMAKE_CURRENT_BINARY_DIR}/Dependencies/Source/libcifpp/rsrc
	-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
	INSTALL_COMMAND ""
	BINARY_DIR ${DF_TRUNK_SOURCE_DIR})

install(CODE [[
	execute_process(COMMAND ${CMAKE_COMMAND}
		-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
		-P ${CMAKE_CURRENT_BINARY_DIR}/density-fitness/cmake_install.cmake)
]])
