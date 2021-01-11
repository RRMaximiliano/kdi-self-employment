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

*** Load data
	use "${emnv_2005}/EMNV05-05 POBLACION.DTA", clear
	
*** Generate variables

	// Sex
	gen sex=(s2p3==1)
	label define sex 1"Male" 0"Female"
	label values sex sex
	
	// Education
	gen edu_y=0 
	
	replace edu_y=0 	if s4p18a==3 |s4p18a==2 | s4p18a==1| s4p18a==0 | s4p18a==12
	replace edu_y=6 	if s4p18a==4
	replace edu_y=9 	if s4p18a==5
	replace edu_y=11 	if s4p18a==6 | s4p18a==7 | s4p18a==8 | s4p18a==9
	replace edu_y=16 	if s4p18a==10
	replace edu_y=18 	if s4p18a==11
	replace edu_y=. 	if s4p18a==.
	replace s4p18b=0 	if s4p18a==1 | s4p18a==12 				// No Education
	gen edu = edu_y+s4p18b
	replace edu_y=0 	if s4p18a==0 | s4p18a==1 
	
	// Age
	gen age = s2p4a
	
	// Potential experience: Age - Edu - 6
	gen pot_exp= age - edu - 6
	gen pot_exp_sqrt= pot_exp^2
	
	// Self-employment
	gen selfemployment_1= (s5p22==5) if s5p22!=. 				 	//	First Activity 
	gen selfemployment_2= (s5p40==5) if s5p40!=.				 	// 	Second Activity
	gen selfemployment_3= (s5p61==5) if s5p61!=. 					//	Third Activity 
	
	// Informality 
	label define yesno 0"No" 1"Yes"
	
	*	Firs Activity
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	qui tab s5p30a, gen(informal_1)
	drop informal_11 informal_13
	rename informal_12 informal_1
	label values informal_1 yesno
	
	*	Second Activity
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	qui tab s5p48a, gen(informal_2)
	drop informal_21 informal_23
	rename informal_22 informal_2
	label values informal_2 yesno
	
	*	Third Activty
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	qui tab s5p66a, gen(informal_3)
	drop informal_31 informal_33
	rename informal_32 informal_3
	label values informal_3 yesno
	
	*	Total Informality: Social Security Definition
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	gen ss_informality= informal_1
	replace ss_informality=1 if informal_1==0 & informal_2==1
	replace ss_informality=1 if informal_1==0 & informal_3==1
	label value ss_informality yesno	
	
	
	// Training information
	qui tab s4p48, gen(training)
	drop 	training2 training3 training4 training5
	rename 	training1 training
	label values training yesno

	qui tab s4p49 if s4p49==0, gen(training_nocost)
	rename 	training_nocost1 training_nocost
	replace training_nocost=0 if training==1 & training_nocost!=1
	label values training_nocost yesno
	
	// Working months
	foreach r in 17 35 56{
		gen working_months`r'= s5p`r'a if s5p`r'b==3
		replace working_months`r'=s5p`r'a/4 if s5p`r'b==2
		replace working_months`r'=s5p`r'a/30 if s5p`r'b==1
	}


	gen working_months =working_months17
	replace working_months = working_months35 if s5p22!=5 & s5p40==5
	replace working_months = working_months56 if s5p22!=5 & s5p61==5	

	// Occupation
	label define occup 	1 "Directivos de Empresas y Poderes del Estado" ///
						2 "Profesionales Científico e Intelectuales"	///
						3 "Técnicos y Profecionales de nivel medio"		///
						4 "Empleados de Oficina"  						///
						5 "Trabajadores de Servicios y Vendedores"		///
						6 "Trabajadores calificados del sector agropecuario y pesquero" ///
						7 "Oficiales, Operarios y Artesanos."			///
						8 "Operadores de Instalaciones y Máquinas"		///
						9 "Trabajadores no Calificados"	0 "Fuerzas Armadas"


	foreach r in 14 32 54 {
		nsplit s5p`r', digits(1 3) gen(occup`r')	
		drop occup`r'2
		rename occup`r'1 occup`r'
		label value occup`r' occup
	}
	
	label value occup* occup
	gen i_occup = occup14
	replace i_occup = occup32 if s5p22!=5 & s5p40==5
	replace i_occup = occup54 if s5p22!=5 & s5p61==5
	label value i_occup occup
	
	
	// Unskilled workers
	gen unskilled = (i_occup==9)
	label value unskilled dummy

	
	// Hours per week
	recode s5p18 (999=.), gen(hours)

	// Income
	*	Net Income
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 20 38 59{
		local es=`s'-1
		recode s5p`s'a (999998/999999=.) (9999998/9999999=.)
		recode s5p`s'b (98/99=.) 
		gen i_net_income_`s'=s5p`s'a 			if s5p`es'!=.
		replace i_net_income_`s'=s5p`s'a*4 		if s5p`s'b==1
		replace i_net_income_`s'=s5p`s'a*2 		if s5p`s'b==2 | s5p`s'b==3
		replace i_net_income_`s'=s5p`s'a 		if s5p`s'b==4
		replace i_net_income_`s'=s5p`s'a/3 		if s5p`s'b==5
		replace i_net_income_`s'=s5p`s'a/6 		if s5p`s'b==6
		replace i_net_income_`s'=s5p`s'a/12 	if s5p`s'b==7	
		global sn`s' net_income 
	}

	*	Commission, overtime, tips, travel
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 23 41 62{
		recode  s5p`s'b ( 999998/ 999999=.)
		gen i_comission_`s'=s5p`s'b
		replace i_comission_`s'=0 if s5p`s'a==2	
		global sn`s' comission
	}

	*	13th Month
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 24 42 63{
		recode  s5p`s'b ( 9999998/ 9999999=.), gen(i_thirteenth_month_`s') 
		global sn`s' thirteenth_month
	}


	*	Commodity money
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 25 43 64 {
		recode  s5p`s'b ( 999998/ 999999=.), gen(i_commodity_money_`s')
		replace i_commodity_money_`s'=0 if s5p`s'a==2
		global sn`s' commodity_money
	}

	*	Housing as wages
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 26 44 {
		gen i_housing_w_`s'=s5p`s'b
		replace i_housing_w_`s'=0 if s5p`s'a==3
		global sn`s' housing_w
	}

 	*	 Free transportation or transportation allowance
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 27 45 {
		gen i_transp_`s'=s5p`s'b
		replace i_transp_`s'=0 if s5p`s'a==3
		global sn`s' transp
	}

 	*	Clothing as wages
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 28 46 {
		recode  s5p`s'b ( 999998/ 999999=.), gen(i_clothing_`s')
		replace i_clothing_`s'=i_clothing_`s'*s5p`s'c
		replace i_clothing_`s'=0 if s5p`s'a==3
		global sn`s' clothing
	}

  	*	Income CP 
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 29 47 65{
		recode  s5p`s'b ( 9999998/ 9999999=.)
		gen i_income_`s'=s5p`s'a if s5p`s'b==5
		replace i_income_`s'=s5p`s'a*30 if s5p`s'b==1
		replace i_income_`s'=s5p`s'a*4 if s5p`s'b==2
		replace i_income_`s'=s5p`s'a*2 if s5p`s'b==3 | s5p`s'b==4
		replace i_income_`s'=s5p`s'a/3 if s5p`s'b==6
		replace i_income_`s'=s5p`s'a/6 if s5p`s'b==7
		replace i_income_`s'=s5p`s'a/12 if s5p`s'b==8
		replace i_income_`s'=. if s5p`s'a==9999998 | s5p`s'a==9999999
		replace i_income_`s'=. if s5p`s'b==98 | s5p`s'b==99
		global sn`s' income
	}
 
   	*	Income: First Activity
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	forvalue se = 23/29 { 	
		rename i_${sn`se'}_`se' i_${sn`se'}_s_first
	}

    *	Income: Second Activity
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	forvalue se = 41/47 {
		rename i_${sn`se'}_`se' i_${sn`se'}_s_second
	}
 
    *	Income: Third Activity
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	forvalue se=62/65 {
		rename i_${sn`se'}_`se' i_${sn`se'}_s_third
	}
 
	rename i_net_income_20 i_net_income_s_first   
	rename i_net_income_38 i_net_income_s_second 
	rename i_net_income_59 i_net_income_s_third 

	sum i_income_s_*

    *	Sum of total income per activities 
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in first second third {
		egen i_income_wage_`s'= rowtotal(i_*_s_`s') if i_net_income_s_`s'!=.
		egen i_income_total_`s'= rowtotal(i_income_wage_`s' i_income_s_`s') 	///
		if i_income_s_`s'!=. | i_income_wage_`s'!=.
	}

    *	Income: Fourth Activity 
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	gen i_income_s_fourth=s5p67b*s5p67c if s5p57a==1 

	egen income_wage=rowtotal(i_income_wage_s*)
	egen income_self_employed=rowtotal(i_income_s*)
	rename i_income_s_fourth i_income_total_fourth
	
	
    *	TOTAL INCOME 
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	egen income_total= rowtotal(i_income_total* ) if 	///
			i_income_total_first!=. 	| 	///
			i_income_total_second!=. 	| 	///
			i_income_total_first!=. 	| 	///
			i_income_total_fourth!=.

	
	//	Primary Activity: Work 
	recode  s5p15 	(100/499=1 "Agricultura, Ganadería, Caza y Silvicultura") ///
					(500/999=2 "Pesca y Acuicultura") (1000/1499=3 "Explotación de Minas y Canteras") ///
					(1500/3999=4 "Industria Manufacturera") (4000/4499=5 "Suministro de Electricidad, Gas y Agua") ///
					(4500/4999=6 "Construcción") (5000/5499=7 "Comercio") ///
					(5500/5999=8 "Hoteles y Restaurantes") (6000/6499=9 "Transporte y Comunicaciones") ///
					(6500/6999=10 "Intermediacion Financiera") ///
					(7000/7499=11 "Serviocios Inmobiliarios y Empresariales") ///
					(7500/7999=12 "Administración Pública y Defensa") (8000/8499=13 "Enseñanza") ///
					(8500/8999=14 "Servicios Sociales y de Salud") ///
					(9000/9499=15 "Servicios Comunitarios y Social") (9500/9799=16 "Servicios Domésticos Privados") ///
					(9800/9899=17 "Organismos Extraterritoriales") ///
					(9900/9999=18 "No Espeficicadas"),  gen(prim_activity)	
		
		
	//	Household structure
	gen i00 = (i00a*100)+i00b
	order i00, first
	bys i00: egen household_size = max(s2p00)

	gen household_type=.
	qui tab s2p2, gen(i_member)
	forvalue x = 1/9 {
		bysort i00: egen memberag`x'=sum(i_member`x')
	}

	replace household_type=1 if (memberag1>=1|memberag2>=1|memberag3>=1) & ///
			(memberag4==0 & memberag5==0 & memberag6==0 & memberag7==0 & memberag8==0 & memberag9==0) & ///
			household_size>1
	replace household_type=2 if (memberag1>=1|memberag2>=1|memberag3>=1) & ///
			(memberag4>=1 | memberag5>=1 | memberag6>=1 | memberag7>=1 | memberag8>=1 ) & ///
			 household_size>1 & memberag9==0
	replace household_type=3 if (memberag1>=1|memberag2>=1|memberag3>=1) & ///
			(memberag4>=0 | memberag5>=0 | memberag6>=0 | memberag7>=0 | memberag8>=0 ) & ///
			 household_size>1 & memberag9>=1
	replace household_type=4 if household_size==1
	replace household_type=5 if memberag1>=1 & memberag9>=1 & household_size>=2 & ///
			(memberag2==0 & memberag3==0 & memberag4==0 & memberag5==0 & memberag6==0 & ///
			 memberag7==0 & memberag8==0)
	replace household_type=6 if (memberag1>=1 & memberag2==0 & memberag3>=1) & ///
			(memberag4==0 & memberag5==0 & memberag6==0 & memberag7==0 & ///
			 memberag8==0 & memberag9==0) & household_size>1 & memberag9==0
			 
	label define household_type 1 "Nuclear" 2 "Ampliados" 3 "Compuesto" 4 "Unipersonales" ///
								5 "Corresidente" 6"Monoparental", replace
	label values household_type household_type
	
	
	// Regions
	gen dominio4=. 
	replace dominio4=1 if i01==55
	replace dominio4=2 if i01==30 | i01==35 | i01==60 | i01==70 | i01==75 | i01==80 | i01==85
	replace dominio4=3 if i01==5 | i01==10 | i01==20 | i01==25 | i01==50 | i01==65 
	replace dominio4=4 if i01==91 | i01==93 
	
	
	// Time set: 2005
	gen t = 0
	gen time = 2005
	

