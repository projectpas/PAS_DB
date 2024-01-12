/*************************************************************           
 ** File:   [USP_UpdateSOPartOnReserve]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to update SO Part While Create Stockline On Reserve 
 ** Date:   12 Jan 2024
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    12 Jan 2024   Rajesh Gami     Created
**************************************************************
 EXEC USP_UpdateSOPartOnReserve 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateSOPartOnReserve] 
@StockLineId bigint,
@Qty int,
@UnitCost decimal(10,2) NULL,
@UnitCostExtended decimal(10,2) NULL, 
@MarginAmount decimal(10,2) NULL,
@MarginAmountExtended decimal(10,2) NULL,
@MarginPercentage decimal(10,2) NULL,
@GrossSalePrice decimal(10,2) NULL,
@SalesPriceExtended decimal(10,2),
@SalesBeforeDiscount decimal(10,2),
@SalesOrderPartId bigint
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
			   		
			UPDATE [dbo].[SalesOrderPart]
			   SET [StockLineId] = @StockLineId
			      ,[Qty] = @Qty
			      ,[UnitCost] = @UnitCost
			      ,[UnitCostExtended] = @UnitCostExtended
			      ,[MarginAmount] = @MarginAmount
			      ,[MarginAmountExtended] = @MarginAmountExtended
			      ,[MarginPercentage] = @MarginPercentage		
				  ,[GrossSalePrice] = @GrossSalePrice	
				  ,[SalesPriceExtended] = @SalesPriceExtended	
				  ,[SalesBeforeDiscount] = @SalesBeforeDiscount	
			      ,[UpdatedDate] = GETUTCDATE()			      
			 WHERE [SalesOrderPartId] = @SalesOrderPartId

	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_UpdateSOPartOnReserve]',
            @ProcedureParameters varchar(3000) = '@StockLineId = ''' + CAST(ISNULL(@StockLineId, '') AS varchar(100))
            + '@Qty = ''' + CAST(ISNULL(@Qty, '') AS varchar(100))
            + '@UnitCost = ''' + CAST(ISNULL(@UnitCost, '') AS varchar(100))             
            + '@UnitCostExtended = ''' + CAST(ISNULL(@UnitCostExtended, '') AS varchar(100))
            + '@MarginAmount = ''' + CAST(ISNULL(@MarginAmount, '') AS varchar(100))
            + '@MarginAmountExtended = ''' + CAST(ISNULL(@MarginAmountExtended, '') AS varchar(100))
			+ '@MarginPercentage = ''' + CAST(ISNULL(@MarginPercentage, '') AS varchar(100))
			+ '@GrossSalePrice = ''' + CAST(ISNULL(@GrossSalePrice, '') AS varchar(100))
			+ '@SalesPriceExtended = ''' + CAST(ISNULL(@SalesPriceExtended, '') AS varchar(100))
			+ '@SalesOrderPartId = ''' + CAST(ISNULL(@SalesOrderPartId, '') AS varchar(100))
			+ '@SalesBeforeDiscount = ''' + CAST(ISNULL(@SalesBeforeDiscount, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END