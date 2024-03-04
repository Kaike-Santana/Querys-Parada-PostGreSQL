
USE [DATA_SCIENCE]
GO

DECLARE @D1 DATETIME		=	 CONCAT('2022-05-21',' 00:00:00.000')   
DECLARE @D2 DATETIME		=	 CONCAT('2022-05-26',' 23:59:59.599')
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: ETL DOS ACIONAMENTOS																*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DROP TABLE IF EXISTS #HIST
SELECT DISTINCT
	IDAND_AND
,	CGCPF_DEV
,	IDCON_AND  
,				CASE 
					WHEN IMAPS_OCO IN ('ACAO','ALO','CPC_N','CPC_P','DISCADOR','EMAIL','MALA','SMS','URA') THEN 1 
					WHEN IDOCO_AND = 67																	   THEN 1 
																										   ELSE 0 
				END AS TENTATIVA	
,				CASE 
					 WHEN IMAPS_OCO IN ('CPC_P','ALO','CPC_N') THEN 1 
					 WHEN IDOCO_AND = 67					   THEN 1 
															   ELSE 0 
				END AS ALO  
,				CASE WHEN IMAPS_OCO IN ('CPC_N') THEN 1 ELSE 0 END AS CPC_N
,				CASE WHEN IMAPS_OCO IN ('CPC_P') THEN 1 
					 WHEN IDOCO_AND = 67		 THEN 1 
												 ELSE 0 
				END AS CPC_P 
,				CASE WHEN IDOCO_AND = 67 THEN 1 ELSE 0 END AS PROMESSA  
INTO #HIST  
FROM [10.251.1.36].NECTAR.DBO.TB_ANDAMENTO		WITH(NOLOCK)  
JOIN [10.251.1.36].NECTAR.DBO.TB_OCORRENCIA		WITH(NOLOCK)  ON IDOCO_AND = IDOCO_OCO  
JOIN [10.251.1.36].NECTAR.DBO.TB_CONTRATO		WITH(NOLOCK)  ON IDCON_AND = IDCON_CON
JOIN [10.251.1.36].[NECTAR].[DBO].[TB_DEVEDOR]	WITH (NOLOCK) ON IDDEV_CON = IDDEV_DEV    
WHERE IDEMP_CON IN (3,5,6,19)  
AND DTAND_AND BETWEEN @D1 AND @D2  
AND 
	(CASE 
		WHEN IMAPS_OCO IN ('ACAO','ALO','CPC_N','CPC_P','DISCADOR','EMAIL','MALA','SMS','URA') THEN 1 
		WHEN IDOCO_AND = 67 THEN 1 
							ELSE 0 
	 END) = 1  
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: CARTEIRA																			*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DROP TABLE IF EXISTS #CARTEIRA
SELECT
CASE    
	WHEN MAX(DIAS_ATRASO) BETWEEN 31 AND 60   THEN '0031 A 0060'
	WHEN MAX(DIAS_ATRASO) BETWEEN 61 AND 90   THEN '0061 A 0090'
	WHEN MAX(DIAS_ATRASO) BETWEEN 91 AND 120  THEN '0091 A 0120'
	WHEN MAX(DIAS_ATRASO) BETWEEN 121 AND 150 THEN '0121 A 0150'
	WHEN MAX(DIAS_ATRASO) BETWEEN 151 AND 180 THEN '0151 A 0180'
END
	FAIXA,
 CPF_CNPJ,
 CONTRATO,
 ID_CONTRATO,
 ELEGIBILIDADE
INTO #CARTEIRA  
FROM DATA_SCIENCE.DBO.ESTOQUE_RCHLO_ANALITICO_MES   
WHERE DT_INFO BETWEEN CONVERT(DATE,@D1) AND CONVERT(DATE,@D2)
GROUP BY CPF_CNPJ,CONTRATO,ID_CONTRATO,ELEGIBILIDADE
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: CARTEIRA																			*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DROP TABLE IF EXISTS #CARTEIRA_JOIN 
SELECT 
	A.FAIXA
