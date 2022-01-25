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

/* 
   Created by: Maarten L. Hekkelman
   Date: woensdag 27 december, 2017
*/

#include <fstream>
#include <iomanip>
#include <filesystem>

#include <boost/program_options.hpp>
#include <boost/iostreams/filter/gzip.hpp>
#include <boost/iostreams/filtering_stream.hpp>

#include "zeep/json/element.hpp"

#include "cif++/BondMap.hpp"
#include "pdb-redo/Statistics.hpp"
#include "revision.hpp"

namespace po = boost::program_options;
namespace fs = std::filesystem;
namespace c = mmcif;
namespace io = boost::iostreams;

// --------------------------------------------------------------------

int pr_main(int argc, char* argv[])
{
	po::options_description visible_options(fs::path(argv[0]).filename().string() + " [options] <mtzfile> <coordinatesfile> [<output>]");
	visible_options.add_options()
		("hklin",				po::value<std::string>(),	"mtz file")
		("recalc",											"Recalculate Fc from FP/SIGFP in mtz file")
		("aniso-scaling",		po::value<std::string>(),	"Anisotropic scaling (none/observed/calculated)")
		("no-bulk",											"No bulk correction")
		("xyzin",				po::value<std::string>(),	"coordinates file")
		("fomap",				po::value<std::string>(),	"Fo map file -- 2mFo - DFc")
		("dfmap",				po::value<std::string>(),	"difference map file -- 2(mFo - DFc)")
		("reshi",				po::value<float>(),			"High resolution")
		("reslo",				po::value<float>(),			"Low resolution")
		("sampling-rate",		po::value<float>()->default_value(1.5f),
															"Sampling rate")
		("electron-scattering",								"Use electron scattering factors")
		("no-edia",											"Skip EDIA score calculation")
		("output,o",			po::value<std::string>(),	"Write output to this file instead of stdout")
		("output-format",		po::value<std::string>()->default_value("json"),
															"Output format, can be either 'edstats' or 'json'")
		("use-auth-ids",									"Write auth_ identities instead of label_")
		("mmcif-dictionary",	po::value<std::string>(),	"Path to the mmcif_pdbx.dic file to use instead of default")
		("compounds",			po::value<std::string>(),	"Location of the components.cif file from CCD")
		("extra-compounds",		po::value<std::string>(),	"File containing residue information for extra compounds in this specific target, should be either in CCD format or a CCP4 restraints file")
		("help,h",											"Display help message")
		("version",											"Print version")
		("verbose,v",										"Verbose output")
		;
	
	po::options_description hidden_options("hidden options");
	hidden_options.add_options()
		("components",			po::value<std::string>(),	"Location of the components.cif file from CCD, alias")
		("debug,d",				po::value<int>(),			"Debug level (for even more verbose output)");

	po::options_description cmdline_options;
	cmdline_options.add(visible_options).add(hidden_options);

	po::positional_options_description p;
	p.add("hklin", 1);
	p.add("xyzin", 1);
	p.add("output", 1);
	
	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(cmdline_options).positional(p).run(), vm);
	po::notify(vm);

