
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
/*HERE IS MY MACRO FOR REGRESSION*/
%LET VLIST= BMI SYSTOLIC_AVG DIASTOLIC_AVG UALBUM LRSCA LRSP GENE1  SEX RACEF3 RANDTYPE STUDY STUDY_T*;


%MACRO CAPGLM (DATASET= , OUTCOME= , CLASS=);
%DO J=1 %TO 14;
PROC GLM DATA=&DATASET;
CLASS &CLASS;
MODEL &OUTCOME=%SCAN(&VLIST, &J)/ SOLUTION;
RUN;
%END;
%MEND ; 

/*CRUDE MODELS*/
%CAPGLM (DATASET=CAP.TRANSPOSED,OUTCOME=PCTEGFR ,CLASS=);
%CAPGLM (DATASET=CAP.TRANSPOSED,OUTCOME=PCTLTKV , CLASS=);




/*CRUDE MODELS FOR PRIMARY COVARIATES OF INTEREST*/
%CAPGLM (DATASET=CAP.TRANSPOSED,OUTCOME=PCTEGFR ,COVAR=LFGF GENE1  , CLASS=GENE1);
%CAPGLM (DATASET=CAP.TRANSPOSED,OUTCOME=PCTEGFR ,COVAR=LFGF GENE1 LFGF*GENE1 , CLASS=GENE1);

%CAPGLM (DATASET=CAP.TRANSPOSED,OUTCOME=PCTEGFR ,COVAR=_1_25_OH_D GENE1  , CLASS=GENE1);
%CAPGLM (DATASET=CAP.TRANSPOSED,OUTCOME=PCTEGFR ,COVAR=_1_25_OH_D GENE1 _1_25_OH_D*GENE1 , CLASS=GENE1);

%CAPGLM (DATASET=CAP.TRANSPOSED,OUTCOME=PCTEGFR ,COVAR=_25_OH_D GENE1  , CLASS=GENE1);
%CAPGLM (DATASET=CAP.TRANSPOSED,OUTCOME=PCTEGFR ,COVAR=_25_OH_D GENE1  _25_OH_D*GENE1, CLASS=GENE1);

%CAPGLM (DATASET=CAP.TRANSPOSED,OUTCOME=PCTLTKV ,COVAR=LFGF GENE1  , CLASS=GENE1);
%CAPGLM (DATASET=CAP.TRANSPOSED,OUTCOME=PCTLTKV ,COVAR=LFGF GENE1 LFGF*GENE1 , CLASS=GENE1);

%CAPGLM (DATASET=CAP.TRANSPOSED,OUTCOME=PCTLTKV ,COVAR=_1_25_OH_D GENE1  , CLASS=GENE1);
%CAPGLM (DATASET=CAP.TRANSPOSED,OUTCOME=PCTLTKV ,COVAR=_1_25_OH_D GENE1 _1_25_OH_D*GENE1 , CLASS=GENE1);

%CAPGLM (DATASET=CAP.TRANSPOSED,OUTCOME=PCTLTKV ,COVAR=_25_OH_D GENE1  , CLASS=GENE1);
%CAPGLM (DATASET=CAP.TRANSPOSED,OUTCOME=PCTLTKV ,COVAR=_25_OH_D GENE1 _25_OH_D*GENE1 , CLASS=GENE1);




