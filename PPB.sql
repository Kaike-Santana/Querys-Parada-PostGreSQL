USE [THESYS_DEV]
GO

INSERT INTO [THESYS_HOMOLOGACAO]..[PPB]
           ([CODIGO]
           ,[DESCRICAO]
           ,[APLICACAO])

SELECT 
 [CODIGO]
,[DESCRICAO]
,[APLICACAO]
FROM PPB