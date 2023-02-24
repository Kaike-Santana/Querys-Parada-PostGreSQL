

/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: NESSA TABELA CONSEGUE A IDADE DO CLIENTE E A REGI�O								*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

SELECT TOP 10*
FROM [10.251.1.36].[NECTAR].[dbo].TB_DEVEDOR  WITH(NOLOCK)


/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: VARI�VEIS DO C�DIGO																*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/  
  
DECLARE @D1 DATE = '2021-09-08'         
DECLARE @D2 DATE = '2021-09-10'               
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: ANALITICO DE DISPAROS																*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/   
IF OBJECT_ID ('tempdb.dbo.#DISPAROS') IS NOT NULL DROP TABLE #DISPAROS  
SELECT  
 CONVERT(DATE,DTAND_AND)[DTAND_AND],  
 IMAPS_OCO,  
CASE   
 WHEN IMAPS_OCO = 'SMS' THEN 'SMS'  
 WHEN IMAPS_OCO = 'URA' THEN 'URA'     
 WHEN IMAPS_OCO IN ('EMAIL','MALA') THEN 'EMAIL'  
 WHEN (CASE WHEN USUAR_PES IN ('wilsonr','Whatsr')  THEN 'DIGITAL' END) = 'DIGITAL'  THEN 'DIGITAL'     
 WHEN (CASE WHEN SETOR = 'DIGITAL' THEN 'WHATSAPP' END) = 'WHATSAPP' THEN 'WHATSAPP'  ELSE ''  
END   
 [PESO],  
 IDAND_AND,  
 IDCON_AND,  
 CGCPF_DEV,  
CASE  
 WHEN DATEDIFF(DAY,MIN(CONVERT(DATE,DTATR_CON)),CONVERT(DATE,DTAND_AND)) < 0      THEN 'A VENCER'   
 WHEN DATEDIFF(DAY,MIN(CONVERT(DATE,DTATR_CON)),CONVERT(DATE,DTAND_AND)) BETWEEN 6 AND 30  THEN 'RUBI'   
 WHEN DATEDIFF(DAY,MIN(CONVERT(DATE,DTATR_CON)),CONVERT(DATE,DTAND_AND)) BETWEEN 31 AND 90  THEN 'SAFIRA'   
 WHEN DATEDIFF(DAY,MIN(CONVERT(DATE,DTATR_CON)),CONVERT(DATE,DTAND_AND)) BETWEEN 91 AND 180  THEN 'ESMERALDA'   
 WHEN DATEDIFF(DAY,MIN(CONVERT(DATE,DTATR_CON)),CONVERT(DATE,DTAND_AND)) BETWEEN 181 AND 360  THEN 'DIAMANTE'   
 WHEN DATEDIFF(DAY,MIN(CONVERT(DATE,DTATR_CON)),CONVERT(DATE,DTAND_AND)) BETWEEN 361 AND 1080 THEN 'OURO'   
 WHEN DATEDIFF(DAY,MIN(CONVERT(DATE,DTATR_CON)),CONVERT(DATE,DTAND_AND)) BETWEEN 1081 AND 1800 THEN 'PRATA'   
 WHEN DATEDIFF(DAY,MIN(CONVERT(DATE,DTATR_CON)),CONVERT(DATE,DTAND_AND)) > 1800     THEN 'BRONZE'   
END   
 [LIGA],  
MAX(  
CASE   
 WHEN DESCR_DOC LIKE '%PL%'  THEN 1  
 WHEN DESCR_DOC LIKE '%MASTER%' THEN 2  
 WHEN DESCR_DOC LIKE '%VISA%' THEN 3  
 WHEN DESCR_DOC LIKE '%EMP%'  THEN 4  
 WHEN DESCR_DOC LIKE '%SAQ%'  THEN 5  
 WHEN DESCR_DOC LIKE '%SALDO%' THEN 0       
END)   
 [PRODUTO]  
INTO   
 #DISPAROS  
FROM    
   [10.251.0.13].[NECTAR].[dbo].TB_ANDAMENTO A WITH(NOLOCK)  
INNER JOIN  [10.251.1.36].[NECTAR].[dbo].TB_CONTRATO B WITH(NOLOCK) ON B.IDCON_CON = IDCON_AND  
INNER JOIN  [10.251.1.36].[NECTAR].[dbo].TB_DEVEDOR  WITH(NOLOCK) ON IDDEV_DEV = IDDEV_CON  
INNER JOIN  [10.251.1.36].[NECTAR].[dbo].TB_OCORRENCIA WITH(NOLOCK) ON IDOCO_OCO = IDOCO_AND   
INNER JOIN  [10.251.1.36].[NECTAR].[dbo].TB_TRANSACAO WITH(NOLOCK) ON IDCON_TRA = IDCON_CON  
INNER JOIN  [10.251.1.36].[NECTAR].[dbo].TB_DOCUMENTO WITH(NOLOCK) ON IDDOC_DOC = IDDOC_TRA  
LEFT JOIN   [10.251.1.36].[NECTAR].[dbo].TB_PESSOAL WITH(NOLOCK) ON IDPES_PES = IDPES_AND    
LEFT JOIN   DATA_SCIENCE.DBO.OPERADORES WITH(NOLOCK) ON IDPES = IDPES_AND AND SETOR = 'DIGITAL'   
WHERE   
 IDEMP_CON IN (3,5,6)   
AND   
 CONVERT(DATE,DTAND_AND) BETWEEN @D1 AND @D2  
