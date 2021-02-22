# SPDX-License-Identifier: BSD-2-Clause
# 
# Copyright (c) 2020 NKI/AVL, Netherlands Cancer Institute
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Description: m4 macro to detect std::filesystem and optionally the linker flags to use it
# 
# Description: Check for libclipper
#
# libclipper may be installed standalone, or it might be part of the CCP4 suite
# This macro checks for both

AC_DEFUN([AX_LIBCLIPPER],
[
	AC_ARG_VAR([CCP4], [The location where CCP4 is installed])

	AS_IF([test x"$CCP4" != x""],
		[
		CPPFLAGS="$CPPFLAGS -I ${CCP4}/include"
		CXXFLAGS="$CXXFLAGS -I ${CCP4}/include"
		LDFLAGS="$LDFLAGS -L${CCP4}/lib"

		dnl since rpath is apparently something that is not ubiquitously available
		AX_CHECK_LINK_FLAG([-Wl,-rpath=/tmp], [
			LDFLAGS="$LDFLAGS -Wl,-rpath=${CCP4}/lib"])

		AC_CHECK_HEADER(
			[clipper/clipper.h],
			[],
			[AC_MSG_ERROR([
	Can't find the libclipper header, clipper/clipper.h.  Make sure that libclipper
	is installed, and either use the --with-clipper option or install
	pkg-config.])])

		AX_CHECK_LIBRARY([CLIPPER], [clipper/clipper.h], [clipper-core],
			[
				CLIPPER_LIBS="-L${CCP4}/lib -lclipper-ccp4 -lclipper-cif -lclipper-minimol -lclipper-mmdb -lclipper-cns -lclipper-phs -lclipper-contrib -lclipper-core -lccp4c -lmmdb2 -lrfftw -lfftw"
			],
			[AC_MSG_ERROR([libclipper not found])])
		])

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
])