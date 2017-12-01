




%macro table1_160718(dataset=, byvar=, 
									
									fishersvars=, chisqvars=, normalvars=, nonparmvars=, countvars=, NormalSDorCI=, NonParmQ1Q3orMinMax=, title=, output=);
/*ods html close;
options nonotes nomprint nospool nosource;
ods trace off;*/

/****************************************
*
*	With by variable
*
*****************************************/



/*%if &byvar ne "" %then %do;*/


	/****************************************
	*
	*	Determine Table Parameters
	*
	*****************************************/




		/* Determine number of variables of each type */
		data temp1;
			normal="&normalvars";
			nonparm="&nonparmvars";
			count="&countvars";
			fishers="&fishersvars";
			chisq="&chisqvars";
			nnormal=countw(normal);
			nnonparm=countw(nonparm);
			ncount=countw(count);
			nfishers=countw(fishers);
			nchisq=countw(chisq);
			call symput("nnormal",nnormal);
			call symput("nnonparm",nnonparm);
			call symput("ncount",ncount);
			call symput("nfishers",nfishers);
			call symput("nchisq",nchisq);
		run;




		/* Determine Variables of each type */
		data temp2;
			set temp1;
			%do i=1 %to &nnormal;
				normalvar&i=scan(normal, &i);
				call symput("normalvar&i",normalvar&i);
			%end;
			%do i=1 %to &nnonparm;
				nonparmvar&i=scan(nonparm, &i);
				call symput("nonparmvar&i",nonparmvar&i);
			%end;
			%do i=1 %to &ncount;
				countvar&i=scan(count, &i);
				call symput("countvar&i",countvar&i);
			%end;
			%do i=1 %to &nfishers;
				fishersvar&i=scan(fishers, &i);
				call symput("fishersvar&i",fishersvar&i);
			%end;
			%do i=1 %to &nchisq;
				chisqvar&i=scan(chisq, &i);
				call symput("chisqvar&i",chisqvar&i);
			%end;
		run;




		/* Create Blank Table 1 Dataset */
		data table1;
			delete;
			format Variable $100.;
			format Category $100.;
		run;







	/****************************************
	*
	*	Normal
	*
	*****************************************/




		/* ANOVA  */
		%do i=1 %to &nnormal;
		%let outcome=%unquote(%str(&)normalvar&i);
		data &dataset;
		set &dataset;
		outcomelabel=vlabel(&outcome)||"^{super 1}";
		call symput("outcomelabel",outcomelabel);
		drop outcomelabel;
		run;

			proc glimmix data=&dataset;
				ods output tests3=t3_&outcome lsmeans=lsm_&outcome nobs=n_&outcome;
				class &byvar;
				model &outcome=&byvar / link=identity dist=normal s cl;
				lsmeans &byvar / cl;
			run;

proc glimmix data=&dataset;
				ods output parameterestimates=pe2_&outcome;
				class &byvar;
				model &outcome= /  link=identity dist=normal s cl;
			run;

proc sort data=&dataset;
by &byvar;
run;

proc means data=&dataset stddev;
ods output summary=sd_&outcome;
var &outcome;
run;

data pe2_&outcome;
merge pe2_&outcome sd_&outcome;
run;


			data pe2_&outcome;
			set pe2_&outcome;
			format estimate 15.2;
			format lower 15.2;
			format upper 15.2;
			run;

			data pe2_&outcome;
			set pe2_&outcome;
			format est $50.;
			where effect="Intercept";
			%if &NormalSDorCI=CI %then %do;
			est=compress(vvalue(estimate))||" ("||compress(vvalue(lower))||", "||compress(vvalue(upper))||")";
			%end;
			%else %if &NormalSDorCI=SD %then %do;
			est=compress(vvalue(estimate))||" �"||compress(round(&outcome._StdDev,0.01));
			%end;
			call symput("estT_&outcome",est);
			run;

data n_&outcome;
set n_&outcome;
missing=NobsRead-nobsused;
percentmissing=100*missing/nobsread;
call symput("miss_&outcome",missing);
call symput("nu_&outcome",nobsused);
call symput("nr_&outcome",NobsRead);
call symput("pm_&outcome",percentmissing);
run;

/*
data n_age;
set n_age;
call symput("miss_age",missing);
call symput("nu_age",nobsused);
call symput("nr_age",NobsRead);
call symput("pm_age",percentmissing);
run;


proc print data=n_age;
run;

%put &miss_age;*/

data t3_&outcome;
set t3_&outcome;
vvalueprobf=vvalue(ProbF);
call symput("p_&outcome",vvalueProbF);
run;



