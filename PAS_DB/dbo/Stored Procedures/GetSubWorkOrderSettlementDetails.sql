
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
     
--EXEC [GetSubWorkOrderSettlementDetails] 212,35,37
**************************************************************/

CREATE PROCEDURE [dbo].[GetSubWorkOrderSettlementDetails]
@WorkorderId bigint,
@SubWorkOrderId bigint,
@SubWOPartNoId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @qtyissue INT =0
				DECLARE @qtyreq INT =0
				DECLARE @TaskStatusID INT;
				DECLARE @MasterCompanyID INT;
				DECLARE @IsLaborCompleled INT = 0;
				DECLARE @AllToolsAreCheckOut INT = 0;
				DECLARE @InventoryStatusID INT;
				DECLARE @QtyTendered INT =0;				

				SELECT @qtyreq = SUM(ISNULL(Quantity,0)),
						@qtyissue=SUM(ISNULL(QuantityIssued,0)) 						
				FROM dbo.SubWorkOrderMaterials WITH(NOLOCK) 	  
				WHERE WorkOrderId=@WorkorderId and SubWorkOrderId=@SubWorkOrderId and SubWOPartNoId =@SubWOPartNoId

				SELECT @QtyTendered = SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.SubWorkOrderMaterialStockLine womsl WITH (NOLOCK)
					JOIN dbo.Stockline sl WITH (NOLOCK) ON womsl.StockLIneId = sl.StockLIneId
					JOIN dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) ON womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId
				WHERE WOM.WorkOrderId=@WorkorderId AND WOM.SubWorkOrderId=@SubWorkOrderId AND WOM.SubWOPartNoId =@SubWOPartNoId AND womsl.ConditionId = WOM.ConditionCodeId
					AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0

				SELECT @MasterCompanyID = MasterCompanyId FROM dbo.WorkOrder WITH (NOLOCK) WHERE WorkOrderId = @WorkorderId

				SELECT @TaskStatusID = TaskStatusId FROM dbo.TaskStatus WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyID AND UPPER(StatusCode) = 'COMPLETED'

				SELECT @InventoryStatusID = AssetInventoryStatusId FROM dbo.AssetInventoryStatus WITH (NOLOCK) WHERE UPPER(Status) = 'AVAILABLE'
				
				IF(EXISTS (SELECT 1 FROM dbo.SubWorkOrderLaborHeader WLH WITH(NOLOCK) WHERE WLH.SubWorkOrderId = @SubWorkOrderId AND WLH.SubWOPartNoId = @SubWOPartNoId AND WLH.WorkOrderId = @WorkorderId))
				BEGIN 
					SELECT @IsLaborCompleled = COUNT(WL.SubWorkOrderLaborId)
					FROM dbo.SubWorkOrderLabor WL WITH(NOLOCK) 
						JOIN dbo.SubWorkOrderLaborHeader WLH WITH(NOLOCK) ON WL.SubWorkOrderLaborHeaderId = WLH.SubWorkOrderLaborHeaderId
					WHERE WLH.SubWorkOrderId = @SubWorkOrderId AND WLH.SubWOPartNoId = @SubWOPartNoId AND WLH.WorkOrderId = @WorkorderId AND  ISNULL(WL.TaskStatusId, 0) <> @TaskStatusID
				END
				ELSE
				BEGIN
					SELECT @IsLaborCompleled = 1;
				END

				IF(EXISTS (SELECT 1 FROM dbo.SubWOCheckInCheckOutWorkOrderAsset COCI WITH(NOLOCK) WHERE COCI.SubWOPartNoId = @SubWOPartNoId AND COCI.SubWorkOrderId = @SubWorkorderId AND COCI.WorkOrderId = @WorkorderId))
				BEGIN 
					SELECT @AllToolsAreCheckOut = COUNT(COCI.SubWOCheckInCheckOutWorkOrderAssetId)
					FROM dbo.SubWOCheckInCheckOutWorkOrderAsset COCI WITH(NOLOCK) 
					WHERE COCI.SubWOPartNoId = @SubWOPartNoId AND COCI.SubWorkOrderId = @SubWorkorderId AND COCI.WorkOrderId = @WorkorderId AND ISNULL(COCI.InventoryStatusId, 0) <> @InventoryStatusID
				END
				ELSE
				BEGIN
					SELECT @AllToolsAreCheckOut = 1;
				END

				SELECT  wosd.WorkOrderId, 
						wos.WorkOrderSettlementName, 
						wos.WorkOrderSettlementId, 
						ISNULL(wosd.SubWorkOrderId,0) as SubWorkOrderId,
						ISNULL(wosd.SubWOPartNoId,0) as SubWOPartNoId,
						ISNULL(wosd.SubWorkOrderSettlementDetailId,0) as SubWorkOrderSettlementDetailId,
						CASE WHEN wos.WorkOrderSettlementId = 1  THEN CASE WHEN ISNULL(@qtyreq, 0) = (ISNULL(@qtyissue, 0) + ISNULL(@QtyTendered, 0)) THEN 1 ELSE  0 END 
							 WHEN wos.WorkOrderSettlementId = 2 THEN CASE WHEN @IsLaborCompleled <= 0 THEN 1 ELSE 0 END 
							 WHEN wos.WorkOrderSettlementId = 6 THEN CASE WHEN @AllToolsAreCheckOut <= 0 THEN 1 ELSE 0 END 
						ELSE wosd.IsMastervalue END as IsMastervalue,
						wosd.Isvalue_NA,
					    wosd.Memo,
					    ISNULL(wosd.ConditionId,0) as ConditionId,
						wosd.conditionName,
					    ISNULL(wosd.UserId,0) as UserId,
					    wosd.UserName,
					    wosd.sattlement_DateTime,
						wosd.MasterCompanyId,
						wosd.CreatedBy,
						wosd.UpdatedBy,
						wosd.CreatedDate,
						wosd.UpdatedDate,
						wosd.IsActive,
						wosd.IsDeleted,
						Im.partnumber
				FROM DBO.WorkOrderSettlement wos  WITH(NOLOCK)
					LEFT JOIN dbo.SubWorkOrderSettlementDetails wosd WITH(NOLOCK) on wosd.WorkOrderSettlementId = wos.WorkOrderSettlementId
					LEFT JOIN dbo.SubWorkOrderPartNumber sop WITH(NOLOCK) on sop.SubWOPartNoId = wosd.SubWOPartNoId
					LEFT JOIN dbo.ItemMaster Im WITH(NOLOCK) on sop.ItemMasterId = Im.ItemMasterId
				WHERE wosd.WorkOrderId = @WorkorderId and wosd.SubWorkOrderId = @SubWorkOrderId and wosd.SubWOPartNoId = @SubWOPartNoId 
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetSubWorkOrderSettlementDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '''
													   @Parameter3 = '''+ ISNULL(@SubWorkOrderId, '') + '''
													   @Parameter4 = ' + ISNULL(@SubWOPartNoId ,'') +''
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