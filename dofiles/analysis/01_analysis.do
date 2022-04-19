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
	
  set seed 78123564
      
*********************************************************************************
*	PART 2: Tables
********************************************************************************/
	
***	2.1 	Table 1: Summary Statistics    
	local vars			      ///	
        sex 				    ///
        age				      ///
        household_size	///
        edu				      ///
        area				    ///
        real_income_1		///
        training        ///
        eligibility_1 
        
	label var sex				        "Gender"
	label var real_income_1		  "Real income"
	label var ln_real_income_1 	"Log of real income"
	label var eligibility_1		  "Eligibility (\%)"
  label var selfemployment_1  "Self employed"
	
	// Esttab export
	eststo clear 
	estpost sum `vars' if selfemployment_1 == 1
	
	esttab 	using "${tables}/summ_stats_pooled.tex", replace					///	
			cells("count(fmt(%9.0fc)) mean(fmt(2 1 2 2 2 %9.0fc 2)) sd(fmt(2 1 2 2 2 %9.0fc 2)) min max") ${stars1}
			
	//  Per year	
	local years "2005 2009 2014"
	foreach y in `years' {
		eststo clear 
		estpost sum `vars' if year == `y' & selfemployment_1 == 1
		
		esttab 	using "${tables}/summ_stats_`y'.tex", replace			///	
			cells("count(fmt(%9.0fc)) mean(fmt(2 1 2 2 2 %9.0fc 2)) sd(fmt(2 1 2 2 2 %9.0fc 2)) min max") ${stars1}
	}
  
* get list of binary vars
	local balance_vars		///	
        sex 				    ///
        age				      ///
        household_size	///
        edu				      ///
        area				    ///
        real_income_1		///
        training        ///
        eligibility_1 

  * Local with variable labels
    foreach v of local balance_vars {
      local varlab_`v' : variable label `v'
    }
    
    sum `balance_vars'
    local binary = "" 
    local continuous = ""
    
    foreach v of varlist `balance_vars' {
      sum `v'
      if (`r(min)'==0 & `r(max)'==1) {
        local binary = "`binary' `v'"
      }
      else if !(`r(min)'==0 & `r(max)'==1) {
        local continuous = "`continuous' `v'"
      }
    }
    
  foreach var of varlist selfemployment_1 employed_1 {          
    preserve
      * Balance tables
        iebaltab `balance_vars' if `var' == 1, ///
          grpvar(year)                                    ///
          browse rowvarlabels                             ///
          tblnonote format(%9.2f) std pt starsnoadd total
          
        tempfile x
        rename * y*
        save `x'
        
      * Clean table
        egen x = fill( 0 1 0 1)
        replace x = . if _n <= 3
        foreach v of varlist yv3 yv5 yv7 yv9 {
          gen x`v' = `v'[_n+1] if x==1
          order x`v', after(`v')
        }
        
        drop if yv1 == "" & !missing(x)
        drop x
        
        qui foreach v of varlist x* {
          replace `v'=subinstr(`v',"[","(",.)
          replace `v'=subinstr(`v',"]",")",.)	
        }
        
      * Remove parentheses for dummies
        foreach v of local binary {
          foreach w of varlist yv3 yv5 yv7 yv9 {
            replace x`w' = "" if yv1 == "`varlab_`v''"
          }
        }	 
        foreach v of local continuous {
          foreach w of varlist yv3 yv5 yv7 yv9 {
            replace `w'=`w' + " " + x`w' if yv1 == "`varlab_`v''"
          }
        }
        
      * Drop cols and rows that we don't need  
        drop x* yv10-yv12
        order yv8 yv9, after(yv1)
        drop if _n < 4
        
      * Add \\ and escapes
        foreach v of varlist yv1-yv6 {
          replace `v' = `v' + " &"
        }
        
        replace yv7 = yv7 + " \\ "

    * Export to LaTeX
      outsheet using "${tables}/tab1_summary_`var'.tex", noquote nonames replace  
    restore 
  }
    
  