proc sort data=&dataset;
by &byvar;
run;

proc means data=&dataset stddev;
ods output summary=sdby_&outcome;
var &outcome;
by &byvar;
run;


proc sort data=sdby_&outcome;
by &byvar;
run;

proc sort data=lsm_&outcome;
by &byvar;
run;

data lsm_&outcome;
merge lsm_&outcome sdby_&outcome;
by &byvar;
run;


			data lsm_&outcome;
			set lsm_&outcome;
			format estimate 15.2;
			format lower 15.2;
			format upper 15.2;
			format by $100.;
			run;

			data lsm_&outcome;
				set lsm_&outcome;
					%if &NormalSDorCI=CI %then %do;
					est=compress(vvalue(estimate))||" ("||compress(vvalue(lower))||", "||compress(vvalue(upper));
					%end;
					%else %if &NormalSDorCI=SD %then %do;
					est=compress(vvalue(estimate))||" �"||compress(round(&outcome._StdDev,0.01));
					%end;
					By=vvalue(&byvar);
					if effect="Scale" then delete;
			run;

proc transpose data=lsm_&outcome out=trans_&outcome;
var est;
id by;
run;

data or1_&outcome;
format Variable $100.;
format Category $100.;
Variable2="&outcomelabel";
Variable=trim(Variable2);
Category="";
drop variable2;
run;

%let est1=%str(&)estT_&outcome;
/*%let est2=%str(")&est1%str(");*/

data or2_&outcome;
set trans_&outcome;
format total $50.;
Total="%unquote(&est1)";
/*Total=%unquote(&est2);*/
drop _name_;
run;

%let miss=%unquote(%str(&)miss_&outcome);
%let nu=%unquote(%str(&)nu_&outcome);
%let pm=%unquote(%str(&)pm_&outcome);
%let p=%unquote(%str(&)p_&outcome);

data or3_&outcome;
Missing=&Miss;
N=&nu;
PercentMissing=compress(round(&pm,0.01)||"%");
pValue="&p";
run;

data or_&outcome;
merge or1_&outcome or2_&outcome or3_&outcome;
format pvalue $100.;
label pvalue="p-Value";
format Variable $100.;
run;


			data table1;
			set table1 or_&outcome;
			format Variable $100.;
			format Category $100.;
			run;



		%end;






	/****************************************
	*
	*	Count
	*
	*****************************************/


		/* Poisson model for count data */
		%do i=1 %to &ncount;
			proc glimmix data=&dataset;
				class &byvar;
				model %unquote(%str(&)countvar&i)=&byvar / noint link=log dist=poisson;
			run;
		%end;




	/****************************************
	*
	*	Non-parametric
	*
	*****************************************/


		%do i=1 %to &nnonparm;
		%let outcome=%unquote(%str(&)nonparmvar&i);
data &dataset;
		set &dataset;
		outcomelabel=vlabel(&outcome)||"^{super 2}";
		call symput("outcomelabel",outcomelabel);
		drop outcomelabel;
		run;



			proc npar1way data=&dataset;
				ods output kruskalwallistest=kw_&outcome;
				class &byvar;
				var &outcome;
			run;


data kw_&outcome;
set kw_&outcome;
if name1="P_KW" then call symput("p_&outcome",nValue1);
run;

proc sort data=&dataset;
by &byvar;
run;

proc means data=&dataset median p25 p75 min max;
ods output summary=s_&outcome;
var &outcome;
by &byvar;
run;

data s_&outcome;
set s_&outcome;
format byvarformatted $100.;
%if &NonParmQ1Q3orMinMax=Q1Q3 %then %do;
est=compress(&outcome._Median)||" ("||compress(&outcome._p25)||", "||compress(&outcome._p75)||")";
%end;
%if &NonParmQ1Q3orMinMax=MinMax %then %do;
est=compress(&outcome._Median)||" ("||compress(&outcome._min)||", "||compress(&outcome._max)||")";
%end;
byvarformatted=vvalue(&byvar);
if byvarformatted="" then delete;
keep est byvarformatted;
run;


proc transpose data=s_&outcome out=trans_&outcome;
var est;
id byvarformatted;
run;


data miss_&outcome;
set &dataset;
outcomelabel=vvalue(&outcome);
predlabel=vvalue(&byvar);
missing=0;
if outcomelabel="" then missing=1;
if predlabel="" then missing=1;
if missing=1 then countobs=0;
if missing=0 then countobs=1;
run;

proc means data=miss_&outcome sum;
ods output summary=s2_&outcome;
var missing countobs;
run;

