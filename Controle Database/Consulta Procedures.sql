

SELECT
 SPECIFIC_CATALOG		AS BANCO
,SPECIFIC_NAME			AS [NOME PROCEDURE]
,ROUTINE_DEFINITION		AS CONSULTA
,CREATED				AS CRIA��O
,LAST_ALTERED			AS [ULT. ALTERA��O]
FROM Data_Science.INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_TYPE = 'PROCEDURE'
