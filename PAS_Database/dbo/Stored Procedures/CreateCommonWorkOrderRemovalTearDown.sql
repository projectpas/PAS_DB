/*************************************************************           
 ** File:   [dbo].[CreateCommonWorkOrderRemovalTearDown]
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Create Common Work Order Removal TearDown
 ** Purpose:         
 ** Date:   18/03/2025        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    18/03/2025   Moin Bloch    Created
     
--   EXEC [dbo].[CreateCommonWorkOrderRemovalTearDown]
**************************************************************/
CREATE    PROCEDURE [dbo].[CreateCommonWorkOrderRemovalTearDown]
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
			
	IF OBJECT_ID(N'tempdb..#CreateCommonWorkOrderRemovalTearDownForCreateWO') IS NOT NULL
	BEGIN
		DROP TABLE #CreateCommonWorkOrderRemovalTearDownForCreateWO
	END	
	
	CREATE TABLE #CreateCommonWorkOrderRemovalTearDownForCreateWO
	(
		[PKID] [BIGINT] NOT NULL IDENTITY, 
		[ID] [BIGINT] NULL,
		[ReceivingCustomerWorkId] [BIGINT] NULL		
	)
		
	INSERT INTO #CreateCommonWorkOrderRemovalTearDownForCreateWO([ID],[ReceivingCustomerWorkId])
	SELECT [ID],[ReceivingCustomerWorkId] FROM @tbl_WorkOrderPartNumberType

	SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #CreateCommonWorkOrderRemovalTearDownForCreateWO  

	WHILE @MinId <= @TotalRecord
	BEGIN
	    DECLARE @ID [BIGINT] = NULL,@WorkFlowWorkOrderId [BIGINT] = NULL,@ReceivingCustomerWorkId [BIGINT] = 0,@RemovalReasonId [BIGINT] = 0
		DECLARE @CommonTeardownTypeId [BIGINT] = 0,@TeardownReasonId [BIGINT] = 0,@CommonWorkOrderTearDownId [BIGINT] = 0
		DECLARE @Reason VARCHAR(1000)='',@RemovalReasonsMemo NVARCHAR(MAX)=''		
		
		SELECT @ID=[ID],@ReceivingCustomerWorkId=[ReceivingCustomerWorkId] FROM #CreateCommonWorkOrderRemovalTearDownForCreateWO WHERE [PKID] = @MinId

		SELECT @WorkFlowWorkOrderId = [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderPartNoId] = @ID;

		IF(@ReceivingCustomerWorkId > 0)
		BEGIN
			SELECT @RemovalReasonId = [RemovalReasonId],@RemovalReasonsMemo = [RemovalReasonsMemo] FROM [dbo].[ReceivingCustomerWork] WITH(NOLOCK) WHERE [ReceivingCustomerWorkId] = @ReceivingCustomerWorkId;			
			IF(@RemovalReasonId > 0)
			BEGIN
				SELECT TOP 1 @CommonTeardownTypeId = ISNULL([CommonTeardownTypeId],0) FROM [dbo].[CommonTeardownType] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [TearDownCode] ='RemovalReason';
				
				IF NOT EXISTS(SELECT TOP 1 [CommonWorkOrderTearDownId] FROM [dbo].[CommonWorkOrderTeardown] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId)
				BEGIN
					INSERT INTO [dbo].[CommonWorkOrderTearDown]([CommonTeardownTypeId],[WorkOrderId],[WorkFlowWorkOrderId],[WOPartNoId],[Memo],[ReasonId],[TechnicianId],[TechnicianDate]
							   ,[InspectorId],[InspectorDate],[IsDocument],[ReasonName],[InspectorName],[TechnicalName],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive]
							   ,[IsDeleted],[MasterCompanyId],[IsSubWorkOrder],[SubWorkOrderId],[SubWOPartNoId])
						VALUES (@CommonTeardownTypeId,@WorkOrderId,@WorkFlowWorkOrderId,0,'',NULL,NULL,NULL,
								NULL,NULL,0,'',NULL,NULL,@CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate,1,
								0,@MasterCompanyId,0,0,0);

					SET @CommonWorkOrderTearDownId = SCOPE_IDENTITY();	   

					 SELECT TOP 1 @TeardownReasonId = [TeardownReasonId],
					              @Reason = [Reason]
					   	    FROM [dbo].[TeardownReason] WITH(NOLOCK) 
						   WHERE [TeardownReasonId] = @RemovalReasonId AND [MasterCompanyId] = @MasterCompanyId;
				
					IF(@CommonWorkOrderTearDownId > 0)
					BEGIN						
					    UPDATE [dbo].[CommonWorkOrderTearDown]
						   SET [ReasonId] = @TeardownReasonId
							  ,[ReasonName] = @Reason
							  ,[Memo] = @RemovalReasonsMemo				  
						 WHERE [CommonWorkOrderTearDownId] = @CommonWorkOrderTearDownId
					END
				END
			END
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
              , @AdhocComments     VARCHAR(150)    = 'CreateCommonWorkOrderRemovalTearDown' 
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