cd "/home/blee5/Documents/DS230/share/Bohee/Pregnancy/"
pwd

global preg "/data/master/DS220/share/BOHEE/Pregnancy/Data/"


**# Multivariable logistic regression models
use ${preg}cohort_analysis, clear
merge 1:1 patid using ${preg}ics_change_censored, keep(master match) nogen
merge 1:1 patid using ${preg}therapy_change_censor, keep(master match) nogen

label define therapy 0 "no treatment" 1 "Reliever only" 2 "Intermittent ICS " 3 "Regular ICS" 4"Intermittent ICS+add-on" 5 "Regular ICS+add-on" 6 "Others", replace
label value therapy therapy

drop if therapy==6

save ${preg}stratified_analysis, replace

**# Stratified analysis
use ${preg}stratified_analysis, clear


* Preexisting diabetes
logit dur_event i.diabetes i.matage_group i.ethnicity i.bmi_cat i.imd i.anx_dep i.atopy i.therapy i.eos_high i.his_exac  i.ther_change_censor  i.review_before  i.smoking_dur i.multigravida, or


* GDM
logit dur_event i.GDM i.matage_group i.ethnicity i.bmi_cat i.imd i.anx_dep i.atopy i.therapy i.eos_high i.his_exac  i.ther_change_censor  i.review_before  i.smoking_dur i.multigravida, or

* Preexisting diabtes or GDM
gen maternalDM=.
replace maternalDM=1 if diabetes==1 | GDM==1
replace maternalDM=0 if maternalDM==.

logit dur_event i.maternalDM i.matage_group i.ethnicity i.bmi_cat i.imd i.anx_dep i.atopy i.therapy i.eos_high i.his_exac  i.ther_change_censor  i.review_before  i.smoking_dur i.multigravida, or

* BEC before pregnancy
logit dur_event i.eos_high i.matage_group i.ethnicity i.bmi_cat i.imd i.anx_dep i.atopy i.therapy i.his_exac  i.ther_change_censor  i.review_before  i.smoking_dur i.multigravida, or

* Age (<30 vs >=30)
gen age2=.
replace age2=0 if matage<30
replace age2=1 if matage>=30

logit dur_event i.age2 i.eos_high i.ethnicity i.bmi_cat i.imd i.anx_dep i.atopy i.therapy i.his_exac  i.ther_change_censor  i.review_before  i.smoking_dur i.multigravida, or

* GWG
global summary "/data/master/DS220/share/Summary_datasets/"
global code "/data/master/DS220/share/Codelists/"


forvalue i=1/6 {
	use ${summary}Aurum_VALUES_Adults`i', clear
	merge m:1 medcodeid using ${code}bmi_Aurum, keep(match) nogen
	compress
	duplicates drop
	save ${preg}bmi_value_`i', replace
}


use ${preg}bmi_value_1, clear


forvalues i=2/6 {
	append using ${preg}bmi_value_`i'
	}

save ${preg}bmi_value_all, replace


use ${preg}stratified_analysis, clear
keep patid new* pregstart secondtrim thirdtrim pregend*
merge 1:m patid using ${preg}bmi_value_all, keepusing(value obsdate bmi weight height keep) keep(match) nogen
sort patid obsdate

gen dif=abs(new_studystart-obs)

keep if obs >pregstart & obs <= pregend
keep if weight==1
keep patid value dif
duplicates drop
summarize value, detail
drop if value<20 | value>250

sort patid dif
by patid: keep if _n==_N

hist value

rename value pregweight
keep patid pregweight
duplicates drop

save  ${preg}preg_weight, replace



use ${preg}stratified_analysis, clear
keep patid new* pregstart secondtrim thirdtrim pregend*
merge 1:m patid using ${preg}bmi_value_all, keepusing(value obsdate bmi weight height keep) keep(match) nogen
sort patid obsdate

gen dif=abs(new_studystart-obs)

keep if obs > pregstart - 365.25*5 & obs < pregstart
keep if weight==1
keep patid value dif
duplicates drop
summarize value, detail
drop if value<20 | value>250

sort patid dif
by patid: keep if _n==1

hist value

rename value baselineweight
keep patid baselineweight
duplicates drop


save  ${preg}baseline_weight, replace




use ${preg}stratified_analysis, clear
merge 1:1 patid using ${preg}baseline_weight, keep(match master) nogen
merge 1:1 patid using ${preg}preg_weight, keep(match master) nogen

gen dif=pregweight-baselineweight

sum dif

drop if dif<0

fre bmi_cat
* normal
sum dif if bmi_cat==0
* underweight
sum dif if bmi_cat==1
* overweight
sum dif if bmi_cat==2

*obese
sum dif if bmi_cat==3


* simple categories
gen gwg=.
replace gwg=0 if dif>=11 & dif<=16
replace gwg=1 if dif<11
replace gwg=2 if dif>16
replace gwg=9 if dif==.

label define gwg 0"normal" 1 "underweightgain"  2 "moreweightgain" 9 "Unknown", replace
label value gwg gwg
tab gwg, mi


logit dur_event i.gwg i.matage_group i.ethnicity i.bmi_cat i.imd i.anx_dep i.atopy i.therapy i.eos_high i.his_exac  i.ther_change_censor  i.review_before  i.smoking_dur i.multigravida, or

* GWG relative to recommendations
gen gwgrecomm=.
* meets recommendations
replace gwgrecomm=0 if bmi_cat==0 & (dif>=11 & dif<=16)
replace gwgrecomm=0 if bmi_cat==1 & (dif>=13 & dif<=18)
replace gwgrecomm=0 if bmi_cat==2 & (dif>=7 & dif<=11)
replace gwgrecomm=0 if bmi_cat==3 & (dif>=5 & dif<=9)

* underrecommendations
replace gwgrecomm=1 if bmi_cat==0 & (dif<11)
replace gwgrecomm=1 if bmi_cat==1 & (dif<13)
replace gwgrecomm=1 if bmi_cat==2 & (dif<7)
replace gwgrecomm=1 if bmi_cat==3 & (dif<5)

* over recommendations
replace gwgrecomm=2 if bmi_cat==0 & (dif>16)
replace gwgrecomm=2 if bmi_cat==1 & (dif>18)
replace gwgrecomm=2 if bmi_cat==2 & (dif>11)
replace gwgrecomm=2 if bmi_cat==3 & (dif>9)
replace gwgrecomm=9 if dif==.
replace gwgrecomm=9 if gwgrecomm==.

label define gwgrecomm 0"normal" 1 "undermeet"  2 "overmeet" 9 "Unknown", replace
label value gwgrecomm gwgrecomm
tab gwgrecomm, mi

logit dur_event i.gwgrecomm i.matage_group i.ethnicity i.bmi_cat i.imd i.anx_dep i.atopy i.therapy i.eos_high i.his_exac  i.ther_change_censor  i.review_before  i.smoking_dur i.multigravida, or


