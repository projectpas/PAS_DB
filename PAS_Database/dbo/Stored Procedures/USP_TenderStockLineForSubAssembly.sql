/*************************************************************           
 ** File:   [USP_TenderStockLineForSubAssembly]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used to tender stockline for sub-assembly 
 ** Purpose:         
 ** Date:   01/03/2024        
          
 ** PARAMETERS:           
 @WOPartNoId BIGINT 
 @SerialNumber varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    01/04/2024		Hemant Saliya		Created
    2    01/19/2024		Devendra Shekh		qty base tender stk changes
    3    01/23/2024		Devendra Shekh		serial Number issue resolved    
	4    01/29/2024		Hemant Saliya		Resolved Error 
	5 	 22/03/2024     Moin Bloch          Added New Field @EvidenceId
	6 	 18/07/2024     Moin Bloch          Added @LocationId Field
	

exec USP_TenderStockLineForSubAssembly @WorkOrderId=4185,@WorkFlowWorkOrderId=3646,@WorkOrderMaterialsId=16481
**************************************************************/
 --Select * from WorkOrderMaterials where WorkOrderId =  4185
CREATE   PROCEDURE [dbo].[USP_TenderStockLineForSubAssembly]
	@WorkOrderId BIGINT,
	@WorkFlowWorkOrderId BIGINT,
	@WorkOrderMaterialsId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

				DECLARE @WOPartNoId BIGINT = 0,
				@IsMaterialStocklineCreate BIT = 1,  
				@IsCustomerStock BIT = 0,  
				@IsCustomerstockType BIT = 0,  
				@ItemMasterId BIGINT,  
				@UnitOfMeasureId BIGINT,  
				@ConditionId BIGINT,  
				@Quantity INT,  
				@IsSerialized BIT,  
				@SerialNumber VARCHAR(50),  
				@CustomerId BIGINT = NULL,  
				@ObtainFromTypeId INT = NULL,  
				@ObtainFrom BIGINT = NULL,  
				@ObtainFromName VARCHAR(500) = '',  
				@OwnerTypeId INT = NULL,  
				@Owner BIGINT = NULL,  
				@OwnerName VARCHAR(500) = '',  
				@TraceableToTypeId INT = NULL,  
				@TraceableTo BIGINT = NULL,  
				@TraceableToName VARCHAR(500) = '',  
				@Memo VARCHAR(MAX) = '',  
				@WorkOrderNumber VARCHAR(50),  
				@ManufacturerId BIGINT,  
				@InspectedById BIGINT = NULL,  
				@InspectedDate DATETIME2(7) = NULL,  
				@ReceiverNumber VARCHAR(500),  
				@ReceivedDate DATETIME2(7),  
				@ManagementStructureId BIGINT,  
				@SiteId BIGINT,  
				@WarehouseId BIGINT = NULL,  
				@LocationId BIGINT = NULL,  
				@ShelfId BIGINT = NULL,  
				@BinId BIGINT = NULL,  
				@MasterCompanyId BIGINT,  
				@UpdatedBy VARCHAR(100),  
				@IsKitType BIT = 0,  
				@Unitcost DECIMAL(18,2) = 0,
				@ProvisionId INT = 0 ,
				@EvidenceId INT = 0,  
				@TearDownWO INT = 0 ,
				@WOTypeId BIGINT = 0 ,
				@SelectedCustomerAffiliation BIGINT,
				@CodeTypeId INT,
				@Nummber BIGINT = 0,
				@PartQtyToTurnIn BIGINT = 0,
				@PartQuantityTurnIn BIGINT = 0,
				@QuantityReserved BIGINT = 0,
				@QuantityIssued BIGINT = 0,
				@QtyToTender BIGINT = 0,
				@ARConditionId BIGINT = 0,
				@CurrentSerialNumber BIGINT = 0,
				@MaterialItemMasterId BIGINT = 0,
				@MaterialIsSerialized BIT = 0,
				@WorkOrderPartNoId BIGINT;

				IF OBJECT_ID(N'tempdb..#tmpWOMStockline') IS NOT NULL
				BEGIN
					DROP TABLE #tmpWOMStockline
				END

				IF OBJECT_ID('tempdb..#tempCustomer') IS NOT NULL
				BEGIN
					DROP TABLE #tempCustomer
				END

				IF OBJECT_ID(N'tempdb..#tmpWOCodePrefixesNew') IS NOT NULL
				BEGIN
					DROP TABLE #tmpWOCodePrefixesNew
				END

				CREATE TABLE #tempCustomer
				(
					[DataId] BIGINT NOT NULL IDENTITY,
					[CustomerId] BIGINT NULL,
					[Name] VARCHAR(100) NULL,
					[CustomerAffiliationId] BIGINT NULL,
					[customerType] VARCHAR(250) NULL
				)
	
				CREATE TABLE #tmpWOMStockline
				(
					ID BIGINT NOT NULL IDENTITY, 						 
					[StockLineId] [bigint] NOT NULL,
					[WorkOrderMaterialsId] [bigint] NULL,
					[ConditionId] [bigint] NOT NULL,
					[QtyIssued] [int] NOT NULL,
					[QtyReserved] [int] NULL,
					[IsActive] BIT NULL,
					[IsDeleted] BIT NULL,
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
				)
				
				SET @TearDownWO = (SELECT Id FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description] = 'Teardown');
				SET @CodeTypeId = (SELECT [CodeTypeId] FROM [dbo].[CodeTypes] WHERE [CodeType] = 'Receiver Number Tender stockline');
				SET @ObtainFromTypeId = (SELECT ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Customer');
				SET @WOPartNoId = (SELECT [WorkOrderPartNoId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId);

				SELECT @WorkOrderPartNoId = ID FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK) JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOP.ID = WOWF.WorkOrderPartNoId WHERE WOWF.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId;

				SELECT @CustomerId = [CustomerId], @WorkOrderNumber = [WorkOrderNum] , @MasterCompanyId = MasterCompanyId, @WOTypeId = WorkOrderTypeId, @UpdatedBy = UpdatedBy
				FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
				SET @ARConditionId = (SELECT ConditionId FROM Condition WHERE [Description] = 'AR' AND MasterCompanyId = @MasterCompanyId);

				/*****************Quntity for Part : Start*******************/
				INSERT INTO #tmpWOMStockline SELECT DISTINCT						
						WOMS.StockLineId, 						
						WOMS.WorkOrderMaterialsId,
						WOMS.ConditionId,
						WOMS.QtyIssued,
						WOMS.QtyReserved,
						WOMS.IsActive,
						WOMS.IsDeleted
				FROM dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) 
				JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId 
				AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOMS.IsActive = 1 AND WOMS.IsDeleted = 0

				SET @QuantityReserved = (SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
												JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) on womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
												WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId)

				SET @PartQuantityTurnIn = (SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)
												JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) on womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
												JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
												WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
												AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0 AND WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId)

				SET @QuantityIssued = (SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) on womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId)

				/*****************Quntity for Part : END*******************/
				
				SELECT @ProvisionId = ProvisionId, @Quantity = ISNULL(Quantity, 0), @ConditionId = ConditionCodeId, @PartQtyToTurnIn = ISNULL(QtyToTurnIn, 0), @MaterialItemMasterId = ISNULL(ItemMasterId, 0)
				FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId;

				SELECT @MaterialIsSerialized = isSerialized FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE ItemMasterId = @MaterialItemMasterId;
				
				SET @SerialNumber = (SELECT [SerialNumber] FROM [dbo].[ReceivingCustomerWork] RC WITH(NOLOCK) 
				INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON RC.ReceivingCustomerWorkId = WO.ReceivingCustomerWorkId WHERE WO.WorkOrderId = @WorkOrderId)

				--Customer Data Insert
				INSERT INTO #tempCustomer([CustomerId], [Name], [CustomerAffiliationId], [customerType])
				SELECT TOP 1 C.[CustomerId], C.[Name], C.[CustomerAffiliationId], ISNULL(CAF.[Description], '')
				FROM [dbo].[Customer] C WITH(NOLOCK) 
				LEFT JOIN [dbo].[CustomerAffiliation] CAF WITH(NOLOCK) ON c.CustomerAffiliationId = CAF.CustomerAffiliationId
				WHERE C.CustomerId = @CustomerId;
				
				SELECT @ObtainFrom = CustomerId, @SelectedCustomerAffiliation = ISNULL(CustomerAffiliationId, 0), @ObtainFromName = [Name] FROM #tempCustomer

				IF(ISNULL(@SelectedCustomerAffiliation, 0) = (SELECT CustomerAffiliationId FROM CustomerAffiliation WHERE [Description] = 'External'))
				BEGIN
					SET @IsCustomerStock = 1
				END
				ELSE
				BEGIN
					SET @IsCustomerStock = 0
				END

				--getting Part Data
				;WITH itemData(ItemMasterId, ShelfLife, IsSerialized, SiteId, WarehouseId, LocationId, ShelfId, BinId,
							   IsOEM, IsOemPNId, IsPma, IsDER, ManufacturerId, PurchaseUnitOfMeasureId)
				AS (SELECT  iM.ItemMasterId, iM.ShelfLife, ISNULL(iM.IsSerialized, 0), iM.SiteId, iM.WarehouseId, iM.LocationId, iM.ShelfId, iM.BinId, 
						    iM.IsOEM, iM.IsOemPNId, iM.IsPma, iM.IsDER, iM.ManufacturerId, iM.PurchaseUnitOfMeasureId
						   FROM [dbo].[ItemMaster] iM WITH(NOLOCK)
						   LEFT JOIN [dbo].[ItemMaster] rPart WITH(NOLOCK) ON iM.RevisedPartId = rPart.ItemMasterId
						   LEFT JOIN [dbo].[ItemMasterExchangeLoan] imxl WITH(NOLOCK) ON iM.RevisedPartId = imxl.ItemMasterId
						   LEFT JOIN [dbo].[ItemMasterPurchaseSale] imps WITH(NOLOCK) ON iM.RevisedPartId = imps.ItemMasterId
						   LEFT JOIN [dbo].[ItemMasterExportInfo] imx WITH(NOLOCK) ON iM.RevisedPartId = imx.ItemMasterId
						   LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON iM.RevisedPartId = gl.GLAccountId
						   WHERE iM.ItemMasterId = @MaterialItemMasterId)

				SELECT @UnitOfMeasureId = PurchaseUnitOfMeasureId, @IsSerialized = IsSerialized,
					   @ManufacturerId = ManufacturerId, @ReceivedDate = GETDATE(), @SiteId = SiteId, @WarehouseId = WarehouseId, @LocationId= LocationId, @ShelfId = ShelfId, @BinId = BinId FROM itemData

				IF(@WOTypeId = @TearDownWO)
				BEGIN
					SET @IsSerialized = 1;
				END

				IF(ISNULL(@IsSerialized, 0) = 1)
				BEGIN
					--SET @Quantity = 1
					SET @QtyToTender = ISNULL(@PartQtyToTurnIn, 0) - ISNULL(@PartQuantityTurnIn, 0)
					IF(@QtyToTender = 0)
					BEGIN
						SET @QtyToTender = @Quantity - (ISNULL(@QuantityReserved, 0) + ISNULL(@QuantityIssued, 0))
					END
					SET @Quantity = @QtyToTender
				END
				ELSE
				BEGIN
					SET @QtyToTender = ISNULL(@PartQtyToTurnIn, 0) - ISNULL(@PartQuantityTurnIn, 0)
					IF(@QtyToTender = 0)
					BEGIN
						SET @QtyToTender = @Quantity - (ISNULL(@QuantityReserved, 0) + ISNULL(@QuantityIssued, 0))
					END
					SET @Quantity = @QtyToTender
					SET @SerialNumber = '';
				END

				DECLARE @TOTALQTY BIGINT = 0;
				SET @TOTALQTY = @Quantity

				WHILE(@TOTALQTY > 0)
				BEGIN

					--CodePrefix Data Insert
					INSERT INTO #tmpWOCodePrefixesNew (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
					SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
					FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
					WHERE CT.CodeTypeId = @CodeTypeId
					AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

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

					SELECT @ItemMasterId = [ItemMasterId], @ManagementStructureId = ManagementStructureId, @CurrentSerialNumber = CurrentSerialNumber 
					FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WOPartNoId;

					SET @CurrentSerialNumber = CASE WHEN @CurrentSerialNumber IS NULL THEN 1 ELSE @CurrentSerialNumber + 1 END

					IF(@MaterialItemMasterId > 0)
					BEGIN
						IF(@MaterialIsSerialized = 1 AND @WOTypeId = @TearDownWO)
						BEGIN
							SET @SerialNumber = @WorkOrderNumber + '-' + CAST(@CurrentSerialNumber AS VARCHAR);
						END
						ELSE
						BEGIN
							SET @SerialNumber = '';
						END
					END
					ELSE
					BEGIN
						SET @SerialNumber = @WorkOrderNumber + '-' + CAST((@CurrentSerialNumber) AS VARCHAR);
					END

					IF(ISNULL(@IsSerialized, 0) = 0)
						SET @SerialNumber = '';
					
					--Tender StockLine Part
					EXEC [dbo].[usp_SaveTurnInWorkOrderMaterils] 
						@IsMaterialStocklineCreate, @IsCustomerStock, @IsCustomerstockType, @MaterialItemMasterId, @UnitOfMeasureId, @ConditionId,
						1, @IsSerialized, @SerialNumber, @CustomerId, @ObtainFromTypeId, @ObtainFrom, @ObtainFromName, @OwnerTypeId, @Owner, @OwnerName,
						@TraceableToTypeId, @TraceableTo, @TraceableToName, @Memo, @WorkOrderId, @WorkOrderNumber, @ManufacturerId, @InspectedById, @InspectedDate,
						@ReceiverNumber, @ReceivedDate, @ManagementStructureId, @SiteId, @WarehouseId, @LocationId, @ShelfId, @BinId, @MasterCompanyId, @UpdatedBy,
						@WorkOrderMaterialsId, @IsKitType, @Unitcost, @ProvisionId, @EvidenceId
					
					UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@Nummber AS BIGINT) WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;
					
					IF OBJECT_ID(N'tempdb..#tmpWOCodePrefixesNew') IS NOT NULL
					BEGIN
						TRUNCATE TABLE #tmpWOCodePrefixesNew;
					END

					SET @TOTALQTY = @TOTALQTY - 1
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
              , @AdhocComments     VARCHAR(150)    = 'USP_TenderStockLineForSubAssembly' 
		      , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))
			                                       + '@Parameter2 = ''' + CAST(ISNULL(@WorkFlowWorkOrderId, '') AS VARCHAR(100))
												   + '@Parameter3 = ''' + CAST(ISNULL(@WorkOrderMaterialsId, '') AS VARCHAR(100)) + '' 		 
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