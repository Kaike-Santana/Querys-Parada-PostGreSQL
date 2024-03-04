USE [Data_Science]
GO
/****** Object:  StoredProcedure [dbo].[PRC_HORA_HORA_CAEDU]    Script Date: 20/07/2023 10:54:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/*																								*/
/* PROGRAMADOR: KAIKE NATAN									                                    */
/* VERSAO     : DATA: 17/08/2022																*/
/* DESCRICAO  : RESPONSÁVEL POR ATUALIZAR O HORA HORA DA CAEDU									*/
/*																								*/
/*	ALTERACAO                                                                                   */
/*        2. PROGRAMADOR: KAIKE NATAN										 DATA: 30/08/2022	*/		
/*           DESCRICAO:	ALTERAÇÂO DA FAIXA DE ATRASO E FILTRO PARA SEPARAR ACORDO DE PROMESSA	*/
/*	ALTERACAO                                                                                   */
/*        3. PROGRAMADOR: KAIKE NATAN										 DATA: 31/08/2022	*/		
/*           DESCRICAO:	REESTRUTURAÇÂO COMPLETA PARA VISÂO COM E SEM BOLETAGEM					*/
/*	ALTERACAO                                                                                   */
/*        4. PROGRAMADOR: KAIKE NATAN 										 DATA: 27/10/2022	*/		
/*           DESCRICAO:	AJUSTE DO NOVO DEPARA DE ACORDO CONSIDERADO INTERNAMENTE				*/
/*	ALTERACAO                                                                                   */
/*        5. PROGRAMADOR: 													 DATA: __/__/____	*/		
/*           DESCRICAO:															  				*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
	ALTER PROCEDURE [dbo].[PRC_HORA_HORA_CAEDU] AS
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: VARIAVÉIS DE CONTROLE DO CÓDIGO												    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
BEGIN;
SET NOCOUNT ON;
	DECLARE @D1 VARCHAR(50)				=	CONCAT(CONVERT(DATE,GETDATE()), ' 00:00:01.000')
	DECLARE @D2 VARCHAR(50)				=	CONCAT(CONVERT(DATE,GETDATE()), ' 23:59:59.997')
	DECLARE @IP VARCHAR(13)				=	'[10.251.1.36]'
	DECLARE @VAZIO VARCHAR(10)			=   ''
	DECLARE @TSQL NVARCHAR(4000) 
	DECLARE @DATA_CONTROLE DATE			=	CAST(@D1 AS DATE)
	DECLARE @ID_CARTEIRA VARCHAR(MAX)	=	'4'
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: ANALITICO DE PRODUÇÃO CRM	DA CAEDU												*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DROP TABLE IF EXISTS ##ANALITICO_PRODUCAO_CAEDU
SELECT  @TSQL = 'SELECT * INTO ##ANALITICO_PRODUCAO_CAEDU FROM OPENQUERY('+@IP+',
''SELECT DISTINCT
	DTAND_AND
,	IDAND_AND
,	IDCON_AND
,	IDOCO_AND
,	DTATR_CON
,	IDEMP_CON
,	VLSAL_CON
,	CONTR_CON
,	IDPES_PES  
,	USUAR_PES  
,	NOME_PES  
,	CGCPF_DEV 
,	DESCR_CAR 
FROM NECTAR.DBO.TB_ANDAMENTO  WITH( NOLOCK )	
JOIN NECTAR.DBO.TB_CONTRATO   WITH( NOLOCK ) ON IDCON_AND = IDCON_CON  
JOIN NECTAR.DBO.TB_DEVEDOR	  WITH( NOLOCK ) ON IDDEV_DEV = IDDEV_CON
JOIN NECTAR.DBO.TB_OCORRENCIA WITH( NOLOCK ) ON IDOCO_AND = IDOCO_OCO  
JOIN NECTAR.DBO.TB_PESSOAL	  WITH( NOLOCK ) ON IDPES_AND = IDPES_PES
JOIN NECTAR.DBO.TB_CARTEIRA	  WITH( NOLOCK ) ON IDCAR_CON = IDCAR_CAR
WHERE IDEMP_CON = '''''+@ID_CARTEIRA+'''''
AND IMAPS_OCO != '''''+@VAZIO+'''''
AND ORIGE_AND IN (0,1)
AND DTAND_AND BETWEEN '''''+@D1+''''' AND ''''' +@D2+ '''''
AND IDPES_PES NOT IN (''''973'''',''''2680'''',''''973'''',''''21'''')
'')'
EXEC SP_EXECUTESQL @TSQL
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: BASE DE ACORDOS																	*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DROP TABLE IF EXISTS #UNION_PRODUCAO
SELECT 
		DTAND_AND		=	CONVERT(DATE,DTAND_AND) 
,		DTPAG_PAG		=	CAST(NULL AS DATE)	
,		HRAND_AND		=	DATEPART(HH,DTAND_AND) 
,		IDEMP_EMP		=	IDEMP_CON	
,		IDPES_PES
,		USUAR_PES
,		AGING			=	DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTAND_AND)) 
,		VLSAL_CON		=	CONVERT(MONEY,VLSAL_CON) 
,		VLVEN_PAG		=	CAST(NULL AS MONEY)					 
,		VLPAG_PAG		=	CAST(NULL AS MONEY)	
,		CGCPF_DEV			 
,		CONTR_CON		=	CONTR_CON				 
,		IDCON_CON		=	IDCON_AND				 
,		IDOCO_AND		=	IDOCO_AND
,		DESCR_CAR
,		NOME_PES
INTO #UNION_PRODUCAO
FROM ##ANALITICO_PRODUCAO_CAEDU
WHERE IDOCO_AND NOT IN (2180,67) --> DESCONSIDERA ACORDO E PROMESSA AÇÃO
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: BASE DE PROMESSA PROVENIENTES DE BOLETAGEM --> (PROMESSA BOLETO)					*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DROP TABLE IF EXISTS #UNION_PRODUCAO_PROMESSA_ACAO
SELECT 
		DTAND_AND		=	CONVERT(DATE,DTAND_AND) 
,		DTPAG_PAG		=	CAST(NULL AS DATE)	
,		HRAND_AND		=	DATEPART(HH,DTAND_AND) 
,		IDEMP_EMP		=	IDEMP_CON	
,		IDPES_PES
,		USUAR_PES
,		AGING			=	DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTAND_AND)) 
,		VLSAL_CON		=	CONVERT(MONEY,VLSAL_CON) 
,		VLVEN_PAG		=	CAST(NULL AS MONEY)					 
,		VLPAG_PAG		=	CAST(NULL AS MONEY)	
,		CGCPF_DEV			 
,		CONTR_CON		=	CONTR_CON				 
,		IDCON_CON		=	IDCON_AND				 
,		IDOCO_AND		=	IDOCO_AND
,		DESCR_CAR
,		NOME_PES
INTO #UNION_PRODUCAO_PROMESSA_ACAO
FROM ##ANALITICO_PRODUCAO_CAEDU
WHERE IDOCO_AND = 2180 --> TRAZ SÓ PROMESSA AÇÃO
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: ANALITICO DE ACORDOS DA CAEDU														*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DROP TABLE IF EXISTS ##ANALITICO_ACORDO_CAEDU
SELECT @TSQL =' SELECT * INTO ##ANALITICO_ACORDO_CAEDU FROM OPENQUERY('+@IP+',  
''SELECT DISTINCT
	DTVEN_PAG  
,	DTPAG_PAG  
,	VLVEN_PAG  
,	VLPAG_PAG  
,	PAGAM_PAG  
,	IDACO_ACO 
,	DTCAD_ACO
,	IDPES_ACO    
,	IDCON_ACO
,	VLSAL_CON   
,	IDEMP_CON   
,	USUAR_PES  
,	NOME_PES  
,	CGCPF_DEV 
FROM NECTAR.DBO.TB_ACORDO		    WITH( NOLOCK )
INNER JOIN NECTAR.DBO.TB_CONTRATO	WITH( NOLOCK ) ON IDCON_CON = IDCON_ACO   
INNER JOIN NECTAR.DBO.TB_DEVEDOR	WITH( NOLOCK ) ON IDDEV_DEV = IDDEV_CON  
INNER JOIN NECTAR.DBO.TB_PAGAMENTO	WITH( NOLOCK ) ON IDACO_PAG = IDACO_ACO  
INNER JOIN NECTAR.DBO.TB_CARTEIRA	WITH( NOLOCK ) ON IDCAR_CON = IDCAR_CAR
INNER JOIN NECTAR.DBO.TB_PESSOAL	WITH( NOLOCK ) ON IDPES_PES = IDPES_ACO
WHERE IDEMP_CON = '''''+@ID_CARTEIRA+'''''
AND PAGAM_PAG = 1 
AND DTCAD_ACO BETWEEN '''''+@D1+''''' AND ''''' +@D2+ '''''
AND IDPES_PES  NOT IN (''''973'''',''''2680'''',''''973'''',''''21'''')
'')'
EXEC SP_EXECUTESQL @TSQL  
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: CONSOLIDA AS 2 BASES																*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DROP TABLE IF EXISTS #BASE_CONSOLIDADA
SELECT X.*
,	Y.VLVEN_PAG AS CASH
,	FLAG	=	'ACORDO'	
INTO #BASE_CONSOLIDADA
FROM #UNION_PRODUCAO    X 
LEFT JOIN ##ANALITICO_ACORDO_CAEDU Y ON Y.IDCON_ACO = X.IDCON_CON AND X.DTAND_AND = CONVERT(DATE,Y.DTCAD_ACO) AND IDOCO_AND IN (SELECT IDOCO_DXP FROM REPORTS.DBO.AUX_DEXPARA_ATMA WHERE ACORDO = 1) 

UNION ALL

SELECT X.*
,	Y.VLVEN_PAG AS CASH
,	FLAG	=	'BOLETAGEM'
FROM #UNION_PRODUCAO_PROMESSA_ACAO X 
LEFT JOIN ##ANALITICO_ACORDO_CAEDU Y ON Y.IDCON_ACO = X.IDCON_CON AND X.DTAND_AND = CONVERT(DATE,Y.DTCAD_ACO) AND X.IDOCO_AND = 2180
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: EXPURGA OCORRENCIAS DE ROBO CONFORME SOLICITADO PELO MARCOS						*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DROP TABLE IF EXISTS #DEPARA
SELECT *
INTO #DEPARA
FROM REPORTS.DBO.AUX_DEXPARA_ATMA
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: DEIXA TABULAÇÕES PASSADAS PELO RODIRGO COMO ACORDO								*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
UPDATE #DEPARA
SET ACORDO = 1
FROM #DEPARA
WHERE IDOCO_DXP = 2180
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: DExPARA FINAL DA CAEDU															*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DROP TABLE IF EXISTS #DEPARA_CONSOLIDADO
SELECT 
	A.* 
,	DESCR_DXP
,	TABULADO
,	ALO
,	CPC
,	CPC_N
,	CPC_P
,	ACORDO
INTO #DEPARA_CONSOLIDADO
FROM #BASE_CONSOLIDADA A LEFT JOIN #DEPARA C ON IDOCO_AND = IDOCO_DXP
WHERE TABULADO = 1
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: TABELA ANALITICA DO MODELO APARTANDO PROMESSA DE ACORDO							*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DELETE FROM DATA_SCIENCE.DBO.TEMP_ANALITICO_CAEDU_PROMESSA WHERE DTAND_AND BETWEEN CONVERT(DATE,@D1) AND CONVERT(DATE,@D2)
INSERT INTO DATA_SCIENCE.DBO.TEMP_ANALITICO_CAEDU_PROMESSA
SELECT 
	DTAND_AND
,	DTPAG_PAG
,	HRAND_AND
,	IDEMP_EMP
,	IDPES_PES
,	USUAR_PES
,	AGING
,	VLSAL_CON
,	VLVEN_PAG
,	VLPAG_PAG
,	CGCPF_DEV
,	CONTR_CON
,	IDCON_CON
,	IDOCO_AND
,	DESCR_CAR
,	CASH
,	FLAG
,	DESCR_DXP
,	TABULADO
,	ALO
,	CPC
,	CPC_N
,	CPC_P
,	ACORDO
,	NOME_PES
FROM #DEPARA_CONSOLIDADO
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: LAYOUT FINAL PARA O RELATORIO (SINTETICO)											*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DROP TABLE IF EXISTS #FINAL
SELECT 
	DATA				=			A.DTAND_AND	
,	HORA				=			IIF(LEN(HRAND_AND) < 2, CONCAT('0',CONVERT(VARCHAR(2),HRAND_AND)), CONVERT(VARCHAR(2),HRAND_AND))
,	ALO					=			ISNULL(SUM(IIF(IDOCO_AND != 2180 AND ALO > 0, 1	 ,0  )),0)
,	ALO_PROMESSA		=			ISNULL(SUM(IIF(IDOCO_AND =  2180, 1  ,0  )),0)
,	CPC					=			ISNULL(SUM(IIF(IDOCO_AND != 2180 AND CPC > 0, CPC,0  )),0)								
,	CPC_P				=			ISNULL(SUM(IIF(IDOCO_AND != 2180 AND CPC_P > 0, CPC_P  ,0  )),0)
,	CPC_PROMESSA		=			ISNULL(SUM(IIF(IDOCO_AND = 2180, 1,0)),0)
,	CPC_P_PROMESSA		=			ISNULL(SUM(IIF(IDOCO_AND = 2180, 1,0)),0)
,	PROMESSA_ACAO		=			ISNULL(SUM(IIF(IDOCO_AND = 2180, 1,0)),0)
,	ACORDO				=			ISNULL(SUM(IIF(IDOCO_AND != 2180 AND ACORDO > 0,ACORDO,0)),0)										
,	CASH				=			ISNULL(SUM(IIF(FLAG = 'ACORDO', CASH, 0)),0)
,	CASH_PROMESSA		=			ISNULL(SUM(IIF(FLAG = 'BOLETAGEM', CASH, 0)),0)
,	SALDO				=			SUM(ISNULL(IIF(ACORDO > 0 AND FLAG = 'ACORDO', VLSAL_CON, 0),0))
,	PROMESSA_SALDO		=			ISNULL(SUM(IIF(FLAG = 'BOLETAGEM', VLSAL_CON,0)),0)
,	CLUSTER				=	
									CASE 
										WHEN AGING BETWEEN 72 AND   96    THEN  '0072 À 0096'
										WHEN AGING BETWEEN 97 AND   120   THEN  '0097 À 0120'
										WHEN AGING BETWEEN 121 AND  150   THEN  '0121 À 0150'
										WHEN AGING BETWEEN 151 AND  180   THEN  '0151 À 0180'
										WHEN AGING BETWEEN 181 AND  210   THEN  '0181 À 0210'
										WHEN AGING BETWEEN 211 AND  360   THEN  '0211 À 0360'
										WHEN AGING BETWEEN 361 AND  540   THEN  '0361 À 0540'
										WHEN AGING BETWEEN 541 AND  720   THEN  '0541 À 0720'
										WHEN AGING BETWEEN 721 AND  1000  THEN  '0721 À 1000'
										WHEN AGING BETWEEN 1001 AND 1200  THEN  '1001 À 1200'
										WHEN AGING BETWEEN 1201 AND 1400  THEN  '1201 À 1400'
										WHEN AGING BETWEEN 1401 AND 1600  THEN  '1401 À 1600'
										WHEN AGING BETWEEN 1601 AND 1825  THEN  '1601 À 1825'
										WHEN AGING BETWEEN 1826 AND 99999 THEN  '1826 À 9999'
										ELSE 'A VENCER'
									END												  							
,	ORIGEM				=	
									CASE 
										WHEN C.SETOR   =   'Digital'			    THEN 'DIGITAL'
										WHEN A.USUAR_PES IN ('wilsonr','Whatsr')    THEN 'WILSON'
										WHEN A.USUAR_PES IN ('Admin','facaacordo')  THEN 'PORTAL'
										ELSE 'CALL CENTER'
									END 
INTO #FINAL
FROM #DEPARA_CONSOLIDADO A
LEFT JOIN DATA_SCIENCE..OPERADORES C ON C.IDPES = A.IDPES_PES
GROUP BY
	A.DTAND_AND	
,	IIF(LEN(HRAND_AND) < 2, CONCAT('0',CONVERT(VARCHAR(2),HRAND_AND)), CONVERT(VARCHAR(2),HRAND_AND))					
,	A.DESCR_CAR
,	CASE 
		WHEN AGING BETWEEN 72 AND   96    THEN  '0072 À 0096'
		WHEN AGING BETWEEN 97 AND   120   THEN  '0097 À 0120'
		WHEN AGING BETWEEN 121 AND  150   THEN  '0121 À 0150'
		WHEN AGING BETWEEN 151 AND  180   THEN  '0151 À 0180'
		WHEN AGING BETWEEN 181 AND  210   THEN  '0181 À 0210'
		WHEN AGING BETWEEN 211 AND  360   THEN  '0211 À 0360'
		WHEN AGING BETWEEN 361 AND  540   THEN  '0361 À 0540'
		WHEN AGING BETWEEN 541 AND  720   THEN  '0541 À 0720'
		WHEN AGING BETWEEN 721 AND  1000  THEN  '0721 À 1000'
		WHEN AGING BETWEEN 1001 AND 1200  THEN  '1001 À 1200'
		WHEN AGING BETWEEN 1201 AND 1400  THEN  '1201 À 1400'
		WHEN AGING BETWEEN 1401 AND 1600  THEN  '1401 À 1600'
		WHEN AGING BETWEEN 1601 AND 1825  THEN  '1601 À 1825'
		WHEN AGING BETWEEN 1826 AND 99999 THEN  '1826 À 9999'
		ELSE 'A VENCER'
	END										
,	CASE 
		WHEN C.SETOR   =   'Digital'				THEN 'DIGITAL'
		WHEN A.USUAR_PES IN ('wilsonr','Whatsr')	THEN 'WILSON'
		WHEN A.USUAR_PES IN ('Admin','facaacordo')	THEN 'PORTAL' 	
		ELSE 'CALL CENTER'
	END 
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: LAYOUT FINAL PARA O POWER BI														*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DELETE FROM REPORTS..TB_REL_HORA_HORA_CAEDU WHERE DATA BETWEEN CONVERT(DATE,@D1) AND CONVERT(DATE,@D2)
INSERT INTO REPORTS..TB_REL_HORA_HORA_CAEDU
SELECT * FROM #FINAL

--> INSERE ANALITICO NO EXCEL 
DELETE FROM REPORTS..TB_REL_HORA_HORA_CAEDU_ANALITICO WHERE DTAND_AND BETWEEN CONVERT(DATE,@D1) AND CONVERT(DATE,@D2)
INSERT INTO REPORTS..TB_REL_HORA_HORA_CAEDU_ANALITICO
SELECT 
	DTAND_AND
,	DTPAG_PAG
,	HRAND_AND
,	IDEMP_EMP
,	IDPES_PES
,	USUAR_PES
,	AGING
,	VLSAL_CON
,	VLVEN_PAG
,	VLPAG_PAG
,	CGCPF_DEV
,	CONTR_CON
,	IDCON_CON
,	IDOCO_AND
,	DESCR_CAR
,	CASH
,	FLAG
,	DESCR_DXP
,	TABULADO
,	ALO
,	CPC
,	CPC_N
,	CPC_P
,	ACORDO
FROM #DEPARA_CONSOLIDADO 
WHERE IDOCO_AND != 2180

--> DELETA OQ NÃO FOR DO MÊS ATUAL
--BEGIN;
--	DECLARE @VALIDA_MES INT	 =  (SELECT DATEPART(MM,MIN(DTAND_AND)) FROM REPORTS..TB_REL_HORA_HORA_CAEDU_ANALITICO)	
--	IF (
--		@VALIDA_MES
--	   )
--	   != DATEPART(MM,CONVERT(DATE,GETDATE()))
--	TRUNCATE TABLE REPORTS..TB_REL_HORA_HORA_CAEDU_ANALITICO
--END;

BEGIN;
  DROP TABLE IF EXISTS ##ANALITICO_ACORDO_CAEDU
  DROP TABLE IF EXISTS ##ANALITICO_PRODUCAO_CAEDU
END;


END;