USE [EXITO]
GO


/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/*PROGRAMADOR: KAIKE NATAN                                                                                             */
/*VERSAO     : 1.0      DATA: 01/09/2021                                                                               */
/*DESCRICAO  : RESPONSAVEL POR FAZER AUDITORIA SOBRE AS ACÔES DO CONTROL DESK:										   */
/*			   DE CANAL, AGRESSIVIDADE E ROBÕS.  																	   */
/*			   																										   */
/*ALTERACAO                                                                                                            */
/*        2. PROGRAMADOR: KAIKE NATAN															     DATA: 03/09/2021  */
/*           DESCRICAO  : INCLUSÃO DAS CARTEIRAS, HORARIO E REPLACE PARA TRATAMENTO DAS COLUNAS	  					   */
/*																													   */
/*ALTERACAO                                                                                                            */
/*        3. PROGRAMADOR: 																		     DATA: __/__/____  */
/*           DESCRICAO  : 																					           */ 
/*																													   */                                                                                                                                         
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

  --ALTER PROCEDURE [dbo].[PRC_MIS_AUDITORIA_CONTROL] AS

  DECLARE @DATA AS DATE 
  SET @DATA	 = CAST(GETDATE() AS DATE)

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	PEGA AS ALTERAÇÕES DE CANAIS								     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

  IF OBJECT_ID('TEMPDB.DBO.#CANAL','U') IS NOT NULL
  DROP TABLE #CANAL 

  SELECT *
  into #CANAL
  FROM [EADMIN].[DBO].[SYSTEMHISTORY]
  WHERE CAST(MOMENT AS DATE) = @DATA
  AND LOCAL = 'CAMPAIGNS'
  AND ACTION  =	'MODIFIED'
  and COMMENT LIKE 'MaxPendingCalls%'
  order by Moment desc

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	PEGA AS ALTERAÇÕES DOS CANAIS YBR (ROBOS DA ANA POR CAMPANHA)    */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/  
  
  IF OBJECT_ID('TEMPDB.DBO.#ROBOS','U') IS NOT NULL
  DROP TABLE #ROBOS 

  SELECT *
  into #ROBOS
  FROM [EADMIN].[DBO].[SYSTEMHISTORY]
  WHERE CAST(MOMENT AS DATE) = @DATA
  AND LOCAL = 'CAMPAIGNS'
  AND ACTION  =	'MODIFIED'
  AND COMMENT LIKE 'MaxChannels%'
  order by Moment desc

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	PEGA AS ALTERAÇÕES DE AGRESSIVIDADE							     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

  IF OBJECT_ID('TEMPDB.DBO.#AGRESSIVIDADE','U') IS NOT NULL
  DROP TABLE #AGRESSIVIDADE 

  SELECT *
  into #AGRESSIVIDADE
  FROM [EADMIN].[DBO].[SYSTEMHISTORY]
  WHERE CAST(MOMENT AS DATE) = @DATA
  AND LOCAL = 'CAMPAIGNS'
  AND ACTION  =	'MODIFIED'
  AND COMMENT LIKE 'Aggressiveness%'
  order by Moment desc

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	CRIA TABELA DA FUSÃO										     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

IF OBJECT_ID('TEMPDB.DBO.#DRAGON_BALL_FUSAO', 'U') IS NOT NULL
DROP TABLE #DRAGON_BALL_FUSAO 
CREATE TABLE #DRAGON_BALL_FUSAO		
									(			
										[Sid] [char](8)  NOT NULL,
										[Module] [varchar](100) NULL,
										[Local] [varchar](255) NULL,
										[Action] [varchar](100) NULL,
										[ActionSid] [varchar](100) NULL,
										[Moment] [datetime] NULL,
										[OriginatorID] [varchar](100) NULL,
										[OriginatorType] [char](1) NULL,
										[Comment] [varchar](max) NULL,
									)												

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	UNON ALL DAS 3 TABELAS ACIMA								     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

INSERT INTO #DRAGON_BALL_FUSAO

SELECT *
FROM #CANAL

UNION ALL

SELECT *
FROM #ROBOS

UNION ALL

SELECT *
FROM #AGRESSIVIDADE

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	SEPARA POR CAMPANHA											     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

IF OBJECT_ID('TEMPDB.DBO.#CAMPANHAS','U') IS NOT NULL
DROP TABLE #CAMPANHAS 	
  SELECT 
		DBZ.*,
		CAMPANHA = CP.Description

  INTO #CAMPANHAS
  FROM #DRAGON_BALL_FUSAO DBZ
  INNER JOIN 
		EADMIN..Campaigns CP
