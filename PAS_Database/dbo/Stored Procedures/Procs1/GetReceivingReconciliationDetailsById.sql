/*************************************************************             
 ** File:   [GetReceivingReconciliationDetailsById]             
 ** Author:   
 ** Description: This stored procedure is used to get Receiving Reconciliation Details
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1                 unknown       Created 
	2    31/10/2023   Moin Bloch    Added FreightAdjustment,TaxAdjustment Fields
	3    08/11/2023   Moin Bloch    Added ControlNumber Field
	4    18/12/2023   Moin Bloch    Added Order By
	5    27/12/2023   Moin Bloch    Modified Remaining RRQty Changed and getting live RRQty From Stockline
    6    03/01/2024   Moin Bloch    Added IsSerialized Field
    7    18/12/2024   Devendra Shekh	Added QtyVariance,PriceVariance Field
	8    12/31/2024   RAJESH GAMI   Getting Vendor Proforma Invoice Amount From the PO/RO 
	9    03/01/2025   RAJESH GAMI   Modified logic for get the VEndorproforma Invoice Amount
	10   22/06/2026   Priyansh Patel  Added Stock and Purchase uom properties [PN-16939]
	11   26/06/2026   Priyansh Patel  Convert All qty and cost uom for purchaseorder from Stock to Purchase uom  [PN-16941]

	
--  EXEC GetReceivingReconciliationDetailsById 136

************************************************************************/
CREATE    PROCEDURE [dbo].[GetReceivingReconciliationDetailsById]
@ReceivingReconciliationId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	            DECLARE @NONStockModuleID INT = 11;
	            DECLARE @ModuleID INT = 2;
				DECLARE @AssetModuleID varchar(500) ='42,43'

				SELECT    JBD.[ReceivingReconciliationDetailId]
				,JBD.[ReceivingReconciliationId]
				,JBD.[StocklineId]
				,JBD.[StocklineNumber]
				,JBD.[ItemMasterId]
				,JBD.[PartNumber]
				,JBD.[PartDescription]
				,JBD.[SerialNumber]
				,JBD.[POReference]
				,CASE WHEN JBD.[Type] = 1 AND PO.PurchaseOrderId IS NOT NULL THEN IM.[PurchaseUnitOfMeasure]
					  WHEN JBD.[Type] = 2 AND RO.RepairOrderId IS NOT NULL THEN IM.[StockUnitOfMeasure]
				 ELSE '' END AS UnitOfMeasure
				,CASE WHEN JBD.[Type] = 1 AND PO.PurchaseOrderId IS NOT NULL AND NULLIF(IM.StockUnitOfMeasure, '') IS NOT NULL AND NULLIF(IM.PurchaseUnitOfMeasure, '') IS NOT NULL AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure THEN dbo.fn_ConvertUOM(JBD.[POQtyOrder], IM.StockUnitOfMeasure, IM.PurchaseUnitOfMeasure, 0, IM.MasterCompanyId)
				 ELSE JBD.[POQtyOrder]  END AS POQtyOrder
				,CASE WHEN JBD.[Type] = 1 AND PO.PurchaseOrderId IS NOT NULL THEN CASE WHEN NULLIF(IM.StockUnitOfMeasure, '') IS NULL OR NULLIF(IM.PurchaseUnitOfMeasure, '') IS NULL OR IM.StockUnitOfMeasure = IM.PurchaseUnitOfMeasure THEN JBD.[ReceivedQty]
				 ELSE dbo.fn_ConvertUOM(JBD.[ReceivedQty], IM.StockUnitOfMeasure, IM.PurchaseUnitOfMeasure, 0, IM.MasterCompanyId) END
				 ELSE JBD.[ReceivedQty] END AS ReceivedQty
				,CASE WHEN JBD.[Type] = 1 AND PO.PurchaseOrderId IS NOT NULL AND NULLIF(IM.StockUnitOfMeasure, '') IS NOT NULL AND NULLIF(IM.PurchaseUnitOfMeasure, '') IS NOT NULL AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure THEN dbo.fn_ConvertUOM(JBD.[POUnitCost], IM.StockUnitOfMeasure, IM.PurchaseUnitOfMeasure, 1, IM.MasterCompanyId)
				 ELSE JBD.[POUnitCost] END AS POUnitCost
				,CASE WHEN JBD.[Type] = 1 AND PO.PurchaseOrderId IS NOT NULL AND NULLIF(IM.StockUnitOfMeasure, '') IS NOT NULL AND NULLIF(IM.PurchaseUnitOfMeasure, '') IS NOT NULL AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure THEN dbo.fn_ConvertUOM(JBD.[POExtCost], IM.StockUnitOfMeasure, IM.PurchaseUnitOfMeasure, 1, IM.MasterCompanyId)
				 ELSE JBD.[POExtCost] END AS POExtCost
				,CASE WHEN JBD.[Type] = 1 AND PO.PurchaseOrderId IS NOT NULL AND NULLIF(IM.StockUnitOfMeasure, '') IS NOT NULL AND NULLIF(IM.PurchaseUnitOfMeasure, '') IS NOT NULL AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure THEN dbo.fn_ConvertUOM(JBD.[InvoicedQty], IM.StockUnitOfMeasure, IM.PurchaseUnitOfMeasure, 0, IM.MasterCompanyId)
				 ELSE JBD.[InvoicedQty] END AS InvoicedQty
				,CASE WHEN JBD.[Type] = 1 AND PO.PurchaseOrderId IS NOT NULL AND NULLIF(IM.StockUnitOfMeasure, '') IS NOT NULL AND NULLIF(IM.PurchaseUnitOfMeasure, '') IS NOT NULL AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure THEN dbo.fn_ConvertUOM(JBD.[InvoicedUnitCost], IM.StockUnitOfMeasure, IM.PurchaseUnitOfMeasure, 1, IM.MasterCompanyId)
				 ELSE JBD.[InvoicedUnitCost] END AS InvoicedUnitCost
				,JBD.[InvoicedExtCost]
				,JBD.[AdjQty]
				,JBD.[AdjUnitCost]
				,JBD.[AdjExtCost]
				,JBD.[APNumber]
				,JBD.[PurchaseOrderId]
				,JBD.[PurchaseOrderPartRecordId]
				,JBD.[IsManual]
				,JBD.[PackagingId]
				,JBD.[Description]
				,JBD.[GlAccountId]
				,[Type]
				,[StockType]
				,ISNULL([QtyVariance], 0) AS [QtyVariance]
				,ISNULL([PriceVariance], 0) AS [PriceVariance]
				,CASE WHEN UPPER(JBD.[StockType]) = 'STOCK' AND JBD.[Type] = 1 AND PO.PurchaseOrderId IS NOT NULL
				THEN CASE WHEN NULLIF(IM.StockUnitOfMeasure, '') IS NULL OR NULLIF(IM.PurchaseUnitOfMeasure, '') IS NULL OR IM.StockUnitOfMeasure = IM.PurchaseUnitOfMeasure
				THEN SLI.RRQty
				ELSE dbo.fn_ConvertUOM(SLI.RRQty, IM.StockUnitOfMeasure, IM.PurchaseUnitOfMeasure, 0, IM.MasterCompanyId)
				END
				WHEN UPPER(JBD.[StockType]) = 'STOCK' THEN SLI.RRQty
				WHEN UPPER(JBD.[StockType]) = 'NONSTOCK' THEN NSI.RRQty
				WHEN UPPER(JBD.[StockType]) = 'ASSET' THEN ASI.RRQty
				ELSE NULL END AS RemainingRRQty
				,CASE WHEN UPPER(JBD.[StockType])= 'STOCK' THEN SLI.isSerialized 
				WHEN UPPER(JBD.[StockType])= 'NONSTOCK' THEN NSI.isSerialized 
				WHEN UPPER(JBD.[StockType])= 'ASSET' THEN ASI.isSerialized ELSE 0 END AS IsSerialized
				,[JBD].[FreightAdjustment]
				,[JBD].[TaxAdjustment]
				,[JBD].[FreightAdjustmentPerUnit]
				,[JBD].[TaxAdjustmentPerUnit]
				,CASE WHEN UPPER(JBD.StockType)= 'STOCK' THEN UPPER(SLI.ControlNumber) 
				WHEN UPPER(JBD.StockType)= 'NONSTOCK' THEN UPPER(NSI.ControlNumber) 
				WHEN UPPER(JBD.StockType)= 'ASSET' THEN UPPER(ASI.ControlNumber) ELSE '' END AS ControlNumber
				,CASE WHEN UPPER(JBD.StockType)= 'STOCK' THEN UPPER(MSD.Level1Name) 
				WHEN UPPER(JBD.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level1Name) 
				WHEN UPPER(JBD.StockType)= 'ASSET' THEN UPPER(AMSD.Level1Name) ELSE '' END  AS level1
				,CASE WHEN UPPER(JBD.StockType)= 'STOCK' THEN UPPER(MSD.Level2Name) 
				WHEN UPPER(JBD.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level2Name) 
				WHEN UPPER(JBD.StockType)= 'ASSET' THEN UPPER(AMSD.Level2Name) ELSE '' END  AS level2
				,CASE WHEN UPPER(JBD.StockType)= 'STOCK' THEN UPPER(MSD.Level3Name) 
				WHEN UPPER(JBD.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level3Name) 
				WHEN UPPER(JBD.StockType)= 'ASSET' THEN UPPER(AMSD.Level3Name) ELSE '' END  AS level3
				,CASE WHEN UPPER(JBD.StockType)= 'STOCK' THEN UPPER(MSD.Level4Name) 
				WHEN UPPER(JBD.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level4Name) 
				WHEN UPPER(JBD.StockType)= 'ASSET' THEN UPPER(AMSD.Level4Name) ELSE '' END  AS level4
				,CASE WHEN UPPER(JBD.StockType)= 'STOCK' THEN UPPER(MSD.Level5Name) 
				WHEN UPPER(JBD.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level5Name) 
				WHEN UPPER(JBD.StockType)= 'ASSET' THEN UPPER(AMSD.Level5Name) ELSE '' END  AS level5
				,CASE WHEN UPPER(JBD.StockType)= 'STOCK' THEN UPPER(MSD.Level6Name) 
				WHEN UPPER(JBD.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level6Name) 
				WHEN UPPER(JBD.StockType)= 'ASSET' THEN UPPER(AMSD.Level6Name) ELSE '' END  AS level6
				,CASE WHEN UPPER(JBD.StockType)= 'STOCK' THEN UPPER(MSD.Level7Name) 
				WHEN UPPER(JBD.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level7Name) 
				WHEN UPPER(JBD.StockType)= 'ASSET' THEN UPPER(AMSD.Level7Name) ELSE '' END  AS level7
				,CASE WHEN UPPER(JBD.StockType)= 'STOCK' THEN UPPER(MSD.Level8Name) 
				WHEN UPPER(JBD.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level8Name) 
				WHEN UPPER(JBD.StockType)= 'ASSET' THEN UPPER(AMSD.Level8Name) ELSE '' END  AS level8
				,CASE WHEN UPPER(JBD.StockType)= 'STOCK' THEN UPPER(MSD.Level9Name) 
				WHEN UPPER(JBD.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level9Name) 
				WHEN UPPER(JBD.StockType)= 'ASSET' THEN UPPER(AMSD.Level9Name) ELSE '' END  AS level9
				,CASE WHEN UPPER(JBD.StockType)= 'STOCK' THEN UPPER(MSD.Level10Name) 
				WHEN UPPER(JBD.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level10Name) 
				WHEN UPPER(JBD.StockType)= 'ASSET' THEN UPPER(AMSD.Level10Name) ELSE '' END  AS level10,

				CASE WHEN  ISNULL(JBH.VendorProformaAmount,0) > 0 THEN ISNULL(JBH.VendorProformaAmount,0) ELSE (CASE WHEN [Type] = 1 THEN ISNULL(Po.DepositAmount,0) ELSE ISNULL(RO.DepositAmount,0) END)END AS VendorProformaAmount,
				(CASE WHEN [Type] = 1 THEN ISNULL(Po.VendorProformaInvoiceNo,'') ELSE ISNULL(RO.VendorProformaInvoiceNo,'') END) AS VendorProformaInvoiceNo,
				(CASE WHEN [Type] = 1 THEN ISNULL(Po.VendorProformaInvoiceId,0) ELSE ISNULL(RO.VendorProformaInvoiceId,0) END) AS VendorProformaInvoiceId

				 FROM [dbo].[ReceivingReconciliationDetails] JBD WITH(NOLOCK)
					 INNER JOIN [dbo].[ReceivingReconciliationHeader] JBH WITH(NOLOCK) ON JBD.ReceivingReconciliationId=JBH.ReceivingReconciliationId	
					 INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId= JBD.[ItemMasterId]					 
					 
					  LEFT JOIN [dbo].[Stockline] SLI WITH(NOLOCK) ON SLI.[StockLineId] = JBD.[StockLineId] AND UPPER(JBD.StockType)= 'STOCK'						
					  LEFT JOIN [dbo].[NonStockInventory] NSI WITH(NOLOCK) ON NSI.[NonStockInventoryId] = JBD.[StockLineId] AND UPPER(JBD.StockType)= 'NONSTOCK'					  
					  LEFT JOIN [dbo].[AssetInventory] ASI WITH(NOLOCK) ON ASI.[AssetInventoryId] = JBD.[StockLineId] AND UPPER(JBD.StockType)= 'ASSET'
					  LEFT JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = JBD.StockLineId AND UPPER(JBD.StockType)= 'STOCK'
					  LEFT JOIN [dbo].[EntityStructureSetup] ES WITH (NOLOCK) ON ES.EntityStructureId=MSD.EntityMSID
					  LEFT JOIN [dbo].[NonStocklineManagementStructureDetails] NMSD WITH (NOLOCK) ON NMSD.ModuleID = @NONStockModuleID AND NMSD.ReferenceID = JBD.StockLineId AND UPPER(JBD.StockType)= 'NONSTOCK'
					  LEFT JOIN [dbo].[EntityStructureSetup] NES WITH (NOLOCK) ON NES.EntityStructureId=NMSD.EntityMSID
					  LEFT JOIN [dbo].[AssetManagementStructureDetails] AMSD WITH (NOLOCK) ON AMSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AssetModuleID,',')) AND AMSD.ReferenceID = JBD.StockLineId AND UPPER(JBD.StockType)= 'ASSET'
					  LEFT JOIN [dbo].[EntityStructureSetup] AES WITH (NOLOCK) ON AES.EntityStructureId=AMSD.EntityMSID			
					  LEFT JOIN [dbo].PurchaseOrder PO WITH (NOLOCK) ON JBD.PurchaseOrderId = PO.PurchaseOrderId AND JBD.[Type] = 1
					  LEFT JOIN [dbo].RepairOrder RO WITH (NOLOCK) ON JBD.PurchaseOrderId = RO.RepairOrderId AND JBD.[Type] = 2
				WHERE JBD.[ReceivingReconciliationId] =@ReceivingReconciliationId ORDER BY JBD.[ReceivingReconciliationDetailId]
    END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReceivingReconciliationDetailsById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReceivingReconciliationId, '') + ''
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