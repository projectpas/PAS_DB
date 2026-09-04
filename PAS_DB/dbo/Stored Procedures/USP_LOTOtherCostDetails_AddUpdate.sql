/*************************************************************
 ** File:   [USP_LOTOtherCostDetails_AddUpdate]
 ** Author: RAJESH GAMI
 ** Description: [PN-17853] Add or Update a manually-entered Freight/Other-Cost row on the Lot's Other
 **              Cost tab. Denormalized Part/Stockline/Condition fields are looked up server-side from
 **              @ItemMasterId/@StocklineId (when NA is not selected) so the caller only has to pass ids.
 **              Reconciled Freight/Charges are re-derived from Stockline.FreightAdjustment/MiscAdjustment
 **              server-side too (not trusted from the client) so they always match the current Stockline
 **              values. TotalFreight/TotalOtherCost are computed here, not by the caller.
 ** Date:   02-Sep-2026 (updated 03-Sep-2026)
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author  		Change Description
 ** --   --------     -------		---------------------------
    1    02-Sep-2026  RAJESH GAMI     [PN-17853] Created
    2    03-Sep-2026  RAJESH GAMI     [PN-17853] Always persist ModuleId/ModuleName = 'SalesOrder' (Part/
                                      Stockline dropdowns are now scoped to Sales Activity/sold parts only,
                                      so every manual Other Cost row - including NA rows - is an SO-context
                                      entry now, per Rajesh)
    3    03-Sep-2026  RAJESH GAMI     [PN-17853] Now also derives and persists ReferenceId/ReferenceNumber/
                                      ReferenceDate (SalesOrderId/SalesOrderNumber/SO CreatedDate) off the
                                      selected Stockline's Trans Out(SO) LotCalculationDetails record, so the
                                      Other Cost grid can show which Sales Order a manual row belongs to
                                      (Rajesh, 03-Sep-2026 - also drives the 'SO-xxxx (Manual Entry)' PoNum
                                      label in USP_Lot_GetAllLotViewsByLotId_Filter's OtherCost branch)
**************************************************************
 EXEC USP_LOTOtherCostDetails_AddUpdate
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_LOTOtherCostDetails_AddUpdate]
@LotOtherCostDetailId bigint OUTPUT,
@LotId bigint,
@StocklineId bigint = NULL,
@ItemMasterId bigint = NULL,
@IsNA bit = 0,
@UnReconciledFreight decimal(18,2) = NULL,
@ManualAdjFreight decimal(18,2) = NULL,
@UnReconciledCharges decimal(18,2) = NULL,
@ManualAdjCharges decimal(18,2) = NULL,
@Memo nvarchar(max) = NULL,
@MasterCompanyId int,
@CreatedBy varchar(256)
AS
BEGIN
  SET NOCOUNT ON;

  -- [PN-17853] Memo is mandatory when the part is selected as NA (Rajesh, 02-Sep-2026 - overrides the xlsx
  -- text which said Description; Memo is the field that is required). Checked BEFORE the TRY/CATCH below on
  -- purpose, so this specific message propagates to the caller as-is instead of being swallowed by the
  -- generic "Unexpected Error Occured..." wrapper in the CATCH block. This is a defense-in-depth backstop -
  -- the Angular Add/Edit popup is expected to enforce this same rule client-side before ever calling here.
  IF (ISNULL(@IsNA,0) = 1 AND (LTRIM(RTRIM(ISNULL(@Memo,''))) = ''))
  BEGIN
	  RAISERROR ('Memo is required when the Part Number is NA.', 16, 1);
	  RETURN (1);
  END

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN

		DECLARE @LotNumber varchar(200) = NULL;
		SELECT @LotNumber = LotNumber FROM [dbo].[Lot] WITH(NOLOCK) WHERE LotId = @LotId;

		-- [PN-17853] 03-Sep-2026: ModuleId/ModuleName are always 'SalesOrder' now - the Part/Stockline dropdowns
		-- feeding this popup are scoped to Sales Activity (sold) parts only, so every manual Other Cost row,
		-- NA included, is implicitly an SO-context entry.
		DECLARE @OtherCostModuleId int = NULL, @OtherCostModuleName varchar(100) = 'SalesOrder';
		SELECT @OtherCostModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

		DECLARE @StocklineNumber varchar(100) = NULL, @ConditionId bigint = NULL, @Condition varchar(200) = NULL;
		DECLARE @ReconciledFreight decimal(18,2) = 0, @ReconciledCharges decimal(18,2) = 0;
		IF (ISNULL(@IsNA,0) = 0 AND ISNULL(@StocklineId,0) > 0)
		BEGIN
			SELECT
				 @StocklineNumber = stk.StockLineNumber
				,@ConditionId = stk.ConditionId
				,@Condition = ISNULL(c.Description, stk.Condition)
				,@ReconciledFreight = ISNULL(stk.FreightAdjustment,0)
				,@ReconciledCharges = ISNULL(stk.MiscAdjustment,0)
			FROM [dbo].[Stockline] stk WITH(NOLOCK)
			LEFT JOIN [dbo].[Condition] c WITH(NOLOCK) ON c.ConditionId = stk.ConditionId
			WHERE stk.StockLineId = @StocklineId;
		END

		-- [PN-17853] 03-Sep-2026: ReferenceId/ReferenceNumber/ReferenceDate = the Sales Order this Stockline
		-- was actually sold on (Trans Out(SO)), same join/Type-literal pattern used elsewhere in this codebase
		-- (see USP_Lot_GetAllLotViewsByLotId_Filter's PNSoldView/OtherCost branches). Most recent SO wins if a
		-- Stockline was somehow sold more than once. NULL for NA rows (no Stockline selected).
		DECLARE @ReferenceId bigint = NULL, @ReferenceNumber varchar(100) = NULL, @ReferenceDate datetime2(7) = NULL;
		IF (ISNULL(@IsNA,0) = 0 AND ISNULL(@StocklineId,0) > 0)
		BEGIN
			SELECT TOP 1
				 @ReferenceId = so.SalesOrderId
				,@ReferenceNumber = so.SalesOrderNumber
				,@ReferenceDate = so.CreatedDate
			FROM [dbo].[LotTransInOutDetails] ltin WITH(NOLOCK)
			INNER JOIN [dbo].[LotCalculationDetails] ltCal WITH(NOLOCK) ON ltin.LotTransInOutId = ltCal.LotTransInOutId
				AND UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE('Trans Out(SO)',' ',''))
			INNER JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON ltCal.ReferenceId = so.SalesOrderId
			WHERE ltin.StockLineId = @StocklineId AND ltin.LotId = @LotId
			ORDER BY so.SalesOrderId DESC;
		END

		DECLARE @PartNumber varchar(200) = NULL, @PartDescription varchar(max) = NULL, @ManufacturerId bigint = NULL, @ManufacturerName varchar(200) = NULL;
		IF (ISNULL(@IsNA,0) = 0 AND ISNULL(@ItemMasterId,0) > 0)
		BEGIN
			SELECT
				 @PartNumber = im.PartNumber
				,@PartDescription = im.PartDescription
				,@ManufacturerId = im.ManufacturerId
				,@ManufacturerName = im.ManufacturerName
			FROM [dbo].[ItemMaster] im WITH(NOLOCK)
			WHERE im.ItemMasterId = @ItemMasterId;
		END
		ELSE IF (ISNULL(@IsNA,0) = 1)
		BEGIN
			SET @PartNumber = 'NA';
			SET @ItemMasterId = NULL;
			SET @StocklineId = NULL;
		END

		DECLARE @TotalFreight decimal(18,2) = ISNULL(@ReconciledFreight,0) + ISNULL(@UnReconciledFreight,0) + ISNULL(@ManualAdjFreight,0);
		DECLARE @TotalOtherCost decimal(18,2) = ISNULL(@ReconciledCharges,0) + ISNULL(@UnReconciledCharges,0) + ISNULL(@ManualAdjCharges,0);

		IF (ISNULL(@LotOtherCostDetailId,0) = 0)
		BEGIN
			INSERT INTO [dbo].[LOTOtherCostDetails]
				([LotId],[LotNumber],[ReconciledFreight],[UnReconciledFreight],[ManualAdjFreight],[TotalFreight]
				,[ReconciledCharges],[UnReconciledCharges],[ManualAdjCharges],[TotalOtherCost]
				,[StocklineId],[StocklineNumber],[ItemMasterId],[PartNumber],[PartDescription],[ManufacturerId],[ManufacturerName]
				,[ConditionId],[Condition],[IsNA],[ModuleId],[ModuleName]
				,[ReferenceId],[ReferenceNumber],[ReferenceDate],[Memo]
				,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
			VALUES
				(@LotId,@LotNumber,@ReconciledFreight,@UnReconciledFreight,@ManualAdjFreight,@TotalFreight
				,@ReconciledCharges,@UnReconciledCharges,@ManualAdjCharges,@TotalOtherCost
				,@StocklineId,@StocklineNumber,@ItemMasterId,@PartNumber,@PartDescription,@ManufacturerId,@ManufacturerName
				,@ConditionId,@Condition,@IsNA,@OtherCostModuleId,@OtherCostModuleName
				,@ReferenceId,@ReferenceNumber,@ReferenceDate,@Memo
				,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
			SET @LotOtherCostDetailId = SCOPE_IDENTITY();
		END
		ELSE
		BEGIN
			UPDATE [dbo].[LOTOtherCostDetails]
			   SET [ReconciledFreight] = @ReconciledFreight
			      ,[UnReconciledFreight] = @UnReconciledFreight
			      ,[ManualAdjFreight] = @ManualAdjFreight
			      ,[TotalFreight] = @TotalFreight
			      ,[ReconciledCharges] = @ReconciledCharges
			      ,[UnReconciledCharges] = @UnReconciledCharges
			      ,[ManualAdjCharges] = @ManualAdjCharges
			      ,[TotalOtherCost] = @TotalOtherCost
			      ,[StocklineId] = @StocklineId
			      ,[StocklineNumber] = @StocklineNumber
			      ,[ItemMasterId] = @ItemMasterId
			      ,[PartNumber] = @PartNumber
			      ,[PartDescription] = @PartDescription
			      ,[ManufacturerId] = @ManufacturerId
			      ,[ManufacturerName] = @ManufacturerName
			      ,[ConditionId] = @ConditionId
			      ,[Condition] = @Condition
			      ,[IsNA] = @IsNA
			      ,[ModuleId] = @OtherCostModuleId
			      ,[ModuleName] = @OtherCostModuleName
			      ,[ReferenceId] = @ReferenceId
			      ,[ReferenceNumber] = @ReferenceNumber
			      ,[ReferenceDate] = @ReferenceDate
			      ,[Memo] = @Memo
			      ,[UpdatedBy] = @CreatedBy
			      ,[UpdatedDate] = GETUTCDATE()
			 WHERE LotOtherCostDetailId = @LotOtherCostDetailId AND LotId = @LotId AND ISNULL(IsDeleted,0) = 0;
		END

		SELECT @LotOtherCostDetailId AS LotOtherCostDetailId
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_LOTOtherCostDetails_AddUpdate]',
            @ProcedureParameters varchar(3000) = '@LotOtherCostDetailId = ''' + CAST(ISNULL(@LotOtherCostDetailId, '') AS varchar(100))
            + '@LotId = ''' + CAST(ISNULL(@LotId, '') AS varchar(100))
            + '@StocklineId = ''' + CAST(ISNULL(@StocklineId, '') AS varchar(100))
            + '@ItemMasterId = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100))
            + '@CreatedBy = ''' + CAST(ISNULL(@CreatedBy, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
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