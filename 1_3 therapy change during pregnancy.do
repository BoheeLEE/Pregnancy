cd "/home/cib06/Documents/DS220/share/BOHEE/Pregnancy/Results"
pwd

global summary "/data/master/DS220/share/Summary_datasets/"
global linked "/home/cib06/Documents/DS220/share/AMIR/Data/Linkage/"
global datacar "/data/master/DS220/share/CARLOS/Pregnancy/"
global pregdata "/data/master/DS220/share/Linkage/Pregnancy_aurum/"
global code "/data/master/DS220/share/Codelists/"
global preg "/data/master/DS220/share/BOHEE/Pregnancy/Data/"
global ocp "/home/cib06/Documents/DS220/share/BOHEE/OCPData/"


**#  Identify the first event date during pregnancy
use ${preg}cohort_final, clear
merge 1:m patid  using ${preg}all_attacks, keep(master match) nogenerate 
rename date exac_date
sort patid exac_date
drop mquarter* missue* study*

keep if exac_date>=pregstart & exac_date < pregend & exac_date!=.

order patid pracid pregid dob age_start new_studystart preQ* exac_date

bysort patid: egen first_event=min(exac_date) 
bysort patid: egen mfirst_event=max(first_event)
drop exac_date first_event exac_type

rename mfirst_event first_event
format %td first_event

duplicates drop

keep patid first_event
save ${preg}first_event_duringpregnancy, replace


**# ICS use pattern

use ${preg}cohort_final, replace
drop mquarter* missue* 

** merge the first event date
merge 1:1 patid using ${preg}first_event_duringpregnancy, nogen keep(master match)

** merge the therapy file
merge 1:m patid using ${summary}AsthmaTherapy_AllADULTS, keep(match) nogen
save ${preg}preg_therapy_final, replace


**********************************
* creating therapy change var
* (1) By ICS rate change with censoring
* (2) BY ICS rate change without censoring 
* (3) By therapy category change
**********************************

* (1) ICS rate change with censoring
* if censoring not show makes clinical difference then remove it as loosing data and adds complexity. Without censoring compare 9 months before and during pregnancy.
use ${preg}preg_therapy_final, clear
keep patid pregend first_event issue group new_studystart pregstart 

** Censor the inhalers by first exac or end of pregnancy
replace pregend= first_event if (first_event < pregend) & (first_event >=pregstart) & first_event!=.

drop if issuedate < new_studystart | issuedate> pregend

gen ics_before=1 if (group==7 | group==9 | group==19) & (issue<pregstart)
gen ics_preg=1 if (group==7 | group==9 | group==19) & (issue>=pregstart)
keep if ics_before==1 | ics_preg==1

bysort patid: egen bef_ics_tot=total(ics_before) 
bysort patid: egen preg_ics_tot=total(ics_preg) 

gen exac=1 if first!=.
bysort patid: egen exac_preg=max(exac)

* find rate during pregnancy (create new days using censored end)
gen days=pregend-pregstart
gen dur_rate= preg_ics_tot*(365/days)

* find difference in yearly rate
replace dur_rate=0 if dur_rate==.
gen difference = dur_rate - bef_ics_tot

* create variable to qualify differences
gen pattern_1inhalerdif_censor=1 if dif>=1
replace pattern_1inhalerdif_censor=2 if dif<=-1
replace pattern_1inhalerdif_censor=0 if pattern_1inhalerdif_censor==.
label define pattern_1inhalerdif_censor 0"No change" 1"Increase ICS" 2 "Decrease ICS", replace
label value pattern_1inhalerdif_censor pattern_1inhalerdif_censor

keep patid pattern exac_preg
duplicates drop

* see if censoring helps understand data
tab pattern_1inhalerdif_censor if exac==1
tab pattern_1inhalerdif_censor if exac==.
 
save ${preg}ics_change_censored, replace


****************************************
* (2) ICS change without censoring
use ${preg}preg_therapy_final, clear
keep patid pregend issue group preQ1 pregstart first_event

drop if issuedate < preQ1 | issuedate> pregend

gen ics_before=1 if (group==7 | group==9 | group==19) & (issue<pregstart)
gen ics_preg=1 if (group==7 | group==9 | group==19) & (issue>=pregstart)
keep if ics_before==1 | ics_preg==1

bysort patid: egen bef_ics_tot=total(ics_before) 
bysort patid: egen preg_ics_tot=total(ics_preg) 

gen exac=1 if first!=. & first<pregend & first>=preQ1
bysort patid: egen exac_preg=max(exac)

* find difference in 9-months rate
gen difference = preg_ics_tot - bef_ics_tot

