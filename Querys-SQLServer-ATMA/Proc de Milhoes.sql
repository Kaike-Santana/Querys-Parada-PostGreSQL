
USE [Data_Science]
GO

/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/*																								*/
/* PROGRAMADOR: KAIKE NATAN									                                    */
/* VERSAO     : DATA: 30/11/2022																*/
/* DESCRICAO  : PROC PARA EXPORTA REGISTRO DE TABELA FISICA COM CABEÇALHO (BCP (BULK COPY))	    */
/*																								*/
/*	ALTERACAO                                                                                   */
/*        2. PROGRAMADOR: 													 DATA: __/__/____	*/		
/*           DESCRICAO  : 																		*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
	ALTER PROCEDURE [dbo].[AAA_PROC_DE_MILHOES] (
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: PARAMETROS DE ENTRADA DA PROC													    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
      @path                NVARCHAR(900)

    , @serverName          SYSNAME = @@SERVERNAME

    , @databaseName        SYSNAME

    , @schemaName          SYSNAME

    , @tableName           SYSNAME

    , @fieldTerminator     NVARCHAR(10)  = '|'

    , @fileExtension       NVARCHAR(10)  = 'txt'

    , @codePage            NVARCHAR(10)  = 'C1251'

    , @excludeColumns      NVARCHAR(MAX) = ''

    , @outputColumnHeaders BIT = 1

    , @debug               BIT = 0
) AS 
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: INICIO BLOCO BEGIN E CONTROLE FLUXO COM TRY CACH								    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
--> INICIO DA BAGUNCINHA
BEGIN
    BEGIN TRY
    IF @debug = 0 SET NOCOUNT ON;
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: VARIÁVEIS DO CÓDIGO															    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
    DECLARE @tsqlCommand     NVARCHAR(MAX) = '';

    DECLARE @cmdCommand      VARCHAR(8000)  = '';

    DECLARE @ParmDefinition  NVARCHAR(500) = '@object_idIN INTEGER, @ColumnsOUT VARCHAR(MAX) OUTPUT';

    DECLARE @tableFullName   NVARCHAR(500) = QUOTENAME(@databaseName) + '.' + QUOTENAME(@schemaName) + '.' + QUOTENAME(@tableName);

    DECLARE @object_id       INTEGER       = OBJECT_ID(@tableFullName);

    DECLARE @Columns         NVARCHAR(MAX) = '';

    DECLARE @filePath        NVARCHAR(900) = @path + @tableFullName + '.' + @fileExtension;

    DECLARE @crlf            NVARCHAR(10)  = CHAR(13);

    DECLARE @TROW50000       NVARCHAR(MAX) = ''
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: VALIDA VARIAVLE @TABLEFULL													    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
    IF (
		@debug
	    ) = 1 
	PRINT (
			ISNULL('/******* Start Debug' + 
			@crlf + 
			'@tableFullName = {' + CAST(@tableFullName AS NVARCHAR) 
			+ '}', '@tableFullName = {Null}')
		  )
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: VALIDA VARIAVLE OBJECT ID														    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
    IF (
		@debug
	   ) = 1 
	PRINT (
			ISNULL(
					'@object_id = {' + CAST(@object_id AS NVARCHAR) + '}', '@object_id = {Null}'
				  )
		  )
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: SETA 	@TROW50000 CONFIRMANDO QUE NÂO EXISTE A TABELA FISICA NO BANCO			    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

    SET @TROW50000 = 'Table ' + @tableFullName + ' is not exists in database ' + QUOTENAME(@databaseName) + '!!!';

    IF @OBJECT_ID IS NULL THROW 50000, @TROW50000, 1;
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: COMANDO SQL DINAMICO PEGANDO EM TODOS OS DATABASES DA INSTANCIA				    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

    SET @tsqlCommand = N'USE ' + @databaseName + ';'                                                            + @crlf +

                       N'SELECT @ColumnsOUT  = @ColumnsOUT + QUOTENAME(Name) + '','''                           + @crlf +

                       N'FROM sys.columns sac '                                                                 + @crlf +

                       N'WHERE sac.object_id = @object_idIN'                                                    + @crlf +

                       N'      AND QUOTENAME(Name) NOT IN (''' + REPLACE(@excludeColumns, ',', ''',''') + ''')' + @crlf +

                       N'ORDER BY Name;';
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: VALIDA O COMANDO T-SQL ACIMA													    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
    IF (
		@debug = 1
	   )
	 PRINT ISNULL(N'@tsqlCommand = {' + @crlf + @tsqlCommand + @crlf + N'}', N'@tsqlCommand = {Null}');
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: APÓS VALIDADO EXECUTA ATRAVES DA PROC INTERNA DO SQL SP_EXECUTESQL			    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
 EXECUTE sp_executesql @tsqlCommand, @ParmDefinition, @object_idIN = @object_id, @ColumnsOUT = @Columns OUTPUT SELECT @Columns;
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: VALIDA COLUNAS PARA CABEÇALHO													    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
    IF (
		@debug
	   )= 1 
	PRINT ISNULL('@Columns = {' + @crlf + @Columns + @crlf + '}', '@Columns = {Null}');
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: SETA A VARIÁVEL COM AS COLUNAS												    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
   SET @Columns = CASE 
					  WHEN LEN(
							   @Columns
							  ) > 0 
							  THEN LEFT(@Columns, LEN(@Columns) - 1)
				  END;
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: VALIDA COLUNAS ANTES DO EXEC DA PROC											    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
   IF (
		@debug
	  )= 1 
	PRINT CAST(ISNULL('@Columns = {' + @Columns + '}', '@Columns = {Null}') AS TEXT);

SET @tsqlCommand = 'EXECUTE xp_cmdshell ' +  '''bcp "SELECT ' + @Columns + '  FROM ' + @tableFullName + '" queryout "' +  @filePath + '" -T -S ' + @serverName +' -c -' + @codePage + ' -t"' + @fieldTerminator + '"''' + @crlf;
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: VALIDA CÓDIGO DO EXEC, DANDO OK, VAI PRO ELSE									    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
    IF (
		@debug
	   ) = 1 
			PRINT CAST(ISNULL('@tsqlCommand = {' + @crlf + @tsqlCommand + @crlf + '}', '@tsqlCommand = {Null}' + @crlf) AS TEXT);
    ELSE

	EXECUTE sp_executesql @tsqlCommand;
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: VALIDA CÓDIGO DO EXEC, DANDO OK, VAI PRO ELSE									    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
    IF (
		@outputColumnHeaders = 1
	   )

--> INICIA VALIDADOR DO CABEÇALHO EXPORTADO
 BEGIN
   SET @tsqlCommand = 'EXECUTE xp_cmdshell ' +  '''bcp "SELECT ''''' + REPLACE(@Columns, ',', @fieldTerminator) + '''''" queryout "' +  @path + @tableFullName + '_headers.txt' + '" -T -S ' + @serverName + ' -c -' + @codePage + ' -t"' + @fieldTerminator + '"''' + @crlf;

       
             IF (
				 @debug
				) = 1 PRINT CAST(ISNULL('@tsqlCommand = {' + @crlf + @tsqlCommand + @crlf + '}', '@tsqlCommand = {Null}' + @crlf) AS TEXT);

             ELSE 
				EXECUTE sp_executesql @tsqlCommand;

             SET @cmdCommand = 'copy /b ' + @path + @tableFullName + '_headers.' + @fileExtension + ' + ' + @filePath + ' ' + @path + @tableFullName + '_headers.' + @fileExtension;

             IF (
				 @debug
				)= 1 
					PRINT CAST(ISNULL('@cmdCommand = {' + @crlf + @cmdCommand + @crlf + '}', '@cmdCommand = {Null}' + @crlf) AS TEXT)
             ELSE 
				EXECUTE xp_cmdshell @cmdCommand;

             SET @cmdCommand = 'del ' + @filePath;

             IF @debug = 1 PRINT CAST(ISNULL('@cmdCommand = {' + @crlf + @cmdCommand + @crlf + '}', '@cmdCommand = {Null}' + @crlf) AS TEXT)

             ELSE EXECUTE xp_cmdshell @cmdCommand;

        END

--> FECHA FLUXO

    ELSE
		SET NOCOUNT OFF;
--> HABILITA CONTADOR DA PROC DNV.

    END TRY
--> FECHA O TRY CACH

--> ABRE CONTROLE DE FLUXO DE ERRO DA PROC
    BEGIN CATCH
		PRINT ('ERRO NÚMERO		: ' + CONVERT(VARCHAR, ERROR_NUMBER()));
 		PRINT ('ERRO MENSAGEM	: ' + ERROR_MESSAGE());
 		PRINT ('ERRO SEVERITY	: ' + CONVERT(VARCHAR, ERROR_SEVERITY()));
 		PRINT ('ERRO STATE		: ' + CONVERT(VARCHAR, ERROR_STATE()));
 		PRINT ('ERRO LINE		: ' + CONVERT(VARCHAR, ERROR_LINE()));
 		PRINT ('ERRO PROC		: ' + ERROR_PROCEDURE());
    END CATCH
--> ENCAPLUSA POSSIVEL ERRO CASO TENHA.

END;

--> FIM DA BAGUNCINHA.