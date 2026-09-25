
/***************************************************************
 ** File:  [USP_SaveLeasePackagingSlip]
 ** Author:   Moin Bloch
 ** Description: Save (generate) a Lease Packing Slip for the selected, already-shipped pick-ticket
 **              lines - mirrors app-work-order-shipping's USP_SaveWorkOrderPackaginSlip, simplified
 **              since Lease has no per-part settlement concept to update. Re-generating a slip for a
 **              pick-ticket line that already has one moves it to a fresh slip number (same as WO).
 ** Date:  25-Sep-2026
 ** Change History
 *******************************************************************************************
 ** PR   Date				Author  				Change Description
 ** --   --------			-------				--------------------------------
    1    25-Sep-2026		Moin Bloch			Created
    2    25-Sep-2026		Moin Bloch			Added LeaseStocklineId passthrough (LeasePackagingSlipItem)

*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveLeasePackagingSlip]
	@Items dbo.LeasePackagingSlipItemsType READONLY,
	@LeaseHeaderId BIGINT,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION

		IF NOT EXISTS (SELECT 1 FROM @Items)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT CAST(0 AS BIT) AS [Status], 'No lines selected to generate a packing slip.' AS [Message],
			       CAST(0 AS BIGINT) AS PackagingSlipId, CAST('' AS VARCHAR(50)) AS PackagingSlipNo;
			RETURN;
		END

		DECLARE @PackingSlipCodeTypeId BIGINT = (SELECT [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Packaging Slip');
		DECLARE @CurrentNo BIGINT, @CodePrefix VARCHAR(10), @CodeSuffix VARCHAR(10);
		DECLARE @Generated TABLE (CurrentNummber BIGINT, CodePrefix VARCHAR(10), CodeSufix VARCHAR(10));

		UPDATE [dbo].[CodePrefixes]
		SET [CurrentNummber] = CASE WHEN ISNULL([CurrentNummber], 0) > 0
									THEN ISNULL([CurrentNummber], 0) + 1
									ELSE ISNULL([StartsFrom], 0) + 1
							   END
		OUTPUT inserted.[CurrentNummber], inserted.[CodePrefix], inserted.[CodeSufix] INTO @Generated
		WHERE [CodeTypeId]      = @PackingSlipCodeTypeId
		  AND [MasterCompanyId] = @MasterCompanyId
		  AND [IsActive]        = 1
		  AND [IsDeleted]       = 0;

		DECLARE @PackagingSlipNo VARCHAR(50);
		IF EXISTS (SELECT 1 FROM @Generated)
		BEGIN
			SELECT TOP 1 @CurrentNo = [CurrentNummber], @CodePrefix = ISNULL([CodePrefix], ''), @CodeSuffix = ISNULL([CodeSufix], '') FROM @Generated;
			SELECT @PackagingSlipNo = CAST(gen.StocklineNumber AS VARCHAR(50)) FROM [dbo].[udfGenerateCodeNumberWithOutDash](@CurrentNo, @CodePrefix, @CodeSuffix) gen;
		END
		ELSE
		BEGIN
			SELECT @PackagingSlipNo = CAST(gen.StocklineNumber AS VARCHAR(50)) FROM [dbo].[udfGenerateCodeNumberWithOutDash](0, '', '') gen;
		END

		-- Any of these pick-ticket lines already assigned to an older slip move to the new one.
		DELETE LPI
		FROM [dbo].[LeasePackagingSlipItem] LPI
		INNER JOIN @Items src ON src.[LeasePickTicketId] = LPI.[LeasePickTicketId]
		WHERE LPI.[IsDeleted] = 0;

		-- Clean up any header left with zero items after the move above.
		DELETE H
		FROM [dbo].[LeasePackagingSlipHeader] H
		WHERE NOT EXISTS (SELECT 1 FROM [dbo].[LeasePackagingSlipItem] I WHERE I.[PackagingSlipId] = H.[PackagingSlipId] AND I.[IsDeleted] = 0);

		INSERT INTO [dbo].[LeasePackagingSlipHeader] ([LeaseHeaderId], [PackagingSlipNo], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
		VALUES (@LeaseHeaderId, @PackagingSlipNo, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);

		DECLARE @PackagingSlipId BIGINT = SCOPE_IDENTITY();

		INSERT INTO [dbo].[LeasePackagingSlipItem] ([PackagingSlipId], [LeasePickTicketId], [LeaseStocklineId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
		SELECT @PackagingSlipId, [LeasePickTicketId], [LeaseStocklineId], [MasterCompanyId], [CreatedBy], [UpdatedBy], GETUTCDATE(), GETUTCDATE(), 1, 0
		FROM @Items;

		COMMIT TRANSACTION

		SELECT CAST(1 AS BIT) AS [Status], 'Success' AS [Message], @PackagingSlipId AS PackagingSlipId, @PackagingSlipNo AS PackagingSlipNo;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_SaveLeasePackagingSlip]',
			@ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100)),
			@ApplicationName VARCHAR(100) = 'PAS'
		EXEC spLogException @DatabaseName = @DatabaseName,
							@AdhocComments = @AdhocComments,
							@ProcedureParameters = @ProcedureParameters,
							@ApplicationName = @ApplicationName,
							@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END