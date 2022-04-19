/********************************************************************************
* PROJECT:	Self-Employment - Nicaragua                                 
* TITLE: 	emnv_2014_population
* YEAR:		2021
*********************************************************************************
	
*** Outline:
	1. Load data
	2, Generate variables
	3. Keep and order variables
	4. Save dataset

*** Requires:
	1. EMNV14-04 POBLACION.dta
	
*** Output:
	1. emnv_14_pop.dta

********************************************************************************/

*** 1. Load data
	use "${emnv_2014}/EMNV14-04 POBLACION.dta", clear
	
*** 2. Generate variables
	// Area
	gen area = (i06 == 1) 
	label var area "Area of residency: urban"
	
	// Sex
	gen sex=(s2p5==1)
	label define sex 1"Male" 0"Female"
	label values sex sex
	
	label var sex "Sex"
	
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
	
	label var edu "Years of education"
	
	// Age
	gen age=s2p2a
	label var age "Age"
	
	// Potential experience: Age - Edu - 6
	gen pot_exp= age - edu - 6
	gen pot_exp_sqrt= pot_exp^2

	label var pot_exp 		"Potential experience"
	label var pot_exp_sqrt 	"Potential experience (Squared)"
	
	// Self-employment
	gen selfemployment_1 = (s5p18==4) if s5p18!=. 				 	//	First  Activity
	gen selfemployment_2 = (s5p34==4) if s5p34!=.				 	//	Second Activity
	gen selfemployment_3 = (s5p49==4) if s5p49!=. 					//	Third Activity

	forvalues x = 1/3 {
	    label var selfemployment_`x' "Self-employed: activity `x'"
	}
	
	// Self-employment
	gen employed_1 = (s5p18==1) if s5p18!=. 				 		//	First  Activity
	gen employed_2 = (s5p34==1) if s5p34!=.				 			//	Second Activity
	gen employed_3 = (s5p49==1) if s5p49!=. 						//	Third Activity

	forvalues x = 1/3 {
	    label var employed_`x' "Self-employed: activity `x'"
	}
	
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
	
	forvalues x = 1/3 {
	    label var informal_`x' "Has social security: activity `x'"
	}
	
	*	Total Informality: Social Security Definition
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	gen ss_informality= informal_1
	replace ss_informality=1 if informal_1==0 & informal_2==1
	replace ss_informality=1 if informal_1==0 & informal_3==1
	label value ss_informality yesno
	
	label var ss_informality  "Has social security"
	
	// Training information	
	tab 	s4p29, gen(training)
	drop 	training2
	rename 	training1 training
	label values training yesno
	
	label var training "Received training"
	
	tab 	s4p30 if s4p30==0, gen (training_nocost)
	rename 	training_nocost1 training_nocost
	replace training_nocost=0 if s4p30!=0 & s4p29==1
	replace training_nocost=. if training==0 & training_nocost ==1
	label value training_nocost yesno

	label var training_nocost "Received training at no cost"
	
	// Working months
	foreach r in 16 32 48 {
		gen working_months`r'= s5p`r'a if s5p`r'b==3
		replace working_months`r'=s5p`r'a/4 if s5p`r'b==2
		replace working_months`r'=s5p`r'a/30 if s5p`r'b==1
	}

	rename working_months16 working_months_1
	rename working_months32 working_months_2
	rename working_months48 working_months_3
	
	forvalues x = 1/3 {
	    label var working_months_`x' "Months worked in activity `x'"
	}
	
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

	rename occup14 occup_1
	rename occup30 occup_2
	rename occup46 occup_3 

	// Unskilled workers	
	forvalues x = 1/3 {
	    gen 		unskilled_`x' = (occup_`x' == 9)
		label var 	unskilled_`x' "Unskilled worked: activity `x'"
	}

	
	// Hours per week
	recode s5p17 (998=.), gen(hours)
	label var hours "Weekly hours worked"

	// Income (Net Income)
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

	rename i_net_income_19	i_net_income_1
	rename i_net_income_35	i_net_income_2
	rename i_net_income_50	i_net_income_3
	
	forvalues x = 1/3 { 
	    label var i_net_income_`x' "Income: activity `x'"
	}
	
	// Income (Net Income) SELF
	foreach s in 26 42 54{
		recode  s5p`s'b ( 9999998/ 9999999=.)
		gen i_income_`s' = s5p`s'a if s5p`s'b==5
		replace i_income_`s' = s5p`s'a*30 if s5p`s'b==1
		replace i_income_`s' = s5p`s'a*4 if s5p`s'b==2
		replace i_income_`s' = s5p`s'a*2 if s5p`s'b==3 | s5p`s'b==4
		replace i_income_`s' = s5p`s'a/3 if s5p`s'b==6
		replace i_income_`s' = s5p`s'a/6 if s5p`s'b==7
		replace i_income_`s' = s5p`s'a/12 if s5p`s'b==8
		replace i_income_`s' = . if s5p`s'a==9999998 | s5p`s'a==9999999
		replace i_income_`s' = . if s5p`s'b==98 | s5p`s'b==99
	 }
	
	rename i_income_26 i_income_1
	rename i_income_42 i_income_2
	rename i_income_54 i_income_3
	
	replace i_net_income_1 = i_income_1 if missing(i_net_income_1)
	replace i_net_income_2 = i_income_2 if missing(i_net_income_2)
	replace i_net_income_3 = i_income_3 if missing(i_net_income_3)	
	
	//	Primary Activity: Work 
	local vars s5p15 s5p31 s5p47 
	local i = 1
	
	foreach var in `vars' {			
		recode  `var' 															                      ///
				(100/499=1 "Agricultura, Ganadería, Caza y Silvicultura") 		///
				(500/999=2 "Pesca y Acuicultura")								              /// 
				(1000/1499=3 "Explotación de Minas y Canteras") 				      ///
				(1500/3999=4 "Industria Manufacturera") 						          ///
				(4000/4499=5 "Suministro de Electricidad, Gas y Agua") 			  ///
				(4500/4999=6 "Construcción") 									                ///
				(5000/5499=7 "Comercio") 										                  ///
				(5500/5999=8 "Hoteles y Restaurantes") 							          ///
				(6000/6499=9 "Transporte y Comunicaciones") 					        ///
				(6500/6999=10 "Intermediacion Financiera") 						        ///
				(7000/7499=11 "Serviocios Inmobiliarios y Empresariales") 		///
				(7500/7999=12 "Administración Pública y Defensa") 				    ///
				(8000/8499=13 "Enseñanza") 										                ///
				(8500/8999=14 "Servicios Sociales y de Salud") 					      ///	
				(9000/9499=15 "Servicios Comunitarios y Social") 				      ///
				(9500/9799=16 "Servicios Domésticos Privados") 					      ///
				(9800/9899=17 "Organismos Extraterritoriales") 					      ///
				(9900/9999=18 "No Espeficicadas"),  							            ///
				gen(activity_`i')			
				
		gen raw_activity_`i' = `var'
		
		label var activity_`i' "Activity `i'"
		local ++i 
	}
	
	//	Household structure
	bys i00: egen household_size=max(s2p00)

	gen household_type=.
	tab s2p4, gen(i_member)
	forvalue x=1/9 {
	bysort i00: egen memberag`x'=sum(i_member`x')
	}
	/* */ 

	replace household_type=1 if (memberag1>=1|memberag2>=1|memberag3>=1) & 								///
			(memberag4==0 & memberag5==0 & memberag6==0 & memberag7==0 & memberag8==0 & memberag9==0) & ///
			household_size>1
	replace household_type=2 if (memberag1>=1|memberag2>=1|memberag3>=1) & 								///
			(memberag4>=1 | memberag5>=1 | memberag6>=1 | memberag7>=1 | memberag8>=1 ) & 				///
			 household_size>1 & memberag9==0
	replace household_type=3 if (memberag1>=1|memberag2>=1|memberag3>=1) & 								///
			(memberag4>=0 | memberag5>=0 | memberag6>=0 | memberag7>=0 | memberag8>=0 ) & 				///
			 household_size>1 & memberag9>=1
	replace household_type=4 if household_size==1
	replace household_type=5 if memberag1>=1 & memberag9>=1 & household_size>=2 & 						///
			(memberag2==0 & memberag3==0 & memberag4==0 & memberag5==0 & memberag6==0 & 				///
			 memberag7==0 & memberag8==0)
	replace household_type=6 if (memberag1>=1 & memberag2==0 & memberag3>=1) & 							///
			(memberag4==0 & memberag5==0 & memberag6==0 & memberag7==0 & 								///
			 memberag8==0 & memberag9==0) & household_size>1 & memberag9==0

	label define household_type 1 "Nuclear" 		///
								2 "Ampliados" 		///
								3 "Compuesto" 		///
								4 "Unipersonales" 	///
								5 "Corresidente" 	///
								6"Monoparental", replace
	label values household_type household_type
	
	label var household_size	"Household size"
	label var household_type	"Household type"
			
	
	/* Regions (already in the dataset)
	gen dominio4=. 
	replace dominio4=1 if i01==55
	replace dominio4=2 if i01==30 | i01==35 | i01==60 | i01==70 | i01==75 | i01==80 | i01==85
	replace dominio4=3 if i01==5 | i01==10 | i01==20 | i01==25 | i01==50 | i01==65 
	replace dominio4=4 if i01==91 | i01==93 
	*/
		
	// Time set: 2014
	gen time = 2
	gen year = 2014
	
	label var time	"Time"
	label var year	"Year"

	rename peso2 Peso2
	rename peso3 Peso3 
	