//	po::variables_map vm;
//	po::store(po::command_line_parser(argc, argv).options(cmdline_options).run(), vm);
//	po::notify(vm);

	// --------------------------------------------------------------------

	if (vm.count("version"))
	{
		write_version_string(std::cout, vm.count("verbose"));
		exit(0);
	}

	if (vm.count("help"))
	{
		std::cerr << visible_options << std::endl;
		return 0;
	}
	
	if (vm.count("xyzin") == 0 or
		(vm.count("hklin") == 0 and (vm.count("fomap") == 0 or vm.count("dfmap") == 0)))
	{
		std::cerr << visible_options << std::endl;
		exit(1);
	}
	
	const std::set<std::string> kAnisoOptions{ "none", "calculated", "observed" };
	if (vm.count("aniso-scaling") and kAnisoOptions.count(vm["aniso-scaling"].as<std::string>()) == 0)
	{
		std::cerr << "Invalid option for aniso-scaling, allowed values are none, observed and calculated" << std::endl;
		exit(1);
	}
	
	if (vm.count("fomap") and (vm.count("reshi") == 0 or vm.count("reslo") == 0))
	{
		std::cerr << "The reshi and reslo parameters are required when using std::map files" << std::endl;
		exit(1);
	}

	cif::VERBOSE = vm.count("verbose") != 0;
	if (vm.count("debug"))
		cif::VERBOSE = vm["debug"].as<int>();

	// Load extra CCD definitions, if any

	if (vm.count("compounds"))
		cif::addFileResource("components.cif", vm["compounds"].as<std::string>());
	else if (vm.count("components"))
		cif::addFileResource("components.cif", vm["components"].as<std::string>());
	
	if (vm.count("extra-compounds"))
		c::CompoundFactory::instance().pushDictionary(vm["extra-compounds"].as<std::string>());
	
	// And perhaps a private mmcif_pdbx dictionary

	if (vm.count("mmcif-dictionary"))
		cif::addFileResource("mmcif_pdbx_v50.dic", vm["mmcif-dictionary"].as<std::string>());

	mmcif::File f(vm["xyzin"].as<std::string>());
	mmcif::Structure structure(f);

	bool electronScattering = vm.count("electron-scattering") > 0;
	if (not electronScattering)
	{
		auto& exptl = f.data()["exptl"];
		electronScattering = not exptl.empty() and exptl.front()["method"] == "ELECTRON CRYSTALLOGRAPHY";
	}
	
	pdb_redo::MapMaker<float> mm;
	
	if (vm.count("hklin"))
	{
		float samplingRate = vm["sampling-rate"].as<float>();
	
		if (vm.count("recalc"))
		{
			auto aniso = pdb_redo::MapMaker<float>::as_None;
			if (vm.count("aniso-scaling"))
			{
				if (vm["aniso-scaling"].as<std::string>() == "observed")
					aniso = pdb_redo::MapMaker<float>::as_Observed;
				else if (vm["aniso-scaling"].as<std::string>() == "calculated")
					aniso = pdb_redo::MapMaker<float>::as_Calculated;
			}
			
			mm.calculate(
				vm["hklin"].as<std::string>(), structure, vm.count("no-bulk"), aniso, samplingRate, electronScattering);
		}
		else
			mm.loadMTZ(vm["hklin"].as<std::string>(), samplingRate);
	}
	else
	{
		float reshi = vm["reshi"].as<float>();
		float reslo = vm["reslo"].as<float>();
		
		mm.loadMaps(vm["fomap"].as<std::string>(), vm["dfmap"].as<std::string>(), reshi, reslo);
	}
	
	std::vector<pdb_redo::ResidueStatistics> r;
	
	if (vm.count("no-edia"))
	{
		pdb_redo::StatsCollector collector(mm, structure, electronScattering);
		r = collector.collect();
	}
	else
	{
		mmcif::BondMap bm(structure);

		pdb_redo::EDIAStatsCollector collector(mm, structure, electronScattering, bm);
		r = collector.collect();
	}

	bool formatAsJSON = vm["output-format"].as<std::string>() == "json";

	std::ofstream of;
	io::filtering_stream<io::output> out;

	if (vm.count("output"))
	{
		fs::path output = vm["output"].as<std::string>();

		of.open(output);
		if (not of.is_open())
		{
			std::cerr << "Could not open output file" << std::endl;
			exit(1);
		}

		if (output.extension() == ".gz")
		{
			out.push(io::gzip_compressor());
			output = output.stem();
		}

		if (vm["output-format"].defaulted() and output.extension() == ".eds")
			formatAsJSON = false;
		
		out.push(of);
	}
	else
		out.push(std::cout);

	if (formatAsJSON)
	{
		using object = zeep::json::element;

		object stats;
		
		for (auto i: r)
		{
			std::tuple<std::string,int,std::string,std::string> pdbID = structure.MapLabelToPDB(i.asymID, i.seqID, i.compID, i.authSeqID);

			stats.emplace_back(object{
				{ "asymID", i.asymID },
				{ "seqID", i.seqID },
				{ "compID", i.compID },
				{
					"pdb", {
						{ "strandID", std::get<0>(pdbID) },
						{ "seqNum", std::get<1>(pdbID) },
						{ "compID", std::get<2>(pdbID) },
						{ "insCode", std::get<3>(pdbID) }
					}
				},
				{ "RSR", i.RSR },
				{ "SRSR", i.SRSR },
				{ "RSCCS", i.RSCCS },
				{ "NGRID", i.ngrid },
				{ "EDIAm", i.EDIAm },
				{ "OPIA", i.OPIA }
			});
		}
		
		out << stats << std::endl;
	}
	else
	{
		out << "RESIDUE" << '\t'
			<< "RSR" << '\t'
			<< "SRSR" << '\t'
			<< "RSCCS" << '\t'
			<< "NGRID" << '\t'
			<< "EDIAm" << '\t'
			<< "OPIA" << std::endl;
	
		bool writeAuth = vm.count("use-auth-ids");
	
		for (auto i: r)
		{
			std::string id;
			
			if (writeAuth)
			{
				std::tuple<std::string,int,std::string,std::string> pdbID = structure.MapLabelToPDB(i.asymID, i.seqID, i.compID, i.authSeqID);
				id = std::get<2>(pdbID) + '_' + std::get<0>(pdbID) + '_' + std::to_string(std::get<1>(pdbID)) + std::get<3>(pdbID);
			}
			else if (i.compID == "HOH")
				id = i.compID + '_' + i.asymID + '_' + i.authSeqID;
			else
				id = i.compID + '_' + i.asymID + '_' + std::to_string(i.seqID);
			
			out << std::fixed << std::setprecision(3)
				<< id << '\t'
				<< i.RSR << '\t'
				<< i.SRSR << '\t'
				<< i.RSCCS << '\t'
				<< i.ngrid << '\t'
				<< i.EDIAm << '\t'
				<< std::setprecision(1) << i.OPIA << std::endl;
		}
	}
	
	return 0;
}

// --------------------------------------------------------------------

// recursively print exception whats:
void print_what (const std::exception& e)
{
	std::cerr << e.what() << std::endl;
	try
	{
		std::rethrow_if_nested(e);
	}
	catch (const std::exception& nested)
	{
		std::cerr << " >> ";
		print_what(nested);
	}
}

int main(int argc, char* argv[])
{
	int result = -1;
	
	try
	{
		result = pr_main(argc, argv);
	}
	catch (std::exception& ex)
	{
		print_what(ex);
		exit(1);
	}

	return result;
}

