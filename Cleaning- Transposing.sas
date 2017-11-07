*************   P   R   O   G   R   A   M       H   E   A   D   E   R   *****************
*****************************************************************************************
*                                                                                       *
*   PROJECT:    CAPSTONE                                                                *
*   AUTHOR:     LAURA GRAU 	                                                            *
*   CREATED:    2017-09-24                                                              *
*                                                                                       *
*   DATA USED:  HALTPKD                                                      			*
*   SOFTWARE:   SAS (r) Proprietary Software 9.4 (TS1M4)                                *                                                   
*                                                                                       *
*****************************************************************************************
***********************************************************************************; RUN;
/*READ IN GENETIC DATA*/
PROC IMPORT 
		DATAFILE= "/folders/myshortcuts/Analysis/1- Source/GeneticDataComplete.xlsx"
		OUT=CAP.GEN
		DBMS= XLSX
		REPLACE;
	GETNAMES=YES;
RUN;

/*READ IN MINERAL METABOLISM DATA-SERUM*/
PROC IMPORT 
		DATAFILE= "/folders/myshortcuts/Analysis/1- Source/HALT_Mineral_Metabolism_EDITS.csv"
		OUT=CAP.METSERUM
		DBMS= CSV
		REPLACE;
	GETNAMES=YES;
RUN;

/*EDIT HALTID IN METABOLISM DATA*/
DATA CAP.METSERUM;
SET CAP.METSERUM;
HALTID=SUBSTR (VIAL_ID, 5,8);
RUN;

/*READ IN HALT DATA SET*/
PROC IMPORT 
		DATAFILE= "/folders/myshortcuts/Analysis/1- Source/HALT_Datset.xlsx"
		OUT=CAP.HALT
		DBMS=XLSX
		REPLACE;
		GETNAMES=YES;
RUN;

/*PLEASE NOTE: DROPPING TIMEPOINTID, AS GENETIC DATA WILL NOT CHANGE WITH TIME*/
/*OTHERWISE, MERGE OF DATASETS TRUNCATES TIMEPOINTID*/
DATA CAP.GEN;
SET CAP.GEN;
DROP timepointid;
RUN;

/*MERGE DATA*/
PROC SORT DATA=CAP.METSERUM;
BY HALTID;
RUN;

PROC SORT DATA=CAP.HALT;
BY HALTID;
RUN;

PROC SORT DATA=CAP.GEN;
BY HALTID;
RUN;

DATA CAP.HALT1;
MERGE CAP.METSERUM CAP.GEN CAP.HALT;
BY HALTID;
RUN;

/*CREATING VARIABLES OF INTEREST*/
/*NEED TO CREATE 1,25(OH)D Total= 1, 25(OH)D2 + 1,25(OH)D3*/
/*NEED TO CREATE 25(OH)D=25(OH)D2 + 25(OH)D3*/
DATA CAP.HALT2;
SET CAP.HALT1;
_1_25_OH_D	= _1_25_OH_2D2  + _1_25_OH_2D3;
_25_OH_D	= _25_OH_D2 	+ _25_OH_D3;
RUN;

/*GENOTYPE: 
1 = PKD1 truncating
2= PKD1 non-truncating
3 = PKD2
4= no mutation detected*/

DATA CAP.HALT3;
SET CAP.HALT2;
IF GENE="PKD1" AND MUTATION_EFFECT="Truncating" 	THEN GENE1=1;
IF GENE="PKD1" AND MUTATION_EFFECT="Non Truncating" THEN GENE1=2;
IF GENE="PKD2" 										THEN GENE1=3;
IF GENE="NMD"	  								    THEN GENE1=4;
IF GENE=" "											THEN GENE1=" ";
RUN;

	
DATA CAP.HALT3;
SET CAP.HALT3;
DROP VAR7 box row column vial_ID alternate barcode Pittsburgh_Family_ID;
run;

PROC SORT DATA=CAP.HALT3;
BY HALTID timepointid;
run;

PROC CONTENTS DATA=CAP.HALT3;
RUN;

/*NEED TO TRANSPOSE THE DATA*/
/*STEP 1: CREATE DATA SET WITH UNCHANGING VARIABLES*/
/*USE TIMEPOINT ID TO TRANSPOSE?*/

DATA CAP.CONSTANTS;
SET CAP.HALT3;
WHERE timepointid='B1' OR timepointid='SB1';   /*USING B1/SB1 AS BASELINE FOR DEMOGRAPHIC*/
KEEP timepointid haltid FGF PTH _25_OH_D _1_25_OH_D GENE1 AGE SEX RACEF3 RACE PKDAGE HPBAGE hght_cm WGHT_KG BMI BSA MARIT EMPL EDU;
RUN;

