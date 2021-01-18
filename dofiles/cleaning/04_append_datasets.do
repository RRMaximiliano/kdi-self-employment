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

*** Load first dataset
	use "${data_int}/emnv_05_pop.dta", clear 
	
*** Append dataset
	append using "${data_int}/emnv_09_pop.dta"
	append using "${data_int}/emnv_14_pop.dta"
	
*** Save dataset
	save "${data_int}/emnv_appended.dta", replace 
	
	
	