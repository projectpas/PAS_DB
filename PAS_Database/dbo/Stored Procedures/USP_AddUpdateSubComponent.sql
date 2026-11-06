/*************************************************************
 ** File:   [USP_AddUpdateSubComponent]
 ** Description: Adds (@SubComponentId = 0) or updates a Sub Component of a PN (Item Master > Sub Assembly > Sub Component). Returns the SubComponentId.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** -----------------------------------------------------------
    1    05/11/2026		Kishor Makwana		[PN-18497] Created
**************************************************************/
-- EXEC [dbo].[USP_AddUpdateSubComponent] @SubComponentId = 0, @ItemMasterId = 1, @MappingItemMasterId = 2, @Quantity = 1, @ConditionId = 1, @WorkscopeId = 1, @IsAutoCreateStockline = 0, @Memo = 'test', @MasterCompanyId = 1, @CreatedBy = 'ADMIN User', @UpdatedBy = 'ADMIN User'
CREATE   PROCEDURE [dbo].[USP_AddUpdateSubComponent]
	@SubComponentId BIGINT = 0,
	@ItemMasterId BIGINT,
	@MappingItemMasterId BIGINT,
	@Quantity BIGINT,
	@ConditionId BIGINT = NULL, -- [PN-18497] Condition is optional (NULL / 0 = no condition)
	@WorkscopeId BIGINT,
	@IsAutoCreateStockline BIT = 0,
	@Memo NVARCHAR(MAX) = NULL,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(256),
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	-- the same sub component PN / Condition / Workscope can be added only once to a PN
	IF EXISTS (SELECT 1 FROM [dbo].[SubComponent] WITH (NOLOCK)
		WHERE [ItemMasterId] = @ItemMasterId AND [MappingItemMasterId] = @MappingItemMasterId AND ISNULL([ConditionId], 0) = ISNULL(@ConditionId, 0) AND [WorkscopeId] = @WorkscopeId AND [SubComponentId] <> ISNULL(@SubComponentId, 0))
	BEGIN
		RAISERROR ('Record already exists', 16, 1);
		RETURN (1);
	END

	BEGIN TRY
		BEGIN TRANSACTION

		IF (ISNULL(@SubComponentId, 0) = 0)
		BEGIN
			INSERT INTO [dbo].[SubComponent] ([ItemMasterId], [MappingItemMasterId], [Quantity], [ConditionId], [WorkscopeId], [IsAutoCreateStockline], [Memo], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
			VALUES (@ItemMasterId, @MappingItemMasterId, @Quantity, NULLIF(@ConditionId, 0), @WorkscopeId, ISNULL(@IsAutoCreateStockline, 0), @Memo, @MasterCompanyId, @CreatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0);

			SET @SubComponentId = SCOPE_IDENTITY();
		END
		ELSE
		BEGIN
			UPDATE [dbo].[SubComponent]
			SET [MappingItemMasterId] = @MappingItemMasterId,
				[Quantity] = @Quantity,
				[ConditionId] = NULLIF(@ConditionId, 0),
				[WorkscopeId] = @WorkscopeId,
				[IsAutoCreateStockline] = ISNULL(@IsAutoCreateStockline, 0),
				[Memo] = @Memo,
				[UpdatedBy] = @UpdatedBy,
				[UpdatedDate] = GETUTCDATE()
			WHERE [SubComponentId] = @SubComponentId AND [MasterCompanyId] = @MasterCompanyId;
		END

		COMMIT TRANSACTION

		SELECT @SubComponentId AS [SubComponentId];
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
			, @AdhocComments VARCHAR(150) = 'USP_AddUpdateSubComponent'
			, @ProcedureParameters VARCHAR(3000) = '@SubComponentId = ' + CAST(ISNULL(@SubComponentId, 0) AS VARCHAR(20)) + ', @ItemMasterId = ' + CAST(ISNULL(@ItemMasterId, 0) AS VARCHAR(20))
			, @ApplicationName VARCHAR(100) = 'PAS'
		EXEC spLogException @DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END