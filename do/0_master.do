/*========================================
  file:    0_master.do                    
  author:  christopher boyer             
           innovations for poverty action  
  date:    2016-12-18                      
  ========================================*/
 
 /* This is the master do-file for the baseline analysis 
    of PSI's Maximum Diva female condom project, a 
	randomized evaluation of the effects of interpersonal
	communication(IPC) campaigns on condom use in Lusaka, 
	Zambia.*/

clear all
version 13
set more off

* project directory structure 
global dir     "C:/Users/cboyer.IPA/Desktop/GitHub"
global proj    "${dir}/PSI-Womens-Condom"
global data    "${proj}/data"
global bin     "${proj}/do"
global log     "${proj}/log"
global figures "${proj}/figures"
global tables  "${proj}/tables"

log using "${log}/maximum_diva_$S_DATE.smcl", replace

* reproduce all analysis steps
cd "${bin}"
do 1_clean.do
do 2_table1.do
do 3_impute.do
do 4_model.do

log close
