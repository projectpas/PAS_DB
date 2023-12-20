-- =============================================
-- Author:		Subhash Saliya
-- Create date: 01 jun 2022
-- Description:	Get Expire Days in Stockline
-- =============================================
CREATE FUNCTION [dbo].[FN_GetExpireDaysStockline]
(
	@StocklineId as bigint
)
RETURNS int
AS
BEGIN
	
	            Declare @DaysReceived int = null
	            Declare @ManufacturingDays  int  = null
	            Declare @TagDays int  = null
	            Declare @OpenDays int = null
	            Declare @expDays int = null 
	            Declare @DiffDays int = null
			    Declare @expirationDate Datetime 
				Declare @tagDate Datetime
				Declare @receivedDate Datetime
	
	            SELECT @DaysReceived = nullif(DaysReceived, 0), @ManufacturingDays = nullif(ManufacturingDays, 0), @TagDays = nullif(TagDays, 0), @OpenDays = nullif(OpenDays, 0),@DiffDays =DATEDIFF(year, CreatedDate, GETDATE())
				       ,@expirationDate= ExpirationDate  ,@tagDate= tagDate,@receivedDate= receivedDate FROM dbo.Stockline STL WITH(NOLOCK) 
				WHERE STL.StocklineId = @StocklineId  AND IsParent = 1

				if(@DaysReceived >0)
				begin
				set @DaysReceived = @DaysReceived-@DiffDays
				end

				if(@ManufacturingDays >0)
				begin
				set @ManufacturingDays = @ManufacturingDays-@DiffDays
				end

				if(@TagDays >0)
				begin
				set @TagDays = @TagDays-@DiffDays
				end

				if(@OpenDays >0)
				begin
				set @OpenDays = @OpenDays-@DiffDays
				end

				if(@expirationDate is not null)
				begin
				set @ManufacturingDays = DATEDIFF(DAY, GETDATE(),@expirationDate)
				end

				if(@tagDate is not null)
				begin
				set @TagDays = DATEDIFF(DAY, GETDATE(),@tagDate)

				end

				if(@receivedDate is not null)
				begin
				set @DaysReceived = DATEDIFF(DAY,GETDATE(),@receivedDate)
				end

				 --if((@ManufacturingDays != 0 OR @expirationDate is not null) and @ManufacturingDays <= @TagDays and @ManufacturingDays <= @DaysReceived and @ManufacturingDays <= @OpenDays )
				 --begin

				 --set @expDays=@ManufacturingDays
				 --end
				 --else if((@TagDays != 0 OR @tagDate is not null) and @TagDays <= @ManufacturingDays and @TagDays <= @DaysReceived and @TagDays <= @OpenDays )
				 --begin

				 --set @expDays=@TagDays
				 --end
				 --else if((@DaysReceived != 0 OR @receivedDate is not null) and @DaysReceived <= @ManufacturingDays and @DaysReceived <= @TagDays and @DaysReceived <= @OpenDays )
				 --begin

				 --set @expDays=@DaysReceived
				 --end
				 -- else if(@OpenDays != 0 and @OpenDays <= @ManufacturingDays and @OpenDays <= @TagDays and @OpenDays <= @DaysReceived  )
				 --begin

				 --set @expDays=@OpenDays
				 --end


				  SELECT @expDays =  MIN(expDays)
					    FROM (VALUES (nullif(@ManufacturingDays,0)), (nullif(@TagDays,0)), (nullif(@DaysReceived,0)), (nullif(@OpenDays,0))) AS v (expDays)

				 --Select , , , , @expDays = least(@ManufacturingDays, @TagDays, @DaysReceived, @OpenDays) 

	
	return @expDays


END