ON (DBZ.ActionSid	=	CP.Sid)

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	MODELAGEM DOS NOMES											     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

IF OBJECT_ID('TEMPDB.DBO.#MODELAGEM','U') IS NOT NULL
DROP TABLE #MODELAGEM 	
  SELECT 
 		Sid
,		TIPO_USUARIO		=		Module
,		LOCAL_ALTERACAO		=		Local
,		ACAO_REALIZADA		=		Action
,		SID_DA_ACAO			=		ActionSid
,		CAMPANHA
,		HORARIO				=		Moment
,		USUARIO				=		OriginatorID
,		DS_ACAO				=		Comment

  INTO #MODELAGEM
  FROM #CAMPANHAS

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	PEGA A PRIMEIRA E ULTIMA ATUALIZAÇÃO ATUAL,						 */
/*				CADA VEZ QUE RODA A PROCEDURE É CLARO						     */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

IF OBJECT_ID('TEMPDB.DBO.#HR_ATUALIZACAO','U') IS NOT NULL
DROP TABLE #HR_ATUALIZACAO  
  SELECT 
		SID_DA_ACAO		
, 		ULT_ATUALIZACAO		=		MAX(HORARIO)
,		PRI_ATUALIZACAO		=		MIN(HORARIO)
INTO #HR_ATUALIZACAO
FROM #MODELAGEM
	GROUP BY 
			SID_DA_ACAO

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	SEPARA O QUE É CANAL, ROTA E AGRESSIVIDADE						 */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

IF OBJECT_ID('TEMPDB.DBO.#INNER','U') IS NOT NULL
DROP TABLE #INNER  
  SELECT				
		TIPO_USUARIO		
,		LOCAL_ALTERACAO		
,		ACAO_REALIZADA		
,		SID_DA_ACAO	
,		USUARIO	
,		DS_ACAO
,		TP_ALTERACAO	= 
						  CASE  
								WHEN SUBSTRING(DS_ACAO,1,11) = 'MaxChannels'		 THEN	'ROBO'		
								WHEN SUBSTRING(DS_ACAO,1,15) = 'MaxPendingCalls'	 THEN	'CANAL' 
								WHEN SUBSTRING(DS_ACAO,1,14) = 'Aggressiveness'		 THEN	'AGRESSIVIDADE' 
						  END
,		CAMPANHA		
,		HORARIO							
,		PRI_ATUALIZACAO =   CAST(NULL AS datetime)	
,		ULT_ATUALIZACAO =	CAST(NULL AS datetime)			
,		DE				=	SUBSTRING(DS_ACAO,1,20)   -- 1,20
,		PARA			=	SUBSTRING(DS_ACAO,22,09)  -- 22,10

  INTO #INNER	
  FROM #MODELAGEM
  ORDER BY SID_DA_ACAO

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	PEGA AS ATUALIZAÇÕES DOS USUARIOS DO CONTROL					 */
/*																				 */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

    UPDATE #INNER
  SET ULT_ATUALIZACAO	=	HR.ULT_ATUALIZACAO
,	  PRI_ATUALIZACAO	=	HR.PRI_ATUALIZACAO

FROM #INNER A
INNER JOIN
	 #HR_ATUALIZACAO HR 
ON (A.SID_DA_ACAO	=	HR.SID_DA_ACAO)

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	PIVOT PARA MELHOR VISUALIZAÇÃO									 */
/*																				 */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

/*IF OBJECT_ID('TEMPDB.DBO.#FINAL','U') IS NOT NULL
DROP TABLE #FINAL 
SELECT 
		TIPO_USUARIO		
,		LOCAL_ALTERACAO		
,		ACAO_REALIZADA		
,		SID_DA_ACAO	
,		DS_ACAO
,		CAMPANHA		
,		HR_ALTERACAO		=	HORARIO							
,		[ALTERACAO_ROBO]
,		[ALTERACAO_CANAL]
,		[ALTERACAO_AGRESSIVIDADE]
,		PRI_ATUALIZACAO 	
,		ULT_ATUALIZACAO 	
	
INTO #FINAL
FROM #INNER
PIVOT	(
		MAX(USUARIO) FOR ALTERACAO_ROTA IN (
				
					([ALTERACAO_ROBO],[ALTERACAO_CANAL],[ALTERACAO_AGRESSIVIDADE]) 
				)
		) PVT*/

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/*		DESCRICAO  :					FAZ A MODELAGEM DA TABELA FINAL										   */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

