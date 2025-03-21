/*************************************************************           
 ** File:   [dbo].[CreateTravelerLabourTask]
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Create Traveler Labour Task
 ** Purpose:         
 ** Date:   18/03/2025        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    18/03/2025   Moin Bloch    Created
     
--   EXEC [dbo].[CreateTravelerLabourTask]
**************************************************************/
CREATE   PROCEDURE [dbo].[CreateTravelerLabourTask]
@tbl_WorkOrderPartNumberType WorkOrderPartNumberType READONLY,
@WorkOrderId BIGINT,
@CreatedBy VARCHAR(256),
@CreatedDate DATETIME2(7),
@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
	
	DECLARE @TotalRecord INT = 0,@MinId BIGINT = 1
			
	IF OBJECT_ID(N'tempdb..#tempCreateTravelerLabourTaskForCreateWO') IS NOT NULL
	BEGIN
		DROP TABLE #tempCreateTravelerLabourTaskForCreateWO
	END	
	
	CREATE TABLE #tempCreateTravelerLabourTaskForCreateWO
	(
		[PKID] [BIGINT] NOT NULL IDENTITY, 
		[ID] [BIGINT] NULL,
		[IsTraveler] [BIT] NULL		
	)
		
	INSERT INTO #tempCreateTravelerLabourTaskForCreateWO([ID],[IsTraveler])
	SELECT [ID],[IsTraveler] FROM @tbl_WorkOrderPartNumberType

	SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tempCreateTravelerLabourTaskForCreateWO  

	WHILE @MinId <= @TotalRecord
	BEGIN
	    DECLARE @ID BIGINT = NULL,@IsTraveler BIT = NULL,@WorkFlowWorkOrderId BIGINT = NULL
		
		SELECT @ID=[ID],@IsTraveler=[IsTraveler] FROM #tempCreateTravelerLabourTaskForCreateWO WHERE [PKID] = @MinId

		IF(@IsTraveler = 1)
		BEGIN
			SELECT TOP 1 @WorkFlowWorkOrderId = [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderPartNoId] = @ID;

			EXEC [dbo].[USP_CreateTravelerLabourTask] @WorkOrderId,@ID,@WorkFlowWorkOrderId,@MasterCompanyId,@CreatedBy;
		END
			
		SET @MinId = @MinId + 1
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
              , @AdhocComments     VARCHAR(150)    = 'CreateTravelerLabourTask' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100)) + 
			                                         '@Parameter2 = ''' + CAST(ISNULL(@CreatedBy, '') AS VARCHAR(100))
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