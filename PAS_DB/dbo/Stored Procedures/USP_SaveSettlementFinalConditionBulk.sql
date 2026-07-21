/*************************************************************           
 ** File:   [USP_SaveSettlementFinalConditionBulk]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to add Work order Settlement Details 
 ** Purpose:         
 ** Date:   14/07/2026
 ** PARAMETERS:                   
 ** RETURN VALUE:         
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    14/07/2026   Moin Bloch 	    Created
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveSettlementFinalConditionBulk]
(
    @WOSettlementList [dbo].[WOSettlementUpdateType] READONLY
)
AS
BEGIN
    SET NOCOUNT ON;

		DECLARE @TotalRecord INT = 0;   
		DECLARE @MinId BIGINT = 1;  
		DECLARE @UpdatedDate DATETIME2(7) =  GETUTCDATE()
		DECLARE @TearDown INT
		DECLARE @ConditionSettlement   INT = 0,@ReleaseFormSettlement INT = 0;
		DECLARE @WOModuleId INT=0,@WOMPNModuleId INT=0;
		
		DECLARE @WorkOrderId         BIGINT = NULL,
		  	    @WorkOrderPartNoId   BIGINT = NULL,
				@WorkFlowWorkOrderId BIGINT = NULL,
				@SubWorkOrderId      BIGINT = NULL,
				@SubWOPartNoId       BIGINT = NULL,
				@FinalConditionId    BIGINT = NULL,
				@IsSubWorkOrder      BIT = 0,
				@UpdatedBy           VARCHAR(256) = NULL,
				@RevisedPartId       BIGINT = NULL,
				@SerialNumber        VARCHAR(100) = NULL;

		SELECT @TearDown = [Id] FROM [dbo].[WorkOrderType] WITH (NOLOCK) WHERE [Description] = 'Internal Teardown';

		SELECT @ConditionSettlement = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH (NOLOCK) WHERE [WorkOrderSettlementName] = 'Final Cond/Cert'

		SELECT @ReleaseFormSettlement = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH (NOLOCK) WHERE [WorkOrderSettlementName] = 'Release Certs (e.g. 8130) Reviewed';

		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'WorkOrder'
		SELECT @WOMPNModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN'

		IF OBJECT_ID(N'tempdb..#tmprSettlementFinalConditionBulk') IS NOT NULL
		BEGIN
			DROP TABLE #tmprSettlementFinalConditionBulk
		END

		CREATE TABLE #tmprSettlementFinalConditionBulk
		(
			[ID] BIGINT NOT NULL IDENTITY, 
			[WorkOrderId]         BIGINT NULL,
            [WorkOrderPartNoId]   BIGINT NULL,
            [WorkFlowWorkOrderId] BIGINT NULL,
            [SubWorkOrderId]      BIGINT NULL,
            [SubWOPartNoId]       BIGINT NULL,
            [FinalConditionId]    BIGINT NULL,
            [IsSubWorkOrder]      BIT NULL,
            [UpdatedBy]           VARCHAR(256) NULL,
            [RevisedPartId]       BIGINT NULL,
            [SerialNumber]        VARCHAR(100) NULL
		)   

		INSERT INTO #tmprSettlementFinalConditionBulk ([WorkOrderId],[WorkOrderPartNoId],[WorkFlowWorkOrderId],[SubWorkOrderId],[SubWOPartNoId],[FinalConditionId],[IsSubWorkOrder],[UpdatedBy],[RevisedPartId],[SerialNumber])
		SELECT [WorkOrderId],[WorkOrderPartNoId],[WorkFlowWorkOrderId],[SubWorkOrderId],[SubWOPartNoId],[FinalConditionId],[IsSubWorkOrder],[UpdatedBy],[RevisedPartId],[SerialNumber]  FROM @WOSettlementList

		SELECT @TotalRecord = COUNT(*), @MinId = MIN([ID]) FROM #tmprSettlementFinalConditionBulk WITH (NOLOCK)

		BEGIN TRY
		BEGIN TRANSACTION

		WHILE @MinId <= @TotalRecord
		BEGIN	
			DECLARE @ConditionMemo    NVARCHAR(MAX);
			DECLARE @OldConditionId   BIGINT = 0;
			DECLARE @OldConditionName VARCHAR(50);
			DECLARE @WorkOrderTypeId  BIGINT = 0;

			SELECT  @WorkOrderId         = [WorkOrderId],
					@WorkOrderPartNoId   = [WorkOrderPartNoId],
					@WorkFlowWorkOrderId = [WorkFlowWorkOrderId],
					@SubWorkOrderId      = [SubWorkOrderId],
					@SubWOPartNoId       = [SubWOPartNoId],
					@FinalConditionId    = [FinalConditionId],
					@IsSubWorkOrder      = [IsSubWorkOrder],
					@UpdatedBy           = [UpdatedBy],
					@RevisedPartId       = [RevisedPartId],
					@SerialNumber        = [SerialNumber]		    
			FROM #tmprSettlementFinalConditionBulk WHERE [ID] = @MinId

			SELECT @ConditionMemo = [Memo] FROM [dbo].[Condition] WITH (NOLOCK) WHERE [ConditionId] = @FinalConditionId;

			SELECT @OldConditionId = [ConditionId] FROM [dbo].[WorkOrderPartNumber] WITH (NOLOCK) WHERE [ID] = @WorkOrderPartNoId;

			SELECT @OldConditionName = [Code] FROM [dbo].[Condition] WITH (NOLOCK) WHERE [ConditionId] = @OldConditionId;

			SELECT @WorkOrderTypeId = [WorkOrderTypeId] FROM [dbo].[WorkOrder] WITH (NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;						

			IF @IsSubWorkOrder = 1
			BEGIN
				 -------------------------------------------------------------------
				 -- Sub Work Order
				 -------------------------------------------------------------------
				 UPDATE [dbo].[SubWorkOrderSettlementDetails]
				 SET [WorkOrderId]           = @WorkOrderId,
					 [SubWOPartNoId]         = @SubWOPartNoId,
					 [SubWorkOrderId]        = @SubWorkOrderId,
					 [WorkOrderSettlementId] = @ConditionSettlement, -- Final_Cond_Cert
					 [ConditionId]           = @FinalConditionId,
					 [conditionName]         = @ConditionMemo,
					 [UpdatedDate]           = @UpdatedDate,
					 [IsMastervalue]         = 1,
					 [Isvalue_NA]            = 0,
					 [RevisedItemmasterid]   = @RevisedPartId,
					 [UpdatedBy]             = @UpdatedBy
				 WHERE [WorkOrderId]    = @WorkOrderId
				   AND [SubWorkOrderId] = @SubWorkOrderId
				   AND [SubWOPartNoId]  = @SubWOPartNoId
				   AND [WorkOrderSettlementId] = @ConditionSettlement;

				 IF EXISTS (SELECT 1 FROM [dbo].[SubWorkOrderPartNumber] WITH (NOLOCK) WHERE [SubWOPartNoId] = @SubWOPartNoId)
				 BEGIN
					 DECLARE @SubRevisedConditionId BIGINT, @SubRevisedItemmasterid BIGINT, @SubRevisedSerialNumber VARCHAR(100), @SubConditionId BIGINT;

					 SELECT @SubRevisedConditionId  = [RevisedConditionId],
							@SubRevisedItemmasterid = [RevisedItemmasterid],
							@SubRevisedSerialNumber = [RevisedSerialNumber],
							@SubConditionId         = [ConditionId]
					 FROM [dbo].[SubWorkOrderPartNumber] WITH (NOLOCK)
					 WHERE [SubWOPartNoId] = @SubWOPartNoId;

					 DECLARE @SubIsLocked BIT = (SELECT ISNULL([islocked],0) FROM [dbo].[SubWorkOrderPartNumber] WITH (NOLOCK) WHERE [SubWOPartNoId] = @SubWOPartNoId);

					 IF (ISNULL(@SubRevisedConditionId, -1) <> ISNULL(@FinalConditionId, -1))
						OR (ISNULL(@SubRevisedItemmasterid, -1) <> ISNULL(@RevisedPartId, -1))
						OR (ISNULL(@SubRevisedSerialNumber, '') <> ISNULL(@SerialNumber, ''))
					 BEGIN
						 SET @SubIsLocked = 0;

						 EXEC [dbo].[Update8130LockUnlockDetails]
							  @WorkorderId       = 0,
							  @WorkOrderPartNoId = 0,
							  @SubWorkOrderId    = @SubWorkOrderId,
							  @SubWOPartNoId     = @SubWOPartNoId,
							  @IsWorkOrder       = 0,
							  @SerialNumber      = @SerialNumber;
					 END

					 UPDATE [dbo].[SubWorkOrderPartNumber]
					 SET [RevisedConditionId]  = CASE WHEN @FinalConditionId = 0 THEN @SubConditionId ELSE @FinalConditionId END,
						 [UpdatedDate]         = @UpdatedDate,
						 [UpdatedBy]           = @UpdatedBy,
						 [RevisedItemmasterid] = @RevisedPartId,
						 [RevisedSerialNumber] = @SerialNumber,
						 [islocked]            = @SubIsLocked
					 WHERE [SubWOPartNoId] = @SubWOPartNoId;

					 IF (ISNULL(@SubIsLocked, 0) = 0)
					 BEGIN
						 IF @WorkOrderTypeId <> @TearDown 
						 BEGIN
							 UPDATE [dbo].[SubWorkOrderSettlementDetails]
							 SET [WorkOrderId]           = @WorkOrderId,
								 [SubWOPartNoId]         = @SubWOPartNoId,
								 [SubWorkOrderId]        = @SubWorkOrderId,
								 [WorkOrderSettlementId] = @ReleaseFormSettlement, -- Release_Certs_8130_Reviewed
								 [UpdatedDate]           = @UpdatedDate,
								 [IsMastervalue]         = 0,
								 [Isvalue_NA]            = 0,
								 [UpdatedBy]             = @UpdatedBy
							 WHERE [WorkOrderId]    = @WorkOrderId
							   AND [SubWorkOrderId] = @SubWorkOrderId
							   AND [SubWOPartNoId]  = @SubWOPartNoId
							   AND [WorkOrderSettlementId] = @ReleaseFormSettlement;
						 END
					 END
				 END
			END
			ELSE
			BEGIN
				
				 UPDATE [dbo].[WorkOrderSettlementDetails]
					SET [WorkOrderId]           = @WorkOrderId,
					    [workOrderPartNoId]     = @WorkOrderPartNoId,
						[WorkFlowWorkOrderId]   = @WorkFlowWorkOrderId,
						[WorkOrderSettlementId] = @ConditionSettlement, -- Final_Cond_Cert
						[ConditionId]           = @FinalConditionId,
						[conditionName]         = @ConditionMemo,
						[IsMastervalue]         = 1,
						[Isvalue_NA]            = 0,
						[UpdatedDate]           = @UpdatedDate,
						[RevisedPartId]         = @RevisedPartId,
						[UpdatedBy]             = @UpdatedBy
				  WHERE [WorkOrderId]         = @WorkOrderId
				    AND [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId
				    AND [workOrderPartNoId]   = @WorkOrderPartNoId
				    AND [WorkOrderSettlementId] = @ConditionSettlement;

				 IF EXISTS (SELECT 1 FROM [dbo].[WorkOrderPartNumber] WITH (NOLOCK) WHERE [ID] = @WorkOrderPartNoId)
				 BEGIN					
					DECLARE @WORevisedConditionId BIGINT, @WORevisedItemmasterid BIGINT, @WORevisedSerialNumber VARCHAR(100), @WOConditionId BIGINT;

					 SELECT @WORevisedConditionId  = [RevisedConditionId],
							@WORevisedItemmasterid = [RevisedItemmasterid],
							@WORevisedSerialNumber = [RevisedSerialNumber],
							@WOConditionId         = [ConditionId]
					 FROM [dbo].[WorkOrderPartNumber] WITH (NOLOCK)
					 WHERE [ID] = @WorkOrderPartNoId;

					 DECLARE @WOIsLocked BIT = (SELECT ISNULL([isLocked],0) FROM [dbo].[WorkOrderPartNumber] WITH (NOLOCK) WHERE [ID] = @WorkOrderPartNoId);

					 IF (ISNULL(@WORevisedConditionId, -1) <> ISNULL(@FinalConditionId, -1))
					 OR (ISNULL(@WORevisedItemmasterid, -1) <> ISNULL(@RevisedPartId, -1))
					 OR (ISNULL(@WORevisedSerialNumber, '') <> ISNULL(@SerialNumber, ''))
					 BEGIN
						SET @WOIsLocked = 0;

						EXEC [dbo].[Update8130LockUnlockDetails]
							 @WorkorderId       = @WorkOrderId,
							 @WorkOrderPartNoId = @WorkOrderPartNoId,
							 @SubWorkOrderId    = 0,
							 @SubWOPartNoId     = 0,
							 @IsWorkOrder       = 1,
							 @SerialNumber      = @SerialNumber;
					 END

  				     UPDATE [dbo].[WorkOrderPartNumber]
					   SET [RevisedConditionId]  = CASE WHEN @FinalConditionId = 0 THEN @WOConditionId ELSE @FinalConditionId END,
						   [UpdatedDate]         = @UpdatedDate,
						   [UpdatedBy]           = @UpdatedBy,
						   [RevisedItemmasterid] = @RevisedPartId,
					  	   [isLocked]            = @WOIsLocked
					 WHERE [ID] = @WorkOrderPartNoId;

					 IF (ISNULL(@WOIsLocked, 0) = 0)
					 BEGIN
						 IF @WorkOrderTypeId <> @TearDown -- TearDown
						 BEGIN
							 UPDATE [dbo].[WorkOrderSettlementDetails]
							 SET [WorkOrderId]           = @WorkOrderId,
								 [workOrderPartNoId]     = @WorkOrderPartNoId,
								 [WorkFlowWorkOrderId]   = @WorkFlowWorkOrderId,
								 [WorkOrderSettlementId] = @ReleaseFormSettlement, -- Release_Certs_8130_Reviewed
								 [UpdatedDate]           = @UpdatedDate,
								 [IsMastervalue]         = 0,
								 [Isvalue_NA]            = 0,
								 [UpdatedBy]             = @UpdatedBy
							 WHERE [WorkOrderId]         = @WorkOrderId
							   AND [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId
							   AND [workOrderPartNoId]   = @WorkOrderPartNoId
							   AND [WorkOrderSettlementId] = @ReleaseFormSettlement;
						 END
					 END
				 END

				 EXEC [dbo].[UpdateWorkOrderPartNumberRevisedColumnsWithId] @WorkOrderPartNumberId = @WorkOrderPartNoId, @SerialNumber = @SerialNumber;

				 EXEC [dbo].[USP_UpdateConditionById] @WOPartNoId = @WorkOrderPartNoId,@WOId = @WorkOrderId,@ConditionId = @FinalConditionId;

				 -------------------------------------------------------------------
				 -- History entry
				 -------------------------------------------------------------------
				 DECLARE @HistWorkOrderPartNoId  BIGINT,
						 @ItemMasterId            BIGINT,
						 @ExistingConditionId     BIGINT,
						 @RevisedConditionIdHist  BIGINT,
						 @OldConditionCode        VARCHAR(50),
						 @NewConditionCode        VARCHAR(50),
						 @OutgoingMPNPartNumber   VARCHAR(100),
						 @ExistingMPNPartNumber   VARCHAR(100),
						 @TemplateBody            NVARCHAR(MAX),
						 @ReplaceContent          NVARCHAR(MAX);

				SELECT @HistWorkOrderPartNoId = [WorkOrderPartNoId] FROM [dbo].[WorkOrderWorkFlow] WITH (NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId;

				SELECT @ItemMasterId        = [ItemMasterId],
					   @ExistingConditionId = [ConditionId],
					   @RevisedConditionIdHist = [RevisedConditionId]
				FROM [dbo].[WorkOrderPartNumber] WITH (NOLOCK)
				WHERE [ID] = @HistWorkOrderPartNoId;

				SELECT @OldConditionCode = [Code] FROM [dbo].[Condition] WITH (NOLOCK) WHERE [ConditionId] = @ExistingConditionId;
				SELECT @NewConditionCode = [Code] FROM [dbo].[Condition] WITH (NOLOCK) WHERE [ConditionId] = @RevisedConditionIdHist;

				SELECT @OutgoingMPNPartNumber = [PartNumber] FROM [dbo].[ItemMaster] WITH (NOLOCK) WHERE [ItemMasterId] = @RevisedPartId;
				SELECT @ExistingMPNPartNumber = [PartNumber] FROM [dbo].[ItemMaster] WITH (NOLOCK) WHERE [ItemMasterId] = @ItemMasterId;

				SELECT @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH (NOLOCK) WHERE [TemplateCode] = 'SettlementOutGoing';

				SET @ReplaceContent = REPLACE(@TemplateBody, '##MPN##', ISNULL(@ExistingMPNPartNumber, ''));
				SET @ReplaceContent = REPLACE(@ReplaceContent, '##ExistingMPN##', ISNULL(@ExistingMPNPartNumber, ''));
				SET @ReplaceContent = REPLACE(@ReplaceContent, '##OutgoingMPN##', ISNULL(@OutgoingMPNPartNumber, ''));
				SET @ReplaceContent = REPLACE(@ReplaceContent, '##OldValue##', ISNULL(@OldConditionName, ''));
				SET @ReplaceContent = REPLACE(@ReplaceContent, '##NewValue##', ISNULL(@NewConditionCode, ''));
				
				EXEC [dbo].[USP_History]
					 @ModuleId        = @WOModuleId,         -- WorkOrder
					 @RefferenceId    = @WorkOrderId,
					 @SubModuleId     = @WOMPNModuleId,      --  WorkOrderMPN
					 @SubRefferenceId = @HistWorkOrderPartNoId,
					 @OldValue        = 'False',
					 @NewValue        = 'True',
					 @HistoryText     = @ReplaceContent,
					 @StatusCode      = 'SettlementOutGoing',
					 @MasterCompanyId = 0,
					 @CreatedBy       = @UpdatedBy,
					 @CreatedDate     = @UpdatedDate,
					 @UpdatedBy       = @UpdatedBy,
					 @UpdatedDate     = @UpdatedDate;
			END

			SET @MinId = @MinId + 1

		END

	COMMIT TRANSACTION;
	END TRY    
    BEGIN CATCH      
		IF @@trancount > 0			
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_SaveSettlementFinalConditionBulk' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, 0) AS VARCHAR(100))
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