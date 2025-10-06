cd "/home/blee5/Documents/DS220/share/BOHEE/Pregnancy/"
pwd

global summary "/data/master/DS220/share/Summary_datasets/"
global linked "/home/blee5/Documents/DS220/share/AMIR/Data/Linkage/"
global datacar "/data/master/DS220/share/CARLOS/Pregnancy/"
global pregdata "/data/master/DS220/share/Linkage/Pregnancy_aurum/"
global code "/data/master/DS220/share/Codelists/"
global preg "/data/master/DS220/share/BOHEE/Pregnancy/Data/"
global ocp "/home/blee5/Documents/DS220/share/BOHEE/OCPData/"

**# Set up pregnancy cohort 

* (1) Identify women from asthma cohort
use ${summary}AsthmaPatients_AURUM_Adults, clear
keep if gender==2
 * N=1,146,385
 
 * (2) Identify women who were pregnant
merge 1:m patid using ${pregdata}pregnancy_register_21_001656_DM, keep(match) nogen

* (3) Identify 1t least 12 months of data before the pregnancy start date and at least 12 months after end date of pregnancy 

generate pregstart_num= date(pregstart, "DMY")
format pregstart_num %d

generate pregend_num= date(pregend, "DMY")
format pregend_num %d

drop pregstart pregend
rename pregstart_num pregstart
rename pregend_num pregend

drop gender mbl babypatid babymob babyyob 
order pracid patid dob study* age_start pregid pregstart pregend 

drop if pregstart < studystart
drop if pregend > studyend

drop if (pregstart < studystart + 365.25) | (pregend >= studyend-365.5) 

count if pregstart-studystart<365.25
count if studyend-pregend<365.25

* (4) keep pregnancy enters the third trimester (at least 28 weeks)
gen gestweeks=round(gestdays/7, 1.0)
drop if gestweeks<28


* (5) Identify the latest pregnancy
sort patid pregstart
drop pregnumber totalpregs


* (5-1) I think we should exclude next pregnancy < prior pregnancy + 365.25
bysort patid: gen gap=pregstart[_n+1]-pregend[_n]
drop if gap<0

bysort patid (pregstart): egen max_gap=max(gap)
drop if gap<365.25


* (5-2) Assign new number of pregnancy during the study period --> Select the latest pregnancy 
bysort patid: gen pregnumber=_n
order pracid  patid pregid dob age_start study*  pregstart pregend gestdays gestweeks matage outcome pregnumber 

bysort patid (pregnumber): keep if _n==_N
* N=63,078
drop gap



* (6) Remove Still birth/miscarriage/TOP/ probable TOP/ ectopic/molar/blighted ovum/loss/unknown
/* outcome 1=live birth
 2= still birth
 3= 1 and 2
 4= miscarriage
 5= TOP
 6= Probable TOP,
 7= Ectopic
 8= Molar
 9= Blighted ovum
 10= Unspecified loss
 11= Delivery based on a third trimester pregnancy record
 12= Delivery based on a late pregnancy record
 13= Outcome unknown
*/

drop if outcome==2 | outcome==3 | outcome==4 | outcome==5 | outcome==6 | outcome==7 | outcome==8 | outcome==9 | outcome==10 | outcome==13
* N=342 patients removed

* Remove unrealistic gestdays >300
drop if gestdays >300
* N=61,534 patients


* N of preterm, N of multiple
rename preterm_ev preterm
rename multiple_ev multiple

tab preterm
tab multiple
drop startsource startadj endsource endadj firstanten 

save ${preg}preg_ptlist, replace



**# Set up timeframes
use ${preg}preg_ptlist, clear

* (1) Set up the new study start and the new studyend date
gen new_studystart=pregstart-365.25
gen new_studyend=pregend+365.25

* (1-1) Replace the new studystart date for women with multiple pregnancies
replace new_studystart= pregstart - 365.25 if (max_gap>=365.25 & pregnumber>1)

format new* %td 

* (2) Add seasons and trimester start dates
foreach var of varlist pregstart`j' pregend`j' {

gen season`var'=.
replace season`var' =1 if month(`var')== 12 | month(`var') ==1 | month(`var') ==2 
replace season`var' =2 if month(`var')== 3 | month(`var') ==4 | month(`var') ==5 
replace season`var' =3 if month(`var')== 6 | month(`var') ==7 | month(`var') ==8 
replace season`var' =4 if month(`var')== 9 | month(`var') ==10 | month(`var') ==11

label values season`var' season
	
}

