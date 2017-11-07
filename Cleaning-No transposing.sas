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

/*HOW DO I CREATE OUTCOME VARIABLE?*/
/*NEED TO CALCULATE % CHANGE IN HTTKV & EGFR FROM BASELINE TO LAST FOLLOW UP*/
/*NEED TO FIGURE OUT WHY 21 OBSERVATIONS ARE BEING OMITTED FOR HAVING MISSING ID*/

/*BEGINNING DESCRIPTIVES*/
PROC SORT DATA=CAP.HALT3;
BY GENE1;
RUN;

PROC MEANS DATA=CAP.HALT3;
VAR LFGF;
BY GENE1;
*IS THERE SOMETHING I CAN PUT IN HERE SO MULTIPLE OBSERVATIONS AREN'T INCLUDED FOR SAME PERSON?*;
RUN;

/*CREATING CHANGE OUTCOMES*/
PROC SORT DATA=CAP.HALT3 OUT=WORK.CHANGE SORTSEQ=LINGUISTIC (NUMERIC_COLLATION=ON);
BY HALTID TIMEPOINTID;
RUN;

DATA WORK.CHANGE1;
SET WORK.CHANGE;
 
*INSERT HERE HOW TO CHOOSE OUTCOME IN FIRST AND LAST*;
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






