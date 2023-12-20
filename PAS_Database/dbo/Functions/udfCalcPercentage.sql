

CREATE FUNCTION [dbo].[udfCalcPercentage]  
(  
   @cost DECIMAL(18,2),  
   @revenue DECIMAL(18,2)
)  
RETURNS DECIMAL(18,2)  
AS  
BEGIN  
	Declare @RevPer DECIMAL(18,2)
	IF(@revenue > 0)
	BEGIN
		SET @RevPer = (@cost/@revenue) * 100;
	END
	ELSE
	BEGIN
		SET @RevPer = 0;
	END
RETURN @RevPer
END