label define season 1 "winter" 2 "spring" 3 "summer" 4 "autumn"
label values seasonpregend* season
label values seasonpregstart* season


generate secondtrim2 = date(secondtrim, "DMY")
format secondtrim2 %td 
drop secondtrim 
rename secondtrim2 secondtrim

generate thirdtrim2 = date(thirdtrim, "DMY")
format thirdtrim2 %td 
drop thirdtrim 
rename thirdtrim2 thirdtrim

* (9)Divide the periods of before/after pregnancy quarterly
gen q1=.
gen q2=.
gen q3=.
gen q4=.
gen q5=.
gen q6=. 

replace q1=new_studystart+365/4
replace q2=q1+365/4
replace q3=q2+365/4
replace q4=pregend + 365/4
replace q5=q4+365/4
replace q6=q5+365/4

order pracid  patid pregid dob age_start studystart new_studystart q1 q2 q3 pregstart secondtrim  thirdtrim pregend q4 q5 q6 new_studyend studyend gestdays gestweeks matage outcome pregnumber preterm multiple season*


forvalues i=1/3 {
rename q`i' preQ`i'
format preQ`i' %td
} 

forvalues i=4/6 {
local j=`i'-3

rename q`i' postQ`i'
rename postQ`i' postQ`j'  
format postQ`j' %td
} 


drop max_gap
save ${preg}preg_cohort, replace


********************
**# Asthma Therapy *
********************
use ${preg}preg_cohort, clear
merge 1:m patid using ${summary}AsthmaTherapy_AllADULTS, keep(match) nogen
save ${preg}preg_therapy_All, replace

*Baseline severity
preserve
keep if issue<pregstart & issue>=nstudystart

*As this is asthma maintainance- OCS was dropped.
drop if group==11

gen saba=1 if group==1
gen ics=1 if group==7 | group==9 | group==19
gen laba=1 if group==6 | group==7 | group==8
gen lama=1 if group==8 | group==8
gen ltra=1 if group==17
gen theo=1 if group==14

bysort patid: egen saba_tot=total(saba)
bysort patid: egen ics_tot=total(ics)

bysort patid: egen icsm=max(ics)
bysort patid: egen labam=max(laba)
bysort patid: egen lamam=max(lama)
bysort patid: egen ltram=max(ltra)
bysort patid: egen theom=max(theo)
drop group saba ics laba lama ltra theo issue dose

duplicates drop
drop if patid==.

gen therapy=0 if saba_tot==0 & ics_tot==0 & labam==. & lamam==. &  ltram==. & theo==.  

replace therapy=1 if saba_tot>=1 & ics_tot==0 & labam==. & lamam==. &  ltram==. & theo==.  
replace therapy=2 if ics_tot>0 & ics_tot<4 & labam==.                          
replace therapy=3 if ics_tot>=4 & labam==.                                                   
replace therapy=4 if ics_tot>0 & ics_tot<4 & labam==1 | ltram==1 & lamam==.  & theo==.   
replace therapy=5 if ics_tot>=4 & labam==1 | ltram==1 & lamam==. &  ltram==. & theo==.    
replace therapy=6 if therapy==. 

label define therapy 0 "no treatment" 1 "SABA only" 2 "ICSonly infreq " 3 "ICSonly regular" 4"ICS+LABA/LTRA infreq" 5 "ICS+LABA/LTRA freq" 6 "Others"
label value therapy therapy

gen saba_cat=1 if saba_tot<3
replace saba_cat=2 if saba_tot>2 & saba_tot<9
replace saba_cat=3 if saba_tot>=8

label define saba_cat 1"1-2" 2"3-8" 3">8"
label value saba_cat saba_cat

drop laba lama ltra theo icsm
keep patid therapy* saba_cat 
duplicates drop

save ${preg}before_preganancy_inhalers, replace
restore

******************************************************
**# Number of inhalers before/during/after pregnancy *
******************************************************
use ${preg}preg_therapy_All, clear

keep if issue>=new_studystart & issue<new_studyend

*As this is asthma maintainance- OCS was dropped.
drop if group==11

gen saba=1 if group==1
gen ics=1 if group==7 | group==9 | group==19
gen laba=1 if group==6 | group==7 | group==8
gen lama=1 if group==8 | group==8
gen ltra=1 if group==17
gen theo=1 if group==14

drop term groups dose dose_cat
drop if issue==.
sort patid issue

foreach i in saba ics laba lama ltra {
by patid: egen `i'_pre_tot=total(`i') if issue<pregstart
by patid: egen `i'_dur_tot=total(`i') if issue>=pregstart & issue<=pregend
by patid: egen `i'_post_tot=total(`i') if issue>pregend
}

