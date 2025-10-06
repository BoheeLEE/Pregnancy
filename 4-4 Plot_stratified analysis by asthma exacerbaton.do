cd "/home/blee5/Documents/DS220/share/BOHEE/Pregnancy/"
pwd

global preg "/data/master/DS220/share/BOHEE/Pregnancy/Data/"

use ${preg}cohort_analysis, clear


label define his_exac 0 "None" 1 "≥1", replace
label value his_exac his_exac

label define review_bef 0 "No" 1 "Yes", replace
label value review_bef review_bef

label define eos_high 0 "<0.3" 1 "≥0.3" 9 "Unknown", replace
label value eos_high eos_high

label define atopy 0 "No" 1 "Yes", replace
label value atopy atopy

label define ethnicity 1 "White" 2 "Mixed" 3 "Asian" 4 "Black" 5 "Other" 6 "Unknown", replace
label value ethnicity ethnicity

label define imd 1 "1 (least deprived)" 2 "2" 3 "3" 4"4" 5 "5 (most deprived)", replace
label value imd imd

label define bmi_cat 1"Underweight" 0 "Normal"  2 "Overweight" 3"Obese" 9"Unknown", replace
label value bmi_cat bmi_cat

label define anx_dep 0 "No" 1 "Yes", replace
label value anx_dep anx_dep

label define matage_group 1 "18-24" 2 "25-29" 3 "30-34" 4 "35-39" 5 "≥40", replace
label value matage_group matage_group

label define multigravida 0 "No" 1 "Yes", replace
label value multigravida multigravida

label define smoking_dur 1 "Never" 2 "Ex-smoker" 3 "Smoker" 9 "Unknown", replace
label value smoking_dur smoking_dur

drop if therapy==6

label define therapy 1 "SABA only" 2 "ICS <4/year" 3 "ICS ≥4/year" 4 "ICS+add-on <4/year" 5"ICS+add-on ≥4/year", replace
label value therapy therapy


preserve
keep if his_exac==1

logit dur_event i.matage_group  i.ethnicity i.imd i.bmi_cat i.smoking_dur i.therapy  i.review_bef i.ther_change_censor i.eos_high i.atopy i.anx_dep    i.multigravida  , or

est store table1

restore



coefplot table1, eform  /// 
xtitle(Odds ratio (log scale), size(vsmall)) ///
xscale(log) ///
xlabel(0.7 "0.7" 1 "1" 2 "2" 5.0 "5.0" , labsize(vsmall)) ///
xline(1, lcolor(black) lwidth(thin) lpattern(dash))  ///
base ///
coeflabels (, labsize(vsmall)) ///
headings(1.therapy="{bf: Asthma medication}"  0.ther_change_censor="{bf:Change in ICS}" 0.eos_high="{bf:Blood eosinophil count(x10{sup:9}/L)}" 1.ethnicity="{bf:Ethnicity}" 1.imd="{bf: IMD}" 0.bmi_cat="{bf:BMI}" 1.anx_dep="{bf: Anxiety/Depression}" 1.atopy="{bf: Atopy}" 1.matage_group="{bf: Maternal age group}" 0.multigravida="{bf: Multigravida}" 1.smoking_dur="{bf: Smoking during pregnancy}" 0.review_before="{bf:Annual asthma review}") ///
byopts(cols(1)) /// 
xsize(1.8) ///
msymbol(square) /// 
msize(0.5) ///
mcolor(black) ///
graphregion(fcolor(white)) ///
bgcol(white) ///
grid(none) ///
ciopts(lcolor(black) lwidth(vthin)) ///
drop(_cons 0.anx_dep 0.atopy) ///
scheme(sj) ///
title("Asthma exacerbation before", margin(0 0 5 0)) ///
saving(table1)

preserve
keep if his_exac==0

logit dur_event i.matage_group  i.ethnicity i.imd i.therapy  i.review_bef i.ther_change_censor i.eos_high i.atopy i.anx_dep i.bmi_cat   i.multigravida i.smoking_dur , or

est store table2

restore



coefplot table2, eform  /// 
xtitle(Odds ratio (log scale), size(vsmall)) ///
xscale(log) ///
xlabel(0.7 "0.7" 1 "1" 2 "2" 5.0 "5.0" , labsize(vsmall)) ///
xline(1, lcolor(black) lwidth(thin) lpattern(dash))  ///
base ///
coeflabels (, labsize(vsmall)) ///
headings(1.therapy="{bf: Asthma medication}"  0.ther_change_censor="{bf:Change in ICS use}" 0.eos_high="{bf:Blood eosinophil count(x10{sup:9}/L)}" 1.ethnicity="{bf:Ethnicity}" 1.imd="{bf: IMD}" 0.bmi_cat="{bf:BMI}" 1.anx_dep="{bf: Anxiety/Depression}" 1.atopy="{bf: Atopy}" 1.matage_group="{bf: Maternal age group}" 0.multigravida="{bf: Multigravida}" 1.smoking_dur="{bf: Smoking during pregnancy}" 0.review_before="{bf:Annual asthma review}") ///
byopts(cols(1)) /// 
xsize(1.8) ///
msymbol(square) /// 
msize(0.5) ///
mcolor(black) ///
graphregion(fcolor(white)) ///
bgcol(white) ///
grid(none) ///
ciopts(lcolor(black) lwidth(vthin)) ///
drop(_cons 0.anx_dep 0.atopy) ///
scheme(sj) ///
title("No asthma exacerbation before", margin(0 0 5 0)) ///
saving(table2)


graph combine table1.gph table2.gph





















