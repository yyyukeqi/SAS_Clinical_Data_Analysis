proc freq data=sasfile.adsl;
	where saffl="Y";
	table trt01an/norow nocol nopercent nocum out=bign (drop=percent rename=(count=denom));
run;

DATA adae;
	set sasfile.adae;
	where SAFFL="Y" and trtem="Y";
RUN;

Proc sort data=adae out=_adae1 nodupkey;
	by USUBJID AETOXGR;
RUN;

/*all grade */;

data adae1;
	set _adae1;
	by USUBJID AETOXGR;
	if last.USUBJID;
RUN;

proc freq data=adae1;
	table trt01an/norow nocol nopercent nocum out=frq1 (drop=percent);
run;

/*individual grade */;

proc freq data=_adae1;
	table trt01an*AETOXGR/norow nocol nopercent nocum out=frq2 (drop=percent);
run;

Proc sort data=adae out=_adae3 nodupkey;
	by USUBJID AEBODSYS AETOXGR;
RUN;

/*all grade */;

data adae3;
	set _adae3;
	by USUBJID AEBODSYS AETOXGR;
	if last.AEBODSYS;
RUN;

proc freq data=adae3 noprint;
	table trt01an*AEBODSYS/norow nocol nopercent nocum out=frq3 (drop=percent);
run;

proc freq data=_adae3 noprint;
	table trt01an*AEBODSYS*AETOXGR/norow nocol nopercent nocum out=frq4 (drop=percent);
run;

Proc sort data=adae out=_adae5 nodupkey;
	by USUBJID AEBODSYS AEDECOD AETOXGR;
RUN;

/*all grade */;

data adae5;
	set _adae5;
	by USUBJID AEBODSYS AEDECOD AETOXGR;
	if last.AEDECOD;
RUN;

proc freq data=adae5 noprint;
	table trt01an*AEBODSYS*AEDECOD/norow nocol nopercent nocum out=frq5 (drop=percent);
run;

proc freq data=_adae5 noprint;
	table trt01an*AEBODSYS*AEDECOD*AETOXGR/norow nocol nopercent nocum out=frq6 (drop=percent);
run;

proc freq data=_adae5 noprint;
	table AEBODSYS*AEDECOD/norow nocol nopercent nocum out=ord2 (drop=percent);
run;

proc sort data=ord2;
	by AEBODSYS descending count;
run;

data ord2(drop=count);
	set ord2;
	by AEBODSYS descending count;
	if first.AEBODSYS then order2=2;
	else order2+1;
run;

%macro addvar(indata=,val=);
	data &indata.;
		set &indata.;
		m=&val.;
	run;
%mend addvar;

%addvar(indata=frq1, val=1);
%addvar(indata=frq2, val=2);
%addvar(indata=frq3, val=3);
%addvar(indata=frq4, val=4);
%addvar(indata=frq5, val=5);
%addvar(indata=frq6, val=6);

data all;
	length col1 $70;
	set frq1(in=a1) frq2(in=a2) frq3(in=b1) frq4(in=b2) frq5(in=c1) frq6(in=c2);
	by m;
	if a1 or a2 then do;
		col1="- Any adverse events -";
		AEBODSYS="Any Adverse Events";
		AEDECOD="Any Adverse Events";
	end;
	else if b1 or b2 then do;
		col1="  - Overall -";
		AEDECOD="Any Adverse Events";
	end;
	else if c1 or c2 then col1="   "||strip(AEDECOD);
	if a1 or a2 then section=1;
	else section=2;
	if AETOXGR="" then col2=6;
	if a1 or b1 or c1 then col2=0;
	else col2=input(AETOXGR, best.);
run;

proc sort data=all;
	by AEBODSYS AEDECOD;
run;

proc sort data=ord2;
	by AEBODSYS AEDECOD;
run;

data all1;
	length col1 $70.;
	merge all ord2;
	by AEBODSYS AEDECOD;
	if section=2 and compress(col1)="-Overall-" then order2=1;
	if section=1 then order2=-1;
run;

proc sort data=all1;
by trt01an;
run;

data final;
	length perc $8 result $16;
	merge all1 bign;
	by trt01an;
	perc=put(((count/denom)*100),8.1);
	result=strip(put(count,8.))||" ("||strip(perc)||"%)";
run;

proc sort data=final;
BY section AEBODSYS order2 col1 col2 AEDECOD;
RUN;

PROC TRANSPOSE data=final out=final_t(drop=_name_) prefix=tt_ac;
	BY section AEBODSYS order2 col1 col2 AEDECOD;
	ID TRT01An;
	VAR result;
RUN;

data final_t2;
	set final_t;
	BY section AEBODSYS;
	output;
	if section=2 and first.AEBODSYS then do;
		col1=upcase(AEBODSYS);
		order2=0;
		tt_ac0="";
		tt_ac1="";
		col2=.;
		output;
	end;
run;

proc sort data=final_t2 out=allsoc(keep=section AEBODSYS order2 col1 col2 AEDECOD) nodupkey;
	where order2 ne 0;
	by AEBODSYS AEDECOD;
run;

data dummy (drop=i);
	set allsoc;
	do i=1 to 5;
		col2=i;
		output;
	end;
run;

proc sort data=dummy;
BY AEBODSYS AEDECOD order2 col1 col2;
RUN;

proc sort data=final_t2;
BY AEBODSYS AEDECOD order2 col1 col2;
RUN;

data qc (drop=AEDECOD);
	merge final_t2 dummy;
	BY AEBODSYS AEDECOD order2 col1 col2;
	if section=1 or (section=2 and col2^=.) then do;
		if tt_ac0=" " then tt_ac0="(0.0%)";
		if tt_ac1=" " then tt_ac1="(0.0%)";
	end;
RUN;

proc format;
	value gradef
		0="All grades"
		1="1"
		2="2"
		3="3"
		4="4"
		5="5"
		6="Not graded"
		.=" "
		;
run;

proc sort data=qc out=t_14_3_2;
BY section AEBODSYS order2 col1 col2;
RUN;

proc report data=t_14_3_2 nowd headline headskip;
	title "Table 14.3/2";
	title2 "Patients with Treatment-Emergent Adverse Events by Highest NCI CTCAE Grade";
	title3 "Safety-Evaluable Patients";
	columns section AEBODSYS order2 col1 col2 tt_ac0 tt_ac1;
	define section /order order=data noprint;
	define AEBODSYS /order order=data noprint width=1;
	define order2 /order order=data noprint;
	define col1 /group width=35 flow "MedDRA System Organ Class and / Preferred Term";
	define col2/ flow "NCI-CTCAE / Grade" format=gradef. center;
	define tt_ac0 / flow "Placebo / (n=32)" left;
	define tt_ac1 / flow "CMP-135 / (n=35)" left;
	break after order2 / skip;
	compute after _page_;
		line @27 80*'_';
	endcomp;
run;

proc printto;
run;