IF OBJECT_ID('TEMPDB.DBO.#FINAL','U') IS NOT NULL
DROP TABLE #FINAL 
SELECT	
		SID_DA_ACAO
,		CARTEIRA = 
			             CASE	WHEN CAMPANHA  =	'ANA_BIGDATA_IA_CARREFOUR_G1'				THEN 'CAR-G1' 
						        WHEN CAMPANHA  =	'URA_NOVOS_NEGOCIOS_CARREFOUR'				THEN 'CAR-G1' 
								WHEN CAMPANHA  =	'G1_CARREFOUR'								THEN 'CAR-G1'
								WHEN CAMPANHA  =	'CARREFOUR'									THEN 'CAR-G1'
						        WHEN CAMPANHA  =	'ANA_BIGDATA_CARREFOURG2'					THEN 'CAR-G2'
								WHEN CAMPANHA  =	'G2_CARREFOUR_PERDA'						THEN 'CAR-G2' 							
								WHEN CAMPANHA  =	'G2_CARREFOUR_REATIVADA'					THEN 'CAR-G2'
								WHEN CAMPANHA  =    'ANA_BIGDATA_LOJA_CARREFOUR'                THEN 'CARREFOUR-LOJA'
								WHEN CAMPANHA  =	'MANUTENCAO_G1'								THEN 'MANUTENCAO-G1'
								WHEN CAMPANHA  =	'ANA_NOVOS_NEGOCIOS_ATACADAO'				THEN 'ATACADAO-G1'
								WHEN CAMPANHA  =	'ANA_NOVOS_NEGOCIOS_G2_ATACADAO'			THEN 'ATACADAO-G2' 
								WHEN CAMPANHA  =	'AVON'										THEN 'AVON' 
								WHEN CAMPANHA  =    'ANA_BIGDATA_CPC_AVON_PREVENTIVO'           THEN 'AVON'
								WHEN CAMPANHA  =	'DESC_AVON'									THEN 'AVON' 
								WHEN CAMPANHA  =    'PREVENTIVO_AVON'							THEN 'AVON'
								WHEN CAMPANHA  =	'ANA_BIGDATA_CPC_AVON_WHATSAPP'				THEN 'AVON' 		
								WHEN CAMPANHA  =	'ANA_NOVOS_NEGOCIOS_AVON'					THEN 'AVON'
								WHEN CAMPANHA  =	'MANUTENCAO_AVON'					        THEN 'MANUTENCAO-AVON'
								WHEN CAMPANHA  =	'ANA_BIGDATA_CPC_NATURA'					THEN 'NATURA'
								WHEN CAMPANHA  =	'ANA_BIGDATA_IA_NATURA'						THEN 'NATURA'
								WHEN CAMPANHA  =	'ANA_ NATURA_IA'							THEN 'NATURA'
								WHEN CAMPANHA  =    'NATURA'									THEN 'NATURA'
								WHEN CAMPANHA  =    'PREVENTIVO_NATURA'                         THEN 'NATURA'
								WHEN CAMPANHA  =	'ESTRELA_AVON'								THEN 'ESTRELA'
								WHEN CAMPANHA  =	'ANA_BIGDATA_CPC_ENERGISA'					THEN 'ENERGISA'
								WHEN CAMPANHA  =    'ANA_BIGDATA_CPC_SOUDI'						THEN 'SOUDI' 
								WHEN CAMPANHA  =    'ANA_BIGDATA_IA_SOUDI'						THEN 'SOUDI' 
								WHEN CAMPANHA  =    'Ana - Soudi - Menor 64'					THEN 'SOUDI'
								WHEN CAMPANHA  =    'RENNER_PREVENTIVO'							THEN 'RENNER'
								WHEN CAMPANHA  =    'ANA_BIGDATA_CPC_RENNER_ESCOB2'				THEN 'RENNER'
								WHEN CAMPANHA  =    'ANA_BIGDATA_SMS_YAMAHA'					THEN 'YAMAHA'
								WHEN CAMPANHA  =    'URA_NOVOS_NEGOCIOS_YAMAHA_TELECOBRANCA'	THEN 'YAMAHA-TELE'
								WHEN CAMPANHA  =    'YAMAHA_TELECOBRANCA'						THEN 'YAMAHA-TELE'
								WHEN CAMPANHA  =    'ATIVOS_G1'									THEN 'ATIVOS-G1'
								WHEN CAMPANHA  =    'ATIVOS_G2_EXITO'							THEN 'ATIVOS-G2_EXITO'
								WHEN CAMPANHA  =    'ATIVOS_G2'									THEN 'ATIVOS-G2'
								WHEN CAMPANHA  =    'ANA_BIGDATA_CPC_UOL'						THEN 'UOL'
								WHEN CAMPANHA  =    'COB_UOL'								    THEN 'UOL'
								WHEN CAMPANHA  =    'ANA_BIGDATA_CPC_PAGSEGURO'				    THEN 'PAGSEGURO'
								WHEN CAMPANHA  =    'ANA_BIGDATA_PREV_PAGSEGURO'				THEN 'PAGSEGURO'
								WHEN CAMPANHA  =    'ANA_BIGDATA_CPC_OMNI_REPASSE'			    THEN 'OMNI_REPASSE'
								WHEN CAMPANHA  =    'ANA_BIGDATA_CPC_OMNI_HONORARIOS'			THEN 'OMNI_HONORARIO'
								WHEN CAMPANHA  =    'ANA_BIGDATA_CPC_OMNI'						THEN 'OMNI'
								WHEN CAMPANHA  =    'ANA_BIGDATA_IA_OMNI'						THEN 'OMNI'
								WHEN CAMPANHA  =    'OMNI_PREVENTIVO'							THEN 'OMNI'
								WHEN CAMPANHA  =    'ANA_BIGDATA_CPC_WILL_BANK'					THEN 'WILL_BANK'
								WHEN CAMPANHA  =    'ANA_BIGDATA_IA_WILLBANK'					THEN 'WILL_BANK'
								WHEN CAMPANHA  =    'WILLBANK_PREVENTIVO'						THEN 'WILL_BANK'
								WHEN CAMPANHA  =    'MANUAL_WILLBANK'							THEN 'WILL_BANK'
								WHEN CAMPANHA  =	'ANA_BIGDATA_SMS_OFFLINE'					THEN 'ANA'		
								WHEN CAMPANHA LIKE  '%Teste%'									THEN 'DESATIVADO'
								WHEN CAMPANHA LIKE  '%TesteDEV%'								THEN 'DESATIVADO'
								WHEN CAMPANHA LIKE  '%URA_NOVOS_NEGOCIOS_EXITO%'				THEN 'DESATIVADO'
								WHEN CAMPANHA LIKE  '%URA_NOVOS_NEGOCIOS_G2_EXITO%'				THEN 'DESATIVADO'
								WHEN CAMPANHA LIKE  '%URA_PREVENTIVA%'							THEN 'DESATIVADO'
								ELSE 'NI' 
						 END
