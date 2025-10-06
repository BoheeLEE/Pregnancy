global summary "/data/master/DS220/share/Summary_datasets/"
global linked "/home/blee5/Documents/DS220/share/AMIR/Data/Linkage/"
global datacar "/data/master/DS220/share/CARLOS/Pregnancy/"
global pregdata "/data/master/DS220/share/Linkage/Pregnancy_aurum/"
global code "/data/master/DS220/share/Codelists/"
global preg "/data/master/DS220/share/BOHEE/Pregnancy/"
global ocp "/home/blee5/Documents/DS220/share/BOHEE/OCPData/"


********************************************************************
** Exacerbation rate every 3 months before/during/after pregnancy *
********************************************************************
**# ALL TYPES
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





**********************************************************************************
**How many women stay the same, go up or go down
**********************************************************************************
**# ALL TYPES
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




