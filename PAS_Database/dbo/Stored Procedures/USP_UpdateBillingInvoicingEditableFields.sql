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
    @SoldToCustomerId BIGINT = NULL,
    @SoldToSiteId BIGINT = NULL,
    @ShipToCustomerId BIGINT = NULL,
    @ShipToSiteId BIGINT = NULL,
    @ShipviaId INT = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @UpdatedBy VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY

		UPDATE [dbo].[BillingInvoicing]
		SET [InvoiceDate] = @InvoiceDate,
			[Notes] = ISNULL(@Notes, [Notes]),
			[InvoiceFilePath] = NULL,
			[UpdatedBy] = @UpdatedBy,
			[UpdatedDate] = GETUTCDATE()
		WHERE [BillingInvoicingId] = @BillingInvoicingId;

		UPDATE [dbo].[BillingInvoicingDetails]
		SET [SoldToCustomerId] = COALESCE(@SoldToCustomerId, [SoldToCustomerId]),
			[SoldToSiteId] = COALESCE(@SoldToSiteId, [SoldToSiteId]),
			[ShipToCustomerId] = COALESCE(@ShipToCustomerId, [ShipToCustomerId]),
			[ShipToSiteId] = COALESCE(@ShipToSiteId, [ShipToSiteId]),
			[ShipviaId] = COALESCE(@ShipviaId, [ShipviaId])
		WHERE [BillingInvoicingId] = @BillingInvoicingId;

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