,		CAMPANHA
,		USUARIO			=	UPPER(USUARIO)
,		TP_ALTERACAO
,		HORARIO		
,		DATA			=	CAST(HORARIO AS date)
,		HR				=	DATEPART(HH,HORARIO)
,		DS_ACAO			=	SUBSTRING(DS_ACAO,1,50)

,		DE				=	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DE,
							'MaxPendingCalls',''),'-->',''),'[',''),']',''),'MaxChannels',''),
							'Aggressiveness',''),' ',''),'--','')

,		PARA			=	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
						    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PARA,
							'-->',''),'[',''),']',''),'holid',''),'Access',''),'Gram',''),'g',''),
							'gramm',''),'a',''),'call f',''),'|',''),'cllf',''),'mxp',''),'->',''),
							'cces',''),'m',''),'r',''),' ',''),'fcto',''),'stt',''),'sttu',''),'x',''),
							'dilty',''),'pio',''),'p',''),'e',''),'i',''),'witt',''),'Wtt',''),'d',''),
							'blc',''),'u',''),'cc',''),'dit',''),'N',''),'vs',''),'fct',''),'II',''),
							'I',''),'Hol',''),'Wt',''),'Wt',''),'lT',''),'s',''),'Cll',''),'O',''),'k','')
,		PRI_ATUALIZACAO		
,		ULT_ATUALIZACAO
INTO #FINAL	
FROM #INNER	

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  : FAZ A MODELAGEM DA TAB FINAL DE ROBO, CANL E AGRESSIVISADE PRO INSERT COM A DE ROTAS	   */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