data s2_&outcome;
set s2_&outcome;
ntotal=missing_sum+countobs_sum;
percentmissing=100*missing_sum/ntotal;
format Variable $100.;
call symput("miss_&outcome",missing_Sum);
call symput("nu_&outcome",countobs_Sum);
call symput("nr_&outcome",ntotal);
call symput("pm_&outcome",percentmissing);
run;

proc means data=miss_&outcome median qrange p25 p75 min max;
where missing ne 1;
ods output summary=s3_&outcome;
var &outcome;
run;


data t_&outcome;
set s3_&outcome;
format total $50.;
%if &NonParmQ1Q3orMinMax=Q1Q3 %then %do;
Total=compress(&outcome._Median)||" ("||compress(&outcome._p25)||", "||compress(&outcome._p75)||")";
%end;
%if &NonParmQ1Q3orMinMax=MinMax %then %do;
Total=compress(&outcome._Median)||" ("||compress(&outcome._min)||", "||compress(&outcome._max)||")";
%end;
format Variable $100.;
keep Total;
run;

data or2_&outcome;
set trans_&outcome;
drop _name_;
run;

data or1_&outcome;
format Variable $100.;
format Category $100.;
Variable="&outcomelabel";
Category="";
run;

%let miss=%unquote(%str(&)miss_&outcome);
%let nu=%unquote(%str(&)nu_&outcome);
%let pm=%unquote(%str(&)pm_&outcome);
%let p=%unquote(%str(&)p_&outcome);

data or3_&outcome;
Missing=&Miss;
N=&nu;
PercentMissing=compress(round(&pm,0.01)||"%");
pValue="&p";
run;

data or_&outcome;
merge or1_&outcome or2_&outcome t_&outcome or3_&outcome;
label pvalue="p-Value";
format pvalue $100.;
run;


data table1;
set table1 or_&outcome;
format category $100.;
run;




		%end;





		
	/****************************************
	*
	*	Fisher's
	*
	*****************************************/


		%do i=1 %to &nfishers;
			%let fishersvar=%unquote(%str(&)fishersvar&i);
data &dataset;
		set &dataset;
		outcomelabel=vlabel(&fishersvar)||"^{super 3}";
		call symput("outcomelabel",outcomelabel);
		drop outcomelabel;
		run;

			

proc freq data=&dataset nlevels;
ods output nlevels=nl_&fishersvar crosstabfreqs=ctf_&fishersvar;
table &byvar * &fishersvar;
run;

%let levels_byvar=levels_&byvar;
%let levels_fishersvar=levels_&fishersvar;

data nl_&fishersvar;
set nl_&fishersvar;
NNL=NNonMissLevels;
run;

data nl_&fishersvar;
set nl_&fishersvar;
if tablevar="&byvar" then do;
if NNL=. then call symput("&levels_byvar",NLevels);
if NNL ne . then call symput("&levels_byvar",NNL);
end;
if tablevar="&fishersvar" then do;
if NNL=. then call symput("&levels_fishersvar",NLevels);
if NNL ne . then call symput("&levels_fishersvar",NNL);
end;
run;


%let byvarlevels=%unquote(%str(&)&levels_byvar);

%let fishersvarlevels=%unquote(%str(&)&levels_fishersvar);


%if %sysevalf(&byvarlevels > 1) %then %let byvarlevelsge2=1;
%else %if %sysevalf(&byvarlevels < 2) %then %let byvarlevelsge2=0;
%if %sysevalf(&fishersvarlevels > 1) %then %let fishersvarlevelsge2=1;
%else %if %sysevalf(&fishersvarlevels < 2) %then %let fishersvarlevelsge2=0;
%let bothlevelsge2=%eval(&byvarlevelsge2 * &fishersvarlevelsge2);



%if %sysevalf(&bothlevelsge2=1) %then %do;
 

			proc freq data=&dataset;
				ods output fishersexact=fe_&fishersvar ;
				table &byvar * &fishersvar / fisher;
			run;

			data fe_&fishersvar;
			set fe_&fishersvar;
				where (label1="Pr <= P") or (label1="Two-sided Pr <= P");
				call symput("p_&fishersvar",cValue1);
			run;

%end;

