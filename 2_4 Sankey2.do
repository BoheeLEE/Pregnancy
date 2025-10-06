global summary "/data/master/DS220/share/Summary_datasets/"
global linked "/home/blee5/Documents/DS220/share/AMIR/Data/Linkage/"
global datacar "/data/master/DS220/share/CARLOS/Pregnancy/"
global pregdata "/data/master/DS220/share/Linkage/Pregnancy_aurum/"
global code "/data/master/DS220/share/Codelists/"
global preg "/data/master/DS220/share/BOHEE/Pregnancy/Data/"
global ocp "/home/blee5/Documents/DS220/share/BOHEE/OCPData/"


** First SANKEY PLOT for asthma attacks by baseline severity 
use ${preg}cohort_analysis, replace
keep patid new* preQ* pregstart secondtrim thirdtrim pregend postQ* study* eos_high therapy gestdays ther*
merge 1:m patid using ${summary}AsthmaTherapy_AllADULTS, keep(match) nogen
save ${preg}preg_therapy_final, replace



* Drop if <280 gestdays
use ${preg}preg_therapy_final, clear
keep patid new* preQ* pregstart secondtrim thirdtrim pregend postQ* study* eos_high therapy issue group  gestdays ther*

save ${preg}sankey_all_severity2, replace



****************************************************
**# Baseline severity before 12 months of pregnancy *
****************************************************

use ${preg}sankey_all_severity2, clear

preserve
keep if  issue>=new_studystart & issue<pregstart

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
drop group saba ics laba lama ltra theo issue 

duplicates drop
drop if patid==.

gen therapy_pre=0 if saba_tot==0 & ics_tot==0 & labam==. & lamam==. &  ltram==. & theo==.  
replace therapy_pre=1 if saba_tot>=1 & ics_tot==0 & labam==. & lamam==. &  ltram==. & theo==.  
replace therapy_pre=2 if ics_tot>0 & ics_tot<4 & labam==.                          
replace therapy_pre=3 if ics_tot>=4 & labam==.                                                   
replace therapy_pre=2 if ics_tot>0 & ics_tot<4 & labam==1 | ltram==1 & lamam==.  & theo==.   
replace therapy_pre=3 if ics_tot>=4 & labam==1 | ltram==1 & lamam==. &  ltram==. & theo==.    
replace therapy_pre=4 if therapy_pre==. 

label define therapy_pre 0 "no treatment" 1 "SABA only" 2 "Infreq ICS" 3 "Regular ICS" 4"Others"
label value therapy_pre therapy_pre


drop laba lama ltra theo icsm
keep patid therapy*
duplicates drop

save ${preg}pre_12mon_preganancy, replace
restore


****************************************************
**# Asthma severity during pregnancy
****************************************************
preserve
keep if  issue>=pregstart & issue<pregend

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
drop group saba ics laba lama ltra theo issue 

duplicates drop
drop if patid==.

gen therapy_dur=0 if saba_tot==0 & ics_tot==0 & labam==. & lamam==. &  ltram==. & theo==.  
replace therapy_dur=1 if saba_tot>=1 & ics_tot==0 & labam==. & lamam==. &  ltram==. & theo==.  
replace therapy_dur=2 if ics_tot>0 & ics_tot<3 & labam==.                          
replace therapy_dur=3 if ics_tot>=3 & labam==.                                                   
replace therapy_dur=2 if ics_tot>0 & ics_tot<3 & labam==1 | ltram==1 & lamam==.  & theo==.   
replace therapy_dur=3 if ics_tot>=3 & labam==1 | ltram==1 & lamam==. &  ltram==. & theo==.    
replace therapy_dur=4 if therapy_dur==. 

label define therapy_dur 0 "no treatment" 1 "SABA only" 2 "Infreq ICS" 3 "Regular ICS" 4"Others"
label value therapy_dur therapy_dur

drop laba lama ltra theo icsm
keep patid therapy*
duplicates drop

save ${preg}during_pregnancy_inhaler, replace
restore
**********************************************************
**# All asthma severity after pregnancy
************************************************************
use ${preg}sankey_all_severity2, clear

keep if  issue>=pregend & issue<new_studyend

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
drop group saba ics laba lama ltra theo issue 

duplicates drop
drop if patid==.

gen therapy_post_all=0 if saba_tot==0 & ics_tot==0 & labam==. & lamam==. &  ltram==. & theo==.  

replace therapy_post_all=1 if saba_tot>=1 & ics_tot==0 & labam==. & lamam==. &  ltram==. & theo==.  
replace therapy_post_all=2 if ics_tot>0 & ics_tot<4 & labam==.                          
replace therapy_post_all=3 if ics_tot>=4 & labam==.                                                   
replace therapy_post_all=2 if ics_tot>0 & ics_tot<4 & labam==1 | ltram==1 & lamam==.  & theo==.   
replace therapy_post_all=3 if ics_tot>=4 & labam==1 | ltram==1 & lamam==. &  ltram==. & theo==.    
replace therapy_post_all=4 if therapy_post_all==. 

label define therapy_post_all 0 "no treatment" 1 "SABA only" 2 "Infreq ICS" 3 "Regular ICS" 4"Others"
label value therapy_post_all therapy_post_all

drop laba lama ltra theo icsm
keep patid therapy_post_all 
duplicates drop

save ${preg}post_all_preganancy_inhaler, replace



**# Combine all pre/dur/post inhalers: Option1 remove all non-users
use ${preg}cohort_analysis, replace

keep patid new* preQ* pregstart secondtrim thirdtrim pregend postQ* study* eos_high ther*

merge 1:1 patid using ${preg}pre_12mon_preganancy, keep(master match) nogenerate 
merge 1:1 patid using ${preg}during_pregnancy_inhaler, keep(master match) nogenerate 
merge 1:1 patid using ${preg}post_all_preganancy_inhaler, keep(master match) nogenerate 


tab therapy_pre, mi
replace therapy_pre=0 if therapy_pre==.
drop if therapy_pre==4

tab therapy_dur, mi
replace therapy_dur=0 if therapy_dur==.
drop if therapy_dur==4

tab therapy_post_all, mi
replace therapy_post_all=0 if therapy_post_all==.
drop if therapy_post_all==4


save ${preg}sankey_inhalers_2, replace