* create variable to qualify differences
gen pattern_1inhalerdif_noncen=1 if dif>=1
replace pattern_1inhalerdif_noncen=2 if dif<=-1
replace pattern_1inhalerdif_noncen=0 if pattern_1inhalerdif_noncen==.
label define pattern_1inhalerdif_noncen 0"No change" 1"Increase ICS" 2 "Decrease ICS", replace
label value pattern_1inhalerdif_noncen pattern_1inhalerdif_noncen

keep patid pattern exac_preg
duplicates drop

* see if censoring helps understand data
tab pattern_1inhalerdif_noncen if exac==1
tab pattern_1inhalerdif_noncen if exac==.
 
save ${preg}ics_change_nocensor, replace

* when comparing censored and not censored
* when censored, 48% of women increase ICS before exacerbation (N=3,848), 30% in each group (no change/increase/decrease) that did not exacerbate 
* when not censored and also only 9 months rate, more women increased ICS (53%)
* so makes some difference but not a lot 


****************************************************
* (3) Therapy category change (censored)
use ${preg}preg_therapy_final, clear
keep patid pregend first_event issue group new_studystart pregstart therapy

** Censor the inhalers by first exac or end of pregnancy
replace pregend= first_event if (first_event < pregend) & (first_event >=pregstart) & first_event!=.

drop if issuedate < new_studystart | issuedate> pregend

gen exac=1 if first!=.
bysort patid: egen exac_preg=max(exac)
replace exac_preg=0 if exac_preg==.

* everyone on saba if not on ICS, so no need add that
gen ics_before=1 if (group==7 | group==9 | group==19) & (issue<pregstart)
gen ics_preg=1 if (group==7 | group==9 | group==19) & (issue>=pregstart)
gen add_before=1 if (group==17 | group==6 | group==7 | group==8) & (issue<pregstart)
gen add_preg=1 if (group==17 | group==6 | group==7 | group==8) & (issue>=pregstart)

sort patid issue
by patid: egen preg_add_on=max(add_preg)
by patid: egen bef_add_on=max(add_before)

by patid: egen bef_ics_tot=total(ics_before) 
by patid: egen preg_ics_tot=total(ics_preg) 

keep exac_preg patid preg_add_on bef_add_on bef_ics_tot preg_ics_tot therapy
duplicates drop

* use rate of >3 per year as got more spread accross the categories
gen ther_preg=0 if preg_ics_tot==0 & preg_add_on==.
replace ther_preg=1 if (preg_ics_tot>0 & preg_ics_tot<3) & preg_add_on==.
replace ther_preg=2 if preg_ics_tot>2 & preg_add_on==.
replace ther_preg=3 if (preg_ics_tot>0 & preg_ics_tot<3) & preg_add_on==1
replace ther_preg=4 if preg_ics_tot>2 & preg_add_on==1
label define ther_preg 0"Reliever only" 1"Intermittent ICS" 2 "Regular ICS" 3 "Intermittent ICS+add-on" 4 "Regular ICS+add-on"
label value ther_preg ther_preg
tab ther_preg, mi

gen ther_before=0 if bef_ics_tot==0 & bef_add_on==.
replace ther_before=1 if (bef_ics_tot>0 & bef_ics_tot<3) & bef_add_on==.
replace ther_before=2 if bef_ics_tot>2 & bef_add_on==.
replace ther_before=3 if (bef_ics_tot>0 & bef_ics_tot<3) & bef_add_on==1
replace ther_before=4 if bef_ics_tot>2 & bef_add_on==1
label define ther_before 0"Reliever only" 1"Intermittent ICS" 2 "Regular ICS" 3 "Intermittent ICS+add-on" 4 "Regular ICS+add-on"
label value ther_before ther_before
tab ther_before, mi

* change therapy category (when censored)
gen ther_change_censor=0 if ther_preg==ther_before
replace ther_change_censor=1 if ther_preg>ther_before
replace ther_change_censor=2 if ther_preg<ther_before
label define ther_change_censor 0"No change" 1"Increase" 2 "Decrease"  
label value ther_change_censor ther_change_censor
tab ther_change

tab ther_change therapy
* only 12% increased, 31% decreased

keep patid ther* exac_preg

save ${preg}therapy_change_censor, replace

****************************************************
* (4) Therapy category change (not censored)
use ${preg}preg_therapy_final, clear
keep patid pregend first_event issue group new_studystart pregstart 

drop if issuedate < new_studystart | issuedate> pregend

gen exac=1 if first!=.
bysort patid: egen exac_preg=max(exac)
replace exac_preg=0 if exac_preg==.

