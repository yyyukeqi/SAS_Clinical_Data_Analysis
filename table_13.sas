PROC IMPORT datafile="/home/u63099160/New Folder2/ADRS.xls"
OUT = sasfile.ADRS REPLACE
DBMS=XLS;
RUN;

DATA adrs;
	set sasfile.ADRS;
	where PARAMCD="BOR" and ittfl="Y";
	KEEP USUBJID PARAMCD param AVALC Trt01p trt01pn AGE AGEGR1 nereasn;
RUN;

data adrs_age1 adrs_age2;
	set adrs;
	if agegr1="<65" then output adrs_age1;
	else if agegr1=">=65" then output adrs_age2;
run;

PROC FREQ data=adrs_age1(rename=(AVALC='Best Overall Response'n));
	Table 'Best Overall Response'n*Trt01p /out=FreqCount_Avalc nocol norow nopercent;
RUN;

Proc print data=FreqCount_Avalc;
run;

PROC TRANSPOSE data=FreqCount_Avalc out=Avalc_t;
	BY 'Best Overall Response'n;
	ID Trt01p;
	VAR Count;
RUN;

data count;
	set Avalc_t;
	where _NAME_='COUNT';
	DROP _LABEL_ _NAME_;

data result(rename=(percentage1=CMP123 percentage2=Placebo Total1=Total));
	set count;
	Total=sum(CMP123,Placebo);
	percentage1 = put(CMP123, 3.)||'('||put(100*CMP123/50,5.1)||')';
	percentage2 = put(Placebo, 3.)||'('||put(100*Placebo/50,5.1)||')';
	Total1=put(Total, 3.)||'('||put(100*Total/100,5.1)||')';
	drop CMP123 Placebo Total;
RUN;

data bor_summary;
	length value $50;
	set result;
	retain Value;
	if 'Best Overall Response'n = 'CR' THEN Value='Complete Response (CR)';
	if 'Best Overall Response'n = 'PR' THEN Value='Partial Response (PR)';
	if 'Best Overall Response'n = 'SD' THEN Value='Stable Disease (SD)';
	if 'Best Overall Response'n = 'PD' THEN Value='Progressive Disease (PD)';
	if 'Best Overall Response'n = 'NE' THEN Value='Unable to Determine (NE)';
	drop 'Best Overall Response'n;
RUN;

proc sort data=BOR_SUMMARY out=summary;
	by Value;
run;

proc freq data=adrs_age1(where=(avalc="NE"));
	Table avalc*nereasn*Trt01p /list out=FreqCount_Avalc_ne1(drop=percent) nocol norow nopercent;
RUN;

Proc print data=FreqCount_Avalc_ne1;
run;

PROC TRANSPOSE data=FreqCount_Avalc_ne1 out=Avalc_ne1t;
	BY nereasn;
	ID Trt01p;
	VAR Count;
RUN;

data result1(rename=(percentage1=CMP123 percentage2=Placebo Total1=Total));
	set Avalc_ne1t(drop=_NAME_ _LABEL_);
	if placebo=. then placebo=0;
	value="    "||nereasn;
	Total=sum(CMP123,Placebo);
	percentage1 = put(CMP123, 3.)||'('||put(100*CMP123/50,5.1)||')';
	percentage2 = put(Placebo, 3.)||'('||put(100*Placebo/50,5.1)||')';
	Total1=put(Total, 3.)||'('||put(100*Total/100,5.1)||')';
	drop CMP123 Placebo Total nereasn;
RUN;

data adrs_age1_or;
	set adrs_age1;
	if (avalc="CR" or avalc="PR") then type=1;
	else type=2;
	output;
	trt01p="Total";
	trt01pn=9;
	output;
run;

proc sort data=adrs_age1_or;
	by trt01p;
run;
	
ods output OneWayFreqs=freq_age1_or(rename=(frequency=count))
		   BinomialCLs=binomialCL_age1_or(where=(Type="Clopper-Pearson (Exact)"));
proc freq data=adrs_age1_or;
	by trt01p;
	Tables type/binomial(ac wilson exact) out=FreqCount_Avalc_re1(drop=percent) nocol norow nopercent;
