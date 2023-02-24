
USE [Data_Science]
GO

/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/*																								*/
/* PROGRAMADOR: KAIKE NATAN									                                    */
/* VERSAO     : DATA: 22/02/2022																*/
/* DESCRICAO  : RESPONSAVEL POR ATUALIZAR A FOTOGRAFIA DA ORGINAL					  		    */
/* ALTERACAO                                                                                    */
/*        2. PROGRAMADOR: KAIKE NATAN										 DATA: 21/05/2022	*/		
/*           DESCRICAO  : INCLUS�O DA TRIGGER PARA CONSOLIDADO DO DIA							*/
/* ALTERACAO                                                                                    */
/*        3. PROGRAMADOR: 													 DATA: __/__/____	*/		
/*           DESCRICAO  :										 								*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
	ALTER PROC [dbo].[sp_ds_photography_original] AS
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	VARI�VEL DE CONTROLE														    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
	DECLARE @DATA AS DATE = CAST(GETDATE() AS DATE)
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	MODELAGEM DAS INFORMA��ES													    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
SELECT DISTINCT
 CASE WHEN IDEMP_CON = 18 THEN 'PIC PAY' END AS CARTEIRA
,CASE WHEN DATEDIFF(DAY, CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) <= 90 THEN 'FASE 1' ELSE 'FASE 2' END FASE
,CGCPF_DEV AS CPF
,TITUL_TRA AS CONTRATO
,DATEDIFF(DAY, CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) [ATRASO CONTRATO]
,CONVERT(DATE,DTINC_CON) AS INCLUS�O
,RTRIM(LTRIM(DESCR_SIT)) AS SITUACAO
,RTRIM(LTRIM(TB_SEGMENTACAO.DESCR_SEG)) AS [SEGMENTA��O]
,CASE 
	  WHEN DATEDIFF(DAY,CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 5 AND 30      THEN '005 a 030'
      WHEN DATEDIFF(DAY,CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 31 AND 60     THEN '031 a 060'
      WHEN DATEDIFF(DAY,CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 61 AND 90     THEN '061 a 090'
      WHEN DATEDIFF(DAY,CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 91 AND 120    THEN '091 a 120'
      WHEN DATEDIFF(DAY,CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 121 AND 180   THEN '121 a 180'
      WHEN DATEDIFF(DAY,CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 181 AND 240   THEN '181 a 240'
      WHEN DATEDIFF(DAY,CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 241 AND 300   THEN '241 a 300'
      WHEN DATEDIFF(DAY,CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 301 AND 360   THEN '301 a 360'
      WHEN DATEDIFF(DAY,CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 361 AND 480   THEN '361 a 480'
      WHEN DATEDIFF(DAY,CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 481 AND 600   THEN '481 a 600'
      WHEN DATEDIFF(DAY,CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 601 AND 720   THEN '601 a 720'
      WHEN DATEDIFF(DAY,CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 721 AND 99999 THEN '720+' ELSE 'Verificar' END [FAIXA]
,ISNULL([ELEGIVEL],1)[ELEGIVEL]
,CASE WHEN DTINC_CON <= DATEADD(DAY,1,(DATEADD(MONTH,-1,EOMONTH(GETDATE())))) THEN 1 ELSE 0 END [ESTOQUE]
,CONVERT(MONEY,VLFAT_TRA) AS [SALDO]
,PRODUTO_DP [PRODUTO] 
,CASE WHEN SCOAS_CON IN ('S','N') AND IDDOC_TRA IN (527,528,909,910)		AND DATEDIFF(DAY, CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 15 AND 59 THEN 1
      WHEN SCOAS_CON IN ('S','N') AND IDDOC_TRA IN (534,573,916,938)		AND DATEDIFF(DAY, CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 10 AND 59 THEN 1
      WHEN SCOAS_CON IN ('S','N') AND IDDOC_TRA IN (442,541,654,824,923)	AND DATEDIFF(DAY, CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 1  AND 34 THEN 1
      WHEN SCOAS_CON IN ('S','N') AND IDDOC_TRA IN (499,501,503,505,507
												   ,514,515,516,517,881
												   ,883,885,887,889,896
												   ,897,898,899)			AND DATEDIFF(DAY, CONVERT(DATE,DTFAT_TRA),CONVERT(DATE,GETDATE())) BETWEEN 6  AND 59 THEN 1 ELSE 0 END [CAMPANHA_FNV]
,CONVERT(DATE,GETDATE()) AS DT_INFO
,CONVERT(DATE,DTNAS_DEV) DT_NASC
,RTRIM(LTRIM(CONTA_TRA)) SCORE
,ESTAD_ETD UF
INTO #TEMP
 FROM		   [10.251.1.36].[nectar].[dbo].TB_CONTRATO			WITH(NOLOCK) 
    INNER JOIN [10.251.1.36].[nectar].[dbo].TB_DEVEDOR			WITH(NOLOCK) ON IDDEV_CON	= IDDEV_DEV
	INNER JOIN [10.251.1.36].[nectar].[dbo].TB_TRANSACAO B		WITH(NOLOCK) ON B.IDCON_TRA	= IDCON_CON
    INNER JOIN [10.251.1.36].[nectar].[dbo].TB_DOCUMENTO		WITH(NOLOCK) ON IDDOC_DOC	= IDDOC_TRA
    INNER JOIN [10.251.1.36].[nectar].[dbo].TB_SITUACAO			WITH(NOLOCK) ON IDSIT_CON	= IDSIT_SIT
	LEFT JOIN  [10.251.1.36].[NECTAR].[DBO].[TB_ENDERECO]		WITH(NOLOCK) ON IDCON_CON	= IDORI_END   
	LEFT JOIN  [10.251.1.36].[NECTAR].[DBO].[TB_ESTADO]			WITH(NOLOCK) ON IDEST_ETD	= IDEST_END  
	INNER JOIN [10.251.1.36].[nectar].[dbo].TB_SEGMENTACAO		WITH(NOLOCK) ON IDSEG_CON	= IDSEG_SEG
	INNER JOIN [10.251.1.36].[nectar].[dbo].TB_CARTEIRA			WITH(NOLOCK) ON IDEMP_CAR	= IDEMP_CON
	LEFT JOIN  [Data_Science].[dbo].[TB_DS_SEGMENTATIONS] C		WITH(NOLOCK) ON C.DESCR_SEG	= TB_SEGMENTACAO.DESCR_SEG AND C.IDEMP = IDEMP_CON
	LEFT JOIN  Data_Science..tb_ds_original_depara_produto ON IDDOC_DP = IDDOC_TRA
WHERE IDEMP_CON = 18
AND   STDEV_CON = 0
AND   IDSIT_CON <> 45
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: TRUNCA A TABELA D0 E INSERE AS INFORMA��ES ATUALIZADAS						    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
TRUNCATE TABLE DATA_SCIENCE.DBO.ESTOQUE_ORIGINAL_D0
INSERT INTO    DATA_SCIENCE.DBO.ESTOQUE_ORIGINAL_D0
SELECT *  FROM #TEMP 
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: DELETA AS INFORMA��ES DO DIA E INSERETE NOVAMENTE								    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

DELETE FROM DATA_SCIENCE.DBO.ESTOQUE_ORIGINAL WHERE DT_INFO = @DATA
INSERT INTO DATA_SCIENCE.DBO.ESTOQUE_ORIGINAL
SELECT * FROM #TEMP


DELETE FROM DATA_SCIENCE.DBO.ESTOQUE_ORIGINAL_MES WHERE DT_INFO = @DATA
INSERT INTO DATA_SCIENCE.DBO.ESTOQUE_ORIGINAL_MES
SELECT * FROM #TEMP

/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :DELETA AS INF DO MES ANTERIOR NO 6 DIA DO MES ATUAL							    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

DELETE FROM DATA_SCIENCE.DBO.ESTOQUE_ORIGINAL_MES 
WHERE DATEPART(MM,DT_INFO) <> DATEPART(MM,CONVERT(DATE,GETDATE())) 
AND CONVERT(DATE,GETDATE()) = CONVERT(DATE,DATEADD(MM,0,DATEADD(DD,-DAY(GETDATE())+6,GETDATE())))


/****************************************************	 ESTRUTURA PARA PEGAR O CONSOLIDADO DA FOTOGRAFIA	****************************************************/

DELETE FROM DATA_SCIENCE.DBO.ESTOQUE_ORIGINAL_07
WHERE DT_INFO != @DATA

-- VALIDA O HOR�RIO DA JOB
IF (DATEPART(HH,GETDATE())) IN (6,7)
	BEGIN
		INSERT INTO   DATA_SCIENCE.DBO.ESTOQUE_ORIGINAL_07
		SELECT * FROM DATA_SCIENCE.DBO.ESTOQUE_ORIGINAL_D0
	END
