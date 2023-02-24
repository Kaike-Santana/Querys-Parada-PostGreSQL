

DECLARE @DT_REFERENCIA AS DATE
SET			@DT_REFERENCIA = CAST(GETDATE() - DATEPART(DD, GETDATE() - 1) AS date)

DECLARE @DT_ARQUIVO CHAR(10)
SET         @DT_ARQUIVO = REPLACE(CONVERT(CHAR(10), GETDATE(), 112), '/', '')

IF OBJECT_ID      ('TEMPDB.DBO.#TB_ARQUIVOS', 'U')   IS NOT NULL
DROP  TABLE #TB_ARQUIVOS
CREATE      TABLE #TB_ARQUIVOS
                        (  ID_ARQUIVO     INT IDENTITY
                        ,  FILTRO         VARCHAR(1000)
                        ,  DIRETORIO      VARCHAR(1000)
                        ,  COMANDO_SQL    VARCHAR(1000)
                        )

INSERT      INTO  #TB_ARQUIVOS
SELECT     FILTRO   =  CAST(NULL AS INT)
		,		DIRETORIO =   'D:\Avon\Dump\004CCCR_DUMP.VARDATA.txt'
		,       COMANDO_SQL = CAST(NULL AS VARCHAR(1000))
FROM		TB_AVON_DUMP_NEW
WHERE DT_REF >= @DT_REFERENCIA 
ORDER BY DT_REF 

---------------------------------------------------------------------------
DECLARE @TITULOS AS VARCHAR(MAX)
SET @TITULOS = 'COD_AGENCIA;RA;CPF/CNPJ;DATA;HORA_INICIO_CHAMADA;CALL_ID;DDD;TELEFONE;COD_RETORNO;DESCRICAO;STATUS_TELECOM;ID_OPERADOR;LOGIN_OPERADOR;HORA_FIM_CHAMADA;ALO;CPC;PROMESSA'

TRUNCATE TABLE TB_ARQUIVO_DUMP
/*
IF OBJECT_ID      ('TEMPDB.DBO.#TB_ARQUIVO_DUMP', 'U')   IS NOT NULL
DROP  TABLE #TB_ARQUIVO_DUMP
CREATE TABLE #TB_ARQUIVO_DUMP (
						ID_ARQUIVO INT IDENTITY,
						ARQUIVO VARCHAR(MAX)
)*/
/*
INSERT INTO TB_ARQUIVO_DUMP (ARQUIVO)
SELECT @TITULOS
*/
INSERT INTO TB_ARQUIVO_DUMP

SELECT ARQUIVO 
FROM  TB_AVON_DUMP_NEW
WHERE DT_REF >= @DT_REFERENCIA 
ORDER BY TP_HORARIO_FIM 

---------------------------------------------------------------------------


UPDATE #TB_ARQUIVOS
SET DIRETORIO = REPLACE(DIRETORIO, 'VARDATA', REPLACE(@DT_ARQUIVO,' ',''))

UPDATE      #TB_ARQUIVOS
SET         COMANDO_SQL       =    '"SELECT ARQUIVO FROM TB_ARQUIVO_DUMP ORDER BY ID_ARQUIVO"'
/*
UPDATE #TB_ARQUIVOS
SET COMANDO_SQL = REPLACE(COMANDO_SQL, 'VARDATA', @DT_REFERENCIA)
*/
----EXEC  MASTER..XP_CMDSHELL 'DEL "C:\Avon\Dump" /Q'





DECLARE       @BCP                       AS VARCHAR(1000)
            , @CONTADOR             AS INT
            , @CONTADOR_FINAL AS INT
            , @DIRETORIO            AS VARCHAR(1000)
            , @SQL                       AS VARCHAR(1000)
            
SET         @CONTADOR               =     1
SET         @CONTADOR_FINAL         =     (SELECT MAX(ID_ARQUIVO) FROM #TB_ARQUIVOS)            
            

       /*     CASO ALGUM DIA TENHA QUE EXPORTAR MAIS DE UM ARQUIVO 
WHILE (@CONTADOR  <=    @CONTADOR_FINAL)        
BEGIN */
            
SET         @DIRETORIO  =     (SELECT DIRETORIO FROM #TB_ARQUIVOS WHERE ID_ARQUIVO = @CONTADOR)
SET         @SQL        =     (SELECT COMANDO_SQL     FROM #TB_ARQUIVOS WHERE ID_ARQUIVO = @CONTADOR)
SET         @BCP        =     'BCP '                  + 
                                   @SQL              +
                                   ' QUERYOUT "'     +
                                   @DIRETORIO        + 
                                  ---  '" -w -t -S localhost -d DB_DAILY -T' 
									 '" -c -t; -T -Slocalhost -d DB_DAILY -T' 
EXEC  MASTER..XP_CMDSHELL     @BCP

/*
SET         @CONTADOR   =     @CONTADOR + 1
END */


