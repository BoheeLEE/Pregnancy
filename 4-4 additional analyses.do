cd "/home/blee5/Documents/DS220/share/BOHEE/Pregnancy/"
pwd

global summary "/data/master/DS220/share/Summary_datasets/"
global linked "/home/blee5/Documents/DS220/share/AMIR/Data/Linkage/"
global datacar "/data/master/DS220/share/CARLOS/Pregnancy/"
global pregdata "/data/master/DS220/share/Linkage/Pregnancy_aurum/"
global code "/data/master/DS220/share/Codelists/"
global preg "/data/master/DS220/share/BOHEE/Pregnancy/Data/"
global ocp "/home/blee5/Documents/DS220/share/BOHEE/OCPData/"

**# GP consultations for asthma
use ${preg}preg_medcode, clear
merge m:1 medcode using ${code}inhaler_technique, nogen keepusing(inhaler) keep(master match)
merge m:1 medcode using ${code}asthma_self_management_plan, nogen keepusing(selfplan) keep(master match)
merge m:1 medcode using ${code}asthma_annualreview, nogen keepusing(review) keep(master match)

drop medcode

keep if obsdate>=new_studystart & obsdate<pregstart

sort patid obs
duplicates drop 

keep if inhaler==1 | selfplan==1 | review==1
keep patid new_studystart pregstart pregend new_studyend obsdate inhaler selfplan review


save ${preg}review_inhaler_management, replace
use ${preg}review_inhaler_management, clear

bysort patid: egen max_inhaler=max(inhaler) 
bysort patid: egen max_selfplan=max(selfplan)
bysort patid: egen max_review=max(review)

drop inhaler self review

duplicates drop

bysort patid: gen latest=(_n==_N)
drop if latest==0

drop latest

rename (max_inhaler max_selfplan max_review) (inhaler selfplan review)

replace inhaler=0 if inhaler==.
replace selfplan=0 if selfplan==.
replace review=0 if review==.

drop obsdate
duplicates drop

keep patid inhaler selfplan review

gen AR_SMP=1 if review==1 & selfplan==1
gen AR_both=1 if review==1 & selfplan==1 & inhaler==1
gen AR_inh=1 if review==1 & inhaler==1
gen SMP=1 if selfplan==1 

replace AR_SMP=0 if AR_SMP==.
replace AR_both=0 if AR_both==.
replace AR_inh=0 if AR_inh==.
replace SMP=0 if SMP==.

save ${preg}annualreview2, replace 




**# Analysis
use ${preg}cohort_final, clear
merge 1:1 patid using${preg}annualreview2, nogen keep(master match)

replace AR_SMP=0 if AR_SMP==.
replace AR_both=0 if AR_both==.
replace AR_inh=0 if AR_inh==.
replace SMP=0 if SMP==.


merge 1:m patid  using ${preg}all_attacks, keep(master match) nogenerate 
rename date exac_date
sort patid exac_date

drop mquarter* missue*

* Countedg the number of events in pre-pregnancy and during pregnancy
bysort patid: egen tot_pre_event= count(exac_date) if exac_date>=new_studystart & exac_date<pregstart 
bysort patid: egen tot_dur_event= count(exac_date) if exac_date>=pregstart & exac_date<pregend 

bysort patid: egen max_pre_event= max(tot_pre_event)
bysort patid: egen max_dur_event= max(tot_dur_event)  

replace max_pre_event=0 if max_pre_event==.
replace max_dur_event=0 if max_dur_event==.

drop exac_date exac_type tot_pre_event tot_dur_event

rename (max_pre_event max_dur_event) (tot_pre_event tot_dur_event)

duplicates drop 

* If the number of event>0, recode it in 1 
gen pre_event=1 if tot_pre_event>0 
gen dur_event=1 if tot_dur_event>0

replace pre_event=0 if pre_event==.
replace dur_event=0 if dur_event==.

save ${preg}cohort_analysis_review2, replace



**# Multivariable logistic regression models
use ${preg}cohort_analysis_review2, clear
merge 1:1 patid using ${preg}ics_change_censored, keep(master match) nogen
merge 1:1 patid using ${preg}therapy_change_censor, keep(master match) nogen

label define therapy 0 "no treatment" 1 "Reliever only" 2 "Intermittent ICS " 3 "Regular ICS" 4"Intermittent ICS+add-on" 5 "Regular ICS+add-on" 6 "Others", replace
label value therapy therapy

drop if therapy==6

replace his_exac=1 if his_exac==2


replace review_bef=0 if review_bef==.
replace AR_SMP=0 if AR_SMP==.
replace AR_both=0 if AR_both==.
replace AR_inh=0 if AR_inh==.
replace SMP=0 if SMP==.


tab review_bef, mi
tab AR_SMP, mi
tab AR_both, mi
tab AR_inh, mi
tab SMP, mi




logit dur_event i.ethnicity i.imd i.bmi_cat i.anx_dep i.atopy i.eos_high i.therapy i.his_exac i.SMP i.matage_group  i.multigravida i.smoking_dur i.ther_change_censor, or






/home/blee5/Documents/DS220/share/Codelists/inhaler_technique.dta
/home/blee5/Documents/DS220/share/Codelists/asthma_self_management_plan.dta
/home/blee5/Downloads/feno.txt

**# 3. EOS 0.3 or 0.5 
use ${preg}cohort_analysis, clear
merge 1:1 patid using${preg}cohort_eos0.5, keep(master match) nogen

replace eos_high5=9 if eos_high5==.
label define eos_high5 9 "Missing", add
label list eos_high5


drop if therapy==6

tab his_exac
replace his_exac=1 if his_exac==2
tab his_exac

putexcel set EOS_5, replace
putexcel A1=collect

logit dur_event i.ethnicity i.imd i.bmi_cat i.anx_dep i.atopy i.eos_high5 i.therapy i.his_exac i.review_bef i.matage_group  i.multigravida i.smoking_dur i.ther_change_censor, or


putexcel A1 = "EOS_0.5"
putexcel A2= etable
putexcel F2:G2, merge
putexcel save

*In the original cohort, we used BEc 0.3 and it was 1.36 [1.26-1.47]. However, when we set BEC by 0.5, OR was 1.25 [1.15-1.36]. other risk factors were very similar.


**# How many have FeNo
use ${preg}cohort_final, clear
keep patid new* pregstart pregend
merge 1:m patid using${preg}preg_medcode, keep(match) nogen
merge m:1 medcode using ${code}FeNo, keep(match master) keepusing(feno) nogen

drop medcode 
drop if obsdate<new_studystart | obs >new_studyend

drop obsdate
duplicates drop

* FeNo was measured 25


*** Genuine asthma
use ${preg}cohort_final, clear
drop if therapy==6

preserve

keep if eos_high==1 & his_exac==1 
tab therapy

restore

preserve

keep if eos_high==1 & his_exac==0 
tab therapy

restore

preserve

keep if eos_high==0 & his_exac==1 
tab therapy

restore

preserve

keep if eos_high==0 & his_exac==0
tab therapy

restore












