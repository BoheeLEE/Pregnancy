global summary "/data/master/DS220/share/Summary_datasets/"
global linked "/home/blee5/Documents/DS220/share/AMIR/Data/Linkage/"
global datacar "/data/master/DS220/share/CARLOS/Pregnancy/"
global pregdata "/data/master/DS220/share/Linkage/Pregnancy_aurum/"
global code "/data/master/DS220/share/Codelists/"
global preg "/data/master/DS220/share/BOHEE/Pregnancy/"
global ocp "/home/blee5/Documents/DS220/share/BOHEE/OCPData/"

use ${preg}cohort_final, clear
merge 1:m patid using ${preg}preg_therapy_All, keep(match) nogen

gen saba=1 if group==1 
gen ics=1 if (group==9 | group==7 | group==19) 
drop dose group term
duplicates drop

save ${preg}cohort_alltherapy, replace


* create variable that represents each day of the 3 year follow-up
use ${preg}cohort_alltherapy, clear
drop if issue<new_studystart | issue>new_studyend

drop if therapy==0 | therapy==6

gen day=round(issuedate-pregend)
replace day=. if issuedate>=pregend


label define therapy 1 "Reliever only" 2 "Low dose/Infrequent ICS" 3 "Medium dose & Regular ICS" 4 "Medium/high dose & Infrequent ICS" 5 "High dose & Regular ICS", modify


hist day if ics==1, by(therapy) ///
xla(-600 "0" -400 "200" -200 "400" 0 "600")  ///
graphregion(color(white)) bgcolor (white)

hist day if saba==1, by(therapy) ///
xla(-600 "0" -400 "200" -200 "400" 0 "600")  ///
graphregion(color(white)) bgcolor (white)

* need new variable as pregnancy length varies for post-pregnancy scripts
gen day2=round(issuedate-pregend)
replace day2=. if issuedate<pregend

hist day2 if ics==1, by(therapy) ///
graphregion(color(white)) bgcolor (white)


hist day2 if saba==1, by(therapy) ///
graphregion(color(white)) bgcolor (white)


drop mquarter*
save ${preg}preg_3month_inhalers, replace

** percentage of women receiving scripts 
use ${preg}preg_3month_inhalers, clear
* ICS
preserve
keep if ics==1
gen quart1=1 if issue>=new_studystart & issue<preQ1 
gen quart2=1 if issue>=preQ1 & issue<preQ2
gen quart3=1 if issue>=preQ2 & issue<preQ3
gen quart4=1 if issue>=preQ3 & issue<pregstart
gen quart5=1 if issue>=pregstart & issue<second
gen quart6=1 if issue>=second & issue<third
gen quart7=1 if issue>=third & issue<pregend
gen quart8=1 if issue>=pregend & issue<postQ1
gen quart9=1 if issue>=postQ1 & issue<postQ2
gen quart10=1 if issue>=postQ2 & issue<postQ3
gen quart11=1 if issue>=postQ3 & issue<new_studyend

forvalues i=1/11 {
bysort patid: egen mquarter`i'=max(quart`i')
}

drop issue quart*
duplicates drop

* use number of ther_dose from previous dataset as this one now only contains those using ICS
collapse (sum) mquarter1 mquarter2 mquarter3 mquarter4 mquarter5 mquarter6 mquarter7 mquarter8 mquarter9 mquarter10 mquarter11, by(therapy)

restore


* SABA
use ${preg}preg_3month_inhalers, clear
preserve
keep if saba==1
gen quart1=1 if issue>=new_studystart & issue<preQ1 
gen quart2=1 if issue>=preQ1 & issue<preQ2
gen quart3=1 if issue>=preQ2 & issue<preQ3
gen quart4=1 if issue>=preQ3 & issue<pregstart
gen quart5=1 if issue>=pregstart & issue<second
gen quart6=1 if issue>=second & issue<third
gen quart7=1 if issue>=third & issue<pregend
gen quart8=1 if issue>=pregend & issue<postQ1
gen quart9=1 if issue>=postQ1 & issue<postQ2
gen quart10=1 if issue>=postQ2 & issue<postQ3
gen quart11=1 if issue>=postQ3 & issue<new_studyend

forvalues i=1/11 {
bysort patid: egen mquarter`i'=max(quart`i')
}

drop issue quart*
duplicates drop

* use number of ther_dose from previous dataset as this one now only contains those using ICS
collapse (sum) mquarter1 mquarter2 mquarter3 mquarter4 mquarter5 mquarter6 mquarter7 mquarter8 mquarter9 mquarter10 mquarter11, by(therapy)

restore
