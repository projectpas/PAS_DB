/*************************************************************           
 ** File: [InsertSubWorkOrderPartNumber]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to insert SubWorkOrderPart
 ** Purpose:         
 ** Date:   13/06/2025    
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    13/06/2025   Amit Ghediya		Created
    2    03/07/2025   Vishal Suthar     WorkFlowId was missing in the update section for Template
     
-- EXEC [InsertSubWorkOrderPartNumber] 
************************************************************************/

CREATE   PROCEDURE [dbo].[InsertSubWorkOrderPartNumber]
	@SubWorkOrderParts SubWorkOrderPartNumberType READONLY
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @TravelerName VARCHAR(250) = '',
				@ClosedStatusId INT = 2,
				@MasterLoopID INT,
				@SubWorkOrderScopeId BIGINT,
				@ItemMasterId BIGINT,
				@SubWOPartNoId BIGINT,
				@TraverIdString VARCHAR(150),
				@CurrentNo INT = 0,
				@CurrentNumber INT,
				@traverlerNumber VARCHAR(150),
				@CodePrefix NVARCHAR(50),
				@CodeSuffix NVARCHAR(50),
				@MasterCompanyId INT,
				@TravelerCodePrefix INT,
				@WorkOrderId BIGINT,
				@WorkOrderMaterialsId BIGINT,
				@Quantity INT,
				@UpdatedById BIGINT,
				@StockLineId BIGINT,
				@SubWorkOrderId BIGINT,
				@CreatedBy NVARCHAR(100),
				@TechStationId BIGINT;


		-- Code Types Of CodePrefix	
		SELECT @TravelerCodePrefix = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='TravelerId';	

		IF OBJECT_ID(N'tempdb..#tmpSubWorkOrderParts') IS NOT NULL
		BEGIN
			DROP TABLE #tmpSubWorkOrderParts
		END
		
		CREATE TABLE #tmpSubWorkOrderParts
		(
			[ID] [bigint] IDENTITY,
			[SubWOPartNoId] [bigint] NULL,
			[WorkOrderId] [bigint] NULL,
			[SubWorkOrderId] [bigint] NULL,
			[ItemMasterId] [bigint] NULL,
			[SubWorkOrderScopeId] [bigint] NULL,
			[EstimatedShipDate] [datetime2](7) NULL,
			[CustomerRequestDate] [datetime2](7) NULL,
			[PromisedDate] [datetime2](7) NULL,
			[EstimatedCompletionDate] [datetime2](7) NULL,
			[NTE] [varchar](30) NULL,
			[Quantity] [int] NULL,
			[StockLineId] [bigint] NULL,
			[CMMIds] [varchar](256) NULL,
			[WorkflowId] [bigint] NULL,
			[SubWorkOrderStageId] [bigint] NULL,
			[SubWorkOrderStatusId] [bigint] NULL,
			[SubWorkOrderPriorityId] [bigint] NULL,
			[IsPMA] [bit] NULL,
			[IsDER] [bit] NULL,
			[TechStationId] [bigint] NULL,
			[TATDaysStandard] [int] NULL,
			[TechnicianId] [bigint] NULL,
			[ConditionId] [bigint] NULL,
			[RevisedItemmasterid] [bigint] NULL,
			[TATDaysCurrent] [int] NULL,
			[IsTraveler] [bit] NULL,
			[IsManualForm] [bit] NULL,
			[WorkOrderMaterialsId] [bigint] NULL,
			[UpdatedById] [bigint] NULL,
			[IsClosed] [bit] NULL,
			[PDFPath] [nvarchar](max) NULL,
			[isLocked] [bit] NULL,
			[IsFinishGood] [bit] NULL,
			[RevisedConditionId] [bigint] NULL,
			[IsTransferredToParentWO] [bit] NULL,
			[RevisedSerialNumber] [varchar](50) NULL,
			[PublicationNo] [varchar](max) NULL,
			[TravelerNumber] [varchar](150) NULL,
			[MasterCompanyId] [int] NULL,
			[CreatedBy] [varchar](256) NULL,
			[UpdatedBy] [varchar](256) NULL,
			[CreatedDate] [datetime2](7) NULL,
			[UpdatedDate] [datetime2](7) NULL,
			[IsActive] [bit] NULL,
			[IsDeleted] [bit] NULL
		)

		INSERT INTO #tmpSubWorkOrderParts ([SubWOPartNoId],[WorkOrderId],[SubWorkOrderId],[ItemMasterId],[SubWorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],[NTE],[Quantity],[StockLineId],
										   [CMMIds],[WorkflowId],[SubWorkOrderStageId],[SubWorkOrderStatusId],[SubWorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],[TechnicianId],[ConditionId],[RevisedItemmasterid],
										   [TATDaysCurrent],[IsTraveler],[IsManualForm],[WorkOrderMaterialsId],[UpdatedById],[IsClosed],[PDFPath],[isLocked],[IsFinishGood],[RevisedConditionId],[IsTransferredToParentWO],[RevisedSerialNumber],
										   [PublicationNo],[TravelerNumber],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
									SELECT [SubWOPartNoId],[WorkOrderId],[SubWorkOrderId],[ItemMasterId],[SubWorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],[NTE],[Quantity],CASE WHEN [StockLineId] = 0 THEN NULL ELSE [StockLineId] END,
										   [CMMIds],CASE WHEN [WorkflowId] = 0 THEN NULL ELSE [WorkflowId] END,[SubWorkOrderStageId],[SubWorkOrderStatusId],[SubWorkOrderPriorityId],[IsPMA],[IsDER],CASE WHEN [TechStationId] = 0 THEN NULL ELSE [TechStationId] END,[TATDaysStandard],CASE WHEN [TechnicianId] = 0 THEN NULL ELSE [TechnicianId] END,[ConditionId],[RevisedItemmasterid],
										   [TATDaysCurrent],[IsTraveler],[IsManualForm],[WorkOrderMaterialsId],[UpdatedById],[IsClosed],[PDFPath],[isLocked],[IsFinishGood],CASE WHEN [RevisedConditionId] = 0 THEN NULL ELSE [RevisedConditionId] END,[IsTransferredToParentWO],[RevisedSerialNumber],
										   [PublicationNo],[TravelerNumber],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted] 
		FROM @SubWorkOrderParts;

		SELECT  @MasterLoopID = MAX(ID) FROM #tmpSubWorkOrderParts
				
		WHILE(@MasterLoopID > 0)
		BEGIN
			 SELECT @SubWorkOrderScopeId = [SubWorkOrderScopeId],
					@ItemMasterId = [ItemMasterId],
					@MasterCompanyId = [MasterCompanyId],
					@WorkOrderId = [WorkOrderId],
					@SubWorkOrderId = [SubWorkOrderId],
					@WorkOrderMaterialsId = [WorkOrderMaterialsId],
					@StockLineId = [StockLineId],
					@SubWOPartNoId = [SubWOPartNoId],
					@Quantity = [Quantity],
					@UpdatedById = [UpdatedById],
					@CreatedBy = [CreatedBy],
					@TechStationId = [TechStationId]
			 FROM #tmpSubWorkOrderParts WHERE [ID] = @MasterLoopID;

			 IF OBJECT_ID(N'tempdb..#tmpGetTravelerName') IS NOT NULL
			 BEGIN
			 	DROP TABLE #tmpGetTravelerName
			 END
			 			  	  
			 CREATE TABLE #tmpGetTravelerName
			 (
			 	TravelerName VARCHAR(250) NULL
			 )  
			 
			 --Get TravelerName from Procedure call.
			 INSERT INTO #tmpGetTravelerName (TravelerName) 
				EXEC [dbo].[USP_GetTravelerNameByWorkScopeId] @SubWorkOrderScopeId,@ItemMasterId;
			
			--Get TravelerName
			SELECT @TraverIdString = ISNULL(TravelerName,'') FROM #tmpGetTravelerName;

			IF(ISNULL(@SubWOPartNoId,0) > 0)
			BEGIN
				IF EXISTS (SELECT 1 FROM [dbo].[SubWorkOrderPartNumber] WITH(NOLOCK) WHERE SubWOPartNoId = @SubWOPartNoId AND SubWorkOrderStatusId != @ClosedStatusId)
				BEGIN
					IF(@TraverIdString IS NULL OR LTRIM(RTRIM(@TraverIdString)) = '')
					BEGIN
						 SELECT TOP 1 
						 	 @CurrentNumber = [CurrentNummber], 
                              @CodePrefix = [CodePrefix],  
                              @CodeSuffix = [CodeSufix]
						 FROM [dbo].[CodePrefixes] WITH(NOLOCK)
						 WHERE [IsActive] = 1 AND [IsDeleted] = 0 
						   AND [MasterCompanyId] = @MasterCompanyId 
						   AND [CodeTypeId] = @TravelerCodePrefix;

						 -- Check for current number and increment
						 IF @CodePrefix IS NOT NULL AND @CodePrefix <> ''
						 BEGIN
						 	  SELECT @CurrentNo = ISNULL([CurrentNummber], 0) FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;        
						 	  IF @CurrentNo > 0
						 	  BEGIN
						 	  	   SET @CurrentNo = @CurrentNo + 1;
						 	  	   UPDATE [dbo].[CodePrefixes] 
						 	  	   SET [CurrentNummber] = @CurrentNo
						 	  	   WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
						 	  END
						 	  ELSE
						 	  BEGIN
						 	  	   SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0)  FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId) + 1;
								   
						 	  	   UPDATE [dbo].[CodePrefixes]
						 	  	   SET [CurrentNummber] = @CurrentNo 
						 	  	   WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
						 	  END
						 	  -- Generate Traverler Number
						 	  SET @TraverIdString = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentNo, ISNULL(@CodePrefix,''),ISNULL(@CodeSuffix, '')))
						 END
						 ELSE
						 BEGIN
						 	-- Generate Traverler Number
						 	SET @TraverIdString = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentNo, '',''))
						 END
					END

					UPDATE sub
					SET 
						sub.EstimatedShipDate = tmp.EstimatedShipDate,
						sub.CustomerRequestDate = tmp.CustomerRequestDate,
						sub.PromisedDate = tmp.PromisedDate,
						sub.EstimatedCompletionDate = tmp.EstimatedCompletionDate,
						sub.NTE = tmp.NTE,
						sub.Quantity = tmp.Quantity,
						sub.SubWorkOrderPriorityId = tmp.SubWorkOrderPriorityId,
						sub.IsPMA = tmp.IsPMA,
						sub.IsDER = tmp.IsDER,
						sub.TechStationId = (CASE WHEN tmp.TechStationId = 0 THEN NULL ELSE tmp.TechStationId END),
						sub.TATDaysStandard = tmp.TATDaysStandard,
						sub.TechnicianId = (CASE WHEN tmp.TechnicianId = 0 THEN NULL ELSE tmp.TechnicianId END),
						sub.ConditionId = tmp.ConditionId,
						sub.RevisedItemmasterid = tmp.RevisedItemmasterid,
						sub.TATDaysCurrent = tmp.TATDaysCurrent,
						sub.IsTraveler = tmp.IsTraveler,
						sub.IsManualForm = tmp.IsManualForm,
						sub.IsClosed = tmp.IsClosed,
						sub.PDFPath = tmp.PDFPath,
						sub.islocked = tmp.islocked,
						sub.IsFinishGood = tmp.IsFinishGood,
						sub.RevisedConditionId = (CASE WHEN tmp.RevisedConditionId = 0 THEN NULL ELSE tmp.RevisedConditionId END),
						sub.IsTransferredToParentWO = tmp.IsTransferredToParentWO,
						sub.RevisedSerialNumber = tmp.RevisedSerialNumber,
						sub.PublicationNo = tmp.PublicationNo,
						sub.TravelerNumber = @TraverIdString,
						sub.CMMIds = tmp.CMMIds,
						sub.SubWorkOrderScopeId = tmp.SubWorkOrderScopeId,
						sub.WorkFlowId = tmp.WorkFlowId
					FROM [dbo].[SubWorkOrderPartNumber] sub
					JOIN #tmpSubWorkOrderParts tmp ON tmp.ID = @MasterLoopID
					WHERE tmp.ID = @MasterLoopID;

					--Call ReserveReleaseSubWorkOrderStockline 
					EXEC USP_Reserve_ReleaseSubWorkOrderStockline @WorkOrderId,@SubWorkOrderId,@WorkOrderMaterialsId,@StockLineId,@SubWOPartNoId,@Quantity,0,@UpdatedById,0
				END
			END
			ELSE
			BEGIN
				 DECLARE @WorkOrderTypeId BIGINT, @IsTraveler BIT = 0, @IsManualForm BIT = 0;

				 --Get from WorkOrder
				 SELECT TOP 1 @WorkOrderTypeId = WorkOrderTypeId
				 FROM [dbo].[WorkOrder] WITH(NOLOCK)
				 WHERE WorkOrderId = @WorkOrderId AND IsActive = 1 AND IsDeleted = 0;

				 --Get from workOrderSettings
				 SELECT TOP 1 @IsTraveler = ISNULL(IsTraveler, 0), 
                     @IsManualForm = ISNULL(IsManualForm, 0)
				 FROM [dbo].[WorkOrderSettings] WITH(NOLOCK)
				 WHERE WorkOrderTypeId = @WorkOrderTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;
				
				 --Set IsTraveler & IsManualForm from table
				 SET @IsTraveler = CASE WHEN @IsTraveler = 0 THEN 0 ELSE @IsTraveler END;
				 SET @IsManualForm = CASE WHEN @IsManualForm = 0 THEN 0 ELSE @IsManualForm END;

				 IF(@TraverIdString IS NULL OR LTRIM(RTRIM(@TraverIdString)) = '')
				 BEGIN
				 	  SELECT TOP 1 
				 	  	 @CurrentNumber = [CurrentNummber], 
                               @CodePrefix = [CodePrefix],  
                               @CodeSuffix = [CodeSufix]
				 	  FROM [dbo].[CodePrefixes] WITH(NOLOCK)
				 	  WHERE [IsActive] = 1 AND [IsDeleted] = 0 
				 	    AND [MasterCompanyId] = @MasterCompanyId 
				 	    AND [CodeTypeId] = @TravelerCodePrefix;
				 	  
				 	  -- Check for current number and increment
				 	  IF(@CodePrefix IS NOT NULL AND @CodePrefix <> '')
				 	  BEGIN
				 	  	   SELECT @CurrentNo = ISNULL([CurrentNummber], 0) FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;        
				 	  	   IF @CurrentNo > 0
				 	  	   BEGIN
				 	  	   	   SET @CurrentNo = @CurrentNo + 1;
				 	  	   	   UPDATE [dbo].[CodePrefixes] 
				 	  	   	   SET [CurrentNummber] = @CurrentNo
				 	  	   	   WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
				 	  	   END
				 	  	   ELSE
				 	  	   BEGIN
				 	  	   	   SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0)  FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId) + 1;
				 	 		    
				 	  	   	   UPDATE [dbo].[CodePrefixes]
				 	  	   	   SET [CurrentNummber] = @CurrentNo 
				 	  	   	   WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
				 	  	   END
				 	  	   -- Generate Traverler Number
				 	  	   SET @TraverIdString = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentNo, ISNULL(@CodePrefix,''),ISNULL(@CodeSuffix, '')))
				 	  END
				 	  ELSE
				 	  BEGIN
				 	  	  -- Generate Traverler Number
				 	  	  SET @TraverIdString = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentNo, '',''))
				 	  END
				 END

				INSERT INTO [dbo].[SubWorkOrderPartNumber] (
					WorkOrderId,SubWorkOrderId,ItemMasterId, SubWorkOrderScopeId,EstimatedShipDate,CustomerRequestDate,PromisedDate,EstimatedCompletionDate,
					NTE,Quantity,StockLineId,CMMIds,WorkflowId,SubWorkOrderStageId,SubWorkOrderStatusId,SubWorkOrderPriorityId,IsPMA,IsDER,TechStationId,
					TATDaysStandard,TechnicianId,ConditionId,TATDaysCurrent,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate, UpdatedDate,IsActive, IsDeleted,IsClosed,
					PDFPath,islocked,IsFinishGood,RevisedConditionId,CustomerReference,RevisedItemmasterid,IsTraveler,IsManualForm,IsTransferredToParentWO,RevisedStockLineId,
					RevisedSerialNumber,PublicationNo,TravelerNumber)
				SELECT
					WorkOrderId,SubWorkOrderId,ItemMasterId, SubWorkOrderScopeId,EstimatedShipDate,CustomerRequestDate,PromisedDate,EstimatedCompletionDate,
					NTE,Quantity,StockLineId,CMMIds,WorkflowId,SubWorkOrderStageId,SubWorkOrderStatusId,SubWorkOrderPriorityId,IsPMA,IsDER,TechStationId,
					TATDaysStandard,TechnicianId,ConditionId,TATDaysCurrent,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate, UpdatedDate,IsActive, IsDeleted,IsClosed,
					PDFPath,islocked,IsFinishGood,RevisedConditionId,NULL,RevisedItemmasterid,IsTraveler,IsManualForm,IsTransferredToParentWO,0,
					RevisedSerialNumber,PublicationNo,@TraverIdString
				FROM #tmpSubWorkOrderParts WHERE [ID] = @MasterLoopID
				
				--Call ReserveReleaseSubWorkOrderStockline 
				EXEC USP_Reserve_ReleaseSubWorkOrderStockline @WorkOrderId,@SubWorkOrderId,@WorkOrderMaterialsId,@StockLineId,@SubWOPartNoId,@Quantity,1,@UpdatedById,0
			END

			IF NOT EXISTS (SELECT 1 FROM [dbo].[SubWorkOrderMaterialMapping] WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId AND SubWorkOrderId = @SubWorkOrderId)
			BEGIN
				 INSERT INTO [dbo].[SubWorkOrderMaterialMapping] (
				 	 [CreatedDate], [UpdatedDate], [CreatedBy], [UpdatedBy], 
				 	 [IsActive], [IsDeleted], [MasterCompanyId], 
				 	 [SubWorkOrderId], [WorkOrderMaterialsId]
				 )
				 VALUES (
				 	 GETUTCDATE(), GETUTCDATE(), @CreatedBy, @CreatedBy, 
				 	 1, 0, @MasterCompanyId, 
				 	 @SubWorkOrderId, @WorkOrderMaterialsId
				 );
			END

			SET @MasterLoopID = @MasterLoopID - 1;
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
              , @AdhocComments     VARCHAR(150)    = 'InsertSubWorkOrderPartNumber' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SubWorkOrderScopeId, '') AS varchar(100))
													+ '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW---------------------------------------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END