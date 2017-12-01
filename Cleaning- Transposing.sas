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

DATA CAP.HALT1;
set CAP.HALT1;
if timepointid='SB1' then timepointid='B1';
RUN; 

data CAP.transposed (drop=f1 f2);
set CAP.transposed;
b1=coalesce(b1,f1);
b2=coalesce(b2,f2);
run;

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

/*RECODE SEX TO BE 0 AND 1*/
DATA CAP.HALT3;
SET CAP.HALT3;
IF SEX=1 THEN SEX=0;
ELSE IF SEX=2 THEN SEX=1;
LFGF=LOG(FGF);
lhttkv=LOG(HTTKV);
RUN;

PROC UNIVARIATE DATA=CAP.HALT3;
HISTOGRAM LFGF;
RUN;
/*CREATING CHANGE OUTCOMES*/
/*EGFR*/
PROC SORT DATA=CAP.HALT3 OUT=WORK.CHANGE SORTSEQ=LINGUISTIC (NUMERIC_COLLATION=ON);
BY HALTID TIMEPOINTID;
RUN;

DATA WORK.CHANGEEGFR;
SET WORK.CHANGE;
IF CKD_EPI_EGFR='.' THEN DELETE;
RUN;

DATA WORK.CHANGEEGFR;
SET WORK.CHANGEEGFR;
BY HALTID;
IF FIRST.HALTID THEN OUTPUT;
IF LAST.HALTID THEN OUTPUT;
RUN;

DATA WORK.CHANGEEGFR;
SET WORK.CHANGEEGFR;
   PCTEGFR = dif( CKD_EPI_EGFR ) / lag( CKD_EPI_EGFR ) * 100;
   RUN;
   
   
DATA WORK.CHANGEEGFR;
SET WORK.CHANGEEGFR;
BY HALTID;
IF FIRST.HALTID THEN DELETE;
RUN;

/*HTTKV*/

DATA WORK.CHANGETKV;
SET WORK.CHANGE;
IF HTTKV='.' THEN DELETE;
RUN;

DATA WORK.CHANGETKV;
SET WORK.CHANGETKV;
BY HALTID;
IF FIRST.HALTID THEN OUTPUT;
IF LAST.HALTID THEN OUTPUT;
RUN;

DATA WORK.CHANGETKV;
SET WORK.CHANGETKV;
   PCTLTKV = dif(LHTTKV) / lag(LHTTKV) * 100;
   RUN; 
   
DATA WORK.CHANGETKV;
SET WORK.CHANGETKV;
BY HALTID;
IF FIRST.HALTID THEN DELETE;
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

/*MERGING TRANSPOSED DATA & CHANGE OUTCOMES*/
DATA CAP.transposed;
MERGE WORK.HALT WORK.HALT1 WORK.HALT2 WORK.HALT3 CAP.CONSTANTS WORK.CHANGETKV  WORK.CHANGEEGFR; /*PUT ALL TRANSPOSED DATA SETS HERE*/;
BY HALTID;
RUN;

PROC SORT DATA=CAP.transposed;
BY TIMEPOINTID;
RUN;












