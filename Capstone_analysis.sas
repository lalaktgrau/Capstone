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

PROC GLM DATA=CAP.CLEAN;
MODEL LFGF=GENE1/SOLUTION;
LSMEANS;
RUN;

PROC GLM DATA=CAP.CLEAN;
MODEL _25_OH_D=GENE1/SOLUTION;
LSMEANS;
RUN;

PROC GLM DATA=CAP.CLEAN;
MODEL _1_25_OH_D=GENE1/SOLUTION;
LSMEANS;
RUN;


/*SURVIVAL ANALYSIS*/
/*
 * FIGURE OUT HOW TO DO COMPETING RISKS
 * USE TIMEPOINTID OR DVDATE AS TIME UNIT (DISCRETE OR CONTINUOUS)
 * 
 */


