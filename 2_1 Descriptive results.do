global summary "/data/master/DS220/share/Summary_datasets/"
global linked "/home/blee5/Documents/DS220/share/AMIR/Data/Linkage/"
global datacar "/data/master/DS220/share/CARLOS/Pregnancy/"
global pregdata "/data/master/DS220/share/Linkage/Pregnancy_aurum/"
global code "/data/master/DS220/share/Codelists/"
global preg "/data/master/DS220/share/BOHEE/Pregnancy/"
global ocp "/home/blee5/Documents/DS220/share/BOHEE/OCPData/"



********************************************************************
**# Exacerbation rate every 3 months before/during/after pregnancy *
********************************************************************
** All types
use ${preg}preg_cohort_order, replace
merge 1:m patid  using ${preg}all_attacks, keep(master match) nogenerate 
rename date exac_date
sort patid


forvalues i=1/11 {
	local j=`i'+1
	gen quart`i'=1 if exac_date>=preg`i' & exac_date<preg`j'
	
}


forvalues i=1/11 {
	local j=`i'+1
	gen issue`i'=exac_date if exac_date>=preg`i' & exac_date<preg`j'
	format issue`i' %td
	
}


forvalues i=1/11 {
bysort patid: egen mquarter`i'=max(quart`i')
}

forvalues i=1/11 {
bysort patid: egen missue`i'=min(issue`i')
format missue`i' %td
}

drop quart* exac_date issue* exac_type
duplicates drop
isid patid

rename (preg1 preg2 preg3 preg4 preg5 preg6 preg7 preg8 preg9 preg10 preg11 preg12) (new_studystart preQ1 preQ2 preQ3 pregstart secondtrim thirdtrim pregend postQ1 postQ2 postQ3 new_studyend) 
save ${preg}preg_cohort_2, replace


**# HES only
use ${preg}cohort_final, replace

rename (new_studystart preQ1 preQ2 preQ3 pregstart secondtrim thirdtrim pregend postQ1 postQ2 postQ3 new_studyend) (preg1 preg2 preg3 preg4 preg5 preg6 preg7 preg8 preg9 preg10 preg11 preg12) 
drop mquarter* missue*

merge 1:m patid  using ${preg}cohort_hosp_exac, keep(master match) nogenerate 
rename date exac_date
sort patid



forvalues i=1/11 {
	local j=`i'+1
	gen quart`i'=1 if exac_date>=preg`i' & exac_date<preg`j'
	
}


forvalues i=1/11 {
	local j=`i'+1
	gen issue`i'=exac_date if exac_date>=preg`i' & exac_date<preg`j'
	format issue`i' %td
	
}


forvalues i=1/11 {
bysort patid: egen mquarter`i'=max(quart`i')
}

forvalues i=1/11 {
bysort patid: egen missue`i'=min(issue`i')
format missue`i' %td
}

drop quart* exac_date issue* 
duplicates drop
isid patid

save ${preg}preg_cohort_2_HESonly, replace




**# AE only
use ${preg}cohort_final, replace

rename (new_studystart preQ1 preQ2 preQ3 pregstart secondtrim thirdtrim pregend postQ1 postQ2 postQ3 new_studyend) (preg1 preg2 preg3 preg4 preg5 preg6 preg7 preg8 preg9 preg10 preg11 preg12) 
drop mquarter* missue*


merge 1:m patid  using ${preg}preg_ae_only, keep(master match) nogenerate 
rename date exac_date
sort patid


forvalues i=1/11 {
	local j=`i'+1
	gen quart`i'=1 if exac_date>=preg`i' & exac_date<preg`j'
	
}


forvalues i=1/11 {
	local j=`i'+1
	gen issue`i'=exac_date if exac_date>=preg`i' & exac_date<preg`j'
	format issue`i' %td
	
}


forvalues i=1/11 {
bysort patid: egen mquarter`i'=max(quart`i')
}

