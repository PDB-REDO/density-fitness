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
# Description: Check for libpdb-redo

AC_DEFUN([AX_LIBPDB_REDO],
[
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
		if test -x "$PKG_CONFIG"
		then
			AX_PKG_CHECK_MODULES([PDB_REDO], [libpdb-redo], [], [], [AC_MSG_ERROR([the required package libpdb-redo is not installed])])
			LIBPDB_REDO_DATA_DIR=$(pkg-config --variable=datalibdir libpdb-redo)
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
			AS_IF([ test -f /usr/share/libpdb-redo/bond-info.bin ], [LIBPDB_REDO_DATA_DIR=/usr/share/libpdb-redo])
			AS_IF([ test -f /usr/local/share/libpdb-redo/bond-info.bin ], [LIBPDB_REDO_DATA_DIR=/usr/local/share/libpdb-redo])
		fi
	])

	AC_ARG_VAR([LIBPDB_REDO_DATA_DIR], [Directory containing bond-info.bin file])
	AC_SUBST([LIBPDB_REDO_DATA_DIR], [$LIBPDB_REDO_DATA_DIR])dnl Check for libpdb-redo

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
		if test -x "$PKG_CONFIG"
		then
			AX_PKG_CHECK_MODULES([PDB_REDO], [libpdb-redo], [], [], [AC_MSG_ERROR([the required package libpdb-redo is not installed])])
			LIBPDB_REDO_DATA_DIR=$(pkg-config --variable=datalibdir libpdb-redo)
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
			AS_IF([ test -f /usr/share/libpdb-redo/bond-info.bin ], [LIBPDB_REDO_DATA_DIR=/usr/share/libpdb-redo])
			AS_IF([ test -f /usr/local/share/libpdb-redo/bond-info.bin ], [LIBPDB_REDO_DATA_DIR=/usr/local/share/libpdb-redo])
		fi
	])

	AC_ARG_VAR([LIBPDB_REDO_DATA_DIR], [Directory containing bond-info.bin file])
	AC_SUBST([LIBPDB_REDO_DATA_DIR], [$LIBPDB_REDO_DATA_DIR])
])