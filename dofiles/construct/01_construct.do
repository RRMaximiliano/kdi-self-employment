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
	use  "${data_int}/emnv_appended.dta", clear 
	
*** Generate variables
	// Cuaen codes
	local vars raw_activity_1 raw_activity_1 raw_activity_1
	local i = 1
	
	foreach var in `vars' {
	#delimit ; 
		recode `var'	
		(100/119=011   "011 - Crops in general- cultivation of market products- horticulture") 
		(120/129=012   "012 - Animal husbandry") 
		(130/139=013   "013 - Growing of agricultural products in combination with animal husbandry (mixed farming)")
		(140/149=014   "014 - Agricultural and livestock service activities, except veterinary activities") 
		(150/159=015   "015 - Ordinary and trapping hunting and repopulation of game animals, including related service activities")
		(200/299=020   "020 - Forestry, Timber extraction and related service activities") 
		(500/599=050   "050 - Fishing, exploitation of fish hatcheries and fish farms- service activities related to fishing") 
		(1010/1019=010 "101 - Extraction and agglomeration of coal of stone")
		(1020/1029=102 "102 - Extraction and agglomeration of lignite")
		(1030/1039=103 "103 - Extraction and agglomeration of peat")
		(1110/1119=102 "111 - Extraction of crude oil and natural gas")
		(1120/1129=112 "112 - Service activities related to oil and gas extraction, except prospecting activities")
		(1200/1209=120 "120 - Extraction of uranium and thorium ores")
		(1300/1319=131 "131 - Extraction of iron ores")
		(1320/1329=132 "132 - Extraction of non-ferrous metalliferous minerals, except uranium and thorium ores")
		(1410/1419=141 "141 - Extraction of stone, sand and clay")
		(1420/1429=142 "142 - Exploitation of mines and quarries")
		(1510/1519=151 "151 - Production, processing and preservation of meat, fish, fruit, vegetables, oils and fats")
		(1520/1529=152 "152 - Manufacture of dairy products")
		(1530/1539=153 "153 - Production of mill products, starches and starch products, and prepared animal feeds")
		(1540/1549=154 "154 - Manufacture of other food products")
		(1550/1559=155 "155 - Preparation of beverages")
		(1600/1609=160 "160 - Manufacture of tobacco products")
		(1710/1719=171 "171 - Spinning, weaving and finishing of textile products")
		(1720/1729=172 "172 - Manufacture of other textile products")
		(1730/1739=173 "173 - Knitting and crochet knitting and knitting")
		(1810/1819=181 "181 - Manufacture of clothing, except fur garments")
		(1820/1829=182 "182 - Adobo and dyeing of skins- manufacture of leather goods")
		(1910/1919=191 "191 - Tanning and dressing of leather- manufacture of suitcases, handbags and saddlery and saddlery articles")
		(1920/1929=192 "192 - Manufacture of footwear")
		(2010/2019=201 "201 - Sawing and planing of wood")
		(2020/2029=202 "202 - Manufacture of products made of wood, cork, straw and plaiting materials")
		(2100/2119=210 "210 - Manufacture of paper and paper products")
		(2210/2219=221 "221 - Publishing activities")
		(2220/2229=222 "222 - Printing activities and related service activities")
		(2230/2239=223 "223 - Reproduction of recordings")
		(2310/2319=231 "231 - Manufacture of coke oven products")
		(2320/2329=232 "232 - Manufacture of petroleum refining products")
		(2330/2339=233 "233 - Elaboration of nuclear fuel")
		(2410/2419=241 "241 - Manufacture of basic chemical substances")
		(2420/2429=242 "242 - Manufacture of other chemical products")
		(2430/2439=243 "243 - Manufacture of manufactured fibers")
		(2510/2519=251 "251 - Manufacture of rubber products")
		(2520/2529=252 "252 - Manufacture of plastic products")
		(2610/2619=261 "261 - Manufacture of glass and glass products")
		(2690/2699=269 "269 ​​- Manufacture of non-metallic mineral products")
		(2710/2719=271 "271 - Basic iron and steel industries")
		(2720/2729=272 "272 - Manufacture of primary products of precious metals and non-ferrous metals")
		(2730/2739=273 "273 - Casting of metals")
		(2810/2819=281 "281 - Manufacture of metal products for structural use, tanks, tanks and steam generators")
		(2890/2899=289 "289 - Manufacture of other fabricated metal products- metalworking services activities")
		(2910/2919=291 "291 - Manufacture of general-purpose machinery")
		(2920/2929=292 "292 - Manufacture of special-purpose machinery")
		(2930/2939=293 "293 - Manufacture of household appliances")
		(3000/3009=300 "300 - Manufacture of office, accounting and computer machinery")
		(3110/3119=311 "311 - Manufacture of electric motors, generators and transformers")
		(3120/3129=312 "312 - Manufacture of electricity distribution and control devices")
		(3130/3139=313 "313 - Manufacture of insulated wires and cables")
		(3140/3149=314 "314 - Manufacture of accumulators and primary batteries and batteries")
		(3150/3159=315 "315 - Manufacture of electric lamps and lighting equipment")
		(3190/3199=319 "319 - Manufacture of other types of electrical equipment")
		(3210/3219=321 "321 - Manufacture of electronic tubes and valves and other electronic components")
		(3220/3229=322 "322 - Manufacture of radio and television transmitters and apparatus for telephony and telegraphy with wires")
		(3230/3239=323 "323 - Manufacture of radio and television receivers, sound and video recording and reproducing apparatus, and related products")
		(3310/3319=331 "331 - Manufacture of medical apparatus and instruments and apparatus for measuring, checking, testing, navigating and other purposes, except optical instruments")
		(3320/3329=332 "332 - Manufacture of optical instruments and photographic equipment")
		(3330/3339=333 "333 - Manufacture of watches")
		(3410/3419=341 "341 - Manufacture of motor vehicles")
		(3420/3429=345 "342 - Manufacture of bodies for motor vehicles- manufacture of trailers and semi-trailers")
		(3430/3439=343 "343 - Manufacture of parts, accessories and parts for motor vehicles and their engines")
		(3510/3519=351 "351 - Construction and repair of ships and other vessels")
		(3520/3529=352 "352 - Manufacture of locomotives and rolling stock for railways and trams")
		(3530/3539=353 "353 - Manufacture of aircraft and spacecraft")
		(3590/3599=359 "359 - Manufacture of other types of transport equipment")
		(3610/3619=361 "361 - Manufacture of furniture")
		(3690/3699=369 "369 - Manufacturing industries")
		(3710/3719=371 "371 - Recycling of metal waste and scrap")
		(3720/3729=372 "372 - Recycling of non-metallic waste and scrap")
		(4010/4019=401 "401 - Generation, collection and distribution of electrical energy")
		(4020/4029=402 "402 - Manufacture of gas- distribution of gaseous fuels by pipes")
		(4030/4039=403 "403 - Supply of steam and hot water")
		(4100/4109=410 "410 - Water collection, treatment and distribution")
		(4510/4519=451 "451 - Preparation of the land")
		(4520/4529=452 "452 - Construction of complete buildings and parts of buildings- civil engineering works")
		(4530/4539=453 "453 - Conditioning of buildings3")
		(4540/4549=454 "454 - Termination of buildings")
		(4550/4559=455 "455 - Rental of construction and demolition equipment with operators")
		(5010/5019=501 "501 - Sale of motor vehicles")
		(5020/5029=502 "502 - Maintenance and repair of motor vehicles")
		(5030/5039=503 "503 - Sale of parts, accessories and parts of motor vehicles")
		(5040/5049=504 "504 - Sale, maintenance and repair of motorcycles and their parts, parts and accessories")
		(5050/5059=505 "505 - Retail sale of automotive fuel")
		(5060/5069=506 "506 - Sale, Maintenance and Repair of Human and Animal Traction Vehicles and their Parts, Parts and Accessories")
		(5110/5119=511 "511 - Wholesale in exchange for a fee or contract")
		(5120/5129=512 "512 - Wholesale of agricultural raw materials, live animals, food, beverages and tobacco")
		(5130/5139=513 "513 - Wholesale of household goods")
		(5140/5149=514 "514 - Wholesale of non-agricultural intermediate products, wastes and wastes")
		(5150/5159=515 "515 - Wholesale of machinery, equipment and materials")
		(5190/5199=519 "519 - Wholesale of other products")
		(5210/5219=521 "521 - Non-specialized retail trade in warehouses")
		(5220/5229=522 "522 - Retail sale of food, beverages and tobacco in specialized stores")
		(5230/5239=523 "523 - Retail trade of other new products in specialized stores")
		(5240/5249=524 "524 - Retail sale in used goods stores")
		(5250/5259=525 "525 - Retail trade not carried out in warehouses")
		(5260/5299=526 "526 - Repair of personal effects and household goods")
		(5510/5519=551 "551 - Hotels- camps and other types of temporary lodging")
		(5520/5529=552 "552 - Restaurants, bars and canteens")
		(6010/6019=601 "601 - Transport by rail")
		(6020/6029=602 "602 - Other types of land transport")
		(6030/6039=603 "603 - Transport by pipes")
		(6110/6119=611 "611 - Shipping and cabotage")
		(6120/6129=612 "612 - Transport by inland waterways")
		(6210/6219=621 "621 - Regular transport by air")
		(6220/6229=622 "622 - Non-regular transport by air")
		(6300/6309=630 "630 - Complementary and auxiliary transport activities- activities of travel agencies")
		(6410/6419=641 "641 - Postal and mail activities")
		(6420/6429=642 "642 - Telecommunications")
		(6510/6519=651 "651 - Monetary intermediation")
		(6590/6599=659 "659 - Other types of financial intermediation")
		(6600/6609=660 "660 - Financing of insurance and pension plans, except compulsory social security plans")
		(6710/6719=671 "671 - Activities auxiliary to financial intermediation, except for the financing of insurance and pension plans")
		(6720/6729=672 "672 - Activities auxiliary to the financing of insurance and pension plans")
		(7010/7019=701 "701 - Real estate activities carried out with own or leased property")
		(7020/7029=702 "702 - Real estate activities performed in exchange for a Remuneration or contract")
		(7110/7119=711 "711 - Rental of transport equipment")
		(7120/7129=712 "712 - Rental of other types of machinery and equipment")
		(7130/7139=713 "713 - Rental of personal effects and household goods")
		(7210/7219=721 "721 - Computer equipment consultants")
		(7220/7229=722 "722 - Consultants in computer programs and supply of computer programs")
		(7230/7239=723 "723 - Data processing")
		(7240/7249=724 "724 - Activities related to databases")
		(7250/7259=725 "725 - Maintenance and repair of office, accounting and computer machinery")
		(7290/7299=729 "729 - Other computer activities")
		(7310/7319=731 "731 - Research and experimental development in the field of natural sciences and engineering")
		(7320/7329=732 "732 - Research and experimental development in the field of social sciences and humanities")
		(7410/7419=741 "741 - Legal and accounting activities, bookkeeping and auditing- tax advice- market research and conducting public opinion surveys- business and management advice")
		(7420/7429=742 "742 - Architectural and engineering activities and other technical activities")
		(7430/7439=743 "743 - Advertising")
		(7490/7499=749 "749 - Business activities")
		(7510/7519=751 "751 - Administration of the State and application of the economic and social policy of the community")
		(7520/7529=752 "752 - Provision of services to the community in general")
		(7530/7539=753 "753 - Activities of compulsory social security plans")
		(8010/8019=801 "801 - Primary education")
		(8020/8029=802 "802 - Secondary education")
		(8030/8039=803 "803 - Higher education")
		(8090/8099=809 "809 - Adult education and other types of education")
		(8510/8519=851 "851 - Activities related to human health")
		(8520/8529=852 "852 - Veterinary activities")
		(8530/8539=853 "853 - Social service activities")
		(9000/9009=900 "900 - Disposal of waste and sewage, sanitation and similar activities")
		(9110/9119=911 "911 - Activities of business, professional and employer organizations")
		(9120/9129=912 "912 - Activities of unions")
		(9190/9199=919 "919 - Activities of other associations")
		(9210/9219=921 "921 - Motion picture, radio and television activities and other entertainment activities")
		(9220/9229=922 "922 - Activities of news agencies")
		(9230/9239=923 "923 - Activities of libraries, archives and museums and other cultural activities")
		(9240/9249=924 "924 - Sports activities and other recreational activities")
		(9300/9309=930 "930 - Other activities")
		(9500/9509=950 "950 - Private households with domestic service")
		(9600/9609=960 "960 - Activities related to the production of goods from private households for self-consumption.")
		(9700/9709=970 "970 - Activities related to the production of private household services for self-consumption.")
		(9800/9809=980 "980 - Extraterritorial Organizations and Bodies")
		(9900/9909=990 "990 - Other unspecified activities"),
		gen(cuaen_codes_`i') ; 
		
		label var cuaen_codes_`i' "CUAEN CODES: Activity `i'"; 
		local ++i; 
	# delimit cr
	}
		

	// Eligibility status
	local vars cuaen_codes_1 cuaen_codes_2 cuaen_codes_3 
	local i = 1 
	
	foreach var in `vars' {
		recode `var'																///
			(011 014 020 	= 1 "Agriculture and Forestry")							///
			(012 013 050 	= 2 "Animal Husbandry") 								///
			(0151/0155 		= 3 "Production of Food Products and Beverages")  		///
			(0171/0192 		= 4 "Manufacture of textile products") 					///
			(201/222 		= 5 "Manufacture products of wood, cork, and publishing activities") 	///
			(242/289 343 351 359 = 6 "Manufacture of chemical, glass, metal and mineral products") 	///
			(291 292 323 331 361 369 371 372 = 7 "Manufacture of machinery and furniture") 			///
			(452/454 		= 8 "Construction") 									///
			(501/506 		= 9 "Sale, retail and maintenance of motor vehicles ") 	///
			(511/519 		= 10 "Wholesale") 										///
			(521/526 		= 11 "Retail trade and sale") 							///
			(551 552 		= 12 "Hotels and Restaurants") 							///
			(602/642 		= 13 "Transport and communication") 					///
			(659/713 		= 14 "Finane, real state, and rental industry") 		///
			(721/749 		= 15 "Business and repair services") 					///
			(801/853 		= 16 "Education, health and social services") 			///
			(132 141 142 	= 17 "Mining industry") 								///	
			(921 924 930 	= 18 "Entertainment, Sports, and Other Activities")		///
			(751 900 919 950 960 9999 = .), 										///
			gen(cat_`i')
		
		label var cat_`i' "Categories: activity `i'"
		
		recode cat_`i' 																///
			(1 3 4 5 7 8 9 10 11 12 = 1 "Eligible") 								///
			(2 6 13/max = 0 "Not Eligible"), 										///
			gen(eligibility_`i')
		
		label var eligibility_`i' "Eligibility status: activity `i'"
		
		recode `var'																///
			(011/020 = 1 "A - AGRICULTURE, LIVESTOCK, HUNTING AND FORESTRY")		///
			(050/099 = 2 "B - FISHING")												///
			(100/149 = 3 "C - MINING AND QUARRY EXPLOITATION")						///
			(150/399 = 4 "D - MANUFACTURING INDUSTRIES")							///
			(400/449 = 5 "E - SUPPLY OF ELECTRICITY, GAS AND WATER")				///
			(450/459 = 6 "F - CONSTRUCTION")										///
			(500/539 = 7 "G - WHOLESALE AND RETAIL TRADE, REPAIR OF MOTOR VEHICLES, MOTORCYCLES, PERSONAL EFFECTS AND DOMESTIC FACILITIES")	///
			(550/599 = 8 "H - HOTELS AND RESTAURANTS")								///
			(600/649 = 9 "I - TRANSPORTATION, STORAGE AND COMMUNICATIONS")			///
			(650/679 = 10 "J - FINANCIAL INTERMEDIATION")							///
			(700/749 = 11 "K - REAL ESTATE, BUSINESS AND RENTAL ACTIVITIES")		///
			(750/759 = 12 "L - PUBLIC ADMINISTRATION AND DEFENSE; SOCIAL SECURITY PLANS OF COMPULSORY AFFILIATION")	///
			(800/809 = 13 "M - TEACHING")											///
			(850/859 = 14 "N - SOCIAL AND HEALTH SERVICES")							///
			(900/939 = 15 "O - OTHER ACTIVITIES OF COMMUNITY, SOCIAL AND PERSONAL SERVICES")	///
			(950/979 = 16 "P - PRIVATE HOMES WITH DOMESTIC SERVICE")				///
			(980/989 = 17 "Q - EXTRATERRITORIAL ORGANIZATIONS")						///
			(990/999 = 18 "Z - OTHER ACTIVITIES NOT SPECIFIED")						///
			(3490 4223 5205 8040 9132 9999 = .), 									///
			gen(main_cat_`i')		
		
		label var main_cat_`i' "Main categories: activity `i'"
		
		local ++i
	}
	
	
	// Real income
	forvalues x = 1/3 {
		gen real_income_`x' = (i_net_income_`x'/131.864135728891)*100 		if year==2009 
		replace real_income_`x' = (i_net_income_`x'/87.5077463635998)*100 	if year==2005
		replace real_income_`x' = (i_net_income_`x'/183.022153833333)*100 	if year==2014
		
		gen ln_real_income_`x' = log(real_income_`x')
		
		label var real_income_`x' 		"Real income: activity `i'"
		label var ln_real_income_`x' 	"Log of real income: activity `i'"
	}
	
	// Time activity
	gen time_activity_1 = main_cat_1 * 10000 + year 
	
*** Save dataset
	save "${data_int}/emnv_cuaen_eligibility.dta", replace 
	

	
	
	