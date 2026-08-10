/*************************************************************           
 ** File:   [GetRMADetailsById]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to Get RMA Part Details
 ** Purpose:         
 ** Date:   22/04/2022      
          
 ** PARAMETERS: @CreditMemoHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    22/04/2022   Moin Bloch      Created
	2    03/27/2024   Hemant Saliya   Updated for Part wise Billing Amy Details
	3    03/27/2024   Hemant Saliya   Updated for -Ve CM Cost
    4    11/05/2024	  Vishal Suthar	  Modified to make use of new SO Part tables 
	5    19/06/2025   AMIT GHEDIYA    Get WO/SO Billing data from new table.  
	6    12/01/2026   Vishal Suthar   Fixed ambiguous column SerialNumber issue
	7    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	8    17/07/2026   Nakul Chandigra Changed Stock UOM to Consume UOM for Qty.(PN-17257)
	9    18/07/2026   BhargavSaliya Changed Stock UOM to Consume UOM for [PartsUnitCost].(PN-17257)
	10    23/July/2026			 RAJESH GAMI						[PN-17350] - Removed leftover IsNonStock=0 exclusion filter(s) added during PN-17008/PN-17009 transitional Non-Stock merge phase (Non-Stock is now merged; filter no longer needed).
-- EXEC GetRMADetailsById 105
************************************************************************/
CREATE    PROCEDURE [dbo].[GetRMADetailsById]
@RMAHeaderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	DECLARE @IsWorkOrder BIT;

	SELECT @IsWorkOrder = isWorkOrder FROM [dbo].[CustomerRMAHeader] CRD WITH (NOLOCK)  WHERE RMAHeaderId = @RMAHeaderId

	IF(@isWorkOrder = 0)
	BEGIN
		SELECT [RMADeatilsId]
			  ,[RMAHeaderId]
			  ,CRD.[ItemMasterId]
			  ,CRD.[PartNumber]
			  ,CRD.[PartDescription]
			  ,[AltPartNumber]
			  ,[CustPartNumber]
			  ,CRD.[SerialNumber]
			  ,CRD.[StocklineId]
			  ,[StocklineNumber]
			  ,CRD.[ControlNumber]
			  ,[ControlId]
			  ,CRD.[ReferenceId]
			  ,[ReferenceNo]
			  ,[RMAReasonId]
			  ,[RMAReason]
			  ,CRD.[Notes]
			  ,[isWorkOrder]
			  ,CRD.[MasterCompanyId]
			  ,CRD.[CreatedBy]
			  ,CRD.[UpdatedBy]
			  ,CRD.[CreatedDate]
			  ,CRD.[UpdatedDate]
			  ,CRD.[IsActive]
			  ,CRD.[IsDeleted]
			  ,IM.ManufacturerName
			  ,CRD.BillingInvoicingItemId,
			 CASE WHEN ISNULL(IM.[StockUnitOfMeasure],'') = ISNULL(IM.[ConsumeUnitOfMeasure],'') THEN ISNULL(SOBII.QtyBilled, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SOBII.QtyBilled, 0), IM.[StockUnitOfMeasure], IM.[ConsumeUnitOfMeasure], 0, IM.MasterCompanyId) END as Qty
			  ,CASE WHEN ISNULL(IM.[StockUnitOfMeasure],'') = ISNULL(IM.[ConsumeUnitOfMeasure],'') THEN ISNULL(SOBII.UnitPrice, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SOBII.UnitPrice, 0), IM.[StockUnitOfMeasure], IM.[ConsumeUnitOfMeasure], 1, IM.MasterCompanyId) END as [PartsUnitCost],
			 (SOBII.PartCost * -1) As [PartsRevenue], 
			  0 AS [LaborRevenue], 
			  (SOBII.MiscCharges * -1) AS [MiscRevenue], 
			  (SOBII.Freight * -1) AS [FreightRevenue],
			  SOBII.SubTotal,
			  (SOBII.SalesTax * -1) As SalesTax, 
			  (SOBII.OtherTax * -1) As OtherTax, 
			  (SOBII.GrandTotal * -1) AS GrandTotal, 
			  (SOBII.GrandTotal * -1) AS [InvoiceAmt],
			  (ISNULL(SOBII.QtyBilled, 1) * ISNULL(SOPC.UnitSalesPrice, 0)) AS [COGSParts], 0 AS [COGSLabor], 0 AS [COGSOverHeadCost], --SOF.BillingAmount, SOC.BillingAmount,
			  (ISNULL(SOBII.QtyBilled, 1) * ISNULL(SOPC.UnitSalesPrice, 0)) AS [COGSInventory], ISNULL(SOPC.UnitSalesPrice, 0) AS [COGSPartsUnitCost],
			  CASE WHEN ISNULL(SOBII.QtyBilled,0) > 0 THEN (SOBII.GrandTotal / SOBII.QtyBilled) ELSE SOBII.GrandTotal END AS UnitPrice,
			  (ISNULL(SOBII.QtyBilled, 1) * ISNULL(SOBII.UnitPrice, 0)) as Amount			  
		  FROM [dbo].[CustomerRMADeatils] CRD WITH (NOLOCK) 
				LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON CRD.ItemMasterId = IM.ItemMasterId
				LEFT JOIN [dbo].[BillingInvoicingItems] SOBII WITH (NOLOCK) ON SOBII.BillingInvoicingItemId = CRD.BillingInvoicingItemId
				LEFT JOIN [dbo].[BillingInvoicing] SOBI WITH (NOLOCK) ON SOBI.BillingInvoicingId = CRD.InvoiceId AND SOBI.BillingInvoicingId = SOBII.BillingInvoicingId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0
				LEFT JOIN [dbo].[SalesOrderPartV1] SOPN WITH (NOLOCK) ON SOPN.SalesOrderId = SOBI.ReferenceId AND SOPN.SalesOrderPartId = SOBII.SubReferenceId
				LEFT JOIN [dbo].[SalesOrderPartCost] SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOPN.SalesOrderPartId
				LEFT JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SOBI.ReferenceId = SO.SalesOrderId
				LEFT JOIN [dbo].[SalesOrderFreight] SOF WITH (NOLOCK) ON SOF.SalesOrderPartId = SOPN.SalesOrderPartId
				LEFT JOIN [dbo].[SalesOrderCharges] SOC WITH (NOLOCK) ON SOC.SalesOrderPartId = SOPN.SalesOrderPartId
		  WHERE RMAHeaderId = @RMAHeaderId AND CRD.IsDeleted = 0 AND CRD.IsActive = 1;
	END
	ELSE
	BEGIN
		SELECT [RMADeatilsId]
			  ,[RMAHeaderId]
			  ,CRD.[ItemMasterId]
			  ,CRD.[PartNumber]
			  ,CRD.[PartDescription]
			  ,[AltPartNumber]
			  ,[CustPartNumber]
			  ,CRD.[SerialNumber]
			  ,CRD.[StocklineId]
			  ,[StocklineNumber]
			  ,[ControlNumber]
			  ,[ControlId]
			  ,CRD.[ReferenceId]
			  ,[ReferenceNo]			  		  
			  ,[Amount]
			  ,WOBII.QtyBilled as Qty
			  ,WOBII.GrandTotal as UnitPrice
			  ,(WOBII.QtyBilled * WOBII.GrandTotal)  as Amount
			  ,WOBII.MaterialCost As [PartsUnitCost]
			  ,(WOBII.MaterialCost * -1) As [PartsRevenue]
			  ,(WOBII.LaborCost * -1) AS  [LaborRevenue] 
			  ,(WOBII.MiscCharges * -1) AS [MiscRevenue] 
			  ,(WOBII.Freight * -1) AS [FreightRevenue]
			  ,WOBII.SubTotal
			  ,(WOBII.SalesTax * -1) AS SalesTax 
			  ,(WOBII.OtherTax * -1) AS OtherTax 
			  ,(WOBII.GrandTotal * -1) AS GrandTotal 
			  ,(WOBII.GrandTotal * -1) AS [InvoiceAmt]
			  ,WOMPN.PartsCost AS [COGSParts] 
			  ,WOMPN.LaborCost AS [COGSLabor] 
			  ,WOMPN.OverHeadCost As [COGSOverHeadCost]
			  ,(ISNULL(WOMPN.PartsCost,0) + ISNULL(WOMPN.LaborCost,0) + ISNULL(WOMPN.OverHeadCost,0)) AS [COGSInventory]
			  ,ISNULL(WOMPN.PartsCost, 0) AS [COGSPartsUnitCost]
			  ,[RMAReasonId]
			  ,[RMAReason]
			  ,CRD.[Notes]
			  ,[isWorkOrder]
			  ,CRD.[MasterCompanyId]
			  ,CRD.[CreatedBy]
			  ,CRD.[UpdatedBy]
			  ,CRD.[CreatedDate]
			  ,CRD.[UpdatedDate]
			  ,CRD.[IsActive]
			  ,CRD.[IsDeleted]
			  ,IM.ManufacturerName
			  ,CRD.BillingInvoicingItemId
		  FROM [dbo].[CustomerRMADeatils] CRD WITH (NOLOCK) 
			  LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON CRD.ItemMasterId = IM.ItemMasterId
			  LEFT JOIN [dbo].[BillingInvoicingItems] WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingItemId = CRD.BillingInvoicingItemId
			  LEFT JOIN [dbo].[WorkOrderPartNumber] WOPN WITH (NOLOCK) ON WOPN.ID = WOBII.SubReferenceId
			  LEFT JOIN [dbo].[WorkOrderMPNCostDetails] WOMPN WITH (NOLOCK) ON WOMPN.WorkOrderId = WOPN.WorkOrderId AND WOBII.SubReferenceId = WOMPN.WOPartNoId
		  WHERE RMAHeaderId = @RMAHeaderId AND CRD.IsDeleted = 0 AND CRD.IsActive = 1;

	END



END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetRMADetailsById' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@RMAHeaderId, '') AS varchar(100))			   
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