*** 2.2 	Table 3: Parallel Trends Assumption Test
	preserve 
		keep if selfemployment_1 == 1 
		keep if time != 2

    // Generate education variables
    gen primary 	  = (edu> 0 & edu<=6) 	    if !missing(edu)
		gen high_school = (edu> 6 & edu<=11)	    if !missing(edu)
		gen more_hs 	  = (edu>=11) 			        if !missing(edu)
        
		local vars "sex area age household_size primary high_school more_hs"
		psmatch2 eligibility_1 `vars', out(ln_real_income_1) ${psmatch}

		label define _treated 	1"Eligibility" 0"Non", 	modify 
		label define time 		  0"Pre" 1"Post", 		modify
		label values _treated _treated 
		label values time time 
		
		eststo clear 
    local vars "sex edu area age household_size"
		eststo: reghdfe ln_real_income_1 time##_treated        ${weights}, noabsorb 								  vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights}, noabsorb 								  vce(cluster time_activity_1)		
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights}, absorb(dominio4) 					vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights}, absorb(dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights}, absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)
		
		esttab 	using "${tables}/parallel_trends.tex", replace ${stars2}	///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)						
				
    // 9 Columns
    eststo clear 
    local vars "sex edu area age household_size"
		eststo: reghdfe ln_real_income_1 time##_treated         ${weights}, noabsorb 								            vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights}, absorb(dominio4) 						        vce(cluster time_activity_1)		
		eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights}, absorb(dominio4 occup_1 main_cat_1) vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated         ${weights} if sex == 0,   noabsorb 					    vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights} if sex == 0, absorb(dominio4) 			  vce(cluster time_activity_1)		
		eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights} if sex == 0, absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated         ${weights} if sex == 1, noabsorb 							  vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights} if sex == 1, absorb(dominio4) 			  vce(cluster time_activity_1)		
		eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights} if sex == 1, absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)		
				
		// Esttab export
		esttab 	using "${tables}/parallel_trends_full.tex", replace ${stars2}				///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)		
	restore 
	
*** 2.3 	Table 6: Falsification Test by education only paid employed workers
	preserve 
    keep if employed_1 == 1 
		recode time (1=0) (2=1)
		    
    // Generate education variables
    gen primary 	  = (edu> 0 & edu<=6) 	    if !missing(edu)
		gen high_school = (edu> 6 & edu<=11)	    if !missing(edu)
		gen more_hs 	  = (edu>=11) 			        if !missing(edu)
    
		local vars "sex area age household_size primary high_school more_hs"
		psmatch2 eligibility_1 `vars', out(ln_real_income_1) ${psmatch}

		label define _treated 	1"Eligibility" 0"Non", 	modify 
		label define time 		0"Pre" 1"Post", 		modify
		label values _treated _treated 
		label values time time 
						
		local vars "sex edu area age household_size"
		eststo clear 		
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if primary == 1, 				absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if primary == 1 & sex == 0,	 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if primary == 1 & sex == 1, 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if high_school == 1, 			absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if high_school == 1 & sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if high_school == 1 & sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if more_hs == 1, 				absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if more_hs == 1 & sex == 0, 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if more_hs == 1 & sex == 1, 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)	
		
		esttab 	using "${tables}/main_did_educ_falsification.tex", replace ${stars2}					///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)				
	restore
	
