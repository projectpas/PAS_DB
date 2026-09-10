/*************************************************************
 ** File:   [USP_UpdateLeaseStockLineProperties]
 ** Description: Updates only the "Lease Properties" fields (pricing type/amount/rate unit,
 **              billing method/interval, thresholds & rates) on an existing [LeaseStockline]
 **              row. Deliberately scoped to just these columns so it never touches
 **              Service Component (Maintenance/Insurance/Taxes) or any other field.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    12/08/2026     Amit Ghediya            Created
    2    10/09/2026     Amit Ghediya            Threshold/rate/usage params widened from DECIMAL(18,2) to DECIMAL(18,6)
                                                 to match the LeaseStockline column precision - at (18,2) SQL Server
                                                 silently rounded HH:MM-derived values (e.g. 6h07m = 6.116667) down to
                                                 2 decimals before they ever reached the table, corrupting the minutes
                                                 on the next load

exec USP_UpdateLeaseStockLineProperties @LeaseStocklineId=1,@PricingMethod=N'FlatRate',@OutrightPrice=NULL,
@FlatRate=500,@RateUnit=N'Cycle',@BillingMethod=N'FlatRatePlusOverrun',@BillingInterval=N'Monthly',
@MinimumCycles=100,@MinimumTimes=50,@MaximumCycles=400,@MaximumTimes=200,
@UsagePerUnitCycles=12,@UsagePerUnitTimes=NULL,@OverrunPerUnitCycles=18,@OverrunPerUnitTimes=NULL,@UpdatedBy=''
************************************************************************/
CREATE    PROCEDURE [dbo].[USP_UpdateLeaseStockLineProperties]
	@LeaseStocklineId BIGINT,
	@PricingMethod NVARCHAR(100) = NULL,
	@OutrightPrice DECIMAL(18,2) = NULL,
	@FlatRate DECIMAL(18,2) = NULL,
	@RateUnit NVARCHAR(50) = NULL,
	@BillingMethod NVARCHAR(50) = NULL,
	@BillingInterval NVARCHAR(100) = NULL,
	@MinimumCycles DECIMAL(18,6) = NULL,
	@MinimumTimes DECIMAL(18,6) = NULL,
	@MaximumCycles DECIMAL(18,6) = NULL,
	@MaximumTimes DECIMAL(18,6) = NULL,
	@UsagePerUnitCycles DECIMAL(18,6) = NULL,
	@UsagePerUnitTimes DECIMAL(18,6) = NULL,
	@OverrunPerUnitCycles DECIMAL(18,6) = NULL,
	@OverrunPerUnitTimes DECIMAL(18,6) = NULL,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION

		UPDATE [dbo].[LeaseStockline]
		SET
			PricingMethod         = @PricingMethod,
			OutrightPrice         = @OutrightPrice,
			FlatRate              = @FlatRate,
			RateUnit              = @RateUnit,
			BillingMethod         = @BillingMethod,
			BillingInterval       = @BillingInterval,
			MinimumCycles         = @MinimumCycles,
			MinimumTimes          = @MinimumTimes,
			MaximumCycles         = @MaximumCycles,
			MaximumTimes          = @MaximumTimes,
			UsagePerUnitCycles    = @UsagePerUnitCycles,
			UsagePerUnitTimes     = @UsagePerUnitTimes,
			OverrunPerUnitCycles  = @OverrunPerUnitCycles,
			OverrunPerUnitTimes   = @OverrunPerUnitTimes,
			UpdatedBy             = @UpdatedBy,
			UpdatedDate           = GETUTCDATE()
		WHERE LeaseStocklineId = @LeaseStocklineId;

		COMMIT TRANSACTION;

		SELECT * FROM [dbo].[LeaseStockline] WITH (NOLOCK) WHERE LeaseStocklineId = @LeaseStocklineId;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_UpdateLeaseStockLineProperties]',
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