* everyone on saba if not on ICS, so no need add that
gen ics_before=1 if (group==7 | group==9 | group==19) & (issue<pregstart)
gen ics_preg=1 if (group==7 | group==9 | group==19) & (issue>=pregstart)
gen add_before=1 if (group==17 | group==6 | group==7 | group==8) & (issue<pregstart)
gen add_preg=1 if (group==17 | group==6 | group==7 | group==8) & (issue>=pregstart)

sort patid issue
by patid: egen preg_add_on=max(add_preg)
by patid: egen bef_add_on=max(add_before)

by patid: egen bef_ics_tot=total(ics_before) 
by patid: egen preg_ics_tot=total(ics_preg) 

keep exac_preg patid preg_add_on bef_add_on bef_ics_tot preg_ics_tot
duplicates drop

* use rate of >3 per year as got more spread accross the categories
gen ther_preg=0 if preg_ics_tot==0 & preg_add_on==.
replace ther_preg=1 if (preg_ics_tot>0 & preg_ics_tot<3) & preg_add_on==.
replace ther_preg=2 if preg_ics_tot>2 & preg_add_on==.
replace ther_preg=3 if (preg_ics_tot>0 & preg_ics_tot<3) & preg_add_on==1
replace ther_preg=4 if preg_ics_tot>2 & preg_add_on==1
label define ther_preg 0"Reliever only" 1"Intermittent ICS" 2 "Regular ICS" 3 "Intermittent ICS+add-on" 4 "Regular ICS+add-on"
label value ther_preg ther_preg
tab ther_preg, mi

gen ther_before=0 if bef_ics_tot==0 & bef_add_on==.
replace ther_before=1 if (bef_ics_tot>0 & bef_ics_tot<3) & bef_add_on==.
replace ther_before=2 if bef_ics_tot>2 & bef_add_on==.
replace ther_before=3 if (bef_ics_tot>0 & bef_ics_tot<3) & bef_add_on==1
replace ther_before=4 if bef_ics_tot>2 & bef_add_on==1
label define ther_before 0"Reliever only" 1"Intermittent ICS" 2 "Regular ICS" 3 "Intermittent ICS+add-on" 4 "Regular ICS+add-on"
label value ther_before ther_before
tab ther_before, mi

* change therapy category (when censored)
gen ther_change=0 if ther_preg==ther_before
replace ther_change=1 if ther_preg>ther_before
replace ther_change=2 if ther_preg<ther_before
label define ther_change 0"No change" 1"Increase" 2 "Decrease"  
label value ther_change ther_change
tab ther_change
* only 13% increased, 28% decreased

keep patid ther* exac_preg

save ${preg}therapy_change_notcensor, replace

********************************************************************************
* ANALYSIS START! 
********************************************************************************
**# Multivariable multinomial regression analysis
* I created 4 outcome strata
* 1. No change & no exac (before/during pregnancy)
* 2. No change & exac both in before/during pregnancy
* 3. Change increase - no exac before pregnancy but yes exac during pregnancy
* 4. Change decrease - yes exac before pregnancy but no exac during pregnancy

use ${preg}cohort_final_incl_alltherapies, clear

keep pracid patid new_studystart preQ1 pregend pregstart gestdays matage imd diabetes atopy pcos gerd heart hypertension eos_high smok* bmi_cat review* GDM GestHTN pulmo dvt preeclampsia vte lowbw iugr cesarean his* multigravida anx_dep ethnicity age_group

merge 1:m patid  using ${preg}all_attacks, keep(master match) nogenerate keepusing(exac_type date)
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


***************** ALL EXACERBATIONS ********************************
* Categorise as exacerbations worse/still exacerbating, or decreased 
gen change=0 if tot_pre_eventm==0 & tot_dur_eventm==0
replace change=1 if tot_pre_eventm<tot_dur_eventm | ((tot_pre_eventm==tot_dur_eventm) & tot_pre_eventm>0)
replace change=2 if tot_pre_eventm>tot_dur_eventm
label define change 0"None" 1"More/any" 2 "Less"
label value change change

* want to use censored as seemed to make big difference if didnt censor for the association between those that decrease ICS and having a pregnancy exacerbation
merge 1:1 patid using ${preg}therapy_change_censor, nogen

* cant have exac before as that is part of the outcome derivation
mlogit change i.age_group i.ethnicity i.bmi_cat i.imd i.smoking_dur i.anx_dep i.atopy i.review_bef i.review_dur i.multi i.ther_before  i.ther_change i.eos_high, base(1) rrr

