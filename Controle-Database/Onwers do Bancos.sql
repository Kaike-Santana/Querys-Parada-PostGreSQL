

SELECT 
		D.database_id
,		D.NAME
,		SUSER_SNAME(D.OWNER_SID) AS OWNER
,		D.USER_ACCESS_DESC
,		D.COMPATIBILITY_LEVEL
FROM SYS.DATABASES AS D







EXEC SP_HELPDB 'teste'



EXEC SP_CHANGEDBOWNER 'CMD'