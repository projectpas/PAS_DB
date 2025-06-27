/*************************************************************           
 ** File:   [CopyExistingBillingInvoicingDetails]           
 ** Author:   HEMANT SALIYA
 ** Description: Copy Billing Invoicing Details
 ** Purpose:         
 ** Date:   28/04/2025
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    28/04/2025   HEMANT SALIYA    Created

DELETE from BillingInvoicing WHERE MasterCompanyId = 2
DELETE from dbo.BillingInvoicingItems WHERE MasterCompanyId = 2
DELETE from dbo.BillingInvoicingDetails  

EXEC CopyExistingBillingInvoicingDetails 2
**************************************************************/ 
CREATE   PROCEDURE [dbo].[CopyExistingBillingInvoicingDetails]
@MasterCompanyId BIGINT = NULL
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	 BEGIN TRY  	
	
		DECLARE @ModuleId BIGINT;
		DECLARE @SubModuleId BIGINT;
		
		SET @ModuleId = 15; --Work Order
		SET @SubModuleId = 43; --Work Order

		--Select * from BillingInvoicing WHERE MasterCompanyId = 2
		--Select * from dbo.BillingInvoicingItems WHERE MasterCompanyId = 2
		--Select * from dbo.BillingInvoicingDetails

		--Insert Into Billing Invoice 
		INSERT INTO dbo.BillingInvoicing(OldBillingInvoicingId,ModuleId,ReferenceId,CustomerId, InvoiceTypeId,InvoiceNo,InvoiceDate,InvoiceTime,PrintDate,EmployeeId,CurrencyId,RevisionTypeId
			,InvoiceStatusId,InvoiceStatus,InvoiceFilePath,RevType,VersionNo,CostPlusType,IsPerformaInvoice,IsVersionIncrease,PostedDate,SubTotal,OtherTax,SalesTax,DepositAmount,GrandTotal
			,IsInvoicePosted,UsedDeposit,ProformaDeposit,RemainingAmount,Notes,WorkOrderShippingId,ManagementStructureId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive
			,IsDeleted,IsReversedJE,QuickBooksReferenceId,IsUpdated,LastSyncDate,SyncToken,IsCreatedFromQuote,IsQuickBookGeneratedInvoice)

		SELECT WOBI.BillingInvoicingId,@ModuleId,WorkOrderId,CustomerId, InvoiceTypeId,InvoiceNo,InvoiceDate,InvoiceTime,PrintDate,EmployeeId,CurrencyId,RevisionTypeId,NULL,InvoiceStatus,InvoiceFilePath,
			RevType,WOBI.VersionNo,CostPlusType,IsPerformaInvoice,WOBI.IsVersionIncrease,PostedDate,WOBI.SubTotal,WOBI.OtherTax,WOBI.SalesTax,DepositAmount,WOBI.GrandTotal,WOBI.IsInvoicePosted,UsedDeposit,ProformaDeposit,RemainingAmount
			,Notes,WorkOrderShippingId,ManagementStructureId,WOBI.MasterCompanyId,WOBI.CreatedBy,WOBI.UpdatedBy,WOBI.CreatedDate,WOBI.UpdatedDate,WOBI.IsActive,WOBI.IsDeleted,IsReversedJE,QuickBooksReferenceId,IsUpdated,LastSyncDate
			,SyncToken,isCreatedFromQuote,IsQuickBookGeneratedInvoice
		FROM dbo.WorkOrderBillingInvoicing WOBI 
		WHERE WOBI.MasterCompanyId = @MasterCompanyId


		--SELECT * from dbo.WorkOrderBillingInvoicing where MasterCompanyId = 2 and IsVersionIncrease = 0
		--SELECT * from dbo.BillingInvoicingItems where MasterCompanyId = 2 and IsVersionIncrease = 0
		--SELECT * from dbo.WorkOrderBillingInvoicingItem where MasterCompanyId = 2 and IsVersionIncrease = 0

		--Update InvoiceStatusId based on status and Path from item
		UPDATE dbo.BillingInvoicing SET InvoiceStatusId = INS.InvoiceStatusId , InvoiceFilePath = WOBI.PDFPath
		FROM dbo.BillingInvoicing BI 
		LEFT JOIN dbo.InvoiceStatus INS ON UPPER(BI.InvoiceStatus) = UPPER(INS.Status)	
		LEFT JOIN dbo.WorkOrderBillingInvoicingItem WOBI ON BI.OldBillingInvoicingId = WOBI.BillingInvoicingId
		WHERE BI.MasterCompanyId = @MasterCompanyId AND ModuleId = @ModuleId

		IF(@MasterCompanyId != 20)
		BEGIN

			--Insert Into Billing Invoice Item
			INSERT INTO dbo.BillingInvoicingItems(OldWOBillingInvoicingItemId,OldBillingInvoicingId,BillingInvoicingId,ModuleId,ReferenceId,SubModuleId,SubReferenceId,ItemMasterId,StocklineId,ConditionId,CostPlusType,
			UnitPrice,QtyBilled,PartCost,IsTotalCheck,TotalBillingCost,TotalBillingCostPercent,TotalBillingCostPlus,IsMaterialCheck,MaterialCost,MaterialCostPercent,MaterialCostPlus,IsLaborCheck,LaborCost,
			LaborCostPercent,LaborCostPlus,IsFreightCheck,Freight,FreightCostPercent,FreightCostPlus,IsMiscChargesCheck,MiscCharges,MiscChargesCostPercent,MiscChargesCostPlus,
			SubTotal,SalesTaxPercent,SalesTax,OtherTaxPercent,OtherTax,GrandTotal, RemainingAmount , PDFPath,VersionNo,IsVersionIncrease,IsPerformaInvoice,MasterCompanyId,CreatedBy,UpdatedBy,
			CreatedDate,UpdatedDate,IsActive,IsDeleted,ShippingId, WorkFlowWorkOrderId)

			SELECT WOBII.WOBillingInvoicingItemId,WOBII.BillingInvoicingId, BI.BillingInvoicingId,@ModuleId,BI.ReferenceId,@SubModuleId,WOBII.WorkOrderPartId,
				CASE WHEN WOP.RevisedPartId > 0 THEN WOP.RevisedPartId ELSE WOP.ItemMasterId END AS ItemMasterId,
				WOP.StocklineId,
				CASE WHEN WOP.RevisedConditionId > 0 THEN WOP.RevisedConditionId ELSE WOP.ConditionId END AS ConditionId,
				BI.CostPlusType,
				UnitPrice,WOBII.NoofPieces, (UnitPrice * WOBII.NoofPieces) AS PartCost, 
				WOBI.TotalWorkOrder AS IsTotalCheck,  
				CASE WHEN WOBI.TotalWorkOrder = 1 THEN WOBI.TotalWorkOrderCost ELSE 0 END AS TotalBillingCost,
				NULL TotalBillingCostPercent,
				CASE WHEN WOBI.TotalWorkOrder = 1 THEN WOBI.TotalWorkOrderCostPlus ELSE 0 END AS TotalBillingCostPlus,
				CASE WHEN ISNULL(WOBII.MaterialCost, 0) > 0 THEN 1 ELSE 0 END AS IsMaterialCheck,			
				WOBII.MaterialCost,NULL AS MaterialCostPercent,WOBII.MaterialCost,
				CASE WHEN ISNULL(WOBII.LaborCost, 0) > 0 THEN 1 ELSE 0 END AS IsLaborCheck,
				LaborCost,NULL AS LaborCostPercent,LaborCost,
				CASE WHEN ISNULL(WOBII.Freight, 0) > 0 THEN 1 ELSE 0 END AS IsFreightCheck,
				WOBII.Freight,NULL AS FreightCostPercent,WOBII.Freight,
				CASE WHEN ISNULL(WOBII.MiscCharges, 0) > 0 THEN 1 ELSE 0 END AS IsMiscChargesCheck,
				WOBII.MiscCharges, NULL AS MiscChargesCostPercent,WOBII.MiscCharges,
				CASE WHEN ISNULL(WOBII.SubTotal, 0) > 0 THEN WOBII.SubTotal ELSE WOBII.UnitPrice END AS SubTotal,		
				NULL,WOBII.SalesTax,NULL,WOBII.OtherTax,
				CASE WHEN ISNULL(WOBII.GrandTotal, 0) > 0 THEN WOBII.GrandTotal ELSE WOBII.UnitPrice END AS GrandTotal, 
				WOBI.RemainingAmount As RemainingAmount,
				WOBII.PDFPath,WOBII.VersionNo,WOBII.IsVersionIncrease,WOBII.IsPerformaInvoice,WOBII.MasterCompanyId,WOBII.CreatedBy,WOBII.UpdatedBy,
				WOBII.CreatedDate,WOBII.UpdatedDate,WOBII.IsActive,WOBII.IsDeleted,BI.WorkOrderShippingId, WOWF.WorkFlowWorkOrderId
			FROM dbo.WorkOrderBillingInvoicingItem WOBII 
				JOIN dbo.WorkOrderBillingInvoicing WOBI ON WOBII.BillingInvoicingId = WOBI.BillingInvoicingId
				JOIN dbo.BillingInvoicing BI ON BI.OldBillingInvoicingId = WOBII.BillingInvoicingId AND ModuleId = @ModuleId
				JOIN dbo.WorkOrderPartNumber WOP ON WOP.ID = WOBII.WorkOrderPartId
				JOIN dbo.WorkOrderWorkFlow WOWF ON WOP.ID = WOWF.WorkOrderPartNoId
			WHERE WOBII.MasterCompanyId = @MasterCompanyId and WOBII.MasterCompanyId <> 20 

			INSERT INTO BillingInvoicingDetails(BillingInvoicingId,SoldToCustomerId,SoldToSiteId,SoldToAttention,ShipToCustomerId,ShipToSiteId,ShipToAttention,
				CustomerDomensticShippingShipViaId,WayBillRef,ShipAccountInfo)
			SELECT BII.BillingInvoicingId , WOBI.SoldToCustomerId, WOBI.SoldToSiteId,NULL,WOBI.ShipToCustomerId,WOBI.ShipToSiteId,WOBI.ShipToAttention,
				WOBI.CustomerDomensticShippingShipViaId,WOBI.WayBillRef,WOBI.ShippingAccountInfo
			FROM dbo.BillingInvoicingItems BII
				JOIN dbo.BillingInvoicing BI ON BI.BillingInvoicingId = BII.BillingInvoicingId AND BI.ModuleId = @ModuleId
				JOIN dbo.WorkOrderBillingInvoicing WOBI ON BI.OldBillingInvoicingId = WOBI.BillingInvoicingId 
				JOIN dbo.WorkOrderBillingInvoicingItem WOBII ON  WOBII.BillingInvoicingId = WOBI.BillingInvoicingId 
			WHERE BII.ModuleId = @ModuleId AND BII.MasterCompanyId = @MasterCompanyId
		
		END
		ELSE
		BEGIN
			--Insert Into Billing Invoice Item
			INSERT INTO dbo.BillingInvoicingItems(OldWOBillingInvoicingItemId,OldBillingInvoicingId,BillingInvoicingId,ModuleId,ReferenceId,SubModuleId,SubReferenceId,ItemMasterId,StocklineId,ConditionId,CostPlusType,
			UnitPrice,QtyBilled,PartCost,IsTotalCheck,TotalBillingCost,TotalBillingCostPercent,TotalBillingCostPlus,IsMaterialCheck,MaterialCost,MaterialCostPercent,MaterialCostPlus,IsLaborCheck,LaborCost,
			LaborCostPercent,LaborCostPlus,IsFreightCheck,Freight,FreightCostPercent,FreightCostPlus,IsMiscChargesCheck,MiscCharges,MiscChargesCostPercent,MiscChargesCostPlus,
			SubTotal,SalesTaxPercent,SalesTax,OtherTaxPercent,OtherTax,GrandTotal, RemainingAmount , PDFPath,VersionNo,IsVersionIncrease,IsPerformaInvoice,MasterCompanyId,CreatedBy,UpdatedBy,
			CreatedDate,UpdatedDate,IsActive,IsDeleted,ShippingId, WorkFlowWorkOrderId)

			SELECT WOBII.WOBillingInvoicingItemId,WOBII.BillingInvoicingId, BI.BillingInvoicingId,@ModuleId,BI.ReferenceId,@SubModuleId,WOBII.WorkOrderPartId,
				CASE WHEN WOP.RevisedPartId > 0 THEN WOP.RevisedPartId ELSE WOP.ItemMasterId END AS ItemMasterId,
				WOP.StocklineId,
				CASE WHEN WOP.RevisedConditionId > 0 THEN WOP.RevisedConditionId ELSE WOP.ConditionId END AS ConditionId,
				BI.CostPlusType,
				UnitPrice,WOBII.NoofPieces, (UnitPrice * WOBII.NoofPieces) AS PartCost, 
				WOBI.TotalWorkOrder AS IsTotalCheck,  
				CASE WHEN ISNULL(WOBII.SubTotal, 0) > 0 THEN WOBII.SubTotal ELSE UnitPrice END AS TotalBillingCost,
				NULL TotalBillingCostPercent,
				CASE WHEN ISNULL(WOBII.SubTotal, 0) > 0 THEN WOBII.SubTotal ELSE UnitPrice END AS TotalBillingCostPlus,
				CASE WHEN ISNULL(WOBII.MaterialCost, 0) > 0 THEN 1 ELSE 0 END AS IsMaterialCheck,			
				WOBII.MaterialCost,NULL AS MaterialCostPercent,WOBII.MaterialCost,
				CASE WHEN ISNULL(WOBII.LaborCost, 0) > 0 THEN 1 ELSE 0 END AS IsLaborCheck,
				LaborCost,NULL AS LaborCostPercent,LaborCost,
				CASE WHEN ISNULL(WOBII.Freight, 0) > 0 THEN 1 ELSE 0 END AS IsFreightCheck,
				WOBII.Freight,NULL AS FreightCostPercent,WOBII.Freight,
				CASE WHEN ISNULL(WOBII.MiscCharges, 0) > 0 THEN 1 ELSE 0 END AS IsMiscChargesCheck,
				WOBII.MiscCharges, NULL AS MiscChargesCostPercent,WOBII.MiscCharges,
				CASE WHEN ISNULL(WOBII.SubTotal, 0) > 0 THEN WOBII.SubTotal ELSE WOBII.UnitPrice END AS SubTotal,		
				NULL,WOBII.SalesTax,NULL,WOBII.OtherTax,
				CASE WHEN ISNULL(WOBII.GrandTotal, 0) > 0 THEN WOBII.GrandTotal ELSE WOBII.UnitPrice END AS GrandTotal, 
				WOBI.RemainingAmount As RemainingAmount,
				WOBII.PDFPath,WOBII.VersionNo,WOBII.IsVersionIncrease,WOBII.IsPerformaInvoice,WOBII.MasterCompanyId,WOBII.CreatedBy,WOBII.UpdatedBy,
				WOBII.CreatedDate,WOBII.UpdatedDate,WOBII.IsActive,WOBII.IsDeleted,BI.WorkOrderShippingId, WOWF.WorkFlowWorkOrderId
			FROM dbo.WorkOrderBillingInvoicingItem WOBII 
				JOIN dbo.WorkOrderBillingInvoicing WOBI ON WOBII.BillingInvoicingId = WOBI.BillingInvoicingId
				JOIN dbo.BillingInvoicing BI ON BI.OldBillingInvoicingId = WOBII.BillingInvoicingId
				JOIN dbo.WorkOrderPartNumber WOP ON WOP.ID = WOBII.WorkOrderPartId
				JOIN dbo.WorkOrderWorkFlow WOWF ON WOP.ID = WOWF.WorkOrderPartNoId
			WHERE WOBII.MasterCompanyId = @MasterCompanyId and WOBII.MasterCompanyId = 20 AND ModuleId = @ModuleId

			INSERT INTO BillingInvoicingDetails(BillingInvoicingId,SoldToCustomerId,SoldToSiteId,SoldToAttention,ShipToCustomerId,ShipToSiteId,ShipToAttention,
				CustomerDomensticShippingShipViaId,WayBillRef,ShipAccountInfo)
			SELECT BII.BillingInvoicingId , WOBI.SoldToCustomerId, WOBI.SoldToSiteId,NULL,WOBI.ShipToCustomerId,WOBI.ShipToSiteId,WOBI.ShipToAttention,
				WOBI.CustomerDomensticShippingShipViaId,WOBI.WayBillRef,WOBI.ShippingAccountInfo
			FROM dbo.BillingInvoicingItems BII
				JOIN dbo.BillingInvoicing BI ON BI.BillingInvoicingId = BII.BillingInvoicingId AND BI.ModuleId = @ModuleId
				JOIN dbo.WorkOrderBillingInvoicing WOBI ON BI.OldBillingInvoicingId = WOBI.BillingInvoicingId 
				JOIN dbo.WorkOrderBillingInvoicingItem WOBII ON  WOBII.BillingInvoicingId = WOBI.BillingInvoicingId
			WHERE BII.MasterCompanyId = @MasterCompanyId AND BII.ModuleId = @ModuleId AND WOBII.MasterCompanyId = 20
		END

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'            
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetBillingInvoicingDetails'             
			   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))			                                      
												   + '@Parameter2 = ''' + CAST(ISNULL(@ModuleId, '') AS VARCHAR(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH    
END