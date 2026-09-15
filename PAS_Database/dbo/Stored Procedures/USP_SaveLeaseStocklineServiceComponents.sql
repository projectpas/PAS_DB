/*************************************************************
 ** File:   [USP_SaveLeaseStocklineServiceComponents]
 ** Description: Saves the full set of dynamic/custom-named Service Component
 **              rows (Name/Amount/Per) for a single LeaseStockline in one call -
 **              inserts new rows (LeaseStocklineServiceComponentId = 0/NULL),
 **              updates existing ones, and soft-deletes any row flagged
 **              IsDeleted = 1 (removed by the user in the popup). Deliberately
 **              separate from the fixed Maintenance/Insurance/Taxes columns on
 **              LeaseStockline (USP_UpdateLeaseStockLineServiceComponent) -
 **              those are untouched by this SP.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    14/09/2026     Amit Ghediya            Created

DECLARE @Components dbo.LeaseStocklineServiceComponentType;
INSERT INTO @Components (LeaseStocklineServiceComponentId, ComponentName, Amount, Per, IsDeleted)
VALUES (0, N'Storage Fee', 500, N'Monthly', 0);
exec USP_SaveLeaseStocklineServiceComponents @LeaseStocklineId=1, @Components=@Components, @MasterCompanyId=1, @UpdatedBy='test'
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_SaveLeaseStocklineServiceComponents]
	@LeaseStocklineId BIGINT,
	@Components [dbo].[LeaseStocklineServiceComponentType] READONLY,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		-- SQL Server's MERGE only allows a second WHEN MATCHED clause if it's a DELETE,
		-- so the soft-delete (an UPDATE) can't share this MERGE with the normal-field
		-- UPDATE - handled as a separate UPDATE statement below instead.
		MERGE [dbo].[LeaseStocklineServiceComponent] AS TARGET
		USING (SELECT * FROM @Components WHERE ISNULL(IsDeleted, 0) = 0) AS SOURCE
			ON TARGET.LeaseStocklineServiceComponentId = SOURCE.LeaseStocklineServiceComponentId
			AND TARGET.LeaseStocklineId = @LeaseStocklineId
		WHEN MATCHED THEN
			UPDATE SET
				ComponentName = SOURCE.ComponentName,
				Amount        = SOURCE.Amount,
				Per           = SOURCE.Per,
				UpdatedBy     = @UpdatedBy,
				UpdatedDate   = GETUTCDATE()
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (LeaseStocklineId, ComponentName, Amount, Per, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)
			VALUES (@LeaseStocklineId, SOURCE.ComponentName, SOURCE.Amount, SOURCE.Per, @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);

		UPDATE T
			SET T.IsDeleted   = 1,
				T.UpdatedBy   = @UpdatedBy,
				T.UpdatedDate = GETUTCDATE()
		FROM [dbo].[LeaseStocklineServiceComponent] T
		INNER JOIN @Components S ON S.LeaseStocklineServiceComponentId = T.LeaseStocklineServiceComponentId
		WHERE T.LeaseStocklineId = @LeaseStocklineId AND ISNULL(S.IsDeleted, 0) = 1;

		SELECT LeaseStocklineServiceComponentId, LeaseStocklineId, ComponentName, Amount, Per
		FROM [dbo].[LeaseStocklineServiceComponent] WITH (NOLOCK)
		WHERE LeaseStocklineId = @LeaseStocklineId AND IsDeleted = 0
		ORDER BY LeaseStocklineServiceComponentId;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_SaveLeaseStocklineServiceComponents]',
            @ProcedureParameters varchar(3000) = '@LeaseStocklineId = ''' + CAST(ISNULL(@LeaseStocklineId, 0) AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
	END CATCH
END