RUN;
ods output close;

proc print data=binomialCL_age1_or; run;
proc print data=freq_age1_or; run;


data binomialCL_age1_or_1;
	set binomialCL_age1_or;
	Value="   (95% CI)";
	CI = '('||put(LowerCL, 6.4)||", "||put(UpperCL, 6.4)||')';
	keep trt01p value CI;
RUN;

PROC TRANSPOSE data=freq_age1_or(where=(type=1)) out=freq_age1_or_t;
	BY type;
	ID Trt01p;
	VAR count;
RUN;

data result2(rename=(percentage1=CMP123 percentage2=Placebo Total1=Total));
	set freq_age1_or_t(drop=_NAME_ type);
	Value="Objective Response Rate(1)";
	percentage1 = put(CMP123, 3.)||'/50 ('||put(100*CMP123/50,5.1)||'%)';
	percentage2 = put(Placebo, 3.)||'/50 ('||put(100*Placebo/50,5.1)||'%)';
	Total1=put(Total, 3.)||'/100 ('||put(100*Total/100,5.1)||'%)';
	drop CMP123 Placebo Total;
RUN;

PROC TRANSPOSE data=binomialCL_age1_or_1 out=result3(drop=_NAME_);
	BY value;
	ID Trt01p;
	VAR CI;
RUN;

proc sql;
	create table empty like summary;
	insert into empty
	set 
	value="Best Overall Response",
	CMP123=" ",
	Placebo=" ",
	Total=" ";
	select * from empty;
quit;

data final;
	length value CMP123 Placebo Total $50;
	set empty summary result1 result2 result3;
run;

PROC FREQ data=adrs_age2(rename=(AVALC='Best Overall Response'n));
	Table 'Best Overall Response'n*Trt01p /out=FreqCount_Avalc1 nocol norow nopercent;
RUN;

Proc print data=FreqCount_Avalc1;
run;

PROC TRANSPOSE data=FreqCount_Avalc1 out=Avalc1_t;
	BY 'Best Overall Response'n;
	ID Trt01p;
	VAR Count;
RUN;

data count1;
	set Avalc1_t;
	where _NAME_='COUNT';
	DROP _LABEL_ _NAME_;

data result_1(rename=(percentage1=CMP123 percentage2=Placebo Total1=Total));
	set count1;
	Total=sum(CMP123,Placebo);
	percentage1 = put(CMP123, 3.)||'('||put(100*CMP123/50,5.1)||')';
	percentage2 = put(Placebo, 3.)||'('||put(100*Placebo/50,5.1)||')';
	Total1=put(Total, 3.)||'('||put(100*Total/100,5.1)||')';
	drop CMP123 Placebo Total;
RUN;

data bor_summary_1;
	length value $50;
	set result_1;
	retain Value;
	if 'Best Overall Response'n = 'CR' THEN Value='Complete Response (CR)';
	if 'Best Overall Response'n = 'PR' THEN Value='Partial Response (PR)';
	if 'Best Overall Response'n = 'SD' THEN Value='Stable Disease (SD)';
	if 'Best Overall Response'n = 'PD' THEN Value='Progressive Disease (PD)';
	if 'Best Overall Response'n = 'NE' THEN Value='Unable to Determine (NE)';
	drop 'Best Overall Response'n;
RUN;

proc sort data=BOR_SUMMARY_1 out=summary_1;
	by Value;
run;

proc freq data=adrs_age2(where=(avalc="NE"));
	Table avalc*nereasn*Trt01p /list out=FreqCount_Avalc_ne2(drop=percent) nocol norow nopercent;
RUN;

Proc print data=FreqCount_Avalc_ne2;
run;

PROC TRANSPOSE data=FreqCount_Avalc_ne2 out=Avalc_ne2t;
	BY nereasn;
	ID Trt01p;
	VAR Count;
RUN;

