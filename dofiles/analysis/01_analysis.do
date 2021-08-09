/********************************************************************************
* PROJECT:	Self-Employment - Nicaragua                                 
* TITLE: 	Analysis do file
* YEAR:		2021
*********************************************************************************
	
*** Outline:
	1. Load Data
	2. Tables
		2.1 Table 1: Summary Statistics
		2.2 	Table 3: Parallel Trends Assumption Test
		2.3 	Table 6: Falsification Test
		2.4 	Table 4: Main Differences in Differences
		2.5 	Table 5: DID by education
		2.6 	Table 7: Possible mechanisms for the SBFE program impact
		2.7		Table 2: Test for equality of means for the pre-intervention variables (2009 LSMS)
	3. Figures
		3.1 Kernel density
		3.2 Bias

*** Requires:
	1. emnv_cuaen_eligibility

*** Outputs: 
	1. Tables and figures (LaTeX)
	
*********************************************************************************
*	PART 1: Load Data
********************************************************************************/

*** Load dataset 
	use "${data_int}/emnv_cuaen_eligibility.dta", clear 
	
*********************************************************************************
*	PART 2: Tables
********************************************************************************/
	
***	2.1 	Table 1: Summary Statistics
	local 	vars				///	
          sex 				///
          age					///
          household_size		///
          edu					      ///
          area				      ///
          real_income_1		  ///
          eligibility_1 
        
	label var sex				        "Gender"
	label var real_income_1		  "Real income"
	label var ln_real_income_1 	"Log of real income"
	label var eligibility_1		  "Eligibility (\%)"
	
	// Esttab export
	eststo clear 
	estpost sum `vars' if selfemployment_1 == 1
	
	esttab 	using "${tables}/summ_stats_pooled.tex", replace					///	
			cells("count(fmt(%9.0fc)) mean(fmt(2 1 2 2 2 %9.0fc 2)) sd(fmt(2 1 2 2 2 %9.0fc 2)) min max") ${stars1}
			
	//  Per year	
	local years "2005 2009 2014"
	foreach y in `years' {
		eststo clear 
		estpost sum `vars' if selfemployment_1 == 1 & year == `y'
		
		esttab 	using "${tables}/summ_stats_`y'.tex", replace			///	
			cells("count(fmt(%9.0fc)) mean(fmt(2 1 2 2 2 %9.0fc 2)) sd(fmt(2 1 2 2 2 %9.0fc 2)) min max") ${stars1}
	}
  
  
  // NEW: Training information
  local   vars      ///
          training  ///
          training_nocost
  
  eststo clear
  estpost sum `vars' if selfemployment_1 == 1
  esttab 	using "${tables}/summ_stats_pooled_se.tex", replace					///	
			cells("count(fmt(%9.0fc)) mean(fmt(%9.2fc)) sd(fmt(%9.2fc)) min max sum") ${stars1}

	foreach y in `years' {
		eststo clear 
		estpost sum `vars' if selfemployment_1 == 1 & year == `y'
		
		esttab 	using "${tables}/summ_stats_`y'_se.tex", replace			///	
			cells("count(fmt(%9.0fc)) mean(fmt(%9.2fc)) sd(fmt(%9.2fc)) min max sum") ${stars1}
	}
  
  // NEW: Training information by gender
  eststo clear
  forvalues x = 0/1 {
    estpost sum `vars' if selfemployment_1 == 1 & sex == `x'
    esttab 	using "${tables}/summ_stats_pooled_se_`x'.tex", replace					///	
			cells("count(fmt(%9.0fc)) mean(fmt(%9.2fc)) sd(fmt(%9.2fc)) min max sum") ${stars1}
  
    foreach y in `years' {
      eststo clear 
      estpost sum `vars' if selfemployment_1 == 1 & year == `y' & sex == `x'
      
      esttab 	using "${tables}/summ_stats_`y'_se_`x'.tex", replace			///	
        cells("count(fmt(%9.0fc)) mean(fmt(%9.2fc)) sd(fmt(%9.2fc)) min max sum") ${stars1}
    }  
  }
    
*** 2.2 	Table 3: Parallel Trends Assumption Test
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
		eststo: reghdfe ln_real_income_1 time##_treated [fw=_weight], 		 noabsorb 								vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight], noabsorb 								vce(cluster time_activity_1)		
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight], absorb(dominio4) 						vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight], absorb(dominio4 occup_1) 				vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight], absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)
		

		esttab 	using "${tables}/parallel_trends.tex", replace ${stars2}	///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)										
	restore 
	
