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
	
	global stars1	"label nolines nogaps fragment nomtitle nonumbers noobs nodep star(* 0.10 ** 0.05 *** 0.01) collabels(none) booktabs"
	global stars2	"label nolines nogaps fragment nomtitle nonumbers nodep star(* 0.10 ** 0.05 *** 0.01) collabels(none) booktabs r2"	
	global caliper = 0.01
	
	//	Table 1: Summary Statistics
	local 	vars				///	
			sex 				///
			edu 				///
			area 				///
			age 				///
			household_size 		///
			real_income_1 		///
			ln_real_income_1 	///
			eligibility_1
		
	label var real_income_1		"Real income"
	label var ln_real_income_1 	"Log of real income"
	label var eligibility_1		"Eligibility (\%)"
	
	eststo clear 
	estpost sum `vars' if selfemployment_1 == 1
	
	esttab 	using "${outputs}/desc_stats/tables/summ_stats_pooled.tex", replace					///	
			cells("count(fmt(%9.0fc)) mean(fmt(%9.2fc)) sd(fmt(%9.2fc)) min max") ${stars1}
			
			
	// Summ stats per year	
	local years "2005 2009 2014"
	foreach y in `years' {
		eststo clear 
		estpost sum `vars' if selfemployment_1 == 1 & year == `y'
		
		esttab 	using "${outputs}/desc_stats/tables/summ_stats_`y'.tex", replace			///	
				cells("count(fmt(%9.0fc)) mean(fmt(%9.2fc)) sd(fmt(%9.2fc)) min max") ${stars1}
	}
	
	
	// Table 2: Parallel Trends Assumption Test
	preserve 
		keep if selfemployment_1 == 1 
		keep if time != 2

		local vars "sex edu area age household_size"
		psmatch2 eligibility_1 `vars', out(ln_real_income_1) com caliper(${caliper}) 

		label define _treated 	1"Eligibility" 0"Non", 	modify 
		label define time 		0"Pre" 1"Post", 		modify
		label values _treated _treated 
		label values time time 
		
		eststo clear 
		eststo: reghdfe ln_real_income_1 time##_treated [fw=_weight], 		 absorb(main_cat_1) 					vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight], absorb(main_cat_1) 					vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight], absorb(main_cat_1 dominio4) 			vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight], absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		

		esttab 	using "${outputs}/desc_stats/tables/parallel_trends.tex", replace ${stars2}	///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)
	restore 
	
	// Table 3: Falsification Test
	preserve 
		keep if employed_1 == 1 
		recode time (1=0) (2=1)
		
		local vars "sex edu area age household_size"
		psmatch2 eligibility_1 `vars', out(ln_real_income_1) com caliper(${caliper}) 

		label define _treated 	1"Eligibility" 0"Non", 	modify 
		label define time 		0"Pre" 1"Post", 		modify
		label values _treated _treated 
		label values time time 
		
		eststo clear 
		eststo: reghdfe ln_real_income_1 time##_treated [fw=_weight], 		 absorb(main_cat_1) 					vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight], absorb(main_cat_1) 					vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight], absorb(main_cat_1 dominio4) 			vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight], absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		

		esttab 	using "${outputs}/desc_stats/tables/falsification.tex", replace ${stars2}	///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)
	restore
	
	
	// Table 4: Main Differences in Differences
	
	preserve 
		keep if selfemployment_1 == 1
		keep if time != 0
		
		recode time (1=0) (2=1)
	
		local vars "sex edu area age household_size"
		psmatch2 eligibility_1 `vars', out(ln_real_income_1) com caliper(${caliper}) 
		
		label define _treated 	1"Eligibility" 0"Non", 	modify 
		label define time 		0"Pre" 1"Post", 		modify
		label values _treated _treated 
		label values time time 		
	
		eststo clear 
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight], 			 absorb(main_cat_1 dominio4) 			vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight], 			 absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if sex == 0, absorb(main_cat_1 dominio4) 			vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if sex == 1, absorb(main_cat_1 dominio4) 			vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)		
		
		esttab 	using "${outputs}/desc_stats/tables/main_did_gender.tex", replace ${stars2}				///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)		
			

		// Table 6: DID by education
		gen primary = (edu> 0 & edu<=6) 	if !missing(edu)
		gen high_school = (edu>6 & edu<=11) if !missing(edu)
		gen more_hs = (edu>=11) 			if !missing(edu)
		
		local vars "sex edu area age household_size"
		eststo clear 		
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if primary == 1, 				absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if primary == 1 & sex == 0,	 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if primary == 1 & sex == 1, 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if high_school == 1, 			absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if high_school == 1 & sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if high_school == 1 & sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if more_hs == 1, 				absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if more_hs == 1 & sex == 0, 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if more_hs == 1 & sex == 1, 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)	
		
		esttab 	using "${outputs}/desc_stats/tables/main_did_educ.tex", replace ${stars2}				///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)			
		
	
		// Table 7: By Sector
		recode 	cat_1									///
				(2 6 13/18= 0)							///	
				(1 = 1 "Agriculture and Forestry" )		///
				(3/5 7 = 2 "Manufacture Industry") 		///
				(8 = 3 "Construction") 					///
				(9 10 11 = 4 "Commerce") 				///
				(12 = 5 "Hotels and Restaurants"), 		///
		gen(sector)
		
		local vars "sex edu area age household_size"
		eststo clear 		
		eststo: reghdfe ln_real_income_1 time##sector `vars' [fw=_weight], 				absorb(dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##sector `vars' [fw=_weight] if sex == 0,  absorb(dominio4 occup_1) 	vce(cluster time_activity_1)		
		eststo: reghdfe ln_real_income_1 time##sector `vars' [fw=_weight] if sex == 1,  absorb(dominio4 occup_1) 	vce(cluster time_activity_1)		
		
		esttab 	using "${outputs}/desc_stats/tables/main_did_sector.tex", replace ${stars2}				///
				keep(1.time 1.sector 2.sector 3.sector 4.sector 5.sector 1.time#1.sector 1.time#2.sector 1.time#3.sector 1.time#4.sector 1.time#5.sector) ///
				order(1.time#1.sector 1.time#2.sector 1.time#3.sector 1.time#4.sector 1.time#5.sector 1.time 1.sector 2.sector 3.sector 4.sector 5.sector) ///
				
		// Table 8: Winsorizing
		winsor2 ln_real_income_1, cuts(1 99) suffix(_win) label
		winsor2 ln_real_income_1, cuts(10 90) suffix(_win2) label
		
		local vars "sex edu area age household_size"
		eststo clear 
		eststo: reghdfe ln_real_income_1_win  time##_treated `vars' [fw=_weight], 			  absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1_win  time##_treated `vars' [fw=_weight] if sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1_win  time##_treated `vars' [fw=_weight] if sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1_win2 time##_treated `vars' [fw=_weight], 			  absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1_win2 time##_treated `vars' [fw=_weight] if sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1_win2 time##_treated `vars' [fw=_weight] if sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)		
		
		esttab 	using "${outputs}/desc_stats/tables/main_did_gender_win.tex", replace ${stars2}				///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)	

		
		
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
		eststo clear 	
		eststo: reghdfe training 			time##_treated `vars' [fw=_weight], absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe hours 				time##_treated `vars' [fw=_weight], absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe working_months_1 	time##_treated `vars' [fw=_weight], absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe n_jobs				time##_treated `vars' [fw=_weight], absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)

		esttab 	using "${outputs}/desc_stats/tables/main_did_other_outcomes.tex", replace ${stars2}				///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)
				
		eststo clear 	
		eststo: reghdfe training 			time##_treated `vars' [fw=_weight] if sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe hours 				time##_treated `vars' [fw=_weight] if sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe working_months_1 	time##_treated `vars' [fw=_weight] if sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe n_jobs				time##_treated `vars' [fw=_weight] if sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)

		esttab 	using "${outputs}/desc_stats/tables/main_did_other_outcomes_females.tex", replace ${stars2}				///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)				

		eststo clear 	
		eststo: reghdfe training 			time##_treated `vars' [fw=_weight] if sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe hours 				time##_treated `vars' [fw=_weight] if sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe working_months_1 	time##_treated `vars' [fw=_weight] if sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe n_jobs				time##_treated `vars' [fw=_weight] if sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)

		esttab 	using "${outputs}/desc_stats/tables/main_did_other_outcomes_males.tex", replace ${stars2}				///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)					
		
		
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