*** 3. Keep variables
	keep 	i00				///
			time 			///
			year			///
			area			///
			sex 			///
			edu 			///
			age 			///
			pot_exp 		///
			pot_exp_sqrt 	///
			selfemployment_1 	///
			selfemployment_2 	///
			selfemployment_3 	///
			employed_1 		///
			employed_2 		///	
			employed_3 		///
			informal_1 		///
			informal_2 		///
			informal_3 		///
			ss_informality 	///
			training 		///
			training_nocost ///
			working_months_1 	///
			working_months_2 	///
			working_months_3 	///
			occup_1 		///
			occup_2 		///
			occup_3 		///
			unskilled_1 	///
			unskilled_2 	///
			unskilled_3 	///
			hours 			///	
			i_net_income_1 	///
			i_net_income_2 	///	
			i_net_income_3 	///
			activity_1 		///
			activity_2 		///
			activity_3 		///	
			raw_activity_1	///
			raw_activity_2	///
			raw_activity_3	///				
			household_size 	///
			household_type 	///
			dominio4 		///
			Peso* 
			
	order 	i00				///
			time 			///
			year			///
			area			///
			sex 			///
			edu 			///
			age 			///
			pot_exp 		///
			pot_exp_sqrt 	///
			selfemployment_1 	///
			selfemployment_2 	///
			selfemployment_3 	///
			employed_1 		///
			employed_2 		///	
			employed_3 		///
			informal_1 		///
			informal_2 		///
			informal_3 		///
			ss_informality 	///
			training 		///
			training_nocost ///
			working_months_1 	///
			working_months_2 	///
			working_months_3 	///
			occup_1 		///
			occup_2 		///
			occup_3 		///
			unskilled_1 	///
			unskilled_2 	///
			unskilled_3 	///
			hours 			///	
			i_net_income_1 	///
			i_net_income_2 	///	
			i_net_income_3 	///
			activity_1 		///
			activity_2 		///
			activity_3 		///	
			raw_activity_1	///
			raw_activity_2	///
			raw_activity_3	///				
			household_size 	///
			household_type 	///
			dominio4 		///
			Peso* 
		
*** 4. Save dataset
	save "${data_int}/emnv_14_pop.dta", replace 
