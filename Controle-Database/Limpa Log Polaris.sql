
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/*																								*/
/* PROGRAMADOR: KAIKE NATAN									                                    */
/* VERSAO     : DATA: 27/01/2022																*/
/* DESCRICAO  : SCRIP DE LIMPAR LOG DA INSTANCIA DO POLARIS							  		    */
/*																								*/
/*	ALTERACAO                                                                                   */
/*        2. PROGRAMADOR:													 DATA: __/__/____	*/		
/*           DESCRICAO  :										 								*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	PARA OBTER O NOME DO ARQUIVO DE DADOS E DE LOG DO BANCO DE DADOS ESPEC�FICO		*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
	SELECT * 
	FROM SYSFILES  
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	MUDA O BACKUP DO BANCO PARA SIMPLES												*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
	ALTER DATABASE DW_RIACHUELO
	SET RECOVERY SIMPLE
	GO
	ALTER DATABASE DW_RoboRiachuelo
	SET RECOVERY SIMPLE
	GO
	ALTER DATABASE NectarTeste
	SET RECOVERY SIMPLE
	GO
	ALTER DATABASE Planning
	SET RECOVERY SIMPLE
	GO
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	TRUNCA OS ARQUIVOS DE LOG DA INSTANCIA											*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
	DBCC SHRINKFILE ('DW_RIACHUELO_log', 1,TRUNCATEONLY);				
	GO
	DBCC SHRINKFILE ('DW_RoboRiachuelo_log', 1,TRUNCATEONLY);				
	GO
	DBCC SHRINKFILE ('Nectar_Log', 1,TRUNCATEONLY);				
	GO
	DBCC SHRINKFILE ('Planning_Log', 1,TRUNCATEONLY);				
	GO
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/* DESCRICAO  :	MUDA O BACKUP DO BANCO PARA FULL NOVAMENTE										*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
	ALTER DATABASE DW_RIACHUELO
	SET RECOVERY FULL
	GO
	ALTER DATABASE DW_RoboRiachuelo
	SET RECOVERY FULL
	GO
	ALTER DATABASE NectarTeste
	SET RECOVERY FULL
	GO
	ALTER DATABASE Planning
	SET RECOVERY FULL
	GO