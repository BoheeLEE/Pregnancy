global linked "/home/blee5/Documents/DS220/share/AMIR/Data/Linkage/"
global link "/home/blee5/Documents/DS220/share/Linkage/Aurum_linked/Final/"
global preg "/data/master/DS220/share/BOHEE/Pregnancy/Data/"
** identify pregnancy complications


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
keep if admidate2>=pregstart & admidate2<new_studyend 
keep if substr(icd,1,4)=="O14" | substr(icd,1,4)=="O14." 

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


**# Low birthweight
*** from AURUM
use ${preg}preg_medcode, clear
merge m:1 medcodeid using${code}LowBW_V2, keep(master match) nogen
sort patid obsdate
replace lowbw=0 if lowbw==.
keep if obsdate>=pregstart & obsdate<pregend

by patid: egen max_lowbw=max(lowbw)
keep patid new_studystart new_studyend pregstart pregend max_lowbw
duplicates drop

rename max_lowbw lowbw

save ${preg}aurum_lowbw, replace

*** from HES: No results.


