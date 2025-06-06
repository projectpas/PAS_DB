/*************************************************************           
 ** File:   [GetExchangeSalesOrderBillingInvoicingItemDetails]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to GetExchangeSalesOrderBillingInvoicingItemDetails
 ** Purpose:         
 ** Date:   06/06/2025      
          
 ** PARAMETERS:  @ExchangeSalesOrderPartId BIGINT, @NoOfPieces INT, @CreatedBy VARCHAR(256), @UpdatedBy VARCHAR(256)
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/06/2025   Ekta Chandegra     Created
     
-- EXEC GetExchangeSalesOrderBillingInvoicingItemDetails @ExchangeSalesOrderPartId=151,@NoOfPieces=1,@CreatedBy = "EKTA CHANDEGRA",@UpdatedBy= "EKTA CHANDEGRA"
************************************************************************/
CREATE   PROCEDURE [dbo].[GetExchangeSalesOrderBillingInvoicingItemDetails]
    @ExchangeSalesOrderPartId BIGINT,
    @NoOfPieces INT,
    @CreatedBy VARCHAR(256),
    @UpdatedBy VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT TOP 1
			@NoOfPieces AS NoOfPieces,
			sop.ExchangeListPrice AS UnitPrice,
			sop.ItemMasterId,
			@CreatedBy AS CreatedBy,
			@UpdatedBy AS UpdatedBy
		FROM [dbo].[ExchangeSalesOrder] so WITH(NOLOCK)
		INNER JOIN [dbo].[ExchangeSalesOrderPart] sop WITH(NOLOCK) ON so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
		LEFT JOIN [dbo].[ExchangeSalesOrderFreight] sof WITH(NOLOCK) ON so.ExchangeSalesOrderId = sof.ExchangeSalesOrderId
		LEFT JOIN [dbo].[ExchangeSalesOrderCharges] soc WITH(NOLOCK) ON so.ExchangeSalesOrderId = soc.ExchangeSalesOrderId
		WHERE sop.ExchangeSalesOrderPartId = @ExchangeSalesOrderPartId;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetExchangeSalesOrderBillingInvoicingItemDetails'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderPartId = ''' + CAST(ISNULL(@ExchangeSalesOrderPartId, '') AS VARCHAR(100))+''',
													@NoOfPieces = ''' + CAST(ISNULL(@NoOfPieces, '') AS VARCHAR(100))+''',
													@CreatedBy = ''' + CAST(ISNULL(@CreatedBy, '') AS VARCHAR(100))+''',
													@UpdatedBy = ''' + CAST(ISNULL(@UpdatedBy, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);
	END CATCH
END