* Those who decreased exacerbations (as compared to increased) had lower odds of..... being older, smoking during pregnancy, having previous live birth, having elevated BEC. But higher odds of.... having an asthma review pre-pregnancy, any ICS use, as compared to reliever only, but higher odds of low dose ICS than higher dose asthma medication. 
* In terms of change in medication, they had lower odds of changing their ICS, so staying on same dose was best. But stronger association with not decreasing it. 
* So women that had fewer asthma attacks (as compared to more asthma attacks) were less likely to decrease their asthma medication. They were also less likely to increase it, but not to the same degree.

* Those who had none, as compared to women who had more/any, had lower odds of being Asian, overweight, obese, worse relative deprivation, smoker during pregnancy, anxious, multigravida, highest asthma medication doses, high BEC. 
* Those who had none (vs more/any) were less likely to decrease or increase their medication. But stronger association with not decreasing their medication. 

* Message: more/asthma attack during pregnancy associated with smoking, elevated BMI, deprviation, anxiety, more severe asthma, eosinophilia + Asian ethnicity
* Message: fewer asthma attacks during pregnancy than before pregnancy, was associated with older mum, first pregnancy, annual asthma review in year before, lower asthma medication use pre-pregnancy, normal eosinophil count before pregnancy and keeping medication the same (not reducing it!)


*****************************************************************************************************
*****************************************************************************************************

* Comparing women who decrease their ICS compared to women who stay the same
logistic ther_change i.exac_preg i.age_group i.ethnicity i.bmi_cat i.imd i.smoking_dur i.anx_dep i.atopy i.review_bef i.review_dur i.multi i.eos_high i.his_exac if ther_change!=1

* Had 211% higher odds of an exac during pregnancy, increased odds of being 18-25 years old, non-white ethnicity, no recording of their smoking status during pregnancy, more likely to be a smoker during pregnancy and much less likely to have review during pregnancy
* Less likely to be atopic, more likely had at least one asthma attack! and more likely it was their first pregnancy 

* Comparing women who increase their ICS compared to women who stay the same
logistic ther_change i.exac_preg i.age_group i.ethnicity i.bmi_cat i.imd i.smoking_dur i.anx_dep i.atopy  i.review_dur i.multi i.eos_high i.his_exac if ther_change!=2

* Had 120% odds of exac during pregnancy, less likely smoking not reported and very likely had asthma review less likely had an annual asthma review 


***************** HOSPITAL EXACERBATIONS ********************************
* Categorise as exacerbations 
gen change_hosp=0 if tot_pre_hospm==0 & tot_dur_hospm==0
replace change_hosp=1 if tot_pre_hospm<tot_dur_hospm | ((tot_pre_hospm==tot_dur_hospm) & tot_pre_hospm>0)
replace change_hosp=2 if tot_pre_hospm>tot_dur_hospm
label define change_hosp 0"None" 1"More/any" 2 "Less"
label value change_hosp change_hosp

merge 1:1 patid using ${preg}therapy_change_censor, nogen

mlogit change_hosp i.age_group i.ethnicity i.bmi_cat i.imd i.smoking_dur i.anx_dep i.atopy i.review_bef  i.multi i.ther_before  i.ther_change i.eos_high, base(1) rrr


* Those who decreased hospitalised exacerbations (as compared to increased) showed similar associations.
* Behavioural: They was strong association with not reducing their medication and seemed associated with increasing their medication. More likely asthma review pre-pregnancy, but less likely one during pregnancy. Strong association with using ICS pre-pregnancy.

* Is it worth doing MI for smoking_during (38% missing)

* Those who had no hospitalised exacerbations as compared to having more/any. Similar as all exacerbations. Risk factors for having them include 18-25 years, Asian, Black and Mixed ethnicity, obesity, more deprivation, smoking during pregnancy or history of smoking, 

gen exac_preg_hosp=1 if tot_dur_hospm >0
replace exac_preg_hosp=0 if exac_preg_hosp==.

* Comparing women who decrease their ICS compared to women who stay the same
logistic ther_change i.exac_preg_hosp i.age_group i.ethnicity i.bmi_cat i.imd i.smoking_dur i.anx_dep i.atopy i.review_bef i.review_dur i.multi i.eos_high i.his_exac if ther_change!=1

* Comparing women who increase their ICS compared to women who stay the same
logistic ther_change i.exac_preg_hosp i.age_group i.ethnicity i.bmi_cat i.imd i.smoking_dur i.anx_dep i.atopy i.review_bef i.review_dur i.multi i.eos_high i.his_exac if ther_change!=2

* similar to findings above, although this time if increase had no hospitalised exac. 
* review during also associated iwth increseing and not having review associated with decreasing









