
USE [DB_REPORT]
GO

/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/*																										*/
/* PROGRAMADOR: KAIKE NATAN									                                            */
/* VERSAO     : 1.0      DATA: 23/09/2021                                                               */
/* DESCRICAO  : RESPONSAVEL POR ATUALIZAR O DAILY DA PAG SEGURO							  			    */
/*																										*/
/*	ALTERACAO                                                                                           */
/*        1. PROGRAMADOR: KAIKE NATAN												   DATA: 24/09/2021 */
/*           DESCRICAO  : IMPLEMENTAÇÃO DO TRY CACTH E FLUXO DO WHILE									*/
/*																										*/
/*	ALTERACAO                                                                                           */
/*        1. PROGRAMADOR: GABIGOL													   DATA: 25/09/2021 */
/*           DESCRICAO  : AJUSTE DOS 2 WHILE															*/
/*																										*/
/*	ALTERACAO                                                                                           */
/*        1. PROGRAMADOR: KAIKE NATAN												   DATA: 27/09/2021 */
/*           DESCRICAO  : INCLUSÃO DO ROW NUMBER PARA RETIRADA DOS DUPLICADOS							*/
/*																										*/
/*	ALTERACAO                                                                                           */
/*        1. PROGRAMADOR: KAIKE NATAN												   DATA: 07/10/2021 */
/*           DESCRICAO  : AGRUPANDO OS DADOS POR HORA													*/
/*																										*/
/*	ALTERACAO                                                                                           */
/*        1. PROGRAMADOR: 															   DATA: __/__/____ */
/*           DESCRICAO  : 																				*/
/*																										*/	
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

	--ALTER PROCEDURE [dbo].[PRC_MIS_DAILY_PAG_SEGURO] AS

	DECLARE @DATA AS DATE
		SET @DATA = CAST(GETDATE() AS DATE)

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	PEGA BASE DO SCC DA WILL BANK DO DIA						     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

 IF OBJECT_ID('TEMPDB.DBO.#SCC','U') IS NOT NULL
 DROP TABLE #SCC 

 SELECT 
		ID_CLIENTE
,		FAIXA_CONTRATANTE
,		PRODUTO = 
					CASE 
							WHEN PRODUTO = 'CARTAO'					THEN  'CARTAO'
							WHEN PRODUTO = 'EMPRESTIMO'				THEN  'EMPRESTIMO'
																	ELSE  'CREDISIM'
					 END

		
 INTO #SCC
 FROM [172.20.1.71].[BD_MIS].[DBO].[SCC_WEDOO] WITH(NOLOCK)
 WHERE ID_CEDENTE = 43

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	PEGA TABULACAO DO 66 DA WILL BANK DO DIA					     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

 IF OBJECT_ID('TEMPDB.DBO.#TABULACAO','U') IS NOT NULL
 DROP TABLE #TABULACAO 
 
 SELECT 
	    TB.ID_CLIENTE
,		TB.NCE
,		TB.CE
,		TB.CPC
,		TB.CPCA
,		TB.AF
,		TB.NM_USUARIO
,		FAIXA_CONTRATANTE	=	
					CASE
							WHEN ATRASO	   < 60							THEN '01.<60'
							WHEN ATRASO	   BETWEEN 61  AND 90			THEN '02.61-90'
							WHEN ATRASO	   BETWEEN 91  AND 120			THEN '03.91-120'
							WHEN ATRASO	   BETWEEN 121 AND 150			THEN '04.121-150'
							WHEN ATRASO	   BETWEEN 151 AND 180			THEN '05.151-180'
							WHEN ATRASO	   BETWEEN 181 AND 360			THEN '06.181-360'
							WHEN ATRASO	   > 360						THEN '07.>360'
					END
