USE DB_REPORT
GO

SELECT
   CARTEIRA ='AVON'
   ,DATEPART(DAY,DATA) AS "POR_DIA"
    ,COUNT(AF) AS "TOTAL DE ACORDOS"
     ,FORMAT(SUM(CAST(at.VL_ENTRADA AS INT)), 'C', 'pt-BR') "CONVERS�O"
	   ---,AVG(VL_ACORDO) AS "MEDIA_VALOR_POR_DIA"
FROM TB_REL_HORA_HORA_TABULACAO_ANALITICO_BACKUP at WITH(NOLOCK)
WHERE ID_CEDENTE = 1
AND DATA >= '2021-06-17' AND DATA <= '2021-06-26'
AND AF = 1
GROUP BY DATA 
       