*** 2.3 	Table 6: Falsification Test by education only paid employed workers
	preserve 
		keep if employed_1 == 1 
		recode time (1=0) (2=1)
		
		local vars "sex edu area age household_size"
		psmatch2 eligibility_1 `vars', out(ln_real_income_1) com caliper(${caliper}) 

		label define _treated 	1"Eligibility" 0"Non", 	modify 
		label define time 		0"Pre" 1"Post", 		modify
		label values _treated _treated 
		label values time time 
						
		// Generate education variables
		gen primary 	= (edu> 0 & edu<=6) 	if !missing(edu)
		gen high_school = (edu> 6 & edu<=11)	if !missing(edu)
		gen more_hs 	= (edu>=11) 			if !missing(edu)
		
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
		
		esttab 	using "${tables}/main_did_educ_falsification.tex", replace ${stars2}					///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)				
	restore
	
*** 2.4 	Table 4: Main Differences in Differences
	preserve 
		keep if selfemployment_1 == 1
		keep if time != 0
		
		recode time (1=0) (2=1)
	
		local vars "sex edu area age household_size"
		psmatch2 eligibility_1 `vars', out(ln_real_income_1) com caliper(${caliper}) 
		
		label define _treated 	1"Eligibility" 0"Non", 	modify 
		label define time 		  0"Pre" 1"Post", 		modify
		label values _treated _treated 
		label values time time 

		eststo clear 
		eststo: reghdfe ln_real_income_1 time##_treated [fw=_weight], 		 			    noabsorb 								    vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight], 			  absorb(dominio4) 						vce(cluster time_activity_1)		
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight], 			  absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated [fw=_weight]        if sex == 0,   noabsorb 					  vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if sex == 0, absorb(dominio4) 			vce(cluster time_activity_1)		
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if sex == 0, absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated [fw=_weight] 		    if sex == 1, noabsorb 							vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if sex == 1, absorb(dominio4) 			vce(cluster time_activity_1)		
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if sex == 1, absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)		
				
		// Esttab export
		esttab 	using "${tables}/main_did_gender.tex", replace ${stars2}				///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)		
		      
		*** 2.5 	Table 5: DID by education
		gen primary 	= (edu> 0 & edu<=6) 	if !missing(edu)
		gen high_school = (edu> 6 & edu<=11)	if !missing(edu)
		gen more_hs 	= (edu>=11) 			if !missing(edu)
		
		local vars "sex edu area age household_size"
		eststo clear 		
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if primary == 1, 				      absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if primary == 1 & sex == 0,	 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if primary == 1 & sex == 1, 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if high_school == 1, 			    absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if high_school == 1 & sex == 0, absorb(main_cat_1 dominio4 occup_1) vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if high_school == 1 & sex == 1, absorb(main_cat_1 dominio4 occup_1) vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if more_hs == 1, 				      absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if more_hs == 1 & sex == 0, 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if more_hs == 1 & sex == 1, 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)	
		
		esttab 	using "${tables}/main_did_educ.tex", replace ${stars2}				///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)			
					
          
 
    // NEW INTERACTION WITH AGE ANG AGE CATEGORIES  
    	
    // NEW AGE CAT VARIABLE
    drop if age < 14
    recode age (14/25 = 1) (26/40 = 2) (40/60 = 3) (else = 4), gen(age_cat)
    label define age_cat 1"14-25" 2"26-40" 3"40-60" 4"61+", modify
    label values age_cat age_cat 
    label var age_cat "Age categories"
        
        
    eststo clear
    
    local vars "sex edu area age household_size"
    eststo: reghdfe ln_real_income_1 time##_treated##ib4.age_cat `vars' [fw=_weight],                                 absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1) 
    eststo: reghdfe ln_real_income_1 time##_treated##ib4.age_cat `vars' [fw=_weight] if sex == 0,                     absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1) 
    eststo: reghdfe ln_real_income_1 time##_treated##ib4.age_cat `vars' [fw=_weight] if sex == 1,                     absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1) 
    eststo: reghdfe ln_real_income_1 time##_treated##ib4.age_cat `vars' [fw=_weight] if primary == 1,                 absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1) 
    eststo: reghdfe ln_real_income_1 time##_treated##ib4.age_cat `vars' [fw=_weight] if primary == 1 & sex == 0,      absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1) 
    eststo: reghdfe ln_real_income_1 time##_treated##ib4.age_cat `vars' [fw=_weight] if primary == 1 & sex == 1,      absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)         
    eststo: reghdfe ln_real_income_1 time##_treated##ib4.age_cat `vars' [fw=_weight] if high_school == 1,             absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1) 
    eststo: reghdfe ln_real_income_1 time##_treated##ib4.age_cat `vars' [fw=_weight] if high_school == 1 & sex == 0,  absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1) 
    eststo: reghdfe ln_real_income_1 time##_treated##ib4.age_cat `vars' [fw=_weight] if high_school == 1 & sex == 1,  absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1) 
    
		esttab 	using "${tables}/main_did_gender_age.tex", replace ${stars2}				///
				keep(1.time 1._treated 1.time#1._treated 1.age_cat 2.age_cat 3.age_cat 1.time#1._treated#1.age_cat 1.time#1._treated#2.age_cat 1.time#1._treated#3.age_cat) ///
        order(1.time#1._treated 1.time 1._treated)		
                  
          
  // NEW INTERACTION WITH AGE ANG AGE CATEGORIES        
    eststo clear
  
    local vars "sex edu area age household_size"
    eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if age_cat == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)         
    eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if age_cat == 2, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)    
    eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if age_cat == 3, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)        
    eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if age_cat == 4, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)    
    eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if age_cat == 1 & sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)         
    eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if age_cat == 2 & sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)    
    eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if age_cat == 3 & sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)        
    eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if age_cat == 4 & sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)    
    eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if age_cat == 1 & sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)         
    eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if age_cat == 2 & sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)    
    eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if age_cat == 3 & sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)        
    eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if age_cat == 4 & sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)    
          
    esttab 	using "${tables}/main_did_gender_age_cat.tex", replace ${stars2}				///
      keep(1.time 1._treated 1.time#1._treated)                                 ///
      order(1.time#1._treated 1.time 1._treated)		     
          
          
   // NEW INTERACTION WITH AGE ANG AGE CATEGORIES        
    local vars "sex edu area age household_size"
    foreach var of varlist primary high_school {
      eststo clear
      
      eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if `var' == 1 & age_cat == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)         
      eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if `var' == 1 & age_cat == 2, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)    
      eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if `var' == 1 & age_cat == 3, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)        
      eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if `var' == 1 & age_cat == 4, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)    
      eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if `var' == 1 & age_cat == 1 & sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)         
      eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if `var' == 1 & age_cat == 2 & sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)    
      eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if `var' == 1 & age_cat == 3 & sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)        
      eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if `var' == 1 & age_cat == 4 & sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)    
      eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if `var' == 1 & age_cat == 1 & sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)         
      eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if `var' == 1 & age_cat == 2 & sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)    
      eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if `var' == 1 & age_cat == 3 & sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)        
      eststo: reghdfe ln_real_income_1 time##_treated `vars' [fw=_weight] if `var' == 1 & age_cat == 4 & sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)    
            
      esttab 	using "${tables}/main_did_gender_`var'_age_cat.tex", replace ${stars2}				///
        keep(1.time 1._treated 1.time#1._treated)                                 ///
        order(1.time#1._treated 1.time 1._treated)		                
    }
          
          
          
          
          
          
          
          
          
		*** 2.6 	Table 7: Possible mechanisms for the SBFE program impact	
		gen n_jobs = (!missing(occup_2)) 
		replace n_jobs = 0 if !missing(occup_1) & missing(occup_2)
	
		local vars "sex edu area age household_size"
		eststo clear 	
		eststo: reghdfe training 			time##_treated `vars' [fw=_weight], absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum training if e(sample) == 1
			estadd scalar mean = r(mean)
		eststo: reghdfe hours 				time##_treated `vars' [fw=_weight], absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum hours if e(sample) == 1
			estadd scalar mean = r(mean)		
		eststo: reghdfe working_months_1 	time##_treated `vars' [fw=_weight], absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum working_months_1 if e(sample) == 1
			estadd scalar mean = r(mean)		
		eststo: reghdfe n_jobs				time##_treated `vars' [fw=_weight], absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum n_jobs if e(sample) == 1
			estadd scalar mean = r(mean)		

		esttab 	using "${tables}/main_did_other_outcomes.tex", replace ${stars2}								///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)			///
				stat(mean, labels("Mean dependent variable"))	
				
		eststo clear 	
		eststo: reghdfe training 			time##_treated `vars' [fw=_weight] if sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum training 	if e(sample) == 1 & sex == 0
			estadd scalar mean = r(mean)
		eststo: reghdfe hours 				time##_treated `vars' [fw=_weight] if sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum hours 		if e(sample) == 1 & sex == 0
			estadd scalar mean = r(mean)
		eststo: reghdfe working_months_1 	time##_treated `vars' [fw=_weight] if sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum working_months_1 if e(sample) == 1 & sex == 0
			estadd scalar mean = r(mean)
		eststo: reghdfe n_jobs				time##_treated `vars' [fw=_weight] if sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum n_jobs if e(sample) == 1 & sex == 0
			estadd scalar mean = r(mean)
			
		esttab 	using "${tables}/main_did_other_outcomes_females.tex", replace ${stars2}						///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)			///
				stat(mean, labels("Mean dependent variable"))				

		eststo clear 	
		eststo: reghdfe training 			time##_treated `vars' [fw=_weight] if sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum training 	if e(sample) == 1 & sex == 1
			estadd scalar mean = r(mean)
		eststo: reghdfe hours 				time##_treated `vars' [fw=_weight] if sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum hours 		if e(sample) == 1 & sex == 1
			estadd scalar mean = r(mean)
		eststo: reghdfe working_months_1 	time##_treated `vars' [fw=_weight] if sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum working_months_1 if e(sample) == 1 & sex == 1
			estadd scalar mean = r(mean)
		eststo: reghdfe n_jobs				time##_treated `vars' [fw=_weight] if sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum n_jobs 		if e(sample) == 1 & sex == 1
			estadd scalar mean = r(mean)

		esttab 	using "${tables}/main_did_other_outcomes_males.tex", replace ${stars2}							///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)			///
				stat(mean, labels("Mean dependent variable"))					
			
		*** 2.7		Table 2: Test for equality of means for the pre-intervention variables (2009 LSMS)
		* ~~~~~~~~~~
		* Un-matched
		* ~~~~~~~~~~
		
		// Covariates
		local 	vars				///	
				sex 				///
				age					///
				household_size		///
				edu					///
				area
		
		eststo clear 
		tvsc `vars' if time == 0, by(eligibility_1) clus_id(time_activity_1) strat_id(main_cat_1)
		esttab using "${tables}/balance_cov.tex", replace ${stars1}		///
			cells("mu_2(fmt(%9.2fc)) mu_1(fmt(%9.2fc)) mu_3(fmt(%9.2fc) star pvalue(d_p))" "se_2(par) se_1(par) se_3(par)") 
		
		// Income
		label var real_income_1 "Real Income"
		
		eststo clear 		
		tvsc real_income_1 if time == 0, by(eligibility_1) clus_id(time_activity_1) strat_id(main_cat_1)	
		esttab using "${tables}/balance_out.tex", replace ${stars1}		///
			cells("mu_2(fmt(%9.2fc)) mu_1(fmt(%9.2fc)) mu_3(fmt(%9.2fc) star pvalue(d_p))" "se_2(par) se_1(par) se_3(par)") 	
		
		* ~~~~~~~~~~
		* Matched
		* ~~~~~~~~~~
		eststo clear 
		tvsc `vars' if time == 0 [fw=_weight], by(_treated) clus_id(time_activity_1) strat_id(main_cat_1)
		esttab using "${tables}/balance_cov_matched.tex", replace ${stars1}		///
			cells("mu_2(fmt(%9.2fc)) mu_1(fmt(%9.2fc)) mu_3(fmt(%9.2fc) star pvalue(d_p))" "se_2(par) se_1(par) se_3(par)") 	
		
		eststo clear 
		tvsc real_income_1 if time == 0 [fw=_weight], by(_treated) clus_id(time_activity_1) strat_id(main_cat_1)
		esttab using "${tables}/balance_out_matched.tex", replace ${stars1}		///
			cells("mu_2(fmt(%9.2fc)) mu_1(fmt(%9.2fc)) mu_3(fmt(%9.2fc) star pvalue(d_p))" "se_2(par) se_1(par) se_3(par)")				 
			
			
			
		*********************************************************************************
		*	PART 3: Figures
		********************************************************************************/
		
		*** 3.1 Kernel density
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
		
		// 3.2 Bias 
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
			
	restore
	
	
	
	