AND   
 CASE WHEN IMAPS_OCO = 'SMS' THEN 1 WHEN IMAPS_OCO = 'URA' THEN 1 WHEN IMAPS_OCO IN ('EMAIL','MALA') THEN 1 WHEN USUAR_PES IN ('wilsonr','Whatsr') THEN 1 WHEN SETOR = 'DIGITAL' THEN 1 ELSE 0 END = 1  
GROUP BY   
CONVERT(DATE,DTAND_AND),IMAPS_OCO,IDAND_AND,IDCON_AND,CGCPF_DEV,  
CASE   
 WHEN IMAPS_OCO = 'SMS' THEN 'SMS'  
 WHEN IMAPS_OCO = 'URA' THEN 'URA'     
 WHEN IMAPS_OCO IN ('EMAIL','MALA') THEN 'EMAIL'  
 WHEN (CASE WHEN USUAR_PES IN ('wilsonr','Whatsr')  THEN 'DIGITAL' END) = 'DIGITAL'  THEN 'DIGITAL'     
 WHEN (CASE WHEN SETOR = 'DIGITAL' THEN 'WHATSAPP' END) = 'WHATSAPP' THEN 'WHATSAPP'  ELSE ''  
END   
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: RETORNO DAS A��ES																	*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/  
IF OBJECT_ID ('tempdb.dbo.#RETORNO') IS NOT NULL DROP TABLE #RETORNO  
  
SELECT DISTINCT   
 DTAND_AND AS DATA,  
 IDCON_AND AS IDCON,  
 CGCPF_DEV AS CGCPF,  
 CASE WHEN IMAPS_OCO IN ('ALO','CPC_N','CPC_P') THEN 1 ELSE 0 END [ALO],  
 CASE WHEN IMAPS_OCO IN ('CPC_N','CPC_P') THEN 1 ELSE 0 END [CPC],  
 CASE WHEN IMAPS_OCO IN ('CPC_P') THEN 1 ELSE 0 END [CPC_P],  
 CASE WHEN IDOCO_AND IN ('67') THEN  1 ELSE 0 END [ACORDO]  
INTO   
 #RETORNO  
FROM    
 [10.251.0.13].[NECTAR].[dbo].TB_ANDAMENTO   
INNER JOIN  [10.251.1.36].[NECTAR].[dbo].TB_CONTRATO ON IDCON_CON = IDCON_AND   
INNER JOIN  [10.251.1.36].[NECTAR].[dbo].TB_OCORRENCIA ON IDOCO_OCO = IDOCO_AND   
INNER JOIN  [10.251.1.36].[NECTAR].[dbo].TB_DEVEDOR ON IDDEV_DEV = IDDEV_CON  
WHERE   
 CASE WHEN IMAPS_OCO IN ('ALO','CPC_N','CPC_P') THEN 1 WHEN IDOCO_AND = '67' THEN 1 ELSE 0 END  = 1  
AND   
 IDEMP_CON IN (3,5,6)   
AND   
 ORIGE_AND = 1   
AND   
 CONVERT(DATE,DTAND_AND) BETWEEN @D1 AND @D2 
 /*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: FUNIL SOBRE RETORNO DAS A��ES														*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/  
  
IF OBJECT_ID ('tempdb.dbo.#ACIONAMENTO') IS NOT NULL DROP TABLE #ACIONAMENTO  
  
SELECT DISTINCT   
 A.*,  
 ISNULL(ALO,0) AS ALO,  
 ISNULL(CPC,0) AS CPC,  
 ISNULL(CPC_P,0) AS CPC_P,  
 ISNULL(ACORDO,0) AS ACORDO
INTO    
 #ACIONAMENTO  
FROM   
 #DISPAROS A     
LEFT JOIN (SELECT DISTINCT DATA,CGCPF,ALO,CPC,CPC_P,ACORDO,PESO FROM #RETORNO A  
INNER JOIN (SELECT DISTINCT DTAND_AND,CGCPF_DEV,MAX(PESO) AS PESO FROM #DISPAROS   
GROUP BY DTAND_AND,CGCPF_DEV) B ON B.DTAND_AND = CONVERT(DATE,A.DATA) AND B.CGCPF_DEV = A.CGCPF  
)B ON CONVERT(DATE,B.DATA) = A.DTAND_AND AND B.CGCPF = A.CGCPF_DEV AND B.PESO = A.PESO  
  
---> FUNIL  
  
SELECT DISTINCT  
 B.LIGA,  
 B.PESO AS A��O,  
 SUM(B.DISPAROS) AS REALIZADOS,  
 SUM(B.CPC) RETORNO,  
 SUM(B.ACORDO) AS ACORDO  
INTO  
 #FINAL  
FROM   
 (SELECT DISTINCT   
LIGA,  
CGCPF_DEV,   
PESO,  
COUNT(DISTINCT IDAND_AND) AS DISPAROS,  
CASE WHEN SUM(ALO) > 0 THEN 1 ELSE 0 END [ALO],  
CASE WHEN SUM(CPC) > 0 THEN 1 ELSE 0 END [CPC],  
CASE WHEN SUM(CPC_P) > 0 THEN 1 ELSE 0 END [CPCP],  
CASE WHEN SUM(ACORDO) > 0 THEN 1 ELSE 0 END [ACORDO]       
FROM   
 #ACIONAMENTO A   
WHERE   
 A.LIGA IN ('ESMERALDA','SAFIRA')  
GROUP BY   
 CGCPF_DEV,LIGA,PESO)B   
GROUP BY  
 B.LIGA,B.PESO
  
  
SELECT * FROM #FINAL   
  