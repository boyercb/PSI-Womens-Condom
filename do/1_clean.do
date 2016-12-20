/*========================================
  file:    1_clean.do                    
  authors: christopher boyer            
           innovations for poverty action  
  date:    2016-12-18                     
  ========================================*/
 
 /* This file cleans and recodes the raw de-identified data 
    from the Maximum Diva project and saves the subset of data 
	relevant for the construction of all figures and tables. */
 
use "${data}/maximum_diva_01_deidentified.dta", clear

/* ===============================================================
   =============== Clean and Recode Study Variables ==============
   =============================================================== */

/* <=== outcome variables ===> */

/* cond6mo - in survey programming cond6mo was skipped when 
   condever is zero to enforce logic constraints; here we recode
   cond6mo to 0 if the respondent reported never using a condom */
replace cond6mo = 0 if condever == 0

/* condlast - same issue as above... condlast is recoded here
   to no if the respondent reported never using condoms or not
   using them in the last 6 months */
replace condlast = 0 if condever == 0 | cond6mo == 0

/* <=== demographic covariates ===> */

/* education - combine the none and some primary categories
   from the original educational attainment variable */
g educ = .
replace educ = 0 if eduattain == 1 | eduattain == 0 | eduattain == 2
replace educ = 1 if eduattain == 3
replace educ = 2 if eduattain == 4

/* age - use the calculated final age from the roster. correct
   for a few rounding errors */
drop if age < 17
replace age = 18 if age == 17
replace age = 24 if age == 25

/* married - collapse relationship status variable into a single
   dichotomous married vs. unmarried variable. */
g married = 0
replace married = 1 if relationship == 1

/* ward poverty rate - categorize */
egen mode_poverty = mode(percpoor), by(ward)
replace percpoor = mode_poverty if mi(percpoor)
g poverty = .
replace poverty = 0 if percpoor >= 0 & percpoor < 0.1
replace poverty = 1 if percpoor >= 0.1 & percpoor < 0.2
replace poverty = 2 if percpoor >= 0.2 & percpoor < .

/* lives_alone - collapse household variable into living alone vs.
   living with others */
g lives_alone = household_f
replace lives_alone = 0 if lives_alone == .

replace salary = 0 if salary == -999
replace salary = 0 if salary == .

/* <=== sexual/reproductive health covariates ===> */

/* childnum - keep as a continuous variable but recode the survey 
   missing value codes as Stata missing value codes. */
replace childnum = .d if childnum == 999
replace childnum = .r if childnum == 998

recode childnum ///
    (0 = 0) ///
    (1/5 = 1), ///
    gen(nchildren)
				
/* sexpartnernum - keep as a continuous variable but recode the survey
   missing value codes as Stata missing value codes (includes one miss
   entered value). */ 
replace sexpartnernum = .d if sexpartnernum == 999
replace sexpartnernum = .r if sexpartnernum == 998 | sexpartnernum == 9981
recode sexpartnernum ///
    (1 = 1) ///
    (2/3 = 2) ///
    (3/5 = 3) ///
    (nonmissing = 4), ///
    gen(npartners)
	
/* sexparnter1mo - keep as a continuous variable but recode the survey 
   missing value codes as Stata missing value codes. */
replace sexpartner1mo = .d if sexpartner1mo == 999
replace sexpartner1mo = .r if sexpartner1mo == 998
recode sexpartner1mo ///
    (0 = 0) ///
    (1 = 1) ///
    (2/3 = 2) ///
    (3/5 = 3) ///
    (nonmissing = 4), ///
    gen(nintercourse)
	
/* sexage - keep as a continuous variable but recode the survey 
   missing value codes as Stata missing value codes. */
replace sexage = .d if sexage == 999 
replace sexage = .r if sexage == 998

recode sexage ///
   (0/18 = 0) ///
   (18/24 = 1), ///
   gen(firstsex)
		
/* sti - recode to binary variable */
g sti = 0
replace sti = 1 if stitestever == 1

/* contspkpartnerrecent */
replace contspkpartnerrecent = .d if contspkpartnerrecent == 999
replace contspkpartnerrecent = .r if contspkpartnerrecent == 998
recode contspkpartnerrecent (2 = 0)

/* continiciate */
replace continiciate = .d if continiciate == 999
replace continiciate = .r if continiciate == 998
recode continiciate (2 = 0)

/* contagree */
replace contagree = .d if contagree == 999
replace contagree = .r if contagree == 998
recode contagree (2 = 0)

/* condop - condom opinion questions. recode don't know 
   to Stata missing value */
foreach var of varlist condop* {
	replace `var' = .d if `var' == 999
}

/* nearHF - categorize facility_km */
g nearHF = .
replace nearHF = 0 if facility_km < 2.5
replace nearHF = 1 if facility_km >= 2.5 & facility_km < .

