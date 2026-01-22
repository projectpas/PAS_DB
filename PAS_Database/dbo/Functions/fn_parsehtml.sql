
/*************************************************************
 ** File:   [fn_parsehtml]
 ** Author:   N/A
 ** Description: This Function is used to Remove HTML Tag from Notes And Memo.
 ** Purpose:
 ** Date:   N/A

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date           Author			    Change Description
 ** --   --------       -------			    --------------------------------
    1    N/A            N/A		            Created
	2    22-Jan-2026    Divyesh Kathiriya   Handle HTML ENTITIES

**************************************************************/

--ALTER FUNCTION [dbo].[fn_parsehtml] 
--(
--	@htmldesc VARCHAR(MAX)
--) 
--RETURNS VARCHAR(MAX)
--AS
--BEGIN
--	DECLARE @first INT, @last INT,@len INT 
--	SET @first = CHARINDEX('<',@htmldesc) 
--	SET @last = CHARINDEX('>',@htmldesc,CHARINDEX('<',@htmldesc)) 
--	SET @len = (@last - @first) + 1 
--	WHILE @first > 0 AND @last > 0 AND @len > 0 
--	BEGIN 
--	---Stuff function is used to insert string at given position and delete number of characters specified from original string
--	SET @htmldesc = STUFF(@htmldesc,@first,@len,'')  
--	SET @first = CHARINDEX('<',@htmldesc) 
--	SET @last = CHARINDEX('>',@htmldesc,CHARINDEX('<',@htmldesc)) 
--	SET @len = (@last - @first) + 1 
--	END 
--	RETURN LTRIM(RTRIM(@htmldesc)) 
--END


CREATE FUNCTION [dbo].[fn_parsehtml]
(
    @htmlDesc NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE 
        @first INT,
        @last INT,
        @len INT;

    IF (@htmlDesc IS NULL)
    BEGIN
        RETURN NULL;
    END

    /* -------------------------------
       STEP 1: Remove HTML TAGS
    --------------------------------*/
    SET @first = CHARINDEX('<', @htmlDesc);
    SET @last  = CHARINDEX('>', @htmlDesc, @first);

    WHILE (@first > 0 AND @last > @first)
    BEGIN
        SET @len = (@last - @first) + 1;
        SET @htmlDesc = STUFF(@htmlDesc, @first, @len, '');
        SET @first = CHARINDEX('<', @htmlDesc);
        SET @last  = CHARINDEX('>', @htmlDesc, @first);
    END

    /* -------------------------------
       STEP 2: Decode HTML ENTITIES
    --------------------------------*/
    SET @htmlDesc = REPLACE(@htmlDesc, '&lt;', '<');
    SET @htmlDesc = REPLACE(@htmlDesc, '&gt;', '>');
    SET @htmlDesc = REPLACE(@htmlDesc, '&amp;', '&');
    SET @htmlDesc = REPLACE(@htmlDesc, '&quot;', '"');
    SET @htmlDesc = REPLACE(@htmlDesc, '&apos;', '''');
    SET @htmlDesc = REPLACE(@htmlDesc, '&nbsp;',' ');

    RETURN LTRIM(RTRIM(@htmlDesc));
END