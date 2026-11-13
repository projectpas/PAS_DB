/*************************************************************
 ** File:   [USP_SaveStocklineAssetDepreciation]
 ** Description: Lease Asset Depreciation - Run Process for ONE Stockline asset (Stockline.IsAsset = 1, IsLease = 1, AssetIsDepreciable = 1) and one
 **              Accounting Period. Writes the depreciation row of the period into StocklineAssetDepreciationHistory (the Asset Inventory tables
 **              AssetDepreciationHistory / AssetInventory are not touched).
 **              USAGE BASED (PN-18535) - the lease asset depreciates by the hours it was used, not by months :
 **                Cost                   = Stockline.AssetTotalCost (Purchase Price + Installation Cost ...)
 **                Depreciation per Hr    = Cost / Asset Life                (Stockline.AssetLife = Asset Life (Mths) of the asset)
 **                Usage Hours of period  = Time usage (Usage Info, LeaseStocklineUsageHistory UsageType 'T', TSN Hours + Minutes / 60) with a To Date
 **                                         (else Entry Date) up to the period end, minus the hours already depreciated in the earlier periods
 **                Period Depreciation    = Usage Hours of period x Depreciation per Hr, rounded to 2 decimals, never more than the Cost still to depreciate
 **                Accumulated Depr       = previous Accumulated Depr + Period Depreciation, NBV = Cost - Accumulated Depr
 **              Example : Cost 175,000 / 2,000 hrs = 87.50 per hr, 860 hrs of usage = 75,250 Accumulated Depr, NBV 99,750.
 **              The values are read from the Stockline (not passed by the caller). The stockline becomes "Fully Depreciated" (Stockline.AssetStatusId)
 **              when the Cost is reached. A period with no usage writes a 0 row, so the period is marked as run.
 **              The journal of the period (posted by the API before this procedure) gives the JournalBatchHeaderId stored on the row.
 ** Returns: one row - Result (Inserted / AlreadyRun / FullyDepreciated / NotEligible / InvalidPeriod), StockLineId, history id and the amounts / hours.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    11/November/2026 Kishor Makwana  [Lease Asset Depreciation] Created
    2    12/November/2026 Kishor Makwana  [PN-18535] Reworked from straight line (months) to usage based (Cost / Lease Duration Hrs x usage hours of the period).
 -- EXEC [dbo].[USP_SaveStocklineAssetDepreciation] @StockLineId = 1, @AccountingCalendarId = 1, @MasterCompanyId = 1, @UpdatedBy = 'ADMIN User'
**************************************************************/
CREATE PROCEDURE [dbo].[USP_SaveStocklineAssetDepreciation]
	@StockLineId          BIGINT,
	@AccountingCalendarId BIGINT,
	@MasterCompanyId      INT,
	@UpdatedBy            VARCHAR(256),
	@JournalBatchHeaderId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION;

		DECLARE @Result VARCHAR(30) = 'Inserted', @HistoryId BIGINT = NULL;
		DECLARE @Cost DECIMAL(18, 6), @Life INT, @Method NVARCHAR(250), @Frequency NVARCHAR(250), @StartDate DATETIME2(7),
		        @StockLineNumber NVARCHAR(100), @SerialNumber NVARCHAR(100), @PartNumber NVARCHAR(250), @AssetName NVARCHAR(100), @Currency NVARCHAR(50),
		        @LegalEntityId BIGINT, @ManagementStructureId BIGINT, @IsAsset BIT, @IsLease BIT, @IsDepreciable BIT, @Found BIT = 0,
		        @ItemMasterId BIGINT, @ConvertedToStocklineId BIGINT;
		DECLARE @PeriodName VARCHAR(100), @PeriodTo DATETIME2(7);
		DECLARE @LeaseDurationHrs DECIMAL(18, 2) = 0, @PerHour DECIMAL(18, 6) = 0, @UsageToDate DECIMAL(18, 6) = 0, @BookedHours DECIMAL(18, 6) = 0,
		        @PeriodHours DECIMAL(18, 6) = 0, @PeriodAmount DECIMAL(18, 6) = 0,
		        @PrevAccum DECIMAL(18, 6) = 0, @Remaining DECIMAL(18, 6), @Accum DECIMAL(18, 6), @NBV DECIMAL(18, 6),
		        @FullyDepreciated BIT = 0;

		SELECT
			@Found                = 1,
			@ItemMasterId         = AssetStockline.ItemMasterId,
			@Cost                 = ISNULL(AssetStockline.AssetTotalCost, 0),
			@Life                 = ISNULL(AssetStockline.AssetLife, 0),
			@Method               = AssetStockline.DepreciationMethodName,
			@Frequency            = AssetStockline.DepreciationFrequencyName,
			@StartDate            = COALESCE(AssetStockline.AssetDepreciationStartDate, AssetStockline.ReceivedDate, AssetStockline.EntryDate),
			@StockLineNumber      = AssetStockline.StockLineNumber,
			@SerialNumber         = AssetStockline.SerialNumber,
			@PartNumber           = AssetStockline.PartNumber,
			@AssetName            = AssetStockline.AssetName,
			@Currency             = AssetStockline.Currency,
			@LegalEntityId        = AssetStockline.LegalEntityId,
			@ManagementStructureId = AssetStockline.ManagementStructureId,
			@IsAsset              = ISNULL(AssetStockline.IsAsset, 0),
			@IsLease              = ISNULL(AssetStockline.IsLease, 0),
			@IsDepreciable        = ISNULL(AssetStockline.AssetIsDepreciable, 0),
			@LeaseDurationHrs     = ISNULL(AssetStockline.AssetLife, 0), -- Asset Life (Mths)
			@ConvertedToStocklineId    = AssetStockline.ConvertedToStocklineId
		FROM dbo.Stockline AssetStockline WITH (UPDLOCK, ROWLOCK)
		WHERE AssetStockline.StockLineId = @StockLineId AND AssetStockline.MasterCompanyId = @MasterCompanyId AND ISNULL(AssetStockline.isDeleted, 0) = 0;

		SELECT @PeriodName = Period.PeriodName, @PeriodTo = Period.ToDate
		FROM dbo.AccountingCalendar Period WITH (NOLOCK)
		WHERE Period.AccountingCalendarId = @AccountingCalendarId AND ISNULL(Period.IsDeleted, 0) = 0;

		IF @PeriodName IS NULL
		BEGIN
			SET @Result = 'InvalidPeriod';
		END
		ELSE IF @Found = 0 OR @IsAsset = 0 OR @IsLease = 0 OR @IsDepreciable = 0 OR @Cost <= 0 OR @LeaseDurationHrs <= 0 OR @ConvertedToStocklineId IS NOT NULL
		BEGIN
			SET @Result = 'NotEligible';
		END
		ELSE IF EXISTS (SELECT 1 FROM dbo.StocklineAssetDepreciationHistory H WITH (NOLOCK)
		                WHERE H.StockLineId = @StockLineId AND H.AccountingCalendarId = @AccountingCalendarId AND H.IsDeleted = 0)
		BEGIN
			SET @Result = 'AlreadyRun';
		END
		ELSE
		BEGIN
			SELECT TOP 1 @PrevAccum = ISNULL(H.AccumulatedDepr, 0)
			FROM dbo.StocklineAssetDepreciationHistory H WITH (NOLOCK)
			WHERE H.StockLineId = @StockLineId AND H.IsDeleted = 0
			ORDER BY H.StocklineAssetDepreciationHistoryId DESC;

			SELECT @BookedHours = ISNULL(SUM(ISNULL(B.UsageHours, 0)), 0)
			FROM dbo.StocklineAssetDepreciationHistory B WITH (NOLOCK)
			WHERE B.StockLineId = @StockLineId AND B.IsDeleted = 0;

			-- Time usage of Usage Info up to the end of the period (an entry is counted in the period of its To Date, else its Entry Date)
			SELECT @UsageToDate = ISNULL(SUM(ISNULL(UH.TSNHours, 0) + ISNULL(UH.TSNMinutes, 0) / 60.0), 0)
			FROM dbo.LeaseStockline LS WITH (NOLOCK)
				INNER JOIN dbo.LeaseStocklineUsageHistory UH WITH (NOLOCK) ON UH.LeaseStocklineId = LS.LeaseStocklineId
			WHERE LS.StockLineId = @StockLineId AND UH.UsageType = 'T' AND UH.IsDeleted = 0 AND UH.IsActive = 1
			  AND (@PeriodTo IS NULL OR COALESCE(UH.ToDate, UH.EntryDate) <= @PeriodTo);

			SET @PeriodHours = CASE WHEN @UsageToDate - @BookedHours > 0 THEN @UsageToDate - @BookedHours ELSE 0 END;
			SET @PerHour     = @Cost / @LeaseDurationHrs;
			SET @Remaining   = @Cost - @PrevAccum;

			IF @Remaining <= 0
			BEGIN
				SET @Result = 'FullyDepreciated';
				SET @FullyDepreciated = 1;
			END
			ELSE
			BEGIN
				SET @PeriodAmount = ROUND(@PeriodHours * @PerHour, 2);
				-- the Accumulated Depr never goes over the Cost
				IF @PeriodAmount > @Remaining SET @PeriodAmount = @Remaining;
				SET @Accum = @PrevAccum + @PeriodAmount;
				SET @NBV   = @Cost - @Accum;
				IF @Accum >= @Cost SET @FullyDepreciated = 1;

				INSERT INTO dbo.StocklineAssetDepreciationHistory
					([StockLineId], [StockLineNumber], [SerialNumber], [PartNumber], [AssetName], [InServiceDate], [DepreciationStartDate], [DepreciableStatus], [Currency],
					 [DepreciableLife], [DepreciationMethod], [DepreciationFrequency], [ResidualPercentage], [InstalledCost], [DepreciationAmount], [AccumulatedDepr],
					 [NetBookValue], [NBVAfterDepreciation], [LastDeprRunPeriod], [AccountingCalendarId], [LegalEntityId], [ManagementStructureId], [JournalBatchHeaderId],
					 [LeaseDurationHrs], [DepreciationPerHour], [UsageHours],
					 [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
				VALUES
					(@StockLineId, @StockLineNumber, @SerialNumber, @PartNumber, @AssetName, ISNULL(@StartDate, GETUTCDATE()), @StartDate,
					 CASE WHEN @FullyDepreciated = 1 THEN 'Fully Depreciated' ELSE 'Depreciating' END, @Currency,
					 @Life, @Method, @Frequency, 0, @Cost, @PeriodAmount, @Accum,
					 @NBV, @NBV, @PeriodName, @AccountingCalendarId, @LegalEntityId, @ManagementStructureId, @JournalBatchHeaderId,
					 @LeaseDurationHrs, @PerHour, @PeriodHours,
					 @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);

				SET @HistoryId = SCOPE_IDENTITY();
			END

			IF @FullyDepreciated = 1
			BEGIN
				DECLARE @FullyDepreciatedStatusId BIGINT;
				SELECT TOP 1 @FullyDepreciatedStatusId = AssetStatus.AssetStatusId
				FROM dbo.AssetStatus AssetStatus WITH (NOLOCK)
				WHERE AssetStatus.MasterCompanyId = @MasterCompanyId AND ISNULL(AssetStatus.IsDeleted, 0) = 0
				  AND UPPER(AssetStatus.Name) IN ('FULLY DEPRECIATED', 'FULLY DEPRECIATING')
				ORDER BY CASE WHEN UPPER(AssetStatus.Name) = 'FULLY DEPRECIATED' THEN 0 ELSE 1 END;

				IF @FullyDepreciatedStatusId IS NOT NULL
				BEGIN
					UPDATE dbo.Stockline SET AssetStatusId = @FullyDepreciatedStatusId, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()
					WHERE StockLineId = @StockLineId;
				END
			END
		END

		COMMIT TRANSACTION;

		SELECT
			@Result            AS [Result],
			@StockLineId       AS [StockLineId],
			@HistoryId         AS [StocklineAssetDepreciationHistoryId],
			@PeriodAmount      AS [DepreciationAmount],
			@PeriodHours       AS [UsageHours],
			@PerHour           AS [DepreciationPerHour],
			@Accum             AS [AccumulatedDepr],
			@NBV               AS [NetBookValue],
			@FullyDepreciated  AS [IsFullyDepreciated];
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_SaveStocklineAssetDepreciation',
		        @ProcedureParameters VARCHAR(3000) = '@StockLineId = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100)) + ''', @AccountingCalendarId = ''' + CAST(ISNULL(@AccountingCalendarId, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END
