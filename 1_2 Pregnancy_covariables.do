global summary "/data/master/DS220/share/Summary_datasets/"
global linked "/home/blee5/Documents/DS220/share/AMIR/Data/Linkage/"
global datacar "/data/master/DS220/share/CARLOS/Pregnancy/"
global pregdata "/data/master/DS220/share/Linkage/Pregnancy_aurum/"
global code "/data/master/DS220/share/Codelists/"
global preg "/data/master/DS220/share/BOHEE/Pregnancy/Data/"
global ocp "/home/blee5/Documents/DS220/share/BOHEE/OCPData/"

** Adding covariates

forvalue i=1/6 {
	use ${preg}preg_cohort_2, clear
	keep patid new* pre* post* preg*
	merge 1:m patid using ${summary}Aurum_MEDCODES_Adults`i', keep(match) nogen
	compress
	duplicates drop
	save ${preg}preg_medcode_`i', replace
	
}

use ${preg}preg_medcode_1, clear

forvalues i=2/6 {
	append using ${preg}preg_medcode_`i'
	}

drop  pregnumber


save ${preg}preg_medcode, replace 

********************
* BEFORE Pregnancy *
********************
**# Diabetes, Atopy, PCOS, GERD, heart disease, hypertension, Pulmembolism, DVT
use ${preg}preg_medcode, clear

drop if obs>pregstart
merge m:1 medcodeid using${code}diabetes_type2, keepusing(diabetes) keep (master match) nogen
merge m:1 medcodeid using${code}Atopy_aurum_clear, keepusing(atopy) keep (master match) nogen
merge m:1 medcodeid using${code}pcos_updated, keepusing(pcos) keep (master match) nogen
merge m:1 medcodeid using${code}gerd, keepusing(gerd) keep (master match) nogen
merge m:1 medcodeid using${code}heart_disease_and_HT, keep (master match) nogen


drop term
rename heart_disease* heartdisease

replace diabetes=0 if diabetes==.
replace atopy=0 if atopy==.
replace pcos=0 if pcos==.
replace gerd=0 if gerd==.
replace heartdisease=0 if heartdisease==.
replace hypertension=0 if hypertension==.


drop med obsdate
sort patid


foreach i in diabetes atopy pcos  gerd heartdisease hypertension {
by patid: egen max_`i'=max(`i')
}

* drop the original variable as only want the max_variable now
drop diabetes* atopy* pcos*  gerd* heart* hypertension* 
duplicates drop

* rename the variables 
rename (max_diabetes max_atopy  max_pcos max_gerd max_heart max_hypertension ) (diabetes atopy pcos gerd heart hypertension)

keep patid diabetes atopy pcos gerd heart hypertension
save ${preg}cohort_comorb, replace

**# COPD baseline
use ${preg}preg_medcode, clear
merge m:1 medcode using ${code}copd_aurum_march2023, nogen keepusing(copd) keep(master match)
drop if obs>pregstart

replace copd=0 if copd==.

drop obsdate
sort patid

foreach i in copd   {
by patid: egen max_`i'=max(`i')
}

* drop the original variable as only want the max_variable now
drop  copd* 
duplicates drop

