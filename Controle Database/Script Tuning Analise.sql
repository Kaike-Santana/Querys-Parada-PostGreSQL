
SET STATISTICS IO ON

SELECT *
FROM TB_DS_CALLFLEX_MES 
WHERE IDCRM = '65051795'

-- 03:27 ANTES DO �NDICE
-- 00:00 DPS DO INDICE

CREATE NONCLUSTERED INDEX IDX_IDCRM ON TB_DS_CALLFLEX_MES (IDCRM);


ALTER TABLE TB_DS_CALLFLEX_MES ALTER COLUMN IDCRM VARCHAR (100);

CREATE NONCLUSTERED INDEX IDX_ID ON TB_DS_FOTOGRAFIA_VELOE_MES (ID_CONTRATO);

EXEC SP_COLUMNS TB_DS_CALLFLEX_MES

