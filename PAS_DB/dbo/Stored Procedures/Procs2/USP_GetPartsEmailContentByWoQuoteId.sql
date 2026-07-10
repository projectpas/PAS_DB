
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_GetPartsEmailContentByWoQuoteId   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_GetPartsEmailContentByWoQuoteId.sql)
-- ---------------------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [USP_GetPartsEmailContentByWoQuoteId]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Get Part Email Content By WO QuoteId
 ** Date:   04 Apr 2025
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1   04 Apr 2025  Rajesh Gami     Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
**************************************************************
EXEC USP_GetPartsEmailContentByWoQuoteId 6610
**************************************************************/
CREATE       PROCEDURE [dbo].[USP_GetPartsEmailContentByWoQuoteId] 
@WorkOrderQuoteId bigint =0
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN			   		
			SELECT DISTINCT
			wqd.WorkOrderQuoteDetailsId,
			wqd.WOPartNoId,
			ISNULL(woq.QuoteNumber, '') AS QuoteNumber,
			ISNULL(cust.Name, '') AS CustomerName,
			ISNULL(wo.WorkOrderNum, '') AS WorkOrderNum,
			ISNULL(im.PartNumber, '') AS MPNPartNum,
			CASE 
				WHEN ISNULL(wqd.MaterialBuildMethod, 0) = 1 THEN 'T&M'
				WHEN ISNULL(wqd.MaterialBuildMethod, 0) = 2 THEN 'Actual'
				ELSE 'Flat'
			END AS QuoteMethod,
			ISNULL(wqd.MaterialBuildMethod, 0) AS MaterialBuildMethod,
			ISNULL(wqd.MaterialFlatBillingAmount, 0) AS MaterialFlatBillingAmount,
			ISNULL(wqd.LaborFlatBillingAmount, 0) AS LaborFlatBillingAmount,
			ISNULL(wqd.ChargesFlatBillingAmount, 0) AS ChargesFlatBillingAmount
		FROM dbo.WorkOrderApproval wapp WITH (NOLOCK)
		INNER JOIN dbo.WorkOrderQuote woq WITH (NOLOCK) ON wapp.WorkOrderQuoteId = woq.WorkOrderQuoteId
		INNER JOIN dbo.WorkOrderQuoteDetails wqd WITH (NOLOCK) ON woq.WorkOrderQuoteId = wqd.WorkOrderQuoteId
		INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) ON woq.WorkOrderId = wo.WorkOrderId
		INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wqd.WOPartNoId = wop.ID
		INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON wop.ItemMasterId = im.ItemMasterId
		INNER JOIN dbo.Customer cust WITH (NOLOCK) ON woq.CustomerId = cust.CustomerId
		WHERE ISNULL(woq.IsDeleted, 0) = 0
		  AND wapp.WorkOrderQuoteId = @WorkOrderQuoteId  AND ISNULL(im.IsNonStock,0) = 0 ;

		-- Quote Materials
		SELECT 
			wqd.WorkOrderQuoteDetailsId,
			ISNULL(im.PartNumber, '') AS PartNumber,
			ISNULL(im.PartDescription, '') AS PartDescription,
			ISNULL(wqm.Quantity, 0) AS Quantity,
			CONVERT(DECIMAL(10,2),(CASE 
				WHEN ISNULL(wqm.BillingAmount, 0) > 0 AND ISNULL(wqm.Quantity, 0) > 0 
					THEN ISNULL(wqm.BillingAmount, 0) / ISNULL(wqm.Quantity, 0)
				ELSE 0 
			END)) AS UnitPrice,
			ISNULL(wqm.BillingAmount, 0) AS Amount
		FROM dbo.WorkOrderApproval wapp WITH (NOLOCK)
		INNER JOIN dbo.WorkOrderQuote woq WITH (NOLOCK) ON wapp.WorkOrderQuoteId = woq.WorkOrderQuoteId
		INNER JOIN dbo.WorkOrderQuoteDetails wqd WITH (NOLOCK) ON woq.WorkOrderQuoteId = wqd.WorkOrderQuoteId
		INNER JOIN dbo.WorkOrderQuoteMaterial wqm WITH (NOLOCK) ON wqd.WorkOrderQuoteDetailsId = wqm.WorkOrderQuoteDetailsId
		INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON wqm.ItemMasterId = im.ItemMasterId
		WHERE ISNULL(wqm.IsDeleted, 0) = 0
		AND wapp.WorkOrderQuoteId = @WorkOrderQuoteId AND ISNULL(im.IsNonStock,0) = 0 ;

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
            ,@AdhocComments varchar(150) = '[USP_GetPartsEmailContentByWoQuoteId]',
            @ProcedureParameters varchar(3000) = '@WorkOrderQuoteId = ''' + CAST(ISNULL(@WorkOrderQuoteId, '') AS varchar(100)),
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