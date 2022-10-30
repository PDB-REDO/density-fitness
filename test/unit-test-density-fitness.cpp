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

#define BOOST_TEST_ALTERNATIVE_INIT_API
#include <boost/test/included/unit_test.hpp>

#include <filesystem>
#include <fstream>
#include <stdexcept>
#include <sstream>
#include <vector>

#include "../src/density-fitness.hpp"

namespace fs = std::filesystem;
namespace tt = boost::test_tools;
namespace utf = boost::unit_test;

// --------------------------------------------------------------------

fs::path gTestDir = fs::current_path();

bool init_unit_test()
{
	// not a test, just initialize test dir

	if (boost::unit_test::framework::master_test_suite().argc == 2)
		gTestDir = boost::unit_test::framework::master_test_suite().argv[1];

	return true;
}

// --------------------------------------------------------------------

BOOST_AUTO_TEST_CASE(test_1)
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

	BOOST_CHECK_EQUAL(r, 0);

	std::ifstream reference(gTestDir / "1cbs-eds.eds");

	std::string line_a, line_b;

	getline(ss, line_a);
	getline(reference, line_b);

	BOOST_CHECK_EQUAL(line_a, line_b);

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

		BOOST_CHECK_EQUAL(ra, rb);
		BOOST_CHECK_EQUAL(na, nb);

		BOOST_TEST(va[0] == vb[0], tt::tolerance(0.01f));
		BOOST_TEST(va[1] == vb[1], tt::tolerance(0.01f));
		BOOST_TEST(va[2] == vb[2], tt::tolerance(0.01f));
		BOOST_TEST(va[3] == vb[3], tt::tolerance(0.1f));	// EDIAm flucuates a bit more
		BOOST_TEST(va[4] == vb[4], tt::tolerance(0.01f));
	}
}
