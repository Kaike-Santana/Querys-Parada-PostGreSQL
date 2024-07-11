USE [THESYS_DEV]
GO

INSERT INTO THESYS_PRODUCAO..[Estoque_Tipos_Mov]
           ([tipo_mov_cod]
           ,[tipo_mov_descr]
           ,[ativo]
           ,[incl_data]
           ,[incl_user]
           ,[incl_device]
           ,[modi_data]
           ,[modi_user]
           ,[modi_device]
           ,[excl_data]
           ,[excl_user]
           ,[excl_device]
           ,[entrada_saida])
select 
	[tipo_mov_cod]
,	[tipo_mov_descr]
,	[ativo]
,	[incl_data]
,	[incl_user]
,	[incl_device]
,	[modi_data]
,	[modi_user]
,	[modi_device]
,	[excl_data]
,	[excl_user]
,	[excl_device]
,	[entrada_saida]
from [Estoque_Tipos_Mov]