forvalues i=1/11 {
bysort patid: egen missue`i'=min(issue`i')
format missue`i' %td
}

drop quart* exac_date issue* 
duplicates drop
isid patid

save ${preg}preg_cohort_2_AEonly, replace


**# OCS only
use ${preg}cohort_final, replace

rename (new_studystart preQ1 preQ2 preQ3 pregstart secondtrim thirdtrim pregend postQ1 postQ2 postQ3 new_studyend) (preg1 preg2 preg3 preg4 preg5 preg6 preg7 preg8 preg9 preg10 preg11 preg12) 
drop mquarter* missue*


merge 1:m patid  using ${preg}preg_ocs_order, keep(master match) nogenerate 
rename issuedate exac_date
sort patid


forvalues i=1/11 {
	local j=`i'+1
	gen quart`i'=1 if exac_date>=preg`i' & exac_date<preg`j'
	
}


forvalues i=1/11 {
	local j=`i'+1
	gen issue`i'=exac_date if exac_date>=preg`i' & exac_date<preg`j'
	format issue`i' %td
	
}


forvalues i=1/11 {
bysort patid: egen mquarter`i'=max(quart`i')
}

forvalues i=1/11 {
bysort patid: egen missue`i'=min(issue`i')
format missue`i' %td
}

drop quart* exac_date issue* 
duplicates drop
isid patid


save ${preg}preg_cohort_2_GPonly, replace



use ${preg}cohort_final, clear


tab therapy

gen therapy_alt=therapy
replace therapy_alt=2 if therapy_alt==4
replace therapy_alt=3 if therapy_alt==5

tab therapy_alt

drop if therapy==6
label define therapy 0 "no treatment" 1 "SABA only" 2 "Infreq ICS" 3 "Regular ICS", replace

tab mquarter1, mi
tab mquarter2, mi
tab mquarter3, m
tab mquarter4, mi
tab mquarter5, mi
tab mquarter6, mi
tab mquarter7, mi
tab mquarter8, mi
tab mquarter9, mi
tab mquarter10, mi
tab mquarter11, mi


preserve
collapse (sum) mquarter1 mquarter2 mquarter3 mquarter4 mquarter5 mquarter6 mquarter7 mquarter8 mquarter9 mquarter10 mquarter11, by(therapy_alt) 
restore

use ${preg}preg_cohort_2_HESonly, clear

tab mquarter1, mi
tab mquarter2, mi
tab mquarter3, m
tab mquarter4, mi
tab mquarter5, mi
tab mquarter6, mi
tab mquarter7, mi
tab mquarter8, mi
tab mquarter9, mi
tab mquarter10, mi
tab mquarter11, mi

use ${preg}preg_cohort_2_AEonly, clear

tab mquarter1, mi
tab mquarter2, mi
tab mquarter3, m
tab mquarter4, mi
tab mquarter5, mi
tab mquarter6, mi
tab mquarter7, mi
tab mquarter8, mi
tab mquarter9, mi
tab mquarter10, mi
tab mquarter11, mi



use ${preg}preg_cohort_2_GPonly, clear

tab mquarter1, mi
tab mquarter2, mi
tab mquarter3, m
tab mquarter4, mi
tab mquarter5, mi
tab mquarter6, mi
tab mquarter7, mi
tab mquarter8, mi
tab mquarter9, mi
tab mquarter10, mi
tab mquarter11, mi


*****************************************************
**# Rate before/during/after pregnancy *
*****************************************************
use ${preg}final_cohort_order, clear
keep patid therapy
save ${preg}final_cohort_baselineinhalers, replace

**** GP managed exacerbations
* remove issuedates after the study end then merge back cohort
forvalues i=1/11 {
local j=`i'+1
	
use ${preg}preg_ocs_order, clear
drop if issue<preg`i' | issue>preg`j'
merge m:1 patid using ${preg}final_cohort_order, nogen
* stset
gen timeout`i'=issuedate
replace timeout`i'=preg`j' if timeout`i'==.

quietly stset timeout`i', id(patid) fail(issue) scale(365.25) origin(preg`i') enter(preg`i') exit(preg`j')
* use per 1000 so comparable to hospital admissions which have very low rates
strate, per(1000) cl(patid)
}

