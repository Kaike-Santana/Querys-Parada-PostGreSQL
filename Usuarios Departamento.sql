
DROP TABLE [THESYS_HOMOLOGACAO].[dbo].[Usuarios_Departamentos]
SELECT 
	   [id_departamento]
      ,[nome]
      ,[incl_data]
      ,[incl_user]
      ,[incl_device]
      ,[modi_data]
      ,[modi_user]
      ,[modi_device]
      ,[excl_data]
      ,[excl_user]
      ,[excl_device]
into [THESYS_HOMOLOGACAO].[dbo].[Usuarios_Departamentos]
  FROM [THESYS_DEV].[dbo].[Usuarios_Departamentos]