CREATE   FUNCTION [dbo].[ConvertUTCtoLocal]    
(    
     @utcDateTime DATETIME,    
     @strTimeZoneName varchar(100)    
)    
RETURNS Datetime    
AS    
BEGIN   
	DECLARE @BaseUtcOffsetSec INT    

    -- Fetch the UTC offset in seconds
    SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec  
    FROM dbo.TimeZone WITH(NOLOCK)  
    WHERE [Description] = @strTimeZoneName    

    -- Return the converted datetime
    RETURN DATEADD(SECOND, @BaseUtcOffsetSec, @utcDateTime)   

	-- Commented By Hemnat To Optimize Function
	--DECLARE @m_createddate as Datetime, @BaseUtcOffsetSec AS INT    
	--SELECT @BaseUtcOffsetSec = BaseUtcOffsetSec FROM  dbo.TimeZone WITH(NOLOCK) WHERE [Description] = @strTimeZoneName    
	--SELECT   @m_createddate = DATEADD(SECOND, @BaseUtcOffsetSec, @utcDateTime)    
	--RETURN @m_createddate    
END