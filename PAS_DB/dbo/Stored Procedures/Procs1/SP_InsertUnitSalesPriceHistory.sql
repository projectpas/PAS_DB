/*************************************************************                
 ** Author: Ekta Chandegra
 ** Description: This stored procedure is used to Create history of unit sales price in stockline
 ** Date:   08/01/2024
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    08/01/2024   Ekta Chandegra    Created
**************************************************************
 EXECUTE SP_InsertUnitSalesPriceHistory  163178 , 1 , 'Admin'
**************************************************************/
CREATE   PROCEDURE [dbo].[SP_InsertUnitSalesPriceHistory] 
@StockLineId bigint ,
@MasterCompanyId int,
@CreatedBy varchar(50)
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
			   		
		IF (@StockLineId > 0)
		BEGIN
		DECLARE @unitSalesPrice decimal , @salesExpiryDate datetime, @id bigint = 0;
			SELECT DISTINCT *
				INTO #TempUnitSalesPriceHistory FROM DBO.Stockline stk WITH(NOLOCK)  WHERE stocklineId = @StockLineId  AND MasterCompanyId = @MasterCompanyId
			SELECT TOP 1 @id = ISNULL(UnitSalePriceHistoryAuditId,0) ,@unitSalesPrice = UnitSalesPrice, @salesExpiryDate = SalesPriceExpiryDate from DBO.UnitSalePriceHistoryAudit usp WITH(NOLOCK) WHERE stocklineId = @StockLineId ORDER BY UnitSalePriceHistoryAuditId DESC

			INSERT INTO [dbo].[UnitSalePriceHistoryAudit]
			   ([StockLineId],[StocklineNumber],[UnitSalesPrice],[SalesPriceExpiryDate],[CreatedDate],[CreatedBy],
			   [UpdatedDate],[UpdatedBy],[IsActive],[IsDeleted],[MasterCompanyId])
			
			   SELECT StocklineId,StocklineNumber,UnitSalesPrice,SalesPriceExpiryDate,GETUTCDATE(),@CreatedBy,GETUTCDATE(),@CreatedBy,
			   1,0,@MasterCompanyId
			   From #TempUnitSalesPriceHistory WHERE @id = 0 OR UnitSalesPrice <> @unitSalesPrice OR  SalesPriceExpiryDate <> @salesExpiryDate
			   OR (@salesExpiryDate IS NULL AND SalesPriceExpiryDate IS NOT NULL)
			   OR (@unitSalesPrice IS NULL AND UnitSalesPrice IS NOT NULL)

			   
		END
		
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			  SELECT ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage 
 
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[SP_InsertUnitSalesPriceHistory] ',
            @ProcedureParameters varchar(3000) = '@StockLineId = ''' + CAST(ISNULL(@StockLineId, '') AS varchar(100))
            + '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
			+ '@CreatedBy = ''' + CAST(ISNULL(@CreatedBy, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END