* rename the variables 
local old "max_copd "
local new "copd"
rename (`old') (`new')

drop medcode
duplicates drop

keep if copd==1
save ${preg}cohort_copd, replace


**# Total WBC
forvalue i=1/6 {
	use ${summary}Aurum_VALUES_Adults`i', clear
	merge m:1 medcodeid using ${code}total_wbc, keep(match) nogen
	compress
	duplicates drop
	save ${preg}Totalwbc_value_`i', replace
}


use ${preg}Totalwbc_value_1, clear


forvalues i=2/6 {
	append using ${preg}Totalwbc_value_`i'
	}

save ${preg}Totalwbc_allpatients, replace

use ${preg}preg_cohort_2, clear
merge 1:m patid using ${preg}Totalwbc_allpatients, keep(master match) nogen
drop medcodeid
drop if value==.

keep patid new* pre* pregstart pregend second third value obs TWBC

rename value value1
rename obs obs1

save ${preg}preg_totalwbc, replace

**# Eosinophil

use ${preg}preg_cohort_2, clear
merge 1:m patid using ${ocp}Eos_allpatients, keep(master match) nogen
drop medcodeid
drop if value==.

keep patid new* pregstart value obs eosinophil

sort patid obsdate

* 22.Oct: change "obsdate<=new_studystart" to "obsdate<pregstart" 
gen eos_`i'=value if  obsdate<pregstart & obsdate>=(new_studystart-365*5)
bysort patid: egen max_eos=max(eos_) 

keep if eos_!=.
bysort patid: gen high=1 if eos_>=0.3

bysort patid:egen tot=total(high)
rename tot tot_hieos

keep patid max_eos tot_hieos
duplicates drop
rename max eos

gen eos_high=1 if eos>=0.3 
replace eos_high=0 if eos<0.3 

save ${preg}cohort_eos, replace

**# Eosinohil 0.5

use ${preg}preg_cohort_2, clear
merge 1:m patid using ${ocp}Eos_allpatients, keep(master match) nogen
drop medcodeid
drop if value==.

keep patid new* pregstart value obs eosinophil

sort patid obsdate

* 22.Oct: change "obsdate<=new_studystart" to "obsdate<pregstart" 
gen eos_`i'=value if  obsdate<pregstart & obsdate>=(new_studystart-365*5)
bysort patid: egen max_eos=max(eos_) 

keep if eos_!=.
bysort patid: gen high=1 if eos_>=0.5

bysort patid:egen tot=total(high)
rename tot tot_hieos

keep patid max_eos tot_hieos
duplicates drop
rename max eos

gen eos_high5=1 if eos>=0.5 
replace eos_high5=0 if eos<0.5 

save ${preg}cohort_eos0.5, replace




**# Baseline eosinophil percentage 
* 22.Oct: change "obsdate<=new_studystart" to "obsdate<pregstart" 
use ${preg}cohort_eos, clear

merge 1:m patid using ${preg}preg_totalwbc, keep(master match) nogen

gen twbc_base=value1 if  obs1<pregstart & obs1>=(new_studystart-365*5)
bysort patid: egen max_twbc_base=max(twbc_base) 

drop obs1 value1 twbc* new* third second preg*
duplicates drop

rename max_twbc_base twbc_base

order patid eos twbc_base 

gen eos_per_baseline= round(eos/twbc_base*100,0.1)
keep patid eos_per*
save ${preg}cohort_eos_percentage_before, replace



**# Eosinophil during pregnancy

use ${preg}preg_cohort_2, clear
merge 1:m patid using ${ocp}Eos_allpatients, keep(master match) nogen
drop medcodeid
drop if value==.

keep patid preg* second third value obs eosinophil

* During/trimesters
sort patid obsdate

gen eos_during=value if  obsdate>=pregstart & obsdate<=pregend
bysort patid: egen max_eos_dur=max(eos_during) 

gen eos_first=value if obsdate>=pregstart & obsdate<second
bysort patid: egen max_eos_first=max(eos_first)

gen eos_second=value if obsdate>=second & obsdate<third
bysort patid: egen max_eos_second=max(eos_second) 

gen eos_third=value if obsdate>=third & obsdate<pregend
bysort patid: egen max_eos_third=max(eos_third)

keep if eos_during!=.

bysort patid: gen high=1 if eos_during>=0.3
bysort patid: egen tot_dur=total(high)
rename tot_dur tot_hieos_dur

keep patid max_eos_* tot_hieos_dur
duplicates drop


gen eos_high_dur=1 if max_eos_dur>=0.3 
replace eos_high_dur=0 if max_eos_dur<0.3

gen eos_high_first=1 if max_eos_first>=0.3 
replace eos_high_first=0 if max_eos_first<0.3

gen eos_high_second=1 if max_eos_second>=0.3 
replace eos_high_second=0 if max_eos_second<0.3

gen eos_high_third=1 if max_eos_third>=0.3 
replace eos_high_third=0 if max_eos_third<0.3

rename (max_eos_dur max_eos_first max_eos_second max_eos_third) (eos_dur eos_fir eos_sec eos_thi)

save ${preg}cohort_eos_during, replace

**# EOS percentage during pregnancy
use ${preg}cohort_eos_during, clear
merge 1:m patid using ${preg}preg_totalwbc, keep(master match) nogen

gen twbc_during=value1 if  obs1>=pregstart & obs1<=pregend
bysort patid: egen max_twbc_during=max(twbc_during) 

gen twbc_first=value if obs1>=pregstart & obs1<second
bysort patid: egen max_twbc_first=max(twbc_first)

gen twbc_second=value if obs1>=second & obs1<third
bysort patid: egen max_twbc_second=max(twbc_second) 

gen twbc_third=value if obs1>=third & obs1<pregend
bysort patid: egen max_twbc_third=max(twbc_third)

drop obs1 value1 twbc* new* third second preg*
duplicates drop

rename (max_twbc_during max_twbc_first  max_twbc_second max_twbc_third) (twbc_dur twbc_first twbc_second twbc_third)

order patid eos_dur twbc_dur eos_fir twbc_first eos_sec twbc_second eos_thi twbc_third

gen eos_per_dur= round(eos_dur/twbc_dur*100,0.1)
gen eos_per_first=  round(eos_fir/twbc_first*100,0.1)
gen eos_per_sec=  round(eos_sec/twbc_sec*100,0.1)
gen eos_per_thi=  round(eos_thi/twbc_third*100,0.1)

keep patid eos_per*

save ${preg}cohort_eos_percentage_during, replace

**# Eosinophil after pregnancy

use ${preg}preg_cohort_2, clear
merge 1:m patid using ${ocp}Eos_allpatients, keep(master match) nogen
drop medcodeid
drop if value==.

keep patid new* preg* value obs eosinophil

sort patid obsdate
gen eos_`i'=value if  obsdate>=pregend & obsdate<=new_studyend
bysort patid: egen max_eos=max(eos_) 

keep if eos_!=.
bysort patid: gen high=1 if eos_>=0.3

bysort patid:egen tot=total(high)
rename tot tot_hieos

keep patid max_eos tot_hieos
duplicates drop
rename max eos_after

gen eos_high_after=1 if eos_after>=0.3 
replace eos_high_after=0 if eos_after<0.3 

save ${preg}cohort_eos_after, replace


**# EOS percentage after pregnancy
use ${preg}cohort_eos_after, clear
merge 1:m patid using ${preg}preg_totalwbc, keep(master match) nogen

gen twbc_after=value1 if  obs1>=pregend & obs1<=new_studyend
bysort patid: egen max_twbc_after=max(twbc_after) 

drop obs1 value1 twbc* new* third second preg*
duplicates drop

rename max_twbc_after twbc_after

order patid eos_after twbc_after 

gen eos_per_after= round(eos_after/twbc_after*100,0.1)
keep patid eos_per*
save ${preg}cohort_eos_percentage_after, replace


**# Smoking

use ${preg}preg_medcode, clear


merge m:1 medcode using ${code}smoking_Aurum_jan2024, keepusing(smoker ex never) nogen

keep if smoker!=. | ex!=. | never!=.

drop medcode
duplicates drop

save ${preg}smoking_temp, replace  //this is a temp file as the merging process above took ages


use ${preg}smoking_temp, clear

keep if (obs > new_studystart-365.25*2 ) & (obs<pregstart)

gen dif=pregstart-obs
sort patid dif

* Identify smokers
by patid: gen smoke=1 if smoker==1 & _n==1

by patid, sort : egen float tot_ex = total(ex)
by patid, sort : egen float tot_smok = total(smoker)
by patid, sort : egen float tot_never = total(never)
gen ignore=1 if (tot_ex==1 | tot_smok==1) & tot_never>3

by patid: egen ex_smoker=max(smoker)
by patid: egen ex_smoker2=max(ex)

* Identify ex-smoker
gen ex_smok=1 if ex_smoker==1 | ex_smoker2==1  //smoker or exsmoker
replace ex_smok=1 if ignore==1   
replace never=. if ex_smok==1   

*Identify non-smoker
by patid: gen no=1 if never==1 & _n==1

* Find the recent data
by patid: keep if _n==1

gen smoking=1 if no==1  //never
replace smoking=2 if ex_smok==1 & no==.  //ex-smoker
replace smoking=3 if smoke==1 //smoker


label define smoking 1 "Never" 2 "Ex-smoker" 3 "Smoker"
label value smoking smoking

keep patid smoking
duplicates drop

tab smoking, m

save ${preg}cohort_smoke, replace

**# Smoking during pregnancy

use ${preg}preg_medcode, clear
merge m:1 medcode using ${code}smoking_Aurum_jan2024, keepusing(smoker ex never) nogen
keep if obsdate >=pregstart & obsdate<=pregend 

keep if smoker!=. | ex!=. | never!=.

drop medcode
duplicates drop


gen dif=pregend-obs
sort patid dif

* Identify smokers
by patid: gen smoke=1 if smoker==1 & _n==1

by patid, sort : egen float tot_ex = total(ex)
by patid, sort : egen float tot_smok = total(smoker)
by patid, sort : egen float tot_never = total(never)
gen ignore=1 if (tot_ex==1 | tot_smok==1) & tot_never>3

by patid: egen ex_smoker=max(smoker)
by patid: egen ex_smoker2=max(ex)

* Identify ex-smoker
gen ex_smok=1 if ex_smoker==1 | ex_smoker2==1  //smoker or exsmoker
replace ex_smok=1 if ignore==1   
replace never=. if ex_smok==1   

*Identify non-smoker
by patid: gen no=1 if never==1 & _n==1

* Find the recent data
by patid: keep if _n==1

gen smoking=1 if no==1  //never
replace smoking=2 if ex_smok==1 & no==.  //ex-smoker
replace smoking=3 if smoke==1 //smoker


label define smoking 1 "Never" 2 "Ex-smoker" 3 "Smoker"
label value smoking smoking

keep patid smoking
rename smoking smoking_dur
duplicates drop

tab smoking_dur, m

save ${preg}cohort_smoke_during, replace



**# BMI
use ${preg}preg_cohort,clear

merge 1:m patid using ${ocp}bmi_value_all, keep(match) nogen

drop medcodeid term
duplicates drop
gen dif=abs(pregstart-obs)
sort patid obsdate 
drop study*
save ${preg}bmi_value_ALL, replace

* get height closet to first diagnosis: 5 years before and 1 year after pregnancy (Height won't be changed a lot)
use ${preg}bmi_value_ALL, clear
keep if obs > pregstart - 365.25*5 & obs < pregstart + 365.25

keep patid value dif height weight
keep if height==1
duplicates drop

drop if value<130 | value>250
summarize value, detail
sort patid dif
by patid: keep if _n==1
drop height
rename value height
keep patid height

save  ${preg}height, replace


* get weight closest to first diagnosis but before pregnancy
use ${preg}bmi_value_ALL, clear
keep if obs > pregstart - 365.25*5 & obs < pregstart
keep if weight==1
keep patid value dif
duplicates drop
summarize value, detail
drop if value<20 | value>250

sort patid dif
by patid: keep if _n==1

hist value

rename value weight
keep patid weight
duplicates drop
save  ${preg}weight, replace


* generate own bmi
preserve
use  ${preg}height, clear
merge 1:1 patid using ${preg}weight, nogen keep(match)
replace height=height/100
gen bmi_calc=weight/(height*height)
summarize bmi_calc
drop if bmi<15 
keep patid bmi
save  ${preg}calculated_bmi, replace
restore

* get BMI closest to age of diagnosis
use ${preg}bmi_value_ALL, clear
keep if bmi==1
drop weight height
keep patid value dif obsdate
duplicates drop
drop if value==.
summarize value
drop if value<10 | value>100
sort patid dif
bysort patid: keep if _n==1
rename value bmi
keep patid bmi
duplicates drop
save ${preg}calculated_bmi_2, replace

use ${preg}calculated_bmi_2, clear
merge 1:1 patid using ${preg}calculated_bmi
gen dif=abs(bmi-23)
gen dif_c=abs(bmi_c-23)
gen bmi_final=bmi if dif<dif_c & bmi!=.
replace bmi_final=bmi_c if dif_c<dif & bmi_c!=.
replace bmi_f=bmi if bmi_f==. & bmi!=.
keep patid bmi_f

replace bmi_f=round(bmi_f, 0.1)

count if bmi==.
gen bmi_cat=bmi

recode bmi_cat min/18.49=1 18.5/24.9=0 25/29.9=2 30/max=3
label define bmi_cat 1"underweight" 0 "normal"  2 "overweight" 3"obese"
label value bmi_cat bmi_cat
tab bmi_cat, mi

save  ${preg}bmi_final, replace

**# GP consultations for asthma
use ${preg}preg_medcode, clear
merge m:1 medcode using ${code}asthma_annualreview, nogen keepusing(review) keep(master match)
drop medcode
drop if obsdate <new_studystart | obsdate> new_studyend

sort patid obs
replace review=0 if review==.

gen gp_during=review if obsdate>=pregstart & obsdate<pregend
bysort patid: egen max_gp_during=max(gp_during)

gen gp_after=review if obsdate>=pregend & obsdate<new_studyend
bysort patid: egen max_gp_after=max(gp_after) 

keep patid max_gp_*
duplicates drop

rename (max_gp_during max_gp_after) (review_during review_after)

save ${preg}annualreview, replace 

**# Annual Review + Inhalers
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

/* NO USE : Previous code - classifing the latest review
use ${preg}preg_medcode, clear
merge m:1 medcode using ${code}asthma_annualreview, nogen keepusing(review) keep(master match)
drop medcode
drop if obsdate <new_studystart | obsdate> new_studyend

sort patid obs
replace review=0 if review==.

bysort patid: egen max_review=max(review) 
bysort patid: egen max_date=max(obsdate) if max_review==1
format max_date %td
drop obsdate review
duplicates drop

rename max_date obsdate
rename max_review review

gen review_cat=.
replace review_cat=1 if obs<pregstart
replace review_cat=2 if obs>=pregstart & obs<=pregend
replace review_cat=3 if obs>pregend
replace review_cat=0 if review_cat==.

tab review_cat

keep patid review*
*/

********************
* DURING pregnancy *
********************
**# Pulmembolism and DVT
use ${preg}preg_medcode, clear
merge m:1 medcodeid using${code}pulmembolism, keepusing(pulmembolism) keep (master match) nogen
merge m:1 medcodeid using${code}dvt, keepusing(dvt) keep (master match) nogen

keep if obs>=pregstart & obs<pregend

replace pulmembolism=0 if pulmembolism==.
replace dvt=0 if dvt==.


drop med obsdate
sort patid

foreach i in pulmembolism dvt {
by patid: egen max_`i'=max(`i')
}

* drop the original variable as only want the max_variable now
drop pulmembolism* dvt*
duplicates drop

* rename the variables 
rename (max_pulmembolism max_dvt) (pulmo dvt)

keep patid pulmo dvt

gen vte=.
replace vte=1 if pulmo==1  |  dvt==1
replace vte=0 if vte==.
save ${preg}cohort_VTE, replace



**# Gestational Diabetes
*** from AURUM
use ${preg}preg_medcode, clear
merge m:1 medcodeid using${code}GDM_V2, keep(master match) nogen
sort patid obsdate
replace gdm=0 if gdm==.
keep if obsdate>=pregstart & obsdate<pregend

by patid: egen max_gdm=max(gdm)
keep patid new_studystart new_studyend pregstart pregend max_gdm
duplicates drop

rename max_gdm gdm

save ${preg}aurum_GDM, replace

*** from HES
use ${preg}preg_cohort_2, clear
keep patid new* pregstart pregend
sort patid
merge 1:m patid using ${linked}HES_primary, nogen keep(match)
keep if admidate2>=pregstart & admidate2<pregend 
keep if substr(icd,1,4)=="O24." | substr(icd,1,4)=="O24"
gen hes_gdm=1

sort patid admi
keep patid new* pregstart pregend hes_gdm 
duplicates drop
save ${preg}HES_GDM, replace

*** combine
use ${preg}aurum_GDM, clear
merge 1:1 patid using${preg}HES_GDM, keep(master match using) nogen
replace hes_gdm=0 if hes_gdm==.

keep if gdm==1 | hes_gdm==1
gen GDM=1

drop gdm hes
save ${preg}all_GDM, replace

**# Gestational hypertension
*** from AURUM
use ${preg}preg_medcode, clear
merge m:1 medcodeid using${code}GestHTN_V2, keep(master match) nogen
sort patid obsdate
replace gestHTN=0 if gestHTN==.
keep if obsdate>=pregstart & obsdate<pregend

by patid: egen max_htn=max(gestHTN)
keep patid new_studystart new_studyend pregstart pregend max_htn
duplicates drop

rename max_htn gestHTN

save ${preg}aurum_gestHTN, replace

*** from HES
use ${preg}preg_cohort_2, clear
keep patid new* pregstart pregend
sort patid
merge 1:m patid using ${linked}HES_primary, nogen keep(match)
keep if admidate2>=pregstart & admidate2<pregend 
keep if substr(icd,1,4)=="O13" | substr(icd,1,4)=="O10" |substr(icd,1,4)=="O10.0" | substr(icd,1,4)=="O10.9" |substr(icd,1,4)=="O11" |substr(icd,1,4)=="O16" | substr(icd,1,4)=="O10.1" | substr(icd,1,4)=="O10.2" | substr(icd,1,4)=="O10.3" | substr(icd,1,4)=="O10.4"
gen hes_gestHTN=1

keep patid new* preg* hes_gestHTN 
duplicates drop

save ${preg}HES_gestHTN, replace

*** combine
use ${preg}aurum_gestHTN, clear
merge 1:1 patid using${preg}HES_gestHTN, keep(master match using) nogen
replace hes_gestHTN=0 if hes_gestHTN==.

keep if gestHTN==1 | hes_gestHTN==1
gen GestHTN=1

drop gestHTN hes
save ${preg}all_GestHTN, replace


**# Pre-eclampsia
*** from AURUM
use ${preg}preg_medcode, clear
merge m:1 medcodeid using${code}Preeclampsia_V2, keep(master match) nogen
sort patid obsdate
replace preeclam=0 if preeclam==.
keep if obsdate>=pregstart & obsdate<pregend

by patid: egen max_pre=max(preeclam)
keep patid new_studystart new_studyend pregstart pregend max_pre
duplicates drop

rename max_pre preeclampsia

save ${preg}aurum_preeclampsia, replace

*** from HES
use ${preg}preg_cohort_2, clear
keep patid new* pregstart pregend
sort patid
merge 1:m patid using ${linked}HES_primary, nogen keep(match)
keep if admidate2>=pregstart & admidate2<pregend 
keep if substr(icd,1,4)=="O14" | substr(icd,1,4)=="O14." | substr(icd,1,4)=="O15" | substr(icd,1,4)=="O15."

gen hes_preeclampsia=1
keep patid new* preg* hes_preeclampsia 
duplicates drop

save ${preg}HES_preeclampsia, replace

*** combine
use ${preg}aurum_preeclampsia, clear
merge 1:1 patid using${preg}HES_preeclampsia, keep(master match using) nogen
replace hes_preeclampsia=0 if hes_preeclampsia==.

keep if preeclampsia==1 | hes_preeclampsia==1
gen Preeclampsia=1

drop preeclampsia hes
save ${preg}all_preeclampsia, replace

**************************************
* AFTER pregnancy: Pregnancy outcome *
**************************************
**# Low birthweight, Intrauterine growth retardation, Cesarean,Preterm delivery

**# Low birthweight and Intrauterine growth retardation
*** from AURUM
use ${preg}preg_medcode, clear
merge m:1 medcodeid using${code}lowbw_updated_dec2024, keep(master match) nogen
sort patid obsdate
replace lowbw=0 if lowbw==.
keep if obsdate>=pregstart & obsdate<new_studyend

by patid: egen max_lowbw=max(lowbw)
keep patid new_studystart new_studyend pregstart pregend max_lowbw
duplicates drop

rename max_lowbw lowbw

save ${preg}aurum_lowbw, replace


use ${preg}preg_medcode, clear
merge m:1 medcodeid using${code}iugr_updated_dec2024, keepusing(iugr) keep (master match) nogen
merge m:1 medcodeid using${code}cesarean, keepusing(cesarean) keep (master match) nogen
merge m:1 medcodeid using${code}preterm, keepusing(preterm) keep (master match) nogen

keep if obs>=pregstart & obs<new_studyend

replace iugr=0 if iugr==.
replace cesarean=0 if cesarean==.
replace preterm=0 if preterm==.

drop med obsdate
sort patid

foreach i in iugr cesarean preterm{
by patid: egen max_`i'=max(`i')
}

* drop the original variable as only want the max_variable now
drop iugr* cesarean* preterm*
duplicates drop

* rename the variables 
rename (max_iugr max_cesarean max_preterm) (iugr cesarean preterm)

keep patid iugr cesarean preterm
save ${preg}cohort_preg_outcomes, replace



*******************************************
**# Asthma exacerbations before pregnancy *
*******************************************
use ${preg}preg_cohort, clear
keep patid new* preg*
merge 1:m patid  using ${linked}HES_primary, keep(master match) nogenerate 
keep if  admi>=new_studystart & admi<pregstart
keep if substr(icd,1,4)=="J45." | substr(icd,1,3)=="J46"
drop icd disch
duplicates drop
gen hosp_exac=1
bysort patid:egen hosp_tot=total(hosp_exac)
rename admidate2 date
keep patid date hosp_exac hosp_tot
duplicates drop
save ${preg}hist_hosp_exac, replace


** A&E **
use ${preg}preg_cohort, clear
keep patid new* preg*
merge 1:m patid using ${linked}AE_final, nogen keep(master match)
keep if  ae>=new_studystart & ae<pregstart
keep if strmatch(diag, "251")
gen ae_exac=1
bysort patid:egen ae_tot=total(ae_exac)
rename ae_date date
keep patid date ae_exac ae_tot
duplicates drop
save ${preg}hist_ae, replace

************** GP exacerbations ***************
*Merge in asthma therapy data
use ${preg}preg_cohort, clear
merge 1:m patid using ${summary}AsthmaTherapy_AllADULTS, keep(master match) nogenerate
replace issue=. if issue<new_studystart | issue>(pregstart)
drop term dose_cat age study* pracid
duplicates drop
save ${preg}hist_asthmatherapy, replace

* (3) Identify exacerbations
* GP exacerbation
use ${preg}preg_cohort, clear
keep patid new* preg*
merge 1:m patid using ${preg}hist_asthmatherapy, keepusing(issue group dose) keep(match) nogen
sort patid issue
keep if issue>=new_studystart & issue<pregstart
keep if group==11
keep if dose==5

drop group dose pregnumber
duplicates drop

save ${preg}hist_ocs, replace


* remove if OCS on day of steroid
use ${preg}preg_cohort, clear
keep patid new_studystart new_studyend preg*

merge 1:m patid using ${summary}Aurum_MEDCODES_AllADULTS, keep(master match) nogenerate

drop if obs<new_studystart | obs>pregstart
merge m:1 medcode using "/home/blee5/Documents/DS216/share/Codelists/SteroidsManagedDiseases_aurum.dta", keep(match) nogen
keep patid obs steroid
duplicates drop
rename obs issuedate

save ${preg}hist_3month_steroiddates, replace

use ${preg}hist_ocs, clear
merge 1:1 patid issuedate using ${preg}hist_3month_steroiddates, nogen keep(master)
drop steroid

drop if issue==.
rename issue date
gen ocs=1
save ${preg}hist_gp, replace


*Merge all exacerbations
use ${preg}hist_gp, clear
merge 1:1 patid date using ${preg}hist_hosp_exac, nogen
merge 1:1 patid date using ${preg}hist_ae, nogen
sort patid date

gen day14=1 if patid[_n]==patid[_n+1] & (date[_n+1]-date[_n]<14)
replace ae_exac=1 if ae_exac[_n+1]==1 & day14==1 & patid[_n]==patid[_n+1]
replace hosp_exac=1 if hosp_exac[_n+1]==1 & day14==1 & patid[_n]==patid[_n+1]
replace ocs=. if (ae_exac==1 | hosp_exac==1)
replace ae_exac=. if hosp_exac==1

replace day14=2 if day14[_n-1]==1 & patid[_n]==patid[_n-1] & (date[_n]-date[_n-1]<14)
drop if day14==2

gen exac_type=1 if ocs==1 
replace exac_type=2 if ae_exac==1
replace exac_type=3 if hosp_exac==1
label define exac_type 0 "None" 1"GP only" 2 "AE" 3 "Hospital" 
label value exac_type exac_type

keep patid date exac
gen exacerbation=1 
bysort patid: egen total_exac=total(exacerbation)
drop exacerbation date exac_type
duplicates drop

rename total_exac his_total_exac
save ${preg}hist_all_attacks, replace

**************************************************************************************
**# Ethnicity
*from AURUM
use ${code}Ethnicity_eleanor, clear
drop if database==1 | database==4
keep medcodeid ethnic_*
duplicates drop
save ${code}aurum_ethnicity, replace

use ${preg}preg_medcode, clear
merge m:1 medcodeid using ${code}aurum_ethnicity, keep(match) nogen

sort patid obsdate

keep if obsdate<studyend
bysort patid (obsdate): keep if _n==_N

keep patid ethnic_6 
duplicates drop
rename ethnic_6 ethnic

save ${preg}preg_aurum_ethnicity, replace

/*
ethnic_6:
           1 White
           2 Mixed
           3 Asian
           4 Black
           5 Other
           6 Unknown
*/


*from HES
use ${code}hesae_patientlist, clear // This is from HES data calsed "hesae_patient_22_002086"
keep patid gen_ethnicity
gen ethnic=gen_ethnicity
replace ethnic=subinstr(ethnic, "Chinese", "3", .)
replace ethnic=subinstr(ethnic, "Bangladesi", "3", .)
replace ethnic=subinstr(ethnic, "Oth_Asian", "3", .)
replace ethnic=subinstr(ethnic, "Pakistani", "3", .)
replace ethnic=subinstr(ethnic, "Indian", "3", .)
replace ethnic=subinstr(ethnic, "Bl_Afric", "4", .)
replace ethnic=subinstr(ethnic, "Bl_Carib", "4", .)
replace ethnic=subinstr(ethnic, "Bl_Other", "4", .)
replace ethnic=subinstr(ethnic, "Mixed", "2", .)
replace ethnic=subinstr(ethnic, "White", "1", .)
replace ethnic=subinstr(ethnic, "Other", "5", .)
replace ethnic=subinstr(ethnic, "Unknown", "6", .)


destring ethnic, replace
label define ethnic 1 "White" 2 "Mixed" 3 "Asian" 4 "Black" 5 "Other" 6 "Unknown", replace
label value ethnic ethnic
drop gen

save ${preg}hes_ethnicity, replace


use ${preg}preg_cohort, clear  
merge 1:1 patid using ${preg}preg_aurum_ethnicity, keep(match master)  nogenerate
keep if ethnic==.
keep patid ethnic
rename ethnic ethnic_aurum
save ${preg}missing_ethnicity, replace

use ${preg}missing_ethnicity, clear
merge 1:1 patid using ${preg}hes_ethnicity, keep(match)  nogenerate
drop ethnic_aurum
rename ethnic ethnic_hes
save ${preg}hes_ethnicity2, replace

use ${preg}preg_cohort, clear  
merge 1:1 patid using ${preg}preg_aurum_ethnicity, keep(match master)  nogenerate
merge 1:1 patid using ${preg}hes_ethnicity2, keep(match master)  nogenerate
gen ethnicity=.
replace ethnicity=ethnic if ethnic!=.
replace ethnicity=ethnic_hes if ethnic_hes!=.
replace ethnicity=6 if ethnicity==.
label define ethnicity 1 "White" 2 "Mixed" 3 "Asian" 4 "Black" 5 "Other" 6 "Unknown", replace
label value ethnicity ethnicity

keep patid ethnicity
save ${preg}simple_ethnicity, replace

* depression/anxiety
**# Depression
use ${preg}preg_medcode, clear

drop if obs>pregstart
merge m:1 medcode using${code}Anxiety_Depression, nogen keepusing(anx_dep) keep(master match)

replace anx_dep=0 if anx_dep==.

drop med obsdate
sort patid

by patid: egen max_anx_dep=max(anx_dep)

drop anx_dep 

duplicates drop
rename max_anx_dep anx_dep

keep patid anx_dep 
save ${preg}cohort_anx_depression, replace

* multigravida
use ${preg}preg_cohort, clear
gen multigravida=1 if pregnumber>1 
replace multigravida=0 if multigravida==.
keep patid multigravida
save ${preg}multigravida, replace


