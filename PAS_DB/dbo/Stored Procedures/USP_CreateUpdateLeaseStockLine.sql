/*************************************************************
 ** File:   [USP_CreateUpdateLeaseStockLine]
 ** Description: This stored procedure is used to Create/Update a record in [LeaseStockline].
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    07/08/2026     Amit Ghediya            Created
    2    10/08/2026     Amit Ghediya            Reworked for denormalized PNDescription/SN/StocklineNumber schema

exec USP_CreateUpdateLeaseStockLine
@LeaseStocklineId=0,@LeasePartId=1,@StockLineId=1,@QtyOrder=1,@OutrightPrice=NULL,@FlatRate=NULL,
@PricingMethod=NULL,@BillingInterval=NULL,@MinimumCycles=NULL,@MinimumTimes=NULL,@MaximumCycles=NULL,@MaximumTimes=NULL,
@UsagePerUnitCycles=NULL,@UsagePerUnitTimes=NULL,@OverrunPerUnitCycles=NULL,@OverrunPerUnitTimes=NULL,
@Maintenance=NULL,@Insurance=NULL,@Taxes=NULL,@RepairOrderId=NULL,@WorkOrderId=NULL,
@MasterCompanyId=1,@CreatedBy=1,@UpdatedBy=1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateUpdateLeaseStockLine]
	@LeaseStocklineId BIGINT = 0,
	@LeasePartId BIGINT,
	@StockLineId BIGINT,
	@QtyOrder INT,
	@OutrightPrice DECIMAL(18,2) = NULL,
	@FlatRate DECIMAL(18,2) = NULL,
	@PricingMethod NVARCHAR(100) = NULL,
	@RateUnit NVARCHAR(50) = NULL,
	@BillingInterval NVARCHAR(100) = NULL,
	@BillingMethod NVARCHAR(50) = NULL,
	@MinimumCycles DECIMAL(18,2) = NULL,
	@MinimumTimes DECIMAL(18,2) = NULL,
	@MaximumCycles DECIMAL(18,2) = NULL,
	@MaximumTimes DECIMAL(18,2) = NULL,
	@UsagePerUnitCycles DECIMAL(18,2) = NULL,
	@UsagePerUnitTimes DECIMAL(18,2) = NULL,
	@OverrunPerUnitCycles DECIMAL(18,2) = NULL,
	@OverrunPerUnitTimes DECIMAL(18,2) = NULL,
	@Maintenance DECIMAL(18,2) = NULL,
	@MaintenancePer NVARCHAR(50) = NULL,
	@Insurance DECIMAL(18,2) = NULL,
	@InsurancePer NVARCHAR(50) = NULL,
	@Taxes DECIMAL(18,2) = NULL,
	@TaxesPer NVARCHAR(50) = NULL,
	@RepairOrderId BIGINT = NULL,
	@WorkOrderId BIGINT = NULL,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(256),
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @PNDescription NVARCHAR(500), @SN NVARCHAR(100), @StocklineNumber VARCHAR(100),
				@ConditionId BIGINT, @QtyAvailable INT, @QtyOH INT, @RONumber VARCHAR(100), @WorkOrderNo VARCHAR(100);

		SELECT
			@PNDescription = IM.PartDescription,
			@SN = SL.SerialNumber,
			@StocklineNumber = SL.StockLineNumber,
			@ConditionId = SL.ConditionId,
			@QtyAvailable = SL.QuantityAvailable,
			@QtyOH = SL.QuantityOnHand
		FROM [dbo].[Stockline] SL WITH (NOLOCK)
		LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = SL.ItemMasterId
		WHERE SL.StockLineId = @StockLineId;

		IF (@RepairOrderId IS NOT NULL)
			SELECT @RONumber = RepairOrderNumber FROM [dbo].[RepairOrder] WITH (NOLOCK) WHERE RepairOrderId = @RepairOrderId;

		IF (@WorkOrderId IS NOT NULL)
			SELECT @WorkOrderNo = WorkOrderNum FROM [dbo].[WorkOrder] WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId;

		IF (ISNULL(@LeaseStocklineId, 0) > 0)
		BEGIN
			UPDATE [dbo].[LeaseStockline]
			SET
				StockLineId           = @StockLineId,
				PNDescription         = @PNDescription,
				QtyOrder              = @QtyOrder,
				QtyAvailable          = @QtyAvailable,
				QtyOH                 = @QtyOH,
				SN                    = @SN,
				StocklineNumber       = @StocklineNumber,
				ConditionId           = @ConditionId,
				OutrightPrice         = @OutrightPrice,
				FlatRate              = @FlatRate,
				PricingMethod         = @PricingMethod,
				RateUnit              = @RateUnit,
				BillingInterval       = @BillingInterval,
				BillingMethod         = @BillingMethod,
				MinimumCycles         = @MinimumCycles,
				MinimumTimes          = @MinimumTimes,
				MaximumCycles         = @MaximumCycles,
				MaximumTimes          = @MaximumTimes,
				UsagePerUnitCycles    = @UsagePerUnitCycles,
				UsagePerUnitTimes     = @UsagePerUnitTimes,
				OverrunPerUnitCycles  = @OverrunPerUnitCycles,
				OverrunPerUnitTimes   = @OverrunPerUnitTimes,
				Maintenance           = @Maintenance,
				MaintenancePer        = @MaintenancePer,
				Insurance             = @Insurance,
				InsurancePer          = @InsurancePer,
				Taxes                 = @Taxes,
				TaxesPer              = @TaxesPer,
				RepairOrderId         = @RepairOrderId,
				RONumber              = @RONumber,
				WorkOrderId           = @WorkOrderId,
				WorkOrderNo           = @WorkOrderNo,
				UpdatedBy             = @UpdatedBy,
				UpdatedDate           = GETUTCDATE()
			WHERE LeaseStocklineId = @LeaseStocklineId;
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[LeaseStockline]
			(
				LeasePartId, PNDescription, QtyOrder, QtyReserved, QtyAvailable, QtyOH, SN, StockLineId, StocklineNumber, ConditionId,
				OutrightPrice, FlatRate, PricingMethod, RateUnit, BillingInterval, BillingMethod, MinimumCycles, MinimumTimes, MaximumCycles, MaximumTimes,
				UsagePerUnitCycles, UsagePerUnitTimes, OverrunPerUnitCycles, OverrunPerUnitTimes, Maintenance, MaintenancePer, Insurance, InsurancePer, Taxes, TaxesPer,
				RepairOrderId, RONumber, WorkOrderId, WorkOrderNo,
				MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted
			)
			VALUES
			(
				@LeasePartId, @PNDescription, @QtyOrder, 0, @QtyAvailable, @QtyOH, @SN, @StockLineId, @StocklineNumber, @ConditionId,
				@OutrightPrice, @FlatRate, @PricingMethod, @RateUnit, @BillingInterval, @BillingMethod, @MinimumCycles, @MinimumTimes, @MaximumCycles, @MaximumTimes,
				@UsagePerUnitCycles, @UsagePerUnitTimes, @OverrunPerUnitCycles, @OverrunPerUnitTimes, @Maintenance, @MaintenancePer, @Insurance, @InsurancePer, @Taxes, @TaxesPer,
				@RepairOrderId, @RONumber, @WorkOrderId, @WorkOrderNo,
				@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0
			);

			SET @LeaseStocklineId = SCOPE_IDENTITY();
		END

		SELECT * FROM [dbo].[LeaseStockline] WITH (NOLOCK) WHERE LeaseStocklineId = @LeaseStocklineId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_CreateUpdateLeaseStockLine]',
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