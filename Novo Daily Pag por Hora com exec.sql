
USE [DB_REPORT]
GO


/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/*																										*/
/* PROGRAMADOR: KAIKE NATAN									                                            */
/* VERSAO     : 1.0      DATA: 23/09/2021                                                               */
/* DESCRICAO  : RESPONSAVEL POR ATUALIZAR O DAILY DA PAG SEGURO							  			    */
/*																										*/
/*	ALTERACAO                                                                                           */
/*        1. PROGRAMADOR: KAIKE NATAN												   DATA: 27/09/2021 */
/*           DESCRICAO  : INCLUSÃO DO ROW NUMBER PARA RETIRADA DOS DUPLICADOS							*/
/*																										*/
/*	ALTERACAO                                                                                           */
/*        1. PROGRAMADOR: KAIKE NATAN												   DATA: 02/10/2021 */
/*           DESCRICAO  : AGRUPANDO OS DADOS POR HORA													*/
/*																										*/
/*	ALTERACAO                                                                                           */
/*        1. PROGRAMADOR: KAIKE NATAN												   DATA: 05/10/2021 */
/*           DESCRICAO  : IMPLEMENTAÇÃO DO FLUXO DE CONTROLE DA QUERY									*/
/*						  ATRAVÉS DO BEGIN TRY CATCH													*/
/*	ALTERACAO                                                                                           */
/*        1. PROGRAMADOR: KAIKE NATAN												   DATA: 07/10/2021 */
/*           DESCRICAO  : DEIXANDO A CONSULTA DINÂNICA COM EXEC DE VARIÁVEL								*/
/*	ALTERACAO                                                                                           */
/*        1. PROGRAMADOR: KAIKE NATAN												   DATA: 07/10/2021 */
/*           DESCRICAO  : DEIXANDO A CONSULTA DINÂNICA COM EXEC DE VARIÁVEL								*/
/*						 																				*/	
/*						 																				*/	
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

	--ALTER PROCEDURE [dbo].[PRC_MIS_DAILY_PAG_SEGURO] AS


	DECLARE @DATA				AS DATE
	DECLARE @CALLDATA			AS VARCHAR (MAX)
	DECLARE @CAMPANHAS_12		AS VARCHAR (MAX)
	DECLARE @DIALER				AS VARCHAR (MAX)
	DECLARE @CAMPANHAS_246		AS VARCHAR (MAX)
	DECLARE @TABULACAO			AS VARCHAR (MAX)

	SET		@DATA			=	CAST(GETDATE() AS date)
	SET		@DIALER			=  'DIALERCALLS'
	SET		@CAMPANHAS_12	=  'CAMPAIGNS'
	SET		@CAMPANHAS_246	=  'TB_CAMPANHAS_FIXA'
	SET		@CALLDATA		=  'CALLDATA'
	SET		@TABULACAO		=  'TB_REL_HORA_HORA_TABULACAO_ANALITICO'

	
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	PEGA TABULACAO DO 66 DA PAG SEGURO DO DIA					     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