%if %sysevalf(&bothlevelsge2=0) %then %let p_&fishersvar=.;

			data ctf_&fishersvar;
				set ctf_&fishersvar;
				if missing ne . then call symput("Miss_&fishersvar",missing);
			run;

			data ctf_&fishersvar;
				set ctf_&fishersvar;
				format by $100.;
				if _type_="11" then do;
					est=compress(frequency)||", "||compress(round(rowpercent,0.001))||"%";
					By=vvalue(&byvar);
				end;
				else if _type_="01" then do;
					est=compress(frequency)||", "||compress(round(percent,0.001))||"%";
					By="Total";
				end;
				if _type_="00" then call symput("nu_&fishersvar",Frequency);
				if _type_="00" then delete;
				if _type_="10" then delete;
				
				keep &byvar &fishersvar By  est;
			run;



data ctf_&fishersvar;
set ctf_&fishersvar;
keep &fishersvar By est;
run;

proc sort data=ctf_&fishersvar;
by &fishersvar;
run;

proc transpose data=ctf_&fishersvar out=trans_&fishersvar;
var est;
by &fishersvar;
id by;
run;

data trans_&fishersvar;
set trans_&fishersvar;
format Variable $100.;
format Category $100.;
				Category=vvalue(&fishersvar);
drop  _name_;
run;

%let miss=%unquote(%str(&)miss_&fishersvar);
%let nobsused=%unquote(%str(&)nu_&fishersvar);
%let pvalue=%unquote(%str(&)p_&fishersvar);

data tr_&fishersvar;
format Variable $100.;
Variable="&outcomelabel";
Missing=&Miss;
N=&nobsused;
PercentMissing=compress(100*round(missing/(missing+n),0.01)||"%");
pValue="&pvalue";
run;

data ar_&fishersvar;
set tr_&fishersvar trans_&fishersvar;
run;

data ar_&fishersvar;
set ar_&fishersvar;
mergevar=_n_;
run;

data ar1_&fishersvar;
set ar_&fishersvar;
keep variable category mergevar;
run;

data ar2_&fishersvar;
set ar_&fishersvar;
drop variable category  pValue;
run;

data ar3_&fishersvar;
set ar_&fishersvar;
keep mergevar N pValue;
run;

data ar_&fishersvar;
merge ar1_&fishersvar ar2_&fishersvar ar3_&fishersvar;
by mergevar;
label pvalue="p-Value";
format pvalue $100.;
format category $100.;
format Variable $100.;
drop mergevar &fishersvar;
run;


data table1;
set table1 ar_&fishersvar;
run;


		%end;









	/****************************************
	*
	*	Chisq
	*
	*****************************************/


		%do i=1 %to &nChisq;
			%let Chisqvar=%unquote(%str(&)Chisqvar&i);
data &dataset;
		set &dataset;
		outcomelabel=vlabel(&Chisqvar)||"^{super 3}";
		call symput("outcomelabel",outcomelabel);
		drop outcomelabel;
		run;

	

proc freq data=&dataset nlevels;
ods output nlevels=nl_&Chisqvar crosstabfreqs=ctf_&Chisqvar;
table &byvar * &Chisqvar;
run;

%let levels_byvar=levels_&byvar;
%let levels_Chisqvar=levels_&Chisqvar;

data nl_&Chisqvar;
set nl_&Chisqvar;
format NNLPresent 10.;
NNLPresent=0;
*NNLPresent=NNonMissLevels;
run;

proc print data=nl_&Chisqvar;;
run;

data nl_&Chisqvar;
set nl_&Chisqvar;
if tablevar="&byvar" then do;
if NNLPresent=0 then call symput("&levels_byvar",NLevels);
if NNLPresent ne 0 then call symput("&levels_byvar",NNonMissLevels);
end;
if tablevar="&Chisqvar" then do;
if NNLPresent=0 then call symput("&levels_Chisqvar",NLevels);
if NNLPresent ne 0 then call symput("&levels_Chisqvar",NNonMissLevels);
end;
run;



%let byvarlevels=%unquote(%str(&)&levels_byvar);

%let Chisqvarlevels=%unquote(%str(&)&levels_Chisqvar);


%if %sysevalf(&byvarlevels > 1) %then %let byvarlevelsge2=1;
%else %if %sysevalf(&byvarlevels < 2) %then %let byvarlevelsge2=0;
%if %sysevalf(&Chisqvarlevels > 1) %then %let Chisqvarlevelsge2=1;
%else %if %sysevalf(&Chisqvarlevels < 2) %then %let Chisqvarlevelsge2=0;
%let bothlevelsge2=%eval(&byvarlevelsge2 * &Chisqvarlevelsge2);



%if %sysevalf(&bothlevelsge2=1) %then %do;
 

			proc freq data=&dataset;
				ods output Chisq=X2_&Chisqvar ;
				table &byvar * &Chisqvar / Chisq;
			run;

			data x2_&Chisqvar;
			set x2_&Chisqvar;
				where statistic="Chi-Square";
				call symput("p_&Chisqvar",Prob);
			run;

