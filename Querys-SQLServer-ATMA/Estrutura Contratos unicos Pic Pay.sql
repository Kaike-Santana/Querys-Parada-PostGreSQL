 



	SELECT DISTINCT
				TITUL_TRA
			   ,IDDOC_TRA
			   ,FLAG		=	'TRA'
			    INTO #BASE 
				FROM	   [10.251.1.36].NECTAR.DBO.TB_TRANSACAO WITH(NOLOCK)
				INNER JOIN [10.251.1.36].NECTAR.DBO.TB_CONTRATO  WITH(NOLOCK) ON IDCON_TRA = IDCON_CON AND IDEMP_CON = 18
				UNION ALL
				SELECT DISTINCT
				TITUL_BAI
			   ,IDDOC_BAI
			   ,FLAG		=	'BAI'
				FROM	   [10.251.1.36].NECTAR.DBO.TB_BAIXA	 WITH(NOLOCK)
				INNER JOIN [10.251.1.36].NECTAR.DBO.TB_CONTRATO  WITH(NOLOCK) ON IDCON_BAI = IDCON_CON AND IDEMP_CON = 18

SELECT  X.*
,	Y.PRODUTO_DP
INTO #PRODUTO
FROM #BASE X JOIN TB_DS_ORIGINAL_DEPARA_PRODUTO Y ON Y.IDDOC_DP = X.IDDOC_TRA	 

SELECT *
INTO #KAIKE
FROM  DATA_SCIENCE.DBO.ESTOQUE_PICPAY_MES


UPDATE DATA_SCIENCE.DBO.ESTOQUE_PICPAY_MES
SET PRODUTO		=	 Y.PRODUTO_DP

FROM DATA_SCIENCE.DBO.ESTOQUE_PICPAY_MES K JOIN #PRODUTO Y ON Y.TITUL_TRA = K.CONTRATO
