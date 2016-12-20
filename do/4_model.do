/*========================================
  file:    4_model.do                    
  author:  christopher boyer             
           innovations for poverty action  
  date:    2016-12-18                      
  ========================================*/
 
 /* this file creates table 3, adjusted models 
    of risk factors for unprotected sex at
	last intercourse.
 */
 
use "${data}/maximum_diva_03_imputed.dta", clear

* order the variables
#delimit ;
order gender
      age
	  edustatus
	  educ
	  employmt
	  married
	  poverty
	  sexage
	  sexpartnernum
	  sexpartner1mo
	  nchildren
	  sti
	  contother
	  nearHF
	  ncontknow
	  contspkpartnerrecent
	  contagree
	  condop_index
	  cond6mo
	  ward
	  qnum;
#delimit cr

cap which estout
if _rc ssc install estout

/* user defined program - combines crude models in the same column 
   for easy display */
cap program drop appendmodels
program appendmodels, eclass
version 13
   syntax namelist
   tempname b V tmp
   foreach name of local namelist {
       qui est restore `name'
       mat `tmp' = e(b)
       local eq1: coleq `tmp'
       gettoken eq1 : eq1
       mat `tmp' = `tmp'[1,"`eq1':"]
       local cons = colnumb(`tmp',"_cons")
       if `cons'<. & `cons'>1 {
           mat `tmp' = `tmp'[1,1..`cons'-1]
       }
       mat `b' = nullmat(`b') , `tmp'
       mat `tmp' = e(V)
       mat `tmp' = `tmp'["`eq1':","`eq1':"]
       if `cons'<. & `cons'>1 {
           mat `tmp' = `tmp'[1..`cons'-1,1..`cons'-1]
       }
       capt confirm matrix `V'
       if _rc {
           mat `V' = `tmp'
       }
       else {
           mat `V' = ///
        ( `V' , J(rowsof(`V'),colsof(`tmp'),0) ) \ ///
        ( J(rowsof(`tmp'),colsof(`V'),0) , `tmp' )
       }
   }
   local names: colfullnames `b'
   mat coln `V' = `names'
   mat rown `V' = `names'
   eret post `b' `V'
   eret local cmd "whatever"
end

eststo clear


* generate reverse outcome variable
g nocondlast = (condlast!=1)

* construct variable list
ds _*, not
local all        "`r(varlist)'"
local exclude    `""qnum" "age" "ward" "cond6mo" "condlast" "nocondlast" "facility_km" "condop_m" "childnum" "sexpartnernum" "sexpartner1mo"'
local contvars   `""facility_km" "percpoor" "sexage" "npartners" "nintercourse" "childnum" "condop_index""'
local demovars   "i.gender i.edustatus i.educ i.employmt i.married i.poverty"
local sexvars    "c.npartners##c.nintercourse i.nchildren i.sti i.contother"
local othervars  "i.ncontknow i.contspkpartnerrecent i.contagree condop_index"
local accessvars "i.nearHF"
local loopvars : list all - exclude

/* loop through crude variables and estimate relative risk model; 
   if factor variable add i. prefix to estimate across levels */
	
local i = 1	
local mlist ""
qui {
	foreach var in `loopvars' {
		nois di "crude model of `var'"
		local cont : list var in contvars
		if `cont' {
			mi estimate, post: glm nocondlast `var', fam(poisson) link(log) vce(robust)
			eststo crude`i'
		}
		else {
			mi estimate, post: glm nocondlast i.`var', fam(poisson) link(log) vce(robust)
			eststo crude`i'
		}
		local model "crude`i'"
		local mlist : list mlist | model
		local i = `i' + 1
	}
}

* combined crude models
eststo crude : appendmodels `mlist'

* adjusted models
mi estimate, post: ///
    glm nocondlast `demovars', fam(poisson) link(log) vce(robust)
eststo adj1
mi estimate, post: ///
    glm nocondlast `demovars' `sexvars', fam(poisson) link(log) vce(robust)
eststo adj2
mi estimate, post: ///
    glm nocondlast `demovars' `sexvars' `accessvars', fam(poisson) link(log) vce(robust)
eststo adj3
mi estimate, post: ///
    glm nocondlast `demovars' `sexvars' `accessvars' `othervars', fam(poisson) link(log) vce(robust)
eststo adj4

esttab crude adj* using "${tables}/table_02.csv", ///
    title("Predictors of Unprotected Sex at Last Intercourse.") ///
    cells(`"b(fmt(%9.2f) star) ci( par("(" " - " ")") fmt(%9.2f))"') ///
	coeflabels("RR" "95% CI") ///
	scalars(ll chi2) ///
	eform wide label replace

	
/* =============================================================== 
   ====================== Robutness Checks ======================= 
   =============================================================== */

eststo clear

mi estimate, post: ///
    glm nocondlast `demovars' `sexvars' `accessvars' `othervars', fam(poisson) link(log) vce(robust)
eststo rob1
/*mi estimate, post: ///
    glm nocondlast `demovars' `sexvars' `accessvars' `othervars', fam(binomial) link(log) vce(robust)
eststo rob2*/
mi estimate, post: ///
    logit nocondlast `demovars' `sexvars' `accessvars' `othervars', vce(robust)
eststo rob3
mi estimate, post: ///
    reg nocondlast `demovars' `sexvars' `accessvars' `othervars', vce(robust)
eststo rob4

esttab rob* using "${tables}/table_03.csv", ///
    title("Robustness Checks.") ///
    cells(`"b(fmt(%9.2f) star) ci( par("(" " - " ")") fmt(%9.2f))"') ///
	coeflabels("RR" "95% CI") ///
	scalars(ll chi2) ///
	wide label replace
