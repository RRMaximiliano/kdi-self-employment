/********************************************************************************
* PROJECT:	Self-Employment - Nicaragua                                 
* TITLE: 	Appending datasets
* YEAR:		2021
*********************************************************************************
	
*** Outline:
	1. Load data
	2. Append and save data
	
*********************************************************************************
*	PART 1: Load data
********************************************************************************/

*** Load dataset
	use "${data_int}/emnv_05_pop.dta", clear 
	
*********************************************************************************
*	PART 2: Append and save data
********************************************************************************/
	
*** Append dataset
	append using "${data_int}/emnv_09_pop.dta"
	append using "${data_int}/emnv_14_pop.dta"
	
*** Save dataset
	save "${data_int}/emnv_appended.dta", replace 
	
	
	