cmake_minimum_required(VERSION 3.24)

include(FetchContent)

FetchContent_Declare(
	libmcfp
	GIT_REPOSITORY https://github.com/mhekkel/libmcfp
	GIT_TAG v1.2.4
)

macro(pdb_redo_provider method dep_name)
	if("${dep_name}" MATCHES "^(mcfp|libmcfp)$")
		# Save our current command arguments in case we are called recursively
		list(APPEND pdb_redo_provider_args ${method} ${dep_name})

		# This will forward to the built-in FetchContent implementation,
		# which detects a recursive call for the same thing and avoids calling
		# the provider again if dep_name is the same as the current call.
		FetchContent_MakeAvailable(libmcfp)

		# Restore our command arguments
		list(POP_BACK pdb_redo_provider_args dep_name method)

		# Tell the caller we fulfilled the request
		if("${method}" STREQUAL "FIND_PACKAGE")
			# We need to set this if we got here from a find_package() call
			# since we used a different method to fulfill the request.
			# This example assumes projects only use the gtest targets,
			# not any of the variables the module may define.
			set(${dep_name}_FOUND TRUE)
		elseif(NOT "${dep_name}" STREQUAL "libmcfp")
			# We used the same method, but were given a different name to the
			# one we populated with. Tell the caller about the name it used.
			FetchContent_SetPopulated(${dep_name}
				SOURCE_DIR "${libmcfp_SOURCE_DIR}"
				BINARY_DIR "${libmcfp_BINARY_DIR}"
			)
		endif()
	endif()
endmacro()

cmake_language(
	SET_DEPENDENCY_PROVIDER pdb_redo_provider
	SUPPORTED_METHODS
	FIND_PACKAGE
	FETCHCONTENT_MAKEAVAILABLE_SERIAL
)