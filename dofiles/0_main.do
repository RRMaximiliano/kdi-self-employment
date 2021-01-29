/********************************************************************************
* PROJECT:	Self-Employment - Nicaragua                                 
* TITLE: 	
* YEAR:		2021
*********************************************************************************
	
*** Outline:
	0. Set initial configurations and globals
	1. Cleaning 
	2. Appending Datasets (Baseline and FUP1)
	3. Construction 
	4. Tables -- Regressions
	5. Figures

*** Programs:
	1. iebaltab2
	2. packages

*********************************************************************************
*	PART 0: Set initial configurations and globals
********************************************************************************/

*** ----------------------------------------------------------------------------
* Set Packages
*** ----------------------------------------------------------------------------
	
	
*** ----------------------------------------------------------------------------
*** Set Dropbox and Github directory
*** ----------------------------------------------------------------------------
		
*** 0.1 Set file path
	if inlist("`c(username)'","maximiliano","Maximiliano", "WB559559", "wb559559"){
		global project			"D:/Documents/GitHub/research-projects/kdi-self-employment"
	} 
	
	
*** 0.2 Setting up folders
	global dofiles		"${project}/dofiles"
	global data			"${project}/data"
	global outputs		"${project}/outputs"
	global tables 		"${project}/outputs/tables"
	global figures		"${project}/outputs/figures"
	
	global emnv_2005	"${data}/raw/2005"
	global emnv_2009	"${data}/raw/2009"
	global emnv_2014 	"${data}/raw/2014"

	global data_int 	"${data}/intermediate"
	
	global caliper = 0.01
	if (${caliper}==0.01) {
		global tables 	"${outputs}/desc_stats_cap_0_01/tables"
	}
	
	if (${caliper}==0.001) {
		global tables 	"${outputs}/desc_stats_cap_0_001/tables"
	}	
	
	if (${caliper}==0.0001) {
		global tables 	"${outputs}/desc_stats_cap_0_0001/tables"
	}	
	
*** 0.0 Install required packages	
	run "${dofiles}/programs/packages.do"	 

	packages tabout ietoolkit winsor2 esttab nsplit esttab outreg2 psmatch2 reghdfe ftools 
	ieboilstart, version(15.1)
	
	
*** 0.4 Execution globals
	global cleaning 	0
	global append_dta	0
	global construct	0
	global analysis		0
	
	set scheme s1color 	
	
********************************************************************************
***	Part 1:  Cleaning 
********************************************************************************
	
*** Creating easy to read long versions of datasets
	if (${cleaning}==1) {
		do "${dofiles}/cleaning/01_emnv_2005_population.do"
		do "${dofiles}/cleaning/02_emnv_2009_population.do"
		do "${dofiles}/cleaning/03_emnv_2014_population.do"
	}
	
*** Append datasets
	if (${append_dta}==1) {
		do "${dofiles}/cleaning/04_append_datasets.do"
	}
	
*** Construction
	if (${construct}==1) {
		do "${dofiles}/construct/01_construct.do"
	}	
	
*** Analysis
	if (${analysis}==1) {
		do "${dofiles}/analysis/01_analysis.do"
	}
 
*	===================================================================================================
*												END		
*	===================================================================================================