/*PI SAID: Use the first and last time point for each participant to calculate change in eGFR and htTKV*/
PROC TRANSPOSE DATA=CAP.HALT3 OUT=WORK.HALT (DROP= _NAME_ _LABEL_) PREFIX=egfr ;
BY HALTID;
ID timepointid;
VAR ckd_epi_egfr;
RUN; 

PROC TRANSPOSE DATA=CAP.HALT3 OUT=WORK.HALT1 (DROP= _NAME_ _LABEL_) PREFIX=httkv ;
BY HALTID;
ID timepointid;
VAR httkv;
RUN;

PROC TRANSPOSE DATA=CAP.HALT3 OUT=WORK.HALT2 (DROP= _NAME_ _LABEL_) PREFIX=sysavg ;
BY HALTID;
ID timepointid;
VAR systolic_avg;
RUN;

PROC TRANSPOSE DATA=CAP.HALT3 OUT=WORK.HALT3 (DROP= _NAME_ _LABEL_) PREFIX=diasavg ;
BY HALTID;
ID timepointid;
VAR diastolic_avg;
RUN;

DATA CAP.CLEAN;
MERGE WORK.HALT WORK.HALT1 WORK.HALT2 WORK.HALT3 CAP.CONSTANTS; /*PUT ALL TRANSPOSED DATA SETS HERE*/;
BY HALTID;
RUN;

PROC SORT DATA=CAP.CLEAN;
BY TIMEPOINTID;
RUN;

/*HOW DO I COMBINE B1 AND SB1?*/
/*ASK INVESTIGATORS WHY THESE ARE DIFFERENT*/
/*HOW DO I CREATE OUTCOME VARIABLE?*/
/*NEED TO CALCULATE % CHANGE IN HTTKV & EGFR FROM BASELINE TO LAST FOLLOW UP*/
/*NEED TO FIGURE OUT WHY 21 OBSERVATIONS ARE BEING OMITTED FOR HAVING MISSING ID*/

/*BEGINNING DESCRIPTIVES*/
/*** Analyze categorical variables ***/
title "Frequencies for Categorical Variables";

proc freq data=CAP.CLEAN;
	tables timepointid / plots=(freqplot);
run;

/*** Analyze numeric variables ***/
title "Descriptive Statistics for Numeric Variables";

proc means data=CAP.CLEAN n nmiss min mean median max std;
	var egfrF12 egfrF18 egfrF24 egfrF30 egfrF36 egfrF42 egfrF48 egfrF5 egfrF54 
		egfrSB1 egfrB1 egfrF72 egfrF60 egfrF66 egfrF78 egfrF84 egfrF90 egfrF96 
		httkvF12 httkvF18 httkvF24 httkvF30 httkvF36 httkvF42 httkvF48 httkvF5 
		httkvF54 httkvSB1 httkvB1 httkvF72 httkvF60 httkvF66 httkvF78 httkvF84 
		httkvF90 httkvF96 sysavgF12 sysavgF18 sysavgF24 sysavgF30 sysavgF36 sysavgF42 
		sysavgF48 sysavgF5 sysavgF54 sysavgSB1 sysavgB1 sysavgF72 sysavgF60 sysavgF66 
		sysavgF78 sysavgF84 sysavgF90 sysavgF96 diasavgF12 diasavgF18 diasavgF24 
		diasavgF30 diasavgF36 diasavgF42 diasavgF48 diasavgF5 diasavgF54 diasavgSB1 
		diasavgB1 diasavgF72 diasavgF60 diasavgF66 diasavgF78 diasavgF84 diasavgF90 
		diasavgF96 FGF PTH age sex racef3 race pkdage hpbage hght_cm wght_kg bmi bsa 
		marit empl edu _1_25_OH_D _25_OH_D GENE1;
run;

title;

