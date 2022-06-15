/*************************************************************           
 ** File:   [GetExpireDaysStockline]           
 ** Author:   Subhash Saliya
 ** Description: Save stockline expire days
 ** Purpose:         
 ** Date:   20-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/20/2022   Subhash Saliya Created
	

-- EXEC [dbo].[GetExpireDaysStockline] 68,1
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetExpireDaysStockline]
@StocklineId bigint = null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	     

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

				print @ManufacturingDays
				print @DaysReceived
				print @TagDays
				print @TagDays
				print @tagDate
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
					print @ManufacturingDays
				end

				if(@tagDate is not null)
				begin
				set @TagDays = DATEDIFF(DAY, GETDATE(),@tagDate)

				print @TagDays
				end

				if(@receivedDate is not null)
				begin
				set @DaysReceived = DATEDIFF(DAY,GETDATE(),@receivedDate)
				end

				  select @DaysReceived as DaysReceived,@TagDays as TagDays,@ManufacturingDays as ManufacturingDays,@OpenDays as OpenDays

	
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetExpireDaysStockline' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@StocklineId AS VARCHAR(10)), '') + ''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException 
                @DatabaseName           = @DatabaseName
                , @AdhocComments          = @AdhocComments
                , @ProcedureParameters = @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END