/* conttravel - */
replace conttravel = .d if conttravel == 999 
g traveltime = .
replace traveltime = 0 if conttravel < 20
replace traveltime = 1 if conttravel >= 20 & conttravel < 40
replace traveltime = 2 if conttravel >= 40 & !mi(conttravel)

/* contother - readreplace other specify values; collapse other 
   contraceptives used in last 6 mo into 3 categories: none vs. modern 
   method vs. other method */
/*
OLD DEFINITION
g contother = .
replace contother = 0 if inlist(1, contuse6mo_o)
replace contother = 1 if inlist(1, contuse6mo_i, contuse6mo_j, contuse6mo_k, contuse6mo_m, contuse6mo_n, contuse6mo_g)
replace contother = 2 if inlist(1, contuse6mo_a, contuse6mo_b, contuse6mo_c, contuse6mo_h, contuse6mo_g, contuse6mo_l) 
replace contother = 3 if inlist(1, contuse6mo_d, contuse6mo_e, contuse6mo_f)
*/
g contother = 0
replace contother = 0 if inlist(1, contuse_j, contuse_k, contuse_l, contuse_n)
replace contother = 1 if inlist(1, contuse_c, contuse_e, contuse_h, contuse_i, contuse_m) 
replace contother = 2 if inlist(1, contuse_afem, contuse_bfem, contuse_amale, contuse_bmale, contuse_d, contuse_f)

/* ncontknow */
drop contknow_p
egen nknow = rowtotal(contknow_a-contknow_i contknow_m)
g ncontknow = .
replace ncontknow = 0 if nknow < 3
replace ncontknow = 1 if nknow >= 3 & !mi(nknow)

/* ncontuse */
egen nuse = rowtotal(contuse_*)

g ncontuse = .
replace ncontuse = 0 if nuse < 3
replace ncontuse = 1 if nuse >= 3 & !mi(nuse)

/* negative perception of condom index */
mca condop_a-condop_q
predict condop_index

/* ===============================================================
   ============ Label Cleaned Variables and Categories ===========
   =============================================================== */

#delimit ;
label define educ 
    0 "Primary"
	1 "Secondary" 
	2 "Higher" ;

label define house_members 
    0 "Alone" 
	1 "Parents" 
	2 "Other family" 
	3 "Spouse" 
	4 "Roommates/non Family" 
	5 "With significant other" ;
	
label define percpoor
    0 "0% - 10%"
	1 "10% - 20%"
	2 "{&ge}20%";
    
label define cont
    0 "None/Traditional"
	1 "Modern Method"
	2 "LARC/LAPM Method";
	
label def mar 
    0 "Unmarried" 
	1 "Married";

label def children
    0 "None"
	1 "1 or more";
	
label def partners
    1 "1"
	2 "2-3"
	3 "3-5"
	4 "5+";
	
label def times1mo
    0 "0"
	1 "1"
	2 "2-3"
	3 "3-5"
	4 "5+";

label def sexage
    0 "< 18"
	1 ">= 18";

label def dist
    0 "< 2.5 km"
	1 ">= 2.5 km";

label def times
    0 "< 20 min"
	1 "20 - 40 min" 
	2 "> 40 min";
#delimit cr

label values educ educ
label values contother cont
label values sti yesno
label values married mar
label values lives_alone yesno
label values nchildren children
label values npartners partners
label values nintercourse times1mo
label values firstsex sexage
label values nearHF dist
label values traveltime times
label values poverty percpoor
label values contspkpartnerrecent yesno
label values contagree yesno

* variable labels
label variable gender        "Gender"
label variable age           "Age"
label variable edustatus     "Currently in School"
label variable educ          "Educational Attainment"
label variable employmt      "Employment Status"
label variable married       "Marital Status"
label variable lives_alone   "Lives Alone"
label variable sexage        "Age at first sexual intercourse"
label variable firstsex      "Age at first sexual intercourse (cat)"
label variable sexpartnernum "Number of lifetime sex partners"
label variable npartners     "Number of lifetime sex partners (cat)"
label variable sexpartner1mo "Number of times engaged in sex in last 30 days"
label variable nintercourse  "Number of times engaged in sex in last 30 days (cat)"
label variable childnum      "Number of children"
label variable nchildren     "Number of children (cat)"
label variable sti           "Ever tested for an STI?"
label variable nearHF        "Distance to nearest health facility"
label variable traveltime    "Time to contraceptive dispensary"
label variable contother     "Other contraceptives used (ever)"
label variable cond6mo       "Male condom use in the last 6 months"
label variable salary        "Income, last 30 days (kwacha)"
label variable religiosity   "Religiosity"
label variable condop_index  "Negative perception of condom use index"
label variable poverty       "Poverty rate, ward-level"

/* ===============================================================
   ============== Save Clean Data for Tables/Figures =============
   =============================================================== */

* dta file for table 1

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
	 nchildren
	 childnum
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
	 qnum;
#delimit cr

save "${data}/maximum_diva_02_cleaned.dta", replace


