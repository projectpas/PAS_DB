/*************************************************************           
 ** File:   [sp_GetCustomerRMAPartsDetails]           
 ** Author:   Subhash Saliya
 ** Description: Get Customer RMAPartsDetails
 ** Purpose:         
 ** Date:   20-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/20/2022   Subhash Saliya Created
	
 -- exec sp_GetCustomerRMAPartsDetails 91,1,1,1    
**************************************************************/ 

CREATE Procedure [dbo].[sp_GetCustomerRMAPartsDetails]
@InvoicingId bigint,
@isWorkOrder bit,
@RMAheaderId BIGINT,
@Ispopup bit = 0
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
			if(@Ispopup =1)
			BEGIN
			   if(@isWorkOrder =0)
			BEGIN

				SELECT SOBI.SOBillingInvoicingId as InvoiceId,SOBI.InvoiceNo [InvoiceNo],SOBII.SOBillingInvoicingItemId as BillingInvoicingItemId,
				SOBI.InvoiceStatus [InvoiceStatus],SOBI.InvoiceDate [InvoiceDate],SO.SalesOrderNumber as ReferenceNo,
				SOBI.GrandTotal [InvoiceAmt],IM.ItemMasterId [ItemMasterId],IM.partnumber [PartNumber], IM.PartDescription [PartDescription],'' as CustPartNumber,
				SOPN.CustomerReference [CustomerReference],ST.SerialNumber [SerialNumber],ST.StocklineNumber as StocklineNumber ,st.Stocklineid as StocklineId,
			    ST.ControlNumber as ControlNumber,ST.IdNumber as ControlId,SOBII.NoofPieces as Qty,SOBII.UnitPrice as UnitPrice,(SOBII.NoofPieces * SOBII.UnitPrice)  as Amount,
				IsWorkOrder=0,SOBI.SalesOrderId AS [ReferenceId],
				RMAC.RMAReasonId,RMAC.RMAReason,RMAC.RMAStatusId,RMAC.RMAStatus,RMAC.RMAValiddate,
				'0' as [RMADeatilsId],
                '0' as [RMAHeaderId]
				 ,'' as [Notes]
                 ,SOBI.[MasterCompanyId]
                 ,SOBI.[CreatedBy]
                 ,SOBI.[UpdatedBy]
                 ,SOBI.[CreatedDate]
                 ,SOBI.[UpdatedDate]
                 ,SOBI.[IsActive]
                 ,SOBI.[IsDeleted]
				 ,ST.isSerialized
				 ,AltPartNumber=(  
				 Select top 1  
				A.PartNumber [AltPartNumberType] from SalesOrderBillingInvoicingItem SOBIIA WITH (NOLOCK) 
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(AI.partnumber) >0 then ',' ELSE '' END + AI.partnumber  
					 FROM Nha_Tla_Alt_Equ_ItemMapping AL WITH (NOLOCK)  
					 INNER Join ItemMaster I WITH (NOLOCK) On AL.ItemMasterId=I.ItemMasterId 
					 INNER Join ItemMaster AI WITH (NOLOCK) On AL.MappingItemMasterId=AI.ItemMasterId 
					 Where I.ItemMasterId = SOBIIA.ItemMasterId  and MappingType=1  
					 AND AL.IsActive = 1 AND AL.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') PartNumber  
				) A  
				WHERE SOBIIA.MasterCompanyId=SOBII.MasterCompanyId and SOBIIA.ItemMasterId =SOBII.ItemMasterId and SOBIIA.SOBillingInvoicingId =SOBII.SOBillingInvoicingId AND isnull(SOBII.IsDeleted,0)=0
				Group By SOBIIA.ItemMasterId, A.PartNumber  
				) 
			    FROM SalesOrderBillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId = SOBI.SOBillingInvoicingId
				LEFT JOIN SalesOrderPart SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.SalesOrderId AND SOPN.SalesOrderPartId = SOBII.SalesOrderPartId
				LEFT JOIN SalesOrder SO WITH (NOLOCK) ON SOBI.SalesOrderId = SO.SalesOrderId
				LEFT JOIN SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId = SO.SalesOrderQuoteId
				LEFT JOIN ItemMaster IM WITH (NOLOCK) ON SOBII.ItemMasterId=IM.ItemMasterId
				LEFT JOIN Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId AND ST.IsParent = 1
				LEFT JOIN RMACreditMemoSettings RMAC WITH (NOLOCK) ON so.MasterCompanyId = RMAC.MasterCompanyId
			    Where SOBI.SOBillingInvoicingId=@InvoicingId		


			END
			ELSE 
			BEGIN 

		        SELECT WOBI.BillingInvoicingId as InvoiceId,WOBI.InvoiceNo [InvoiceNo],WOBII.WOBillingInvoicingItemId as BillingInvoicingItemId,
				WOBI.InvoiceStatus [InvoiceStatus],WOBI.InvoiceDate [InvoiceDate],WO.WorkOrderNum as ReferenceNo,
				WOBI.GrandTotal [InvoiceAmt],
				IM.ItemMasterId [ItemMasterId],IM.partnumber [PartNumber], IM.PartDescription [PartDescription],'' as AltPartNumber,'' as CustPartNumber,
				WOPN.CustomerReference [CustomerReference],ST.SerialNumber [SerialNumber],ST.StocklineNumber as StocklineNumber ,st.Stocklineid as StocklineId,
			    ST.ControlNumber as ControlNumber,ST.IdNumber as ControlId,WOBII.NoofPieces as Qty,WOBI.GrandTotal as UnitPrice,(WOBII.NoofPieces * WOBI.GrandTotal)  as Amount,
			    RMAC.RMAReasonId,RMAC.RMAReason,RMAC.RMAStatusId,RMAC.RMAStatus,RMAC.RMAValiddate,
				IsWorkOrder=1,WOBI.WorkOrderId AS [ReferenceId],
				'0' as [RMADeatilsId],
                '0' as [RMAHeaderId]
				 ,'' as [Notes]
                 ,WOBI.[MasterCompanyId]
                 ,WOBI.[CreatedBy]
                 ,WOBI.[UpdatedBy]
                 ,WOBI.[CreatedDate]
                 ,WOBI.[UpdatedDate]
                 ,WOBI.[IsActive]
                 ,WOBI.[IsDeleted]
				 ,ST.isSerialized
				 ,AltPartNumber=(  
				 Select top 1  
				A.PartNumber [AltPartNumberType] from WorkOrderBillingInvoicingItem WOBIIA WITH (NOLOCK) 
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(AI.partnumber) >0 then ',' ELSE '' END + AI.partnumber  
					 FROM Nha_Tla_Alt_Equ_ItemMapping AL WITH (NOLOCK)  
					 INNER Join ItemMaster I WITH (NOLOCK) On AL.ItemMasterId=I.ItemMasterId 
					 INNER Join ItemMaster AI WITH (NOLOCK) On AL.MappingItemMasterId=AI.ItemMasterId 
					 Where I.ItemMasterId = WOBIIA.ItemMasterId  and MappingType=1  
					 AND AL.IsActive = 1 AND AL.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') PartNumber  
				) A  
				WHERE WOBIIA.MasterCompanyId=WOBII.MasterCompanyId and WOBIIA.ItemMasterId =WOBII.ItemMasterId  and WOBIIA.BillingInvoicingId =WOBII.BillingInvoicingId AND isnull(WOBII.IsDeleted,0)=0
				Group By WOBIIA.ItemMasterId, A.PartNumber  
				) 
				FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
				LEFT JOIN WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId
				LEFT JOIN WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId
				LEFT JOIN WorkOrder WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
				LEFT JOIN ItemMaster IM WITH (NOLOCK) ON WOBII.ItemMasterId=IM.ItemMasterId
				LEFT JOIN Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId AND ST.IsParent = 1
				LEFT JOIN RMACreditMemoSettings RMAC WITH (NOLOCK) ON WO.MasterCompanyId = RMAC.MasterCompanyId
			    Where WOBI.BillingInvoicingId=@InvoicingId AND WOBI.IsVersionIncrease=0
			
			
			END
			END
			ELSE 
			BEGIN


			DECLARE @InvoiceStatus varchar(30)
			DECLARE @InvoiceId bigint
			SELECT @isWorkOrder =isWorkOrder,@InvoiceId= InvoiceId FROM [dbo].[CustomerRMAHeader]  WITH (NOLOCK) WHERE  RMAHeaderId =@RMAHeaderId


			if(@isWorkOrder =1)
			BEGIN
			  SELECT @InvoiceStatus = InvoiceStatus FROM WorkOrderBillingInvoicing WOBI WITH (NOLOCK) WHERE  BillingInvoicingId =@InvoiceId
			END
			ELSE
			BEGIN
			  SELECT @InvoiceStatus = InvoiceStatus FROM SalesOrderBillingInvoicing SOBI WITH (NOLOCK) WHERE  SOBillingInvoicingId =@InvoiceId
			END

			   SELECT CRM.[RMADeatilsId]
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
		   ,ST.isSerialized
		   ,CRM.InvoiceId
		   ,@InvoiceStatus as InvoiceStatus
		   ,CRM.BillingInvoicingItemId
		   ,CRH.InvoiceNo
		   ,CRM.CustomerReference
		   ,AltPartNumber=(  
				 Select top 1  
				A.PartNumber [AltPartNumberType] from CustomerRMADeatils SOBIIA WITH (NOLOCK) 
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(AI.partnumber) >0 then ',' ELSE '' END + AI.partnumber  
					 FROM Nha_Tla_Alt_Equ_ItemMapping AL WITH (NOLOCK)  
					 INNER Join ItemMaster I WITH (NOLOCK) On AL.ItemMasterId=I.ItemMasterId 
					 INNER Join ItemMaster AI WITH (NOLOCK) On AL.MappingItemMasterId=AI.ItemMasterId 
					 Where I.ItemMasterId = SOBIIA.ItemMasterId  and MappingType=1  
					 AND AL.IsActive = 1 AND AL.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') PartNumber  
				) A  
				WHERE SOBIIA.MasterCompanyId=CRM.MasterCompanyId and SOBIIA.ItemMasterId =CRM.ItemMasterId AND isnull(SOBIIA.IsDeleted,0)=0
				Group By SOBIIA.ItemMasterId, A.PartNumber  
				) 
           FROM [dbo].[CustomerRMADeatils] CRM  WITH (NOLOCK)
		   LEFT JOIN CustomerRMAHeader CRH WITH (NOLOCK) ON CRH.RMAHeaderId=CRM.RMAHeaderId  
	       LEFT JOIN Stockline ST WITH (NOLOCK) ON ST.StockLineId=CRM.StockLineId AND ST.IsParent = 1 where  CRM.RMAHeaderId =@RMAheaderId AND isnull(CRM.IsDeleted,0) =0 AND  isnull(CRM.IsActive,1)=1

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