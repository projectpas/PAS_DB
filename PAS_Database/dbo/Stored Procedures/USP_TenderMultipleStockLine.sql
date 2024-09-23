/*************************************************************   
** Author:  <Devendra Shekh>  
** Create date: <09/12/2024>  
** Description: <Tender Multiple StockLine>  
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author					Change Description  
** --   --------		-------					--------------------------------
** 1	09/12/2024		Devendra Shekh			Created
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_TenderMultipleStockLine]
	@tbl_TenderMultipleStocklineType [TenderMultipleStocklineType] READONLY,
	@UserName VARCHAR(100) = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			--BEGIN TRANSACTION
				BEGIN
					
					DECLARE @TotalStockLineCount BIGINT = 0, @CurrentStk BIGINT = 0;
					DECLARE @WorkOrderMaterialsId BIGINT, @Quantity INT, @IsSerialized BIT, @SerialNumber VARCHAR(150), @WorkOrderNum VARCHAR(30), @ReceivedDate DATETIME2,
							@IsKitType BIT, @ItemMasterId BIGINT, @UnitOfMeasureId BIGINT, @ConditionId BIGINT, @CustomerId BIGINT, @WorkOrderId BIGINT, @ManufacturerId BIGINT, @ProvisionId BIGINT,
							@SiteId BIGINT, @WareHouseId BIGINT, @LocationId BIGINT, @ShelfId BIGINT, @BinId BIGINT, @MasterCompanyId INT, @ManagementStructureId BIGINT;
					DECLARE @CodeTypeId INT, @TearDownWO INT = 0, @ObtainFromTypeId INT = NULL, @WOTypeId BIGINT = 0, @IsCustomerStock BIT = 0,  
							@ObtainFrom BIGINT = NULL, @ObtainFromName VARCHAR(500) = '', @SelectedCustomerAffiliation BIGINT, @IsCustomerstockType BIT = 0, @Nummber BIGINT = 0, @Unitcost DECIMAL(18,2) = 0,
							@OwnerTypeId INT = NULL, @Owner BIGINT = NULL, @OwnerName VARCHAR(500) = '', @TraceableToTypeId INT = NULL, @TraceableTo BIGINT = NULL, @TraceableToName VARCHAR(500) = '',  
							@InspectedById BIGINT = NULL, @InspectedDate DATETIME2(7) = NULL, @ReceiverNumber VARCHAR(500), @EvidenceId INT = 0, @IsMaterialStocklineCreate BIT = 1;
					DECLARE @TenderWOMStk [SaveAndTenderMultipleStocklineType];

					IF OBJECT_ID('tempdb..#TenderMultipleStkListData') IS NOT NULL
						DROP TABLE #TenderMultipleStkListData

					IF OBJECT_ID(N'tempdb..#tmpWOCodePrefixesNew') IS NOT NULL
						DROP TABLE #tmpWOCodePrefixesNew

					IF OBJECT_ID('tempdb..#tempCustomer') IS NOT NULL
						DROP TABLE #tempCustomer

					CREATE TABLE #TenderMultipleStkListData
					(
						[RecordID] BIGINT NOT NULL IDENTITY, 	
						[WorkOrderMaterialsId] [bigint] NULL,
						[PartNumber] [varchar](200) NULL,
						[PartDescription] [varchar](MAX) NULL,
						[UOM] [varchar](100) NULL,
						[Condition] [varchar](256) NULL,
						[Quantity] [int] NULL,
						[CustomerName] [varchar](100) NULL,
						[CustomerCode] [varchar](100) NULL,
						[IsSerialized] [bit] NULL, 
						[SerialNumberNotProvided] [bit] NULL, 
						[SerialNumber] [varchar](150) NULL, 
						[WorkOrderNum] [varchar](30) NULL,
						[Manufacturer] [varchar](100) NULL,
						[Receiver] [varchar](150) NULL,
						[ReceivedDate] [datetime2] NULL,
						[Provision] [varchar](150) NULL,
						[Site] [varchar](250) NULL,
						[WareHouse] [varchar](250) NULL,
						[Location] [varchar](250) NULL,
						[Shelf] [varchar](250) NULL,
						[Bin] [varchar](250) NULL,
						[IsKitType] [bit] NULL,
						[ItemMasterId] [bigint] NULL,
						[UnitOfMeasureId] [bigint] NULL,
						[ConditionId] [bigint] NULL,
						[CustomerId] [bigint] NULL,
						[WorkOrderId] [bigint] NULL,
						[Manufacturerid] [bigint] NULL,
						[ProvisionId] [bigint] NULL,
						[SiteId] [bigint] NULL,
						[WareHouseId] [bigint] NULL,
						[LocationId] [bigint] NULL,
						[ShelfId] [bigint] NULL,
						[BinId] [bigint] NULL,
						[MasterCompanyId] [int] NULL,
						[WorkFlowWorkOrderId] [bigint] NULL,
						[ManagementStructureId] [bigint] NULL,
						[UnitCost] [decimal](18,2) NULL
					)

					CREATE TABLE #tmpWOCodePrefixesNew
					(
							ID BIGINT NOT NULL IDENTITY, 
							CodePrefixId BIGINT NULL,
							CodeTypeId BIGINT NULL,
							CurrentNumber BIGINT NULL,
							CodePrefix VARCHAR(50) NULL,
							CodeSufix VARCHAR(50) NULL,
							StartsFrom BIGINT NULL,
							MasterCompanyId INT NULL,
					)

					CREATE TABLE #tempCustomer
					(
						[DataId] BIGINT NOT NULL IDENTITY,
						[CustomerId] BIGINT NULL,
						[Name] VARCHAR(100) NULL,
						[CustomerAffiliationId] BIGINT NULL,
						[customerType] VARCHAR(250) NULL
					)

					SET @CodeTypeId = (SELECT [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE UPPER([CodeType]) = 'RECEIVER NUMBER TENDER STOCKLINE');
					SET @TearDownWO = (SELECT Id FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE UPPER([Description]) = 'TEARDOWN');
					SET @ObtainFromTypeId = (SELECT ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'CUSTOMER');					

					INSERT INTO #TenderMultipleStkListData(
							[WorkOrderMaterialsId], [PartNumber], [PartDescription], [UOM], [Condition], [Quantity], [CustomerName], [CustomerCode], [IsSerialized], [SerialNumberNotProvided], [SerialNumber], [WorkOrderNum], [Manufacturer], 
							[Receiver], [ReceivedDate], [Provision], [Site], [WareHouse], [Location], [Shelf], [Bin], [IsKitType], [ItemMasterId], [UnitOfMeasureId], [ConditionId], [CustomerId], [WorkOrderId], [Manufacturerid], 
							[ProvisionId], [SiteId], [WareHouseId], [LocationId], [ShelfId], [BinId], [MasterCompanyId], [WorkFlowWorkOrderId], [ManagementStructureId], [UnitCost])
					SELECT	[WorkOrderMaterialsId], [PartNumber], [PartDescription], [UOM], [Condition], [Quantity], [CustomerName], [CustomerCode], [IsSerialized], [SerialNumberNotProvided], [SerialNumber], [WorkOrderNum], [Manufacturer], 
							[Receiver], [ReceivedDate], [Provision], [Site], [WareHouse], [Location], [Shelf], [Bin], [IsKitType], [ItemMasterId], [UnitOfMeasureId], [ConditionId], [CustomerId], [WorkOrderId], [Manufacturerid], 
							[ProvisionId], [SiteId], [WareHouseId], [LocationId], [ShelfId], [BinId], [MasterCompanyId], [WorkFlowWorkOrderId], [ManagementStructureId], [UnitCost]
					FROM @tbl_TenderMultipleStocklineType;

					SELECT @TotalStockLineCount = MAX(RecordID), @CurrentStk = MIN(RecordID) FROM #TenderMultipleStkListData;

					WHILE(ISNULL(@TotalStockLineCount, 0) >=  ISNULL(@CurrentStk, 0))
					BEGIN
						
						SELECT	@WorkOrderMaterialsId = WorkOrderMaterialsId, @Quantity = Quantity, @IsSerialized = IsSerialized, @SerialNumber = SerialNumber,
								@WorkOrderNum = WorkOrderNum, @ReceivedDate = ReceivedDate, @IsKitType = IsKitType, @ItemMasterId = ItemMasterId, @UnitOfMeasureId = UnitOfMeasureId,
								@ConditionId = ConditionId, @CustomerId = CustomerId, @WorkOrderId = WorkOrderId, @ManufacturerId = ManufacturerId, @ProvisionId = ProvisionId,
								@SiteId = SiteId, @WareHouseId = WareHouseId, @LocationId = LocationId, @ShelfId = ShelfId, @BinId = BinId,
								@MasterCompanyId = MasterCompanyId, @ManagementStructureId = [ManagementStructureId], @Unitcost = [UnitCost]
						FROM  #TenderMultipleStkListData WHERE RecordID = @CurrentStk;

						SELECT @WOTypeId = WorkOrderTypeId FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;

						--CodePrefix Data Insert
						IF(ISNULL(@CurrentStk, 0) = 1)
						BEGIN
							INSERT INTO #tmpWOCodePrefixesNew (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom, MasterCompanyId) 
							SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom, CP.MasterCompanyId
							FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
							WHERE CT.CodeTypeId = @CodeTypeId
							AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
						END

						IF(ISNULL(@ObtainFrom , 0) = 0)
						BEGIN
							--Customer Data Insert
							INSERT INTO #tempCustomer([CustomerId], [Name], [CustomerAffiliationId], [customerType])
							SELECT TOP 1 C.[CustomerId], C.[Name], C.[CustomerAffiliationId], ISNULL(CAF.[Description], '')
							FROM [dbo].[Customer] C WITH(NOLOCK) 
							LEFT JOIN [dbo].[CustomerAffiliation] CAF WITH(NOLOCK) ON c.CustomerAffiliationId = CAF.CustomerAffiliationId
							WHERE C.CustomerId = @CustomerId;
				
							SELECT @ObtainFrom = CustomerId, @SelectedCustomerAffiliation = ISNULL(CustomerAffiliationId, 0), @ObtainFromName = [Name] FROM #tempCustomer

							IF(ISNULL(@SelectedCustomerAffiliation, 0) = (SELECT CustomerAffiliationId FROM CustomerAffiliation WHERE UPPER([Description]) = 'EXTERNAL'))
							BEGIN
								SET @IsCustomerStock = 1
							END
							ELSE
							BEGIN
								SET @IsCustomerStock = 0
							END
						END

						--IF(@WOTypeId = @TearDownWO)
						--BEGIN
						--	SET @IsSerialized = 1;
						--END

						DECLARE @TOTALQTY BIGINT = 0, @QtyToTender BIGINT = 0, @SerialNumCount INT = 1, @TenderStkSerialNumber VARCHAR(150);

						IF(ISNULL(@IsSerialized, 0) = 1)
						BEGIN
							SET @TOTALQTY = @Quantity;
							SET @QtyToTender = @Quantity;
							SET @Quantity = 1;
						END
						ELSE
						BEGIN
							SET @TOTALQTY = 1;
							SET @QtyToTender = 1;
						END

						WHILE(ISNULL(@TOTALQTY, 0) > 0)
						BEGIN
							
							IF((ISNULL(@IsSerialized, 0) = 1) AND (ISNULL(@SerialNumber, '') != '') AND ISNULL(@QtyToTender, 0) > 1)
							BEGIN
								SET @TenderStkSerialNumber = @SerialNumber + '-' + CAST(@SerialNumCount AS VARCHAR); 
								SET @SerialNumCount += 1;
							END
							ELSE
							BEGIN
								SET @TenderStkSerialNumber = @SerialNumber;
							END							

							IF (EXISTS (SELECT 1 FROM #tmpWOCodePrefixesNew WHERE CodeTypeId = @CodeTypeId))
							BEGIN
								SELECT @Nummber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) END 
								FROM #tmpWOCodePrefixesNew WHERE CodeTypeId = @CodeTypeId
					
								SET @ReceiverNumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](
												@Nummber,
												(SELECT CodePrefix FROM #tmpWOCodePrefixesNew WHERE CodeTypeId = @CodeTypeId),
												(SELECT CodeSufix FROM #tmpWOCodePrefixesNew WHERE CodeTypeId = @CodeTypeId)))
							END
							/*****************End Prefixes*******************/	
					
							--Tender StockLine Part
							INSERT INTO @TenderWOMStk VALUES(
								@IsMaterialStocklineCreate, @IsCustomerStock, @IsCustomerstockType, @ItemMasterId, @UnitOfMeasureId, @ConditionId,
								@Quantity, @IsSerialized, @TenderStkSerialNumber, @CustomerId, @ObtainFromTypeId, @ObtainFrom, @ObtainFromName, @OwnerTypeId, @Owner, @OwnerName,
								@TraceableToTypeId, @TraceableTo, @TraceableToName, '', @WorkOrderId, @WorkOrderNum, @ManufacturerId, @InspectedById, @InspectedDate,
								@ReceiverNumber, @ReceivedDate, @ManagementStructureId, @SiteId, @WarehouseId, @LocationId, @ShelfId, @BinId, @MasterCompanyId, @UserName,
								@WorkOrderMaterialsId, @IsKitType, @Unitcost, @ProvisionId, @EvidenceId)

							--EXEC [dbo].[usp_SaveTurnInWorkOrderMaterils] 
							--	@IsMaterialStocklineCreate, @IsCustomerStock, @IsCustomerstockType, @ItemMasterId, @UnitOfMeasureId, @ConditionId,
							--	@Quantity, @IsSerialized, @TenderStkSerialNumber, @CustomerId, @ObtainFromTypeId, @ObtainFrom, @ObtainFromName, @OwnerTypeId, @Owner, @OwnerName,
							--	@TraceableToTypeId, @TraceableTo, @TraceableToName, '', @WorkOrderId, @WorkOrderNum, @ManufacturerId, @InspectedById, @InspectedDate,
							--	@ReceiverNumber, @ReceivedDate, @ManagementStructureId, @SiteId, @WarehouseId, @LocationId, @ShelfId, @BinId, @MasterCompanyId, @UserName,
							--	@WorkOrderMaterialsId, @IsKitType, @Unitcost, @ProvisionId, @EvidenceId
					
							UPDATE #tmpWOCodePrefixesNew SET CurrentNumber = CAST(@Nummber AS BIGINT) WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;
							
							SET @TOTALQTY = @TOTALQTY - 1;
						END

						UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@Nummber AS BIGINT) WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;

						SET @CurrentStk += 1;
					END
				END 

				EXEC [USP_SaveTurnInMultipleWorkOrderMaterils] @TenderWOMStk;

				IF OBJECT_ID('tempdb..#TenderMultipleStkListData') IS NOT NULL
					DROP TABLE #TenderMultipleStkListData

				IF OBJECT_ID(N'tempdb..#tmpWOCodePrefixesNew') IS NOT NULL
					DROP TABLE #tmpWOCodePrefixesNew

				IF OBJECT_ID('tempdb..#tempCustomer') IS NOT NULL
					DROP TABLE #tempCustomer
				--SELECT * FROM @TenderWOMStk
			--COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_TenderMultipleStockLine' 
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