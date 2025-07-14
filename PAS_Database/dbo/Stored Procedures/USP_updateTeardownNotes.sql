/***************************************************************
 ** File:   [USP_updateActionForVendorAudit]
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used to update WorkOrderTearDown memo.
 ** Date:  03-04-2025
            
  ** Change History
 **************************************************************             
 ** PR   Date				Author  			Change Description              
 ** --   --------			-------				--------------------------------            
    1    03-04-2025			AMIT GHEDIYA		Created
    2    04-04-2025			Devendra SHekh		Added Audit Details changes
	3    10-07-2025         Moin Bloch          Updated PublicationNotes
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_updateTeardownNotes]
	@WorkOrderId BIGINT,
	@WorkFlowWorkOrderId BIGINT,
	@CommonWorkOrderTearDownId BIGINT,
	@Memo VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
		
		--UPDATE [DBO].[CommonWorkOrderTearDown]
		--	SET 
		--	Memo = @Memo
		--	WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND CommonWorkOrderTearDownId = @CommonWorkOrderTearDownId;
	
		----Adding Audit Details
		--DECLARE @CommonTeardownType VARCHAR(250), @CommonTeardownTypeId BIGINT = 0;

		--SELECT @CommonTeardownTypeId = [CommonTeardownTypeId] FROM [DBO].[CommonWorkOrderTearDown] WITH(NOLOCK) WHERE [CommonWorkOrderTearDownId] = @CommonWorkOrderTearDownId;
		--SELECT @CommonTeardownType = [Name] FROM [dbo].[CommonTeardownType] WITH(NOLOCK)  where CommonTeardownTypeId= @CommonTeardownTypeId

		--INSERT INTO [dbo].[CommonWorkOrderTearDownAudit]
		--		([CommonWorkOrderTearDownId] ,[CommonTeardownType] ,[Memo] ,[TechnicianDate] ,[InspectorDate] ,[ReasonName] ,[InspectorName] ,[TechnicalName]
		--		,[CreatedBy] ,[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted] ,[MasterCompanyId] ,[IsSubWorkOrder])
		--SELECT	@CommonWorkOrderTeardownId ,@CommonTeardownType ,@Memo ,[TechnicianDate] ,[InspectorDate] ,[ReasonName] ,[InspectorName] ,[TechnicalName]
		--		,[CreatedBy] ,[UpdatedBy] ,[CreatedDate] ,GETDATE(), [IsActive] ,[IsDeleted] ,[IsSubWorkOrder] ,IsSubWorkOrder
		--FROM [DBO].[CommonWorkOrderTearDown] WITH(NOLOCK)
		--WHERE CommonWorkOrderTearDownId = @CommonWorkOrderTeardownId

		DECLARE @WorkOrderPartNoId BIGINT = 0

		SELECT @WorkOrderPartNoId = WorkOrderPartNoId 
		 FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) 
		WHERE [WorkOrderId] = @WorkOrderId 
		  AND [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId
		  
		UPDATE [dbo].[WorkOrderPartNumber] SET [PublicationNotes] = @Memo WHERE [ID] = @WorkOrderPartNoId AND [WorkOrderId] = @WorkOrderId 

	END TRY   
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_updateTeardownNotes'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '', '
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);           
	END CATCH
END;