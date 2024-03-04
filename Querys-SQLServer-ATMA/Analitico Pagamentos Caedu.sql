
DECLARE @D1 VARCHAR(40)			=   CONCAT(CONVERT(DATE,GETDATE()-27), ' 00:00:00.000')
DECLARE @D2 VARCHAR(40)			=   CONCAT(CONVERT(DATE,GETDATE()-1), ' 23:59:59.599')

SELECT 
		  CONVERT(DATE,DTPAG_PAG)   AS DATA_PGTO
		, CONVERT(DATE,DTVEN_PAG)   AS DATA_VENC
		, CONVERT(MONEY,VLPAG_PAG)  AS VALOR_PAGO 
		, CGCPF_DEV					AS CPF_DEV
		, IDCON_CON					AS ID_CRM
		,	CASE  
				WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTACO_ACO)) BETWEEN 72   AND 96    THEN  '0072 � 0096'
				WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTACO_ACO)) BETWEEN 97   AND 120   THEN  '0097 � 0120'
				WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTACO_ACO)) BETWEEN 121  AND 150   THEN  '0121 � 0150'
				WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTACO_ACO)) BETWEEN 151  AND 180   THEN  '0151 � 0180'
				WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTACO_ACO)) BETWEEN 181  AND 210   THEN  '0181 � 0210'
				WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTACO_ACO)) BETWEEN 211  AND 360   THEN  '0211 � 0360'
				WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTACO_ACO)) BETWEEN 361  AND 540   THEN  '0361 � 0540'
				WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTACO_ACO)) BETWEEN 541  AND 720   THEN  '0541 � 0720'
				WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTACO_ACO)) BETWEEN 721  AND 1000  THEN  '0721 � 1000'
				WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTACO_ACO)) BETWEEN 1001 AND 1200  THEN  '1001 � 1200'
				WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTACO_ACO)) BETWEEN 1201 AND 1400  THEN  '1201 � 1400'
				WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTACO_ACO)) BETWEEN 1401 AND 1600  THEN  '1401 � 1600'
				WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTACO_ACO)) BETWEEN 1601 AND 1825  THEN  '1601 � 1825'
				WHEN DATEDIFF(DAY,CONVERT(DATE,DTATR_CON),CONVERT(DATE,DTACO_ACO)) BETWEEN 1826 AND 99999 THEN  '1826 � 9999'
				ELSE 'A VENCER'
			END ATRASO    
		FROM [10.251.1.36].NECTAR.DBO.TB_CONTRATO     
		JOIN [10.251.1.36].NECTAR.DBO.TB_ACORDO     ON IDCON_CON = IDCON_ACO  
		JOIN [10.251.1.36].NECTAR.DBO.TB_PAGAMENTO  ON IDACO_ACO = IDACO_PAG  
		JOIN [10.251.1.36].NECTAR.DBO.TB_DEVEDOR    ON IDDEV_CON = IDDEV_DEV 
		WHERE IDEMP_CON = 4 
		AND DTVEN_PAG BETWEEN @D1 AND @D2
		AND PAGAM_PAG = 1