,	COUNT(DISTINCT A.CONTRATO) CARTEIRA
,	COUNT(DISTINCT CASE WHEN ELEGIBILIDADE = 1 THEN A.CONTRATO END) CARTEIRA_ELEGIVEL
,	COUNT(DISTINCT A.CPF_CNPJ) CARTEIRA_U
,	COUNT(DISTINCT CASE WHEN ELEGIBILIDADE = 1 THEN A.CPF_CNPJ END) CARTEIRA_ELEGIVEL_U
,	SUM(TENTATIVA)	TENTATIVA
,	SUM(ALO)		ALO
,	SUM(CPC_N)		CPC_N
,	SUM(CPC_P)		CPC_P
,	SUM(PROMESSA)	PROMESSA 
,	COUNT(DISTINCT CASE WHEN TENTATIVA = 1	THEN B.CGCPF_DEV END)   TENTATIVA_U
,	COUNT(DISTINCT CASE WHEN ALO	   = 1	THEN B.CGCPF_DEV END)	ALO_U
,	COUNT(DISTINCT CASE WHEN CPC_N     = 1	THEN B.CGCPF_DEV END)	CPC_N_U
,	COUNT(DISTINCT CASE WHEN CPC_P     = 1	THEN B.CGCPF_DEV END)	CPC_P_U
,	COUNT(DISTINCT CASE WHEN PROMESSA  = 1	THEN B.CGCPF_DEV END)   PROMESSA_U
INTO #CARTEIRA_JOIN
FROM #CARTEIRA A JOIN #HIST B ON ID_CONTRATO = IDCON_AND
WHERE A.FAIXA IS NOT NULL
GROUP BY A.FAIXA
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: PAGAMENTOS EFETIVIDADE															*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 
DROP TABLE IF EXISTS #PRE_PAGAMENTO
SELECT *
INTO #PRE_PAGAMENTO
FROM (
		  SELECT DISTINCT   
		  CGCPF_DEV  
		, IDCON_CON
		, CONTR_CON
		, CASE  
		    WHEN DATEDIFF(DAY,MAX(CONVERT(DATE,DTATR_CON)),CONVERT(DATE,DTACO_ACO)) BETWEEN 31 AND 60    THEN '0031 A 0060' -- SAFIRA  
		    WHEN DATEDIFF(DAY,MAX(CONVERT(DATE,DTATR_CON)),CONVERT(DATE,DTACO_ACO)) BETWEEN 61 AND 90    THEN '0061 A 0090' -- SAFIRA  
		    WHEN DATEDIFF(DAY,MAX(CONVERT(DATE,DTATR_CON)),CONVERT(DATE,DTACO_ACO)) BETWEEN 91 AND 120   THEN '0091 A 0120' -- ESMERALDA  
			WHEN DATEDIFF(DAY,MAX(CONVERT(DATE,DTATR_CON)),CONVERT(DATE,DTACO_ACO)) BETWEEN 121 AND 150  THEN '0121 A 0150' -- ESMERALDA  
			WHEN DATEDIFF(DAY,MAX(CONVERT(DATE,DTATR_CON)),CONVERT(DATE,DTACO_ACO)) BETWEEN 151  AND 180 THEN '0151 A 0180' -- RUBI  
		    ELSE '' END ATRASO    
		, CONVERT(MONEY, VLPAG_PAG) AS VALOR_PAGO  
		, CONVERT (DATE,DTPAG_PAG) AS DATA_PGTO
		, CONVERT(DATE,DTVEN_PAG)  AS DATA_VENC
		, CAST(NULL AS NUMERIC) AS TESTE
		FROM	  [10.251.1.36].NECTAR.DBO.TB_CONTRATO     WITH(NOLOCK)   
		JOIN	  [10.251.1.36].NECTAR.DBO.TB_ACORDO       WITH(NOLOCK) ON IDCON_CON = IDCON_ACO  
		JOIN	  [10.251.1.36].NECTAR.DBO.TB_PAGAMENTO    WITH(NOLOCK) ON IDACO_ACO = IDACO_PAG  
		JOIN	  [10.251.1.36].NECTAR.DBO.TB_DEVEDOR      WITH(NOLOCK) ON IDDEV_CON = IDDEV_DEV  
		LEFT JOIN [10.251.1.36].NECTAR.DBO.TB_PESSOAL	   WITH(NOLOCK) ON IDPES_ACO = IDPES_PES  
		LEFT JOIN DATA_SCIENCE..OPERADORES								ON IDPES_ACO = IDPES  
		WHERE IDEMP_CON IN (3,5,6,19)  
		AND DTVEN_PAG BETWEEN @D1 AND @D2
		AND PAGAM_PAG = 1  
		AND IIF(CAST(DTVEN_PAG AS DATE) <= CONVERT(DATE,GETDATE()), 'USAR', 'NAO') != 'NAO'
		GROUP BY   
		CGCPF_DEV  
		, IDCON_CON  
		, SCORE_CON   
		, CONVERT(DATE,  DTPAG_PAG)  
		, CONVERT(MONEY, VLPAG_PAG)   
		, CONVERT(DATE,  DTACO_ACO)
		, CONVERT(DATE,  DTVEN_PAG)
		, CONTR_CON ) X  
