global summary "/data/master/DS220/share/Summary_datasets/"
global linked "/home/blee5/Documents/DS220/share/AMIR/Data/Linkage/"
global datacar "/data/master/DS220/share/CARLOS/Pregnancy/"
global pregdata "/data/master/DS220/share/Linkage/Pregnancy_aurum/"
global code "/data/master/DS220/share/Codelists/"
global preg "/data/master/DS220/share/BOHEE/Pregnancy/"
global ocp "/home/blee5/Documents/DS220/share/BOHEE/OCPData/"

*******************************************************************************
**# Rates of ICS presciptions *
*******************************************************************************

use ${preg}cohort_final, replace
merge 1:m patid using ${summary}AsthmaTherapy_AllADULTS, keep(match) nogen
save ${preg}preg_therapy_final, replace


use ${preg}preg_therapy_final, clear
keep patid new* preQ* pregstart secondtrim thirdtrim pregend postQ* study* eos_high issue group gestdays
save ${preg}all_severity, replace

use ${preg}all_severity, clear
drop if issuedate < new_studystart | issuedate> new_studyend

*As this is asthma maintainance- OCS was dropped.
drop if group==11

gen saba=1 if group==1
gen ics=1 if group==7 | group==9 | group==19

drop groups 
drop if issue==.
sort patid issue

foreach i in saba ics {
by patid: egen `i'_pre_tot=total(`i') if issue>=new_studystart & issue<pregstart
by patid: egen `i'_dur_tot=total(`i') if issue>=pregstart & issue<=pregend
by patid: egen `i'_post_tot=total(`i') if issue>=pregend & issue<postQ2
by patid: egen `i'_post_tot2=total(`i') if issue>=postQ2 & issue<new_studyend
by patid: egen `i'_post_tot_all=total(`i') if issue>=pregend & issue<new_studyend
}

drop saba ics issue
duplicates drop

foreach i in saba ics {
by patid: egen m`i'_pre_tot=max(`i'_pre_tot) 
by patid: egen m`i'_dur_tot=max(`i'_dur_tot) 
by patid: egen m`i'_post_tot=max(`i'_post_tot)
by patid: egen m`i'_post_tot2=max(`i'_post_tot2) 
by patid: egen m`i'_post_tot_all=max(`i'_post_tot_all) 
}

keep patid gestdays m*
duplicates drop

foreach i in saba ics  {
rename m`i'_pre_tot `i'_pre_tot 
rename m`i'_dur_tot `i'_dur_tot 
rename m`i'_post_tot `i'_post_tot
rename m`i'_post_tot2 `i'_post_tot2  
rename m`i'_post_tot_all `i'_post_tot_all  
replace `i'_pre_tot=0 if `i'_pre_tot ==.
replace `i'_dur_tot=0 if `i'_dur_tot ==.
replace `i'_post_tot=0 if `i'_post_tot ==.
replace `i'_post_tot2=0 if `i'_post_tot2 ==.
replace `i'_post_tot_all=0 if `i'_post_tot_all ==.
}


keep patid gestdays ics_pre_tot ics_dur_tot ics_post_tot ics_post_tot2 ics_post_tot_all

save ${preg}all_severity_total, replace

* already have yearly rate from pre-pregnancy
* find rate during pregnancy
gen dur_rate= ics_dur*(gest/365)
* find difference in yearly rate
gen difference=dur-ics_pre

* create variable to qualify differences
* first say that 1 inhaler per year more is increase, 1 inhaler less is decrease and in between is the same; therefore, women used 3 inhalers per year pre-pregnancy has to change to only 2 inhalers per year to say she has reduced (this seems to lenient)
gen pattern_1inhalerdif=1 if dif>=1
replace pattern_1inhalerdif=2 if dif<=-1
replace pattern_1inhalerdif=0 if pattern==.
label define pattern_1inhalerdif 0"No change" 1"Increase ICS" 2 "Decrease ICS"
label value pattern_1inhalerdif pattern_1inhalerdif


* instead use 0.5 inhalers per year as cut-off (stricter and probably more clinically meaningful)
gen pattern_halfinhalerdiff=1 if dif>=0.5
replace pattern_halfinhalerdiff=2 if dif<=-0.5
replace pattern_halfinhalerdiff=0 if pattern_halfinhalerdiff==.
label value pattern_halfinhalerdiff pattern_1inhalerdifv
tab pattern_halfinhalerdiff

save ${preg}rate_inhalers, replace