IF OBJECT_ID('TEMPDB.DBO.#END','U') IS NOT NULL
DROP TABLE #END
SELECT
		CAMPANHA
,		CARTEIRA
,		USUARIO
,		TP_ALTERACAO
,		DE
,		PARA
,		DATA
,		HR
,		HORARIO
,		PRI_ATUALIZACAO
,		ULT_ATUALIZACAO
INTO #END
FROM #FINAL
ORDER BY 
		DATA DESC

/************************************************************ INICIO DA TABELA DE ROTAS ****************************************************/

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	PEGA AS ALTERAÇÕES DE CANAIS									 */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

IF OBJECT_ID('TEMPDB.DBO.#ROTAS','U') IS NOT NULL
DROP TABLE #ROTAS 

SELECT 
     B.DESCRIPTION
    ,A.* 
    ,ACCESSLINEDE	= SUBSTRING(COMMENT,CHARINDEX('ACCESSLINESID',COMMENT)+15,8)
    ,ACCESSLINEPARA = SUBSTRING(COMMENT,CHARINDEX('ACCESSLINESID',COMMENT)+30,8)

INTO #ROTAS
FROM EADMIN..SYSTEMHISTORY A WITH(NOLOCK)
INNER JOIN EADMIN..CAMPAIGNS B WITH(NOLOCK) ON A.ACTIONSID = B.SID
WHERE 
    CAST(MOMENT AS DATE) = @DATA
    AND COMMENT LIKE '%ACCESSLINESID%' 

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	FAZ A MODELAGEM PRO INSERT COM A TABELA FINAL					 */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

