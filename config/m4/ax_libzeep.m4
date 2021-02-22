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
# Description: Check for libzeep

AC_DEFUN([AX_LIBZEEP],
[
	AC_ARG_WITH([zeep],
		AS_HELP_STRING([--with-zeep=@<:@location@:>@],
			[Use the libzeep library as specified.]),
			[
				AS_IF([test -d ${withval}/include], [], [
					AC_MSG_ERROR(['${withval}'' is not a valid directory for --with-zeep])
				])

				ZEEP_CFLAGS="-I ${withval}/include"
				ZEEP_LIBS="-L${withval}/.libs -lzeep"

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
				[ LIBS="-lzeep $LIBS" ],
				[AC_MSG_ERROR([libzeep not found])])
		fi
	])
])