
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/*																								*/
/* PROGRAMADOR: KAIKE NATAN										                                */
/* VERSAO     : DATA: 04/05/2022																*/
/* DESCRICAO  : CONSULTA PARA REPROCESSAR FOTOGR�FIA DO DIA DAS CARTEIRAS			 		    */
/*																								*/
/*        2. PROGRAMADOR: 													 DATA: __/__/____	*/		
/*           DESCRICAO  :										 								*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	VARI�VEL DO C�DIGO															    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
BEGIN TRANSACTION
DECLARE @CONTADOR_INICIAL INT		=	 1;
DECLARE @ID_CARTEIRA	  INT		=	 16; 
DECLARE @CONTADOR_FINAL	  DATETIME	=	 '2022-02-17 00:00:00:000'--(SELECT CONCAT(MIN(CONVERT(DATE,DTAND_AND)),' 00:00:00:000') FROM [10.251.1.36].NECTAR.DBO.TB_ANDAMENTO WITH(NOLOCK) JOIN [10.251.1.36].NECTAR.DBO.TB_CONTRATO WITH(NOLOCK) ON IDCON_AND = IDCON_CON WHERE IDEMP_CON = @ID_CARTEIRA) 
DECLARE @DATA_FIM		  INT		=	 (SELECT DATEDIFF(DAY,CONVERT(DATE,@CONTADOR_FINAL),CONVERT(DATE,GETDATE())));
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: ESTRUTURA DO PADR�O DA FOROGRAFIA DA CARTEIRA									    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
TRUNCATE TABLE DATA_SCIENCE.DBO.FOTOGRAFIA_TESTE 
WHILE ( @CONTADOR_INICIAL <= @DATA_FIM )
BEGIN
INSERT INTO DATA_SCIENCE.DBO.FOTOGRAFIA_TESTE  
SELECT DISTINCT 
	EMPRESA						=			CASE WHEN IDEMP_CON = 16 THEN 'PRA VALER' END 
,	CGCPF_DEV					=			CGCPF_DEV
,	NOME_DEVEDOR				=			NOME_DEV									 
,	ID_CONTRATO					=			IDCON_CON									 
,	CONTRATO					=			CONTR_CON									 
,	DT_IMPORTACAO				=			CONVERT(DATE,DTINC_CON)						 
,	DT_DEVOLUCAO				=			CONVERT(DATE,DTDEV_CON)						 
,	DT_ATRASO					=			CONVERT(DATE,DTATR_CON)						 
,	FACULDADE					=			DESCR_LOJ									 
,	SEGMENTACAO					=			TB_SEGMENTACAO.DESCR_SEG					 
,	ELEGIBILIDADE				=			ISNULL(SG.ELEGIVEL,1)						 
,	DIAS_ATRASO					=			DATEDIFF(DAY,DTATR_CON,@CONTADOR_FINAL)		 
,	SALDO						=			CONVERT(MONEY,VLSAL_CON)					 
,	VL_ATUALIZADO				=			CONVERT(MONEY,VLATU_CON)					 
,	RATING						=	
											CASE
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) < 0								THEN '5 A 30'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	0 AND 4					THEN '5 A 30'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	5 AND 30				THEN '5 A 30'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	31 AND 60				THEN '31 A 60'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	61 AND 90				THEN '61 A 90'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	91 AND 120				THEN '91 A 120'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	121 AND 150				THEN '121 A 150'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	151 AND 180				THEN '151 A 180'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	181 AND 210				THEN '181 A 210'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	211 AND 240				THEN '211 A 240'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	241 AND 270				THEN '241 A 270'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	271 AND 300				THEN '271 A 300'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	301 AND 330				THEN '301 A 330'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	331 AND 360				THEN '331 A 360'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	361 AND 720				THEN '361 A 720'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	721 AND 1080			THEN '721 A 1080'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	1081 AND 1440			THEN '1081 A 1440'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	1441 AND 1800			THEN '1441 A 1800'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) > 1800								THEN '> 1800'	
											END
,  LIGA							=	
 											CASE																	 
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN -9999 AND 2	THEN 'A VENCER'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	3  AND 60	THEN 'TELE-COBRAN�A'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) BETWEEN	61 AND 360	THEN 'FASE 1'
												WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,@CONTADOR_FINAL)) > 360					THEN 'W.O'
											END 
,	@CONTADOR_FINAL AS DT_INFO
,	DESCR_SIT 
FROM [10.251.1.36].NECTAR.DBO.TB_CONTRATO A
LEFT JOIN  (
			 SELECT DISTINCT IDCON_TRA,VLFAT_TRA,TITUL_TRA,DTFAT_TRA,IDDOC_TRA,CONTA_TRA 
			 FROM [10.251.1.36].NECTAR.DBO.TB_TRANSACAO WITH (NOLOCK)
			 INNER JOIN [10.251.1.36].NECTAR.DBO.TB_CONTRATO WITH (NOLOCK) ON IDCON_CON = IDCON_TRA AND IDEMP_CON = @ID_CARTEIRA
			 
			 UNION ALL 
			 
			 SELECT DISTINCT IDCON_BAI,VLFAT_BAI,TITUL_BAI,DTFAT_BAI,IDDOC_BAI,CONTA_BAI FROM [10.251.1.36].NECTAR.DBO.TB_BAIXA WITH (NOLOCK)
			 INNER JOIN [10.251.1.36].NECTAR.DBO.TB_CONTRATO WITH (NOLOCK) ON IDCON_CON = IDCON_BAI AND IDEMP_CON = @ID_CARTEIRA
			 WHERE IDCON_BAI NOT IN (
			 						 SELECT DISTINCT 
			 						 IDCON_TRA 
			 						 FROM [10.251.1.36].NECTAR.DBO.TB_TRANSACAO WITH (NOLOCK) 
			 						 INNER JOIN [10.251.1.36].NECTAR.DBO.TB_CONTRATO WITH (NOLOCK) ON IDCON_TRA = IDCON_CON AND IDEMP_CON = @ID_CARTEIRA
			 					    )			
			) B ON IDCON_TRA = IDCON_CON
LEFT JOIN [10.251.1.36].NECTAR.DBO.TB_DEVEDOR			WITH(NOLOCK) ON IDDEV_CON    =  IDDEV_DEV
LEFT JOIN [10.251.1.36].NECTAR.DBO.TB_SITUACAO			WITH(NOLOCK) ON IDSIT_SIT	 =  IDSIT_CON
LEFT JOIN [10.251.1.36].NECTAR.DBO.TB_LOJA				WITH(NOLOCK) ON IDLOJ_CON	 =  IDLOJ_LOJ
LEFT JOIN [10.251.1.36].NECTAR.DBO.TB_SEGMENTACAO		WITH(NOLOCK) ON IDSEG_CON    =  IDSEG_SEG
LEFT JOIN [Data_Science].[DBO].[TB_DS_SEGMENTATIONS] SG	WITH(NOLOCK) ON SG.DESCR_SEG =  TB_SEGMENTACAO.DESCR_SEG AND SG.IDEMP = A.IDEMP_CON
WHERE 
	IDEMP_CON  = @ID_CARTEIRA
AND
	CASE WHEN STDEV_CON = 1 AND CONVERT(DATE,DTDEV_CON) >= CONVERT(DATE,@CONTADOR_FINAL) THEN 1 
		 WHEN STDEV_CON = 0 THEN 1 
		 WHEN IDSIT_SIT = 45 AND DTSIT_CON <= @CONTADOR_FINAL THEN 0
	END = 1
AND CONVERT(DATE,DTINC_CON) <= @CONTADOR_FINAL
AND DATEPART(DW,@CONTADOR_FINAL) NOT IN (7,1)

SET @CONTADOR_INICIAL = @CONTADOR_INICIAL + 1
SET @CONTADOR_FINAL   = @CONTADOR_FINAL   + 1

END
COMMIT TRANSACTION;