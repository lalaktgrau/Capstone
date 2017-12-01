
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
%MACRO CAPANL (DATASET= ,OUTCOME= ,COVAR= , CLASS=);
PROC GLM DATA=&DATASET;
CLASS &CLASS;
MODEL &OUTCOME=&COVAR/ SOLUTION;
RUN;
%MEND ; 


/*RUNNING THE MACRO*/
%CAPANL (DATASET=CAP.TRANSPOSED,OUTCOME=PCTEGFR ,COVAR=LFGF GENE1  , CLASS=GENE1);