data result1_1(rename=(percentage1=CMP123 percentage2=Placebo Total1=Total));
	set Avalc_ne2t(drop=_NAME_ _LABEL_);
	if cmp123=. then cmp123=0;
	if placebo=. then placebo=0;
	value="    "||nereasn;
	Total=sum(CMP123,Placebo);
	percentage1 = put(CMP123, 3.)||'('||put(100*CMP123/50,5.1)||')';
	percentage2 = put(Placebo, 3.)||'('||put(100*Placebo/50,5.1)||')';
	Total1=put(Total, 3.)||'('||put(100*Total/100,5.1)||')';
	drop CMP123 Placebo Total nereasn;
RUN;

data adrs_age2_or;
	set adrs_age2;
	if (avalc="CR" or avalc="PR") then type=1;
	else type=2;
	output;
	trt01p="Total";
	trt01pn=9;
	output;
run;

proc sort data=adrs_age2_or;
	by trt01p;
run;
	
ods output OneWayFreqs=freq_age2_or(rename=(frequency=count))
		   BinomialCLs=binomialCL_age2_or(where=(Type="Clopper-Pearson (Exact)"));
proc freq data=adrs_age2_or;
	by trt01p;
	Tables type/binomial(ac wilson exact) out=FreqCount_Avalc_re2(drop=percent) nocol norow nopercent;
RUN;
ods output close;

proc print data=binomialCL_age2_or; run;
proc print data=freq_age2_or; run;


data binomialCL_age2_or_1;
	set binomialCL_age2_or;
	Value="   (95% CI)";
	CI = '('||put(LowerCL, 6.4)||", "||put(UpperCL, 6.4)||')';
	keep trt01p value CI;
RUN;

PROC TRANSPOSE data=freq_age2_or(where=(type=1)) out=freq_age2_or_t;
	BY type;
	ID Trt01p;
	VAR count;
RUN;

data result2_1(rename=(percentage1=CMP123 percentage2=Placebo Total1=Total));
	set freq_age2_or_t(drop=_NAME_ type);
	Value="Objective Response Rate(1)";
	percentage1 = put(CMP123, 3.)||'/50 ('||put(100*CMP123/50,5.1)||'%)';
	percentage2 = put(Placebo, 3.)||'/50 ('||put(100*Placebo/50,5.1)||'%)';
	Total1=put(Total, 3.)||'/100 ('||put(100*Total/100,5.1)||'%)';
	drop CMP123 Placebo Total;
RUN;

PROC TRANSPOSE data=binomialCL_age2_or_1 out=result3_1(drop=_NAME_);
	BY value;
	ID Trt01p;
	VAR CI;
RUN;


data final_1;
	length value CMP123 Placebo Total $50;
	set empty summary_1 result1_1 result2_1 result3_1;
run;

Proc report data=final
			headline nowd headskip;
	title1 "Table 13";
	title2 'Best Overall Response per Investigator by Age Category';
	title3 "ITT Subjects";
	title6 lspace=3 height=0.8 justify=left "Subgroup: Age Category-<65";
	column Value ("Number of Subjects (%)" "______" (CMP123 Placebo Total));
	define Value / order order=data '' style(column)=[asis=on] flow;
	define CMP123 / display "CMP123 / N=50";
	define Placebo / display 'Placebo / N=50';
	define Total / display "Total / N=100";
	compute after;
		line @1 110*"_";
		line @1 "(1): 95% confidence interval computed using Clopper-Pearson approach.";
	endcomp;
RUN;
	
Proc report data=final_1
			headline nowd headskip;
	title1 "Table 13";
	title2 'Best Overall Response per Investigator by Age Category';
	title3 "ITT Subjects";
	title6 lspace=3 height=0.8 justify=left "Subgroup: Age Category->=65";
	column Value ("Number of Subjects (%)" "______" (CMP123 Placebo Total));
	define Value / order order=data '' style(column)=[asis=on] flow;
	define CMP123 / display "CMP123 / N=50";
	define Placebo / display 'Placebo / N=50';
	define Total / display "Total / N=100";
	compute after;
		line @1 110*"_";
		line @1 "(1): 95% confidence interval computed using Clopper-Pearson approach.";
	endcomp;
RUN;
		