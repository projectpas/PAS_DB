/*************************************************************           
 ** File:   [sp_GetCustomerRMAPartsDetails]           
 ** Author:   Subhash Saliya
 ** Description: Get Customer RMAPartsDetails
 ** Purpose:         
 ** Date:   20-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		  Change Description            
 ** --   --------     -------		  --------------------------------          
    1    04/20/2022   Subhash Saliya  Created
	2	 02/1/2024	  AMIT GHEDIYA	  added isperforma Flage for SO
	3    03/27/2024   Hemant Saliya   Updated for Part wise Billing Amy Details
	4    04/04/2024   Hemant Saliya   Updated for -Ve for CM
	
 -- exec sp_GetCustomerRMAPartsDetails 120,0,13,1    
**************************************************************/ 

CREATE   Procedure [dbo].[sp_GetCustomerRMAPartsDetails]
@InvoicingId bigint,
@IsWorkOrder  bit,
@RMAHeaderId  BIGINT,
@Ispopup bit = 0
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
			IF(@Ispopup =1)
			BEGIN
				IF(@isWorkOrder = 0)
				BEGIN
					SELECT SOBI.SOBillingInvoicingId AS InvoiceId,SOBI.InvoiceNo [InvoiceNo],SOBII.SOBillingInvoicingItemId as BillingInvoicingItemId,
						SOBI.InvoiceStatus [InvoiceStatus],SOBI.InvoiceDate [InvoiceDate],SO.SalesOrderNumber as ReferenceNo,
						IM.ItemMasterId [ItemMasterId],IM.partnumber [PartNumber], IM.PartDescription [PartDescription],'' as CustPartNumber,
						SOPN.CustomerReference [CustomerReference],ST.SerialNumber [SerialNumber],ST.StocklineNumber as StocklineNumber ,st.Stocklineid as StocklineId,
						ST.ControlNumber as ControlNumber,ST.IdNumber as ControlId, SOBII.NoofPieces as Qty, SOBII.UnitPrice As [PartsUnitCost],
						(SOBII.PartCost * -1) As [PartsRevenue], 
						0 AS [LaborRevenue], 
						(SOBII.MiscCharges * -1) AS [MiscRevenue], 
						(SOBII.Freight * -1) AS [FreightRevenue],
						(ISNULL(SOBII.NoofPieces, 1) * ISNULL(SOPN.UnitSalesPricePerUnit, 0)) AS [COGSParts], 
						0 AS [COGSLabor], 0 AS [COGSOverHeadCost], --SOF.BillingAmount, SOC.BillingAmount,
						(ISNULL(SOBII.NoofPieces, 1) * ISNULL(SOPN.UnitSalesPricePerUnit, 0)) AS [COGSInventory], 
						ISNULL(SOPN.UnitSalesPricePerUnit, 0) AS [COGSPartsUnitCost],
						CASE WHEN ISNULL(SOBII.NoofPieces,0) > 0 THEN (SOBII.GrandTotal / SOBII.NoofPieces) ELSE SOBII.GrandTotal END AS UnitPrice,
						(ISNULL(SOBII.NoofPieces, 1) * ISNULL(SOBII.UnitPrice, 0)) as Amount,
						IsWorkOrder=0,SOBI.SalesOrderId AS [ReferenceId],
						RMAC.RMAReasonId,RMAC.RMAReason,RMAC.RMAStatusId,RMAC.RMAStatus,RMAC.RMAValiddate,
						SOBII.SubTotal,
						(SOBII.SalesTax * -1) As SalesTax, 
						(SOBII.OtherTax * -1) As OtherTax, 
						(SOBII.GrandTotal * -1) AS GrandTotal, 
						(SOBII.GrandTotal * -1) AS [InvoiceAmt],
						'0' as [RMADeatilsId],
						'0' as [RMAHeaderId],
						'' as [Notes],
						SOBI.[MasterCompanyId],
						SOBI.[CreatedBy],
						SOBI.[UpdatedBy],
						SOBI.[CreatedDate],
						SOBI.[UpdatedDate],
						SOBI.[IsActive],
						SOBI.[IsDeleted],
						ST.isSerialized,
						SOBII.NoofPieces as InvoiceQty,
						IM.ManufacturerName,
						AltPartNumber=(  
						 Select top 1  
						A.PartNumber [AltPartNumberType] from [dbo].[SalesOrderBillingInvoicingItem] SOBIIA WITH (NOLOCK) 
						OUTER APPLY(  
						 SELECT   
							STUFF((SELECT CASE WHEN LEN(AI.partnumber) >0 THEN ',' ELSE '' END + AI.partnumber  
							 FROM [dbo].[Nha_Tla_Alt_Equ_ItemMapping] AL WITH (NOLOCK)  
							 INNER JOIN [dbo].[ItemMaster] I WITH (NOLOCK) ON AL.ItemMasterId=I.ItemMasterId 
							 INNER JOIN [dbo].[ItemMaster] AI WITH (NOLOCK) ON AL.MappingItemMasterId=AI.ItemMasterId 
							 Where I.ItemMasterId = SOBIIA.ItemMasterId  and MappingType=1  
							 AND AL.IsActive = 1 AND AL.IsDeleted = 0  
							 FOR XML PATH('')), 1, 1, '') PartNumber  
						) A  
						WHERE SOBIIA.MasterCompanyId=SOBII.MasterCompanyId AND SOBIIA.ItemMasterId =SOBII.ItemMasterId and SOBIIA.SOBillingInvoicingId =SOBII.SOBillingInvoicingId AND ISNULL(SOBII.IsDeleted,0)=0 AND ISNULL(SOBIIA.IsProforma,0) = 0
						GROUP BY SOBIIA.ItemMasterId, A.PartNumber  
						) 
					FROM [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK)
						LEFT JOIN [dbo].[SalesOrderBillingInvoicingItem] SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId = SOBI.SOBillingInvoicingId AND ISNULL(SOBII.IsProforma,0) = 0
						LEFT JOIN [dbo].[SalesOrderPart] SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.SalesOrderId AND SOPN.SalesOrderPartId = SOBII.SalesOrderPartId
						LEFT JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SOBI.SalesOrderId = SO.SalesOrderId
						LEFT JOIN [dbo].[SalesOrderFreight] SOF WITH (NOLOCK) ON SOF.SalesOrderPartId = SOPN.SalesOrderPartId
						LEFT JOIN [dbo].[SalesOrderCharges] SOC WITH (NOLOCK) ON SOC.SalesOrderPartId = SOPN.SalesOrderPartId
						LEFT JOIN [dbo].[SalesOrderQuote] SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId = SO.SalesOrderQuoteId
						LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SOBII.ItemMasterId=IM.ItemMasterId
						LEFT JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId AND ST.IsParent = 1
						LEFT JOIN [dbo].[RMACreditMemoSettings] RMAC WITH (NOLOCK) ON so.MasterCompanyId = RMAC.MasterCompanyId
					WHERE SOBI.SOBillingInvoicingId=@InvoicingId AND ISNULL(SOBI.IsProforma,0) = 0		
				END
				ELSE 
				BEGIN 
					SELECT WOBI.BillingInvoicingId as InvoiceId, WOBI.InvoiceNo [InvoiceNo], WOBII.WOBillingInvoicingItemId as BillingInvoicingItemId,
						WOBI.InvoiceStatus [InvoiceStatus], WOBI.InvoiceDate [InvoiceDate], WO.WorkOrderNum as ReferenceNo,				
						IM.ItemMasterId [ItemMasterId],IM.partnumber [PartNumber], IM.PartDescription [PartDescription],'' as AltPartNumber,'' as CustPartNumber,
						WOPN.CustomerReference [CustomerReference],ST.SerialNumber [SerialNumber],ST.StocklineNumber as StocklineNumber ,st.Stocklineid as StocklineId,
						ST.ControlNumber as ControlNumber,ST.IdNumber as ControlId,WOBII.NoofPieces as Qty,WOBII.GrandTotal as UnitPrice,(WOBII.NoofPieces * WOBII.GrandTotal)  as Amount,
						RMAC.RMAReasonId,RMAC.RMAReason,RMAC.RMAStatusId,RMAC.RMAStatus,RMAC.RMAValiddate,
						IsWorkOrder=1,WOBI.WorkOrderId AS [ReferenceId], WOBII.MaterialCost As [PartsUnitCost],
						(WOBII.MaterialCost * -1) As [PartsRevenue], 
						(WOBII.LaborCost * -1) AS  [LaborRevenue], 
						(WOBII.MiscCharges * -1) AS [MiscRevenue], 
						(WOBII.Freight * -1) AS [FreightRevenue],
						WOBII.SubTotal,
						(WOBII.SalesTax * -1) AS SalesTax, 
						(WOBII.OtherTax * -1) AS OtherTax, 
						(WOBII.GrandTotal * -1) AS GrandTotal, 
						(WOBII.GrandTotal * -1) AS [InvoiceAmt],
						WOMPN.PartsCost AS [COGSParts], WOMPN.LaborCost AS [COGSLabor] , WOMPN.OverHeadCost As [COGSOverHeadCost], 
						(ISNULL(WOMPN.PartsCost,0) + ISNULL(WOMPN.LaborCost,0) + ISNULL(WOMPN.OverHeadCost,0)) AS [COGSInventory],
						ISNULL(WOMPN.PartsCost, 0) AS [COGSPartsUnitCost],						
						'0' as [RMADeatilsId],
						'0' as [RMAHeaderId],
						'' as [Notes],
						WOBI.[MasterCompanyId],
						WOBI.[CreatedBy],
						WOBI.[UpdatedBy],
						WOBI.[CreatedDate],
						WOBI.[UpdatedDate],
						WOBI.[IsActive],
						WOBI.[IsDeleted],
						ST.isSerialized,
						WOBII.NoofPieces as InvoiceQty,
						IM.ManufacturerName,
						AltPartNumber=(  
						 SELECT TOP 1  
						A.PartNumber [AltPartNumberType] from [dbo].[WorkOrderBillingInvoicingItem] WOBIIA WITH (NOLOCK) 
						Outer Apply(  
						 SELECT   
							STUFF((SELECT CASE WHEN LEN(AI.partnumber) >0 then ',' ELSE '' END + AI.partnumber  
							 FROM [dbo].[Nha_Tla_Alt_Equ_ItemMapping] AL WITH (NOLOCK)  
							 INNER JOIN [dbo].[ItemMaster] I WITH (NOLOCK) On AL.ItemMasterId=I.ItemMasterId 
							 INNER JOIN [dbo].[ItemMaster] AI WITH (NOLOCK) On AL.MappingItemMasterId=AI.ItemMasterId 
							 Where I.ItemMasterId = WOBIIA.ItemMasterId  and MappingType=1  
							 AND AL.IsActive = 1 AND AL.IsDeleted = 0  
							 FOR XML PATH('')), 1, 1, '') PartNumber  
						) A  
						WHERE WOBIIA.MasterCompanyId=WOBII.MasterCompanyId and WOBIIA.ItemMasterId =WOBII.ItemMasterId  and WOBIIA.BillingInvoicingId =WOBII.BillingInvoicingId AND ISNULL(WOBII.IsDeleted,0)=0
						GROUP BY WOBIIA.ItemMasterId, A.PartNumber  
						) 
					FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK)
						LEFT JOIN [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId
						LEFT JOIN [dbo].[WorkOrderPartNumber] WOPN WITH (NOLOCK) ON WOPN.WorkOrderId = WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId
						LEFT JOIN [dbo].[WorkOrderMPNCostDetails] WOMPN WITH (NOLOCK) ON WOMPN.WorkOrderId = WOBI.WorkOrderId AND WOPN.ID = WOMPN.WOPartNoId
						LEFT JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
						LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON WOBII.ItemMasterId=IM.ItemMasterId
						LEFT JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId AND ST.IsParent = 1
						LEFT JOIN [dbo].[RMACreditMemoSettings] RMAC WITH (NOLOCK) ON WO.MasterCompanyId = RMAC.MasterCompanyId
					WHERE WOBI.BillingInvoicingId=@InvoicingId AND WOBI.IsVersionIncrease=0			
				END
			END
			ELSE 
			BEGIN
				DECLARE @InvoiceStatus VARCHAR(30)
				DECLARE @InvoiceId BIGINT
				SELECT @isWorkOrder =isWorkOrder,@InvoiceId= InvoiceId FROM [dbo].[CustomerRMAHeader]  WITH (NOLOCK) WHERE  RMAHeaderId =@RMAHeaderId
				IF(@isWorkOrder =1)
				BEGIN
					SELECT @InvoiceStatus = InvoiceStatus FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) WHERE  BillingInvoicingId =@InvoiceId
				END
				ELSE
				BEGIN
					SELECT @InvoiceStatus = InvoiceStatus FROM [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK) WHERE  SOBillingInvoicingId =@InvoiceId AND ISNULL(SOBI.IsProforma,0) = 0
				END
					SELECT CRM.[RMADeatilsId]
					   ,CRM.[RMAHeaderId],CRM.[ItemMasterId] ,CRM.[PartNumber] ,CRM.[PartDescription] ,CRM.[CustPartNumber] ,CRM.[SerialNumber]
					   ,CRM.[StocklineId] ,CRM.[StocklineNumber] ,CRM.[ControlNumber] ,CRM.[ControlId] ,CRM.[ReferenceId] ,CRM.[ReferenceNo]
					   ,CRM.[Qty] ,CRM.[UnitPrice] ,CRM.[Amount] ,CRM.[RMAReasonId] ,CRM.[RMAReason] ,CRM.[Notes],CRM.[isWorkOrder]
					   ,CRM.[MasterCompanyId] ,CRM.[CreatedBy],CRM.[UpdatedBy],CRM.[CreatedDate] ,CRM.[UpdatedDate] ,CRM.[IsActive]
					   ,CRM.[IsDeleted] ,CRM.[ReturnDate] ,CRM.[WorkOrderNum],CRM.[ReceiverNum] ,ST.isSerialized ,CRM.InvoiceId ,@InvoiceStatus as InvoiceStatus
					   ,CRM.BillingInvoicingItemId ,CRH.InvoiceNo,CRM.CustomerReference,CRM.InvoiceQty ,IM.ManufacturerName
					   ,0 SubTotal, 0 As SalesTax, 0 AS OtherTax, 0 GrandTotal, 0 PartsUnitCost,0 As PartsRevenue, 0 As LaborRevenue, 0 MiscRevenue
					   ,0 AS FreightRevenue, 0 As COGSParts, 0 AS COGSPartsUnitCost, 0 COGSLabor, 0 As COGSOverHeadCost, 0 As COGSInventory
					   ,AltPartNumber=(  
						SELECT TOP 1  
							A.PartNumber [AltPartNumberType] from [dbo].[CustomerRMADeatils] SOBIIA WITH (NOLOCK) 
						Outer Apply( SELECT   
										STUFF((SELECT CASE WHEN LEN(AI.partnumber) > 0 then ',' ELSE '' END + AI.partnumber  
									FROM Nha_Tla_Alt_Equ_ItemMapping AL WITH (NOLOCK)  
									INNER Join [dbo].[ItemMaster] I WITH (NOLOCK) On AL.ItemMasterId=I.ItemMasterId 
									INNER Join [dbo].[ItemMaster] AI WITH (NOLOCK) On AL.MappingItemMasterId=AI.ItemMasterId 
									WHERE I.ItemMasterId = SOBIIA.ItemMasterId  and MappingType=1  
										AND AL.IsActive = 1 AND AL.IsDeleted = 0  
						 FOR XML PATH('')), 1, 1, '') PartNumber  
						) A  
						WHERE SOBIIA.MasterCompanyId=CRM.MasterCompanyId and SOBIIA.ItemMasterId =CRM.ItemMasterId AND ISNULL(SOBIIA.IsDeleted,0)=0
						GROUP BY SOBIIA.ItemMasterId, A.PartNumber  
						) 
					FROM [dbo].[CustomerRMADeatils] CRM  WITH (NOLOCK)
					   LEFT JOIN [dbo].[CustomerRMAHeader] CRH WITH (NOLOCK) ON CRH.RMAHeaderId=CRM.RMAHeaderId 
					   LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON CRM.ItemMasterId = IM.ItemMasterId
					   LEFT JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.StockLineId = CRM.StockLineId AND ST.IsParent = 1 
					WHERE  CRM.RMAHeaderId =@RMAheaderId AND ISNULL(CRM.IsDeleted,0) = 0 AND ISNULL(CRM.IsActive,1)=1
				END
			END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetCustomerRMAPartsDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@InvoicingId, '') + '''
													   @Parameter2 = ' + ISNULL(CAST(@isWorkOrder AS varchar(10)) ,'') +'
													   @Parameter3 = ' + ISNULL(CAST(@RMAheaderId AS varchar(10)) ,'') +'
													   @Parameter4 = ' + ISNULL(CAST(@Ispopup AS varchar(10)) ,'') +''
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