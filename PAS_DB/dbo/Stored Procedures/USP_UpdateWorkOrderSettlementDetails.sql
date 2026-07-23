/*************************************************************           
 ** File:  [USP_UpdateWorkOrderSettlementDetails]
 ** Author:   Moin Bloch 
 ** Description: Update settlement-detail For each row
 ** Date:   15/07/2026
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    15/07/2026   Moin Bloch 	    Created - converted from C# repository method
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateWorkOrderSettlementDetails]
(
	@WorkOrderSettlementDetailsList [dbo].[WorkOrderSettlementDetailsUpdateType] READONLY,
	@IsWOClose BIT = 0
)
AS
BEGIN
	SET NOCOUNT ON;

		DECLARE @TotalRecord INT = 0;
		DECLARE @MinId BIGINT = 1;
		DECLARE @UpdatedDate Datetime2(7) = GETUTCDATE(),@UpdatedBy VARCHAR(256)='',@MasterCompanyId INT = 0;
		DECLARE @MaterialSettlement INT,@LaborSettlement INT,@FinalCondCertSettlementId INT;
		
		SELECT @MaterialSettlement = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH (NOLOCK) WHERE [WorkOrderSettlementName] = 'Material Required is Issued';

		SELECT @LaborSettlement = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH (NOLOCK) WHERE [WorkOrderSettlementName] = 'Labor Entries Confirmed';
		
		SELECT @FinalCondCertSettlementId = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE [WorkOrderSettlementName] = 'Final Cond/Cert';

		DECLARE @WOModuleId INT, @WOMPNModuleId INT;
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @WOMPNModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN';

		IF OBJECT_ID(N'tempdb..#tmpWOSettlementUpdate') IS NOT NULL
			DROP TABLE #tmpWOSettlementUpdate;		

		CREATE TABLE #tmpWOSettlementUpdate
		(
			[ID] BIGINT NOT NULL IDENTITY,
			[WorkOrderSettlementDetailId] BIGINT NULL,
			[WorkOrderId]                 BIGINT NULL,
			[WorkFlowWorkOrderId]         BIGINT NULL,
			[workOrderPartNoId]           BIGINT NULL,
			[WorkOrderSettlementId]       INT NULL,
			[WorkOrderSettlementName]     VARCHAR(500) NULL,
			[IsMastervalue]               BIT NULL,
			[Isvalue_NA]                  BIT NULL,
			[Memo]                        NVARCHAR(MAX) NULL,
			[ConditionId]                 BIGINT NULL,
			[UserId]                      BIGINT NULL,
			[conditionName]               VARCHAR(200) NULL,
			[UserName]                    VARCHAR(500) NULL,
			[sattlement_DateTime]         DATETIME NULL,
			[MasterCompanyId]             INT NULL,
			[CreatedBy]                   VARCHAR(256) NULL,
			[UpdatedBy]                   VARCHAR(256) NULL,
			[CreatedDate]                 DATETIME NULL,
			[UpdatedDate]                 DATETIME NULL,
			[IsActive]                    BIT NULL,
			[IsDeleted]                   BIT NULL,
			[RevisedPartId]               BIGINT NULL
		);
		
		INSERT INTO #tmpWOSettlementUpdate
			([WorkOrderSettlementDetailId],[WorkOrderId],[WorkFlowWorkOrderId],[workOrderPartNoId],[WorkOrderSettlementId],
			 [WorkOrderSettlementName],[IsMastervalue],[Isvalue_NA],[Memo],[ConditionId],[UserId],[conditionName],[UserName],
			 [sattlement_DateTime],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[RevisedPartId])
		SELECT [WorkOrderSettlementDetailId],[WorkOrderId],[WorkFlowWorkOrderId],[workOrderPartNoId],[WorkOrderSettlementId],
			   [WorkOrderSettlementName],[IsMastervalue],[Isvalue_NA],[Memo],[ConditionId],[UserId],[conditionName],[UserName],
			   [sattlement_DateTime],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[RevisedPartId]
		FROM @WorkOrderSettlementDetailsList;

		SELECT @TotalRecord = COUNT(*), @MinId = MIN([ID]) FROM #tmpWOSettlementUpdate

	BEGIN TRY
	BEGIN TRANSACTION

		WHILE @MinId <= @TotalRecord
		BEGIN
			DECLARE @WorkOrderSettlementDetailId BIGINT, @WorkOrderId BIGINT, @WorkFlowWorkOrderId BIGINT, @WorkOrderPartNoId BIGINT,
					@WorkOrderSettlementId BIGINT, @WorkOrderSettlementName VARCHAR(500), @IsMastervalue BIT, @IsvalueNA BIT,
					@ItemMemo NVARCHAR(MAX), @ItemConditionId BIGINT, @ItemUserId BIGINT, @ItemConditionName VARCHAR(200),
					@ItemUserName VARCHAR(500), @ItemSattlementDateTime DATETIME,@ItemRevisedPartId BIGINT,@ItemMasterId BIGINT, @PartNumber VARCHAR(100);

			SELECT @WorkOrderSettlementDetailId = [WorkOrderSettlementDetailId], @WorkOrderId = [WorkOrderId], @WorkFlowWorkOrderId = [WorkFlowWorkOrderId],
				   @WorkOrderPartNoId = [workOrderPartNoId], @WorkOrderSettlementId = [WorkOrderSettlementId],
				   @IsMastervalue = ISNULL([IsMastervalue],0),@IsvalueNA = ISNULL([Isvalue_NA],0), @ItemMemo = [Memo], @ItemConditionId = [ConditionId],
				   @ItemUserId = [UserId], @ItemConditionName = [conditionName], @ItemUserName = [UserName], @ItemSattlementDateTime = [sattlement_DateTime],
				   @MasterCompanyId = [MasterCompanyId], @UpdatedBy = [UpdatedBy],
				   @ItemRevisedPartId = [RevisedPartId]
			FROM #tmpWOSettlementUpdate WITH (NOLOCK)
			WHERE [ID] = @MinId;
						
			SELECT @ItemMasterId = [ItemMasterId] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WorkOrderPartNoId;
			SELECT @PartNumber = [PartNumber] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId;
			SELECT @WorkOrderSettlementName = [WorkOrderSettlementName] FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE [WorkOrderSettlementId] = @WorkOrderSettlementId;
			
			IF(@WorkOrderSettlementDetailId > 0 AND (@WorkOrderSettlementId <> @MaterialSettlement OR @WorkOrderSettlementId <> @LaborSettlement))
			BEGIN
				DECLARE @OldIsMastervalue BIT, @OldIsvalueNA BIT, @OldMemo NVARCHAR(MAX);
				DECLARE @FoundExisting INT = 0;

				SELECT @OldIsMastervalue = ISNULL([IsMastervalue],0), @OldIsvalueNA = ISNULL([Isvalue_NA],0), @OldMemo = [Memo], @FoundExisting = 1
				FROM [dbo].[WorkOrderSettlementDetails] WITH (NOLOCK)
				WHERE [WorkOrderSettlementDetailId] = @WorkOrderSettlementDetailId;
							
				IF (@OldIsMastervalue <> @IsMastervalue OR @OldIsvalueNA <> @IsvalueNA)	
				BEGIN
					-------------------------------------------------------------------
					-- History entry
					-------------------------------------------------------------------
					DECLARE @TemplateCode VARCHAR(50) = CASE WHEN ISNULL(@IsvalueNA,0) = 1 THEN 'SettlementNA' ELSE 'Settlement' END;
					DECLARE @TemplateBody NVARCHAR(MAX);
					SELECT @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH (NOLOCK) WHERE [TemplateCode] = @TemplateCode;

					DECLARE @OldValueText VARCHAR(10) = CASE WHEN ISNULL(@OldIsMastervalue,0) = 1 THEN 'True' ELSE 'False' END;
					DECLARE @NewValueText VARCHAR(10) = CASE WHEN ISNULL(@IsMastervalue,0) = 1 THEN 'True' ELSE 'False' END;

					DECLARE @ReplaceContent NVARCHAR(MAX) = @TemplateBody;
					SET @ReplaceContent = REPLACE(@ReplaceContent, '##MPN##', ISNULL(@PartNumber, ''));
					SET @ReplaceContent = REPLACE(@ReplaceContent, '##ItemName##', ISNULL(@WorkOrderSettlementName, ''));
					IF (ISNULL(@IsvalueNA,0) = 0)
					BEGIN
						SET @ReplaceContent = REPLACE(@ReplaceContent, '##OldValue##', @OldValueText);
						SET @ReplaceContent = REPLACE(@ReplaceContent, '##NewValue##', @NewValueText);
					END
					SET @ReplaceContent = REPLACE(@ReplaceContent, '##UserName##', ISNULL(@ItemUserName, ''));
					
					SET @ReplaceContent = REPLACE(@ReplaceContent, '##sattlementDateTime##', ISNULL(CONVERT(VARCHAR(30), @ItemSattlementDateTime, 100), ''));
										
					EXEC [dbo].[USP_History]
						@ModuleId        = @WOModuleId,
						@RefferenceId    = @WorkOrderId,
						@SubModuleId     = @WOMPNModuleId,
						@SubRefferenceId = @WorkOrderPartNoId,
						@OldValue        = @OldValueText,
						@NewValue        = @NewValueText,
						@HistoryText     = @ReplaceContent,
						@StatusCode      = 'Settlement',
						@MasterCompanyId = @MasterCompanyId,
						@CreatedBy       = @UpdatedBy,
						@CreatedDate     = @UpdatedDate,
						@UpdatedBy       = @UpdatedBy,
						@UpdatedDate     = @UpdatedDate
										
					DECLARE @FinalConditionIdOut BIGINT = @ItemConditionId;
					DECLARE @FinalConditionNameOut VARCHAR(200) = @ItemConditionName;

					IF (@WorkOrderSettlementId = @FinalCondCertSettlementId AND @IsMastervalue <> 1)
					BEGIN
						SET @FinalConditionIdOut = NULL;
						SET @FinalConditionNameOut = '';
						
						UPDATE [dbo].[WorkOrderSettlementDetails]
							SET [IsMastervalue]         = @IsMastervalue,
								[Isvalue_NA]            = @IsvalueNA,
								[Memo]                  = @ItemMemo,
								[ConditionId]           = @FinalConditionIdOut,
								[UserId]                = @ItemUserId,
								[conditionName]         = @FinalConditionNameOut,
								[UserName]              = @ItemUserName,
								[sattlement_DateTime]   = @UpdatedDate,						
								[UpdatedBy]             = @UpdatedBy,						
								[UpdatedDate]           = @UpdatedDate													
						  WHERE [WorkOrderSettlementDetailId] = @WorkOrderSettlementDetailId;
					END
					ELSE 
					BEGIN
						 UPDATE [dbo].[WorkOrderSettlementDetails]
							SET [IsMastervalue]         = @IsMastervalue,
								[Isvalue_NA]            = @IsvalueNA,
								[Memo]                  = @ItemMemo,							
								[UserId]                = @ItemUserId,							
								[UserName]              = @ItemUserName,
								[sattlement_DateTime]   = @UpdatedDate,						
								[UpdatedBy]             = @UpdatedBy,						
								[UpdatedDate]           = @UpdatedDate													
						  WHERE [WorkOrderSettlementDetailId] = @WorkOrderSettlementDetailId;
					END
				END				
			END
			
			SET @MinId = @MinId + 1;
		END
		
		-- WO CLOSE
		IF (@IsWOClose = 1)
		BEGIN
			DECLARE @ClosedWorkOrderStageId BIGINT;
			DECLARE @ClosedWorkOrderStatusId BIGINT;
			
			SELECT @ClosedWorkOrderStageId = [WorkOrderStageId] FROM [dbo].[WorkOrderStage] WITH (NOLOCK) WHERE [StageCode] = 'WORKORDERCLOSED' AND [MasterCompanyId] = @MasterCompanyId;

			SELECT @ClosedWorkOrderStatusId = [Id] FROM [dbo].[WorkOrderStatus] WITH (NOLOCK) WHERE [StatusCode] = 'CLOSED';
			
			IF OBJECT_ID(N'tempdb..#tmpWOClosedSettlementUpdate') IS NOT NULL
				DROP TABLE #tmpWOClosedSettlementUpdate;

			CREATE TABLE #tmpWOClosedSettlementUpdate
			(
				[ID] BIGINT NOT NULL IDENTITY,			
				[WorkOrderId]                 BIGINT NULL,			
				[workOrderPartNoId]           BIGINT NULL			
			);			

			SET @TotalRecord = 0;
			SET @MinId = 1;

			INSERT INTO #tmpWOClosedSettlementUpdate([WorkOrderId],[workOrderPartNoId])
			SELECT DISTINCT [WorkOrderId],[workOrderPartNoId]FROM @WorkOrderSettlementDetailsList;

			SELECT @TotalRecord = COUNT(*), @MinId = MIN([ID]) FROM #tmpWOClosedSettlementUpdate
						
			WHILE @MinId <= @TotalRecord
			BEGIN	
				SELECT @WorkOrderId = [WorkOrderId],
				       @WorkOrderPartNoId = [workOrderPartNoId] 
				 FROM #tmpWOClosedSettlementUpdate WHERE [ID] = @MinId;													
				

				DECLARE @OldStageCode VARCHAR(50), @OldStageName VARCHAR(200);
				DECLARE @NewStageCode VARCHAR(50), @NewStageName VARCHAR(200);

				IF (@WorkOrderPartNoId > 0)
				BEGIN
					DECLARE @CurrentPartStageId BIGINT;
					SELECT @CurrentPartStageId = [WorkOrderStageId] FROM [dbo].[WorkOrderPartNumber] WITH (NOLOCK) WHERE [ID] = @WorkOrderPartNoId;

					SELECT @OldStageCode = [Code], @OldStageName = [Stage] FROM [dbo].[WorkOrderStage] WITH (NOLOCK) WHERE [WorkOrderStageId] = @CurrentPartStageId;

					SELECT TOP 1 @NewStageCode = [Code], @NewStageName = [Stage] FROM [dbo].[WorkOrderStage] WITH (NOLOCK) WHERE [StageCode] = 'WORKORDERCLOSED';
				END
						
				UPDATE [dbo].[WorkOrderPartNumber]
				   SET [UpdatedDate]       = @UpdatedDate,
					   [UpdatedBy]         = @UpdatedBy,
					   [IsClosed]          = 1,
					   [closeddate]        = @UpdatedDate,
					   [WorkOrderStageId]  = @ClosedWorkOrderStageId,
					   [WorkOrderStatusId] = @ClosedWorkOrderStatusId,
					   [IsFinishGood]      = 1
				 WHERE [ID] = @WorkOrderPartNoId;

				-- UPDATE WORK ORDER TURN ARROUND TIME
				EXEC [dbo].[USP_AddEdit_WorkOrderTurnArroundTime] @WorkOrderPartNoId = @WorkOrderPartNoId, @CurrentStageId = @ClosedWorkOrderStageId, @CreatedBy = @UpdatedBy;

				-- UPDATE WORK ORDER PART NUMBER COLUMNS
				EXEC [dbo].[UpdateWorkOrderPartNumberColumnsWithId] @WorkOrderPartNumberId = @WorkOrderPartNoId;
							
				DECLARE @IsWOClosed BIT = 0;
				IF EXISTS (SELECT 1 FROM [dbo].[WorkOrderPartNumber] WITH (NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND ISNULL([IsClosed],0) = 0)
				BEGIN
					SET @IsWOClosed = 1;
				END

				IF (@IsWOClosed = 0)
				BEGIN
					UPDATE [dbo].[WorkOrder] SET [UpdatedDate] = @UpdatedDate,[UpdatedBy] = @UpdatedBy,[WorkOrderStatusId] = @ClosedWorkOrderStatusId WHERE [WorkOrderId] = @WorkOrderId;

					-- UPDATE WORK ORDER MPN STOCKLINE QTY FOR SHIPPING
					EXEC [dbo].[USP_UpdateWorkOrderMPNStocklineQtyForShipping] @WorkOrderPartNoId = @WorkOrderPartNoId,@WorkorderId = @WorkOrderId;

					-------------------------------------------------------------------
					-- HISTORY ENTRY ("CLOSEWO")
					-------------------------------------------------------------------
					DECLARE @CloseWorkOrderNum VARCHAR(100);
					DECLARE @CloseItemMasterId BIGINT;
					DECLARE @CloseMPNPartNumber VARCHAR(100);
					DECLARE @CloseTemplateBody NVARCHAR(MAX);
					DECLARE @CloseReplaceContent NVARCHAR(MAX);
					
					SELECT @CloseWorkOrderNum = [WorkOrderNum] FROM [dbo].[WorkOrder] WITH (NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
					SELECT @CloseItemMasterId = [ItemMasterId] FROM [dbo].[WorkOrderPartNumber] WITH (NOLOCK) WHERE [ID] = @WorkOrderPartNoId;
					SELECT @CloseMPNPartNumber = [PartNumber] FROM [dbo].[ItemMaster] WITH (NOLOCK) WHERE [ItemMasterId] = @CloseItemMasterId;
					SELECT @CloseTemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH (NOLOCK) WHERE [TemplateCode] = 'CloseWO';
					
					SET @CloseReplaceContent = REPLACE(@CloseTemplateBody, '##WoNum##', ISNULL(@CloseWorkOrderNum, ''));
					SET @CloseReplaceContent = REPLACE(@CloseReplaceContent, '##WoMPN##', ISNULL(@CloseMPNPartNumber, ''));

					DECLARE @OldStage  VARCHAR(250)
					DECLARE @NewStage  VARCHAR(250)

					SET @OldStage = CONCAT(ISNULL(@OldStageCode,''), '-', ISNULL(@OldStageName,''))
					SET @NewStage = CONCAT(ISNULL(@NewStageCode,''), '-', ISNULL(@NewStageName,''))
								
					EXEC [dbo].[USP_History]
						@ModuleId        = @WOModuleId,
						@RefferenceId    = @WorkOrderId,
						@SubModuleId     = @WOMPNModuleId,
						@SubRefferenceId = @WorkOrderPartNoId,			
						@OldValue        = @OldStage,
						@NewValue        = @NewStage,
						@HistoryText     = @CloseReplaceContent,
						@StatusCode      = 'CloseWO',
						@MasterCompanyId = @MasterCompanyId,
						@CreatedBy       = @UpdatedBy,
						@CreatedDate     = @UpdatedDate,
						@UpdatedBy       = @UpdatedBy,
						@UpdatedDate     = @UpdatedDate;
				END

				SET @MinId = @MinId + 1;			
			END
		END

	COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0)
			ROLLBACK TRANSACTION;

		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_UpdateWorkOrderSettlementDetails'
			, @ProcedureParameters VARCHAR(3000) = '@IsWOClose = ''' + CAST(ISNULL(@IsWOClose,0) AS VARCHAR(10)) + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			@DatabaseName = @DatabaseName,
			@AdhocComments = @AdhocComments,
			@ProcedureParameters = @ProcedureParameters,
			@ApplicationName = @ApplicationName,
			@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END