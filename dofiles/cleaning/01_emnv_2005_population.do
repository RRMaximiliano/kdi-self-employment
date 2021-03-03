/********************************************************************************
* PROJECT:	Self-Employment - Nicaragua                                 
* TITLE: 	emnv_2005_population
* YEAR:		2021
*********************************************************************************
	
*** Outline:
	1. Load data
	2, Generate variables
	3. Keep and order variables
	4. Save dataset

*** Requires:
	1. EMNV05-05 POBLACION.dta
	
*** Output:
	1. emnv_05_pop.dta

********************************************************************************/

*** 1. Load data
	use "${emnv_2005}/EMNV05-05 POBLACION.DTA", clear
	
*** 2. Generate variables
	// Area
	gen area = (i06 == 1) 
	label var area "Area of residency: urban"
	
	// Sex
	gen sex = (s2p3 == 1)
	label define sex 1"Male" 0"Female"
	label values sex sex
	
	label var sex "Sex"
	
	// Education
	gen edu_y = 0 
	
	replace edu_y=0 	if s4p18a==3 | s4p18a==2 | s4p18a==1| s4p18a==0 | s4p18a==12
	replace edu_y=6 	if s4p18a==4
	replace edu_y=9 	if s4p18a==5
	replace edu_y=11 	if s4p18a==6 | s4p18a==7 | s4p18a==8 | s4p18a==9
	replace edu_y=16 	if s4p18a==10
	replace edu_y=18 	if s4p18a==11
	replace edu_y=. 	if s4p18a==.
	replace s4p18b=0 	if s4p18a==1 | s4p18a==12 				// No Education
	
	gen edu = edu_y + s4p18b
	replace edu_y=0 	if s4p18a==0 | s4p18a==1 
	
	label var edu "Years of education"
	
	// Age
	gen age = s2p4a
	label var age "Age"
	
	// Potential experience: Age - Edu - 6
	gen pot_exp= age - edu - 6
	gen pot_exp_sqrt= pot_exp^2
	
	label var pot_exp 		"Potential experience"
	label var pot_exp_sqrt 	"Potential experience (Squared)"
	
	// Self-employment
	gen selfemployment_1 = (s5p22==5) if s5p22!=. 				 	//	First  Activity 
	gen selfemployment_2 = (s5p40==5) if s5p40!=.				 	// 	Second Activity
	gen selfemployment_3 = (s5p61==5) if s5p61!=. 					//	Third  Activity 
	
	forvalues x = 1/3 {
	    label var selfemployment_`x' "Self-employed: activity `x'"
	}
	
	// Employed
	gen employed_1 = (s5p22==1) if s5p22!=. 				 	//	First  Activity 
	gen employed_2 = (s5p40==1) if s5p40!=.				 		// 	Second Activity
	gen employed_3 = (s5p61==1) if s5p61!=. 					//	Third  Activity 
	
	forvalues x = 1/3 {
	    label var employed_`x' "Self-employed: activity `x'"
	}	
	
	// Informality (Cotiza en el seguro social)
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
	
	forvalues x = 1/3 {
	    label var informal_`x' "Has social security: activity `x'"
	}
	
	*	Total Informality: Social Security Definition
	*	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	gen ss_informality = informal_1
	replace ss_informality = 1 if informal_1==0 & informal_2==1
	replace ss_informality = 1 if informal_1==0 & informal_3==1
	label value ss_informality yesno	
	
	label var ss_informality  "Has social security"
	
	// Training information
	qui tab s4p48, gen(training)
	drop 	training2 training3 training4 training5
	rename 	training1 training
	label values training yesno
	
	label var training "Received training"

	qui tab s4p49 if s4p49==0, gen(training_nocost)
	rename 	training_nocost1 training_nocost
	replace training_nocost=0 if training==1 & training_nocost!=1
	label values training_nocost yesno
	
	label var training_nocost "Received training at no cost"
	
	// Working months
	foreach r in 17 35 56{
		gen working_months`r'= s5p`r'a if s5p`r'b==3
		replace working_months`r'=s5p`r'a/4 if s5p`r'b==2
		replace working_months`r'=s5p`r'a/30 if s5p`r'b==1
	}

	rename working_months17 working_months_1
	rename working_months35 working_months_2
	rename working_months56 working_months_3
	
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


	foreach r in 14 32 54 {
		nsplit s5p`r', digits(1 3) gen(occup`r')	
		drop occup`r'2
		rename occup`r'1 occup`r'
		label value occup`r' occup
	}
	
	rename occup14 occup_1
	rename occup32 occup_2
	rename occup54 occup_3 
	
	forvalues x = 1/3 {
	    label var occup_`x' "Occupation: activity `x'"
	}
		
	// Unskilled workers	
	forvalues x = 1/3 {
	    gen 		unskilled_`x' = (occup_`x' == 9)
		label var 	unskilled_`x' "Unskilled worked: activity `x'"
	}
	
	// Hours per week
	recode s5p18 (999 = .), gen(hours)
	label var hours "Weekly hours worked"

	// Income (Net Income)
	foreach s in 20 38 59{
		local es = `s'-1
		recode s5p`s'a (999998/999999=.) (9999998/9999999=.)
		recode s5p`s'b (98/99=.) 
		
		gen i_net_income_`s' = s5p`s'a 			if s5p`es'!=.
		replace i_net_income_`s'=s5p`s'a*4 		if s5p`s'b==1
		replace i_net_income_`s'=s5p`s'a*2 		if s5p`s'b==2 | s5p`s'b==3
		replace i_net_income_`s'=s5p`s'a 		if s5p`s'b==4
		replace i_net_income_`s'=s5p`s'a/3 		if s5p`s'b==5
		replace i_net_income_`s'=s5p`s'a/6 		if s5p`s'b==6
		replace i_net_income_`s'=s5p`s'a/12 	if s5p`s'b==7	
	}

	rename i_net_income_20	i_net_income_1
	rename i_net_income_38	i_net_income_2
	rename i_net_income_59	i_net_income_3
	
	forvalues x = 1/3 { 
	    label var i_net_income_`x' "Income: activity `x'"
	}
	
	//	Activities: Type
	local vars s5p15 s5p33 s5p55 
	local i = 1
	
	foreach var in `vars' {			
		recode  `var' 															///
				(100/499=1 "Agricultura, Ganadería, Caza y Silvicultura") 		///
				(500/999=2 "Pesca y Acuicultura")								/// 
				(1000/1499=3 "Explotación de Minas y Canteras") 				///
				(1500/3999=4 "Industria Manufacturera") 						///
				(4000/4499=5 "Suministro de Electricidad, Gas y Agua") 			///
				(4500/4999=6 "Construcción") 									///
				(5000/5499=7 "Comercio") 										///
				(5500/5999=8 "Hoteles y Restaurantes") 							///
				(6000/6499=9 "Transporte y Comunicaciones") 					///
				(6500/6999=10 "Intermediacion Financiera") 						///
				(7000/7499=11 "Serviocios Inmobiliarios y Empresariales") 		///
				(7500/7999=12 "Administración Pública y Defensa") 				///
				(8000/8499=13 "Enseñanza") 										///
				(8500/8999=14 "Servicios Sociales y de Salud") 					///	
				(9000/9499=15 "Servicios Comunitarios y Social") 				///
				(9500/9799=16 "Servicios Domésticos Privados") 					///
				(9800/9899=17 "Organismos Extraterritoriales") 					///
				(9900/9999=18 "No Espeficicadas"),  							///
				gen(activity_`i')			
					
		gen raw_activity_`i' = `var'			
		label var activity_`i' "Activity `i'"
		local ++i 
	}
	
	//	Household structure
	gen i00 = (i00a*100)+i00b
	order i00, first
	bys i00: egen household_size = max(s2p00)

	gen household_type=.
	qui tab s2p2, gen(i_member)
	forvalue x = 1/9 {
		bysort i00: egen memberag`x' = sum(i_member`x')
	}

	replace household_type=1 if (memberag1>=1|memberag2>=1|memberag3>=1) & 					///
			(memberag4==0 & memberag5==0 & memberag6==0 & memberag7==0 & memberag8==0 & memberag9==0) & ///
			household_size>1
	replace household_type=2 if (memberag1>=1|memberag2>=1|memberag3>=1) & 					///
			(memberag4>=1 | memberag5>=1 | memberag6>=1 | memberag7>=1 | memberag8>=1 ) & 	///
			 household_size>1 & memberag9==0
	replace household_type=3 if (memberag1>=1|memberag2>=1|memberag3>=1) & 					///
			(memberag4>=0 | memberag5>=0 | memberag6>=0 | memberag7>=0 | memberag8>=0 ) & 	///
			 household_size>1 & memberag9>=1
	replace household_type=4 if household_size==1
	replace household_type=5 if memberag1>=1 & memberag9>=1 & household_size>=2 & 		///
			(memberag2==0 & memberag3==0 & memberag4==0 & memberag5==0 & memberag6==0 & ///
			 memberag7==0 & memberag8==0)
	replace household_type=6 if (memberag1>=1 & memberag2==0 & memberag3>=1) & 			///
			(memberag4==0 & memberag5==0 & memberag6==0 & memberag7==0 & 				///
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
	
	// Regions
	gen dominio4 = . 
	replace dominio4=1 if i01==55																// Managua
	replace dominio4=2 if i01==30 | i01==35 | i01==60 | i01==70 | i01==75 | i01==80 | i01==85	// Pacifico
	replace dominio4=3 if i01==5  | i01==10 | i01==20 | i01==25 | i01==50 | i01==65 			// Central
	replace dominio4=4 if i01==91 | i01==93 													// Caribe
	
	label var dominio4 "Dominio"
	
	// Time set: 2005
	gen time = 0
	gen year = 2005
	
	label var time	"Time"
	label var year	"Year"
	
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
	save "${data_int}/emnv_05_pop.dta", replace 

	
	
	
	
	