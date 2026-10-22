/*************************************************************
 ** File:   [USP_UpdateStocklineDraftForIsSerialized]
 ** Author:   Shrey Chandegara
 ** Description: This stored procedure is used to Update stockline draft for timelife
 ** Purpose:
 ** Date:   11-04-2024

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author				Change Description
 ** --   --------     -------			--------------------------------
    1    11-04-2024   Shrey Chandegara		Created
    2    20/July/2026  RAJESH GAMI		[PN-17350] - Redirected Non-Stock branch from legacy NonStockInventoryDraft to unified StocklineDraft (ItemMasterId, StockLineId, StockLineNumber columns), filtered with ISNULL(IsNonStock,0) = 1.
    3    13/Aug/2026  RAJESH GAMI		[PN-17350] - Re-added missing ISNULL(IsNonStock,0) = 1 filter on the NonStock-branch StocklineDraft UPDATE WHERE clause that was dropped when this proc was ported from BETA.
    4    21/Oct/2026  RAJESH GAMI		[PN-18382] - Receiving PO: Stock / Non-Stock draft rows are now restructured when Is Serialized is changed. Non-Serialized -> Serialized keeps the main row (IsParent = 0, full Quantity) and creates one child row per unit (IsParent = 1, Quantity = 1, decimal remainder on the last child). Serialized -> Non-Serialized deletes the child rows (with their Management Structure / TimeLife draft rows) and keeps the main row (IsParent = 1, full Quantity). ParentId is reset to 0 on the affected rows (it is re-linked on save). Handled per PO part line, received rows are never touched. Also fixed the CATCH block parameter string (varchar + bigint conversion error).


	EXEC [USP_UpdateStocklineDraftForIsSerialized] 158,0, 12084,11

**************************************************************/
CREATE     PROCEDURE [dbo].[USP_UpdateStocklineDraftForIsSerialized]
(
 @ItemMasterId BIGINT NULL,
 @Active bit NULL,
 @PurchaseOrderId BIGINT NULL,
 @ItemTypeId INT NULL
)
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
 BEGIN TRY
    BEGIN TRANSACTION
	BEGIN
		DECLARE @StockItemId BIGINT;
		DECLARE @NonStockItemId BIGINT;
		DECLARE @AssetItemId BIGINT;

		DECLARE @IsNonStockDraft BIT = 0;
		DECLARE @GroupIndex INT = 1;
		DECLARE @PurchaseOrderPartRecordId BIGINT;
		DECLARE @MainDraftId BIGINT;
		DECLARE @TotalQty DECIMAL(18,6);
		DECLARE @IntegerPart INT;
		DECLARE @DecimalPart DECIMAL(18,6);
		DECLARE @ChildCount INT;
		DECLARE @LastChildId BIGINT;
		DECLARE @EntityMSID BIGINT;
		DECLARE @MasterCompanyId INT;
		DECLARE @CreatedBy VARCHAR(256);
		DECLARE @IdCodeTypeId BIGINT;
		DECLARE @CurrentIdNumber BIGINT;
		DECLARE @IdNumber VARCHAR(50);
		DECLARE @CodePrefix NVARCHAR(50);
		DECLARE @CodeSufix NVARCHAR(50);
		DECLARE @NewChildCount INT;
		DECLARE @NewChildIndex INT;
		DECLARE @NewChildDraftId BIGINT;

		SET @StockItemId = (SELECT ItemTypeId FROM ItemType WHERE Description = 'Stock')
		SET @NonStockItemId = (SELECT ItemTypeId FROM ItemType WHERE Description = 'Non-Stock')
		SET @AssetItemId = (SELECT ItemTypeId FROM ItemType WHERE Description = 'Asset')

		IF @ItemMasterId > 0
		BEGIN
			IF (@ItemTypeId = @StockItemId OR @ItemTypeId = @NonStockItemId)
				BEGIN
					SET @IsNonStockDraft = CASE WHEN @ItemTypeId = @NonStockItemId THEN 1 ELSE 0 END;

					IF OBJECT_ID(N'tempdb..#SerializedDraftGroups') IS NOT NULL
					BEGIN
						DROP TABLE #SerializedDraftGroups
					END
					IF OBJECT_ID(N'tempdb..#ChildDrafts') IS NOT NULL
					BEGIN
						DROP TABLE #ChildDrafts
					END
					IF OBJECT_ID(N'tempdb..#NewChildDrafts') IS NOT NULL
					BEGIN
						DROP TABLE #NewChildDrafts
					END
					IF OBJECT_ID(N'tempdb..#MainDraftCopy') IS NOT NULL
					BEGIN
						DROP TABLE #MainDraftCopy
					END

					CREATE TABLE #SerializedDraftGroups
					(
						ID INT NOT NULL IDENTITY,
						PurchaseOrderPartRecordId BIGINT NULL,
						MainDraftId BIGINT NOT NULL,
						HasReceivedRows BIT NOT NULL
					)

					CREATE TABLE #ChildDrafts
					(
						StockLineDraftId BIGINT NOT NULL
					)

					CREATE TABLE #NewChildDrafts
					(
						ID INT NOT NULL IDENTITY,
						StockLineDraftId BIGINT NOT NULL
					)

					-- One group per PO part line of this item on this PO. The MAIN row is the first draft row created for the line
					-- (lowest StockLineDraftId, same as index 0 on the Receiving PO page); every other row of the line is a child row.
					INSERT INTO #SerializedDraftGroups (PurchaseOrderPartRecordId, MainDraftId, HasReceivedRows)
					SELECT SD.PurchaseOrderPartRecordId,
						MIN(SD.StockLineDraftId),
						MAX(CASE WHEN SD.StockLineId IS NOT NULL OR SD.StockLineNumber IS NOT NULL THEN 1 ELSE 0 END)
					FROM [dbo].[StocklineDraft] SD WITH(NOLOCK)
					WHERE SD.ItemMasterId = @ItemMasterId
						AND SD.PurchaseOrderId = @PurchaseOrderId
						AND ISNULL(SD.IsNonStock, 0) = @IsNonStockDraft
					GROUP BY SD.PurchaseOrderPartRecordId

					SELECT @IdCodeTypeId = CodeTypeId FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE CodeType = 'Id Number';

					WHILE (@GroupIndex <= (SELECT MAX(ID) FROM #SerializedDraftGroups))
					BEGIN
						SET @PurchaseOrderPartRecordId = NULL;
						SET @MainDraftId = NULL;

						-- Lines that already have received (stockline created) rows are left untouched.
						SELECT @PurchaseOrderPartRecordId = PurchaseOrderPartRecordId, @MainDraftId = MainDraftId
						FROM #SerializedDraftGroups WHERE ID = @GroupIndex AND HasReceivedRows = 0;

						IF (@MainDraftId IS NOT NULL)
						BEGIN
							TRUNCATE TABLE #ChildDrafts;
							TRUNCATE TABLE #NewChildDrafts;

							INSERT INTO #ChildDrafts (StockLineDraftId)
							SELECT SD.StockLineDraftId
							FROM [dbo].[StocklineDraft] SD WITH(NOLOCK)
							WHERE SD.ItemMasterId = @ItemMasterId
								AND SD.PurchaseOrderId = @PurchaseOrderId
								AND ISNULL(SD.IsNonStock, 0) = @IsNonStockDraft
								AND ISNULL(SD.PurchaseOrderPartRecordId, 0) = ISNULL(@PurchaseOrderPartRecordId, 0)
								AND SD.StockLineDraftId <> @MainDraftId
								AND SD.StockLineId IS NULL AND SD.StockLineNumber IS NULL

							IF (@Active = 1)
							BEGIN
								-- Non-Serialized -> Serialized : main row (IsParent = 0) + one child row (IsParent = 1) per unit
								UPDATE [dbo].[StocklineDraft]
								SET isSerialized = 1,
									IsParent = 0,
									ParentId = 0,
									UpdatedDate = GETUTCDATE()
								WHERE StockLineDraftId = @MainDraftId

								IF NOT EXISTS (SELECT 1 FROM #ChildDrafts)
								BEGIN
									SELECT @TotalQty = ISNULL(Quantity, 0), @EntityMSID = ManagementStructureEntityId,
										@MasterCompanyId = MasterCompanyId, @CreatedBy = CreatedBy
									FROM [dbo].[StocklineDraft] WITH(NOLOCK) WHERE StockLineDraftId = @MainDraftId;

									SET @IntegerPart = FLOOR(@TotalQty);
									SET @DecimalPart = @TotalQty - @IntegerPart;
									SET @ChildCount = @IntegerPart + CASE WHEN @DecimalPart > 0 THEN 1 ELSE 0 END;

									IF (@ChildCount > 0)
									BEGIN
										-- ID Number for the child rows (same rule as SaveReceivingToStocklineDraft : current number + 1)
										SET @IdNumber = NULL;
										SET @CurrentIdNumber = NULL;

										SELECT TOP 1 @CurrentIdNumber = CASE WHEN CP.CurrentNummber > 0 THEN CAST(CP.CurrentNummber AS BIGINT) + 1 ELSE CAST(CP.StartsFrom AS BIGINT) + 1 END,
											@CodePrefix = CP.CodePrefix, @CodeSufix = CP.CodeSufix
										FROM [dbo].[CodePrefixes] CP WITH(NOLOCK)
										WHERE CP.CodeTypeId = @IdCodeTypeId AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

										IF (@CurrentIdNumber IS NOT NULL)
										BEGIN
											SET @IdNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](@CurrentIdNumber, @CodePrefix, @CodeSufix))
										END

										-- Child rows are copies of the main row (same PO part, condition, traceability, management structure, etc.)
										IF OBJECT_ID(N'tempdb..#MainDraftCopy') IS NOT NULL
										BEGIN
											DROP TABLE #MainDraftCopy
										END

										SELECT * INTO #MainDraftCopy FROM [dbo].[StocklineDraft] WITH(NOLOCK) WHERE StockLineDraftId = @MainDraftId
										ALTER TABLE #MainDraftCopy DROP COLUMN StockLineDraftId

										INSERT INTO [dbo].[StocklineDraft]
										OUTPUT INSERTED.StockLineDraftId INTO #NewChildDrafts (StockLineDraftId)
										SELECT C.*
										FROM #MainDraftCopy C
										CROSS JOIN (SELECT TOP (@ChildCount) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Num
													FROM sys.all_columns A CROSS JOIN sys.all_columns B) N

										SELECT @LastChildId = MAX(StockLineDraftId) FROM #NewChildDrafts;

										-- ParentId / StockLineDraftNumber are reset exactly like SaveReceivingToStocklineDraft (ParentId = 0, 'STL_DRFT-000000'); the real StockLineDraftNumber
										-- and the ParentId link (UpdateStocklineDraftDetail) are generated again when the draft is saved from the Receiving PO page.
										-- Each child holds 1 unit; the decimal remainder (if any) goes on the last child, same as SaveReceivingToStocklineDraft
										UPDATE SD
										SET SD.Quantity = CASE WHEN SD.StockLineDraftId = @LastChildId AND @DecimalPart > 0 THEN @DecimalPart ELSE 1 END,
											SD.QuantityOnHand = CASE WHEN SD.StockLineDraftId = @LastChildId AND @DecimalPart > 0 THEN @DecimalPart ELSE 1 END,
											SD.QuantityAvailable = CASE WHEN SD.StockLineDraftId = @LastChildId AND @DecimalPart > 0 THEN @DecimalPart ELSE 1 END,
											SD.QuantityToReceive = CASE WHEN SD.StockLineDraftId = @LastChildId AND @DecimalPart > 0 THEN @DecimalPart ELSE 1 END,
											SD.PurchaseOrderExtendedCost = ISNULL(SD.PurchaseOrderUnitCost, 0),
											SD.IsParent = 1,
											SD.isSerialized = 1,
											SD.ParentId = 0,
											SD.StockLineDraftNumber = 'STL_DRFT-000000',
											SD.SerialNumber = '',
											SD.IdNumber = ISNULL(@IdNumber, SD.IdNumber),
											SD.CreatedDate = GETUTCDATE(),
											SD.UpdatedDate = GETUTCDATE()
										FROM [dbo].[StocklineDraft] SD
										INNER JOIN #NewChildDrafts N ON N.StockLineDraftId = SD.StockLineDraftId

										-- Management Structure details for every new child row
										SELECT @NewChildCount = COUNT(1) FROM #NewChildDrafts;
										SET @NewChildIndex = 1;

										WHILE (@NewChildIndex <= @NewChildCount)
										BEGIN
											SELECT @NewChildDraftId = StockLineDraftId FROM #NewChildDrafts WHERE ID = @NewChildIndex;

											IF (@EntityMSID IS NOT NULL)
											BEGIN
												EXEC [dbo].[PROCAddStockLineDraftMSData] @NewChildDraftId, @EntityMSID, @MasterCompanyId, @CreatedBy, @CreatedBy, 31, 1;
											END

											SET @NewChildIndex = @NewChildIndex + 1;
										END
									END
								END
								ELSE
								BEGIN
									-- Child rows already exist (already Serialized) : only make sure the flags are correct
									UPDATE SD
									SET SD.isSerialized = 1,
										SD.IsParent = 1
									FROM [dbo].[StocklineDraft] SD
									INNER JOIN #ChildDrafts C ON C.StockLineDraftId = SD.StockLineDraftId
								END
							END
							ELSE
							BEGIN
								-- Serialized -> Non-Serialized : delete the child rows and keep the main row with the full quantity
								DELETE MS
								FROM [dbo].[StockLineDraftManagementStructureDetails] MS
								INNER JOIN #ChildDrafts C ON C.StockLineDraftId = MS.ReferenceID
								WHERE MS.ModuleID = 31

								DELETE TL
								FROM [dbo].[TimeLifeDraft] TL
								INNER JOIN #ChildDrafts C ON C.StockLineDraftId = TL.StockLineDraftId

								DELETE SD
								FROM [dbo].[StocklineDraft] SD
								INNER JOIN #ChildDrafts C ON C.StockLineDraftId = SD.StockLineDraftId

								UPDATE [dbo].[StocklineDraft]
								SET isSerialized = 0,
									IsParent = 1,
									ParentId = 0,
									SerialNumber = '',
									UpdatedDate = GETUTCDATE()
								WHERE StockLineDraftId = @MainDraftId
							END
						END

						SET @GroupIndex = @GroupIndex + 1;
					END
				END
			IF(@ItemTypeId = @AssetItemId)
				BEGIN
					UPDATE [dbo].[AssetInventoryDraft]
					SET isSerialized = @Active ,
					IsParent = CASE WHEN IsParent = 1 THEN 0 Else 1 END
					WHERE AssetRecordId = @ItemMasterId AND PurchaseOrderId = @PurchaseOrderId
				END
		END
	END
    COMMIT TRANSACTION

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
    ERROR_MESSAGE() AS ErrorMessage;

   DECLARE @ErrorLogID int
   ,@DatabaseName varchar(100) = DB_NAME()
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
   ,@AdhocComments varchar(150) = 'USP_UpdateStocklineDraftForIsSerialized'
   ,@ProcedureParameters varchar(3000) = '@ItemMasterId = ' + ISNULL(CAST(@ItemMasterId AS VARCHAR(20)), '') + ', @Active = ' + ISNULL(CAST(@Active AS VARCHAR(5)), '') + ', @PurchaseOrderId = ' + ISNULL(CAST(@PurchaseOrderId AS VARCHAR(20)), '') + ', @ItemTypeId = ' + ISNULL(CAST(@ItemTypeId AS VARCHAR(20)), '')
   ,@ApplicationName varchar(100) = 'PAS'
   -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
   EXEC spLogException @DatabaseName = @DatabaseName,
    @AdhocComments = @AdhocComments,
    @ProcedureParameters = @ProcedureParameters,
    @ApplicationName = @ApplicationName,
    @ErrorLogID = @ErrorLogID OUTPUT;
   RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
   RETURN (1);
  END CATCH
END
