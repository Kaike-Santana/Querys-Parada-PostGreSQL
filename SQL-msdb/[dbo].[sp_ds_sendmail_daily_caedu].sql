
USE [Data_Science]
GO
 
DECLARE  
    @HTML VARCHAR(MAX)
,   @ASSUNTO VARCHAR(MAX)  =  (concat('Daily Caedu - ',convert(varchar(5),getdate(),103)))  
,	@DIRETORIO VARCHAR(MAX) = '\\polaris\NectarServices\Administrativo\Temporario\PraValer\Dump\DUMP_PRA_VALER_03032023.txt'
  

SET @HTML = '  
Bom dia!<br/><br/>  
  
Em anexo Daily Caedu.<br/><br/>  
  
<h2><span style="color:#A9A9A9"><strong><span style="font-size:10px"><span style="font-family:arial,helvetica,sans-serif"><em>Est&aacute; &eacute; uma mensagem autom&aacute;tica.</em></span></span></strong></span></h2>  
  
'  
BEGIN TRY  

EXEC msdb.dbo.sp_send_dbmail  
    @profile_name = 'DBA',  
    @recipients = 'kaike.santana@atmatec.com.br',  
	@importance = 'HIGH',  
	@file_attachments = @DIRETORIO,
    @subject = @ASSUNTO,  
    @body = @HTML,   
    @body_format = 'HTML'  

END TRY

BEGIN CATCH
   		PRINT 'ERRO NÚMERO		: ' + CONVERT(VARCHAR, ERROR_NUMBER());
 		PRINT 'ERRO MENSAGEM	: ' + ERROR_MESSAGE();
 		PRINT 'ERRO SEVERITY	: ' + CONVERT(VARCHAR, ERROR_SEVERITY());
 		PRINT 'ERRO STATE		: ' + CONVERT(VARCHAR, ERROR_STATE());
 		PRINT 'ERRO LINE		: ' + CONVERT(VARCHAR, ERROR_LINE());
 		PRINT 'ERRO PROC		: ' + ERROR_PROCEDURE();
END CATCH