drop saba ics laba lama ltra issue
duplicates drop

foreach i in saba ics laba lama ltra {
by patid: egen m`i'_pre_tot=max(`i'_pre_tot) 
by patid: egen m`i'_dur_tot=max(`i'_dur_tot) 
by patid: egen m`i'_post_tot=max(`i'_post_tot) 
}

keep patid m*
duplicates drop

foreach i in saba ics laba lama ltra {
rename m`i'_pre_tot `i'_pre_tot 
rename m`i'_dur_tot `i'_dur_tot 
rename m`i'_post_tot `i'_post_tot 
replace `i'_pre_tot=0 if `i'_pre_tot ==.
replace `i'_dur_tot=0 if `i'_dur_tot ==.
replace `i'_post_tot=0 if `i'_post_tot ==.
}


* for LAMA and LTRA consider patient taking it if had at least 2 scripts in the time period
* rename variable to yes/no instead of total number

foreach i in lama ltra {
rename `i'_pre_tot `i'_pre_yes 
rename `i'_dur_tot `i'_dur_yes 
rename `i'_post_tot `i'_post_yes 
replace `i'_pre_yes=1 if `i'_pre_yes>1
replace `i'_dur_yes=1 if `i'_dur_yes>1
replace `i'_post_yes=1 if `i'_post_yes>1
}


* create variable for ICS alone and one for ICS+add-one (ltra or laba)
gen ics_add_pre_yes=1 if ics_pre_tot>0 & (laba_pre_tot>0 | ltra_pre_yes==1)
replace ics_add_pre_yes=0 if ics_add_pre_yes==.
gen ics_add_dur_yes=1 if ics_dur_tot>0 & (laba_dur_tot>0 | ltra_dur_yes==1)
replace ics_add_dur_yes=0 if ics_add_dur_yes==.
gen ics_add_post_yes=1 if ics_post_tot>0 & (laba_post_tot>0 | ltra_post_yes==1)
replace ics_add_post_yes=0 if ics_add_post_yes==.
drop laba*

order patid saba_pre ics_pre ics_add_pre ltra_pre lama_pre saba_dur ics_dur ics_add_dur ltra_dur lama_dur saba_post ics_post ics_add_post ltra_post lama_post

save ${preg}pregnacy_alltime_asthma_therapy, replace


***************************************
**# Event during the follow-up period *
***************************************
use ${preg}preg_cohort, clear
keep patid new* 
merge 1:m patid  using ${linked}HES_primary, keep(master match) nogenerate 
drop if admi>new_studyend | admi<new_studystart
keep if substr(icd,1,4)=="J45." | substr(icd,1,3)=="J46"
drop icd disch
duplicates drop
gen hosp_exac=1
bysort patid:egen hosp_tot=total(hosp_exac)
rename admidate2 date
keep patid date hosp_exac hosp_tot
duplicates drop
save ${preg}cohort_hosp_exac, replace


** A&E **
use ${preg}preg_cohort, clear
keep patid new* 
merge 1:m patid using ${linked}AE_final, nogen keep(master match)
drop if ae>new_studyend | ae<new_studystart
keep if strmatch(diag, "251")
gen ae_exac=1
bysort patid:egen ae_tot=total(ae_exac)
rename ae_date date
keep patid date ae_exac ae_tot
duplicates drop
save ${preg}cohort_ae, replace

************** GP exacerbations ***************
*Merge in asthma therapy data
use ${preg}preg_cohort, clear
merge 1:m patid using ${summary}AsthmaTherapy_AllADULTS, keep(master match) nogenerate
replace issue=. if issue<new_studystart | issue>(new_studyend)
drop term dose_cat age study* pracid
duplicates drop
save ${preg}pregnancy_cohort_asthmatherapy, replace

* (3) Identify exacerbations
* GP exacerbation
use ${preg}preg_cohort, clear
merge 1:m patid using ${preg}pregnancy_cohort_asthmatherapy, keepusing(issue group dose) keep(match) nogen

replace issue=. if issue< new_studystart | issue> new_studyend
replace issue=. if group!=11
replace issue=. if dose!=5

drop group dose
duplicates drop

save ${preg}preg_ocs, replace