,		PRODUTO = 
					CASE 
							WHEN TB.GRUPO1 = 'CARTAO'					THEN  'CARTAO'
							WHEN TB.GRUPO1 = 'EMPRESTIMO'				THEN  'EMPRESTIMO'
																	    ELSE  'CREDISIM'
					 END
 INTO #TABULACAO 
 FROM [DB_REPORT].[DBO].[TB_REL_HORA_HORA_TABULACAO_ANALITICO] TB WITH(NOLOCK)
 WHERE TB.ID_CEDENTE = 43
 AND DATA = @DATA

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO : PEGA DISCAGENS PagSeguro DA ATTO, (PS: SE VIER VAZIO É PQ DISCOU NA OLOS)   */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

 IF OBJECT_ID('TEMPDB.DBO.#DISCAGEM','U') IS NOT NULL
 DROP TABLE #DISCAGEM 

 SELECT 
		D.CALLID
,		D.CALLMOMENT
,		D.TERMINATIONSTATUS
,		D.DATAMEMO1
,		C.DESCRIPTION 
,		FAIXA_CONTRATANTE	=	SC.FAIXA_CONTRATANTE
,		PRODUTO				=	SC.PRODUTO
,		TelNumber

 INTO #DISCAGEM
 FROM [172.20.30.12].[EDATA].[DBO].[DIALERCALLS] D WITH(NOLOCK)
 	LEFT JOIN
 	  [172.20.30.12].[EADMIN].[DBO].[CAMPAIGNS] C 
 ON   D.CAMPAIGNSID = C.SID
	LEFT JOIN 
		#SCC SC
 ON D.DataMemo1 = SC.ID_CLIENTE
 WHERE CAST(D.CallMoment AS DATE) = @DATA
 AND (
		C.DESCRIPTION LIKE '%PAG%'
		OR C.DESCRIPTION LIKE '%UOL%'
	 )
 

/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	PEGA DISCAGENS PagSeguro DA OLOS, (PS: SE VIER VAZIO É PQ DISCOU NA ATTO)   */
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

IF OBJECT_ID('TEMPDB.DBO.#DISCAGEM_OLOS','U') IS NOT NULL
DROP TABLE #DISCAGEM_OLOS 

SELECT 
			A.CALLID
,			A.CALLSTART
,			ALO					=	IIF(A.AGENTSTART IS NULL, 0, 200)
,			DATAMEMO1			=	A.CUSTOMERID
,			B.DESCRIPTION
,			FAIXA_CONTRATANTE	=	SC.FAIXA_CONTRATANTE
,			PRODUTO				=	SC.PRODUTO
,			TelNumber			=	DNIS
INTO #DISCAGEM_OLOS
FROM [172.20.10.246].[EXPORTDATA].[DBO].[CALLDATA] A WITH(NOLOCK) 
LEFT JOIN							  
	 [172.20.10.246].[EXPORTDATA].[DBO].[TB_CAMPANHAS_FIXA] B WITH(NOLOCK)
ON	(A.CAMPAIGNID	=	 B.CAMPAIGNID)
LEFT JOIN
	#SCC SC
