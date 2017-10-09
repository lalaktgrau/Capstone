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

/*MERGE METABOLISM DATA*/
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

PROC CONTENTS DATA=CAP.HALT1;
RUN;

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

/*NEED TO TRANSPOSE THE DATA*/
/*STEP 1: CREATE DATA SET WITH UNCHANGING VARIABLES*/
/*USE TIMEPOINT ID TO TRANSPOSE?*/

DATA CAP.CONSTANTS;
SET CAP.HALT3;
/*WHERE YEARS=0;   ***FIGURE OUT TIME MEASUREMENT****/
KEEP /*WHICH VARIABLES AM I KEEPING*/;
RUN;

/*CANNOT TRANSPOSE USING TIMEPOINTID BECAUSE THERE ARE MULTIPLE VALUES FOR EACH TIMEPOINTID*/
/*PI SAID: Use the first and last time point for each participant to calculate change in eGFR and htTKV*/
PROC TRANSPOSE DATA=CAP.HALT3 OUT=WORK.HALT (DROP=_NAME_) PREFIX=egfr ;
BY HALTID;
ID timepointid;
VAR ckd_epi_egfr;
RUN; 

DATA CAP.CLEAN;
MERGE /*PUT ALL TRANSPOSED DATA SETS HERE*/;
BY HALTID;
RUN;
