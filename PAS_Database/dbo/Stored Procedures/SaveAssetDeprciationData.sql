-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <9-1-2024>
-- Description:	<This SP to save Depreciated Asset Data on click of Run Process>
-- =============================================
CREATE   PROCEDURE [dbo].[SaveAssetDeprciationData] 
@SerialNumber VARCHAR(30) = NULL,
@StklineNumber VARCHAR(30) = NULL,
@InServiceDate DATETIME = NULL,
@DepreciableLife BIGINT = NULL,
@DepreciationMethod VARCHAR(30) = NULL,
@DepreciationFrequencyName VARCHAR(30) = NULL,
@AssetId VARCHAR(30) = NULL,
@AssetInventoryId BIGINT = NULL,
@InstalledCost DECIMAL(18,2) = NULL,
@MasterCompanyId BIGINT = NULL,
@CreatedBy VARCHAR(30) = NULL,
@CreatedDate DATETIME = NULL,
@IsActive BIT = NULL,
@IsDeleted BIT = NULL,
@CURRENCY VARCHAR(30) = NULL,
@EntityMSID BIGINT = NULL,
@UpdatedBy VARCHAR(30) = NULL,
@UpdatedDate DATETIME = NULL,
@SelectedAccountingPeriodId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN	

		DECLARE @DepreciationAmount DECIMAL(18,2);
		DECLARE @AccumlatedDepr DECIMAL(18,2);
		DECLARE @NetBookValue DECIMAL(18,2);
		DECLARE @NBVAfterDepreciation DECIMAL(18,2);
		DECLARE @ResidualPercentage DECIMAL(18,2);
		DECLARE @AfterReduceResidual DECIMAL(18,2);
		DECLARE @DepreciationStartDate DATETIME;
		DECLARE @LastDeprRunPeriod VARCHAR(30)

		SELECT @AccumlatedDepr = [AccumlatedDepr] FROM AssetDepreciationHistory WHERE [AssetInventoryId] = @AssetInventoryId AND [ID] = (SELECT MAX(ID) FROM AssetDepreciationHistory)
		SELECT @ResidualPercentage = ResidualPercentage FROM AssetInventory WHERE [AssetInventoryId] = @AssetInventoryId 
		SELECT @AfterReduceResidual = ISNULL(ISNULL(@InstalledCost,0) - ISNULL(@ResidualPercentage,0),0);
		SELECT @DepreciationAmount = ISNULL(ISNULL(@AfterReduceResidual,0) / ISNULL(@DepreciableLife,0),0);										-- (@InstalledCost - @ResidualPercentage) / @DepreciableLife
		SELECT @AccumlatedDepr = (ISNULL(ISNULL(@AccumlatedDepr,0) + ISNULL(@DepreciationAmount,0),0));											-- @AccumlatedDepr + @DepreciationAmount;
		SELECT @NetBookValue = (ISNULL(ISNULL(@InstalledCost,0) - ISNULL(@AccumlatedDepr,0),0));												-- @InstalledCost - @AccumlatedDepr;
		SELECT @NBVAfterDepreciation = (ISNULL(ISNULL(@NetBookValue,0) - ISNULL(@DepreciationAmount,0),0));										-- @NetBookValue - @DepreciationAmount;
		
		SELECT @LastDeprRunPeriod = PeriodName FROM AccountingCalendar WHERE AccountingCalendarId = @SelectedAccountingPeriodId 
		SET @DepreciationStartDate = GETUTCDATE();

		IF(@InServiceDate = NULL)
		BEGIN
			SET @InServiceDate = GETUTCDATE();
		END

		IF(@SerialNumber = NULL)
		BEGIN
			SET @SerialNumber = '';
		END

		INSERT INTO [AssetDepreciationHistory]

		([SerialNo],[StklineNumber],[InServiceDate],[DepriciableStatus],[CURRENCY],[DepriciableLife],[DepreciationMethod],[DepreciationFrequency],[AssetId]
		,[AssetInventoryId],[InstalledCost],[DepreciationAmount],[AccumlatedDepr],[NetBookValue],[NBVAfterDepreciation],[LastDeprRunPeriod],[AccountingCalenderId],
		[MasterCompanyId],[CreatedBy],[CreatedDate],[updatedBy],[updatedDate],[IsActive],[IsDelete],[DepreciationStartDate])
		
		VALUES (
				@SerialNumber,
				@StklineNumber,
				@InServiceDate,
				'Depreciating',
				@CURRENCY,
				@DepreciableLife,
				@DepreciationMethod,
				@DepreciationFrequencyName,
				@AssetId,
				@AssetInventoryId,
				@InstalledCost,
				@DepreciationAmount,
				@AccumlatedDepr,
				@NetBookValue,
				@NBVAfterDepreciation,
				@LastDeprRunPeriod,
				@SelectedAccountingPeriodId,
				@MasterCompanyId,
				@CreatedBy,
				@CreatedDate,
				@UpdatedBy,
				@UpdatedDate,
				@IsActive,
				@IsDeleted,
				@DepreciationStartDate
			)

		-- SELECT * FROM AssetDepreciationHistory
					
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
                ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'SaveAssetDeprciationData' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AssetInventoryId, 0) + ''', 													'
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