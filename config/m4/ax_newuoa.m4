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
# Description: Check for libnewuoa or dlib

AC_DEFUN([AX_NEWUOA],
[
	HAVE_NEWUOA=0

	if test -x "$PKG_CONFIG"
	then
		AX_PKG_CHECK_MODULES([NEWUOA], [newuoa], [], [
			HAVE_NEWUOA=1
			AC_DEFINE([HAVE_NEWUOA], [1])
		], [AC_MSG_WARN([the required package libnewuoa-dev is not installed])])
	else
		AC_CHECK_HEADER(
			[newuoa.h], [], [AC_MSG_WARN([Can't find the newuoa header file.])])

		AX_CHECK_LIBRARY([NEWUOA], [newuoa.h], [newuoa],
			[
				LIBS="-lnewuoa $LIBS"
				HAVE_NEWUOA=1
			],
			[AC_MSG_WARN([libnewuoa not found])])
	fi

	if test "$HAVE_NEWUOA" = "0" ; then
		AX_CHECK_LIBRARY([DLIB], [dlib/global_optimization.h], [dlib],
				[
					HAVE_DLIB=1
					DLIB_LIBS="-ldlib $LIBS"
				],
				[AC_MSG_WARN([libdlib-dev not found])])

		AC_SUBST([DLIB_CFLAGS], [])
		AC_SUBST([DLIB_LIBS], [$DLIB_LIBS])
	fi

	AS_IF([ test "x${HAVE_DLIB}" = "x" && test "x${HAVE_NEWUOA}" = "x" ], [
		AC_MSG_ERROR([Either libnewuoa-dev or libdlib-dev should be installed])
	])
])