*** Keep variables
	keep 	Peso* 			///
			s5p15 			///
			dominio4 		///
			i00 			///
			i01 			///
			i02 			///
			i03 			///
			t 				///
			time			///
			i06 			///
			s2p00 			///
			edu 			///
			sex 			///
			age 			///
			pot_exp 		///
			pot_exp_sqrt 	///
			selfemployment_1 	///
			selfemployment_2 	///
			selfemployment_3  	///
			informal_1 		///
			informal_2 		///
			informal_3 		///
			ss_informality 	///
			training 		///
			training_nocost 	///
			working_months17 	///
			working_months35 	///
			working_months56 	///
			working_months 		///
			occup14 			///
			occup32 			///
			occup54 			///
			i_occup 			///
			unskilled 			///
			hours 				///
			i_net_income_s_first 	///
			i_net_income_s_second 	///
			i_net_income_s_third 	///
			i_comission_s_first 	///
			i_comission_s_second 	///
			i_comission_s_third 	///
			i_housing_w_s_first 	///
			i_housing_w_s_second 	///
			i_transp_s_first 		///
			i_transp_s_second 		///
			i_clothing_s_first 		///
			i_clothing_s_second 	///
			i_income_s_first 		///
			i_income_s_second 		///
			i_income_s_third 		///
			i_income_wage_first 	///
			i_income_total_first 	///
			i_income_wage_second 	///
			i_income_total_second 	///
			i_income_wage_third 	///
			i_income_total_third 	///
			i_income_total_fourth 	///
			income_wage 			///
			income_self_employed 	///
			income_total 			///
			prim_activity 			///	
			household_size 			///
			household_type		
			
*** Save dataset
	save "${data_int}/emnv_05_pop.dta", replace 

	
	
	
	
	