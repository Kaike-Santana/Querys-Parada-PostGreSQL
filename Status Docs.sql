USE THESYS_DEV
GO

INSERT INTO THESYS_PRODUCAO..[Status_Docs]
           ([Codigo]
           ,[StatusDescricao]
           ,[StatusGrupo]
           ,[incl_data]
           ,[incl_user]
           ,[incl_device]
           ,[modi_data]
           ,[modi_user]
           ,[modi_device]
           ,[excl_data]
           ,[excl_user]
           ,[excl_device])
select 
			[Codigo]
           ,[StatusDescricao]
           ,[StatusGrupo]
           ,[incl_data]
           ,[incl_user]
           ,[incl_device]
           ,[modi_data]
           ,[modi_user]
           ,[modi_device]
           ,[excl_data]
           ,[excl_user]
           ,[excl_device]
from [Status_Docs]