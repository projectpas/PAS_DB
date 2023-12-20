/*************************************************************           
 ** File:   [UpdatePartAfterWOCreated]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to update part details after WO is created in receiving customer
 ** Purpose:
 ** Date:   05/31/2023
          
 ** PARAMETERS:          
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/31/2023   Vishal Suthar Created
     
-- EXEC [UpdatePartAfterWOCreated] 1005, 2956
**************************************************************/
CREATE   PROCEDURE [dbo].[UpdatePartAfterWOCreated]
	@ItemMasterId BIGINT,
	@ConditionId BIGINT,
	@WorkOrderPartNumberId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF NOT EXISTS (SELECT TOP 1 * FROM DBO.WorkOrderPartNumber WOP WITH (NOLOCK) WHERE ID = @WorkOrderPartNumberId AND WOP.ItemMasterId = @ItemMasterId AND WOP.ConditionId = @ConditionId)
				BEGIN
					UPDATE SL 
					SET SL.ItemMasterId = @ItemMasterId,
					SL.ConditionId = @ConditionId,
					SL.Condition = (SELECT Con.Code FROM DBO.Condition Con WITH(NOLOCK) WHERE Con.ConditionId = @ConditionId),
					SL.PartNumber = (SELECT IIM.partnumber FROM DBO.ItemMaster IIM WITH(NOLOCK) WHERE IIM.ItemMasterId = @ItemMasterId),
					SL.PNDescription = (SELECT IIM.PartDescription FROM DBO.ItemMaster IIM WITH(NOLOCK) WHERE IIM.ItemMasterId = @ItemMasterId)
					FROM [dbo].[Stockline] SL WITH(NOLOCK)
					INNER JOIN dbo.ReceivingCustomerWork RC WITH(NOLOCK) ON SL.StockLineId = RC.StockLineId
					INNER JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.ItemMasterId = RC.ItemMasterId
					INNER JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = RC.ItemMasterId
					WHERE WOP.ID = @WorkOrderPartNumberId;

					UPDATE WOP 
					SET WOP.ItemMasterId = @ItemMasterId,
					WOP.ConditionId = @ConditionId,
					WOP.RevisedItemmasterid = @ItemMasterId
					FROM [dbo].WorkOrderPartNumber WOP WITH(NOLOCK)
					WHERE WOP.ID = @WorkOrderPartNumberId;

					UPDATE WOSD
					SET WOSD.RevisedPartId = @ItemMasterId,
					WOSD.ConditionId = @ConditionId,
					WOSD.conditionName = (SELECT Con.Code FROM DBO.Condition Con WITH(NOLOCK) WHERE Con.ConditionId = @ConditionId)
					FROM [dbo].WorkOrderSettlementDetails WOSD WITH(NOLOCK)
					WHERE WOSD.workOrderPartNoId = @WorkOrderPartNumberId
					AND WOSD.WorkOrderSettlementId = 9
					AND WOSD.RevisedPartId IS NOT NULL;
				END
			END
		COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdatePartAfterWOCreated' 
              , @ProcedureParameters VARCHAR(3000)  = '@ItemMasterId = '''+ ISNULL(@ItemMasterId, '') + ',
													   @WorkOrderPartNumberId = '''+ ISNULL(@WorkOrderPartNumberId, '') + ''
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