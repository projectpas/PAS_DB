
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
     
--EXEC [GetWorkOrderSettlementDetails] 67,66,66
**************************************************************/

CREATE PROCEDURE [dbo].[GetWorkOrderSettlementDetails]
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
				DECLARE @qtyissue INT =0
				DECLARE @qtyreq INT =0
				DECLARE @TaskStatusID INT;
				DECLARE @MasterCompanyID INT;
				DECLARE @IsLaborCompleled INT = 0;
				DECLARE @AllToolsAreCheckOut INT = 0;
				DECLARE @InventoryStatusID INT;

				SELECT @qtyreq = SUM(ISNULL(Quantity,0)),
						@qtyissue=SUM(ISNULL(QuantityIssued,0)) 
				FROM dbo.WorkOrderMaterials WITH(NOLOCK) 	  
				WHERE WorkFlowWorkOrderId=@workflowWorkorderId
				
				SELECT @MasterCompanyID = MasterCompanyId FROM dbo.WorkOrder WITH (NOLOCK) WHERE WorkOrderId = @WorkorderId

				SELECT @TaskStatusID = TaskStatusId FROM dbo.TaskStatus WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyID AND UPPER(StatusCode) = 'COMPLETED'

				SELECT @InventoryStatusID = AssetInventoryStatusId FROM dbo.AssetInventoryStatus WITH (NOLOCK) WHERE UPPER(Status) = 'AVAILABLE'

				IF(EXISTS (SELECT 1 FROM dbo.WorkOrderLaborHeader WLH WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @workflowWorkorderId))
				BEGIN 
					SELECT @IsLaborCompleled = COUNT(WL.WorkOrderLaborId)
					FROM dbo.WorkOrderLabor WL WITH(NOLOCK) 
						JOIN dbo.WorkOrderLaborHeader WLH WITH(NOLOCK) ON WL.WorkOrderLaborHeaderId = WLH.WorkOrderLaborHeaderId
					WHERE WLH.WorkFlowWorkOrderId = @workflowWorkorderId AND ISNULL(WL.TaskStatusId, 0) <> @TaskStatusID
				END
				ELSE
				BEGIN
					SELECT @IsLaborCompleled = 1;
				END

				IF(EXISTS (SELECT 1 FROM dbo.CheckInCheckOutWorkOrderAsset COCI WITH(NOLOCK) WHERE COCI.workOrderPartNoId = @workOrderPartNoId AND COCI.WorkOrderId = @WorkorderId))
				BEGIN 
					SELECT @AllToolsAreCheckOut = COUNT(COCI.CheckInCheckOutWorkOrderAssetId)
					FROM dbo.CheckInCheckOutWorkOrderAsset COCI WITH(NOLOCK) 
					WHERE COCI.workOrderPartNoId = @workOrderPartNoId AND COCI.WorkOrderId = @WorkorderId AND ISNULL(COCI.InventoryStatusId, 0) <> @InventoryStatusID
				END
				ELSE
				BEGIN
					SELECT @AllToolsAreCheckOut = 1;
				END
				
				SELECT  wosd.WorkOrderId, 
						wos.WorkOrderSettlementName, 
						wos.WorkOrderSettlementId, 
						ISNULL(wosd.WorkFlowWorkOrderId,0) as WorkFlowWorkOrderId,
						ISNULL(wosd.workOrderPartNoId,0) as workOrderPartNoId,
						ISNULL(wosd.WorkOrderSettlementDetailId,0) as WorkOrderSettlementDetailId,
						CASE WHEN wos.WorkOrderSettlementId = 1 THEN CASE WHEN @qtyreq = @qtyissue THEN 1 ELSE 0 END 
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
						wosd.IsDeleted
				FROM DBO.WorkOrderSettlement wos  WITH(NOLOCK)
					LEFT JOIN dbo.WorkOrderSettlementDetails wosd WITH(NOLOCK) on wosd.WorkOrderSettlementId = wos.WorkOrderSettlementId
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