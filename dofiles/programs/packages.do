*! version 0.0.1  25aug2020	Roro

	capture program drop packages 

	program define packages 

		version 16 
		
		syntax [anything] [, update]
		
		local i = 0 
		
		foreach pgks of local anything {
												
			capture which `pgks'
			
			if (_rc != 111) {
			
				display as result in smcl `"[`++i'] Package {it:`pgks'} is installed"'
			}
			
			// Look if the package is installed			
			else {
				
				display as error in smcl `"Package {it:`pgks'} needs to be installed from SSC in order to run this do-file;"' _newline ///
				`"This package will be automatically installed if it is found at SSC."'
				
				capture ssc install `pgks', replace
				
				if (_rc == 601) {
					display as error in smcl `"Package `pgks' is not found at SSC;"' _newline ///
					`"Please check if {it:`pgks'} is spelled correctly and whether `pgks' is indeed a user-written command."'
					
					exit
				}
				
				else {
					display as result in smcl `"Package `pgks' has been installed successfully"'
				}
			}
					
			// With the update option
			if ("`update'" != "") {
				
				capture ado update `pgks'
				
				if (r(pkglist)) {
					display as result in smcl `"Package {it:`pgks'} is up to date."'
				}
				
			}
		}
		
	end 
