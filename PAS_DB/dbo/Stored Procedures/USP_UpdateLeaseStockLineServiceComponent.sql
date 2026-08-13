/*************************************************************
 ** File:   [USP_UpdateLeaseStockLineServiceComponent]
 ** Description: Updates only the "Service Component" fields (Maintenance/Insurance/Taxes
 **              amount + billing interval) on an existing [LeaseStockline] row. Deliberately
 **              scoped to just these columns so it never touches Lease Properties or any
 **              other field.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    12/08/2026     Amit Ghediya            Created

exec USP_UpdateLeaseStockLineServiceComponent @LeaseStocklineId=1,
@Maintenance=0,@MaintenancePer=N'Monthly',@Insurance=0,@InsurancePer=N'Monthly',@Taxes=0,@TaxesPer=N'Monthly',@UpdatedBy=1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateLeaseStockLineServiceComponent]
	@LeaseStocklineId BIGINT,
	@Maintenance DECIMAL(18,2) = NULL,
	@MaintenancePer NVARCHAR(50) = NULL,
	@Insurance DECIMAL(18,2) = NULL,
	@InsurancePer NVARCHAR(50) = NULL,
	@Taxes DECIMAL(18,2) = NULL,
	@TaxesPer NVARCHAR(50) = NULL,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		UPDATE [dbo].[LeaseStockline]
		SET
			Maintenance    = @Maintenance,
			MaintenancePer = @MaintenancePer,
			Insurance      = @Insurance,
			InsurancePer   = @InsurancePer,
			Taxes          = @Taxes,
			TaxesPer       = @TaxesPer,
			UpdatedBy      = @UpdatedBy,
			UpdatedDate    = GETUTCDATE()
		WHERE LeaseStocklineId = @LeaseStocklineId;

		SELECT * FROM [dbo].[LeaseStockline] WITH (NOLOCK) WHERE LeaseStocklineId = @LeaseStocklineId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_UpdateLeaseStockLineServiceComponent]',
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