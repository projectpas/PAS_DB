/*************************************************************           
 ** File:   [GetWorkOrderSettlementDetails]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Work order Settlement Details  
 ** Purpose:         
 ** Date:   12/30/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/02/2020   Subhash Saliya Created
	2	 06/28/2021	  Hemant Saliya  Added Transation & Content Managment
	3	 09/13/2021	  Hemant Saliya  Add Calculated Field for Labor All Labor are Completd
    4	 07/26/2022	  Subhash Saliya Add Calculated Field for Sipping or Invoiced are Completd
	5	 06/08/2023	  Hemant Saliya  Updated for Calucation for Materilas Qty

--EXEC [GetWorkOrderSettlementDetails] 2757,2267,2261
**************************************************************/
CREATE   PROCEDURE [dbo].[GetWorkOrderSettlementDetails]
	@WorkorderId bigint,
	@workOrderPartNoId bigint,
	@workflowWorkorderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @qtyissue INT =0;
				DECLARE @qtyissued INT =0;
				DECLARE @OtherMaterialsProvisionQty INT =0;
				DECLARE @OtherProvisionQty INT =0;
				DECLARE @qtyreq INT =0;
				DECLARE @qtyrequested INT =0;
				DECLARE @QtyTendered INT =0;
				
				DECLARE @kitqtyissue INT =0;
				DECLARE @OtherMaterialsProvisionKitQty INT =0;
				DECLARE @OtherProvisionKitQty INT =0;
				DECLARE @kitqtyreq INT =0;
				DECLARE @kitQtyTendered INT =0;

				DECLARE @QtyToTendered INT =0;
				DECLARE @TaskStatusID INT;
				DECLARE @MasterCompanyID INT;
				DECLARE @IsLaborCompleled INT = 0;
				DECLARE @AllToolsAreCheckOut INT = 0;
				DECLARE @IsShippingCompleled INT = 0;
				DECLARE @IsBillingCompleled INT = 0;
				DECLARE @InventoryStatusID INT;
				DECLARE @ProvisionId INT = 1; -- FOR REPLACE

				SELECT  @qtyreq = SUM(ISNULL(Quantity,0)),
						@QtyToTendered = SUM(ISNULL(QtyToTurnIn,0))
						--@qtyissue=SUM(ISNULL(QuantityIssued,0))						
				FROM dbo.WorkOrderMaterials WITH(NOLOCK) 	  
				WHERE WorkFlowWorkOrderId = @workflowWorkorderId

				SELECT  @OtherMaterialsProvisionQty = SUM(ISNULL(WOM.Quantity,0))
				FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) 	  
					LEFT JOIN dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId	
				WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ProvisionId != 1 AND WOMS.WOMStockLineId IS NULL

				SELECT @qtyissue = SUM(ISNULL(WOMS.QtyIssued,0)) 
				FROM dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) 
					JOIN dbo.WorkOrderMaterials WOM WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId	  
				WHERE WorkFlowWorkOrderId = @workflowWorkorderId AND WOMS.ProvisionId = @ProvisionId -- REPLACE

				SELECT @OtherProvisionQty = SUM(ISNULL(WOMS.Quantity,0)) 
				FROM dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) 
					JOIN dbo.WorkOrderMaterials WOM WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId	  
				WHERE WorkFlowWorkOrderId = @workflowWorkorderId AND WOMS.ProvisionId != @ProvisionId -- REPLACE

				SELECT  @kitqtyreq =  SUM(ISNULL(Quantity,0)),
						@kitQtyTendered =  SUM(ISNULL(QtyToTurnIn,0))
						--@kitqtyissue =  SUM(ISNULL(QuantityIssued,0))						
				FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) 	  
				WHERE WorkFlowWorkOrderId = @workflowWorkorderId

				SELECT  @OtherMaterialsProvisionKitQty = SUM(ISNULL(WOM.Quantity,0))
				FROM dbo.WorkOrderMaterialsKit WOM WITH(NOLOCK) 	  
					LEFT JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH(NOLOCK) ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId	
				WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ProvisionId != 1 AND WOMS.WorkOrderMaterialStockLineKitId IS NULL

				SELECT @kitqtyissue = SUM(ISNULL(WOMS.QtyIssued,0)) 
				FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH(NOLOCK) 
					JOIN dbo.WorkOrderMaterialsKit WOM WITH(NOLOCK) ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId	  
				WHERE WorkFlowWorkOrderId = @workflowWorkorderId AND WOMS.ProvisionId = @ProvisionId -- REPLACE

				SELECT @OtherProvisionKitQty = SUM(ISNULL(WOMS.Quantity,0)) 
				FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH(NOLOCK) 
					JOIN dbo.WorkOrderMaterialsKit WOM WITH(NOLOCK) ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId	  
				WHERE WorkFlowWorkOrderId = @workflowWorkorderId AND WOMS.ProvisionId != @ProvisionId -- REPLACE

				SET  @qtyrequested = ISNULL(@qtyreq,0) + ISNULL(@kitqtyreq,0) - ISNULL(@OtherMaterialsProvisionQty, 0) - ISNULL(@OtherMaterialsProvisionKitQty, 0)
				SET  @QtyToTendered = isnull(@QtyToTendered,0)+ ISNULL(@kitQtyTendered,0)
				SET  @qtyissued = ISNULL(@qtyissue,0) + ISNULL(@kitqtyissue,0) + ISNULL(@OtherProvisionQty, 0) + ISNULL(@OtherProvisionKitQty, 0)

				SELECT @QtyTendered = SUM(ISNULL(womsl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)
					JOIN dbo.WorkOrderMaterials WOM WITH(NOLOCK) ON womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
				WHERE WOM.WorkFlowWorkOrderId=@workflowWorkorderId AND womsl.ConditionId = WOM.ConditionCodeId
					AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(womsl.QuantityTurnIn, 0) > 0
				
				SELECT @MasterCompanyID = MasterCompanyId FROM dbo.WorkOrder WITH (NOLOCK) WHERE WorkOrderId = @WorkorderId

				SELECT @TaskStatusID = TaskStatusId FROM dbo.TaskStatus WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyID AND UPPER(StatusCode) = 'COMPLETED'

				SELECT @InventoryStatusID = AssetInventoryStatusId FROM dbo.AssetInventoryStatus WITH (NOLOCK) WHERE UPPER(Status) = 'AVAILABLE'

				SELECT @IsShippingCompleled = count(WorkOrderShippingId) FROM dbo.WorkOrderShippingItem WITH (NOLOCK) WHERE WorkOrderPartNumId = @workOrderPartNoId
				SELECT @IsBillingCompleled = count(wobi.BillingInvoicingId) FROM DBO.WorkOrderBillingInvoicing wobi 
						INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wobi.BillingInvoicingId = wobii.BillingInvoicingId
						INNER JOIN DBO.WorkOrderPartNumber wop WITH(NOLOCK) on wop.WorkOrderId = wobi.WorkOrderId AND wop.ID = wobii.WorkOrderPartId
						INNER JOIN DBO.WorkOrderWorkFlow wowf WITH(NOLOCK) on wop.ID = wowf.WorkOrderPartNoId  WHERE wop.WorkOrderId = @WorkorderId and wop.ID =@workOrderPartNoId and wobi.IsVersionIncrease=0 and InvoiceStatus='Invoiced'

				IF(EXISTS (SELECT 1 FROM dbo.WorkOrderLaborHeader WLH WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @workflowWorkorderId and IsDeleted= 0))
				BEGIN 
				    
					SELECT @IsLaborCompleled = COUNT(WL.WorkOrderLaborId)
					FROM dbo.WorkOrderLabor WL WITH(NOLOCK) 
						JOIN dbo.WorkOrderLaborHeader WLH WITH(NOLOCK) ON WL.WorkOrderLaborHeaderId = WLH.WorkOrderLaborHeaderId
					WHERE WLH.WorkFlowWorkOrderId = @workflowWorkorderId and WLh.WorkOrderId = @WorkorderId and WLH.IsDeleted= 0 AND ISNULL(WL.TaskStatusId, 0) <> @TaskStatusID
					PRINT @IsLaborCompleled
				END
				ELSE
				BEGIN
					SELECT @IsLaborCompleled = 0;
				END

				IF(EXISTS (SELECT 1 FROM dbo.CheckInCheckOutWorkOrderAsset COCI WITH(NOLOCK) WHERE COCI.workOrderPartNoId = @workOrderPartNoId AND COCI.WorkOrderId = @WorkorderId and IsDeleted= 0))
				BEGIN 
					SELECT @AllToolsAreCheckOut = COUNT(COCI.CheckInCheckOutWorkOrderAssetId)
					FROM dbo.CheckInCheckOutWorkOrderAsset COCI WITH(NOLOCK) 
					WHERE COCI.workOrderPartNoId = @workOrderPartNoId and COCI.IsDeleted= 0 AND COCI.WorkOrderId = @WorkorderId AND ISNULL(COCI.InventoryStatusId, 0) <> @InventoryStatusID
				END
				ELSE
				BEGIN
					SELECT @AllToolsAreCheckOut = 0;
				END
				
				SELECT  wosd.WorkOrderId, 
						wos.WorkOrderSettlementName, 
						wos.WorkOrderSettlementId, 
						ISNULL(wosd.WorkFlowWorkOrderId,0) as WorkFlowWorkOrderId,
						ISNULL(wosd.workOrderPartNoId,0) as workOrderPartNoId,
						ISNULL(wosd.WorkOrderSettlementDetailId,0) as WorkOrderSettlementDetailId,
						--CASE WHEN wos.WorkOrderSettlementId = 1 THEN CASE WHEN ISNULL(@qtyreq, 0) +  ISNULL(@QtyToTendered, 0) = (ISNULL(@qtyissue, 0) + ISNULL(@QtyTendered, 0)) THEN 1 ELSE 0 END 
						CASE WHEN wos.WorkOrderSettlementId = 1 THEN CASE WHEN ISNULL(@qtyrequested, 0) = (ISNULL(@qtyissued, 0)) THEN 1 ELSE 0 END 
							 WHEN wos.WorkOrderSettlementId = 2 THEN CASE WHEN @IsLaborCompleled <= 0 THEN 1 ELSE 0 END 
							 WHEN wos.WorkOrderSettlementId = 6 THEN CASE WHEN @AllToolsAreCheckOut <= 0 THEN 1 ELSE 0 END 
						ELSE wosd.IsMastervalue END 
						AS IsMastervalue,
						wosd.Isvalue_NA,
					    wosd.Memo,
					    ISNULL(wosd.ConditionId,0) as ConditionId,
					    ISNULL(wosd.UserId,0) as UserId,
						wosd.conditionName,
					    wosd.UserName,
					    wosd.sattlement_DateTime,
						wosd.MasterCompanyId,
						wosd.CreatedBy,
						wosd.UpdatedBy,
						wosd.CreatedDate,
						wosd.UpdatedDate,
						wosd.IsActive,
						wosd.IsDeleted,
						wosd.RevisedPartId,
						IM.partnumber as 'RevisedPartNumber',
						case when @IsShippingCompleled > 0 then 1 else 0 end as 'IsShippingCompleled',
						case when @IsBillingCompleled > 0 then 1 else 0 end as 'IsBillingCompleled'
				FROM DBO.WorkOrderSettlement wos  WITH(NOLOCK)
					LEFT JOIN dbo.WorkOrderSettlementDetails wosd WITH(NOLOCK) on wosd.WorkOrderSettlementId = wos.WorkOrderSettlementId
					LEFT JOIN ItemMaster IM ON IM.ItemMasterId = wosd.RevisedPartId
				WHERE wosd.WorkOrderId = @WorkorderId and wosd.WorkflowWorkOrderId = @workflowWorkorderId and wosd.workOrderPartNoId = @workOrderPartNoId 
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderSettlementDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '''
													   @Parameter3 = '''+ ISNULL(@workOrderPartNoId, '') + '''
													   @Parameter4 = ' + ISNULL(@workflowWorkorderId ,'') +''
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