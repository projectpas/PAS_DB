/*************************************************************
 ** File:   [USP_UpdateLeaseAgreementPDF]
 ** Description: Stores the generated PDF file name / path on the saved Lease Agreement version.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    02/11/2026     Rajesh Gami             [PN-18468] Created - Lease Agreement PDF path

exec USP_UpdateLeaseAgreementPDF @LeaseAgreementId=1, @PDFFileName='LSE-000001_Agreement_V1.Pdf', @PDFPath='/1/Leasing/LSE-000001/LSE-000001_Agreement_V1.Pdf', @UpdatedBy='Jim Roberts'
************************************************************************/
CREATE PROCEDURE [dbo].[USP_UpdateLeaseAgreementPDF]
	@LeaseAgreementId BIGINT,
	@PDFFileName VARCHAR(256),
	@PDFPath NVARCHAR(1000),
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

		UPDATE [dbo].[LeaseAgreement]
		SET [PDFFileName] = @PDFFileName,
			[PDFPath]     = @PDFPath,
			[UpdatedBy]   = @UpdatedBy,
			[UpdatedDate] = GETUTCDATE()
		WHERE [LeaseAgreementId] = @LeaseAgreementId
		  AND [IsDeleted] = 0;

		DECLARE @RowsUpdated INT = @@ROWCOUNT;

	COMMIT TRANSACTION;
	SELECT CASE WHEN @RowsUpdated > 0 THEN 1 ELSE 0 END AS [Status];

	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0)
			ROLLBACK TRANSACTION;

		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_UpdateLeaseAgreementPDF]',
			@ProcedureParameters VARCHAR(3000) = '@LeaseAgreementId = ''' + CAST(ISNULL(@LeaseAgreementId, 0) AS VARCHAR(100))
											   + ''', @PDFFileName = ''' + ISNULL(@PDFFileName, ''),
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
