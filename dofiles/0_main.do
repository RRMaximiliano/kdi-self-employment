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
	if inlist("`c(username)'","maximiliano","WB559559", "wb559559"){
		global project			"D:/Documents/GitHub/reserach-projects/kdi-self-employment"
	} 
	
	
*** 0.2 Setting up folders
	global dofiles	"${project}/dofiles"
	global data		"${project}/data"
	
	global emnv_2005	"${data}/raw/2005"
	global emnv_2009	"${data}/raw/2009"
	global emnv_2014 	"${data}/raw/2014"

	global data_int 	"${data}/intermediate"
	
*** 0.0 Install required packages	
	run "${dofiles}/programs/packages.do"	 

	packages tabout ietoolkit winsor esttab nsplit 									// Add update option to update the packages
	ieboilstart, version(15.1)
	
	
********************************************************************************
***	Part 1:  Cleaning 
********************************************************************************
	
*** Creating easy to read long versions of datasets

	
*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Do files EMNV 2014 
*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	/*
	do "$dofiles\EMNV 2014 - Household Assets" 
	do "$dofiles\EMNV 2014 - Vivienda" 
	do "$dofiles\EMNV 2014 - Merging - Household + Household's Assets" 
	do "$dofiles\EMNV 2014 - Population"
	do "$dofiles\EMNV 2014 - Business"
	do "$dofiles\EMNV 2014 - Merging - Business + Pop"
	do "$dofiles\EMNV 2014 - Business + Population"
	do "$dofiles\EMNV 2014 - Poverty"
	do "$dofiles\EMNV 2014 - Social Programs"
	*/ 
	
*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Do files EMNV 2005
*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	*do "$dofiles\EMNV 2005 - Population"

*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Append 
*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	*do "$dofiles\EMNV 2005-2014 Append"

*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Analysis 
*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	* do "$dofiles\Diff-i-Diff 2005-2009-2014" 

 
*	===================================================================================================
*												END		
*	===================================================================================================
