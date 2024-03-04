
ALTER  FUNCTION [dbo].[ConverteSegundosEmHoras](@Segundos int) 
RETURNS VARCHAR(10) AS 
BEGIN 
DECLARE @StrHora VARCHAR(50) 
DECLARE @x INT
SET @x =(@Segundos / 3600)
IF LEN(@x) =3 
SELECT @StrHora =  RIGHT('00' + CAST((@Segundos / 3600) AS VARCHAR),3), @StrHora = @StrHora + ':' + RIGHT('00' + CAST((@Segundos %3600)/60 AS VARCHAR), 2), 
@StrHora = @StrHora + ':' + RIGHT('00' + CAST((@Segundos %3600)%60 AS VARCHAR), 2)
ELSE IF Len(@x) >3
SELECT @StrHora =  RIGHT('00' + CAST((@Segundos / 3600) AS VARCHAR),4), @StrHora = @StrHora + ':' + RIGHT('00' + CAST((@Segundos %3600)/60 AS VARCHAR), 2), 
@StrHora = @StrHora + ':' + RIGHT('00' + CAST((@Segundos %3600)%60 AS VARCHAR), 2)
ELSE 
SELECT @StrHora =  RIGHT('00' + CAST((@Segundos / 3600) AS VARCHAR),2), @StrHora = @StrHora + ':' + RIGHT('00' + CAST((@Segundos %3600)/60 AS VARCHAR), 2), 
@StrHora = @StrHora + ':' + RIGHT('00' + CAST((@Segundos %3600)%60 AS VARCHAR), 2)
RETURN @StrHora 
END
