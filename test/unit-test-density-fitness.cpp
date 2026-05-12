/*-
 * SPDX-License-Identifier: BSD-2-Clause
 * 
 * Copyright (c) 2020 NKI/AVL, Netherlands Cancer Institute
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <catch2/catch_all.hpp>

#include <filesystem>
#include <fstream>
#include <stdexcept>
#include <sstream>
#include <vector>

#include <cif++/cif++.hpp>

#include "../src/density-fitness.hpp"

namespace fs = std::filesystem;

// --------------------------------------------------------------------

fs::path gTestDir = fs::current_path();

int main(int argc, char *argv[])
{
	Catch::Session session; // There must be exactly one instance

	// Build a new parser on top of Catch2's
#if CATCH22
	using namespace Catch::clara;
#else
	// Build a new parser on top of Catch2's
	using namespace Catch::Clara;
#endif

	auto cli = session.cli()                               // Get Catch2's command line parser
	           | Opt(gTestDir, "data-dir")                 // bind variable to a new option, with a hint string
	                 ["-D"]["--data-dir"]                  // the option names it will respond to
	           ("The directory containing the data files") // description string for the help output
	           | Opt(cif::VERBOSE, "verbose")["-v"]["--cif-verbose"]("Flag for cif::VERBOSE");

	// Now pass the new composite back to Catch2 so it uses that
	session.cli(cli);

	// Let Catch2 (using Clara) parse the command line
	int returnCode = session.applyCommandLine(argc, argv);
	if (returnCode != 0) // Indicates a command line error
		return returnCode;

	cif::add_file_resource("components.cif", gTestDir / "ccd-subset.cif");
	cif::compound_factory::instance().push_dictionary(gTestDir / "REA.cif");

	return session.run();
}

// --------------------------------------------------------------------

TEST_CASE("test_1")
{
	// Simply compare results for 1cbs. TODO: Perhaps we should have a more complicated test case one day

	std::stringstream ss;

	auto saved = std::cout.rdbuf(ss.rdbuf());

	auto mtz = (gTestDir / "1cbs_map.mtz").string();
	auto xyz = (gTestDir / "1cbs.cif.gz").string();

	std::vector<const char*> argv{
		"density-fitness",
		mtz.c_str(),
		xyz.c_str(),
		"--output-format=eds",
		"--quiet",
		nullptr
	};

	int r = density_fitness_main(argv.size() - 1, const_cast<char* const *>(argv.data()));

	std::cout.rdbuf(saved);

	REQUIRE(r == 0);

	std::ifstream reference(gTestDir / "1cbs-eds.eds");

	std::string line_a, line_b;

	getline(ss, line_a);
	getline(reference, line_b);

	CHECK(line_a == line_b);

	for (;;)
	{
		if (not getline(ss, line_a) or not getline(reference, line_b))
			break;

		std::string ra, rb;
		float va[5], vb[5];
		int na, nb;

		std::stringstream sa(line_a);
		std::stringstream sb(line_b);

		sa >> ra >> va[0] >> va[1] >> va[2] >> na >> va[3] >> va[4];
		sb >> rb >> vb[0] >> vb[1] >> vb[2] >> nb >> vb[3] >> vb[4];

		CHECK(ra == rb);
		CHECK(na == nb);

		CHECK_THAT(va[0], Catch::Matchers::WithinRel(vb[0], 0.01f));
		CHECK_THAT(va[1], Catch::Matchers::WithinRel(vb[1], 0.01f));
		CHECK_THAT(va[2], Catch::Matchers::WithinRel(vb[2], 0.01f));
		CHECK_THAT(va[3], Catch::Matchers::WithinRel(vb[3], 0.1f));	// EDIAm flucuates a bit more
		CHECK_THAT(va[4], Catch::Matchers::WithinRel(vb[4], 0.1f));	// So does OPIA, I guess?
	}
}
