PROC IMPORT datafile="/home/u63099160/New Folder2/ADEFF.xls"
OUT = sasfile.ADEFF REPLACE
DBMS=XLS;
RUN;

DATA adeff;
	set sasfile.ADEFF;
	where PARAMCD="VLOAD" and ittfl="Y" and ANL01FL="Y";
	KEEP USUBJID AVISITN AVISITN_1 AVAL Trt01a trt01an Base CHG Param PARAMCD;
RUN;

proc sort data=adeff;
	by AVISITN AVISITN_1 Trt01a;
run;

proc means data=adeff n mean stderr maxdec=3 STACKODSOUTPUT;
	var AVAL;
	by AVISITN AVISITN_1 Trt01a;
	ods output summary=sta;
RUN;

data summary;
	SET sta;
	'Mean (SE)'n=put(Mean, 5.3)||"("||put(StdErr, 5.3)||')';
	keep AVISITN_1 Trt01a N 'Mean (SE)'n;
RUN;


DATA adeff1;
	set ADEFF;
	where AVISITN_1 in ("Week 12", "Week 16");
	KEEP USUBJID AVISITN AVISITN_1 AVAL Trt01a trt01an Base CHG Param PARAMCD;
RUN;

proc sort data=adeff1;
	by AVISITN AVISITN_1 Trt01a;
run;

proc freq data=adeff1;
	tables AVISITN_1*Trt01a /list out=freq;
run;

proc mixed data=adeff1;
	class AVISITN_1 Trt01a;
	model CHG=AVISITN_1*Trt01a;
	lsmeans AVISITN_1*Trt01a;
	ods output LSMeans=sta1;
RUN;

data summary1;
	merge freq(keep=AVISITN_1 Trt01a count) sta1;
	by AVISITN_1 Trt01a;
	Estimate=abs(Estimate);
	'Mean (SE)'n=put(Estimate, 5.3)||"("||put(StdErr, 5.3)||')';
	keep AVISITN_1 Trt01a count 'Mean (SE)'n;
RUN;

Proc report data=summary
			headline nowd headskip;
	title1 "Table 11";
	title2 'Summary of Viral Load Over Time';
	title3 "ITT Subjects";
	column AVISITN_1 Trt01a N 'Mean (SE)'n;
	define AVISITN_1 / group order=data 'Test / Day';
	define Trt01a / group 'Treatment';
	define N / display;
	define 'Mean (SE)'n / display "Unadjusted / Mean (SE)";
	compute after AVISITN_1;
		line @1 " ";
	endcomp;
RUN;

Proc report data=summary1
			headline nowd headskip;
	title1 "Table 12";
	title2 'Summary of Adjusted Mean of Change from Baseline Viral Load at Week 12 and 16';
	title3 "ITT Population";
	column AVISITN_1 Trt01a count 'Mean (SE)'n;
	define AVISITN_1 / group order=data 'Test Day';
	define Trt01a / group 'Treatment';
	define count / display "N";
	define 'Mean (SE)'n / display "Adjusted Mean (SE)";
	compute after AVISITN_1;
		line @1 " ";
	endcomp;
	compute after;
		line @1 110*"_";
		line @1 "Adjusted mean is calculated using PROC MIXED stage as factor and treatment.";
	endcomp;
RUN;