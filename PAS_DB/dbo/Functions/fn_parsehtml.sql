CREATE FUNCTION [dbo].[fn_parsehtml] 
(
	@htmldesc VARCHAR(MAX)
) 
RETURNS VARCHAR(MAX)
AS
BEGIN
	DECLARE @first INT, @last INT,@len INT 
	SET @first = CHARINDEX('<',@htmldesc) 
	SET @last = CHARINDEX('>',@htmldesc,CHARINDEX('<',@htmldesc)) 
	SET @len = (@last - @first) + 1 
	WHILE @first > 0 AND @last > 0 AND @len > 0 
	BEGIN 
	---Stuff function is used to insert string at given position and delete number of characters specified from original string
	SET @htmldesc = STUFF(@htmldesc,@first,@len,'')  
	SET @first = CHARINDEX('<',@htmldesc) 
	SET @last = CHARINDEX('>',@htmldesc,CHARINDEX('<',@htmldesc)) 
	SET @len = (@last - @first) + 1 
	END 
	RETURN LTRIM(RTRIM(@htmldesc)) 
END