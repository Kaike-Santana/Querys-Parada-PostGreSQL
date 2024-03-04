

USE Planning
GO

DROP TABLE IF EXISTS TBL_BLKLIST_D0_VIAVAREJO
CREATE TABLE TBL_BLKLIST_D0_VIAVAREJO(
--CPF VARCHAR(14) NOT NULL,
TELEFONE VARCHAR(20) NOT NULL
--DATA VARCHAR(14) NOT NULL
)

create nonclustered index sku_telefone on TBL_BLKLIST_D0_VIAVAREJO (telefone)

BULK INSERT TBL_BLKLIST_D0_VIAVAREJO
FROM '\\polaris\NectarServices\Administrativo\Temporario\BADLIST_VVAR_20230814.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ';',
ROWTERMINATOR = '\n'
)
GO



SELECT COUNT(DISTINCT X.TELEFONE)
FROM TBL_BLKLIST_D0_VIAVAREJO X
WHERE NOT EXISTS (
				  SELECT *
				  FROM TB_PLANNING_BLACKLIST_CF_ESTATICA Y
				  WHERE Y.FONE = X.TELEFONE
				 )

