proc sort data=sasfile.adsl out=adsl;
	by usubjid;
	where ittfl='Y';
run;

proc sort data=sasfile.adtte out=adtte;
	by usubjid;
	where paramcd="TTPFS";
run;

DATA adtte1;
	merge adsl(in=a) adtte(in=b);
	by usubjid;
	if a;
	keep usubjid param paramcd cnsr trt: ittfl aval;
run;


ods listing gpath="/home/u63099160/New Folder2/";
ods output Survivalplot=SurvivalPlotData;
ods graphics on;
proc lifetest data=adtte1 plots=(survival(atrisk=0 to 15 by 3));
	time aval*cnsr(1);
	strata trtp / test=logrank adjust=sidak;
run;

ods listing style=htmlblue;
ods graphics / reset width=5in height=3in imagename="Survival_Plot_SG";
ods graphics off;

footnote1 justify=left h=8pt italic "Study PRJ5457C";
footnote2 justify=left h=8pt italic "TLG Specifications, Version 9.4";
footnote3 justify=right h=8pt italic "Page 1 of 1";
proc sgplot data=SurvivalPlotData noborder;
	title1 "Kaplan Meier Curves for Progression Free Survival by Treatment Arm in Second Remission";
	title2 "Randomized Sujects with 2nd Remission";
	step x=time y=survival / group=stratum name="s";
	styleattrs datacontrastcolors=(red blue);
	xaxis values=(0 to 15 by 3) labelpos=center label="Time to Progression(month)" labelattrs=(weight=bold);
	yaxis labelpos=center label="Progression-Free Rate" labelattrs=(weight=bold);
	scatter x=time y=censored / MARKERATTRS=(symbol=plus) name="c";
	scatter x=time y=censored / MARKERATTRS=(symbol=plus) group=stratum colormodel=(blue red);
	xaxistable atrisk / x=tatrisk title="Number at Risk:" class=stratum colorgroup=stratum valueattrs=(weight=bold);
	keylegend "s" / linelength=20 location=inside position=bottomleft;
	inset "Median Time(mo)    5.8     7.7" "Hazard Ratio          0.730" "(95% CI)         (0.362,1.472)" "Log-rank p-value     0.3857"
		/ valuealign=left;
run;



