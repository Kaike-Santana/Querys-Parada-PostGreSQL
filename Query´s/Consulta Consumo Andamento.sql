

USE Nectar
GO

DECLARE @APOCALIPSE DATE = '2022-07-15' 
SELECT 
		DATA		=	CONVERT(DATE,DTAND_AND)
,		TAMANHO		=	COUNT(1)
FROM TB_ANDAMENTO
WHERE CONVERT(DATE,DTAND_AND) >= @APOCALIPSE
GROUP BY CONVERT(DATE,DTAND_AND)
ORDER BY CONVERT(DATE,DTAND_AND) DESC
