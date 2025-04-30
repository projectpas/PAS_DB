/*************************************************************           
 ** File:   [dbo].[CreateWorkOrderSettlementDetails]
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Create Work Order Settlement Details
 ** Purpose:         
 ** Date:   17/03/2025        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    17/03/2025   Moin Bloch		Created
    2    03/04/2025   Devendra Shekh    Resolved issue for Save Details for Multiple MPN
     
--   EXEC [dbo].[CreateWorkOrderSettlementDetails]
**************************************************************/
CREATE    PROCEDURE [dbo].[CreateWorkOrderSettlementDetails]
@tbl_WorkOrderPartNumberType WorkOrderPartNumberType READONLY,
@WorkOrderId BIGINT,
@WorkOrderTypeId BIGINT,
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
	DECLARE @SMTotalRecord INT = 0,@SMMinId BIGINT = 1
	DECLARE @TearDown INT=3
	
	SELECT @TearDown = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Teardown';
	
	IF OBJECT_ID(N'tempdb..#tmprCreateWorkOrderSettlementDetails') IS NOT NULL
	BEGIN
		DROP TABLE #tmprCreateWorkOrderSettlementDetails
	END
	IF OBJECT_ID(N'tempdb..#tmprWorkOrderSettlement') IS NOT NULL
	BEGIN
		DROP TABLE #tmprWorkOrderSettlement
	END
	
	CREATE TABLE #tmprCreateWorkOrderSettlementDetails
	(
		[PKID] [BIGINT] NOT NULL IDENTITY, 
		[ID] [BIGINT] NULL
	)

	CREATE TABLE #tmprWorkOrderSettlement
	(
	    [SMID] [BIGINT] NOT NULL IDENTITY, 
		[WorkOrderSettlementId] [BIGINT] NOT NULL
	)

	INSERT INTO #tmprCreateWorkOrderSettlementDetails([ID])
	SELECT [ID] FROM @tbl_WorkOrderPartNumberType

	SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tmprCreateWorkOrderSettlementDetails  

	WHILE @MinId <= @TotalRecord
	BEGIN
	    DECLARE @ID [BIGINT] = NULL,@WorkFlowWorkOrderId [BIGINT] = NULL,@WorkOrderSettlementDetailId [BIGINT] = NULL,@WorkOrderSettlementId [BIGINT] = NULL

		SELECT @ID=[ID] FROM #tmprCreateWorkOrderSettlementDetails WHERE [PKID] = @MinId
		
		TRUNCATE TABLE #tmprWorkOrderSettlement

		INSERT INTO #tmprWorkOrderSettlement([WorkOrderSettlementId])
		SELECT [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE [IsDeleted] = 0;
	   
	    SELECT @WorkFlowWorkOrderId=[WorkFlowWorkOrderId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderPartNoId] = @ID;

		IF NOT EXISTS(SELECT TOP 1 [WorkOrderSettlementDetailId] FROM [dbo].[WorkOrderSettlementDetails] WITH(NOLOCK) WHERE [IsDeleted] = 0 AND [workOrderPartNoId] = @ID)
		BEGIN
			
			SELECT @SMTotalRecord = COUNT(*), @SMMinId = MIN([SMID]) FROM #tmprWorkOrderSettlement  
			WHILE @SMMinId <= @SMTotalRecord
			BEGIN
			    DECLARE @Isvalue_NA BIT=0;

				SELECT @WorkOrderSettlementId=[WorkOrderSettlementId] FROM #tmprWorkOrderSettlement WHERE [SMID] = @SMMinId
				
				IF(@WorkOrderTypeId = @TearDown AND @WorkOrderSettlementId IN (3, 4, 5, 7, 8,10, 11))
				BEGIN
					 SET @Isvalue_NA = 1;
				END
				ELSE 
				BEGIN
					SET @Isvalue_NA = 0;
				END

				INSERT INTO [dbo].[WorkOrderSettlementDetails]([WorkOrderId],[WorkFlowWorkOrderId],[workOrderPartNoId],[WorkOrderSettlementId],[MasterCompanyId],
						    [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsMastervalue],[Isvalue_NA],[Memo],[ConditionId],[UserId],
							[UserName],[sattlement_DateTime],[conditionName],[RevisedPartId])
                      VALUES(@WorkOrderId,@WorkFlowWorkOrderId,@ID,@WorkOrderSettlementId,@MasterCompanyId,
					         @CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate,1,0,0,@Isvalue_NA,'',NULL,NULL,
							 NULL,NULL,NULL,NULL);

				SET @SMMinId = @SMMinId + 1
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
              , @AdhocComments     VARCHAR(150)    = 'CreateWorkOrderSettlementDetails' 
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