* remove if OCS on day of steroid
use ${preg}preg_cohort, clear
keep patid new_studystart new_studyend

merge 1:m patid using ${summary}Aurum_MEDCODES_AllADULTS, keep(master match) nogenerate

drop if obs<new_studystart | obs>new_studyend
merge m:1 medcode using "/home/blee5/Documents/DS216/share/Codelists/SteroidsManagedDiseases_aurum.dta", keep(match) nogen
keep patid obs steroid
duplicates drop
rename obs issuedate

save ${preg}preg_3month_steroiddates, replace

use ${preg}preg_ocs, clear
merge 1:1 patid issuedate using ${preg}preg_3month_steroiddates, nogen keep(master)
drop steroid

drop if issue==.
rename issue date
gen ocs=1
save ${preg}cohort_gp, replace


*Merge all exacerbations
use ${preg}cohort_gp, clear
merge 1:1 patid date using ${preg}cohort_hosp_exac, nogen
merge 1:1 patid date using ${preg}cohort_ae, nogen
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
drop exacerbation 
duplicates drop

save ${preg}all_attacks, replace

*** getting AE visits that did not go to hospital admission within 7 days
use ${preg}cohort_ae, clear
merge 1:1 patid date using ${preg}cohort_hosp_exac, nogen
keep patid date ae_exac hosp_exac
drop if hosp==1 & ae==1
sort patid date
gen day7=1 if patid[_n]==patid[_n+1] & (date[_n+1]-date[_n]<7)
replace day7=2 if day7[_n-1]==1 & patid[_n]==patid[_n-1] & (date[_n]-date[_n-1]<7)
drop if day7==1 | day7==2
keep patid date ae
keep if ae==1

save ${preg}preg_ae_only, replace



**# Order number
** to do rates as forvalues first change variables names so number order
use ${preg}cohort_gp, clear
rename (new_studystart preQ1 preQ2 preQ3 pregstart secondtrim thirdtrim pregend postQ1 postQ2 postQ3 new_studyend) (preg1 preg2 preg3 preg4 preg5 preg6 preg7 preg8 preg9 preg10 preg11 preg12)
rename date issuedate
save ${preg}preg_ocs_order, replace

use ${preg}preg_cohort, clear
rename (new_studystart preQ1 preQ2 preQ3 pregstart secondtrim thirdtrim pregend postQ1 postQ2 postQ3 new_studyend) (preg1 preg2 preg3 preg4 preg5 preg6 preg7 preg8 preg9 preg10 preg11 preg12)
save ${preg}preg_cohort_order, replace

use ${preg}preg_ae_only, clear
merge m:1 patid using ${preg}preg_cohort_order, nogen
rename date issuedate
save ${preg}preg_ae_only_order, replace

use ${preg}cohort_hosp_exac, clear
merge m:1 patid using ${preg}preg_cohort_order, nogen
rename date issuedate
save ${preg}preg_hes_order, replace

use ${preg}all_attacks, clear
merge m:1 patid using ${preg}preg_cohort_order, nogen
rename date issuedate
save ${preg}all_attacks_order, replace

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

** See attackes by exac type in a separte dofile called "Descriptive Results"


*************************
**# Merge all variables *
*************************
use ${preg}preg_cohort_2,clear

* Grouping the cohort by exacerbation during pregnancy
gen exac_ever=.
replace exac_ever=1 if mquarter5==1 | mquarter6==1 | mquarter7==1
replace exac_ever=0 if mquarter5==. & mquarter6==. & mquarter7==.

tab exac_ever

*remove COPD
merge 1:1 patid using ${preg}cohort_copd, keep(master) nogen

*merge other variables
*Baseline asthma severity
merge 1:1 patid using ${preg}before_preganancy_inhalers, keep(master match) nogen
drop if therapy==.
drop if therapy==0

*IMD
merge 1:1 patid using ${linked}IMD, keep(master match) nogen
rename e2019 imd
drop if imd==.

*Baseline comorbid
merge 1:1 patid using ${preg}cohort_comorb, keep(master match) nogen

replace diabetes=9 if diabetes==.
replace atopy=9 if atopy==.
replace pcos=9 if pcos==.
replace gerd=9 if gerd==.
replace heart=9 if heart==.
replace hypertension=9 if hypertension==.

*Baseline eosinophils
merge 1:1 patid using ${preg}cohort_eos, keep(master match) nogen

replace eos_high=9 if eos_high==.
label define eos_high 0 "low" 1 "high" 9 "Missing"
label list eos_high

