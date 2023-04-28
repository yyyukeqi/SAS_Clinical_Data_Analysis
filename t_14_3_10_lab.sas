%let pgname=t_14_3_10;

proc format;
	value trtc (notsorted)
		0='Placebo'
		1="CMP-135"
		;
	value $ncidirf
		"L"="Low"
		'H'="High"
		;
	value $testnmf (notsorted)
		"SODIUM"="Sodium (mmol/L)"
		"K"="Potassium (mmol/L)"
		"MG"="Magnesium (mmol/L)"
		"ALP"="Alkaline Phosphatase (U/L)"
		"AST"="Aspartate Aminotransferase (U/L)"
		"ALT"="Alanine Aminotransferase (U/L)"
		"BILI"="Bilirubin (umol/L)"
		"BUN"="Blood Urea Nitrogen (mmol/L)"
		"CREAT"="Creatinine (umol/L)"
		;
	invalue $testordf (notsorted)
		"SODIUM"=1
		"K"=2
		"MG"=3
		"ALP"=4
		"AST"=5
		"ALT"=6
		"BILI"=7
		"BUN"=8
		"CREAT"=9
		;
	value $bncigrf (notsorted)
		'0'='0'
		'1'='1'
		'2'='2'
		'3'='3'
		'4'='4'
		'9'="1-4"
		;
run;

proc datasets mt=data lib=work kill;
run;

proc sort data=sasfile.adlbsi 
			(where=(ady>=1 and ablfl ^='Y'and anl01fl ='Y' and  parcat2="SI" and SAFFL="Y")) 
	out=adlb;
	by usubjid;
run;

data adlb (keep=patnum usubjid testdes testnm ncidir bncidir trtc nciabgr bnciabgr
				ontreat saffl anlflag ablfl ady evals avalc);
	length testdes $40 testnm $8 ontreat $1;
	set adlb;
	where paramcd in ("CALPS","CALTS","CASTS","CBILIS","CBUNS","CCREATS",
					  "CKS","CMGS", "CSODIUMS");
	testdes=strip(scan(param,2,'|('));
	lnparmcd=length(paramcd);
	end=lnparmcd-2;
	testnm=strip(substr(paramcd,2,END));
	ncidir=atoxdir;
	bncidir=btoxdir; 
	trtc=trt01an; 
	nciabgr=atoxgr;
	bnciabgr=btoxgr;
	if ady >=1 then ontreat="Y";
	else ontreat=" ";
	anlflag=anl01fl;
	evals=saffl;
	patnum=input(scan(usubjid,3,'-'),best.);
run;

proc freq data=adlb;
	title "testnum and testdes values and freq";
	table testdes*testnm/list norow nopercent missing;
run;

data rpt;
	set adlb;
	if testnm in ('SODIUM', 'K', 'MG') then do;
		if bncidir=' ' then do;
			bncidir='L';
			bnciabgr='0';
		end;
		if ncidir=' ' then do;
			ncidir='L';
			nciabgr='0';
		end;
	end;
	if testnm in ("ALP","AST","ALT","BILI","BUN","CREAT") then do;
		if bncidir=' ' then do;
			bncidir='H';
			bnciabgr='0';
		end;
		if ncidir=' ' then do;
			ncidir='H';
			nciabgr='0';
		end;
	end;
run;

proc print data=rpt;
	title "All DATA: Records with high base for SODIUM, K, MG";
	where bncidir='H' and testnm in ('SODIUM', 'K', 'MG');
	format trtc trtc.;
run;

proc sort data=rpt out=rpt_base(keep=patnum testnm bncidir bnciabgr);
	by patnum testnm bnciabgr;
run;
 
data rpt_base_II;
	set rpt_base;
	by patnum testnm bnciabgr;
	if last.testnm;
run;

proc sort data=rpt out=rpt_I;
	by patnum testnm nciabgr ncidir;
run;

data rpt_II;
	set rpt_I (drop=bncidir bnciabgr);
	by patnum testnm nciabgr ncidir;
	if last.testnm;
run;

data rpt_final;
	merge rpt_II(in=a) rpt_base_II(in=b);
	by patnum testnm;
	if a and b;
run;

data rpt_final;
	set rpt_final;
	if testnm in ('SODIUM', 'K', 'MG') and ncidir='H' then nciabgr='9';
	if testnm in ('SODIUM', 'K', 'MG') and bncidir='H' then bnciabgr='9';
run;

proc sort data=rpt_final nodupkey out=denom;
	by patnum trtc testnm bncidir bnciabgr;
run;

proc sort data=rpt_final;
	by trtc testnm bncidir;
run;

proc freq data=rpt_final;
	table trtc*testnm*bnciabgr*bncidir*nciabgr/out=stats missing list nopercent norow nocol;
	format trtc trtc.;
run;

proc freq data=denom;
	table trtc*testnm*bnciabgr*bncidir/out=bign(rename=(count=bign) drop=percent) missing list nopercent norow nocol;
	format trtc trtc.;
