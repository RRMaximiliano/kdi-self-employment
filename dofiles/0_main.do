/********************************************************************************
* PROJECT:	Self-Employment - Nicaragua                                 
* TITLE: 	Main Do file
* YEAR:		2021
*********************************************************************************
	
*** Outline:
	0. Set initial configurations and globals
		0.1 Set file path
		0.2 Set relative folders
		0.3 Tables globals
		0.4 Install required packages
		0.5 Execution do files
	2. Cleaning 
	3. Appending
	4. Construction 
	5. Analysis

*** Programs to be install:
	1. packages
	2. tvsc

*********************************************************************************
*	PART 0: Set initial configurations and globals
********************************************************************************/
		
*** 0.1 Set file path
	if inlist("`c(username)'","maximiliano","Maximiliano", "WB559559", "wb559559", "ifyou"){
		global project			"C:/Users/ifyou/Documents/GitHub/research-projects/kdi-self-employment"
	} 
	
*** 0.2 Set relative folders
	global dofiles		"${project}/dofiles"
	global data			  "${project}/data"
	global outputs		"${project}/outputs"
	global emnv_2005	"${data}/raw/2005"
	global emnv_2009	"${data}/raw/2009"
	global emnv_2014 	"${data}/raw/2014"
	global data_int 	"${data}/intermediate"
	
  global comcal = 0
  global caliper  = 0.0001
  if (${comcal} == 1) {
  	global psmatch = "com caliper(${caliper})"
    global weights = "[fw = _weight]"
    
    // Tables and figures
    global tables 	"${outputs}/desc_stats_cap_0_0001/tables"
		global figures 	"${outputs}/desc_stats_cap_0_0001/figures"
  }
	
  global nnncal = 1
  if (${nnncal} == 1) {
    global nn       = 10
    global psmatch  = "neighbor(${nn})"  	
    global weights  = "[aw = _weight]"
     
    // Tables and Figures outputs
    if (${nn} == 5) {
      global tables 	"${outputs}/desc_stats_eligibility_nn_5/tables"
      global figures 	"${outputs}/desc_stats_eligibility_nn_5/figures"
    }	
    
    else if (${nn} == 10) {
      global tables 	"${outputs}/desc_stats_eligibility_nn_10/tables"
      global figures 	"${outputs}/desc_stats_eligibility_nn_10/figures"	
    }
    
    else if (${nn} == 20) {
      global tables 	"${outputs}/desc_stats_eligibility_nn_20/tables"
      global figures 	"${outputs}/desc_stats_eligibility_nn_20/figures"	 	
    }
  }
  
	
*** 0.3 Tables globals
	global stars1	"label nolines nogaps fragment nomtitle nonumbers noobs nodep star(* 0.10 ** 0.05 *** 0.01) collabels(none) booktabs b(3) se(3)"
	global stars2	"label nolines nogaps fragment nomtitle nonumbers nodep star(* 0.10 ** 0.05 *** 0.01) collabels(none) booktabs r2 b(3) se(3)"	
	
*** 0.4 Install required packages	
	// To install all the required programs
	run "${dofiles}/programs/packages.do"	 

	packages ietoolkit winsor2 nsplit esttab psmatch2 reghdfe ivreghdfe ivreg2 ranktest ftools
	ieboilstart, version(15.1)
	
	// TvsC to create comparison between eligible and non elitgible groups
	run "${dofiles}/programs/tvsc.do"	
	
*** 0.5 Execution globals
	global cleaning 	1
	global append_dta	1
	global construct	1
	global analysis		1
	
	set scheme s1color 	
	 
  exit
  
********************************************************************************
***	Part 1:  Cleaning 
********************************************************************************
	
*** Creating easy to read long versions of datasets
	if (${cleaning}==1) {
		do "${dofiles}/cleaning/01_emnv_2005_population.do"
		do "${dofiles}/cleaning/02_emnv_2009_population.do"
		do "${dofiles}/cleaning/03_emnv_2014_population.do"
	}
	
********************************************************************************
***	Part 2:  Appending
********************************************************************************
	
*** Append datasets
	if (${append_dta}==1) {
		do "${dofiles}/cleaning/04_append_datasets.do"
	}
	
********************************************************************************
***	Part 3:  Construction
********************************************************************************
	
*** Construction
	if (${construct}==1) {
		do "${dofiles}/construct/01_construct.do"
	}	
	
********************************************************************************
***	Part 4:  Analysis
********************************************************************************
	
*** Analysis
	if (${analysis}==1) {
		do "${dofiles}/analysis/01_analysis.do"
	}
 
*** ----------------------------------------------------------------------------
*** END
*** ----------------------------------------------------------------------------