* by therapy group
forvalues i=1/11 {
local j=`i'+1
	
use ${preg}preg_ocs_order, clear
drop if issue<preg`i' | issue>preg`j'
merge m:1 patid using ${preg}final_cohort_baselineinhalers, nogenerate
* stset
gen timeout`i'=issuedate
replace timeout`i'=preg`j' if timeout`i'==.

quietly stset timeout`i', id(patid) fail(issue) scale(365.25) origin(preg`i') enter(preg`i') exit(preg`j')
strate therapy, per(1000) cl(patid)
}


**** Hospital admissions 
* as one asthma group
forvalues i=1/11 {
local j=`i'+1
	
use ${preg}preg_hes_order, clear
drop if issue<preg`i' | issue>preg`j'
merge m:1 patid using ${preg}final_cohort_order, nogen
* stset
gen timeout`i'=issuedate
replace timeout`i'=preg`j' if timeout`i'==.

quietly stset timeout`i', id(patid) fail(issue) scale(365.25) origin(preg`i') enter(preg`i') exit(preg`j')
strate, per(1000) cl(patid)
}

* by therapy group
forvalues i=1/11 {
local j=`i'+1
	
use ${preg}preg_hes_order, clear
drop if issue<preg`i' | issue>preg`j'
merge m:1 patid using ${preg}final_cohort_baselineinhalers, nogenerate
* stset
gen timeout`i'=issuedate
replace timeout`i'=preg`j' if timeout`i'==.

quietly stset timeout`i', id(patid) fail(issue) scale(365.25) origin(preg`i') enter(preg`i') exit(preg`j')
strate therapy, per(1000) cl(patid)
}


**** AE only 
* as one asthma group
forvalues i=1/11 {
local j=`i'+1
	
use ${preg}preg_ae_only_order, clear
drop if issue<preg`i' | issue>preg`j'
merge m:1 patid using ${preg}final_cohort_order, nogen
* stset
gen timeout`i'=issuedate
replace timeout`i'=preg`j' if timeout`i'==.

quietly stset timeout`i', id(patid) fail(issue) scale(365.25) origin(preg`i') enter(preg`i') exit(preg`j')
strate, per(1000) cl(patid)
}

* by therapy group
forvalues i=1/11 {
local j=`i'+1
	
use ${preg}preg_ae_only_order, clear
drop if issue<preg`i' | issue>preg`j'
merge m:1 patid using ${preg}final_cohort_baselineinhalers, nogenerate
* stset
gen timeout`i'=issuedate
replace timeout`i'=preg`j' if timeout`i'==.

quietly stset timeout`i', id(patid) fail(issue) scale(365.25) origin(preg`i') enter(preg`i') exit(preg`j')
strate therapy, per(1000) cl(patid)
}


**** ALL exacerbations
* remove issuedates after the study end then merge back cohort
forvalues i=1/11 {
local j=`i'+1
	
use ${preg}all_attacks_order, clear
drop if issue<preg`i' | issue>preg`j'
merge m:1 patid using ${preg}final_cohort_order, nogen
* stset
gen timeout`i'=issuedate
replace timeout`i'=preg`j' if timeout`i'==.

quietly stset timeout`i', id(patid) fail(issue) scale(365.25) origin(preg`i') enter(preg`i') exit(preg`j')
* use per 1000 so comparable to hospital admissions which have very low rates
strate, per(1000) cl(patid)
}

* by therapy group
forvalues i=1/11 {
local j=`i'+1
	
use ${preg}all_attacks_order, clear
drop if issue<preg`i' | issue>preg`j'
merge m:1 patid using ${preg}final_cohort_baselineinhalers, nogenerate
* stset
gen timeout`i'=issuedate
replace timeout`i'=preg`j' if timeout`i'==.

quietly stset timeout`i', id(patid) fail(issue) scale(365.25) origin(preg`i') enter(preg`i') exit(preg`j')
strate therapy, per(1000) cl(patid)
}



**********************************************************************************
**#How many women stay the same, go up or go down
**********************************************************************************
use ${preg}cohort_final, replace
merge 1:m patid  using ${preg}all_attacks, keep(master match) nogenerate 
rename date issue

gen preyear1=1 if issue>=new_studystart & issue<pregstart
gen preg1=1 if issue>=pregstart & issue<pregend
gen postpreg1=1 if issue>=pregend & issue<new_studyend

