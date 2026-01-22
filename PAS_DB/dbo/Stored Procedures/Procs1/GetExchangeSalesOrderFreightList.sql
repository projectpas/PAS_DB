/*************************************************************           
 ** File:   [GetExchangeSalesOrderFreightList]           
 ** Author: Abhishek Jirawla 
 ** Description: This stored procedure is used to Get Exchange Sales Order Freight List Details
 ** Purpose:         
 ** Date:   09-04-2024
 ** PARAMETERS: @ExchangeSalesOrderId bigint 
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09-04-2024  Abhishek Jirawla     Created

-- EXEC GetExchangeSalesOrderFreightList 8,0
************************************************************************/
CREATE   PROCEDURE [dbo].[GetExchangeSalesOrderFreightList]
@ExchangeSalesOrderId bigint,
@IsDeleted bit,
@Opr int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	
	IF(@Opr=1)
	BEGIN
	SELECT [ExchangeSalesOrderFreightId]
          ,[ExchangeSalesOrderId]
          --,[ExchangeSalesOrderPartRecordId]
          --,[ItemMasterId]
          --,[PartNumber]
          ,[ShipViaId]
          ,[ShipViaName]
          ,[MarkupPercentageId]
          ,[MarkupFixedPrice]
          ,[HeaderMarkupId]
          ,[BillingMethodId]
          ,[BillingRate]
          ,[BillingAmount]
          ,[HeaderMarkupPercentageId]
          ,[Weight]
          ,[UOMId]
          ,[UOMName]
          ,[Length]
          ,[Width]
          ,[Height]
          ,[DimensionUOMId]
          ,[DimensionUOMName]
          ,[CurrencyId]
          ,[CurrencyName]
          ,[Amount]
          ,[Memo]
          ,[MasterCompanyId]
          ,[CreatedBy]
          ,[UpdatedBy]
          ,[CreatedDate]
          ,[UpdatedDate]
          ,[IsActive]
          ,[IsDeleted]
		  --,[LineNum]
		  --,[ManufacturerId]
		  --,[Manufacturer]
      FROM [dbo].[ExchangeSalesOrderFreight] WITH (NOLOCK) WHERE ExchangeSalesOrderId=@ExchangeSalesOrderId AND IsDeleted=@IsDeleted;
	END
	BEGIN
	SELECT [ExchangeSalesOrderFreightId]
          ,[ExchangeSalesOrderId]
          --,[ExchangeSalesOrderPartRecordId]
          --,[ItemMasterId]
          --,[PartNumber]
          ,[ShipViaId]
          ,[ShipViaName]
          ,[MarkupPercentageId]
          ,[MarkupFixedPrice]
          ,[HeaderMarkupId]
          ,[BillingMethodId]
          ,[BillingRate]
          ,[BillingAmount]
          ,[HeaderMarkupPercentageId]
          ,[Weight]
          ,[UOMId]
          ,[UOMName]
          ,[Length]
          ,[Width]
          ,[Height]
          ,[DimensionUOMId]
          ,[DimensionUOMName]
          ,[CurrencyId]
          ,[CurrencyName]
          ,[Amount]
          ,[Memo]
          ,[MasterCompanyId]
          ,[CreatedBy]
          ,[UpdatedBy]
          ,[CreatedDate]
          ,[UpdatedDate]
          ,[IsActive]
          ,[IsDeleted]
		  --,[LineNum]
		  --,[ManufacturerId]
		  --,[Manufacturer]
      FROM [dbo].[ExchangeSalesOrderFreightAudit] WITH (NOLOCK) WHERE [ExchangeSalesOrderFreightId]=@ExchangeSalesOrderId;
	END
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetExchangeSalesOrderFreightList' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ExchangeSalesOrderId, '') AS varchar(100))			   
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