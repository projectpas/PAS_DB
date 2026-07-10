-- ===== PROCEDURE: [dbo].[usp_SaveRMAPartDetails]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs3/usp_SaveRMAPartDetails.sql) =====
/*************************************************************           
 ** File:   [sp_GetCustomerRMAPartsDetails]           
 ** Author:   Subhash Saliya
 ** Description: Save Customer RMAPartsDetails
 ** Purpose:         
 ** Date:   20-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/20/2022   Subhash Saliya Created
	2    04/19/2023   MOIN BLOCH     ADDED NEW FIELDS   
	3	 02/1/2024	  AMIT GHEDIYA	 added isperforma Flage for SO
	4    04-07-2025   AMIT GHEDIYA   Changed Old To New Billing Table
	5    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	6    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	
declare @p1 dbo.CustomerRMADeatilsType
insert into @p1 values(3,2,1,N'ADS-B',N'GARMIN GTX 335 ADS-B TRANSPONDER WITH GPS',N'',N'',N'',7427,N'STL-000063',N'CNTL-000778',N'ID_NUM-000002',145,N'WO-000111',45,74,3330,5,N'Non Functional',N'',N'True',2,N'ADMIN ADMIN',N'ADMIN ADMIN','2022-04-22 05:20:26.5100000','2022-04-22 05:20:26.5100000',1,0)
insert into @p1 values(4,2,1,N'ADS-B',N'GARMIN GTX 335 ADS-B TRANSPONDER WITH GPS',N'',N'',N'',7428,N'STL-000064',N'CNTL-000779',N'ID_NUM-000002',145,N'WO-000111',123,23,2829,8,N'Non Functional',N'',N'True',2,N'ADMIN ADMIN',N'ADMIN ADMIN','2022-04-22 05:20:26.5110000','2022-04-22 05:20:26.5110000',1,0)

exec dbo.usp_SaveRMAPartDetails @tbl_CustomerRMADeatilsType=@p1  
**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_SaveRMAPartDetails]
@tbl_CustomerRMADeatilsType CustomerRMADeatilsType READONLY,
@ModuleId INT
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
				BEGIN TRANSACTION
				BEGIN
					 DECLARE @WOModuleId INT,
							 @SOModuleId INT;

					 SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
					 SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

				--  CustomerRMADeatils LIST
					IF((SELECT COUNT(RMADeatilsId) FROM @tbl_CustomerRMADeatilsType) > 0 )
					BEGIN
						MERGE dbo.CustomerRMADeatils AS TARGET
						USING @tbl_CustomerRMADeatilsType AS SOURCE ON (TARGET.RMAHeaderId = SOURCE.RMAHeaderId AND TARGET.RMADeatilsId = SOURCE.RMADeatilsId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED 				
							THEN UPDATE 						
							SET 
							
								 TARGET.[Qty] = SOURCE.Qty
								,TARGET.[UnitPrice] = SOURCE.UnitPrice
								,TARGET.[Amount] =SOURCE.Amount
								,TARGET.[RMAReasonId] =SOURCE.RMAReasonId
								,TARGET.[RMAReason] = SOURCE.RMAReason
								,TARGET.[Notes] =SOURCE.Notes
								,TARGET.[UpdatedBy] = SOURCE.UpdatedBy
								,TARGET.[UpdatedDate] = GETUTCDATE()
								,TARGET.[IsCreateStockline]=1
								,TARGET.[ReturnDate]  = SOURCE.ReturnDate	
	                            ,TARGET.[WorkOrderNum]  = SOURCE.WorkOrderNum	
	                            ,TARGET.[ReceiverNum]  = SOURCE.ReceiverNum		
							
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT ([RMAHeaderId]
										,[ItemMasterId]
										,[PartNumber]
										,[PartDescription]
										,[AltPartNumber]
										,[CustPartNumber]
										,[SerialNumber]
										,[StocklineId]
										,[StocklineNumber]
										,[ControlNumber]
										,[ControlId]
										,[ReferenceId]
										,[ReferenceNo]
										,[Qty]
										,[UnitPrice]
										,[Amount]
										,[RMAReasonId]
										,[RMAReason]
										,[Notes]
										,[isWorkOrder]
										,[MasterCompanyId]
										,[CreatedBy]
										,[UpdatedBy]
										,[CreatedDate]
										,[UpdatedDate]
										,[IsActive]
										,[IsDeleted]
										,[InvoiceId]
										,[BillingInvoicingItemId]
										,IsCreateStockline
										,CustomerReference
										,InvoiceQty
										,[ReturnDate]  
										,[WorkOrderNum]
										,[ReceiverNum] 																				
										)
								 VALUES (
										 SOURCE.[RMAHeaderId]
										,SOURCE.[ItemMasterId]
										,SOURCE.[PartNumber]
										,SOURCE.[PartDescription]
										,SOURCE.[AltPartNumber]
										,SOURCE.[CustPartNumber]
										,SOURCE.[SerialNumber]
										,SOURCE.[StocklineId]
										,SOURCE.[StocklineNumber]
										,SOURCE.[ControlNumber]
										,SOURCE.[ControlId]
										,SOURCE.[ReferenceId]
										,SOURCE.[ReferenceNo]
										,SOURCE.[Qty]
										,SOURCE.[UnitPrice]
										,SOURCE.[Amount]
										,SOURCE.[RMAReasonId]
										,SOURCE.[RMAReason]
										,SOURCE.[Notes]
										,SOURCE.[isWorkOrder]
										,SOURCE.[MasterCompanyId]
										,SOURCE.[CreatedBy]
										,SOURCE.[UpdatedBy]
										,GETUTCDATE()
										,GETUTCDATE()
										,SOURCE.[IsActive]
										,SOURCE.[IsDeleted]
										,SOURCE.[InvoiceId]
										,SOURCE.[BillingInvoicingItemId]
										,0
										,SOURCE.CustomerReference
										,SOURCE.InvoiceQty
										,SOURCE.ReturnDate
										,SOURCE.WorkOrderNum	
										,SOURCE.ReceiverNum		
										);

					 END
					 Declare @RMAHeaderId bigint 
					 Declare @isWorkOrder bit 
					 set @RMAHeaderId = (Select top 1 RMAHeaderId from @tbl_CustomerRMADeatilsType)
					
					 
						DECLARE @InvoiceStatus varchar(30)
						DECLARE @InvoiceId bigint
						SELECT @isWorkOrder =isWorkOrder,@InvoiceId= InvoiceId FROM [dbo].[CustomerRMAHeader]  WITH (NOLOCK) WHERE  RMAHeaderId =@RMAHeaderId


						if(@isWorkOrder =1)
						BEGIN
							 SELECT @InvoiceStatus = InvoiceStatus FROM BillingInvoicing WOBI WITH (NOLOCK) WHERE  BillingInvoicingId = @InvoiceId AND ISNULL(WOBI.IsPerformaInvoice,0) = 0 AND WOBI.ModuleId = @WOModuleId
						END
						ELSE
						BEGIN
							 SELECT @InvoiceStatus = InvoiceStatus FROM BillingInvoicing SOBI WITH (NOLOCK) WHERE  BillingInvoicingId = @InvoiceId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND SOBI.ModuleId = @SOModuleId
						END

					 SELECT  CRM.[RMADeatilsId]
                            ,CRM.[RMAHeaderId]
                            ,CRM.[ItemMasterId]
                            ,CRM.[PartNumber]
                            ,CRM.[PartDescription]
							,IM.[ManufacturerName]
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
							,@InvoiceStatus as InvoiceStatus
							,CRM.BillingInvoicingItemId
							,CRM.CustomerReference
							,CRH.InvoiceNo
							,CRM.InvoiceQty
							,AltPartNumber=(  
								 Select top 1  
								A.PartNumber [AltPartNumberType] from dbo.CustomerRMADeatils SOBIIA WITH (NOLOCK) 
								Outer Apply(  
								 SELECT   
									STUFF((SELECT CASE WHEN LEN(AI.partnumber) >0 then ',' ELSE '' END + AI.partnumber  
									 FROM dbo.Nha_Tla_Alt_Equ_ItemMapping AL WITH (NOLOCK)  
									 INNER Join dbo.ItemMaster I WITH (NOLOCK) On AL.ItemMasterId=I.ItemMasterId 
									 INNER Join dbo.ItemMaster AI WITH (NOLOCK) On AL.MappingItemMasterId=AI.ItemMasterId 
									 Where I.ItemMasterId = SOBIIA.ItemMasterId  and MappingType=1  
									 AND AL.IsActive = 1 AND AL.IsDeleted = 0  
									 AND ISNULL(I.IsNonStock,0) = 0 AND ISNULL(AI.IsNonStock,0) = 0
									 FOR XML PATH('')), 1, 1, '') PartNumber  
								) A  
								WHERE SOBIIA.MasterCompanyId=CRM.MasterCompanyId and SOBIIA.ItemMasterId =CRM.ItemMasterId AND isnull(SOBIIA.IsDeleted,0)=0
								Group By SOBIIA.ItemMasterId, A.PartNumber  
								) 
		                    FROM dbo.CustomerRMADeatils CRM  WITH (NOLOCK)
							LEFT JOIN dbo.CustomerRMAHeader CRH WITH (NOLOCK) ON CRH.RMAHeaderId=CRM.RMAHeaderId 
			                LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=CRM.StockLineId AND ISNULL(ST.IsNonStock,0) = 0
							LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON Im.ItemMasterId=CRM.ItemMasterId 
				             AND ISNULL(IM.IsNonStock,0) = 0
							 WHERE isnull(CRM.IsDeleted,0) = 0  and CRM.RMAHeaderId =@RMAHeaderId 
				
				END
				COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_SaveRMAPartDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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