IF OBJECT_ID('TEMPDB.DBO.#FINAL_ROTAS','U') IS NOT NULL
DROP TABLE #FINAL_ROTAS 
SELECT 
	 CAMPANHA		=	 A.DESCRIPTION 
    ,CARTEIRA		= 
			             CASE	
								WHEN A.DESCRIPTION   =	'ANA_BIGDATA_IA_CARREFOUR_G1'				THEN 'CAR-G1' 
						        WHEN A.DESCRIPTION   =	'URA_NOVOS_NEGOCIOS_CARREFOUR'				THEN 'CAR-G1' 
								WHEN A.DESCRIPTION   =	'G1_CARREFOUR'								THEN 'CAR-G1'
								WHEN A.DESCRIPTION   =	'CARREFOUR'									THEN 'CAR-G1'
						        WHEN A.DESCRIPTION   =	'ANA_BIGDATA_CARREFOURG2'					THEN 'CAR-G2'
								WHEN A.DESCRIPTION   =	'G2_CARREFOUR_PERDA'						THEN 'CAR-G2' 							
								WHEN A.DESCRIPTION   =	'G2_CARREFOUR_REATIVADA'					THEN 'CAR-G2'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_LOJA_CARREFOUR'				THEN 'CARREFOUR-LOJA'
								WHEN A.DESCRIPTION   =	'MANUTENCAO_G1'								THEN 'MANUTENCAO-G1'
								WHEN A.DESCRIPTION   =	'ANA_NOVOS_NEGOCIOS_ATACADAO'				THEN 'ATACADAO-G1'
								WHEN A.DESCRIPTION   =	'ANA_NOVOS_NEGOCIOS_G2_ATACADAO'			THEN 'ATACADAO-G2' 
								WHEN A.DESCRIPTION   =	'AVON'										THEN 'AVON' 
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_AVON_PREVENTIVO'			THEN 'AVON'
								WHEN A.DESCRIPTION   =	'DESC_AVON'									THEN 'AVON' 
								WHEN A.DESCRIPTION   =  'PREVENTIVO_AVON'							THEN 'AVON'
								WHEN A.DESCRIPTION   =	'ANA_BIGDATA_CPC_AVON_WHATSAPP'				THEN 'AVON' 		
								WHEN A.DESCRIPTION   =	'ANA_NOVOS_NEGOCIOS_AVON'					THEN 'AVON'
								WHEN A.DESCRIPTION   =	'Ana - Avon_NN'								THEN 'AVON'
								WHEN A.DESCRIPTION   =	'MANUTENCAO_AVON'					        THEN 'MANUTENCAO-AVON'
								WHEN A.DESCRIPTION   =	'ANA_BIGDATA_CPC_NATURA'					THEN 'NATURA'
								WHEN A.DESCRIPTION   =	'Ana - Natura_NN'							THEN 'NATURA'
								WHEN A.DESCRIPTION   =	'ANA_BIGDATA_IA_NATURA'						THEN 'NATURA'
								WHEN A.DESCRIPTION   =	'ANA_ NATURA_IA'							THEN 'NATURA'
								WHEN A.DESCRIPTION   =  'NATURA'									THEN 'NATURA'
								WHEN A.DESCRIPTION   =  'PREVENTIVO_NATURA'							THEN 'NATURA'
								WHEN A.DESCRIPTION   =	'ESTRELA_AVON'								THEN 'ESTRELA'
								WHEN A.DESCRIPTION   =	'ANA_BIGDATA_CPC_ENERGISA'					THEN 'ENERGISA'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_SOUDI'						THEN 'SOUDI' 
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_IA_SOUDI'						THEN 'SOUDI' 
								WHEN A.DESCRIPTION   =  'Ana - Soudi - Menor 64'					THEN 'SOUDI' 
								WHEN A.DESCRIPTION   =  'RENNER_PREVENTIVO'							THEN 'RENNER'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_RENNER_ESCOB2'				THEN 'RENNER'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_SMS_YAMAHA'					THEN 'YAMAHA'
								WHEN A.DESCRIPTION   =  'URA_NOVOS_NEGOCIOS_YAMAHA_TELECOBRANCA'	THEN 'YAMAHA-TELE'
								WHEN A.DESCRIPTION   =  'YAMAHA_TELECOBRANCA'						THEN 'YAMAHA-TELE'
								WHEN A.DESCRIPTION   =  'ATIVOS_G1'									THEN 'ATIVOS-G1'
								WHEN A.DESCRIPTION   =  'ATIVOS_G2_EXITO'							THEN 'ATIVOS-G2_EXITO'
								WHEN A.DESCRIPTION   =  'ATIVOS_G2'									THEN 'ATIVOS-G2'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_UOL'						THEN 'UOL'
								WHEN A.DESCRIPTION   =  'COB_UOL'								    THEN 'UOL'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_PAGSEGURO'					THEN 'PAGSEGURO'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_PREV_PAGSEGURO'				THEN 'PAGSEGURO'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_OMNI_REPASSE'				THEN 'OMNI_REPASSE'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_OMNI_HONORARIOS'			THEN 'OMNI_HONORARIO'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_OMNI'						THEN 'OMNI'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_IA_OMNI'						THEN 'OMNI'
								WHEN A.DESCRIPTION   =  'OMNI_PREVENTIVO'							THEN 'OMNI'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_WILL_BANK'					THEN 'WILL_BANK'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_IA_WILLBANK'					THEN 'WILL_BANK'
								WHEN A.DESCRIPTION   =  'WILLBANK_PREVENTIVO'						THEN 'WILL_BANK'
								WHEN A.DESCRIPTION   =  'MANUAL_WILLBANK'							THEN 'WILL_BANK'
								WHEN A.DESCRIPTION   =	'ANA_BIGDATA_SMS_OFFLINE'					THEN 'ANA'		
								WHEN A.DESCRIPTION  LIKE '%Teste%'									THEN 'DESATIVADO'
								WHEN A.DESCRIPTION  LIKE '%TesteDEV%'								THEN 'DESATIVADO'
								WHEN A.DESCRIPTION  LIKE '%URA_NOVOS_NEGOCIOS_EXITO%'				THEN 'DESATIVADO'
								WHEN A.DESCRIPTION  LIKE '%URA_NOVOS_NEGOCIOS_G2_EXITO%'			THEN 'DESATIVADO'
								WHEN A.DESCRIPTION  LIKE '%URA_PREVENTIVA%'							THEN 'DESATIVADO'
								ELSE 'NI' 
						END

	,USUARIO			=	A.ORIGINATORID
	,TP_ALTERAÇÃO		=  'ROTA'
    ,DE					=	B.LINEID
    ,PARA				=	C.LINEID
    ,DATA				=	CAST(A.MOMENT AS DATE)
	,HR					=	DATEPART(HH,A.MOMENT)
	,HORARIO			=	A.MOMENT
	,PRI_ATUALIZACAO	=   MIN(A.MOMENT)
	,ULT_ATUALIZACAO	=	MAX(A.MOMENT)