run;

proc sort data=stats nodupkey out=template(keep=trtc testnm bncidir);
	by trtc testnm bncidir;
run;

data template;
	length bnciabgr $ 1;
	set template;
	by trtc testnm bncidir;
	if (testnm in ('SODIUM', 'K', 'MG') and bncidir='L') 
		or testnm in ("ALP","AST","ALT","BILI","BUN","CREAT") then do;
		bnciabgr='0';
		output;
		bnciabgr='1';
		output;
		bnciabgr='2';
		output;
		bnciabgr='3';
		output;
		bnciabgr='4';
		output;
	end;
	else if testnm in ('SODIUM', 'K', 'MG') and bncidir='H' then do;
		bnciabgr='9';
		output;
	end;
run;

data template;
	set template;
	col1=0;
	col2=0;
	col3=0;
	col4=0;
	col0=0;
	col9=0;
run;

proc sort data=template;
	by trtc testnm bncidir bnciabgr;
run;

proc sort data=bign;
	by trtc testnm bncidir bnciabgr;
run;

proc sort data=stats;
	by trtc testnm bncidir bnciabgr;
run;
proc print; run;

proc transpose data=stats out=stats_trans prefix=col;
	by trtc testnm bncidir bnciabgr;
	id nciabgr;
	var count;
run;

proc sort data=stats_trans;
	by trtc testnm bncidir bnciabgr;
run;

	
data stats_trans_II;
	length gr0-gr4 gr9 $12;
	merge template(in=a) stats_trans bign;
	by trtc testnm bncidir bnciabgr ;
	if a;
	if col0 > 0 then gr0=put(col0, 3.)||'('||put(100*col0/bign,5.1)||'%)';
	else gr0='  '||' (00.0%)';
	if col1 > 0 then gr1=put(col1, 3.)||'('||put(100*col1/bign,5.1)||'%)';
	else gr1='  '||' (00.0%)';
	if col2 > 0 then gr2=put(col2, 3.)||'('||put(100*col2/bign,5.1)||'%)';
	else gr2='  '||' (00.0%)';
	if col3 > 0 then gr3=put(col3, 3.)||'('||put(100*col3/bign,5.1)||'%)';
	else gr3='  '||' (00.0%)';
	if col4 > 0 then gr4=put(col4, 3.)||'('||put(100*col4/bign,5.1)||'%)';
	else gr4='  '||' (00.0%)';
	if col9 > 0 then gr9=put(col9, 3.)||'('||put(100*col9/bign,5.1)||'%)';
	else gr9='  '||' (00.0%)';
	if bign=. then bign=0;
	if bncidir='H' then bncidir="High"; 
	else if bncidir="L" then bncidir="Low";
	
	testord=input(testnm,$testordf.);
	drop _name_ _label_;
run;

proc sort data=stats_trans_II;
	by trtc testord testnm descending bncidir descending bnciabgr ;
run;
proc print; run;

data final1 (keep=trtc testord testnm bnciabgr bncidir bign gr0 gr1 gr2 gr3 gr4 gr9);
	set stats_trans_II (where=(trtc=1));
run;

proc report data=final1 nowd headline headskip missing;
	title6 "Treatment: CMP-135";
	columns testnm bncidir bnciabgr bign 
			("Post-Baseline NCI CTCAE Grade / ____________________" gr0 gr1 gr2 gr3 gr4 gr9);
	define testnm /order order=data "Lab Parameter" format=$testnmf.;
	define bncidir /order order=data "Lab / Event" format=$ncidirf.;
	define bnciabgr /order order=data "Baseline / Grade" format=$bncigrf.;
	define bign / display "N";
	define gr0 / display "0" center;
	define gr1 / display "1" center;
	define gr2 / display "2" center;
	define gr3 / display "3" center;
	define gr4 / display "4" center;
	define gr9 / display "Other (value > ULN)" center;
	break after testnm / skip;
run;

proc printto;
run;

data final2 (keep=trtc testord testnm bnciabgr bncidir bign gr0 gr1 gr2 gr3 gr4 gr9);
	set stats_trans_II (where=(trtc=0));
run;

proc report data=final2 nowd headline headskip missing;
	title6 "Treatment: Placebo";
	columns testnm bncidir bnciabgr bign 
			("Post-Baseline NCI CTCAE Grade / ____________________" gr0 gr1 gr2 gr3 gr4 gr9);
	define testnm /order order=data "Lab Parameter" format=$testnmf.;
	define bncidir /order order=data "Lab / Event" format=$ncidirf.;
	define bnciabgr /order order=data "Baseline / Grade" format=$bncigrf.;
	define bign / display "N";
	define gr0 / display "0" center;
	define gr1 / display "1" center;
	define gr2 / display "2" center;
	define gr3 / display "3" center;
	define gr4 / display "4" center;
	define gr9 / display "Other (value > ULN)" center;
	break after testnm / skip;
run;

proc printto;
run;