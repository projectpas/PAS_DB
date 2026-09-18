/*************************************************************
 ** File:   [USP_SaveLeaseCharges]
 ** Description: Saves the full batch of charge rows submitted from the
 **              "Add/Edit Charges" popup in one call - inserts new rows
 **              (LeaseChargesId = 0/NULL), updates existing ones, and
 **              soft-deletes any row flagged IsDeleted = 1. Handles both
 **              the multi-row "Add Charges" flow and the single-row Edit
 **              flow (same shape, just a 1-row batch).
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    17/09/2026     Amit Ghediya            Created

DECLARE @Charges dbo.LeaseChargesType;
INSERT INTO @Charges (LeaseChargesId, LeaseStocklineId, ReportedDate, ChargesTypeId, Description, UOMId, Quantity, UnitCost, ExtendedCost, VendorId, IsDeleted)
VALUES (0, 11, GETUTCDATE(), 1, N'Freight', NULL, 2, 100, 200, NULL, 0);
exec USP_SaveLeaseCharges @LeaseHeaderId=9, @Charges=@Charges, @MasterCompanyId=1, @UpdatedBy='test'
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_SaveLeaseCharges]
	@LeaseHeaderId BIGINT,
	@Charges [dbo].[LeaseChargesType] READONLY,
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
		MERGE [dbo].[LeaseCharges] AS TARGET
		USING (SELECT * FROM @Charges WHERE ISNULL(IsDeleted, 0) = 0) AS SOURCE
			ON TARGET.LeaseChargesId = SOURCE.LeaseChargesId
			AND TARGET.LeaseHeaderId = @LeaseHeaderId
		WHEN MATCHED THEN
			UPDATE SET
				LeaseStocklineId = SOURCE.LeaseStocklineId,
				ReportedDate     = SOURCE.ReportedDate,
				ChargesTypeId    = SOURCE.ChargesTypeId,
				Description      = SOURCE.Description,
				UOMId            = SOURCE.UOMId,
				Quantity         = SOURCE.Quantity,
				UnitCost         = SOURCE.UnitCost,
				ExtendedCost     = SOURCE.ExtendedCost,
				VendorId         = SOURCE.VendorId,
				UpdatedBy        = @UpdatedBy,
				UpdatedDate      = GETUTCDATE()
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (LeaseHeaderId, LeaseStocklineId, ReportedDate, ChargesTypeId, Description, UOMId, Quantity, UnitCost, ExtendedCost, VendorId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)
			VALUES (@LeaseHeaderId, SOURCE.LeaseStocklineId, SOURCE.ReportedDate, SOURCE.ChargesTypeId, SOURCE.Description, SOURCE.UOMId, SOURCE.Quantity, SOURCE.UnitCost, SOURCE.ExtendedCost, SOURCE.VendorId, @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);

		UPDATE T
			SET T.IsDeleted   = 1,
				T.UpdatedBy   = @UpdatedBy,
				T.UpdatedDate = GETUTCDATE()
		FROM [dbo].[LeaseCharges] T
		INNER JOIN @Charges S ON S.LeaseChargesId = T.LeaseChargesId
		WHERE T.LeaseHeaderId = @LeaseHeaderId AND ISNULL(S.IsDeleted, 0) = 1;

		SELECT
			LC.LeaseChargesId,
			LC.LeaseStocklineId,
			LSL.PN AS PartNumber,
			SLIVE.SerialNumber,
			LC.ReportedDate,
			LC.ChargesTypeId,
			CH.ChargeType,
			ISNULL(GL.AccountName, '') AS GLAccountName,
			LC.Description,
			LC.UOMId,
			ISNULL(UOM.ShortName, '') AS UOM,
			LC.Quantity,
			LC.UnitCost,
			LC.ExtendedCost,
			LC.VendorId,
			V.VendorName
		FROM [dbo].[LeaseCharges] LC WITH (NOLOCK)
		JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.LeaseStocklineId = LC.LeaseStocklineId
		LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
		JOIN [dbo].[Charge] CH WITH (NOLOCK) ON CH.ChargeId = LC.ChargesTypeId
		LEFT JOIN [dbo].[GLAccount] GL WITH (NOLOCK) ON GL.GLAccountId = CH.GLAccountId
		LEFT JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = LC.UOMId
		LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON V.VendorId = LC.VendorId
		WHERE LC.LeaseHeaderId = @LeaseHeaderId AND LC.IsDeleted = 0
		ORDER BY LC.LeaseChargesId;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_SaveLeaseCharges]',
            @ProcedureParameters varchar(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS varchar(100)),
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
