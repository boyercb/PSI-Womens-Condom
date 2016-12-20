/*========================================
  file:    3_impute.do                    
  author:  christopher boyer             
           innovations for poverty action  
  date:    2016-12-18                      
  ========================================*/
 
 /* this file imputes multiple values for missing survey
    responses using the chained equations estimator from
	the -mi- system. we impute 50 random data sets to increase
	stability of pooled estimates (caution takes a while to run).
 */
 
use "${data}/maximum_diva_02_cleaned.dta", replace
 
/* =============================================================== 
   ==================== Multiple Imputation ====================== 
   =============================================================== */

// set the random seed (digit from dollar bill)
set seed 28106935

ds, has(type numeric)
local numeric `r(varlist)'
recode `numeric' (.d = .)
recode `numeric' (.r = .)

// register the variables with missing values to be imputed
mi set wide
mi register imputed              ///
            educ                 ///
			sexage               ///
			facility_km          ///
			sexpartnernum        ///
			sexpartner1mo        ///
			childnum             ///
			contspkpartnerrecent ///
			contagree            ///	
			condop_m             ///
			condop_index

// impute 50 data sets
mi impute chained                                               ///
    (mlogit)  educ                                              ///
    (logit)   contspkpartnerrecent condop_m contagree           ///
	(poisson) childnum                                          ///
	(regress) facility_km sexage sexpartnernum sexpartner1mo condop_index = ///
	gender edustatus employmt married sti contother ward, ///
	add(50) augment dots


/* nearHF - categorize facility_km */
drop nearHF
mi passive: g nearHF = .
mi passive: replace nearHF = 0 if facility_km < 2.5
mi passive: replace nearHF = 1 if facility_km >= 2.5

drop nchildren
mi passive: g nchildren = .
mi passive: replace nchildren = 0 if childnum == 0
mi passive: replace nchildren = 1 if childnum >= 1

label values nearHF dist
label values nchildren children

label variable nearHF        "Distance to nearest health facility"
label variable nchildren     "Number of children (cat)"

mi passive: g npartners = sexpartnernum/5
mi passive: g nintercourse = sexpartner1mo/5

label variable npartners     "Number of lifetime sex partners (units of 5)"
label variable nintercourse  "Number of times engaged in sex in last 30 days (units of 5)"

#delimit ;
keep gender
     age
	 edustatus
	 educ
	 employmt
	 married
	 sexage
	 sexpartnernum
	 sexpartner1mo
	 npartners
	 nintercourse
	 nchildren
	 sti
	 contother
	 ncontknow
	 contspkpartnerrecent
	 contagree
	 condop_m
	 condop_index
	 cond6mo
	 condlast
	 ward
	 nearHF
	 facility_km
	 poverty
	 qnum
	 _*;
#delimit cr

save "${data}/maximum_diva_03_imputed.dta", replace
