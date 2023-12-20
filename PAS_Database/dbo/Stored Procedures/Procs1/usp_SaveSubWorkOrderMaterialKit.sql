/*************************************************************           
 ** File:     [usp_SaveSubWorkOrderMaterialKit]           
 ** Author:	  Hemant Saliya
 ** Description: This SP is Used to save Sub WO material KITs    
 ** Purpose:         
 ** Date:   11/27/2023
          
 ** PARAMETERS:             
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author					Change Description            
 ** --   --------     -------				--------------------------------     
	1    11/27/2023   Hemant Saliya			Created

declare @p1 dbo.WorkOrderMaterialKitType
insert into @p1 values(0,3718,124,148,124,124,3380,N'JD-KIT',20748,5,15280,1,N'ADMIN User',N'ADMIN User','2023-09-05 05:42:00','2023-11-06 02:25:00',1,0)

exec dbo.usp_SaveSubWorkOrderMaterialKit @tbl_WorkOrderMaterialKitType=@p1

**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_SaveSubWorkOrderMaterialKit]
	@tbl_WorkOrderMaterialKitType WorkOrderMaterialKitType READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
			DECLARE @InsertedWorkOrderMaterialsKitMappingId BIGINT;
			DECLARE @Main_LoopID AS INT;
			DECLARE @LoopID AS INT;
			DECLARE @KitAddfor AS INT = 0;
			DECLARE @BodyTemplate NVARCHAR(MAX);
			DECLARE @TempBody NVARCHAR(MAX);
			DECLARE @historyModuleId BIGINT;
			DECLARE @historyWorkOrderId BIGINT;
			DECLARE @historyMasterCompanyId INT;
			DECLARE @historyCreatedBy VARCHAR(MAX);
			DECLARE @historyUpdatedBy VARCHAR(MAX);
			DECLARE @kitnumber VARCHAR(MAX);
			DECLARE @moduleId BIGINT
			DECLARE	@WorkOrderNum VARCHAR(MAX),@WOPartNum VARCHAR(MAX),@historyQTY INT,@historyCondition VARCHAR(MAX),@historyKitNumber VARCHAR(MAX),@historySubRefferenceId BIGINT;

			IF OBJECT_ID(N'tempdb..#SubWorkOrderMaterialKitType') IS NOT NULL
			BEGIN
				DROP TABLE #SubWorkOrderMaterialKitType 
			END
			
			CREATE TABLE #SubWorkOrderMaterialKitType 
			(
				ID BIGINT NOT NULL IDENTITY, 
				[SubWorkOrderMaterialKitMappingId] [bigint] NULL,
				[WorkOrderId] [bigint] NULL,
				[WOPartNoId] [bigint] NULL,
				[SubWorkOrderId] [bigint] NULL,
				[SubWOPartNoId] [bigint] NULL,
				[KitId] [bigint] NULL,
				[KitNumber] [varchar](256) NULL,
				[ItemMasterId] [bigint] NULL,
				[Quantity] [int] NULL,
				[UnitCost] [decimal](18, 2) NULL,
				[MasterCompanyId] [int] NULL,
				[CreatedBy] [varchar](256) NULL,
				[UpdatedBy] [varchar](256) NULL,
				[CreatedDate] [datetime2](7) NULL,
				[UpdatedDate] [datetime2](7) NULL,
				[IsActive] [bit] NULL,
				[IsDeleted] [bit] NULL
			)
				
			INSERT INTO #SubWorkOrderMaterialKitType 
			([SubWorkOrderMaterialKitMappingId], [WorkOrderId], [WOPartNoId], [SubWorkOrderId], [SubWOPartNoId], [KitId], [KitNumber], [ItemMasterId], [Quantity], 
			[UnitCost], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			SELECT [WorkOrderMaterialKitMappingId], [WorkOrderId], [WOPartNoId], [SubWorkOrderId], [SubWOPartNoId], [KitId], [KitNumber], [ItemMasterId], [Quantity], 
			[UnitCost], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
			FROM @tbl_WorkOrderMaterialKitType

			DECLARE @TotMainCount AS INT;
			SELECT @TotMainCount = COUNT(*), @Main_LoopID = MIN(ID) FROM #SubWorkOrderMaterialKitType;

			WHILE (@Main_LoopID <= @TotMainCount)
			BEGIN
				DECLARE @KitId BIGINT;
				SELECT @KitId = [KitId] FROM #SubWorkOrderMaterialKitType WHERE ID = @Main_LoopID;

				INSERT INTO [dbo].[SubWorkOrderMaterialsKitMapping]
				([SubWOPartNoId],[KitId],[KitNumber],[ItemMasterId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
				SELECT [SubWOPartNoId],[KitId],[KitNumber],[ItemMasterId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted]
				FROM #SubWorkOrderMaterialKitType tmp WHERE [KitId] = @KitId;

				SELECT @InsertedWorkOrderMaterialsKitMappingId = SCOPE_IDENTITY();

				--DATA ENTRY IN History TABLE.	
				IF (SELECT tmp.WorkOrderId FROM #SubWorkOrderMaterialKitType tmp WHERE tmp.KitId = @KitId) > 0
				BEGIN
					SELECT TOP 1 @moduleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SubWorkOrder'
				END

				SELECT @historyModuleId = @moduleId
				SELECT @BodyTemplate = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = 'AddKit';
				SELECT @WorkOrderNum = SW.SubWorkOrderNo, @historyKitNumber = KitNumber ,@historyWorkOrderId = WMK.SubWorkOrderId FROM #SubWorkOrderMaterialKitType WMK WITH(NOLOCK)
				LEFT JOIN dbo.SubWorkOrder SW  WITH(NOLOCK) ON SW.SubWorkOrderId = WMK.SubWorkOrderId 
				
				SELECT @historySubRefferenceId = tmp.SubWOPartNoId, @historyCreatedBy= tmp.CreatedBy, @historyUpdatedBy =tmp.UpdatedBy,
					   @historyKitNumber = tmp.KitNumber
				FROM #SubWorkOrderMaterialKitType tmp WHERE [KitId] = @KitId;

				SET @BodyTemplate =   REPLACE(@BodyTemplate, '##kitNumber##', ISNULL(@historyKitNumber,''));
				
				IF @TempBody IS NULL
					SET @TempBody = @BodyTemplate  + '.';
				ELSE
					SET @TempBody = @TempBody + ' ' +  @BodyTemplate +'.';
				
				SET @kitnumber = 'Kit Added:'+@historyKitNumber;
				
				EXEC [dbo].[USP_History] @historyModuleId,@historyWorkOrderId,null,@historySubRefferenceId,'',@kitnumber,@TempBody,'AddKit',@historyMasterCompanyId,@historyCreatedBy,NULL,@historyUpdatedBy,NULL;
				
				SET @TempBody = '';
				--END DATA ENTRY IN History TABLE.

				IF OBJECT_ID(N'tempdb..#KitItemMasterMapping') IS NOT NULL
				BEGIN
					DROP TABLE #KitItemMasterMapping
				END

				CREATE TABLE #KitItemMasterMapping
				(
					ID bigint NOT NULL IDENTITY,
					[KitItemMasterMappingId] [bigint] NOT NULL,
					[KitId] [bigint] NOT NULL,
					[ItemMasterId] [bigint] NOT NULL,
					[ManufacturerId] [bigint] NOT NULL,
					[ConditionId] [bigint] NOT NULL,
					[UOMId] [bigint] NOT NULL,
					[Qty] [int] NULL,
					[UnitCost] [decimal](18, 2) NULL,
					[StocklineUnitCost] [decimal](18, 2) NULL,
					[PartNumber] [varchar](250) NULL,
					[PartDescription] [varchar](MAX) NULL,
					[Manufacturer] [varchar](256) NULL,
					[Condition] [varchar](256) NULL,
					[UOM] [varchar](256) NULL,
					[MasterCompanyId] [int] NULL,
					[CreatedBy] [varchar](256) NULL,
					[UpdatedBy] [varchar](256) NULL,
					[CreatedDate] [datetime2](7) NULL,
					[UpdatedDate] [datetime2](7) NULL,
					[IsActive] [bit] NULL,
					[IsDeleted] [bit] NULL
				)

				INSERT INTO #KitItemMasterMapping 
				([KitItemMasterMappingId], [KitId], [ItemMasterId], [ManufacturerId], [ConditionId], [UOMId], [Qty], [UnitCost], [StocklineUnitCost], [PartNumber], 
				[PartDescription], [Manufacturer], [Condition], [UOM], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
				SELECT [KitItemMasterMappingId], [KitId], [ItemMasterId], [ManufacturerId], [ConditionId], [UOMId], [Qty], [UnitCost], [StocklineUnitCost], [PartNumber], 
				[PartDescription], [Manufacturer], [Condition], [UOM], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
				FROM [dbo].[KitItemMasterMapping] WHERE [KitId] = @KitId AND IsActive = 1 AND IsDeleted = 0;

				DECLARE @TotCount AS INT;
				SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #KitItemMasterMapping;

				WHILE (@LoopID <= @TotCount)
				BEGIN
					DECLARE @MasterCompanyId BIGINT;
					DECLARE @ItemMasterId BIGINT;
					DECLARE @Qty BIGINT;
					DECLARE @UOMId BIGINT;
					DECLARE @UnitCost [decimal](18, 2);
					DECLARE @TaskId BIGINT;
					DECLARE @ItemClassificationId BIGINT;
					DECLARE @ProvisionId BIGINT;

					SELECT TOP 1 @MasterCompanyId = MasterCompanyId FROM #SubWorkOrderMaterialKitType;
					SELECT @TaskId = [DefaultTaskId] FROM [dbo].[WorkOrderSettings] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId;
					IF (ISNULL(@TaskId, 0) = 0)
					BEGIN
						SELECT @TaskId = ISNULL(TaskId, 0) FROM [dbo].[Task] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND UPPER(Description) = 'ALL TASK';
					END

					SELECT @ItemMasterId = [ItemMasterId], @Qty = Qty, @UOMId = UOMId, @UnitCost = StocklineUnitCost FROM #KitItemMasterMapping WHERE ID = @LoopID;
					SELECT @ItemClassificationId = IM.ItemClassificationId FROM [DBO].[ItemMaster] IM WHERE ItemMasterId = @ItemMasterId;
					SELECT @ProvisionId = PROV.ProvisionId FROM [DBO].[Provision] PROV WHERE UPPER(StatusCode) = 'REPLACE';

					INSERT INTO [dbo].[SubWorkOrderMaterialsKit]
					([SubWorkOrderMaterialsKitMappingId],[WorkOrderId],[SubWorkOrderId],[SubWOPartNoId],[ItemMasterId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
					[IsActive],[IsDeleted],[TaskId],[ConditionCodeId],[ItemClassificationId],[Quantity],[UnitOfMeasureId],[UnitCost],[ExtendedCost],[Memo],[IsDeferred],
					[QuantityReserved],[QuantityIssued],[IssuedDate],[ReservedDate],[IsAltPart],[AltPartMasterPartId],[IsFromWorkFlow],[PartStatusId],
					[IssuedById],[ReservedById],[IsEquPart],[ParentSubWorkOrderMaterialsId],[ItemMappingId],[TotalReserved],[TotalIssued],[ProvisionId],
					[MaterialMandatoriesId],[TotalStocklineQtyReq],[QtyOnOrder],[QtyOnBkOrder],[POId],[PONum],[PONextDlvrDate],[QtyToTurnIn],[Figure],[Item])
					SELECT @InsertedWorkOrderMaterialsKitMappingId, tmp.WorkOrderId, tmp.SubWorkOrderId, tmp.[SubWOPartNoId], @ItemMasterId, tmp.MasterCompanyId, tmp.CreatedBy, tmp.UpdatedBy, GETDATE(), GETDATE(),
					tmp.IsActive, tmp.IsDeleted, @TaskId, (SELECT KIM.[ConditionId] FROM #KitItemMasterMapping KIM WHERE ID = @LoopID), @ItemClassificationId, @Qty, @UOMId, @UnitCost, (@UnitCost * @Qty), '', 0,
					0, 0, NULL, NULL, 0, 0, 0, 0, 
					NULL, NULL, 0, 0, 0, 0, 0, @ProvisionId,
					1, 0, 0, 0, NULL, NULL, NULL, 0, NULL, NULL
					FROM #SubWorkOrderMaterialKitType tmp WHERE tmp.KitId = @KitId; 
					
					SET @KitAddfor = @KitAddfor + 1;
					
								
					SET @LoopID = @LoopID + 1;
					END
				SET @Main_LoopID = @Main_LoopID + 1;
			END 

			
		END
		COMMIT TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_SaveSubWorkOrderMaterialKit' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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