WHERE ATRASO <> '' 
AND DATA_PGTO IS NOT NULL
/******************************************************************************************************/	
UPDATE #PRE_PAGAMENTO
SET TESTE	=	Y.SALDO_CONTABIL

FROM #PRE_PAGAMENTO X JOIN REPORTS.DBO.TB_SAVE_RIACHUELO_ULTIMA Y ON Y.CHAVE_CYBER = X.CONTR_CON
WHERE X.ATRASO != ''
AND X.DATA_PGTO IS NOT NULL
/******************************************************************************************************/
DROP TABLE IF EXISTS #SALDO_ATUALIZADO
SELECT 
		*
,		VALIDA	=	IIF(VALOR_PAGO < CONVERT(MONEY,TESTE), CONVERT(MONEY,TESTE), VALOR_PAGO)
INTO #SALDO_ATUALIZADO
FROM #PRE_PAGAMENTO
/******************************************************************************************************/
DROP TABLE IF EXISTS #PAGAMENTO_JOIN
SELECT   
	COUNT(DISTINCT IDCON_CON) PAGTO_U,  
	COUNT(DISTINCT IDCON_CON) PAGTO, 
	SUM(VALIDA) VALOR_PAGO,
	ATRASO
INTO #PAGAMENTO_JOIN
FROM #SALDO_ATUALIZADO
WHERE ATRASO <> '' 
AND DATA_PGTO IS NOT NULL
GROUP BY ATRASO 
/******************************************************************************************************/
SELECT 
	 FAIXA
,	 CARTEIRA		=	C.CARTEIRA
,	 MAILING		=	C.CARTEIRA
,	 DISCADO		=	C.TENTATIVA
,	 ALO			=	C.ALO
,	 CPC			=	C.CPC_N + CPC_P
,	 PROMESSA		=	C.PROMESSA
--,	 CONVERSAO		=	CONCAT(LEFT(ROUND(((CAST(PROMESSA AS DECIMAL) * 100) / (CAST(C.CPC_N + CPC_P AS DECIMAL))),2),5), ' %')
,	 PG.PAGTO	 
,	 PG.VALOR_PAGO
--,	 EFETIVIDADE	=	CONCAT(LEFT(ROUND(((CAST(PG.PAGTO AS DECIMAL) * 100) / (CAST(PROMESSA AS DECIMAL))),2),5), ' %')
FROM #CARTEIRA_JOIN C LEFT JOIN #PAGAMENTO_JOIN PG ON PG. ATRASO = C.FAIXA
ORDER BY FAIXA ASC
/******************************************************************************************************/
-- UNIQUE
SELECT 
	 FAIXA
,	 CARTEIRA		=	C.CARTEIRA
,	 MAILING		=	C.CARTEIRA
,	 DISCADO		=	C.TENTATIVA_U
,	 ALO			=	C.ALO_U
,	 CPC			=	C.CPC_N_U + CPC_P_U
,	 PROMESSA		=	C.PROMESSA_U
--,	 CONVERSAO		=	--''--CONCAT(LEFT(ROUND(((CAST(PROMESSA_U AS DECIMAL) * 100) / (CAST(C.CPC_N_U + CPC_P_U AS DECIMAL))),2),5), ' %')
,	 PG.PAGTO	 
,	 PG.VALOR_PAGO
--,	 EFETIVIDADE	=	--''--CONCAT(LEFT(ROUND(((CAST(PG.PAGTO AS DECIMAL) * 100) / (CAST(PROMESSA_U AS DECIMAL))),2),5), ' %')
FROM #CARTEIRA_JOIN C
LEFT JOIN #PAGAMENTO_JOIN PG ON PG. ATRASO = C.FAIXA
ORDER BY FAIXA ASC
