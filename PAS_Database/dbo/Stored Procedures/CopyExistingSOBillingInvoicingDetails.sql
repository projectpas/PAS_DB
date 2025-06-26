/*************************************************************           
 ** File:   [CopyExistingBillingSOInvoicingDetails]           
 ** Author:   HEMANT SALIYA
 ** Description: Copy SO Billing Invoicing Details
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
CREATE   PROCEDURE [dbo].[CopyExistingSOBillingInvoicingDetails]
@MasterCompanyId BIGINT = NULL
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	 BEGIN TRY  	
	
		DECLARE @ModuleId BIGINT;
		DECLARE @SubModuleId BIGINT;
		
		SET @ModuleId = 10; --Sales Order
		SET @SubModuleId = 66; --Sales Order Part

		--Select * from BillingInvoicing WHERE MasterCompanyId = 2
		--Select * from dbo.BillingInvoicingItems WHERE MasterCompanyId = 2
		--Select * from dbo.BillingInvoicingDetails
		--Select NetSaleAmountPerUnit AS UNITPRiCE,  * from SalesOrderStockLineCost

		--Insert Into Billing Invoice 
		INSERT INTO dbo.BillingInvoicing(OldBillingInvoicingId,ModuleId,ReferenceId,CustomerId, InvoiceTypeId,InvoiceNo,InvoiceDate,InvoiceTime,PrintDate,EmployeeId,CurrencyId,RevisionTypeId
			,InvoiceStatusId,InvoiceStatus,InvoiceFilePath,RevType,VersionNo,CostPlusType,IsPerformaInvoice,IsVersionIncrease,PostedDate,SubTotal,OtherTax,SalesTax,DepositAmount,GrandTotal
			,IsInvoicePosted,UsedDeposit,ProformaDeposit,RemainingAmount,Notes,WorkOrderShippingId,ManagementStructureId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive
			,IsDeleted,IsReversedJE,QuickBooksReferenceId,IsUpdated,LastSyncDate,SyncToken,IsCreatedFromQuote,IsQuickBookGeneratedInvoice)

		SELECT SOBI.SOBillingInvoicingId,@ModuleId,SOBI.SalesOrderId,SOBI.CustomerId, InvoiceTypeId,InvoiceNo,InvoiceDate,NULL AS InvoiceTime,PrintDate,SOBI.EmployeeId,SOBI.CurrencyId,NULL AS RevisionTypeId,NULL,InvoiceStatus,InvoiceFilePath,
			RevType,SOBI.VersionNo,NULL AS CostPlusType,IsProforma,SOBI.IsVersionIncrease,PostedDate,SOBI.SubTotal,SOBI.OtherTax,SOBI.SalesTax,SOBI.DepositAmount,SOBI.GrandTotal,			
			CASE WHEN SOBI.InvoiceStatus = 'Invoiced' THEN 1 ELSE 0 END AS IsInvoicePosted,
			UsedDeposit,ProformaDeposit,RemainingAmount
			,NULL AS Notes,NULL AS WorkOrderShippingId,ManagementStructureId,SOBI.MasterCompanyId,SOBI.CreatedBy,SOBI.UpdatedBy,SOBI.CreatedDate,SOBI.UpdatedDate,SOBI.IsActive,SOBI.IsDeleted,0,QuickBooksReferenceId,IsUpdated,LastSyncDate
			,SyncToken,NULL AS isCreatedFromQuote,IsQuickBookGeneratedInvoice
		FROM dbo.SalesOrderBillingInvoicing SOBI 
		JOIN SalesOrder SO ON SOBI.SalesOrderId = SO.SalesOrderId
		WHERE SOBI.MasterCompanyId = @MasterCompanyId


		--SELECT top 100  * from dbo.SalesOrderBillingInvoicing where MasterCompanyId = 1 and IsVersionIncrease = 0 Order by 1 desc
		--SELECT * from dbo.BillingInvoicingItems where MasterCompanyId = 2 and IsVersionIncrease = 0
		--SELECT top 200 * from dbo.SalesOrderBillingInvoicingItem where MasterCompanyId = 1 and IsVersionIncrease = 0 Order by 1 desc

		--Update InvoiceStatusId based on status and Path from item
		UPDATE dbo.BillingInvoicing SET InvoiceStatusId = INS.InvoiceStatusId 
		FROM dbo.BillingInvoicing BI 
		LEFT JOIN dbo.InvoiceStatus INS ON UPPER(BI.InvoiceStatus) = UPPER(INS.Status)	
		WHERE BI.MasterCompanyId = @MasterCompanyId

		--Insert Into Billing Invoice Item
		INSERT INTO dbo.BillingInvoicingItems(OldWOBillingInvoicingItemId,OldBillingInvoicingId,BillingInvoicingId,ModuleId,ReferenceId,SubModuleId,SubReferenceId,ItemMasterId,StocklineId,ConditionId,CostPlusType,
		UnitPrice,QtyBilled,PartCost,IsTotalCheck,TotalBillingCost,TotalBillingCostPercent,TotalBillingCostPlus,IsMaterialCheck,MaterialCost,MaterialCostPercent,MaterialCostPlus,IsLaborCheck,LaborCost,
		LaborCostPercent,LaborCostPlus,IsFreightCheck,Freight,FreightCostPercent,FreightCostPlus,IsMiscChargesCheck,MiscCharges,MiscChargesCostPercent,MiscChargesCostPlus,
		SubTotal,SalesTaxPercent,SalesTax,OtherTaxPercent,OtherTax,GrandTotal, RemainingAmount , PDFPath,VersionNo,IsVersionIncrease,IsPerformaInvoice,MasterCompanyId,CreatedBy,UpdatedBy,
		CreatedDate,UpdatedDate,IsActive,IsDeleted,ShippingId, WorkFlowWorkOrderId)

		SELECT SOBII.SOBillingInvoicingItemId,SOBII.SOBillingInvoicingId, BI.BillingInvoicingId,@ModuleId,BI.ReferenceId,@SubModuleId,SOBII.SalesOrderPartId,
			SOP.ItemMasterId,
			SOBII.StocklineId,
			SOP.ConditionId,
			BI.CostPlusType,
			SOC.NetSaleAmountPerUnit AS UnitPrice,
			SOBII.NoofPieces, 
			CASE WHEN SOBI.IsProforma = 1 THEN SOC.NetSaleAmount ELSE (SOBII.NoofPieces * SOC.NetSaleAmountPerUnit) END AS PartCost, 
			0 AS IsTotalCheck,  
			CASE WHEN ISNULL(SOBII.SubTotal, 0) > 0 THEN SOBII.SubTotal ELSE SOBII.PartCost END AS TotalBillingCost,
			NULL TotalBillingCostPercent,
			CASE WHEN ISNULL(SOBII.SubTotal, 0) > 0 THEN SOBII.SubTotal ELSE SOBII.PartCost END AS TotalBillingCostPlus,
			0 AS IsMaterialCheck,			
			NULL AS  MaterialCost,NULL AS MaterialCostPercent,NULL AS MaterialCost,
			0 AS IsLaborCheck,
			NULL LaborCost,NULL AS LaborCostPercent,NULL LaborCost,
			CASE WHEN ISNULL(SOBII.Freight, 0) > 0 THEN 1 ELSE 0 END AS IsFreightCheck,
			SOBII.Freight,NULL AS FreightCostPercent,SOBII.Freight,
			CASE WHEN ISNULL(SOBII.MiscCharges, 0) > 0 THEN 1 ELSE 0 END AS IsMiscChargesCheck,
			SOBII.MiscCharges, NULL AS MiscChargesCostPercent,SOBII.MiscCharges,
			CASE WHEN ISNULL(SOBII.SubTotal, 0) > 0 THEN SOBII.SubTotal ELSE SOBII.PartCost END AS SubTotal,		
			NULL,SOBII.SalesTax,NULL,SOBII.OtherTax,
			CASE WHEN ISNULL(SOBII.GrandTotal, 0) > 0 THEN SOBII.GrandTotal ELSE SOBII.PartCost END AS GrandTotal, 
			SOBI.RemainingAmount As RemainingAmount,
			SOBII.PDFPath,SOBII.VersionNo,SOBII.IsVersionIncrease,SOBII.IsProforma,SOBII.MasterCompanyId,SOBII.CreatedBy,SOBII.UpdatedBy,
			SOBII.CreatedDate,SOBII.UpdatedDate,SOBII.IsActive,SOBII.IsDeleted,BI.WorkOrderShippingId, NULL AS WorkFlowWorkOrderId
		FROM dbo.SalesOrderBillingInvoicingItem SOBII 
			JOIN dbo.SalesOrderBillingInvoicing SOBI ON SOBII.SOBillingInvoicingId = SOBI.SOBillingInvoicingId
			JOIN dbo.BillingInvoicing BI ON BI.OldBillingInvoicingId = SOBII.SOBillingInvoicingId
			JOIN dbo.SalesOrderPartV1 SOP ON SOP.SalesOrderPartId = SOBII.SalesOrderPartId
			JOIN dbo.SalesOrderStocklineV1 SOST ON SOP.SalesOrderPartId = SOST.SalesOrderPartId
			JOIN dbo.SalesOrderStockLineCost SOC ON SOST.SalesOrderStocklineId = SOC.SalesOrderStocklineId
		WHERE SOBII.MasterCompanyId = @MasterCompanyId 


		INSERT INTO BillingInvoicingDetails(BillingInvoicingId,SoldToCustomerId,SoldToSiteId,SoldToAttention,ShipToCustomerId,ShipToSiteId,ShipToAttention,
			CustomerDomensticShippingShipViaId,WayBillRef,ShipAccountInfo)
		SELECT BII.BillingInvoicingId , SOBI.SoldToCustomerId, SOBI.SoldToSiteId,NULL,SOBI.ShipToCustomerId,SOBI.ShipToSiteId,SOBI.ShipToAttention,
			NULL AS CustomerDomensticShippingShipViaId,NULL AS WayBillRef,NULL AS ShippingAccountInfo
		FROM dbo.BillingInvoicingItems BII
			JOIN dbo.BillingInvoicing BI ON BI.BillingInvoicingId = BII.BillingInvoicingId
			JOIN dbo.SalesOrderBillingInvoicing SOBI ON BI.OldBillingInvoicingId = SOBI.SOBillingInvoicingId 
			JOIN dbo.SalesOrderBillingInvoicingItem SOBII ON  SOBII.SoBillingInvoicingId = SOBI.SOBillingInvoicingId
		


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