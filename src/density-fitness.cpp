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

#include <zeep/json/element.hpp>
#include <cfg.hpp>
#include <gxrio.hpp>

#include <pdb-redo/BondMap.hpp>
#include <pdb-redo/Statistics.hpp>

#include "density-fitness.hpp"

#include "revision.hpp"

namespace fs = std::filesystem;

// --------------------------------------------------------------------

int density_fitness_main(int argc, char* const argv[])
{
	auto &config = cfg::config::instance();

	auto usage = [argv,&config]()
	{
		std::cout << fs::path(argv[0]).filename().string() << " [options] <mtzfile> <coordinatesfile> [<output>]" << std::endl
				  << config << std::endl;
	};

	config.init(
		cfg::make_option("help,h", "Display help message"),
		cfg::make_option("version", "Print version"),
		cfg::make_option("verbose,v", "Verbose output"),
		cfg::make_option("quiet", "Do not print verbose output at all"),
		cfg::make_option<std::string>("hklin", "mtz file"),
		cfg::make_option<std::string>("xyzin", "coordinates file"),
		cfg::make_option<std::string>("output,o", "Write output to this file instead of stdout"),
		cfg::make_option<std::string>("output-format", "json", "Output format, can be either 'edstats' or 'json'"),
		cfg::make_option("recalc", "Recalculate Fc from FP/SIGFP in mtz file"),
		cfg::make_option<std::string>("aniso-scaling", "Anisotropic scaling (none/observed/calculated)"),
		cfg::make_option("no-bulk", "No bulk correction"),
		cfg::make_option<std::string>("fomap", "Fo map file -- 2mFo - DFc"),
		cfg::make_option<std::string>("dfmap", "difference map file -- 2(mFo - DFc)"),
		cfg::make_option<float>("reshi", "High resolution"),
		cfg::make_option<float>("reslo", "Low resolution"),
		cfg::make_option<float>("sampling-rate", 1.5f, "Sampling rate"),
		cfg::make_option("electron-scattering", "Use electron scattering factors"),
		cfg::make_option("no-edia", "Skip EDIA score calculation"),
		cfg::make_option("use-auth-ids", "Write auth_ identities instead of label_"),
		cfg::make_option<std::string>("mmcif-dictionary", "Path to the mmcif_pdbx.dic file to use instead of default"),
		cfg::make_option<std::string>("compounds", "Location of the components.cif file from CCD"),
		cfg::make_option<std::string>("extra-compounds", "File containing residue information for extra compounds in this specific target, should be either in CCD format or a CCP4 restraints file")
	);

	config.parse(argc, argv);

	// --------------------------------------------------------------------

	if (config.has("version"))
	{
		write_version_string(std::cout, config.has("verbose"));
		exit(0);
	}

	if (config.has("help"))
	{
		usage();
		return 0;
	}

	// --------------------------------------------------------------------
	
	fs::path hklin, xyzin, output;

	if (config.has("hklin"))
		hklin = config.get<std::string>("hklin");

	if (config.has("xyzin"))
		xyzin = config.get<std::string>("xyzin");

	if (config.has("output"))
		output = config.get<std::string>("output");

	std::deque<std::string> operands(config.operands().begin(), config.operands().end());

	if (hklin.empty() and not operands.empty())
	{
		hklin = operands.front();
		operands.pop_front();
	}
	
	if (xyzin.empty() and not operands.empty())
	{
		xyzin = operands.front();
		operands.pop_front();
	}
	
	if (output.empty() and not operands.empty())
	{
		output = operands.front();
		operands.pop_front();
	}
	
	if (hklin.empty() or (xyzin.empty() and (config.has("fomap") == false or config.has("dfmap") == false)))
	{
		usage();
		exit(1);
	}
	
	const std::set<std::string> kAnisoOptions{ "none", "calculated", "observed" };
	if (config.has("aniso-scaling") and kAnisoOptions.count(config.get<std::string>("aniso-scaling")) == 0)
	{
		std::cerr << "Invalid option for aniso-scaling, allowed values are none, observed and calculated" << std::endl;
		exit(1);
	}
	
	if (config.has("fomap") and (config.has("reshi") == false or config.has("reslo") == false))
	{
		std::cerr << "The reshi and reslo parameters are required when using std::map files" << std::endl;
		exit(1);
	}

	if (config.has("quiet"))
		cif::VERBOSE = -1;
	else
		cif::VERBOSE = config.count("verbose");

	// Load extra CCD definitions, if any

	if (config.has("compounds"))
		cif::add_file_resource("components.cif", config.get<std::string>("compounds"));
	
	if (config.has("extra-compounds"))
		cif::compound_factory::instance().push_dictionary(config.get<std::string>("extra-compounds"));
	
	// And perhaps a private mmcif_pdbx dictionary

	if (config.has("mmcif-dictionary"))
		cif::add_file_resource("mmcif_pdbx.dic", config.get<std::string>("mmcif-dictionary"));

	gxrio::ifstream xyzinFile(xyzin);
	if (not xyzinFile.is_open())
		throw std::runtime_error("Could not open xyzin file");

	cif::file f = cif::pdb::read(xyzinFile);
	cif::mm::structure structure(f);

	if (f.empty())
		throw std::runtime_error("Invalid or empty mmCIF file");

	bool electronScattering = config.has("electron-scattering");
	if (not electronScattering)
	{
		auto& exptl = f.front()["exptl"];
		electronScattering = not exptl.empty() and exptl.front()["method"] == "ELECTRON CRYSTALLOGRAPHY";
	}
	
	pdb_redo::MapMaker<float> mm;
	
	if (not hklin.empty())
	{
		float samplingRate = config.get<float>("sampling-rate");
	
		if (config.has("recalc"))
		{
			auto aniso = pdb_redo::MapMaker<float>::as_None;
			if (config.has("aniso-scaling"))
			{
				if (config.get<std::string>("aniso-scaling") == "observed")
					aniso = pdb_redo::MapMaker<float>::as_Observed;
				else if (config.get<std::string>("aniso-scaling") == "calculated")
					aniso = pdb_redo::MapMaker<float>::as_Calculated;
			}
			
			mm.calculate(
				hklin, structure, config.has("no-bulk"), aniso, samplingRate, electronScattering);
		}
		else
			mm.loadMTZ(hklin, samplingRate);
	}
	else
	{
		float reshi = config.get<float>("reshi");
		float reslo = config.get<float>("reslo");
		
		mm.loadMaps(config.get<std::string>("dfmap"), config.get<std::string>("fomap"), reshi, reslo);
	}
	
	std::vector<pdb_redo::ResidueStatistics> r;
	
	if (config.has("no-edia"))
	{
		pdb_redo::StatsCollector collector(mm, structure, electronScattering);
		r = collector.collect();
	}
	else
	{
		pdb_redo::BondMap bm(structure.get_datablock());

		pdb_redo::EDIAStatsCollector collector(mm, structure, electronScattering, bm);
		r = collector.collect();
	}

	bool formatAsJSON = config.get<std::string>("output-format") == "json";

	std::unique_ptr<std::ostream> outFile;
	std::streambuf *out_buffer;

	if (not output.empty())
	{
		outFile.reset(new gxrio::ofstream(output));
		out_buffer = outFile->rdbuf();

		if (config.count("output-format") == 0 and output.extension() == ".eds")
			formatAsJSON = false;
	}
	else
		out_buffer = std::cout.rdbuf();

	std::ostream out(out_buffer);

	if (formatAsJSON)
	{
		using object = zeep::json::element;

		object stats;
		
		for (auto i: r)
		{
			auto &res = structure.get_residue(i.asymID, i.seqID, i.authSeqID);

			stats.emplace_back(object{
				{ "asymID", i.asymID },
				{ "seqID", i.seqID },
				{ "compID", i.compID },
				{
					"pdb", {
						{ "strandID", res.get_auth_asym_id() },
						{ "seqNum", i.authSeqID.empty() ? 0 : stoi(i.authSeqID) },
						{ "compID", i.compID },
						{ "insCode", res.get_pdb_ins_code() }
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
	
		bool writeAuth = config.has("use-auth-ids");
	
		for (auto i: r)
		{
			std::string id;
			
			if (writeAuth)
			{
				auto &res = structure.get_residue(i.asymID, i.seqID, i.authSeqID);

				id = i.compID + '_' + res.get_auth_asym_id() + '_' + res.get_auth_seq_id() + res.get_pdb_ins_code();
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
