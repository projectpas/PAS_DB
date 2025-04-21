/*************************************************************           
 ** File:   [USP_GetLaborMainTaskListSub_WorkOrder]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Create Stockline ForCustomer RMA   
 ** Purpose:         
 ** Date:   01/03/2023        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    01/03/2023   Subhash Saliya	Created
    2    04/21/2025   Vishal Suthar		Corrected the table name and added DB standards

-- EXEC [USP_GetLaborMainTaskListSub_WorkOrder] 692,682
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLaborMainTaskListSub_WorkOrder]
 @subWOPartNoId bigint ,
 @subWorkOrderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @DataEnteredBy BIGINT = 0
				DECLARE @Traveler_setupid AS BIGINT = 0;
				DECLARE @WorkOrderPartId AS BIGINT = 0;
				DECLARE @WorkScopeId AS BIGINT = 0;
				DECLARE @ItemMasterId AS BIGINT = 0;
				DECLARE @IstravelerTask BIT = 0
			    DECLARE @highestSequence BIGINT = 0
                
				SET @WorkOrderPartId=@subWOPartNoId
				SELECT TOP 1 @ItemMasterId=ItemMasterId,@WorkScopeId=SubWorkOrderScopeId,@IstravelerTask=IsTraveler from DBO.SubWorkOrderPartNumber WITH (NOLOCK) WHERE SubWOPartNoId = @WorkOrderPartId

			    IF (EXISTS (SELECT 1 FROM DBO.Traveler_Setup WITH (NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId = @ItemMasterId AND IsVersionIncrease = 0))
				BEGIN
				   SELECT TOP 1 @Traveler_setupid= Traveler_setupid FROM Traveler_Setup WITH (NOLOCK) WHERE WorkScopeId = @WorkScopeId AND ItemMasterId = @ItemMasterId AND IsVersionIncrease = 0
				
				SELECT TOP 1 @highestSequence= Sequence FROM DBO.Traveler_Setup_Task WITH (NOLOCK) WHERE Traveler_setupid =@Traveler_setupid ORDER BY Sequence DESC
				END
				ELSE IF (EXISTS (SELECT 1 FROM DBO.Traveler_Setup WITH (NOLOCK) WHERE WorkScopeId = @WorkScopeId AND ItemMasterId IS NULL AND IsVersionIncrease = 0))
				BEGIN
				   SELECT TOP 1 @Traveler_setupid= Traveler_setupid FROM DBO.Traveler_Setup WITH (NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId IS NULL AND IsVersionIncrease = 0

				SELECT TOP 1 @highestSequence = Sequence FROM DBO.Traveler_Setup_Task WITH (NOLOCK) where Traveler_setupid = @Traveler_setupid ORDER BY Sequence DESC
				END

				SELECT 
                wl.[TaskId],
				Max([TaskInstruction]) as TaskInstruction,
				Max(UPPER(T.Description)) as Task,
				Max(SubWorkOrderLaborId) as WorkOrderLaborId,
				Max(Isnull(TTS.Sequence,9999)) as Sequence,
				Max(@highestSequence) as HighestSequence
                FROM [dbo].[SubWorkOrderLabor] wl  WITH(NOLOCK) 
                INNER JOIN DBO.SubWorkOrderLaborHeader wlh WITH(NOLOCK)  ON wlh.SubWorkOrderLaborHeaderId = wl.SubWorkOrderLaborHeaderId
                INNER JOIN DBO.SubWorkOrderTask SWOT WITH(NOLOCK) ON SWOT.SubWorkOrderTaskId = wl.TaskId
                LEFT JOIN DBO.Task T WITH(NOLOCK) ON T.TaskId= SWOT.TaskId
				LEFT JOIN DBO.Traveler_Setup_Task TTS WITH(NOLOCK) ON TTS.TaskId = wl.TaskId AND Traveler_SetupId = @Traveler_setupid
                WHERE wl.IsDeleted = 0 AND wlh.SubWOPartNoId = @WorkOrderPartId AND wlh.SubWorkOrderId = @subWorkOrderId
				GROUP BY wl.[TaskId] ORDER BY Sequence ASC
			END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLaborMainTaskList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderPartId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END