bysort patid: egen preyear=total(preyear)
bysort patid: egen preg=total(preg1)
bysort patid: egen postpreg=total(postpreg1)

gen prepreg_rate=preyear/365.25
gen postpreg_rate=postpreg/365.25

bysort patid: gen preg_rate=preg/(pregend-pregstart)

keep patid prepreg_rate postpreg_rate preg_rate
duplicates drop

gen change=0 if preg==prepreg
replace change=1 if preg>prepreg
replace change=2 if preg<prepreg

label define change 0"None" 1"More" 2"Less"
label value change change
tab change

merge 1:1 patid using ${preg}cohort_final, keepusing(therapy) nogen

drop if therapy==0 | therapy==6
* table to show if change and by asthma severity
tab therapy change, row


*************************************
**#Inhaler use during the follow-up *
*************************************

use ${preg}cohort_final, clear
merge 1:m patid using ${preg}preg_therapy_All, keep(match) nogen

gen saba=1 if group==1 
gen ics=1 if (group==9 | group==7 | group==19) 
drop dose group term
duplicates drop

save ${preg}cohort_alltherapy, replace


* create variable that represents each day of the 3 year follow-up
use ${preg}cohort_alltherapy, clear
drop if issue<new_studystart | issue>new_studyend

drop if therapy==0 | therapy==6

gen day=round(issuedate-pregend)
replace day=. if issuedate>=pregend

hist day if ics==1, by(therapy)
hist day if saba==1, by(therapy)

* need new variable as pregnancy length varies for post-pregnancy scripts
gen day2=round(issuedate-pregend)
replace day2=. if issuedate<pregend

hist day2 if ics==1, by(therapy)
hist day2 if saba==1, by(therapy)


drop mquarter*
save ${preg}preg_3month_inhalers, replace

** percentage of women receiving scripts 
use ${preg}preg_3month_inhalers, clear
* ICS
preserve
keep if ics==1
gen quart1=1 if issue>=new_studystart & issue<preQ1 
gen quart2=1 if issue>=preQ1 & issue<preQ2
gen quart3=1 if issue>=preQ2 & issue<preQ3
gen quart4=1 if issue>=preQ3 & issue<pregstart
gen quart5=1 if issue>=pregstart & issue<second
gen quart6=1 if issue>=second & issue<third
gen quart7=1 if issue>=third & issue<pregend
gen quart8=1 if issue>=pregend & issue<postQ1
gen quart9=1 if issue>=postQ1 & issue<postQ2
gen quart10=1 if issue>=postQ2 & issue<postQ3
gen quart11=1 if issue>=postQ3 & issue<new_studyend

forvalues i=1/11 {
bysort patid: egen mquarter`i'=max(quart`i')
}

drop issue quart*
duplicates drop

* use number of ther_dose from previous dataset as this one now only contains those using ICS
collapse (sum) mquarter1 mquarter2 mquarter3 mquarter4 mquarter5 mquarter6 mquarter7 mquarter8 mquarter9 mquarter10 mquarter11, by(therapy)

restore


* SABA
use ${preg}preg_3month_inhalers, clear
preserve
keep if saba==1
gen quart1=1 if issue>=new_studystart & issue<preQ1 
gen quart2=1 if issue>=preQ1 & issue<preQ2
gen quart3=1 if issue>=preQ2 & issue<preQ3
gen quart4=1 if issue>=preQ3 & issue<pregstart
gen quart5=1 if issue>=pregstart & issue<second
gen quart6=1 if issue>=second & issue<third
gen quart7=1 if issue>=third & issue<pregend
gen quart8=1 if issue>=pregend & issue<postQ1
gen quart9=1 if issue>=postQ1 & issue<postQ2
gen quart10=1 if issue>=postQ2 & issue<postQ3
gen quart11=1 if issue>=postQ3 & issue<new_studyend

forvalues i=1/11 {
bysort patid: egen mquarter`i'=max(quart`i')
}

drop issue quart*
duplicates drop

* use number of ther_dose from previous dataset as this one now only contains those using ICS
collapse (sum) mquarter1 mquarter2 mquarter3 mquarter4 mquarter5 mquarter6 mquarter7 mquarter8 mquarter9 mquarter10 mquarter11, by(therapy)

restore

