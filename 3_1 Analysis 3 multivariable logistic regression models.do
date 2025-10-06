cd "/home/blee5/Documents/DS220/share/BOHEE/Pregnancy/"
pwd

global preg "/data/master/DS220/share/BOHEE/Pregnancy/Data/"


**# Multivariable logistic regression models
use ${preg}cohort_analysis, clear
drop if therapy==6


putexcel set Main_logistic_regression_model_v3, replace
putexcel A1=collect

logit dur_event i.ethnicity i.imd i.bmi_cat i.anx_dep i.atopy i.eos_high i.therapy i.his_exac i.review_bef i.matage_group  i.multigravida i.smoking_dur i.ther_change_censor, or

putexcel A1 = "Overall risk"
putexcel A2= etable
putexcel F2:G2, merge
putexcel save



/*# Negative binomial regression models
use ${preg}cohort_analysis, clear
merge 1:1 patid using ${preg}ics_change_censored, keep(master match) nogen
merge 1:1 patid using ${preg}therapy_change_censor, keep(master match) nogen

label define therapy 0 "no treatment" 1 "Reliever only" 2 "Intermittent ICS " 3 "Regular ICS" 4"Intermittent ICS+add-on" 5 "Regular ICS+add-on" 6 "Others", replace
label value therapy therapy

drop if therapy==6

* cases_before: tot_pre_event
rename tot_pre_event case_before
* time_before: pregstart - new_studystart
* cases_during: tot_dur_event
rename tot_dur_event case_during
* time_during: pregend - pregstart

gen time_preg_before = pregstart - new_studystart
gen time_preg_during = pregend - pregstart

reshape long case time_preg, i(patid) j(period) string

gen exposure=0 if period=="_before"
replace exposure=1 if period=="_during"

order patid period case exposure


**
putexcel set therpy_change_censor_removedvariables, replace

putexcel A1=collect

menbreg case  i.matage_group i.ethnicity i.multigravida i.imd i.bmi_cat i.anx_dep i.atopy i.smoking_dur i.review_before i.therapy i.eos_high i.ther_change_censor review_during, exposure(time_preg) || patid:, irr

putexcel A1 = "Simple NBR_asthma attacks"
putexcel A2= etable
putexcel F2:G2, merge
putexcel save
**
*/

*** Which women most likely to decrease ICS?
**# Multivariable logistic regression models
use ${preg}cohort_analysis, clear

drop if therapy==6

fre ther_change_censor
gen ther_change_censor2=ther_change_censor
replace ther_change_censor2=0 if ther_change_censor2==1
replace ther_change_censor2=1 if ther_change_censor2==2

fre ther_change_censor2

logit ther_change_censor2 i.his_exac i.matage_group i.ethnicity i.multigravida i.imd i.bmi_cat i.anx_dep i.atopy i.smoking_dur i.therapy i.eos_high i.review_during, or


*** Which women most likely to SAME ICS?
**# Multivariable logistic regression models
use ${preg}cohort_analysis, clear
merge 1:1 patid using ${preg}ics_change_censored, keep(master match) nogen
merge 1:1 patid using ${preg}therapy_change_censor, keep(master match) nogen

label define therapy 0 "no treatment" 1 "Reliever only" 2 "Intermittent ICS " 3 "Regular ICS" 4"Intermittent ICS+add-on" 5 "Regular ICS+add-on" 6 "Others", replace
label value therapy therapy

drop if therapy==6

fre ther_change_censor
gen ther_change_censor2=ther_change_censor
replace ther_change_censor2=9 if ther_change_censor2==0
replace ther_change_censor2=0 if ther_change_censor2==1
replace ther_change_censor2=0 if ther_change_censor2==2
replace ther_change_censor2=1 if ther_change_censor2==9

fre ther_change_censor2

logit ther_change_censor2 i.his_exac i.matage_group i.ethnicity i.multigravida i.imd i.bmi_cat i.anx_dep i.atopy i.smoking_dur i.therapy i.eos_high i.review_during, or



**# ICS change 0= no change, 1 =increased
use ${preg}cohort_analysis, clear

drop if therapy==6
drop if therapy==5

fre ther_change_censor
drop if ther_change_censor==2


putexcel set Increased_ICSusers_v3, replace
putexcel A1=collect

logit ther_change_censor i.ethnicity i.imd i.bmi_cat  i.anx_dep i.atopy i.eos_high i.therapy i.his_exac i.matage_group i.review_bef i.smoking_dur i.multigravida, or

putexcel A1 = "Increased_ICSusers"
putexcel A2= etable
putexcel F2:G2, merge
putexcel save




**# ICS change 0= no change, 1 =decreased
use ${preg}cohort_analysis, clear

drop if therapy==6
drop if therapy==1


