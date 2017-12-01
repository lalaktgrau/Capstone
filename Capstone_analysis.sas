*************   P   R   O   G   R   A   M       H   E   A   D   E   R   *****************
*****************************************************************************************
*                                                                                       *
*   PROJECT:    CAPSTONE                                                                *
*   AUTHOR:     LAURA GRAU 	                                                            *
*   CREATED:    2017-11-07                                                              *
*                                                                                       *
*   DATA USED:  HALTPKD                                                      			*
*   SOFTWARE:   SAS (r) Proprietary Software 9.4 (TS1M4)                                *                                                   
*                                                                                       *
*****************************************************************************************
***********************************************************************************; RUN;
/* ANALYSIS PLAN
1.	ANOVA Vitamin D according to PKD Mutation
2.	ANOVA FGF23 according to PKD Mutation
3.	Figure out proper significance level (Tukey’s adjustment?)
4.	Crude Models of each covariate with outcomes
	OUTCOMES: 	CHANGE IN EGFR 
				% INCREASE HTTKV 
5.	Significant Covariates go into final models
Decline in eGFR= genotype + FGF23 + Mineral Metabolites+interactions+ Demographics
% increase in htTKV= genotype + FGF23 + Mineral Metabolites+interactions+ Demographics
*/
PROC FORMAT ;
VALUE GENOTYPE
	1 	= "PKD1 Truncating"
	2	= "PKD1 Non-Truncating"
	3 	= "PKD2"
	4	= "No Mutation Detected";
	run;
	
DATA CAP.TRANSPOSED;
SET CAP.TRANSPOSED;
LABEL 	GENE1="GENOTYPE"
		SEX="GENDER"
		MARIT= "MARITAL STATUS"
		EDU="EDUCATIONAL ATTAINMENT"
		EMPL="EMPLOYMENT STATUS"
		HTTKV="HEIGHT-ADJUSTED TOTAL KIDNEY VOLUME"
		CKD_EPI_EGFR= "ESTIMATED GLOMERULAR FILTRATION RATE";	
FORMAT GENE1 GENOTYPE.;
		RUN;

PROC UNIVARIATE DATA=CAP.TRANSPOSED;
HISTOGRAM;
VAR HTTKV LHTTKV FGF LFGF PCTEGFR PCTLTKV CKD_EPI_EGFR;
RUN;

/*CATEGORICAL VARIABLES*/
PROC FREQ DATA=CAP.transposed;
TABLES GENE1 sex racef3 race marit empl edu;
RUN;

/*HOW ARE DEMOGRAPHICS DISTRIBUTED BY GENOTYPE?*/
PROC FREQ DATA=CAP.transposed;
TABLES sex*GENE1 racef3*GENE1 race*GENE1 marit*GENE1 empl*GENE1 edu*GENE1;
EXACT CHISQ;
RUN;

PROC FREQ DATA=CAP.transposed;
TABLES sex racef3 race marit empl edu;
RUN;


/*HOW DO CONTINUOUS VARIABLES DIFFER BY GENOTYPE?*/
PROC SORT DATA=CAP.transposed;
BY GENE1;
RUN;

PROC MEANS data=CAP.transposed n nmiss mean std LCLM UCLM;
VAR  egfrB1  httkvB1  sysavgB1 diasavgB1 lFGF PTH age 
pkdage hpbage  bmi bsa _1_25_OH_D _25_OH_D  
ualbum lrsca lrsp pctegfr pctLtkv;
CLASS GENE1;
OUTPUT OUT=WORK.MEANS;
RUN;


PROC BOXPLOT DATA=CAP.TRANSPOSED;
PLOT PCTEGFR*GENE1;
PLOT PCTLTKV*GENE1;
PLOT _1_25_OH_D*GENE1;
PLOT _25_OH_D*GENE1;
PLOT LFGF*GENE1;
RUN;  


/*ANOVA OF LOGFGF23 BY GENETIC MUTATION*/
PROC ANOVA DATA=CAP.transposed;
CLASS GENE1;
MODEL LFGF=GENE1;
MEANS GENE1;
RUN;

/*ANOVA OF VITAMIN D BY GENETIC MUTATION*/
PROC ANOVA DATA=CAP.transposed;
CLASS GENE1;
MODEL _25_OH_D=GENE1;
MEANS GENE1;
RUN;

/*ANOVA OF VITAMIN D BY GENETIC MUTATION*/
PROC ANOVA DATA=CAP.transposed;
CLASS GENE1;
MODEL _1_25_OH_D=GENE1;
MEANS GENE1;
RUN;






/*SURVIVAL ANALYSIS*/
/*
 * FIGURE OUT HOW TO DO COMPETING RISKS
 * USE TIMEPOINTID OR DVDATE AS TIME UNIT (DISCRETE OR CONTINUOUS)
 * 
 */


