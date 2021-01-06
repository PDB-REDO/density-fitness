AC_PREREQ([2.69])

AC_INIT([density-fitness], 2.0, [m.hekkelman@nki.nl])

dnl Switch to a decent C++ compiler, and check if it works.
AC_LANG(C++)
AX_CXX_COMPILE_STDCXX_17([noext])

AX_CHECK_COMPILE_FLAG([-fstandalone-debug], [ CXXFLAGS="$CXXFLAGS -fstandalone-debug" ], , [-Werror])

AC_CONFIG_SRCDIR([src/density-fitness.cpp])
AC_CONFIG_AUX_DIR(config)
AC_CONFIG_MACRO_DIR([config/m4])
AC_CONFIG_HEADERS([src/config.hpp])

AC_PREFIX_DEFAULT(/usr/local)

AC_DEFUN([read_test], [AC_LANG_SOURCE(
	esyscmd(config/tools/m4esc.sh config/test/$1))])

AC_PROG_INSTALL

AX_PTHREAD

AC_ARG_VAR([DEBUG], [Build a debug version of the application])

AC_ARG_VAR([MRC], [Specify a location for the mrc executable])

USE_RSRC=0

if test "x$MRC" = "x"; then
	AC_PATH_PROG([MRC], [mrc])
fi

if test "x$MRC" = "x"; then
	AC_MSG_WARN([The mrc application was not found, not using resources.])
else
	AC_ARG_ENABLE(
		resources,
		[AS_HELP_STRING([--enable-resources], [Use mrc to store data in resources])])

	AS_IF([test "x$enable_resources" = "xyes" ], [
		USE_RSRC=1
	])
fi

AC_SUBST([USE_RSRC], [$USE_RSRC])

AC_DEFINE_UNQUOTED([USE_RSRC], [$USE_RSRC], [Use mrc to store resources])

dnl revision numbering is something used internally at the NKI
AC_ARG_ENABLE(
	revision,
	[AS_HELP_STRING([--disable-revision], [Create a build number as revision])])

AS_IF([test "x$enable_revision" != "xno" ], [
	UPDATE_REVISION=1
])

AC_SUBST([UPDATE_REVISION], [$UPDATE_REVISION])

AC_CHECK_HEADER([filesystem], [], [AC_MSG_ERROR([The file <filesystem> is missing, perhaps you should install a more recent libstdc++ implementation.])])

