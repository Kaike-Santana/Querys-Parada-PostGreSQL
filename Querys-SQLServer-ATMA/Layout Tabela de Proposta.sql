
DROP TABLE IF EXISTS #PROPOSTAS
SELECT 
  DTCAD_PRO
, DTVEN_PRO
, IDPRO_PRO
, IMAPS_OCO		=	NULL
, CONTR_CON
, DESCR_OCO		=	'Proposta Cadastrada'
, DESCR_DOC		=	NULL
, CGCPF_DEV
, DTATR_CON
, IDEMP_CON
, IDOCO_AND		=	171
, VLSAL_CON
, TELEFONE		=	NULL
, TPTEL_TEL		=	NULL
, VLCOR_PRO
, IDCON_CON
--INTO #PROPOSTAS
FROM [10.251.1.36].[Nectar].[dbo].TB_PROPOST 
JOIN [10.251.1.36].[NECTAR].[DBO].TB_CONTRATO   WITH(NOLOCK) ON IDCON_CON = IDCON_PRO
JOIN [10.251.1.36].[NECTAR].[DBO].TB_EMPRESA    WITH(NOLOCK) ON IDEMP_EMP = IDEMP_CON
JOIN [10.251.1.36].[NECTAR].[DBO].TB_DEVEDOR    WITH(NOLOCK) ON IDDEV_DEV = IDDEV_CON
WHERE IDEMP_EMP = 16