*** 2.4 	Table 4: Main Differences in Differences
	preserve 
		keep if selfemployment_1 == 1
		keep if time != 0
		
		recode time (1=0) (2=1)
    
    // Generate education variables
    gen primary 	  = (edu> 0 & edu<=6) 	    if !missing(edu)
		gen high_school = (edu> 6 & edu<=11)	    if !missing(edu)
		gen more_hs 	  = (edu>=11) 			        if !missing(edu)
        
    label var primary       "Primary completed or less"
    label var high_school   "Secondary completed or less"        
    label var more_hs       "Above secondary school"
        
		local vars "sex area age household_size primary high_school more_hs"
		psmatch2 eligibility_1 `vars', out(ln_real_income_1) ${psmatch}
		
		label define _treated 	1"Eligibility" 0"Non", 	modify 
		label define time 		  0"Pre" 1"Post", 		modify
		label values _treated _treated 
		label values time time 

		eststo clear 
    local vars "sex edu area age household_size"
		eststo: reghdfe ln_real_income_1 time##_treated         ${weights}, 	noabsorb 								            vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights}, absorb(dominio4) 						        vce(cluster time_activity_1)		
		eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights}, absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated         ${weights} if sex == 0,   noabsorb 					    vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights} if sex == 0, absorb(dominio4) 			  vce(cluster time_activity_1)		
		eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights} if sex == 0, absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated         ${weights} if sex == 1, noabsorb 							  vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights} if sex == 1, absorb(dominio4) 			  vce(cluster time_activity_1)		
		eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights} if sex == 1, absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)		
				
		// Esttab export
		esttab 	using "${tables}/main_did_gender.tex", replace ${stars2}				///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)		
		      
		*** 2.5 	Table 5: DID by education		
		local vars "sex edu area age household_size"
		eststo clear 		
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if primary == 1, 				      absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if primary == 1 & sex == 0,	 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if primary == 1 & sex == 1, 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if high_school == 1, 			    absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if high_school == 1 & sex == 0, absorb(main_cat_1 dominio4 occup_1) vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if high_school == 1 & sex == 1, absorb(main_cat_1 dominio4 occup_1) vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if more_hs == 1, 				      absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if more_hs == 1 & sex == 0, 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
		eststo: reghdfe ln_real_income_1 time##_treated `vars' ${weights} if more_hs == 1 & sex == 1, 	absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)	
		
		esttab 	using "${tables}/main_did_educ.tex", replace ${stars2}				///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)			
					
          
 
    // Below Median Age 
    sum age, detail
    gen age_med = (age > `r(p50)') if !missing(age)
 
    label var age_med "Above median age"
                        
		*** 2.6 	Table  EXTRA: BY MEDIAN AGE
    eststo clear
    
    eststo clear 
    local vars "sex edu area age household_size"
    eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights} if age_med == 0,            absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)
    eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights} if sex == 0 & age_med == 0, absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)	
    eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights} if sex == 1 & age_med == 0, absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)	
    eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights} if age_med == 1,            absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)
    eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights} if sex == 0 & age_med == 1, absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)		
    eststo: reghdfe ln_real_income_1 time##_treated `vars'  ${weights} if sex == 1 & age_med == 1, absorb(dominio4 occup_1 main_cat_1) 	vce(cluster time_activity_1)	
    
    esttab 	using "${tables}/main_did_gender_age_med.tex", replace ${stars2}				///
            keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)			
                            
          
                     
		*** 2.6 	Table 7: Possible mechanisms for the SBFE program impact	
		gen n_jobs = (!missing(occup_2)) 
		replace n_jobs = 0 if !missing(occup_1) & missing(occup_2)
	
		local vars "sex edu area age household_size"
		eststo clear 	
		eststo: reghdfe training 			time##_treated `vars' ${weights},             absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum training if e(sample) == 1
			estadd scalar mean = r(mean)
		eststo: reghdfe working_months_1 	time##_treated `vars' ${weights},         absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum working_months_1 if e(sample) == 1
			estadd scalar mean = r(mean)		
		eststo: reghdfe n_jobs				time##_treated `vars' ${weights},             absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum n_jobs if e(sample) == 1
			estadd scalar mean = r(mean)		

		esttab 	using "${tables}/main_did_other_outcomes.tex", replace ${stars2}								///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)			///
				stat(mean, labels("Mean dependent variable"))	
				
		eststo clear 	
		eststo: reghdfe training 			time##_treated `vars' ${weights} if sex == 0,     absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum training 	if e(sample) == 1 & sex == 0
			estadd scalar mean = r(mean)
		eststo: reghdfe working_months_1 	time##_treated `vars' ${weights} if sex == 0, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum working_months_1 if e(sample) == 1 & sex == 0
			estadd scalar mean = r(mean)
		eststo: reghdfe n_jobs				time##_treated `vars' ${weights} if sex == 0,     absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum n_jobs if e(sample) == 1 & sex == 0
			estadd scalar mean = r(mean)
			
		esttab 	using "${tables}/main_did_other_outcomes_females.tex", replace ${stars2}						///
				keep(1.time 1._treated 1.time#1._treated) order(1.time#1._treated 1.time 1._treated)			///
				stat(mean, labels("Mean dependent variable"))				

		eststo clear 	
		eststo: reghdfe training 			time##_treated `vars' ${weights} if sex == 1,     absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum training 	if e(sample) == 1 & sex == 1
			estadd scalar mean = r(mean)
		eststo: reghdfe working_months_1 	time##_treated `vars' ${weights} if sex == 1, absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
			sum working_months_1 if e(sample) == 1 & sex == 1
			estadd scalar mean = r(mean)
		eststo: reghdfe n_jobs				time##_treated `vars' ${weights} if sex == 1,     absorb(main_cat_1 dominio4 occup_1) 	vce(cluster time_activity_1)
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
		local   vars			            ///	
                sex 				      ///
                age					      ///
                household_size		///
                primary           ///
                high_school       ///
                more_hs           ///
                area                

		eststo clear 
		tvsc `vars' if !missing(time), by(eligibility_1) clus_id(time_activity_1) strat_id(main_cat_1)
		esttab using "${tables}/balance_cov.tex", replace ${stars1}		///
			cells("mu_2(fmt(%9.3fc)) mu_1(fmt(%9.3fc)) mu_3(fmt(%9.3fc) star pvalue(d_p))" "se_2(par) se_1(par) se_3(par)") 
		
		// Income
		label var real_income_1 "Real Income"
		
		eststo clear 		
		tvsc real_income_1 if !missing(time), by(eligibility_1) clus_id(time_activity_1) strat_id(main_cat_1)	
		esttab using "${tables}/balance_out.tex", replace ${stars1}		///
			cells("mu_2(fmt(%9.3fc)) mu_1(fmt(%9.3fc)) mu_3(fmt(%9.3fc) star pvalue(d_p))" "se_2(par) se_1(par) se_3(par)") 	
		
		* ~~~~~~~~~~
		* Matched
		* ~~~~~~~~~~
		eststo clear 
		tvsc `vars' if !missing(time) ${weights}, by(_treated) clus_id(time_activity_1) strat_id(main_cat_1)
		esttab using "${tables}/balance_cov_matched.tex", replace ${stars1}		///
			cells("mu_2(fmt(%9.3fc)) mu_1(fmt(%9.3fc)) mu_3(fmt(%9.3fc) star pvalue(d_p))" "se_2(par) se_1(par) se_3(par)") 	
		
		eststo clear 
		tvsc real_income_1 if !missing(time) ${weights}, by(_treated) clus_id(time_activity_1) strat_id(main_cat_1)
		esttab using "${tables}/balance_out_matched.tex", replace ${stars1}		///
			cells("mu_2(fmt(%9.3fc)) mu_1(fmt(%9.3fc)) mu_3(fmt(%9.3fc) star pvalue(d_p))" "se_2(par) se_1(par) se_3(par)")				 
			
			
		*********************************************************************************
		*	PART 3: Figures
		********************************************************************************/
		
		*** 3.1 Kernel density
		foreach var of varlist real_income_1 edu age household_size { 
		// With Matching
		kdensity `var' if eligibility_1==1 ${weights}, plot(kdensity `var' if eligibility_1==0 ${weights}) legend(label(1 "Eligible") label(2 "Not Eligible") rows(1))
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
  
  // Appendix Tables
  use "${data_int}/emnv_cuaen_eligibility.dta", clear 

  // Fix missings
  foreach var of varlist cuaen_codes_1-cuaen_codes_3 {
    replace `var' = 990 if inlist(`var',3490,4223,5205,8040,9132,9999)
  }
  
  forvalues i = 1/3 {
  	replace main_cat_`i' = 18 if cuaen_codes_`i' == 990
  }
  
  keep if selfemployment_1 == 1

  tab eligibility_1, gen(eleg_dum)

  collapse (sum) *_dum*, by(cuaen_codes_1 main_cat_1) 
  
  order main_cat_1, first
  
  egen total = rowtotal(*_dum*) 
  
  export delimit using "${tables}/cuaen_codes.csv"