*Smoking
merge 1:1 patid using ${preg}cohort_smoke, keep(master match) nogen

replace smoking=9 if smoking==.
label define smoking 9 "Missing", add
label list smoking

*Smoking_during pregnancy
merge 1:1 patid using ${preg}cohort_smoke_during, keep(master match) nogen

replace smoking_dur=9 if smoking_dur==.
label define smoking_dur 9 "Missing", add
label list smoking_dur

*Baseline BMI
merge 1:1 patid using ${preg}bmi_final, keep(master match) nogen

label list bmi_cat
replace bmi_cat=9 if bmi_cat==.
label define bmi_cat 9 "Missing", add
label list bmi_cat

* Annual review
merge 1:1 patid using ${preg}annualreview, keep(master match) nogen
replace review_dur=0 if review_dur==.
replace review_aft=0 if review_aft==.

merge 1:1 patid using ${preg}annualreview2, keep(master match) nogen

replace AR_SMP=0 if AR_SMP==.
replace AR_both=0 if AR_both==.
replace AR_inh=0 if AR_inh==.
replace SMP=0 if SMP==.

rename AR_inh review_before


*pregnancy complications
merge 1:1 patid using ${preg}cohort_VTE, keep(master match) nogen

replace vte=0 if vte==.

merge 1:1 patid using ${preg}all_preeclampsia, keep(master match) nogen

replace Preeclampsia=0 if Preeclampsia==.

merge 1:1 patid using ${preg}all_GestHTN, keep(master match) nogen
replace GestHTN=0 if GestHTN==.

merge 1:1 patid using ${preg}all_GDM, keep(master match) nogen
replace GDM=0 if GDM==.


*Pregnancy outcome
merge 1:1 patid using ${preg}aurum_lowbw, keep(master match) nogen

replace lowbw=0 if lowbw==.

merge 1:1 patid using ${preg}cohort_preg_outcomes, keep(master match) nogen
replace preterm=0 if preterm==.
replace iugr=0 if iugr==.
replace cesarean=0 if cesarean==.


* Previous asthma attacks
merge 1:1 patid using ${preg}hist_all_attacks, keep(master match) nogen

gen his_exac=1 if his_total>0
replace his_exac=0 if his_total==.
label define exac_type 0 "None" 1 "1 or more"


* Multigravida
merge 1:1 patid using${preg}multigravida, keep(master match) nogen

* Depression/Anxiety
merge 1:1 patid using${preg}cohort_anx_depression, keep(master match) nogen
replace anx_dep=0 if anx_dep==.

* Ethinicity
merge 1:1 patid using${preg}simple_ethnicity, keep(master match) nogen
replace ethnicity=9 if ethnicity==.


* Age groups
replace age_start=round(age_start, 1)
gen age_group=age_start
recode age_group min/24=1 25/29=2 30/34=3 35/39=4 40/max=5
label define age_group 1 "18-24" 2 "25-29" 3 "30-34" 4 "35-39" 5 ">=40"
label value age_group age_group

tab age_group


* Maternal age 
replace matage=round(matage, 1)
gen matage_group=matage
recode matage_group min/24=1 25/29=2 30/34=3 35/39=4 40/max=5
label define matage_group 1 "18-24" 2 "25-29" 3 "30-34" 4 "35-39" 5 ">=40"
label value matage_group matage_group

tab matage_group

* Maternal DM
gen maternalDM=.
replace maternalDM=1 if diabetes==1 | GDM==1
replace maternalDM=0 if maternalDM==.



save ${preg}cohort_final, replace


**# Added Outcome

use ${preg}cohort_final, clear
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

* add therapy change
merge 1:1 patid using ${preg}ics_change_censored, keep(master match) nogen
merge 1:1 patid using ${preg}therapy_change_censor, keep(master match) nogen

label define therapy 1 "Reliever only" 2 "Intermittent ICS " 3 "Regular ICS" 4"Intermittent ICS+add-on" 5 "Regular ICS+add-on" 6 "Others", replace
label value therapy therapy

save ${preg}cohort_analysis, replace




**# Ordering Final cohort
use ${preg}cohort_analysis, clear
rename (new_studystart preQ1 preQ2 preQ3 pregstart secondtrim thirdtrim pregend postQ1 postQ2 postQ3 new_studyend) (preg1 preg2 preg3 preg4 preg5 preg6 preg7 preg8 preg9 preg10 preg11 preg12)
save ${preg}final_cohort_order, replace