INTO #FINAL_ROTAS
FROM #ROTAS A 
INNER JOIN eadmin..AccessLine B WITH(NOLOCK) ON A.ACCESSLINEDE	 = B.SID
INNER JOIN eadmin..AccessLine C WITH(NOLOCK) ON A.ACCESSLINEPARA = C.SID
GROUP BY
		A.DESCRIPTION,
						CASE	
								WHEN A.DESCRIPTION   =	'ANA_BIGDATA_IA_CARREFOUR_G1'				THEN 'CAR-G1' 
						        WHEN A.DESCRIPTION   =	'URA_NOVOS_NEGOCIOS_CARREFOUR'				THEN 'CAR-G1' 
								WHEN A.DESCRIPTION   =	'G1_CARREFOUR'								THEN 'CAR-G1'
								WHEN A.DESCRIPTION   =	'CARREFOUR'									THEN 'CAR-G1'
						        WHEN A.DESCRIPTION   =	'ANA_BIGDATA_CARREFOURG2'					THEN 'CAR-G2'
								WHEN A.DESCRIPTION   =	'G2_CARREFOUR_PERDA'						THEN 'CAR-G2' 							
								WHEN A.DESCRIPTION   =	'G2_CARREFOUR_REATIVADA'					THEN 'CAR-G2'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_LOJA_CARREFOUR'				THEN 'CARREFOUR-LOJA'
								WHEN A.DESCRIPTION   =	'MANUTENCAO_G1'								THEN 'MANUTENCAO-G1'
								WHEN A.DESCRIPTION   =	'ANA_NOVOS_NEGOCIOS_ATACADAO'				THEN 'ATACADAO-G1'
								WHEN A.DESCRIPTION   =	'ANA_NOVOS_NEGOCIOS_G2_ATACADAO'			THEN 'ATACADAO-G2' 
								WHEN A.DESCRIPTION   =	'AVON'										THEN 'AVON' 
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_AVON_PREVENTIVO'			THEN 'AVON'
								WHEN A.DESCRIPTION   =	'DESC_AVON'									THEN 'AVON' 
								WHEN A.DESCRIPTION   =  'PREVENTIVO_AVON'							THEN 'AVON'
								WHEN A.DESCRIPTION   =	'ANA_BIGDATA_CPC_AVON_WHATSAPP'				THEN 'AVON' 		
								WHEN A.DESCRIPTION   =	'ANA_NOVOS_NEGOCIOS_AVON'					THEN 'AVON'
								WHEN A.DESCRIPTION   =	'Ana - Avon_NN'								THEN 'AVON'
								WHEN A.DESCRIPTION   =	'MANUTENCAO_AVON'					        THEN 'MANUTENCAO-AVON'
								WHEN A.DESCRIPTION   =	'ANA_BIGDATA_CPC_NATURA'					THEN 'NATURA'
								WHEN A.DESCRIPTION   =	'Ana - Natura_NN'							THEN 'NATURA'
								WHEN A.DESCRIPTION   =	'ANA_BIGDATA_IA_NATURA'						THEN 'NATURA'
								WHEN A.DESCRIPTION   =	'ANA_ NATURA_IA'							THEN 'NATURA'
								WHEN A.DESCRIPTION   =  'NATURA'									THEN 'NATURA'
								WHEN A.DESCRIPTION   =  'PREVENTIVO_NATURA'							THEN 'NATURA'
								WHEN A.DESCRIPTION   =	'ESTRELA_AVON'								THEN 'ESTRELA'
								WHEN A.DESCRIPTION   =	'ANA_BIGDATA_CPC_ENERGISA'					THEN 'ENERGISA'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_SOUDI'						THEN 'SOUDI' 
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_IA_SOUDI'						THEN 'SOUDI' 
								WHEN A.DESCRIPTION   =  'Ana - Soudi - Menor 64'					THEN 'SOUDI'
								WHEN A.DESCRIPTION   =  'RENNER_PREVENTIVO'							THEN 'RENNER'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_RENNER_ESCOB2'				THEN 'RENNER'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_SMS_YAMAHA'					THEN 'YAMAHA'
								WHEN A.DESCRIPTION   =  'URA_NOVOS_NEGOCIOS_YAMAHA_TELECOBRANCA'	THEN 'YAMAHA-TELE'
								WHEN A.DESCRIPTION   =  'YAMAHA_TELECOBRANCA'						THEN 'YAMAHA-TELE'
								WHEN A.DESCRIPTION   =  'ATIVOS_G1'									THEN 'ATIVOS-G1'
								WHEN A.DESCRIPTION   =  'ATIVOS_G2_EXITO'							THEN 'ATIVOS-G2_EXITO'
								WHEN A.DESCRIPTION   =  'ATIVOS_G2'									THEN 'ATIVOS-G2'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_UOL'						THEN 'UOL'
								WHEN A.DESCRIPTION   =  'COB_UOL'								    THEN 'UOL'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_PAGSEGURO'					THEN 'PAGSEGURO'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_PREV_PAGSEGURO'				THEN 'PAGSEGURO'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_OMNI_REPASSE'				THEN 'OMNI_REPASSE'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_OMNI_HONORARIOS'			THEN 'OMNI_HONORARIO'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_OMNI'						THEN 'OMNI'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_IA_OMNI'						THEN 'OMNI'
								WHEN A.DESCRIPTION   =  'OMNI_PREVENTIVO'							THEN 'OMNI'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_CPC_WILL_BANK'					THEN 'WILL_BANK'
								WHEN A.DESCRIPTION   =  'ANA_BIGDATA_IA_WILLBANK'					THEN 'WILL_BANK'
								WHEN A.DESCRIPTION   =  'WILLBANK_PREVENTIVO'						THEN 'WILL_BANK'
								WHEN A.DESCRIPTION   =  'MANUAL_WILLBANK'							THEN 'WILL_BANK'
								WHEN A.DESCRIPTION   =	'ANA_BIGDATA_SMS_OFFLINE'					THEN 'ANA'		
								WHEN A.DESCRIPTION  LIKE '%Teste%'									THEN 'DESATIVADO'
								WHEN A.DESCRIPTION  LIKE '%TesteDEV%'								THEN 'DESATIVADO'
								WHEN A.DESCRIPTION  LIKE '%URA_NOVOS_NEGOCIOS_EXITO%'				THEN 'DESATIVADO'
								WHEN A.DESCRIPTION  LIKE '%URA_NOVOS_NEGOCIOS_G2_EXITO%'			THEN 'DESATIVADO'
								WHEN A.DESCRIPTION  LIKE '%URA_PREVENTIVA%'							THEN 'DESATIVADO'
								ELSE 'NI' 
						END,
			A.ORIGINATORID,
  			B.LINEID,
    		C.LINEID,
    		CAST(A.MOMENT AS DATE),
			DATEPART(HH,A.MOMENT),
			A.MOMENT