%end;

%if %sysevalf(&bothlevelsge2=0) %then %let p_&Chisqvar=.;

			data ctf_&Chisqvar;
				set ctf_&Chisqvar;
				if missing ne . then call symput("Miss_&Chisqvar",missing);
			run;

			data ctf_&Chisqvar;
				set ctf_&Chisqvar;
				format by $100.;
				if _type_="11" then do;
					est=compress(frequency)||", "||compress(round(rowpercent,0.001))||"%";
					By=vvalue(&byvar);
				end;
				else if _type_="01" then do;
					est=compress(frequency)||", "||compress(round(percent,0.001))||"%";
					By="Total";
				end;
				if _type_="00" then call symput("nu_&Chisqvar",Frequency);
				if _type_="00" then delete;
				if _type_="10" then delete;
				
				keep &byvar &Chisqvar By  est;
			run;



data ctf_&Chisqvar;
set ctf_&Chisqvar;
format by $100.;
keep &Chisqvar By est;
run;

proc sort data=ctf_&Chisqvar;
by &Chisqvar;
run;

proc transpose data=ctf_&Chisqvar out=trans_&Chisqvar;
var est;
by &Chisqvar;
id by;
run;

data trans_&Chisqvar;
set trans_&Chisqvar;
format Category $100.;
				Category=vvalue(&Chisqvar);
drop  _name_;
run;

%let miss=%unquote(%str(&)miss_&Chisqvar);
%let nobsused=%unquote(%str(&)nu_&Chisqvar);
%let pvalue=%unquote(%str(&)p_&Chisqvar);


data tr_&Chisqvar;
format Variable $100.;
Variable="&outcomelabel";
Missing=&Miss;
N=&nobsused;
PercentMissing=compress(100*round(missing/(missing+n),0.01)||"%");
pValue="&pvalue";
run;

data ar_&Chisqvar;
set tr_&Chisqvar trans_&Chisqvar;
run;

data ar_&Chisqvar;
set ar_&Chisqvar;
mergevar=_n_;
run;

data ar1_&Chisqvar;
set ar_&Chisqvar;
keep variable category mergevar;
run;

data ar2_&Chisqvar;
set ar_&Chisqvar;
drop variable category  pValue;
run;

data ar3_&Chisqvar;
set ar_&Chisqvar;
keep mergevar N pValue;
run;

data ar_&Chisqvar;
merge ar1_&Chisqvar ar2_&Chisqvar ar3_&Chisqvar;
by mergevar;
label pvalue="p-Value";
format pvalue $100.;
format category $100.;
drop mergevar &Chisqvar;
run;


data table1;
set table1 ar_&Chisqvar;
run;


		%end;







 data table1;
 set table1;
 label Total="Combined Cohort";
 label missing="N Missing";
 label N="N Used";
 label percentmissing="% Missing";
 mergevar=_n_;
 run;

 data table1a;
 set table1;
 keep mergevar variable category;
 run;

 data table1b;
 set table1;
 keep mergevar missing n percentmissing;
 run;

 data table1c;
 set table1;
 keep mergevar total;
 run;

 data table1d;
 set table1;
 keep mergevar pvalue;
 run;

 data table1e;
 set table1;
 drop variable category missing n percentmissing total pvalue;
 run;

 data table1;
 merge table1a table1e table1c table1b table1d;
 by mergevar;
 drop mergevar;
 run;


ods escapechar='^';

%if &NormalSDorCI=CI %then %do;
footnote "^{super 1}Estimates for symmetrical numeric variables are given as mean (95% CI)."
%end;

%if &NormalSDorCI=SD %then %do;
footnote "^{super 1}Estimates for symmetrical numeric variables are given as mean +/- standard deviation.";
%end;

%if &NonParmQ1Q3orMinMax=Q1Q3 %then %do;
footnote2 "^{super 2}Estimates for asymmetrical numeric variables are given as median (inter-quartile range).";
%end;

%if &NonParmQ1Q3orMinMax=MinMax %then %do;
footnote2 "^{super 2}Estimates for asymmetrical numeric variables are given as median (Minimum, Maximum).";
%end;

footnote3 "^{super 3}Estimates for categorical variables are given as frequency, percent.";



ods &output

%if &output=rtf %then %do;
style=journal
/*style(journal)=[posttext="SuperScript test \super 2"];*/
%end;

;

title &title;

proc print data=table1 noobs label;
run;

footnote;
title;

ods &output close;

ods html;

options notes source;



%mend;