dnl check if we need stdc++fs as library
AC_TRY_LINK(
	[#include <filesystem>],
	[(void)std::filesystem::current_path();],
	[],
	[
		LIBS="$LIBS -lstdc++fs"

		AC_TRY_LINK(
			[#include <filesystem>],
			[(void)std::filesystem::current_path();],
			[],
			[
				AC_MSG_ERROR([Could not link filesystem])
			]
		)
	]
)

AX_BOOST_BASE([1.65.1], [], [AC_MSG_ERROR([Could not find a recent version of boost])])
AX_BOOST_PROGRAM_OPTIONS
AX_BOOST_IOSTREAMS

CPPFLAGS="$CPPFLAGS $BOOST_CPPFLAGS"
LDFLAGS="$LDFLAGS $BOOST_LDFLAGS"

dnl Check for libcifpp

AC_ARG_WITH([cif++],
	AS_HELP_STRING([--with-cif++=@<:@location@:>@],
		[Use the cif++ library as specified.]),
		[
			AS_IF([test -d ${withval}/include], [], [
				AC_MSG_ERROR(['${withval}'' is not a valid directory for --with-cif++])
			])
			dnl AC_SUBST([CIFPP_CFLAGS], ["-I ${withval}/include"])
			dnl AC_SUBST([CIFPP_LIBS], ["-L${withval}/.libs -lcif++"])

			CIFPP_CFLAGS="-I ${withval}/include"
			CIFPP_LIBS="-L${withval}/.libs -lcifpp"
			LIBCIFPP_DATA_DIR="${withval}/rsrc/dictionaries"

			AC_SUBST([CIFPP_CFLAGS], [$CIFPP_CFLAGS])
			AC_SUBST([CIFPP_LIBS], [$CIFPP_LIBS])
		])

AS_IF([test "x$CIFPP_LIBS" = "x"], [
	PKG_PROG_PKG_CONFIG
	if test -x "$PKG_CONFIG"
	then
		AX_PKG_CHECK_MODULES([CIFPP], [libcifpp], [], [], [AC_MSG_ERROR([the required package libcif++ is not installed])])
	else
		AC_CHECK_HEADER(
	        [cif++/Config.hpp],
	        [
				dnl CIFPP_CFLAGS="-I ${withval}/include"
			],
			[AC_MSG_ERROR([
Can't find the libcif++ header, Config.hpp.  Make sure that it
is installed, and either use the --with-cif++ option or install
pkg-config.])])

		AX_CHECK_LIBRARY([CIFPP], [cif++/Config.hpp], [cifpp],
			[
				LIBS="-lcifpp $LIBS"
			],
			[AC_MSG_ERROR([libcif++ not found])])
	fi

	AS_IF([ test -f /var/cache/libcifpp/mmcif_pdbx_v50.dic ], [LIBCIFPP_DATA_DIR=/var/cache/libcifpp ])
])

AC_ARG_VAR([LIBCIFPP_DATA_DIR], [Directory containing mmcif_pdbx_v50.dic file])
AC_SUBST([LIBCIFPP_DATA_DIR], [$LIBCIFPP_DATA_DIR])

dnl Check for libzeep

AC_ARG_WITH([zeep],
	AS_HELP_STRING([--with-zeep=@<:@location@:>@],
		[Use the libzeep library as specified.]),
		[
			AS_IF([test -d ${withval}/include], [], [
				AC_MSG_ERROR(['${withval}'' is not a valid directory for --with-zeep])
			])

			ZEEP_CFLAGS="-I ${withval}/include"
			ZEEP_LIBS="-L${withval}/.libs -lzeep-json"

			AC_SUBST([ZEEP_CFLAGS], [$ZEEP_CFLAGS])
			AC_SUBST([ZEEP_LIBS], [$ZEEP_LIBS])
		])

AS_IF([test "x$ZEEP_LIBS" = "x"], [
	if test -x "$PKG_CONFIG"
	then
		AX_PKG_CHECK_MODULES([ZEEP], [libzeep], [], [], [AC_MSG_ERROR([the required package libzeep is not installed])])
	else
		AC_CHECK_HEADER(
			[zeep/json/element.hpp],
			[],
			[AC_MSG_ERROR([
Can't find the libzeep header, zeep/json/element.hpp.  Make sure that libzeep
is installed, and either use the --with-zeep option or install
pkg-config.])])

		AX_CHECK_LIBRARY([ZEEP], [zeep/json/element.hpp], [zeep],
			[ LIBS="-lzeep-json $LIBS" ],
			[AC_MSG_ERROR([libzeep not found])])
	fi
])

dnl Check for libpdb-redo

AC_ARG_WITH([pdb-redo],
	AS_HELP_STRING([--with-pdb-redo=@<:@location@:>@],
		[Use the pdb-redo library as specified.]),
		[
			AS_IF([test -d ${withval}/include], [], [
				AC_MSG_ERROR(['${withval}'' is not a valid directory for --with-pdb-redo])
			])
			dnl AC_SUBST([PDB_REDO_CFLAGS], ["-I ${withval}/include"])
			dnl AC_SUBST([PDB_REDO_LIBS], ["-L${withval}/.libs -lpdb-redo"])

			PDB_REDO_CFLAGS="-I ${withval}/include"
			PDB_REDO_LIBS="-L${withval}/.libs -lpdb-redo"
			LIBPDB_REDO_DATA_DIR="${withval}/rsrc"

			AC_SUBST([PDB_REDO_CFLAGS], [$PDB_REDO_CFLAGS])
			AC_SUBST([PDB_REDO_LIBS], [$PDB_REDO_LIBS])
		])

AS_IF([test "x$PDB_REDO_LIBS" = "x"], [
	AC_PATH_PROG([PKG_CONFIG], [pkg-config])
	if test -x "$PKG_CONFIG"
	then
		AX_PKG_CHECK_MODULES([PDB_REDO], [libpdb-redo], [], [], [AC_MSG_ERROR([the required package libpdb-redo is not installed])])
	else
		AC_CHECK_HEADER(
	        [pdb-redo/Config.hpp],
	        [
				dnl PDB_REDO_CFLAGS="-I ${withval}/include"
			],
			[AC_MSG_ERROR([
Can't find the libpdb-redo header, Config.hpp.  Make sure that it
is installed, and either use the --with-pdb-redo option or install
pkg-config.])])

		AX_CHECK_LIBRARY([PDB_REDO], [pdb-redo/Config.hpp], [pdb-redo],
			[
				LIBS="-lpdb-redo $LIBS"
			],
			[AC_MSG_ERROR([libpdb-redo not found])])
	fi

	AS_IF([ test -f /usr/share/libpdb-redo/bond-info.bin ], [LIBPDB_REDO_DATA_DIR=/usr/share/libpdb-redo])
	AS_IF([ test -f /usr/local/share/libpdb-redo/bond-info.bin ], [LIBPDB_REDO_DATA_DIR=/usr/local/share/libpdb-redo])
])

AC_ARG_VAR([LIBPDB_REDO_DATA_DIR], [Directory containing bond-info.bin file])
AC_SUBST([LIBPDB_REDO_DATA_DIR], [$LIBPDB_REDO_DATA_DIR])

dnl Check for libclipper

AC_ARG_WITH([clipper],
	AS_HELP_STRING([--with-clipper=@<:@location@:>@],
		[Use the libclipper library as specified.]),
		[
			AS_IF([test -d ${withval}], [], [
				AC_MSG_ERROR(['${withval}'' is not a valid directory for --with-clipper])
			])

			CLIPPER_CFLAGS="-I ${withval}"
			CLIPPER_LIBS="-L${withval}/lib -lclipper-ccp4 -lclipper-cif -lclipper-minimol -lclipper-mmdb -lclipper-cns -lclipper-phs -lclipper-contrib -lclipper-core -lccp4c -lmmdb2"

			AC_SUBST([CLIPPER_CFLAGS], [$CLIPPER_CFLAGS])
			AC_SUBST([CLIPPER_LIBS], [$CLIPPER_LIBS])
		])

AS_IF([test "x$CLIPPER_LIBS" = "x"], [
	if test -x "$PKG_CONFIG"
	then
		AX_PKG_CHECK_MODULES([CLIPPER], [clipper], [], [], [AC_MSG_ERROR([the required package libclipper is not installed])])
	else
		AC_CHECK_HEADER(
			[clipper/clipper.h],
			[],
			[AC_MSG_ERROR([
Can't find the libclipper header, clipper/clipper.h.  Make sure that libclipper
is installed, and either use the --with-clipper option or install
pkg-config.])])

		AX_CHECK_LIBRARY([CLIPPER], [clipper.h], [clipper-core],
				[ LIBS="-lclipper-fortran -lclipper-ccp4 -lclipper-cif -lclipper-minimol -lclipper-mmdb -lclipper-cns -lclipper-phs -lclipper-contrib -lclipper-core -lccp4c -lmmdb2 $LIBS" ],
				[AC_MSG_ERROR([libclipper not found])])
	fi
])

AC_MSG_CHECKING([clipper version])
AC_COMPILE_IFELSE(
	[read_test(clipper-test.cpp)],
	[AC_MSG_RESULT([ok])],
	[AC_MSG_ERROR([The version of clipper is not up to date])])

AC_DEFINE([HAVE_CLIPPER], [1], [Use libclipper])

dnl Process Makefile.in to create Makefile
AC_OUTPUT([GNUmakefile])
