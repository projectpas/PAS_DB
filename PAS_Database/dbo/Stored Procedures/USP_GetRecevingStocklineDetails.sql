/*************************************************************           
 ** File:   [USP_GetRecevingStocklineDetails]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get RecevingStocklineDetails List
 ** Purpose:         
 ** Date:   05-11-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    05-11-2025    Sahdev Saliya       Created  

    exec [dbo].[USP_GetRecevingStocklineDetails]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetRecevingStocklineDetails]
    @ItemMasterId BIGINT = NULL,
    @ConditionId BIGINT = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT TOP 1
            st.StockLineId,
            st.PurchaseUnitOfMeasureId,
            ISNULL(st.UnitSalesPrice, 0) AS UnitSalesPrice,
            (ISNULL (st.PurchaseOrderUnitCost, 0) + ISNULL(pp.DiscountPerUnit, 0)) AS VendorListPrice,
            po.PurchaseOrderNumber,
            st.ReceivedDate
        FROM dbo.ItemMaster AS im WITH (NOLOCK)
			INNER JOIN dbo.StockLine AS st WITH (NOLOCK) ON im.ItemMasterId = st.ItemMasterId
			INNER JOIN dbo.PurchaseOrder AS po WITH (NOLOCK) ON st.PurchaseOrderId = po.PurchaseOrderId
			INNER JOIN dbo.PurchaseOrderPart AS pp WITH (NOLOCK) ON st.PurchaseOrderPartRecordId = pp.PurchaseOrderPartRecordId
        WHERE st.ItemMasterId = @ItemMasterId
	      AND st.ConditionId = @ConditionId
		  AND st.PurchaseOrderId > 0
        ORDER BY st.StockLineId DESC;

    END TRY
    BEGIN CATCH
			DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetRecevingStocklineDetails'
				  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
				  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
			EXEC spLogException @DatabaseName = @DatabaseName
				,@AdhocComments = @AdhocComments
				,@ProcedureParameters = @ProcedureParameters
				,@ApplicationName = @ApplicationName
				,@ErrorLogID = @ErrorLogID OUTPUT;

			RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

			RETURN (1); 
	 END CATCH
END