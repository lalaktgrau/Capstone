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
ODS LISTING CLOSE;
ODS HTML PATH="/folders/myshortcuts/Capstone/Reports";
ODS GRAPHICS ON;


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

/*BASED ON DISTRIBUTION OF FGF, I LOG TRANSFORMED*/
/*EDIT SEX CODE*/
DATA CAP.HALT3;
SET CAP.HALT3;
LFGF=LOG(FGF);
IF SEX=1 THEN SEX=0;
ELSE IF SEX=2 THEN SEX=1;
RUN;


PROC SGPLOT DATA=CAP.HALT3;
HISTOGRAM LFGF;
RUN;


/*ASK INVESTIGATORS WHY THESE ARE DIFFERENT*/
/*HOW DO I CREATE OUTCOME VARIABLE?*/
/*NEED TO CALCULATE % CHANGE IN HTTKV & EGFR FROM BASELINE TO LAST FOLLOW UP*/
/*NEED TO FIGURE OUT WHY 21 OBSERVATIONS ARE BEING OMITTED FOR HAVING MISSING ID*/

/*BEGINNING DESCRIPTIVES*/
PROC SORT DATA=cap.halt3;
BY GENE1;
RUN;

PROC MEANS DATA=CAP.HALT3;
VAR LFGF;
BY GENE1;
*IS THERE SOMETHING I CAN PUT IN HERE SO MULTIPLE OBSERVATIONS AREN'T INCLUDED FOR SAME PERSON?*;
RUN;

/*MISSING DATA ANALYSIS*/
DATA CAP.MISSING;
SET CAP.HALT3;
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
IF TIMEPOINTID=' ' THEN TIMEPOINTIDMISS=1;
ELSE 					TIMEPOINTIDMISS=0;
IF DVDATE=' ' THEN DVDATEMISS=1;
ELSE   DVDATEMISS=0;
RUN;

PROC FREQ DATA=CAP.MISSING;
TABLES GENEMISS SEXMISS RACEFMISS RACEMISS MARITMISS EMPLMISS EDUMISS TIMEPOINTIDMISS DVDATEMISS;
RUN;