ON (A.CustomerId	=	 SC.ID_CLIENTE)
WHERE CAST(CALLSTART AS DATE) = @DATA
AND (
		B.DESCRIPTION LIKE '%PAG%'
		OR B.DESCRIPTION LIKE '%UOL%'
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
,	 		FAIXA_CONTRATANTE
,			PRODUTO
,			TelNumber
	FROM #DISCAGEM_OLOS

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	CRIA TABELA DO INSERT										     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

 IF OBJECT_ID('TEMPDB.DBO.#DRAGON_BALL_FUSAO','U') IS NOT NULL
 DROP TABLE #DRAGON_BALL_FUSAO 
 CREATE TABLE #DRAGON_BALL_FUSAO		
								(			
									DATA  DATE NULL ,
									FAIXA_CONTRATANTE VARCHAR (100) NULL ,
									PRODUTO VARCHAR(100) NULL,
									BASE_GERAL BIGINT NULL ,
									DISCADO BIGINT NULL , 
									ATEND_ESF BIGINT NULL, 
									CPC_ESF BIGINT NULL ,
									CPCA BIGINT NULL,
									OPERADORES VARCHAR(MAX) NULL,
									DISCADOS_UNIQ BIGINT NULL ,
									ATEND_UNIQ BIGINT NULL ,
									CPC_UNIQ BIGINT NULL ,
									BOLETOS INT NULL
								)												

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	SEPARA O ATRASO	DOS CLIENTES								     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

	IF OBJECT_ID('TEMPDB.DBO.#TB_CONT','U') IS NOT NULL
	DROP TABLE #TB_CONT 

	SELECT DISTINCT FAIXA_CONTRATANTE , 
		   NUM = LEFT(FAIXA_CONTRATANTE,2)
	INTO #TB_CONT
	FROM #TABULACAO
	WHERE FAIXA_CONTRATANTE IS NOT NULL
	ORDER BY  1 

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	SEPARA O PRODUTO POR ATRASO									     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

 IF OBJECT_ID('TEMPDB.DBO.#TESTE','U') IS NOT NULL
 DROP TABLE #TESTE 
 CREATE TABLE #TESTE
					(
						PRODUTO VARCHAR(100)  NOT NULL,
						ID int NOT NULL IDENTITY(1,1)
					)


	INSERT INTO #TESTE
	SELECT DISTINCT  PRODUTO
	FROM #TABULACAO 


/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :			CRIA O LOOP DO INSERT								     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

BEGIN TRANSACTION 
 BEGIN 
 	BEGIN TRY 
 
  DECLARE @COUNT AS INT 
  SET @COUNT = 1 
 
 
  DECLARE @CountProd as INT
  SET @CountProd = 1
 
 
 WHILE(@COUNT <= (SELECT MAX(NUM) FROM #TB_CONT )) ---- FAIXA
 BEGIN

INSERT INTO #DRAGON_BALL_FUSAO VALUES 
(
@DATA --DATA
,	(SELECT FAIXA_CONTRATANTE
		FROM #TB_CONT 
			WHERE NUM = @COUNT) --FAIXA CONTRATANTE	
,				(SELECT PRODUTO
					FROM #TESTE
						WHERE ID = @CountProd) -- PRODUTO
,							(SELECT COUNT(1)
								FROM #SCC	
									WHERE FAIXA_CONTRATANTE = 
										(SELECT FAIXA_CONTRATANTE FROM #TB_CONT WHERE NUM = @COUNT) 
											AND PRODUTO = (SELECT PRODUTO FROM #TESTE WHERE ID = @CountProd)) -- BASE GERAL
,												(SELECT COUNT(DATAMEMO1) 
													FROM #DISCAGEM	 
														WHERE FAIXA_CONTRATANTE = 
															(SELECT FAIXA_CONTRATANTE FROM #TB_CONT WHERE NUM = @COUNT)
																AND PRODUTO = (SELECT PRODUTO FROM #TESTE WHERE ID = @CountProd))-- DISCADO   
,																	(SELECT COUNT(1) 
																		FROM #TABULACAO	 
																			WHERE CE = 1 
																				AND FAIXA_CONTRATANTE = 
																			(SELECT FAIXA_CONTRATANTE FROM #TB_CONT WHERE NUM = @COUNT)
																		AND PRODUTO = (SELECT PRODUTO FROM #TESTE WHERE ID = @CountProd))-- ALO
,																	(SELECT COUNT (1) 
																FROM #TABULACAO	 
															WHERE CPC = 1 
														AND FAIXA_CONTRATANTE = 
													(SELECT FAIXA_CONTRATANTE FROM #TB_CONT WHERE NUM = @COUNT)
												AND PRODUTO = (SELECT PRODUTO FROM #TESTE WHERE ID = @CountProd))-- CPC
,											(SELECT COUNT (1) 
										FROM #TABULACAO	 
									WHERE CPCA = 1 
								AND FAIXA_CONTRATANTE = 
							(SELECT FAIXA_CONTRATANTE FROM #TB_CONT WHERE NUM = @COUNT)
						AND PRODUTO = (SELECT PRODUTO FROM #TESTE WHERE ID = @CountProd))-- CPCA
,					(SELECT COUNT(DISTINCT NM_USUARIO) 
				FROM #TABULACAO	 
			WHERE FAIXA_CONTRATANTE = 
				(SELECT FAIXA_CONTRATANTE FROM #TB_CONT WHERE NUM = @COUNT)
					AND PRODUTO = (SELECT PRODUTO FROM #TESTE WHERE ID = @CountProd))-- OPERADORES
,						(SELECT COUNT(DISTINCT DATAMEMO1)	 
							FROM #DISCAGEM 
								WHERE ISNUMERIC(DATAMEMO1) = 1 
									AND FAIXA_CONTRATANTE = 
										(SELECT FAIXA_CONTRATANTE FROM #TB_CONT WHERE NUM = @COUNT)
											AND PRODUTO = (SELECT PRODUTO FROM #TESTE WHERE ID = @CountProd))-- DISCADOS UNIQ
,												(SELECT COUNT(DISTINCT ID_CLIENTE)   
													FROM #TABULACAO 
														WHERE CE = 1 
															AND FAIXA_CONTRATANTE = 
																(SELECT FAIXA_CONTRATANTE FROM #TB_CONT WHERE NUM = @COUNT)
																	AND PRODUTO = (SELECT PRODUTO FROM #TESTE WHERE ID = @CountProd)) -- ALO UNIQ
,															(SELECT COUNT(DISTINCT ID_CLIENTE)  
														FROM #TABULACAO 
													WHERE CPC = 1 
												AND FAIXA_CONTRATANTE = 
											(SELECT FAIXA_CONTRATANTE FROM #TB_CONT WHERE NUM = @COUNT)
										AND PRODUTO = (SELECT PRODUTO FROM #TESTE WHERE ID = @CountProd))-- CPC UNIQ
,									(SELECT COUNT(1) 
								FROM #TABULACAO    
							WHERE AF = 1 
						AND FAIXA_CONTRATANTE = 
					(SELECT FAIXA_CONTRATANTE FROM #TB_CONT WHERE NUM = @COUNT)
				AND PRODUTO = (SELECT PRODUTO FROM #TESTE WHERE ID = @CountProd)) -- ACORDOS           
)

					IF(@COUNT = (SELECT MAX(NUM) FROM #TB_CONT ) AND @CountProd < (SELECT MAX(ID) FROM #TESTE ))
				SET @COUNT = 0 
			IF(@CountProd <= (SELECT MAX(ID) FROM #TESTE)  AND @COUNT = 0 )
		SET @CountProd = @CountProd + 1 
	SET @COUNT = @COUNT + 1 ---- FAIXA
END 
 END TRY
 	BEGIN CATCH
 		PRINT 'Erro número		: ' + convert(varchar, error_number());
 		PRINT 'Erro mensagem	: ' + error_message();
 		PRINT 'Erro severity	: ' + convert(varchar, error_severity());
 		PRINT 'Erro state		: ' + convert(varchar, error_state());
 		PRINT 'Erro line		: ' + convert(varchar, error_line());
 		PRINT 'Erro proc		: ' + error_procedure();
 	END CATCH;
 END
COMMIT TRANSACTION

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :			SELECT FINAL										     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

DELETE FROM TB_MIS_DAILY_PAGSEGURO
WHERE DATA		=	@DATA
AND   HORARIO	=	DATEPART(HH,GETDATE())


INSERT INTO TB_MIS_DAILY_PAGSEGURO
SELECT 
		DATA
,		FAIXA_CONTRATANTE
,		PRODUTO
,		HORARIO		=	DATEPART(HH,GETDATE())
,		DISCADO
,		ATEND_ESF
,		CPC_ESF
,		CPCA
,		OPERADORES
,		BOLETOS

FROM #DRAGON_BALL_FUSAO






