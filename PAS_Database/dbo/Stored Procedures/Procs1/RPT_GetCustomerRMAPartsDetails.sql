/*************************************************************           
 ** File:   [RPT_GetCustomerRMAPartsDetails]           
 ** Author:   Amit Ghediya 
 ** Description: Get Customer RMAPartsDetails for SSRS Report
 ** Purpose:         
 ** Date:   04/21/2023       
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/21/2023   Amit Ghediya    Created
	2	 01/02/2024	  AMIT GHEDIYA	  added isperforma Flage for SO
	
 -- exec RPT_GetCustomerRMAPartsDetails 120,0,13,1    
**************************************************************/ 

CREATE     Procedure [dbo].[RPT_GetCustomerRMAPartsDetails]
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
			   IF(@isWorkOrder =0)
			   BEGIN
					SELECT 
					ROW_NUMBER() OVER (
						ORDER BY SOBI.SOBillingInvoicingId
					) row_num, 
					SOBI.SOBillingInvoicingId AS InvoiceId,SOBI.InvoiceNo [InvoiceNo],SOBII.SOBillingInvoicingItemId AS BillingInvoicingItemId,
					SOBI.InvoiceStatus [InvoiceStatus],SOBI.InvoiceDate [InvoiceDate],SO.SalesOrderNumber AS ReferenceNo,
					SOBI.GrandTotal [InvoiceAmt],IM.ItemMasterId [ItemMasterId],IM.partnumber [PartNumber], IM.PartDescription [PartDescription],'' AS CustPartNumber,
					SOPN.CustomerReference [CustomerReference],ST.SerialNumber [SerialNumber],ST.StocklineNumber AS StocklineNumber ,st.Stocklineid AS StocklineId,
					ST.ControlNumber AS ControlNumber,ST.IdNumber AS ControlId,SOBII.NoofPieces AS Qty,SOBII.UnitPrice AS UnitPrice,(SOBII.NoofPieces * SOBII.UnitPrice)  AS Amount,
					IsWorkOrder=0,SOBI.SalesOrderId AS [ReferenceId],
					RMAC.RMAReasonId,RMAC.RMAReason,RMAC.RMAStatusId,RMAC.RMAStatus,RMAC.RMAValiddate,
					'0' AS [RMADeatilsId],
					'0' AS [RMAHeaderId]
					 ,'' AS [Notes]
					 ,SOBI.[MasterCompanyId]
					 ,SOBI.[CreatedBy]
					 ,SOBI.[UpdatedBy]
					 ,SOBI.[CreatedDate]
					 ,SOBI.[UpdatedDate]
					 ,SOBI.[IsActive]
					 ,SOBI.[IsDeleted]
					 ,ST.isSerialized
					 ,SOBII.NoofPieces AS InvoiceQty
					 ,IM.ManufacturerName
					 ,AltPartNumber=(  
					 SELECT TOP 1  
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
					WHERE SOBIIA.MasterCompanyId=SOBII.MasterCompanyId AND SOBIIA.ItemMasterId =SOBII.ItemMasterId 
					and SOBIIA.SOBillingInvoicingId =SOBII.SOBillingInvoicingId 
					AND ISNULL(SOBII.IsDeleted,0)=0 AND ISNULL(SOBIIA.IsProforma,0) = 0
					GROUP BY SOBIIA.ItemMasterId, A.PartNumber  
					) 
					FROM [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK)
					LEFT JOIN [dbo].[SalesOrderBillingInvoicingItem] SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId = SOBI.SOBillingInvoicingId AND ISNULL(SOBII.IsProforma,0) = 0
					LEFT JOIN [dbo].[SalesOrderPart] SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.SalesOrderId AND SOPN.SalesOrderPartId = SOBII.SalesOrderPartId
					LEFT JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SOBI.SalesOrderId = SO.SalesOrderId
					LEFT JOIN [dbo].[SalesOrderQuote] SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId = SO.SalesOrderQuoteId
					LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SOBII.ItemMasterId=IM.ItemMasterId
					LEFT JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId AND ST.IsParent = 1
					LEFT JOIN [dbo].[RMACreditMemoSettings] RMAC WITH (NOLOCK) ON so.MasterCompanyId = RMAC.MasterCompanyId
					WHERE SOBI.SOBillingInvoicingId=@InvoicingId AND ISNULL(SOBI.IsProforma,0) = 0		

			END
			ELSE 
			BEGIN 
		        SELECT 
				ROW_NUMBER() OVER (
					ORDER BY WOBI.BillingInvoicingId
				) row_num, 
				WOBI.BillingInvoicingId AS InvoiceId,WOBI.InvoiceNo [InvoiceNo],WOBII.WOBillingInvoicingItemId AS BillingInvoicingItemId,
				WOBI.InvoiceStatus [InvoiceStatus],WOBI.InvoiceDate [InvoiceDate],WO.WorkOrderNum AS ReferenceNo,
				WOBI.GrandTotal [InvoiceAmt],
				IM.ItemMasterId [ItemMasterId],IM.partnumber [PartNumber], IM.PartDescription [PartDescription],'' AS AltPartNumber,'' AS CustPartNumber,
				WOPN.CustomerReference [CustomerReference],ST.SerialNumber [SerialNumber],ST.StocklineNumber AS StocklineNumber ,st.Stocklineid AS StocklineId,
			    ST.ControlNumber AS ControlNumber,ST.IdNumber AS ControlId,WOBII.NoofPieces AS Qty,WOBI.GrandTotal AS UnitPrice,(WOBII.NoofPieces * WOBI.GrandTotal)  AS Amount,
			    RMAC.RMAReasonId,RMAC.RMAReason,RMAC.RMAStatusId,RMAC.RMAStatus,RMAC.RMAValiddate,
				IsWorkOrder=1,WOBI.WorkOrderId AS [ReferenceId],
				'0' AS [RMADeatilsId],
                '0' AS [RMAHeaderId]
				,'' AS [Notes]
                ,WOBI.[MasterCompanyId]
                ,WOBI.[CreatedBy]
                ,WOBI.[UpdatedBy]
                ,WOBI.[CreatedDate]
                ,WOBI.[UpdatedDate]
                ,WOBI.[IsActive]
                ,WOBI.[IsDeleted]
				,ST.isSerialized
				,WOBII.NoofPieces AS InvoiceQty
				,IM.ManufacturerName
				,AltPartNumber=(  
				SELECT TOP 1  
				A.PartNumber [AltPartNumberType] FROM [dbo].[WorkOrderBillingInvoicingItem] WOBIIA WITH (NOLOCK) 
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(AI.partnumber) >0 THEN ',' ELSE '' END + AI.partnumber  
					 FROM [dbo].[Nha_Tla_Alt_Equ_ItemMapping] AL WITH (NOLOCK)  
					 INNER Join [dbo].[ItemMaster] I WITH (NOLOCK) On AL.ItemMasterId=I.ItemMasterId 
					 INNER Join [dbo].[ItemMaster] AI WITH (NOLOCK) On AL.MappingItemMasterId=AI.ItemMasterId 
					 WHERE I.ItemMasterId = WOBIIA.ItemMasterId  and MappingType=1  
					 AND AL.IsActive = 1 AND AL.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') PartNumber  
				) A  
				WHERE WOBIIA.MasterCompanyId=WOBII.MasterCompanyId and WOBIIA.ItemMasterId =WOBII.ItemMasterId  and WOBIIA.BillingInvoicingId =WOBII.BillingInvoicingId AND isnull(WOBII.IsDeleted,0)=0
				GROUP BY WOBIIA.ItemMasterId, A.PartNumber  
				) 
				FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK)
				LEFT JOIN [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId
				LEFT JOIN [dbo].[WorkOrderPartNumber] WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId
				LEFT JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
				LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON WOBII.ItemMasterId=IM.ItemMasterId
				LEFT JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId AND ST.IsParent = 1
				LEFT JOIN [dbo].[RMACreditMemoSettings] RMAC WITH (NOLOCK) ON WO.MasterCompanyId = RMAC.MasterCompanyId
			    WHERE WOBI.BillingInvoicingId=@InvoicingId AND WOBI.IsVersionIncrease=0;	
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

			   SELECT 
			   ROW_NUMBER() OVER (
					ORDER BY CRM.RMADeatilsId
				) row_num, 
			   CRM.[RMADeatilsId]
			   ,CRM.[RMAHeaderId]
			   ,CRM.[ItemMasterId]
			   ,CRM.[PartNumber]
			   ,CRM.[PartDescription]
			   ,CRM.[CustPartNumber]
			   ,CRM.[SerialNumber]
			   ,CRM.[StocklineId]
			   ,CRM.[StocklineNumber]
			   ,CRM.[ControlNumber]
			   ,CRM.[ControlId]
			   ,CRM.[ReferenceId]
			   ,CRM.[ReferenceNo]
			   ,CRM.[Qty]
			   ,CRM.[UnitPrice]
			   ,CRM.[Amount]
			   ,CRM.[RMAReasonId]
			   ,CRM.[RMAReason]
			   ,CRM.[Notes]
			   ,CRM.[isWorkOrder]
			   ,CRM.[MasterCompanyId]
			   ,CRM.[CreatedBy]
			   ,CRM.[UpdatedBy]
			   ,CRM.[CreatedDate]
			   ,CRM.[UpdatedDate]
			   ,CRM.[IsActive]
			   ,CRM.[IsDeleted]
			   ,CRM.[ReturnDate]  
			   ,CRM.[WorkOrderNum]
			   ,CRM.[ReceiverNum] 	
			   ,ST.isSerialized
			   ,CRM.InvoiceId
			   ,@InvoiceStatus AS InvoiceStatus
			   ,CRM.BillingInvoicingItemId
			   ,CRH.InvoiceNo
			   ,CRM.CustomerReference
			   ,CRM.InvoiceQty
			   ,IM.ManufacturerName
			   ,AltPartNumber=(  
				SELECT TOP 1  
					A.PartNumber [AltPartNumberType] FROM [dbo].[CustomerRMADeatils] SOBIIA WITH (NOLOCK) 
					Outer Apply(  
					 SELECT   
						STUFF((SELECT CASE WHEN LEN(AI.partnumber) >0 THEN ',' ELSE '' END + AI.partnumber  
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
			   LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON CRM.ItemMasterId=IM.ItemMasterId
			   LEFT JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.StockLineId=CRM.StockLineId AND ST.IsParent = 1 WHERE  CRM.RMAHeaderId =@RMAheaderId AND ISNULL(CRM.IsDeleted,0) =0 AND  ISNULL(CRM.IsActive,1)=1

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
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetCustomerRMAPartsDetails' 
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