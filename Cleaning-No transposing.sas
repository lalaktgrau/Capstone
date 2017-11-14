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
   PCTTKV = dif(HTTKV) / lag(HTTKV) * 100;
   RUN; 
   
DATA WORK.CHANGETKV;
SET WORK.CHANGETKV;
BY HALTID;
IF FIRST.HALTID THEN DELETE;
RUN;


/*BEGINNING DESCRIPTIVES*/
PROC SORT DATA=WORK.CHANGEHALT;
BY GENE1;
RUN;

PROC MEANS DATA=WORK.CHANGEHALT;
VAR LFGF;
BY GENE1;
RUN;

/*MISSING DATA ANALYSIS*/
DATA CAP.MISSING;
SET CAP.HALT3;		
IF GENE1='.' 		THEN 	GENEMISS=1;
ELSE 					GENEMISS=0;
IF SEX='.'			THEN 	SEXMISS=1;
ELSE					SEXMISS=0;
IF RACEF3='.' 		THEN	RACEFMISS=1;
ELSE					RACEFMISS=0;
IF RACE='.'			THEN 	RACEMISS=1;
ELSE					RACEMISS=0;
IF MARIT='.'		THEN	MARITMISS=1;
ELSE 					MARITMISS=0;
IF EMPL='.'			THEN	EMPLMISS=1;
ELSE 					EMPLMISS=0;
IF EDU='.' 			THEN 	EDUMISS=1;
ELSE 					EDUMISS=0;
IF TIMEPOINTID=' ' 	THEN TIMEPOINTIDMISS=1;
ELSE 						TIMEPOINTIDMISS=0;
IF DVDATE=' ' 		THEN DVDATEMISS=1;
ELSE  						 DVDATEMISS=0;
RUN;

PROC FREQ DATA=CAP.MISSING;
TABLES GENEMISS SEXMISS RACEFMISS RACEMISS MARITMISS EMPLMISS EDUMISS TIMEPOINTIDMISS DVDATEMISS;
RUN;

/*GRAPHICS*/
PROC SORT DATA=CAP.HALT3 OUT=WORK.CHANGE SORTSEQ=LINGUISTIC (NUMERIC_COLLATION=ON);
BY HALTID TIMEPOINTID ;
RUN;

PROC SGPLOT DATA=CAP.HALT3 ;
SERIES X=timepointid Y=HTTKV/GROUP=GENE1;
XAXIS TYPE=DISCRETE;
RUN;

PROC SGPLOT DATA=CAP.HALT3 ;
SERIES X=timepointid Y=CKD_EPI_EGFR/GROUP=GENE1;
XAXIS TYPE=DISCRETE;
RUN;

/*MEANS BY GENOTYPE*/
/*GENOTYPE=1*/
DATA WORK.GENE1;
SET CAP.HALT3;
WHERE GENE1=1;
RUN;

PROC SORT DATA=WORK.GENE1;
BY TIMEPOINTID;
RUN;

PROC BOXPLOT DATA=WORK.GENE1;
PLOT HTTKV*TIMEPOINTID;
RUN;
PROC BOXPLOT DATA=WORK.GENE1;
PLOT CKD_EPI_EGFR*TIMEPOINTID;
RUN;

PROC MEANS DATA=WORK.GENE1 MEAN;
OUTPUT OUT=WORK.MEANSGENE1 MEAN=;
VAR HTTKV;
BY TIMEPOINTID;
RUN;

PROC SGPLOT DATA=WORK.MEANSGENE1;
SCATTER X=TIMEPOINTID Y=HTTKV;
XAXIS TYPE=DISCRETE;RUN;

/*GENOTYPE=2*/
DATA WORK.GENE2;
SET CAP.HALT3;
WHERE GENE1=2;
RUN;

PROC BOXPLOT DATA=WORK.GENE2;
PLOT HTTKV*TIMEPOINTID;
RUN;
PROC BOXPLOT DATA=WORK.GENE2;
PLOT CKD_EPI_EGFR*TIMEPOINTID;
RUN;

PROC SORT DATA=WORK.GENE2;
BY TIMEPOINTID;
RUN;
PROC MEANS DATA=WORK.GENE2 MEAN;
OUTPUT OUT=WORK.MEANSGENE2 MEAN=;
VAR HTTKV;
BY TIMEPOINTID;
RUN;

PROC SGPLOT DATA=WORK.MEANSGENE2;
SCATTER X=TIMEPOINTID Y=HTTKV;
XAXIS TYPE=DISCRETE;RUN;

/*GENOTYPE=3*/
DATA WORK.GENE3;
SET CAP.HALT3;
WHERE GENE1=3;
RUN;

PROC BOXPLOT DATA=WORK.GENE3;
PLOT HTTKV*TIMEPOINTID;
RUN;
PROC BOXPLOT DATA=WORK.GENE3;
PLOT CKD_EPI_EGFR*TIMEPOINTID;
RUN;

PROC SORT DATA=WORK.GENE3;
BY TIMEPOINTID;
RUN;
PROC MEANS DATA=WORK.GENE3 MEAN;
OUTPUT OUT=WORK.MEANSGENE3 MEAN=;
VAR HTTKV;
BY TIMEPOINTID;
RUN;

PROC SGPLOT DATA=WORK.MEANSGENE3;
SCATTER X=TIMEPOINTID Y=HTTKV;
XAXIS TYPE=DISCRETE;RUN;

/*GENOTYPE=4*/
DATA WORK.GENE4;
SET CAP.HALT3;
WHERE GENE1=4;
RUN;

PROC BOXPLOT DATA=WORK.GENE4;
PLOT HTTKV*TIMEPOINTID;
RUN;
PROC BOXPLOT DATA=WORK.GENE4;
PLOT CKD_EPI_EGFR*TIMEPOINTID;
RUN;

PROC SORT DATA=WORK.GENE4;
BY TIMEPOINTID;
RUN;
PROC MEANS DATA=WORK.GENE4 MEAN;
OUTPUT OUT=WORK.MEANSGENE4 MEAN=;
VAR HTTKV;
BY TIMEPOINTID;
RUN;

PROC SGPLOT DATA=WORK.MEANSGENE4;
SCATTER X=TIMEPOINTID Y=HTTKV;
XAXIS TYPE=DISCRETE;
RUN;






























