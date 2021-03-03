	capture program drop tvsc
	
	program tvsc, eclass
		syntax varlist [aw pw fw] [if] [in], by(varname) clus_id(varname numeric) strat_id(varlist fv) [ * ]

		marksample 	touse
		markout 	`touse' `by'
		tempname 	mu_1 mu_2 mu_3 mu_4 se_1 se_2 se_3 se_4 d_p d_p2 N_C N_T S_C S_T N_S N_FE S_S S_FE
		
		capture drop TD*
		tab `by' , gen(TD)
		
		foreach var of local varlist {
			reg `var' TD1 TD2  [`weight' `exp'] `if', nocons
			mat `N_S' = nullmat(`N_S'), e(N)
			mat `S_S' = nullmat(`S_S'), e(N_clust)
			test (_b[TD1] - _b[TD2] == 0)
			mat `d_p'  = nullmat(`d_p'), r(p)
			matrix A = e(b)
			lincom (TD1 - TD2)

			mat `mu_3' = nullmat(`mu_3'), A[1,2]-A[1,1]
			mat `se_3' = nullmat(`se_3'), r(se)

			sum `var' [`weight' `exp'] if TD1==1 & e(sample)==1
			mat `mu_1' = nullmat(`mu_1'), r(mean)
			mat `se_1' = nullmat(`se_1'), r(sd)/sqrt(r(N))
			mat `N_C' = nullmat(`N_C'), r(N)
			qui tab `clus_id' if TD1==1 & e(sample)==1
			mat `S_C' = nullmat(`S_C'),  r(r)

			sum `var' [`weight' `exp'] if TD2==1 & e(sample)==1
			mat `mu_2' = nullmat(`mu_2'),r(mean)
			mat `se_2' = nullmat(`se_2'), r(sd)/sqrt(r(N))
			mat `N_T' = nullmat(`N_T'), r(N)
			qui tab `clus_id' if TD2==1 & e(sample)==1
			mat `S_T' = nullmat(`S_T'),  r(r)

			reghdfe `var' TD1 TD2 [`weight' `exp'] `if',  vce(cluster `clus_id') absorb(`strat_id')
			mat `N_FE' = nullmat(`N_FE'), e(N)
			mat `S_FE' = nullmat(`S_FE'), e(N_clust)
			test (_b[TD1]- _b[TD2]== 0)
			mat `d_p2'  = nullmat(`d_p2'),r(p)
			matrix A = e(b)
			lincom (TD1 - TD2)
			
			mat `mu_4' = nullmat(`mu_4'), A[1,2]-A[1,1]
			mat `se_4' = nullmat(`se_4'), r(se)
		}
		
		foreach mat in mu_1 mu_2 mu_3 mu_4 se_1 se_2 se_3 se_4 d_p d_p2 N_C N_T S_C S_T N_S N_FE S_S S_FE {
			mat coln ``mat'' = `varlist'
		}
		
		local cmd "tvsc"
		foreach mat in mu_1 mu_2 mu_3 mu_4  se_1 se_2 se_3 se_4 d_p d_p2 N_C N_T S_C S_T N_S N_FE S_S S_FE {
			eret mat `mat' = ``mat''
		}
		
		drop TD*
	end
	
	
	
	