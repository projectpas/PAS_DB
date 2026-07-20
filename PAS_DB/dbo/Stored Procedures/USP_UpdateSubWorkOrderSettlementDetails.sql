/*************************************************************           
 ** File:  [USP_UpdateWorkOrderSettlementDetails]
 ** Author:   Moin Bloch 
 ** Description: Update settlement-detail For each row
 ** Date:   17/07/2026
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    20/07/2026   Moin Bloch 	    Created - converted from C# repository method
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_UpdateSubWorkOrderSettlementDetails]
@SettlementDetails  [dbo].[SubWorkOrderSettlementDetailType] READONLY,
@IsWOClose BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

		DECLARE @Final_Cond_Cert_SettlementId BIGINT;  
		SELECT @Final_Cond_Cert_SettlementId = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE [WorkOrderSettlementName] = 'Final Cond/Cert';

		DECLARE @TotalRecord INT = 0;
		DECLARE @MinId BIGINT = 1;
		DECLARE @UpdatedDate DATETIME2(7) = GETUTCDATE(),@UpdatedBy VARCHAR(256)='',@MasterCompanyId INT = 0,@UpdatedById BIGINT

		IF OBJECT_ID(N'tempdb..#tmprSubWOSettlementFinalConditionBulk') IS NOT NULL
		BEGIN
			DROP TABLE #tmprSubWOSettlementFinalConditionBulk
		END

		CREATE TABLE #tmprSubWOSettlementFinalConditionBulk
		(
			[ID] BIGINT NOT NULL IDENTITY, 
			[SubWorkOrderSettlementDetailId]   BIGINT          NULL,
			[WorkOrderId]                      BIGINT          NULL,
			[WorkOrderSettlementId]            BIGINT          NULL,
			[SubWorkOrderId]                   BIGINT          NULL,
			[SubWOPartNoId]                    BIGINT          NULL,
			[IsMastervalue]                    BIT             NULL,
			[Isvalue_NA]                       BIT             NULL,
			[Memo]                             NVARCHAR(MAX)   NULL,
			[ConditionId]                      BIGINT          NULL,
			[UserId]                           BIGINT          NULL,
			[UserName]                         NVARCHAR(200)   NULL,
			[conditionName]                    NVARCHAR(200)   NULL,
			[RevisedItemmasterid]              BIGINT          NULL,
			[UpdatedBy]                        NVARCHAR(100)   NULL,   
			[UpdatedById]                      BIGINT          NULL 
		)
		
		INSERT INTO #tmprSubWOSettlementFinalConditionBulk([SubWorkOrderSettlementDetailId],[WorkOrderId],[WorkOrderSettlementId],[SubWorkOrderId],[SubWOPartNoId],[IsMastervalue],[Isvalue_NA],[Memo],
			[ConditionId],[UserId],[UserName],[conditionName],[RevisedItemmasterid],[UpdatedBy],[UpdatedById])
		SELECT [SubWorkOrderSettlementDetailId],[WorkOrderId],[WorkOrderSettlementId],[SubWorkOrderId],[SubWOPartNoId],[IsMastervalue],[Isvalue_NA],[Memo],
			[ConditionId],[UserId],[UserName],[conditionName],[RevisedItemmasterid],[UpdatedBy],[UpdatedById]
		FROM @SettlementDetails;

		SELECT @TotalRecord = COUNT(*), @MinId = MIN([ID]) FROM #tmprSubWOSettlementFinalConditionBulk

    BEGIN TRY
        BEGIN TRANSACTION;
		
		WHILE @MinId <= @TotalRecord
		BEGIN
			DECLARE @SubWorkOrderSettlementDetailId BIGINT,@WorkOrderId BIGINT,@SubWorkOrderId BIGINT,@SubWOPartNoId BIGINT,
					@WorkOrderSettlementId BIGINT,@IsMastervalue BIT, @IsvalueNA BIT,@ItemIsMastervalue BIT,@ItemIsvalue_NA BIT,
					@ItemMemo NVARCHAR(MAX), @ItemUserId BIGINT,@ItemUserName VARCHAR(500);
			
			SELECT @SubWorkOrderSettlementDetailId = [SubWorkOrderSettlementDetailId], 
			       @WorkOrderId = [WorkOrderId], 
				   @SubWorkOrderId = [SubWorkOrderId],
				   @WorkOrderSettlementId = [WorkOrderSettlementId],
				   @IsMastervalue = ISNULL([IsMastervalue],0),
				   @IsvalueNA = ISNULL([Isvalue_NA],0),				   
				   @ItemUserId = [UserId], 				   
				   @ItemUserName = [UserName], 
				   @UpdatedBy = [UpdatedBy],		
				   @UpdatedById = [UpdatedById]
			FROM #tmprSubWOSettlementFinalConditionBulk WHERE [ID] = @MinId;

			SELECT @ItemIsMastervalue = ISNULL([IsMastervalue],0), @ItemIsvalue_NA = ISNULL([Isvalue_NA],0) FROM [dbo].[SubWorkOrderSettlementDetails] WITH (NOLOCK) WHERE [SubWorkOrderSettlementDetailId] = @SubWorkOrderSettlementDetailId

			IF(@SubWorkOrderSettlementDetailId > 0 AND (ISNULL(@IsMastervalue, 0) <> ISNULL(@ItemIsMastervalue, 0)  OR ISNULL(@IsvalueNA, 0) <> ISNULL(@ItemIsvalue_NA, 0)))
			BEGIN
				IF (@WorkOrderSettlementId = @Final_Cond_Cert_SettlementId AND @IsMastervalue <> 1)
				BEGIN					
					UPDATE [dbo].[SubWorkOrderSettlementDetails]
					   SET [IsMastervalue] = @IsMastervalue
						  ,[Isvalue_NA] = @IsvalueNA
						  ,[ConditionId] = NULL
						  ,[conditionName] = ''
						  ,[UpdatedBy] = @UpdatedBy		
						  ,[UpdatedDate] = @UpdatedDate  				  
						  ,[UserId] = @ItemUserId
						  ,[UserName] = @ItemUserName
						  ,[sattlement_DateTime] = @UpdatedDate
					 WHERE [SubWorkOrderSettlementDetailId] = @SubWorkOrderSettlementDetailId
				END
				ELSE 
				BEGIN
					UPDATE [dbo].[SubWorkOrderSettlementDetails]
					   SET [IsMastervalue] = @IsMastervalue
						  ,[Isvalue_NA] = @IsvalueNA
						  ,[UpdatedBy] = @UpdatedBy		
						  ,[UpdatedDate] = @UpdatedDate  				  
						  ,[UserId] = @ItemUserId
						  ,[UserName] = @ItemUserName
						  ,[sattlement_DateTime] = @UpdatedDate
					 WHERE [SubWorkOrderSettlementDetailId] = @SubWorkOrderSettlementDetailId
				END
			END		

			SET @MinId = @MinId + 1;
		END

        IF (@IsWOClose = 1)
        BEGIN
			IF OBJECT_ID(N'tempdb..#tmpSubWOClosedSettlementUpdate') IS NOT NULL
				DROP TABLE #tmpSubWOClosedSettlementUpdate;

			CREATE TABLE #tmpSubWOClosedSettlementUpdate
			(
				[ID] BIGINT NOT NULL IDENTITY,			
				[WorkOrderId]                 BIGINT NULL,								
				[SubWOPartNoId]               BIGINT NULL,
                [SubWorkOrderId]              BIGINT NULL
			);

			DECLARE @ClosedWorkOrderStageId BIGINT;
			DECLARE @ClosedWorkOrderStatusId BIGINT;

			SET @TotalRecord = 0;
			SET @MinId = 1;

			INSERT INTO #tmpSubWOClosedSettlementUpdate([WorkOrderId],[SubWOPartNoId],[SubWorkOrderId])
			SELECT DISTINCT [WorkOrderId],[SubWOPartNoId],[SubWorkOrderId] FROM @SettlementDetails;

			SELECT @TotalRecord = COUNT(*), @MinId = MIN([ID]) FROM #tmpSubWOClosedSettlementUpdate
						
			WHILE @MinId <= @TotalRecord
			BEGIN
				DECLARE @WorkOrderStageId BIGINT,@WorkOrderStatusId BIGINT,@StockLineId BIGINT,@IsWOClosed BIT = 0,@WorkOrderMaterialsId BIGINT

				SELECT @WorkOrderId = [WorkOrderId], 
					   @SubWOPartNoId = [SubWOPartNoId],
					   @SubWorkOrderId = [SubWorkOrderId]					  		   
				FROM #tmpSubWOClosedSettlementUpdate WHERE [ID] = @MinId;

				SELECT @MasterCompanyId = [MasterCompanyId] FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;

				SELECT @WorkOrderStageId = [WorkOrderStageId] FROM [dbo].[WorkOrderStage] WITH(NOLOCK) WHERE [StageCode] = 'WORKORDERCLOSED' AND [MasterCompanyId] = @MasterCompanyId;

				SELECT @WorkOrderStatusId = [Id] FROM [dbo].[WorkOrderStatus] WITH(NOLOCK) WHERE [StatusCode] = 'CLOSED';

				 -- CLOSE THE SUB WORK ORDER PART NUMBER
				UPDATE [dbo].[SubWorkOrderPartNumber]
				SET [UpdatedDate]           = @UpdatedDate,
					[UpdatedBy]             = @UpdatedBy,
					[IsClosed]              = 1,
					[IsFinishGood]          = 1,
					[SubWorkOrderStageId]   = CASE WHEN ISNULL(@WorkOrderStageId,0) > 0 THEN @WorkOrderStageId ELSE [SubWorkOrderStageId] END,
					[SubWorkOrderStatusId]  = CASE WHEN ISNULL(@WorkOrderStatusId,0) > 0 THEN @WorkOrderStatusId ELSE [SubWorkOrderStatusId] END
				WHERE [SubWOPartNoId] = @SubWOPartNoId;

				-- PULL THE STOCKLINEID FOR THIS PART (POST-UPDATE, SAME AS C# RE-QUERY)
				SELECT TOP 1 @StockLineId = [StockLineId]
				FROM [dbo].[SubWorkOrderPartNumber] WITH (NOLOCK)
				WHERE [SubWOPartNoId] = @SubWOPartNoId;

				-- UPDATE STOCKLINE INVENTORY LINKAGE (QTY UPDATES LEFT COMMENTED, SAME AS SOURCE)
				IF (@StockLineId IS NOT NULL)
				BEGIN
					UPDATE [dbo].[StockLine]
					  SET  [WorkOrderId]    = @WorkOrderId,
						   [SubWorkOrderId] = @SubWorkOrderId,
						   [SubWOPartNoId]  = @SubWOPartNoId,
						   [UpdatedDate]    = @UpdatedDate,
						   [UpdatedBy]      = @UpdatedBy						
					 WHERE [StockLineId] = @StockLineId;
				END

				-- DETERMINE IF ANY SIBLING PART UNDER THIS WO/SUBWO IS STILL OPEN
				IF EXISTS (SELECT 1 FROM [dbo].[SubWorkOrderPartNumber] WITH (NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND [SubWorkOrderId] = @SubWorkOrderId AND ISNULL([IsClosed], 0) = 0)
				BEGIN
					SET @IsWOClosed = 1;
				END
				
				IF (@IsWOClosed = 0)
				BEGIN
					UPDATE [dbo].[SubWorkOrder]
					   SET [UpdatedDate]          = @UpdatedDate,
						   [UpdatedBy]            = @UpdatedBy,
						   [SubWorkOrderStatusId] = @WorkOrderStatusId
					 WHERE [SubWorkOrderId] = @SubWorkOrderId;	

					 SELECT @WorkOrderMaterialsId = [WorkOrderMaterialsId],@StockLineId = [StockLineId] FROM [dbo].[SubWorkOrder] WITH(NOLOCK) WHERE [SubWorkOrderId] = @SubWorkOrderId;

					EXEC [dbo].[USP_CloseSubWorkOrder]
						 @WorkOrderId          = @WorkOrderId,
						 @SubWorkOrderId       = @SubWorkOrderId,
						 @WorkOrderMaterialsId = @WorkOrderMaterialsId,
						 @StocklineId          = @StockLineId,
						 @UpdatedById          = @UpdatedById;
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
			, @AdhocComments VARCHAR(150) = 'USP_UpdateSubWorkOrderSettlementDetails'
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