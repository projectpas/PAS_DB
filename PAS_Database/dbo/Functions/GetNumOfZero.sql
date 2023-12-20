CREATE   FUNCTION [dbo].[GetNumOfZero](@ZoroLength INT)
RETURNS VARCHAR(MAX) 
AS
BEGIN  
	DECLARE @Zero VARCHAR(MAX)=''
	DECLARE @i INT = 1;
	WHILE @i <= @ZoroLength
	BEGIN   		
		SET @Zero = @Zero + '0';
		SET @i = @i + 1;
	END;	
	RETURN @Zero;
END