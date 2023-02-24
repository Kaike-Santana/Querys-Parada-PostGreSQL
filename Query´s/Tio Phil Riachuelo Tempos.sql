
USE [Data_Science]
GO

/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* PROGRAMADOR:MARCOS CASTRO								                                    */
/* VERSAO     :DATA: 23/03/2022																	*/
/* DESCRICAO  :EXPORTA ARQUIVO DE TEMPOS OPERACIONAIS RENNER									*/
/*																								*/
/*	ALTERACAO                                                                                   */
/*        1. PROGRAMADOR: MARCOS CASTRO										DATA: 28/03/2022	*/		
/*           DESCRICAO  : INCLUSÃO DA FILA RECEPTIVO											*/
/*	ALTERACAO                                                                                   */
/*        2. PROGRAMADOR: KAIKE NATAN										DATA: 22/04/2022	*/		
/*           DESCRICAO  : RETIRADA DOS ESPAÇOS VAZIOS E DATA NO FORMATO BRASILEIRO				*/
/*	ALTERACAO                                                                                   */
/*        3. PROGRAMADOR: KAIKE NATAN										DATA: 28/06/2022	*/		
/*           DESCRICAO  : REESTRUTURAÇÃO DO LAYOUT DA PROCEDURE									*/
/*	ALTERACAO                                                                                   */
/*        4. PROGRAMADOR:													DATA: __/__/____	*/		
/*           DESCRICAO  :																		*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
	--ALTER   PROCEDURE [dbo].[PRC_ARQUIVO_TEMPOS_OPERACIONAIS_RENNER] AS
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	SETA AS VARIÁVEIS PARA PEGAR SEG A SEXTA									    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
BEGIN;
	DECLARE @DIA DATE = CONVERT(DATE,GETDATE()-1)
	IF(
		DATEPART(
				 DW,GETDATE()
				) = 2
	  )
		BEGIN;
			SET @DIA  = CONVERT(DATE,GETDATE()-2)
		END;
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :VARIAVÉIS DO CÓDIGO															    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DECLARE @DIA DATE = CONVERT(DATE,GETDATE()-1)
DECLARE @ANO  VARCHAR(4) = CONVERT(VARCHAR(4),@DIA,112)
DECLARE @MES  VARCHAR(2) = SUBSTRING(CONVERT(VARCHAR(8),@DIA,112),5,2)
DECLARE @DATA VARCHAR(8) = CONVERT(VARCHAR(8),@DIA,112)
DECLARE @HORA VARCHAR(8) = REPLACE(LEFT(CONVERT(TIME,GETDATE()),8),':','')
DECLARE @NOMENCLATURA_MARC VARCHAR(MAX)  
SET		@NOMENCLATURA_MARC = 'TEMPOS_OPERACIONAIS_'+@DATA+'_'+@HORA+'_ATM.txt'
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: CHAMADAS OPERACIONAIS																*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
IF OBJECT_ID ('tempdb.dbo.#CHAMADAS') IS NOT NULL DROP TABLE #CHAMADAS
SELECT
 DATA
,AGENTE
,[ATENDIDAS ATIVO]			=	 COUNT(IIF(FILA != 3003,UNIQUEID,NULL))
,[ATENDIDAS RECEPTIVO]		=	 COUNT(IIF(FILA  = 3003,UNIQUEID,NULL))
INTO #CHAMADAS
FROM DATA_SCIENCE..TB_DS_CALLFLEX_MES
WHERE NOME_FILA LIKE '%RIACH%'
AND DATA = @DIA 
AND AGENTE != 0
GROUP BY DATA,AGENTE
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: AGENTES CALLFLEX																	*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DROP TABLE IF EXISTS #AGENTS
SELECT DISTINCT A.* 
INTO #AGENTS			
FROM OPENQUERY([10.251.2.18],'select cpf,user as usuario from replica_atmsp2b1.agents') A 

union all

SELECT DISTINCT A.* 		
FROM OPENQUERY([10.251.2.18],'select cpf,user as usuario from replica_atmspbb1.agents') A 
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: TEMPOS OPERACIONAIS															    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DECLARE @DIA DATE = CONVERT(DATE,GETDATE()-1)
DECLARE @ANO  VARCHAR(4) = CONVERT(VARCHAR(4),@DIA,112)
DECLARE @MES  VARCHAR(2) = SUBSTRING(CONVERT(VARCHAR(8),@DIA,112),5,2)
DECLARE @DATA VARCHAR(8) = CONVERT(VARCHAR(8),@DIA,112)
DECLARE @HORA VARCHAR(8) = REPLACE(LEFT(CONVERT(TIME,GETDATE()),8),':','')
IF OBJECT_ID ('tempdb.dbo.#TEMPOS') IS NOT NULL DROP TABLE #TEMPOS
SELECT DISTINCT
	ID						=	RTRIM(LTRIM(CAST(2 AS VARCHAR)))
,	COD_ASSESSORIA			=	RTRIM(LTRIM(CAST('ATM' AS VARCHAR)))
,	PERIODO					=	RTRIM(LTRIM(CAST(CONVERT(CHAR(6),A.DATA,112) AS VARCHAR)))
,	PRIMEIRO_LOGIN			=	RTRIM(LTRIM(CONCAT(REPLACE(CONVERT(VARCHAR(10),A.DATA,103),'/','-'),' ',HORA_LOGIN )))
,	ULTIMO_LOGOUT			=	RTRIM(LTRIM(CONCAT(REPLACE(CONVERT(VARCHAR(10),A.DATA,103),'/','-'),' ',HORA_LOGOUT)))
,	USUARIO					=	RTRIM(LTRIM(CAST(RTRIM(LTRIM(B.CPF)) AS VARCHAR)))
,	REGIME					=	RTRIM(LTRIM(CAST(IIF(CONTRATO IS NULL,'CLT',RTRIM(LTRIM((CASE WHEN CONTRATO = 'MENSALISTA' THEN 'CLT' ELSE CONTRATO END)))) AS VARCHAR)))
,	DATA_ADMISSAO			=	REPLACE(RTRIM(LTRIM(CONVERT(VARCHAR(20),ISNULL(Admissao,'05/09/2022'),103))),'/','-')
,	CARGA_HORARIA			=	RTRIM(LTRIM(CAST(IIF(CONTRATO = 'ESTAGIARIO','06:00:00','06:20:00') AS VARCHAR)))
,	TTL						=	RTRIM(LTRIM(CAST(DBO.ConverteSegundosEmHoras(IIF(CONTRATO = 'CLT',(TEMPO_LOGADO+1200),TEMPO_LOGADO)) AS VARCHAR)))
,	TTO						=	RTRIM(LTRIM(CAST(DBO.ConverteSegundosEmHoras(TEMPO_DISPONIVEL) AS VARCHAR)))
,	TTPNR					=	RTRIM(LTRIM(CAST(DBO.ConverteSegundosEmHoras(IIF(CONTRATO = 'CLT',(TEMPO_PAUSAS_OFICIAIS+1200),TEMPO_PAUSAS_OFICIAIS)) AS VARCHAR)))
,	TTPE					=	RTRIM(LTRIM(CAST(DBO.ConverteSegundosEmHoras(TEMPO_OUTRAS_PAUSAS)	AS VARCHAR)))
,	TTT						=	RTRIM(LTRIM(CAST(DBO.ConverteSegundosEmHoras(TEMPO_PAUSA_OCORRENCIA) AS VARCHAR)))
,	TTA						=	RTRIM(LTRIM(CAST(DBO.ConverteSegundosEmHoras(TEMPO_EM_ATENDIMENTO) AS VARCHAR)))
,	TMD						=	RTRIM(LTRIM(CAST(DBO.ConverteSegundosEmHoras(TME)	AS VARCHAR)))
,	TMT						=	RTRIM(LTRIM(CAST(DBO.ConverteSegundosEmHoras(TEMPO_PAUSA_OCORRENCIA) AS VARCHAR)))
,	TMA						=	RTRIM(LTRIM(CAST(DBO.ConverteSegundosEmHoras(TMA)	AS VARCHAR)))
,	[ATENDIDAS ATIVO]		=	ISNULL(RTRIM(LTRIM(CAST([ATENDIDAS ATIVO] AS VARCHAR))),0)
,	[ATENDIDAS RECEPTIVO]	=	ISNULL(RTRIM(LTRIM(CAST([ATENDIDAS RECEPTIVO] AS VARCHAR))),0)
INTO #TEMPOS
FROM REPORTS..TB_DS_TEMPOS_OPERACIONAL_ATMA A 
left JOIN #AGENTS B	  ON B.USUARIO = A.AGENTE
left JOIN #CHAMADAS D  ON A.AGENTE  = D.AGENTE AND A.DATA = D.DATA	
LEFT JOIN DATA_SCIENCE..OPERADORES O ON O.CPF = B.CPF
WHERE A.DATA = @DIA 
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: ALIMENTA TABELA FISICA														    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
INSERT INTO REPORTS.DBO.TB_DS_RENNER_DUMP_TEMPOS
SELECT DISTINCT * FROM #TEMPOS
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: INCLUSÃO DO CABEÇALHO															    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
IF OBJECT_ID ('TEMPDB.DBO.##CABECALHO') IS NOT NULL DROP TABLE ##CABECALHO 
SELECT *  
INTO ##CABECALHO  
FROM(
		SELECT DISTINCT 
		ID						=	1			
,		COD_ASSESSORIA			=	'COD_ASSESSORIA'		
,		PERIODO					=	'PERIODO'				
,		PRIMEIRO_LOGIN			=	'PRIMEIRO_LOGIN'		
,		ULTIMO_LOGOUT			=	'ULTIMO_LOGOUT'		
,		USUARIO					=	'USUARIO'				
,		REGIME					=	'REGIME'				
,		DATA_ADMISSAO			=	'DATA_ADMISSAO'		
,		CARGA_HORARIA			=	'CARGA_HORARIA'		
,		TTL						=	'TTL'					
,		TTO						=	'TTO'					
,		TTPNR					=	'TTPNR'				
,		TTPE					=	'TTPE'					
,		TTT						=	'TTT'					
,		TTA						=	'TTA'					
,		TMD						=	'TMD'					
,		TMT						=	'TMT'					
,		TMA						=	'TMA'					
,		[ATENDIDAS ATIVO]		=	'ATENDIDAS ATIVO'		
,		[ATENDIDAS RECEPTIVO]	=	'ATENDIDAS RECEPTIVO'	
UNION ALL
SELECT * FROM #TEMPOS) A 

/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO: EXPORTA ARQUIVO NO LAYOUT DO CLIENTE 											    */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
DECLARE @BCP NVARCHAR(4000)  
SET @BCP = ' master..xp_cmdshell ''bcp " SELECT COD_ASSESSORIA,PERIODO,PRIMEIRO_LOGIN,ULTIMO_LOGOUT,USUARIO,REGIME,DATA_ADMISSAO,CARGA_HORARIA,TTL,TTO,TTPNR,TTPE,TTT,TTA,TMD,TMT,TMA,[ATENDIDAS ATIVO],[ATENDIDAS RECEPTIVO]  FROM ##CABECALHO A ORDER BY ID ASC " queryout "\\polaris\NectarServices\Administrativo\Output\17.Renner\01.tempos_operacionais\'+@ANO+'\'+@MES+'"\'+@NOMENCLATURA_MARC+' -c -T -t ";" '''  
EXEC SP_EXECUTESQL @BCP

END;

BEGIN;
	DROP TABLE IF EXISTS ##CABECALHO;
END;