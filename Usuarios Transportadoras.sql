
drop table [Usuarios_Transportadoras]
SELECT [CODIUSER]
      ,[ID_TRANSPORTADORA]
      ,[incl_data]
      ,[incl_user]
      ,[incl_device]
      ,[modi_data]
      ,[modi_user]
      ,[modi_device]
      ,[excl_data]
      ,[excl_user]
      ,[excl_device]
  into [THESYS_homologacao].[dbo].[Usuarios_Transportadoras]
  FROM [THESYS_DEV].[dbo].[Usuarios_Transportadoras]