# CMake module to find a package, or fetch it in case it is not found locally

cmake_minimum_required(VERSION 3.25)

function(find_or_fetch_package _package)
	set(flags VERBOSE)
	set(options VERSION GIT_REPOSITORY GIT_TAG)
	set(variables VARIABLES)
	cmake_parse_arguments(FOF_OPTIONS "${flags}" "${options}" "${variables}" ${ARGN})

	if(NOT _package)
		message(FATAL_ERROR "TARGET option is missing")
	endif()

	if(TARGET "${_package}" OR ${_package}_FOUND)
		return(PROPAGATE ${FOF_OPTIONS_VARIABLES})
	endif()

	find_package("${_package}" ${FOF_OPTIONS_VERSION} QUIET)

	if(${FOF_OPTIONS_VARIABLES})
		message(NOTICE "fof cifpp data dir: ${CIFPP_SHARE_DIR}")
	endif()

	if(${_package}_FOUND)
		return(PROPAGATE ${FOF_OPTIONS_VARIABLES})
	endif()

	include(FetchContent)

	if(NOT FOF_OPTIONS_GIT_REPOSITORY)
		message("Package ${_package} not found and GIT_REPOSITORY option is missing")
	endif()

	if(NOT FOF_OPTIONS_GIT_TAG)
		message("Package ${_package} not found and GIT_TAG option is missing")
	endif()

	FetchContent_Declare(
		"${_package}"
		GIT_REPOSITORY ${FOF_OPTIONS_GIT_REPOSITORY}
		GIT_TAG  ${FOF_OPTIONS_GIT_TAG})
	
	FetchContent_MakeAvailable("${_package}")

	return(PROPAGATE ${FOF_OPTIONS_VARIABLES})

endfunction()