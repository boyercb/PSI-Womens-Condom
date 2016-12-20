/*========================================
  file:    2_table1.do                    
  authors: christopher boyer            
           innovations for poverty action  
  date:    2016-12-18                     
  ========================================*/
 
 /* this file creates table 1 a summary of demographic
    and sexual and reproductive health history characterstics of 
	the study population by contraceptive use.
 */
 
use "${data}/maximum_diva_02_cleaned.dta", clear

* note this code uses the user-written table1 command
cap which table1
if _rc ssc install table1

#delimit ;
table1, by(condlast) 
    saving("${tables}/table_01.xlsx", replace)
	plusminus
	test
	format(%4.2f)
    vars(gender cat \
	     age contn \ 
		 edustatus cat \
		 educ cat \
		 employmt cat \
         married cat \
		 poverty cat \
         sexage contn \
		 sexpartnernum contn\
		 sexpartner1mo contn\
	     nchildren cat \
         sti cat \ 
		 contother cat \
		 nearHF cat \
		 ncontknow cat \
		 contspkpartnerrecent cat \
		 contagree cat \
		 condop_m cat \
		 condop_index contn );
#delimit cr
