/*************************************************************
 ** File:   [SaveLeaseDepreciationData]
 ** Author:  Kishor Makwana
 ** Description: This stored procedure is used to save lease stockline depreciation data on click of Run Process
 **              (lease version of SaveAssetDeprciationData: AssetDepreciationHistory -> LeaseDepreciationHistory).
 ** Purpose:     Amount, accumulated depreciation and NBV come from fn_GetLeaseDepreciationAmount (LeaseStockline / LeaseHeader / Stockline /
 **              Item Master Asset setup), the same values the journal of USP_CreateBatch_DepreciableLeaseStockline is posted with.
 **              One history row per lease stockline and accounting period (a second call for the same period does nothing).
 ** PARAMETERS: @LeaseStocklineId BIGINT, @SelectedAccountingPeriodId BIGINT, @MasterCompanyId BIGINT, @CreatedBy VARCHAR(256)
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author                 Change Description
 ** --   --------     -------                --------------------------------
    1    17/11/2026   Kishor Makwana         Created (Process Depreciation - Lease)
************************************************************************/
CREATE   PROCEDURE [dbo].[SaveLeaseDepreciationData]
@LeaseStocklineId BIGINT,
@SelectedAccountingPeriodId BIGINT = NULL,
@MasterCompanyId BIGINT = NULL,
@CreatedBy VARCHAR(256) = NULL,
@UpdatedBy VARCHAR(256) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @LastDeprRunPeriod VARCHAR(30);
		SELECT @LastDeprRunPeriod = PeriodName FROM DBO.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @SelectedAccountingPeriodId;

		INSERT INTO DBO.[LeaseDepreciationHistory]
			([LeaseStocklineId],[LeaseHeaderId],[StocklineNumber],[SerialNo],[InServiceDate],[DepriciableStatus],[CURRENCY],[DepriciableLife],[DepreciationMethod],[DepreciationFrequency],
			 [InstalledCost],[DepreciationAmount],[AccumlatedDepr],[NetBookValue],[NBVAfterDepreciation],[ResidualPercentage],[LastDeprRunPeriod],[AccountingCalenderId],
			 [MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDelete],[DepreciationStartDate])
		SELECT F.LeaseStocklineId, F.LeaseHeaderId, F.StocklineNumber, F.SerialNo, F.InServiceDate, 'Depreciating', F.CurrencyCode, F.Life, F.MethodName, F.FrequencyName,
			   F.Cost, F.DepreciationAmount, F.PrevAccum + F.DepreciationAmount, F.Cost - (F.PrevAccum + F.DepreciationAmount),
			   CASE WHEN (F.Cost - (F.PrevAccum + F.DepreciationAmount)) - F.DepreciationAmount < 0 THEN 0 ELSE (F.Cost - (F.PrevAccum + F.DepreciationAmount)) - F.DepreciationAmount END,
			   F.ResidualPercentage, @LastDeprRunPeriod, @SelectedAccountingPeriodId,
			   ISNULL(@MasterCompanyId, F.MasterCompanyId), @CreatedBy, GETUTCDATE(), ISNULL(@UpdatedBy, @CreatedBy), GETUTCDATE(), 1, 0, GETUTCDATE()
		FROM [dbo].[fn_GetLeaseDepreciationAmount](@LeaseStocklineId, @SelectedAccountingPeriodId) F
		WHERE F.AlreadyDepreciated = 0 AND F.DepreciationAmount > 0;
	END
	COMMIT  TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'SaveLeaseDepreciationData'
            , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@LeaseStocklineId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
			exec spLogException
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			=  @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END