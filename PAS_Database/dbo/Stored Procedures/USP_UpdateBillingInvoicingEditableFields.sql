/*************************************************************           
 ** File:   [USP_UpdateBillingInvoicingEditableFields]           
 ** Author:   Vishal Suthar
 ** Description: Update Billing Invoice Fields
 ** Purpose:         
 ** Date:   11/09/2026
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    11/09/2026		Vishal Suthar	Created

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateBillingInvoicingEditableFields]
    @BillingInvoicingId BIGINT,
    @InvoiceDate DATETIME,
    @AccountingPeriodId INT = NULL,
    @UpdatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY

		UPDATE BillingInvoicing
		SET InvoiceDate = @InvoiceDate,
			UpdatedBy = @UpdatedBy,
			UpdatedDate = GETDATE()
		WHERE BillingInvoicingId = @BillingInvoicingId;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
				@AdhocComments VARCHAR(150) = 'USP_UpdateBillingInvoicingEditableFields',
				@ProcedureParameters VARCHAR(3000) = '@BillingInvoicingId = ' + CAST(ISNULL(@BillingInvoicingId,0) AS VARCHAR(50)) + ', @InvoiceDate = ' + ISNULL(CONVERT(VARCHAR(50), @InvoiceDate, 121), ''),
				@ApplicationName VARCHAR(100) = 'PAS';

		EXEC spLogException
			@DatabaseName = @DatabaseName,
			@AdhocComments = @AdhocComments,
			@ProcedureParameters = @ProcedureParameters,
			@ApplicationName = @ApplicationName,
			@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END