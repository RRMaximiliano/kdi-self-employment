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

*** Load dataset 
	use "${data_int}/emnv_cuaen_eligibility.dta", clear 
	
	global sig "nocons label"
	global caliper = 0.0001
	
	//	Table 1: Summary Statistics
	local 	vars		///	
			sex 		///
			edu 		///
			area 		///
			age 				///
			household_size 		///
			real_income_1 		///
			ln_real_income_1 	///
			eligibility_1
	
	// Generate sector 
	recode 	cat_1									///
			(2 6 13/18= 0)							///	
			(1 = 1 "Agriculture and Forestry" )		///
			(3/5 7 = 2 "Manufacture Industry") 		///
			(8 = 3 "Construction") 					///
			(9 10 11 = 4 "Commerce") 				///
			(12 = 5 "Hotels and Restaurants"), 		///
	gen(sector)
		
	// Overall summ stats by year
	local years "2005 2009 2014"
	local append "replace"
	foreach y in `years' {
		estpost sum `vars' if selfemployment_1 == 1 & year == `y'
		
		esttab 	using "${outputs}/summ_stats.csv", `append'								///	
			cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min max") label nogaps 		///
			fragment nomtitle nonumbers nodepvar noobs collabels(none)		
			
		local append "append"
	}

	// Overall summ stats by gender and year
	local append "replace"
	forvalues sex = 0/1 {
		foreach y in `years' {
			estpost sum `vars' if selfemployment_1 == 1 & year == `y' & sex == `sex'
			
			esttab 	using "${outputs}/summ_stats_gender.csv", `append'						///	
				cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min max") label nogaps 		///
				fragment nomtitle nonumbers nodepvar noobs collabels(none)		
				
			local append "append"
		}	
	}
	
	// Pooled all years 
	estpost sum `vars' if selfemployment_1 == 1
		
	esttab 	using "${outputs}/summ_stats_pooled.csv", replace							///	
			cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min max") label nogaps 		///
			fragment nomtitle nonumbers nodepvar noobs collabels(none)	
			
	// Pooled by gender	
	local append "replace"
	forvalues sex = 0/1 {
		estpost sum `vars' if selfemployment_1 == 1 & sex == `sex'
		
		esttab 	using "${outputs}/summ_stats_pooled_gender.csv", `append'				///	
			cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min max") label nogaps 		///
			fragment nomtitle nonumbers nodepvar noobs collabels(none)	
			
		local append "append"
	}		
		
	
	// Drop agriculture sector 
	drop if sector == 1
	
	// Table 2: Parallel Trends Assumption Test
	preserve 
		keep if selfemployment_1 == 1 
		keep if time != 2

		local vars "sex edu area age household_size"
		psmatch2 eligibility_1 `vars', out(ln_real_income_1) com caliper(${caliper}) 
		
		reg ln_real_income_1 time##_treated ib7.main_cat_1 [fw=_weight], 								vce(cluster time_activity_1) 
			outreg2 using "${outputs}/parallel_trend.xml", replace $sig 																///
			addtext(Primary Activity Fixed Effects, Yes, Controls, No, Regional  Fixed Effects, No, Occupation Fixed Effects, No)		///
			keep(1.time#1._treated 1.time 1._treated)
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' [fw=_weight], 						vce(cluster time_activity_1) 
			outreg2 using "${outputs}/parallel_trend.xml", $sig 																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, No, Occupation Fixed Effects, No)		///
			keep(1.time#1._treated 1.time 1._treated)		
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4  [fw=_weight], 			vce(cluster time_activity_1) 
			outreg2 using "${outputs}/parallel_trend.xml", $sig 																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, No)		///
			keep(1.time#1._treated 1.time 1._treated)	
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight], 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/parallel_trend.xml", $sig 																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
			keep(1.time#1._treated 1.time 1._treated)			
	restore 
	
	// Table 3: Falsification Test
	preserve 
		keep if employed_1 == 1 
		recode time (1=0) (2=1)
		
		local vars "sex edu area age household_size"
		psmatch2 eligibility_1 `vars', out(ln_real_income_1) com caliper(${caliper}) 
	
		reg ln_real_income_1 time##_treated ib7.main_cat_1 [fw=_weight], 								vce(cluster time_activity_1) 
			outreg2 using "${outputs}/falsification.xml", replace $sig 																///
			addtext(Primary Activity Fixed Effects, Yes, Controls, No, Regional  Fixed Effects, No, Occupation Fixed Effects, No)	///
			keep(1.time#1._treated 1.time 1._treated)
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' [fw=_weight], 						vce(cluster time_activity_1) 
			outreg2 using "${outputs}/falsification.xml", $sig 																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, No, Occupation Fixed Effects, No)	///
			keep(1.time#1._treated 1.time 1._treated)		
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4  [fw=_weight], 			vce(cluster time_activity_1) 
			outreg2 using "${outputs}/falsification.xml", $sig 																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, No)	///
			keep(1.time#1._treated 1.time 1._treated)	
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight], 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/falsification.xml", $sig 																			///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
			keep(1.time#1._treated 1.time 1._treated)	
	restore
	
	
	// Table 4: Main Differences in Differences
	
	preserve 
		keep if selfemployment_1 == 1
		keep if time != 0
		
		recode time (1=0) (2=1)
	
		local vars "sex edu area age household_size"
		psmatch2 eligibility_1 `vars', out(ln_real_income_1) com caliper(${caliper}) 
	
		reg ln_real_income_1 time##_treated ib7.main_cat_1 [fw=_weight], 								vce(cluster time_activity_1) 
			outreg2 using "${outputs}/main_did.xml", replace $sig 																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, No, Regional  Fixed Effects, No, Occupation Fixed Effects, No)		///
			keep(1.time#1._treated 1.time 1._treated)
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' [fw=_weight], 						vce(cluster time_activity_1) 
			outreg2 using "${outputs}/main_did.xml", $sig 																				///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, No, Occupation Fixed Effects, No)		///
			keep(1.time#1._treated 1.time 1._treated)		
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4  [fw=_weight], 			vce(cluster time_activity_1) 
			outreg2 using "${outputs}/main_did.xml", $sig 																				///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, No)		///
			keep(1.time#1._treated 1.time 1._treated)	
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight], 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/main_did.xml", $sig 																				///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
			keep(1.time#1._treated 1.time 1._treated)	
			
		// Table 5: DID by Sex
		local vars "sex edu area age household_size"
		forvalues x = 0/1 {
			reg ln_real_income_1 time##_treated ib7.main_cat_1 [fw=_weight] if sex == `x', 									vce(cluster time_activity_1) 
				outreg2 using "${outputs}/main_did_`x'.xml", replace $sig 																		///
				addtext(Primary Activity Fixed Effects, Yes, Controls, No, Regional  Fixed Effects, No, Occupation Fixed Effects, No)			///
				keep(1.time#1._treated 1.time 1._treated)	
			reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' [fw=_weight] if sex == `x', 							vce(cluster time_activity_1) 
				outreg2 using "${outputs}/main_did_`x'.xml", $sig 																				///
				addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, No, Occupation Fixed Effects, No)			///
				keep(1.time#1._treated 1.time 1._treated)			
			reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4  [fw=_weight] if sex == `x',				vce(cluster time_activity_1) 
				outreg2 using "${outputs}/main_did_`x'.xml", $sig 																				///
				addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, No)			///
				keep(1.time#1._treated 1.time 1._treated)	
			reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight] if sex == `x', 		vce(cluster time_activity_1) 
				outreg2 using "${outputs}/main_did_`x'.xml", $sig 																				///
				addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)		///
				keep(1.time#1._treated 1.time 1._treated)	
		}

		// Table 6: DID by education
		gen primary = (edu> 0 & edu<=6) if !missing(edu)
		gen high_school = (edu>6 & edu<=11) if !missing(edu)
		gen more_hs = (edu>=11) if !missing(edu)
		
		local vars "sex edu area age household_size"
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4  [fw=_weight] 			if primary ==1, 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/main_did_educ.xml", $sig replace																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, No, Occupation Fixed Effects, No)			///
			keep(1.time#1._treated 1.time 1._treated)		
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight] if primary ==1, 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/main_did_educ.xml", $sig 																				///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)		///
			keep(1.time#1._treated 1.time 1._treated)			
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4  [fw=_weight] 			if high_school ==1, vce(cluster time_activity_1) 
			outreg2 using "${outputs}/main_did_educ.xml", $sig																			  	///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, No, Occupation Fixed Effects, No)			///
			keep(1.time#1._treated 1.time 1._treated)		
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight] if high_school ==1, vce(cluster time_activity_1) 	
			outreg2 using "${outputs}/main_did_educ.xml", $sig 																				///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)		///
			keep(1.time#1._treated 1.time 1._treated)			
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4  [fw=_weight] 			if more_hs ==1, 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/main_did_educ.xml", $sig																			  	///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, No, Occupation Fixed Effects, No)			///
			keep(1.time#1._treated 1.time 1._treated)				
		reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight] if more_hs ==1, 	vce(cluster time_activity_1)
			outreg2 using "${outputs}/main_did_educ.xml", $sig 																				///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)		///
			keep(1.time#1._treated 1.time 1._treated)	
		
		// By gender
		local vars "sex edu area age household_size"
		local append "replace"
		
		forvalues sex = 0/1 {
			reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight] if primary ==1 & sex == `sex', 	vce(cluster time_activity_1)
				outreg2 using "${outputs}/main_did_educ_sex.xml", $sig 	`append'																///
				addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)		///
				keep(1.time#1._treated 1.time 1._treated)	
			reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight] if high_school ==1 & sex == `sex', 	vce(cluster time_activity_1)
				outreg2 using "${outputs}/main_did_educ_sex.xml", $sig 																			///
				addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)		///
				keep(1.time#1._treated 1.time 1._treated)	
			reg ln_real_income_1 time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight] if more_hs ==1 & sex == `sex', 	vce(cluster time_activity_1)
				outreg2 using "${outputs}/main_did_educ_sex.xml", $sig 																			///
				addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)		///
				keep(1.time#1._treated 1.time 1._treated)
				
			local append "append"
		} 
		
		// Table 7: By Sector
		/*
		recode 	cat_1									///
				(2 6 13/18= 0)							///	
				(1 = 1 "Agriculture and Forestry" )		///
				(3/5 7 = 2 "Manufacture Industry") 		///
				(8 = 3 "Construction") 					///
				(9 10 11 = 4 "Commerce") 				///
				(12 = 5 "Hotels and Restaurants"), 		///
		gen(sector)
		*/
		
		local vars "sex edu area age household_size"
		reg ln_real_income_1 time##sector ib7.main_cat_1 [fw=_weight], 								vce(cluster time_activity_1) 
			outreg2 using "${outputs}/sector.xml", replace $sig 																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, No, Regional  Fixed Effects, No, Occupation Fixed Effects, No)		///
			keep(1.time i.sector 1.time#i.sector)
		reg ln_real_income_1 time##sector ib7.main_cat_1 `vars' [fw=_weight], 						vce(cluster time_activity_1) 
			outreg2 using "${outputs}/sector.xml", $sig 																				///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, No, Occupation Fixed Effects, No)		///
			keep(1.time i.sector 1.time#i.sector)		
		reg ln_real_income_1 time##sector ib7.main_cat_1 `vars' i.dominio4  [fw=_weight], 			vce(cluster time_activity_1) 
			outreg2 using "${outputs}/sector.xml", $sig 																				///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, No)		///
			keep(1.time i.sector 1.time#i.sector)	
		reg ln_real_income_1 time##sector ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight], 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/sector.xml", $sig 																				///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
			keep(1.time i.sector 1.time#i.sector)			
		
		
		// Sector by gender
		local vars "sex edu area age household_size"
		local append "replace"
		forvalues sex = 0/1 {	
			reg ln_real_income_1 time##sector ib7.main_cat_1 `vars' i.dominio4  [fw=_weight] if sex == `sex', 			vce(cluster time_activity_1) 
				outreg2 using "${outputs}/sector_gender.xml", $sig `append'																	///
				addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, No)		///
				keep(1.time i.sector 1.time#i.sector)	
			reg ln_real_income_1 time##sector ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight] if sex == `sex', 	vce(cluster time_activity_1) 
				outreg2 using "${outputs}/sector_gender.xml", $sig 																			///
				addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
				keep(1.time i.sector 1.time#i.sector)			
				
			local append "append"
		}
		
		
		// Table 8: Winsorizing
		winsor2 ln_real_income_1, cuts(1 99) suffix(_win) label
		winsor2 ln_real_income_1, cuts(10 90) suffix(_win2) label
		
		local vars "sex edu area age household_size"
		reg ln_real_income_1_win time##_treated ib7.main_cat_1 `vars' i.dominio4  [fw=_weight], 			vce(cluster time_activity_1) 
			outreg2 using "${outputs}/main_did_win.xml", replace $sig 																	///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, No)		///
			keep(1.time#1._treated 1.time 1._treated)	
		reg ln_real_income_1_win time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight], 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/main_did_win.xml", $sig 																			///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
			keep(1.time#1._treated 1.time 1._treated)	
		reg ln_real_income_1_win2 time##_treated ib7.main_cat_1 `vars' i.dominio4  [fw=_weight], 			vce(cluster time_activity_1) 
			outreg2 using "${outputs}/main_did_win.xml", $sig 																			///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, No)		///
			keep(1.time#1._treated 1.time 1._treated)	
		reg ln_real_income_1_win2 time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight], 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/main_did_win.xml", $sig 																			///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
			keep(1.time#1._treated 1.time 1._treated)			
	
	
		// Figures
		
		// Kernel density
		foreach var of varlist real_income_1 edu age household_size { 
		// With Matching
		kdensity `var' if eligibility_1==1 [fw=_weight], plot(kdensity `var' if eligibility_1==0 [fw=_weight]) legend(label(1 "Eligible") label(2 "Not Eligible") rows(1))
			graph export "${figures}/kernel_`var'.pdf", replace 
			graph export "${figures}/kernel_`var'.png", replace 
		
		// Without matching
		kdensity `var' if eligibility_1==1, plot(kdensity `var' if eligibility_1==0) legend(label(1 "Eligible") label(2 "Not Eligible") rows(1))
			graph export "${figures}/kernelnm_`var'.pdf", replace 
			graph export "${figures}/kernelnm_`var'.png", replace 
		} 		
		
		
		// Bias
		local vars "sex edu area age household_size"		
		pstest `vars' if time!=., t(eligibility_1) mw(_weight) both hist 
			graph export "${figures}/psmatch_hist.png", replace 
		pstest `vars' if time!=., t(eligibility_1) mw(_weight) both hist 			
			graph export "${figures}/psmatch_hist.pdf", replace 
		pstest `vars' if time!=., t(eligibility_1) mw(_weight) both graph 
			graph export "${figures}/psmatch_balance.png", replace 
		pstest `vars' if time!=., t(eligibility_1) mw(_weight) both graph 			
			graph export "${figures}/psmatch_balance.pdf", replace 
		psgraph, bin(20)
			graph export "${figures}/psmatch_bins.png", replace 
		psgraph, bin(20)	
			graph export "${figures}/psmatch_bins.pdf", replace 	
		

	// Other Outcomes	
	gen n_jobs = (!missing(occup_2)) 
	replace n_jobs = 0 if !missing(occup_1) & missing(occup_2)
	
		local vars "sex edu area age household_size"
		reg training time##_treated ib7.main_cat_1 `vars' i.dominio4  [fw=_weight], 			vce(cluster time_activity_1) 
			outreg2 using "${outputs}/other_outcomes.xml", replace $sig 																///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, No)		///
			keep(1.time#1._treated 1.time 1._treated)	
		reg training time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight], 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/other_outcomes.xml", $sig 																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
			keep(1.time#1._treated 1.time 1._treated)	
		reg hours time##_treated ib7.main_cat_1 `vars' i.dominio4  [fw=_weight], 			vce(cluster time_activity_1) 
			outreg2 using "${outputs}/other_outcomes.xml", $sig 																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, No)		///
			keep(1.time#1._treated 1.time 1._treated)	
		reg hours time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight], 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/other_outcomes.xml", $sig 																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
			keep(1.time#1._treated 1.time 1._treated)		
		reg working_months_1 time##_treated ib7.main_cat_1 `vars' i.dominio4  [fw=_weight], 			vce(cluster time_activity_1) 
			outreg2 using "${outputs}/other_outcomes.xml", $sig 																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, No)		///
			keep(1.time#1._treated 1.time 1._treated)	
		reg working_months_1 time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight], 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/other_outcomes.xml", $sig 																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
			keep(1.time#1._treated 1.time 1._treated)		
		reg n_jobs time##_treated ib7.main_cat_1 `vars' i.dominio4  [fw=_weight], 			vce(cluster time_activity_1) 
			outreg2 using "${outputs}/other_outcomes.xml", $sig 																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, No)		///
			keep(1.time#1._treated 1.time 1._treated)	
		reg n_jobs time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight], 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/other_outcomes.xml", $sig 																		///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
			keep(1.time#1._treated 1.time 1._treated)				
			
		
	// Other outcomes by sex
	local vars "sex edu area age household_size"	
	local append "replace"
	forvalues sex = 0/1 {
		reg training time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight] if sex == `sex', 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/other_outcomes_sex.xml", $sig  `append'															///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
			keep(1.time#1._treated 1.time 1._treated)	
		reg hours time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight] if sex == `sex', 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/other_outcomes_sex.xml", $sig 																	///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
			keep(1.time#1._treated 1.time 1._treated)					
		reg working_months_1 time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight] if sex == `sex', 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/other_outcomes_sex.xml", $sig 																	///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
			keep(1.time#1._treated 1.time 1._treated)			
		reg n_jobs time##_treated ib7.main_cat_1 `vars' i.dominio4 i.occup_1 [fw=_weight] if sex == `sex', 	vce(cluster time_activity_1) 
			outreg2 using "${outputs}/other_outcomes_sex.xml", $sig 																	///
			addtext(Primary Activity Fixed Effects, Yes, Controls, Yes, Regional  Fixed Effects, Yes, Occupation Fixed Effects, Yes)	///
			keep(1.time#1._treated 1.time 1._treated)
			
		local append "append"
	} 
	
		// T-TEST (Balance)
		*	Unmatched Sample
		*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		local append "replace"
		foreach x of var sex edu area age household_size {
			eststo ttest1_`x': qui reg `x' if time==0 & eligibility_1==1 					/* Eligible */ 
			eststo ttest0_`x': qui reg `x' if time==0 & eligibility_1==0 					/* Not Eligible */ 
			eststo ttestc_`x': qui reg `x' eligibility_1 if time==0 						/* Combined */ 

			#delimit ; 
			esttab using "${outputs}/ttest.csv", `append' 
			se(2) nonumbers noobs label mtitle("eligle" "not eligible" "diff") nonotes; 
			#delimit cr 
			
			local append "append"
			est clear 
		}

		*	Matched Sample
		*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		local append "replace"
		
		foreach x of var sex edu age area household_size{
			eststo ttest1m_`x': qui reg `x' [fw=_weight] if time==0 & eligibility_1==1 	/* Eligible */ 
			eststo ttest0m_`x': qui reg `x' [fw=_weight] if time==0 & eligibility_1==0 	/* Not Eligible */ 
			eststo ttestcm_`x': qui reg `x' eligibility_1 [fw=_weight] if time==0 		/* Combined */ 

			#delimit ; 
			esttab using "${outputs}/ttest_matched.csv", `append' 
			se(2) nonumbers noobs label mtitle("eligle" "not eligible" "diff") nonotes; 
			#delimit cr 
			local append "append" 
			est clear 
		}
		
	restore 		