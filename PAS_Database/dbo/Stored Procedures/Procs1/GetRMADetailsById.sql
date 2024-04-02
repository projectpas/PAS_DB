

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
     
-- EXEC GetRMADetailsById 36
************************************************************************/
CREATE   PROCEDURE [dbo].[GetRMADetailsById]
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
			  ,[SerialNumber]
			  ,CRD.[StocklineId]
			  ,[StocklineNumber]
			  ,CRD.[ControlNumber]
			  ,[ControlId]
			  ,[ReferenceId]
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
			  SOBII.NoofPieces as Qty, SOBII.UnitPrice As [PartsUnitCost],
			  SOBII.PartCost As [PartsRevenue], 0 AS [LaborRevenue], SOBII.MiscCharges AS [MiscRevenue], SOBII.Freight AS [FreightRevenue],
			  (ISNULL(SOBII.NoofPieces, 1) * ISNULL(SOPN.UnitSalesPricePerUnit, 0)) AS [COGSParts], 0 AS [COGSLabor], 0 AS [COGSOverHeadCost], --SOF.BillingAmount, SOC.BillingAmount,
			  (ISNULL(SOBII.NoofPieces, 1) * ISNULL(SOPN.UnitSalesPricePerUnit, 0)) AS [COGSInventory], ISNULL(SOPN.UnitSalesPricePerUnit, 0) AS [COGSPartsUnitCost],
			  CASE WHEN ISNULL(SOBII.NoofPieces,0) > 0 THEN (SOBII.GrandTotal / SOBII.NoofPieces) ELSE SOBII.GrandTotal END AS UnitPrice,
			  (ISNULL(SOBII.NoofPieces, 1) * ISNULL(SOBII.UnitPrice, 0)) as Amount,
			  SOBII.SubTotal,SOBII.SalesTax, SOBII.OtherTax, SOBII.GrandTotal, SOBII.GrandTotal [InvoiceAmt]
		  FROM [dbo].[CustomerRMADeatils] CRD WITH (NOLOCK) 
				LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON CRD.ItemMasterId = IM.ItemMasterId
				LEFT JOIN [dbo].[SalesOrderBillingInvoicingItem] SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingItemId = CRD.BillingInvoicingItemId AND ISNULL(SOBII.IsProforma,0) = 0
				LEFT JOIN [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK) ON SOBI.SOBillingInvoicingId = CRD.InvoiceId AND SOBI.SOBillingInvoicingId = SOBII.SOBillingInvoicingId
				LEFT JOIN [dbo].[SalesOrderPart] SOPN WITH (NOLOCK) ON SOPN.SalesOrderId = SOBI.SalesOrderId AND SOPN.SalesOrderPartId = SOBII.SalesOrderPartId
				LEFT JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SOBI.SalesOrderId = SO.SalesOrderId
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
			  ,[SerialNumber]
			  ,CRD.[StocklineId]
			  ,[StocklineNumber]
			  ,[ControlNumber]
			  ,[ControlId]
			  ,[ReferenceId]
			  ,[ReferenceNo]			  		  
			  ,[Amount]
			  ,WOBII.NoofPieces as Qty
			  ,WOBII.GrandTotal as UnitPrice
			  ,(WOBII.NoofPieces * WOBII.GrandTotal)  as Amount
			  ,WOBII.MaterialCost As [PartsUnitCost]
			  ,WOBII.MaterialCost As [PartsRevenue]
			  ,WOBII.LaborCost AS [LaborRevenue] 
			  ,WOBII.MiscCharges AS [MiscRevenue] 
			  ,WOBII.Freight AS [FreightRevenue]
			  ,WOMPN.PartsCost AS [COGSParts] 
			  ,WOMPN.LaborCost AS [COGSLabor] 
			  ,WOMPN.OverHeadCost As [COGSOverHeadCost]
			  ,(ISNULL(WOMPN.PartsCost,0) + ISNULL(WOMPN.LaborCost,0) + ISNULL(WOMPN.OverHeadCost,0)) AS [COGSInventory]
			  ,ISNULL(WOMPN.PartsCost, 0) AS [COGSPartsUnitCost]
			  ,WOBII.SubTotal, WOBII.SalesTax, WOBII.OtherTax, WOBII.GrandTotal, WOBII.GrandTotal [InvoiceAmt]
			  ,[RMAReasonId]
			  ,[RMAReason]
			  ,[Notes]
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
			  LEFT JOIN [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH (NOLOCK) ON WOBII.WOBillingInvoicingItemId = CRD.BillingInvoicingItemId
			  LEFT JOIN [dbo].[WorkOrderPartNumber] WOPN WITH (NOLOCK) ON WOPN.ID = WOBII.WorkOrderPartId
			  LEFT JOIN [dbo].[WorkOrderMPNCostDetails] WOMPN WITH (NOLOCK) ON WOMPN.WorkOrderId = WOPN.WorkOrderId AND WOBII.WorkOrderPartId = WOMPN.WOPartNoId
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