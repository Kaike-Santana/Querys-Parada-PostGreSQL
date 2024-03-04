

--USE Data_Science
--GO

--CREATE PROCEDURE Rodar_Perfil_Cliente_Renner
--AS BEGIN

	DECLARE @D1 VARCHAR(30)				=	CONCAT('2022-05-01', ' 00:00:00.000')
	DECLARE @D2 VARCHAR(30)				=	CONCAT(CONVERT(DATE,GETDATE()-1), ' 23:59:59.599')
	DECLARE @IP VARCHAR(13)				=	'[10.251.1.36]'
	DECLARE @VAZIO VARCHAR(10)			=   ''
	DECLARE @TSQL NVARCHAR(4000)
	DECLARE @DATA_CONTROLE DATE			=	CAST(@D1 AS DATE)
	DECLARE @ID_CARTEIRA VARCHAR(MAX)	=	'17'

/*				BASE DA RENNER NA ATMA				*/
DROP TABLE IF EXISTS ##BASE_RENNER
SET @TSQL = 'SELECT * INTO ##BASE_RENNER FROM OPENQUERY('+@IP+',''
 SELECT 
	IDCON_CON
,	CONTR_CON
,	DTATR_CON	
,	CGCPF_DEV
,	PRODUTO				=	CASE 	
							WHEN DESCR_BND IN (''''CBRCARNE'''',''''CBRCREL'''',''''MASTER'''',''''VISA'''')						THEN ''''CBR''''
							WHEN DESCR_BND IN (''''PLFATURA'''',''''CCRCFI'''',''''RCCRCFI'''',''''FACRELI'''',''''RFACRELI'''')	THEN ''''CCR''''
							WHEN DESCR_BND IN (''''REPCFI'''',''''EPCFI'''')														THEN ''''EP''''
							ELSE ''''VERIFICAR''''		
							END	
,	DTNAS_DEV
,	GENERO_DEV
,	NOME_DEV
,	VLSAL_CON
FROM	  NECTAR.DBO.TB_CONTRATO 	WITH(NOLOCK) 
JOIN	  NECTAR.DBO.TB_DEVEDOR		WITH(NOLOCK) ON IDDEV_DEV = IDDEV_CON
LEFT JOIN NECTAR.DBO.TB_BANDEIRA	WITH(NOLOCK) ON IDBND_BND = IDBND_CON 
WHERE IDEMP_CON = '''''+@ID_CARTEIRA+'''''
AND STDEV_CON = 0 '')'
EXEC (@TSQL)

/*				BASE DA RENNER NA ATMA				*/
DROP TABLE IF EXISTS ETL_BASE
SELECT DISTINCT
	NOME		=		NOME_DEV
,	CPF			=		CGCPF_DEV
,	PRODUTO		
,	ATRASO		=		DATEDIFF(DAY,DTATR_CON,GETDATE())
,	IDADE		=		DATEDIFF(YEAR,DTNAS_DEV,GETDATE())
,	VLSAL_CON
,CASE WHEN DATEDIFF(YEAR,DTNAS_DEV,GETDATE()) <1												THEN 'A VENCER'
		 WHEN DATEDIFF(YEAR,DTNAS_DEV,GETDATE()) BETWEEN		15		AND		25				THEN '15 A 25'
		 WHEN DATEDIFF(YEAR,DTNAS_DEV,GETDATE()) BETWEEN		26		AND		35				THEN '26 A 35'
		 WHEN DATEDIFF(YEAR,DTNAS_DEV,GETDATE()) BETWEEN		36		AND		45				THEN '36 A 45'
		 WHEN DATEDIFF(YEAR,DTNAS_DEV,GETDATE()) BETWEEN		46		AND		55				THEN '46 A 55'
		 WHEN DATEDIFF(YEAR,DTNAS_DEV,GETDATE()) BETWEEN		56		AND		60				THEN '56 A 60'
		 WHEN DATEDIFF(YEAR,DTNAS_DEV,GETDATE()) > 61											THEN '>61'
ELSE 'VERIFICAR'
	END AS 'FAIXA_IDADE'
,CASE WHEN DATEDIFF(day,DTATR_CON,GETDATE()) <0											THEN 'A VENCER'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		0		AND		15				THEN	'0 A 15'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		16		AND		30				THEN	'16 A 30'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		31		AND		60				THEN	'31 A 60'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		61		AND		90				THEN	'61 A 90'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		91		AND		120				THEN	'91 A 120'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		121		AND		150				THEN	'121 A 150'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		151		AND		180				THEN	'151 A 180'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		181		AND		210				THEN	'181 A 210'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		211		AND		240				THEN	'211 A 240'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		241		AND		270				THEN	'241 A 270'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		271		AND		300				THEN	'271 A 300'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		301		AND		330				THEN	'301 A 330'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		331		AND		360				THEN	'331 A 360'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		361		AND		720				THEN	'361 A 720'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		721		AND		1080			THEN	'721 A 1080'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		1081	AND		1440			THEN	'1081 A 1440'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) BETWEEN		1441	AND		1800			THEN	'1441 A 1800'
		 WHEN DATEDIFF(day,DTATR_CON,GETDATE()) >1800										THEN	'1801 A 9999'
ELSE 'VERIFICAR'
	END AS 'FAIXA_ATRASO'
,	UF			=		ESTAD_ETD
,	ESTADO		=		DESCR_ETD	
,	SEXO		=		CASE 
							WHEN GENERO_DEV = 2		THEN 'FEMININO'
							WHEN GENERO_DEV = 1		THEN 'MASCULINO'
							WHEN GENERO_DEV = 0		THEN 'ND'
							WHEN GENERO_DEV IS NULL THEN 'ND'
							ELSE 'VERIFICAR'
						END

INTO ETL_BASE
FROM ##BASE_RENNER X
INNER JOIN	[10.251.1.36].[NECTAR].[dbo].[TB_ENDERECO]	WITH(NOLOCK) ON IDCON_CON  = IDORI_END AND PREFE_END = 1
INNER JOIN  [10.251.1.36].[nectar].[dbo].[TB_ESTADO]	WITH(NOLOCK) ON IDEST_END  = IDEST_ETD 

SELECT 
	PRODUTO
,	ATRASO	
,	UF
,	ESTADO
,	SEXO
,	IDADE
,	FAIXA_ATRASO
,	FAIXA_IDADE
,	BASE			=	COUNT(DISTINCT CPF)	
,	VLSAL_CON
FROM ETL_BASE
GROUP BY 	PRODUTO
,	ATRASO	
,	UF
,	ESTADO
,	SEXO
,	IDADE
,	FAIXA_ATRASO
,	FAIXA_IDADE
,	VLSAL_CON
-- END




