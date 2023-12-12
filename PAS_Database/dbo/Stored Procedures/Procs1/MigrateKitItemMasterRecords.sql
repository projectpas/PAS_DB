/*************************************************************             
 ** File:   [MigrateKitItemMasterRecords]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Migrate KIT Item Master Records
 ** Purpose:           
 ** Date:   11/29/2023

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    11/29/2023   Vishal Suthar		Created
  

declare @p5 int
set @p5=NULL
declare @p6 int
set @p6=NULL
declare @p7 int
set @p7=NULL
declare @p8 int
set @p8=NULL
exec sp_executesql N'EXEC MigrateKitItemMasterRecords @FromMasterComanyID, @UserName, @Processed OUTPUT, @Migrated OUTPUT, @Failed OUTPUT, @Exists OUTPUT',N'@FromMasterComanyID int,@UserName nvarchar(12),@Processed int output,@Migrated int output,@Failed int output,@Exists int output',@FromMasterComanyID=12,@UserName=N'ROGER BENTLY',@Processed=@p5 output,@Migrated=@p6 output,@Failed=@p7 output,@Exists=@p8 output
select @p5, @p6, @p7, @p8
**************************************************************/
CREATE   PROCEDURE [dbo].[MigrateKitItemMasterRecords]
(
	@FromMasterComanyID INT = NULL,
	@UserName VARCHAR(100) NULL,
	@Processed INT OUTPUT,
	@Migrated INT OUTPUT,
	@Failed INT OUTPUT,
	@Exists INT OUTPUT
)
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
  
    BEGIN TRY  
    BEGIN TRANSACTION  
    BEGIN
		DECLARE @LoopID AS INT;

		IF OBJECT_ID(N'tempdb..#TempKitItemMaster') IS NOT NULL
		BEGIN
			DROP TABLE #TempKitItemMaster
		END

		CREATE TABLE #TempKitItemMaster
		(
			ID bigint NOT NULL IDENTITY,
			[KitMasterId] [bigint] NOT NULL,
			[MainItemMasterId] [bigint] NULL,
			[KitItemMasterId] [bigint] NULL,
			[Qty] [int] NULL,
			[UnitCost] decimal(18, 2) NULL,
			[ConditionId] [bigint] NULL,
			[MasterCompanyId] BIGINT NULL,
			[Migrated_Id] BIGINT NULL,
			[SuccessMsg] [varchar](500) NULL,
			[ErrorMsg] [varchar](500) NULL,
		)

		INSERT INTO #TempKitItemMaster ([KitMasterId],[MainItemMasterId],[KitItemMasterId],[Qty],[UnitCost],[ConditionId],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
		SELECT [KitMasterId],[MainItemMasterId],[KitItemMasterId],[Qty],[UnitCost],[ConditionId],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg]
		FROM [Quantum_Staging].dbo.[KitMasters] KIM WITH (NOLOCK) WHERE KIM.Migrated_Id IS NULL;

		DECLARE @ProcessedRecords INT = 0;
		DECLARE @MigratedRecords INT = 0;
		DECLARE @RecordsWithError INT = 0;
		DECLARE @RecordExits INT = 0;

		DECLARE @TotCount AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #TempKitItemMaster;

		WHILE (@LoopID <= @TotCount)
		BEGIN
			SET @ProcessedRecords = @ProcessedRecords + 1;
			
			DECLARE @PNM_AUTO_KEY BIGINT;
			DECLARE @KIT_PNM_AUTO_KEY BIGINT;
			DECLARE @PCC_AUTO_KEY BIGINT;
			DECLARE @UNIT_COST DECIMAL(18,2) = 0;
			DECLARE @PART_NUMBER VARCHAR(50);
			DECLARE @PART_DESC NVARCHAR(MAX);
			DECLARE @ITEMMASTER_ID BIGINT;
			DECLARE @CONDITIONCODE VARCHAR(50);
			DECLARE @PN VARCHAR(50);
			DECLARE @PN_DESC NVARCHAR(MAX);
			DECLARE @ManufacturerId BIGINT = 0;
			DECLARE @ManufacturerName VARCHAR(50) = '';
			DECLARE @CurrentKitItemMasterId BIGINT = 0;
			DECLARE @CurrentNummber BIGINT;
			DECLARE @CodePrefix VARCHAR(50);
			DECLARE @CodeSufix VARCHAR(50);	
			DECLARE @CodeTypeId BIGINT;
			DECLARE @KitNumber VARCHAR(100);
			DECLARE @CustomerId BIGINT = NULL;
			DECLARE @CustomerName VARCHAR(100) = NULL;
			DECLARE @KitId BIGINT = 0;

			DECLARE @FoundError BIT = 0;
			DECLARE @ErrorMsg VARCHAR(MAX) = '';

			SELECT @CurrentKitItemMasterId = KitMasterId, @PNM_AUTO_KEY = MainItemMasterId, @KIT_PNM_AUTO_KEY = KitItemMasterId, @PCC_AUTO_KEY = ConditionId, @UNIT_COST = UnitCost FROM #TempKitItemMaster WHERE ID = @LoopID;

			SELECT @PART_NUMBER = IM.PN, @PART_DESC = IM.[DESCRIPTION] 
			FROM [Quantum].[QCTL_NEW_3].[PARTS_MASTER] IM WITH(NOLOCK) WHERE IM.PNM_AUTO_KEY = @PNM_AUTO_KEY;		
	   
			SELECT @ITEMMASTER_ID = IM.[ItemMasterId] FROM [dbo].[ItemMaster] IM WITH(NOLOCK) 
			WHERE UPPER(IM.partnumber) = UPPER(@PART_NUMBER) AND UPPER(IM.PartDescription) = UPPER(@PART_DESC);
		 		
			SELECT @PN = IM.[partnumber], 
		       @PN_DESC = IM.[PartDescription], 
			   @ManufacturerId = IM.[ManufacturerId], 
			   @ManufacturerName = IM.[ManufacturerName] 
			FROM [dbo].[ItemMaster] IM WITH(NOLOCK) WHERE IM.ItemMasterId = @ITEMMASTER_ID AND MasterCompanyId = @FromMasterComanyID;

			SELECT @CodeTypeId = [CodeTypeId] FROM [CodeTypes] WHERE [CodeType] = 'KitMaster';
	   
			SELECT @CurrentNummber = [CurrentNummber],
	           @CodePrefix = [CodePrefix],
			   @CodeSufix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK)
			WHERE [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @FromMasterComanyID;

			IF (ISNULL(@PNM_AUTO_KEY, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Kit Item Master Id is missing</p>'
			END
			IF (ISNULL(@UNIT_COST, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Unit cost is missing</p>'
			END
			
			IF (@FoundError = 1)
			BEGIN
				UPDATE KITs
				SET KITs.ErrorMsg = ErrorMsg
				FROM [Quantum_Staging].DBO.[KitMasters] KITs WHERE KITs.KitMasterId = @CurrentKitItemMasterId;

				SET @RecordsWithError = @RecordsWithError + 1;
			END

			IF (@FoundError = 0)
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM [dbo].[KitMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ITEMMASTER_ID AND [MasterCompanyId] = @FromMasterComanyID)
				BEGIN
					IF OBJECT_ID(N'tempdb..#KitMapData') IS NOT NULL
					BEGIN
						DROP TABLE #KitMapData
					END

					CREATE TABLE #KitMapData
					(
						[ID] [bigint] NOT NULL IDENTITY,
						[KIT_AUTO_KEY] [float] NOT NULL,
						[PNM_AUTO_KEY] [float] NULL,
						[KIT_PNM_AUTO_KEY] [float] NULL,
						[QTY_ITEM] [numeric](11, 2) NOT NULL,
						[UNIT_COST] [numeric](19, 4) NULL,
						[PCC_AUTO_KEY] [float] NULL	
					)

					SET @KitNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(CAST(@CurrentNummber AS BIGINT) + 1, @CodePrefix, @CodeSufix));
		
					INSERT INTO [dbo].[KitMaster]([KitNumber],[ItemMasterId],[ManufacturerId],[PartNumber],[PartDescription],[Manufacturer]
						   ,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[CustomerId]
						   ,[CustomerName],[KitCost])
					 VALUES (@KitNumber,@ITEMMASTER_ID,@ManufacturerId,@PN,@PN_DESC,@ManufacturerName,
						   @FromMasterComanyID,@UserName,@UserName,GETDATE(),GETDATE(),1,0,@CustomerId,
						   @CustomerName,@UNIT_COST);

					SELECT @KitId = SCOPE_IDENTITY();

					UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = CAST(@CurrentNummber AS BIGINT) + 1 WHERE [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @FromMasterComanyID;
	  			
					INSERT INTO #KitMapData ([KIT_AUTO_KEY],[PNM_AUTO_KEY],[KIT_PNM_AUTO_KEY],[QTY_ITEM],[UNIT_COST],[PCC_AUTO_KEY])
					SELECT [KitMasterId],[MainItemMasterId],[KitItemMasterId],[Qty],[UnitCost],[ConditionId]
					FROM #TempKitItemMaster WHERE [MainItemMasterId] = @PNM_AUTO_KEY;

					DECLARE @LoopMapID AS INT;
					DECLARE @TotMapCount AS INT;

					SELECT  @TotMapCount = COUNT(*), @LoopMapID = MIN(ID) FROM #KitMapData;

					WHILE (@LoopMapID <= @TotMapCount)
					BEGIN
						DECLARE @InsertedKitItemMasterMappingId BIGINT = 0;
						DECLARE @PART_MAP_NUMBER VARCHAR(50)='';
						DECLARE @PART_MAP_DESC NVARCHAR(MAX)='';
						DECLARE @ITEMMASTER_MAP_ID BIGINT = 0;
						DECLARE @UOMId BIGINT = 0;	
						DECLARE @ConditionId BIGINT = 0;	
						DECLARE @StocklineUnitCost DECIMAL(18,2) = 0;
						DECLARE @ConditionName VARCHAR(50)='';
						DECLARE @UnitOfMeasure VARCHAR(50)='';		
						DECLARE @CONDDESCRIPTION VARCHAR(50)='';	
					
						SELECT @KIT_PNM_AUTO_KEY = KIT_PNM_AUTO_KEY, @PCC_AUTO_KEY = PCC_AUTO_KEY FROM #KitMapData WHERE ID = @LoopMapID;

						SELECT @PART_MAP_NUMBER = IM.PN,@PART_MAP_DESC = IM.[DESCRIPTION] FROM [Quantum].[QCTL_NEW_3].[PARTS_MASTER] IM WITH(NOLOCK) WHERE IM.PNM_AUTO_KEY = @KIT_PNM_AUTO_KEY;	

						SELECT @ITEMMASTER_MAP_ID = IM.[ItemMasterId] FROM [dbo].[ItemMaster] IM WITH(NOLOCK) WHERE UPPER(IM.partnumber) = UPPER(@PART_MAP_NUMBER) AND UPPER(IM.PartDescription) = UPPER(@PART_MAP_DESC) AND IM.MasterCompanyId = @FromMasterComanyID;
					
						SELECT @CONDITIONCODE = CC.CONDITION_CODE,@CONDDESCRIPTION = [DESCRIPTION] FROM [Quantum].QCTL_NEW_3.[PART_CONDITION_CODES] CC WITH(NOLOCK) WHERE CC.PCC_AUTO_KEY = @PCC_AUTO_KEY;	
					
						SELECT @ConditionId = [ConditionId], @ConditionName = [Description] FROM [dbo].[Condition] Cond WITH(NOLOCK) WHERE (UPPER(Cond.[Description]) = UPPER(@CONDITIONCODE)) AND [MasterCompanyId] = @FromMasterComanyID;
					
						SELECT TOP 1 @StocklineUnitCost = [PP_UnitPurchasePrice] FROM [dbo].[ItemMasterPurchaseSale] IPS WITH(NOLOCK) WHERE [ItemMasterId] = @ITEMMASTER_MAP_ID AND [ConditionId] = @ConditionId AND [MasterCompanyId] = @FromMasterComanyID;
												
						SELECT @PN = IM.[partnumber], 
								@PN_DESC = IM.[PartDescription], 
								@ManufacturerId = IM.[ManufacturerId], 
								@ManufacturerName = IM.[ManufacturerName], 
								@UOMId = IM.[PurchaseUnitOfMeasureId],
								@UnitOfMeasure = IM.PurchaseUnitOfMeasure
							FROM [dbo].[ItemMaster] IM WITH(NOLOCK) WHERE IM.ItemMasterId = @ITEMMASTER_MAP_ID AND MasterCompanyId = @FromMasterComanyID;

						INSERT INTO [dbo].[KitItemMasterMapping]([KitId],[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],[Qty]
							,[UnitCost],[StocklineUnitCost],[PartNumber],[PartDescription],[Manufacturer],[Condition],[UOM]
							,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
						SELECT @KitId,@ITEMMASTER_MAP_ID,@ManufacturerId,@ConditionId,@UOMId,(CAST(ISNULL(KT.[QTY_ITEM], 0) AS INT))
							,(CAST(ISNULL(KT.[UNIT_COST], 0) AS DECIMAL(18, 2))),@StocklineUnitCost,@PN,@PN_DESC,@ManufacturerName,@ConditionName,@UnitOfMeasure
							,@FromMasterComanyID,@UserName,@UserName,GETDATE(),GETDATE(),1,0
						FROM #KitMapData AS KT WHERE ID = @LoopMapID; 
	   		       
						SET @InsertedKitItemMasterMappingId = SCOPE_IDENTITY();

						SET @LoopMapID = @LoopMapID + 1;

						UPDATE KITs
						SET KITs.Migrated_Id = @InsertedKitItemMasterMappingId,
						KITs.SuccessMsg = 'Record migrated successfully'
						FROM [Quantum_Staging].DBO.[KitMasters] KITs WHERE KITs.KitMasterId = @CurrentKitItemMasterId;

						SET @MigratedRecords = @MigratedRecords + 1;
					END
				END
				--ELSE
				--BEGIN
				--	UPDATE KITs
				--	SET KITs.ErrorMsg = ISNULL(ErrorMsg, '') + '<p>KIT Master record already exists</p>'
				--	FROM [Quantum_Staging].DBO.[KitMasters] KITs WHERE KITs.KitMasterId = @CurrentKitItemMasterId;

				--	SET @RecordExits = @RecordExits + 1;
				--END
			END

			SET @LoopID = @LoopID + 1;
		END
	END

	COMMIT TRANSACTION

	SET @Processed = @ProcessedRecords;
	SET @Migrated = @MigratedRecords;
	SET @Failed = @RecordsWithError;
	SET @Exists = @RecordExits;

	SELECT @Processed, @Migrated, @Failed, @Exists;
  END TRY
  BEGIN CATCH
    IF @@trancount > 0
	  ROLLBACK TRAN;
	  SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
	  DECLARE @ErrorLogID int
	  ,@DatabaseName varchar(100) = DB_NAME()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
	  ,@AdhocComments varchar(150) = 'MigrateKitItemMasterRecords'
	  ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(CAST(@FromMasterComanyID AS VARCHAR(10)), '') + ''
	  ,@ApplicationName varchar(100) = 'PAS'
	  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
	  RETURN (1);  
	 END CATCH  
END