fre ther_change_censor
drop if ther_change_censor==1
replace ther_change_censor=1 if ther_change_censor==2
label define ther_change_censor 0 "No change" 1 "Decreased", replace

fre ther_change_censor

putexcel set Decreased_ICSusers_v3, replace
putexcel A1=collect

logit ther_change_censor i.ethnicity i.imd i.bmi_cat  i.anx_dep i.atopy i.eos_high i.therapy i.his_exac i.matage_group i.review_bef i.smoking_dur i.multigravida, or

putexcel A1 = "Decreased_ICSusers"
putexcel A2= etable
putexcel F2:G2, merge
putexcel save


logit ther_change_censor i.pre_event i.dur_event i.matage_group i.ethnicity i.multigravida i.imd i.bmi_cat i.anx_dep i.atopy i.smoking_dur i.therapy i.eos_high i.review_during , or

tab his_exac



********************************************************************************
**# Outcomes for GP and hospital - who is at risk? - Multinomial LR ************
use ${preg}cohort_final, clear
merge 1:m patid  using ${preg}all_attacks, keep(master match) nogenerate 

gen exac=1 if date!=. 
gen exac_gp=1 if date!=. & exac_type==1
gen exac_hosp=1 if date!=. &  exac_type>1

* Count the number of events in 9 months pre-pregnancy and during pregnancy
bysort patid: egen tot_pre_event= total(exac) if date>=preQ1 & date<=pregstart 
bysort patid: egen tot_dur_event= total(exac) if date>pregstart & date<pregend
replace tot_pre_event=0 if tot_pre_event==. 
replace tot_dur_event=0 if tot_dur_event==.

bysort patid: egen tot_pre_gp= total(exac_gp) if date>=preQ1 & date<=pregstart 
bysort patid: egen tot_dur_gp= total(exac_gp) if date>pregstart & date<pregend
replace tot_pre_gp=0 if tot_pre_gp==.
replace tot_dur_gp=0 if tot_dur_gp==.

bysort patid: egen tot_pre_hosp= total(exac_hosp) if date>=preQ1 & date<=pregstart 
bysort patid: egen tot_dur_hosp= total(exac_hosp) if date>pregstart & date<pregend
replace tot_pre_hosp=0 if tot_pre_hosp==.
replace tot_dur_hosp=0 if tot_dur_hosp==.

drop date exac*
duplicates drop 

bysort patid: egen tot_pre_eventm=max(tot_pre_event)
bysort patid: egen tot_dur_eventm=max(tot_dur_event)
bysort patid: egen tot_pre_gpm=max(tot_pre_gp)
bysort patid: egen tot_dur_gpm=max(tot_dur_gp)
bysort patid: egen tot_pre_hospm=max(tot_pre_hosp)
bysort patid: egen tot_dur_hospm=max(tot_dur_hosp)
drop tot_pre_event tot_dur_event tot_pre_gp tot_dur_gp tot_pre_hosp tot_dur_hosp
duplicates drop


* If the number of event>0, recode it in 1 
gen pre_gp=1 if tot_pre_gp>0 
gen dur_gp=1 if tot_dur_gp>0
gen pre_hosp=1 if tot_pre_hosp>0 
gen dur_hosp=1 if tot_dur_hosp>0

replace pre_gp=0 if pre_gp==.
replace dur_gp=0 if dur_gp==.
replace pre_hosp=0 if pre_hosp==.
replace dur_hosp=0 if dur_hosp==.

save ${preg}cohort_analysis_gp_hosp, replace

**# Multinomial Logistic Regression: Hospital visit or GP?
use ${preg}cohort_analysis_gp_hosp, clear
merge 1:1 patid using ${preg}therapy_change_censor, keep(master match) nogen

label define therapy 0 "no treatment" 1 "Reliever only" 2 "Intermittent ICS " 3 "Regular ICS" 4"Intermittent ICS+add-on" 5 "Regular ICS+add-on" 6 "Others", replace
label value therapy therapy

drop if therapy==6


gen change=0 if tot_pre_eventm==0 & tot_dur_eventm==0
replace change=1 if tot_pre_gpm<tot_dur_gpm 
replace change=2 if tot_pre_hospm<tot_dur_hospm
label define change 0"None" 1">=1GP" 2 ">=1Hosp"
label value change change

putexcel set changeinoutcomesbysettings_Multinomial_v5, replace
putexcel A1=collect

*UPDATED 
mlogit change i.ethnicity i.imd i.bmi_cat i.anx_dep i.atopy i.eos_high i.therapy i.his_exac i.review_bef i.matage_group  i.multigravida i.smoking_dur i.ther_change_censor, base(0) rrr




putexcel A1 = "Change in outcomes by settings"
putexcel A2= etable
putexcel F2:G2, merge
putexcel save

