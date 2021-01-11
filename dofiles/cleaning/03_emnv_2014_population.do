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
	use "${emnv_2014}/EMNV14-04 POBLACION.dta", clear
	
*** Generate variables

	// Sex
	gen sex=(s2p5==1)
	label define sex 1"Male" 0"Female"
	label values sex sex
	
	// Education
	gen edu_y=0

	replace edu_y=. if s4p12a==.
	replace edu_y=6 if s4p12a==4
	replace edu_y=9 if s4p12a==5
	replace edu_y=11 if s4p12a==6 | s4p12a==7 | s4p12a==8 | s4p12a==9
	replace edu_y=16 if s4p12a==10
	replace edu_y=18 if s4p12a==11
	replace s4p12b=0 if s4p12a==1 | s4p12a==12 /* No Education*/
	gen edu= edu_y+s4p12b
	replace edu=0 if s4p12a==0 | s4p12a==1 
	
	// Age
	gen age=s2p2a
	
	// Potential experience: Age - Edu - 6
	gen pot_exp= age - edu - 6
	gen pot_exp_sqrt= pot_exp^2

	// Self-employment
	gen selfemployment_1= (s5p18==4) if s5p18!=. 				 	/* 		First Activity 			*/
	gen selfemployment_2= (s5p34==4) if s5p34!=.				 	/* 		Second Activity 		*/
	gen selfemployment_3= (s5p49==4) if s5p49!=. 					/* 		Third Activity 			*/

	
	// Informality 
	label define yesno 0"No" 1"Yes"
	
	*	Firs Activity
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	qui tab s5p28a, gen(informal_1)
	drop informal_11 informal_13
	rename informal_12 informal_1
	label values informal_1 yesno
	
	*	Second Activity
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	qui tab s5p44a, gen(informal_2)
	drop informal_21 informal_23
	rename informal_22 informal_2
	label values informal_2 yesno
	
	*	Third Activty
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	qui tab s5p56a, gen(informal_3)
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
	tab s4p29, gen(training)
	drop training2
	rename training1 training
	label value training yesno

	tab s4p30 if s4p30==0, gen (training_nocost)
	rename training_nocost1 training_nocost
	replace training_nocost=0 if s4p30!=0 & s4p29==1
	replace training_nocost=. if training==0 & training_nocost ==1
	label value training_nocost yesno
	
	// Working months
	foreach r in 16 32 48 {
		gen working_months`r'= s5p`r'a if s5p`r'b==3
		replace working_months`r'=s5p`r'a/4 if s5p`r'b==2
		replace working_months`r'=s5p`r'a/30 if s5p`r'b==1
	}

	gen working_months=working_months16
	replace working_months= working_months32 if s5p18!=4 & s5p34==4
	replace working_months= working_months48 if s5p18!=4 & s5p49==4
	
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

	foreach r in 14 30 46 {
		nsplit s5p`r', digits(1 3) gen(occup`r')
		drop occup`r'2
		rename occup`r'1 occup`r'
	}

	label value occup* occup
	gen i_occup=occup14
	replace i_occup= occup30 if s5p18!=4 & s5p34==4
	replace i_occup= occup46 if s5p18!=4 & s5p49==4
	label value i_occup occup

	// Unskilled workers
	gen unskilled = (i_occup==9) if i_occup!=.
	label value unskilled yesno

	
	// Hours per week
	recode s5p17 (998=.), gen(hours)
	sum s5p17 s5p33

	// Income
	*	Net Income
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 19 35 50{
		local es=`s'-1
		recode s5p`s'a (999998/999999=.) (9999998/9999999=.)
		gen i_net_income_`s'=s5p`s'a if s5p`es'!=.
		replace i_net_income_`s'=s5p`s'a*30 			if s5p`s'b==1
		replace i_net_income_`s'=s5p`s'a*4 				if s5p`s'b==2
		replace i_net_income_`s'=s5p`s'a*2 				if s5p`s'b==3 | s5p`s'b==4
		replace i_net_income_`s'=s5p`s'a/3 				if s5p`s'b==6
		replace i_net_income_`s'=s5p`s'a/6 				if s5p`s'b==7
		replace i_net_income_`s'=s5p`s'a/12 			if s5p`s'b==8
		global sn`s' net_income
	}

	*	Commission, overtime, tips, travel
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 20 36 51{
		recode  s5p`s'b ( 999998/ 999999=.)
		gen i_comission_`s'=s5p`s'b
		replace i_comission_`s'=0 if s5p`s'a==2
		global sn`s' comission
	}

	*	13th Month
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 21 37 52{
		recode  s5p`s'b (9999998/ 9999999=.), gen(i_thirteenth_month_`s')
		replace i_thirteenth_month_`s'= i_thirteenth_month_`s'/s5p`s'c
		global sn`s' thirteenth_month
	}

	*	Commodity money
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 22 38 53 {
		recode  s5p`s'b ( 999998/ 999999=.), gen(i_commodity_money_`s')
		replace i_commodity_money_`s'=0 if s5p`s'a==2
		global sn`s' commodity_money
	}

	*	Housing as wages
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 23 39 {
		gen i_housing_w_`s'=s5p`s'b
		replace i_housing_w_`s'=0 if s5p`s'a==3
		global sn`s' housing_w
	}

 	*	 Free transportation or transportation allowance
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 24 40 {
		gen i_transp_`s'=s5p`s'b
		replace i_transp_`s'=0 if s5p`s'a==3
		global sn`s' transp
	}

 	*	Clothing as wages
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 25 41 {
		recode  s5p`s'b ( 999998/ 999999=.), gen(i_clothing_`s')
		replace i_clothing_`s'=i_clothing_`s'*s5p`s'c
		replace i_clothing_`s'=0 if s5p`s'a==3
		global sn`s' clothing
	}

  	*	Income CP
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in 26 42 54{
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
	forvalue se =19/26 {
		rename i_${sn`se'}_`se' i_${sn`se'}_s_first
	}


    *	Income: Second Activity
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	forvalue se =35/42 {
		rename i_${sn`se'}_`se' i_${sn`se'}_s_second
	}

    *	Income: Third Activity
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	forvalue se =50/54 {
		rename i_${sn`se'}_`se' i_${sn`se'}_s_third
	}

	sum i_income_s_*

    *	Sum of total income per activities 
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	foreach s in first second third {
		egen i_income_wage_`s'= rowtotal(i_*_s_`s') if i_net_income_s_`s'!=.
		egen i_income_total_`s'= rowtotal(i_income_wage_`s' i_income_s_`s') ///
		if i_income_s_`s'!=. | i_income_wage_`s'!=.
	}

	sum i_income_wage_* i_income_total*


    *	Income: Fourth Activity 
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	gen i_income_s_fourth=s5p57b/12 if s5p57a==1
	egen income_wage=rowtotal(i_income_wage_s*)
	egen income_self_employed=rowtotal(i_income_s*)
	rename i_income_s_fourth i_income_total_fourth

    *	TOTAL INCOME 
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	egen income_total= rowtotal(i_income_total* ) if	/// 
			i_income_total_first!=. 	| 	///
			i_income_total_second!=. 	| 	///
			i_income_total_first!=. 	| 	///
			i_income_total_fourth!=.

	
	//	Primary Activity: Work 
	recode s5p15	(100/499=1 "Agricultura, Ganadería, Caza y Silvicultura") ///
					(500/999=2 "Pesca y Acuicultura") (1000/1499=3 "Explotación de Minas y Canteras") ///
					(1500/3999=4 "Industria Manufacturera") (4000/4499=5 "Suministro de Electricidad, Gas y Agua") ///
					(4500/4999=6 "Construcción") (5000/5499=7 "Comercio") ///
					(5500/5999=8 "Hoteles y Restaurantes") (6000/6499=9 "Transporte y Comunicaciones") ///
					(6500/6999=10 "Intermediacion Financiera") ///
					(7000/7499=11 "Serviocios Inmobiliarios y Empresariales") ///
					(7500/7999=12 "Administración Pública y Defensa") (8000/8499=13 "Enseñanza") ///
					(8500/8999=14 "Servicios Sociales y de Salud") (9000/9499= 15 "Servicios Comunitarios y Social") ///
					(9500/9799=16 "Servicios Domésticos Privados") ///
					(9800/9899= 17 "Organismos Extraterritoriales") ///
					(9900/9999=18 "No Espeficicadas"),  gen(prim_activity)

					
	//	Household structure
	bys i00: egen household_size=max(s2p00)

	gen household_type=.
	tab s2p4, gen(i_member)
	forvalue x=1/9 {
	bysort i00: egen memberag`x'=sum(i_member`x')
	}
	/* */ 

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
			
	
	/* Regions (already in the dataset)
	gen dominio4=. 
	replace dominio4=1 if i01==55
	replace dominio4=2 if i01==30 | i01==35 | i01==60 | i01==70 | i01==75 | i01==80 | i01==85
	replace dominio4=3 if i01==5 | i01==10 | i01==20 | i01==25 | i01==50 | i01==65 
	replace dominio4=4 if i01==91 | i01==93 
	*/
	
	// Time set: 2009
	gen t = 2
	gen time = 2014
	

*** Keep variables
	keep	peso* 				///
			s5p15 				///
			i00 				///
			t 					///
			time				///
			dominio4 			///
			i06 				///
			edu 				///
			age 				///
			sex 				///
			pot_exp 			///
			pot_exp_sqrt 		///
			selfemployment_1 	///
			selfemployment_2 	///
			selfemployment_3  	///
			informal_1 			///
			informal_2 			///
			informal_3 			///
			ss_informality 		///
			training 			///
			training_nocost 	///
			working_months16 	///
			working_months32 	///
			working_months48 	///
			working_months 		///
			occup14 			///
			occup30 			///
			occup46 			///
			i_occup 			///
			unskilled 			///
			hours 					///
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
			i_income_wage_second	///
			i_income_total_second 	///
			i_income_wage_third		///
			i_income_total_third 	///
			i_income_total_fourth	///
			income_wage 			///
			income_self_employed 	///
			income_total			///
			prim_activity 			///
			household_size 			///
			household_type
		
*** Save dataset
	save "${data_int}/emnv_14_pop.dta", replace 
