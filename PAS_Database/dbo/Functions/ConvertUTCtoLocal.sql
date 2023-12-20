CREATE   FUNCTION [dbo].[ConvertUTCtoLocal]    
(    
     @utcDateTime DATETIME,    
     @strTimeZoneName varchar(100)    
)    
RETURNS Datetime    
AS    
BEGIN    
	DECLARE @m_createddate as Datetime, @BaseUtcOffsetSec AS INT    
	SELECT @BaseUtcOffsetSec = BaseUtcOffsetSec FROM  Timezone WHERE Description = @strTimeZoneName    
 select   @m_createddate=DATEADD(SECOND, @BaseUtcOffsetSec, @utcDateTime)    
RETURN @m_createddate    
END