ORDER BY MOMENT DESC 

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	CRIA TABELA FINAL MODELADA E COM TODAS AS INFORMAÇÕES			 */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

IF OBJECT_ID('TEMPDB.DBO.#FINALMENTE_ACABOU', 'U') IS NOT NULL
DROP TABLE   #FINALMENTE_ACABOU 
CREATE TABLE #FINALMENTE_ACABOU	
									(			
										[Campanha] [varchar](100)  NOT NULL,
										[Carteira] [varchar](100) NULL,
										[Usuario] [varchar](255) NULL,
										[Tp_Alteracao] [varchar](100) NULL,
										[De] [varchar](100) NULL,
										[Para] [varchar] (100) NULL,
										[Data] [date] NULL,
										[Hr] [char](2) NULL,
										[Horario] [datetime] NULL,
										[Pri_Atualizacao] [datetime] null,
										[Ult_Atualizacao] [datetime] null
									)

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	UNIFICAÇÃO DAS 2 TABELAS FINAIS	E SELECT						 */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

INSERT INTO #FINALMENTE_ACABOU

SELECT *
FROM #END

UNION ALL

SELECT *
FROM #FINAL_ROTAS

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	TABELA SINTÉTICA FINAL COM TODAS AS VISÕES						 */
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/ 

DELETE FROM [172.20.1.66].[DB_REPORT].[DBO].[TB_REL_AUDITORIA_CONTROL]
WHERE DATA = @DATA

INSERT INTO [172.20.1.66].[DB_REPORT].[DBO].[TB_REL_AUDITORIA_CONTROL]
SELECT
		CAMPANHA
,		CARTEIRA
,		USUARIO			=	UPPER(USUARIO)
,		TP_ALTERACAO
,		DE
,		PARA
,		DATA
,		HR
,		HORARIO
,		PRI_ATUALIZACAO
,		ULT_ATUALIZACAO
FROM #FINALMENTE_ACABOU
ORDER BY 
		DATA DESC