EXECUTE ('

 IF OBJECT_ID(''TEMPDB.DBO.#TABULACAO'',''U'') IS NOT NULL
 BEGIN
	DROP TABLE #TABULACAO 
 END
 
 SELECT 
		TB.DATA
,       TB.HORA
,	    TB.ID_CLIENTE
,		CE			
,		CPC
,		CPCA
,		TB.AF
,		NM_USUARIO
,		FAIXA_CONTRATANTE	=	

								 CASE
										WHEN ATRASO	   < 60							THEN ''01.<60''
										WHEN ATRASO	   BETWEEN 61  AND 90			THEN ''02.61-90''
										WHEN ATRASO	   BETWEEN 91  AND 120			THEN ''03.91-120''
										WHEN ATRASO	   BETWEEN 121 AND 150			THEN ''04.121-150''
										WHEN ATRASO	   BETWEEN 151 AND 180			THEN ''05.151-180''
										WHEN ATRASO	   BETWEEN 181 AND 360			THEN ''06.181-360''
										WHEN ATRASO	   > 360						THEN ''07.>360''
								 END

,		PRODUTO				= 
								 CASE 
										WHEN TB.GRUPO1 = ''CARTAO''					THEN  ''CARTAO''
										WHEN TB.GRUPO1 = ''EMPRESTIMO''				THEN  ''EMPRESTIMO''
																				    ELSE  ''CREDISIM''
								 END
 INTO #TABULACAO 
 FROM [' +@TABULACAO+ '] TB WITH(NOLOCK)
 WHERE TB.ID_CEDENTE = 43
 AND DATA = ''' +@DATA+ '''

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO : PEGA DISCAGENS PAG SEGURO DA ATTO, (PS: SE VIER VAZIO É PQ DISCOU NA OLOS)   */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

IF OBJECT_ID(''TEMPDB.DBO.#DISCAGEM'',''U'') IS NOT NULL
BEGIN
	DROP TABLE #DISCAGEM 
END

 SELECT 
		D.CALLID
,		D.CALLMOMENT
,		D.TERMINATIONSTATUS
,		D.DATAMEMO1
,		C.DESCRIPTION 
,		TELNUMBER

 INTO #DISCAGEM
 FROM [172.20.30.12].[EDATA].[DBO].[' +@DIALER+ '] D WITH(NOLOCK)
 	LEFT JOIN
 	  [172.20.30.12].[EADMIN].[DBO].[' +@CAMPANHAS_12+ ']  C WITH(NOLOCK)
 ON   D.CAMPAIGNSID = C.SID

 WHERE CAST(D.CALLMOMENT AS DATE) = ''' + @DATA + '''
 AND (
		  C.DESCRIPTION LIKE ''%PAG%''
		OR C.DESCRIPTION LIKE ''%UOL%''
	 )
		
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	PEGA DISCAGENS PAG SEGURO DA OLOS, (PS: SE VIER VAZIO É PQ DISCOU NA ATTO)  */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

IF OBJECT_ID(''TEMPDB.DBO.#DISCAGEM_OLOS'',''U'') IS NOT NULL
BEGIN
	DROP TABLE #DISCAGEM_OLOS 
END

SELECT 
			A.CALLID
,			A.CALLSTART
,			ALO					=	IIF(A.AGENTSTART IS NULL, 0, 200)
,			DATAMEMO1			=	A.CUSTOMERID
,			B.DESCRIPTION
,			TELNUMBER			=	A.DNIS

INTO #DISCAGEM_OLOS
FROM [172.20.10.246].[EXPORTDATA].[DBO].[' +@CALLDATA+ '] A WITH(NOLOCK) 
   LEFT JOIN							  
	 [172.20.10.246].[EXPORTDATA].[DBO].[' +@CAMPANHAS_246+ '] B WITH(NOLOCK)
ON	(A.CAMPAIGNID	=	 B.CAMPAIGNID)
WHERE CAST(CALLSTART AS DATE) = ''' +@DATA+ '''
AND (
		  B.DESCRIPTION LIKE ''%PAG%''
		OR B.DESCRIPTION LIKE ''%UOL%''
	)
		
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	UNIFICAÇÃO DAS DISCAGENS							  		     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

	INSERT INTO #DISCAGEM
	SELECT 
	 		CALLID
,	 		CALLSTART
,	 		ALO				
,	 		DATAMEMO1	
,	 		DESCRIPTION
,			TELNUMBER 
	FROM #DISCAGEM_OLOS		

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	SEPARA AS COLUNAS DA DISCAGEM PRO JOIN				  		     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

IF OBJECT_ID(''TEMPDB.DBO.#TABELA_DISCAGEM'',''U'') IS NOT NULL
BEGIN
	DROP TABLE #TABELA_DISCAGEM 
END

SELECT 
	   DISCADO = COUNT(1)
,	   DATAMEMO1

INTO #TABELA_DISCAGEM
FROM #DISCAGEM
GROUP BY 
	   DATAMEMO1

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	SEPARA AS COLUNAS DA DISCAGEM PRO JOIN				  		     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

IF OBJECT_ID(''TEMPDB.DBO.#FINAL'',''U'') IS NOT NULL
BEGIN
	DROP TABLE #FINAL 
END

SELECT
		DATA,
		ID_CLIENTE,
		AGING		=	FAIXA_CONTRATANTE,
		PRODUTO,
		OPERADORES  =	NM_USUARIO,
		HORA		=	
						CASE 
								WHEN HORA BETWEEN 0  AND 1	 THEN ''00hrs ás 01hrs''
								WHEN HORA BETWEEN 1  AND 2	 THEN ''01hrs ás 02hrs''
								WHEN HORA BETWEEN 2  AND 3   THEN ''02hrs ás 03hrs''
								WHEN HORA BETWEEN 3  AND 4   THEN ''03hrs ás 04hrs''
								WHEN HORA BETWEEN 4  AND 5   THEN ''04hrs ás 05hrs''
								WHEN HORA BETWEEN 5  AND 6	 THEN ''05hrs ás 06hrs''
								WHEN HORA BETWEEN 6  AND 7	 THEN ''06hrs ás 07hrs''
								WHEN HORA BETWEEN 7  AND 8	 THEN ''07hrs ás 08hrs''
								WHEN HORA BETWEEN 8  AND 9   THEN ''08hrs ás 09hrs''
								WHEN HORA BETWEEN 9  AND 10  THEN ''09hrs ás 10hrs''
								WHEN HORA BETWEEN 10 AND 11  THEN ''10hrs ás 11hrs''
								WHEN HORA BETWEEN 11 AND 12  THEN ''11hrs ás 12hrs''
								WHEN HORA BETWEEN 12 AND 13  THEN ''12hrs ás 13hrs''
								WHEN HORA BETWEEN 13 AND 14  THEN ''13hrs ás 14hrs''
								WHEN HORA BETWEEN 14 AND 15  THEN ''14hrs ás 15hrs''
								WHEN HORA BETWEEN 15 AND 16  THEN ''15hrs ás 16hrs''
								WHEN HORA BETWEEN 16 AND 17  THEN ''16hrs ás 17hrs''
								WHEN HORA BETWEEN 17 AND 18  THEN ''17hrs ás 18hrs''
								WHEN HORA BETWEEN 18 AND 19  THEN ''18hrs ás 19hrs''
								WHEN HORA BETWEEN 19 AND 20  THEN ''19hrs ás 20hrs''
								WHEN HORA BETWEEN 20 AND 21  THEN ''20hrs ás 21hrs''
								WHEN HORA BETWEEN 21 AND 22  THEN ''21hrs ás 22hrs''
								WHEN HORA BETWEEN 22 AND 23  THEN ''22hrs ás 23hrs''
								WHEN HORA BETWEEN 23 AND 0   THEN ''23hrs ás 00hrs''
						END,	
						
		ATEND_ESF	=	CE,
		CPC_ESF		=	CPC,
		CPCA,
		BOLETOS		=	AF,
		DISCADO		=	TD.DISCADO

INTO #FINAL
FROM  #TABULACAO T
   LEFT JOIN
	  #TABELA_DISCAGEM TD
ON T.ID_CLIENTE		=	TD.DATAMEMO1

--WHERE ISNUMERIC(TD.DATAMEMO1) = 1
ORDER BY 
		HORA DESC

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	SEPARA AS COLUNAS DA DISCAGEM PRO JOIN				  		     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

DELETE FROM TB_MIS_DAILY_PAGSEGURO
WHERE DATA	=	''' +@DATA+ '''

INSERT INTO TB_MIS_DAILY_PAGSEGURO
SELECT *
FROM #FINAL


 ')