proc univariate data=CAP.CLEAN noprint;
	histogram egfrF12 egfrF18 egfrF24 egfrF30 egfrF36 egfrF42 egfrF48 egfrF5 
		egfrF54 egfrSB1 egfrB1 egfrF72 egfrF60 egfrF66 egfrF78 egfrF84 egfrF90 
		egfrF96 httkvF12 httkvF18 httkvF24 httkvF30 httkvF36 httkvF42 httkvF48 
		httkvF5 httkvF54 httkvSB1 httkvB1 httkvF72 httkvF60 httkvF66 httkvF78 
		httkvF84 httkvF90 httkvF96 sysavgF12 sysavgF18 sysavgF24 sysavgF30 sysavgF36 
		sysavgF42 sysavgF48 sysavgF5 sysavgF54 sysavgSB1 sysavgB1 sysavgF72 sysavgF60 
		sysavgF66 sysavgF78 sysavgF84 sysavgF90 sysavgF96 diasavgF12 diasavgF18 
		diasavgF24 diasavgF30 diasavgF36 diasavgF42 diasavgF48 diasavgF5 diasavgF54 
		diasavgSB1 diasavgB1 diasavgF72 diasavgF60 diasavgF66 diasavgF78 diasavgF84 
		diasavgF90 diasavgF96 FGF PTH age sex racef3 race pkdage hpbage hght_cm 
		wght_kg bmi bsa marit empl edu _1_25_OH_D _25_OH_D GENE1;
run;

/*BASED ON DISTRIBUTION OF FGF, I LOG TRANSFORMED*/
DATA CAP.CLEAN;
SET CAP.CLEAN;
LFGF=LOG(FGF);
RUN;

PROC SGPLOT DATA=CAP.CLEAN;
HISTOGRAM LFGF;
RUN;

/*CONSIDER RECATEGORIZING VARIABLES TO HAVE LARGER GROUPS*/
/*RECODE SEX TO BE 0 AND 1*/
DATA CAP.CLEAN;
SET CAP.CLEAN;
IF SEX=1 THEN SEX=0;
ELSE IF SEX=2 THEN SEX=1;
RUN;

/*CATEGORICAL VARIABLES*/
PROC FREQ DATA=CAP.CLEAN;
TABLES GENE1 sex racef3 race marit empl edu;
RUN;

/*HOW ARE DEMOGRAPHICS DISTRIBUTED BY GENOTYPE?*/
PROC FREQ DATA=CAP.CLEAN;
TABLES sex*GENE1 racef3*GENE1 race*GENE1 marit*GENE1 empl*GENE1 edu*GENE1;
RUN;

/*HOW DO CONTINUOUS VARIABLES DIFFER BY GENOTYPE?*/
PROC SORT DATA=CAP.CLEAN;
BY GENE1;
RUN;
PROC MEANS data=CAP.CLEAN n nmiss min mean median max std;
	VAR egfrF12 egfrF18 egfrF24 egfrF30 egfrF36 egfrF42 egfrF48 egfrF5 egfrF54 
		egfrSB1 egfrB1 egfrF72 egfrF60 egfrF66 egfrF78 egfrF84 egfrF90 egfrF96 
		httkvF12 httkvF18 httkvF24 httkvF30 httkvF36 httkvF42 httkvF48 httkvF5 
		httkvF54 httkvSB1 httkvB1 httkvF72 httkvF60 httkvF66 httkvF78 httkvF84 
		httkvF90 httkvF96 sysavgF12 sysavgF18 sysavgF24 sysavgF30 sysavgF36 sysavgF42 
		sysavgF48 sysavgF5 sysavgF54 sysavgSB1 sysavgB1 sysavgF72 sysavgF60 sysavgF66 
		sysavgF78 sysavgF84 sysavgF90 sysavgF96 diasavgF12 diasavgF18 diasavgF24 
		diasavgF30 diasavgF36 diasavgF42 diasavgF48 diasavgF5 diasavgF54 diasavgSB1 
		diasavgB1 diasavgF72 diasavgF60 diasavgF66 diasavgF78 diasavgF84 diasavgF90 
		diasavgF96 FGF PTH age pkdage hpbage hght_cm wght_kg bmi bsa 
		 _1_25_OH_D _25_OH_D ;
		 BY GENE1;
RUN;

/*MISSING DATA ANALYSIS*/
DATA CAP.MISSING;
SET CAP.CLEAN;
IF GENE1='.' 	THEN 	GENEMISS=1;
ELSE 					GENEMISS=0;
IF SEX='.'		THEN 	SEXMISS=1;
ELSE					SEXMISS=0;
IF RACEF3='.' 	THEN	RACEFMISS=1;
ELSE					RACEFMISS=0;
IF RACE='.'		THEN 	RACEMISS=1;
ELSE					RACEMISS=0;
IF MARIT='.'	THEN	MARITMISS=1;
ELSE 					MARITMISS=0;
IF EMPL='.'		THEN	EMPLMISS=1;
ELSE 					EMPLMISS=0;
IF EDU='.' 		THEN 	EDUMISS=1;
ELSE 					EDUMISS=0;
RUN;

PROC FREQ DATA=CAP.MISSING;
TABLES GENEMISS SEXMISS RACEFMISS RACEMISS MARITMISS EMPLMISS EDUMISS;
RUN;






