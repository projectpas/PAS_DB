-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <9-1-2024>
-- Description:	<This SP to save Depreciated Asset Data on click of Run Process>
-- =============================================

/*************************************************************           
 ** File:   [SaveAssetDeprciationData]           
 ** Author:  Ayesha Sultana
 ** Description: This stored procedure is used to save asset depericiation data
 ** Purpose:         
 ** Date:   9-1-2024  
 ** PARAMETERS: @JournalBatchHeaderId bigint
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		     Change Description            
 ** --   --------     -------		     --------------------------------          
    1    09/01/2024   Ayesha Sultana     Created
	2	 27/03/2024	  Abhishek Jirawla	 Added more conditions to the store procedure with correcting a few features of it as well
	3	 19/12/2024	  Abhishek Jirawla	 Added Full Depreciating status once depreciation is done
	4	 31-Aug-2026	  Ayushi Patel		 [PN-16393] UOM Changes

************************************************************************/

CREATE   PROCEDURE [dbo].[SaveAssetDeprciationData] 
@SerialNumber VARCHAR(30) = NULL,
@StklineNumber VARCHAR(30) = NULL,
@InServiceDate DATETIME = NULL,
@DepreciableLife BIGINT = NULL,
@DepreciationMethod VARCHAR(30) = NULL,
@DepreciationFrequencyName VARCHAR(30) = NULL,
@AssetId VARCHAR(30) = NULL,
@AssetInventoryId BIGINT = NULL,
@InstalledCost DECIMAL(18,6) = NULL,
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

		DECLARE @DepreciationAmount DECIMAL(18,6);
		DECLARE @AccumlatedDepr DECIMAL(18,6);
		DECLARE @NetBookValue DECIMAL(18,6);
		DECLARE @NBVAfterDepreciation DECIMAL(18,6);
		DECLARE @ResidualPercentage DECIMAL(18,6);
		DECLARE @AfterReduceResidual DECIMAL(18,6);
		DECLARE @ReduceResidualPerc DECIMAL(18,6);
		DECLARE @Hundred DECIMAL(18,6) = 100;
		DECLARE @DepreciationStartDate DATETIME;
		DECLARE @LastDeprRunPeriod VARCHAR(30)
		DECLARE @FullyDepreciatedStatusId BIGINT; 

		SELECT @AccumlatedDepr = [AccumlatedDepr] FROM DBO.AssetDepreciationHistory WITH(NOLOCK) WHERE [AssetInventoryId] = @AssetInventoryId AND [ID] = (SELECT MAX(ID) FROM DBO.AssetDepreciationHistory WITH(NOLOCK) WHERE [AssetInventoryId] = @AssetInventoryId)
		SELECT @ResidualPercentage = ResidualPercentage FROM DBO.AssetInventory WITH(NOLOCK) WHERE [AssetInventoryId] = @AssetInventoryId 

		SELECT @ReduceResidualPerc = ISNULL(ISNULL(@ResidualPercentage,0) / ISNULL(@Hundred,0),0);				
		SELECT @AfterReduceResidual = ISNULL(ISNULL(@InstalledCost,0) - (ISNULL(@InstalledCost,0) * ISNULL(@ReduceResidualPerc,0)),0);
		SELECT @DepreciationAmount = ISNULL(ISNULL(@AfterReduceResidual,0) / ISNULL(@DepreciableLife,0),0);										-- (@InstalledCost * @ResidualPercentage / 100) / @DepreciableLife
		SELECT @AccumlatedDepr = (ISNULL(ISNULL(@AccumlatedDepr,0) + ISNULL(@DepreciationAmount,0),0));											-- @AccumlatedDepr + @DepreciationAmount;
		SELECT @NetBookValue = (ISNULL(ISNULL(@InstalledCost,0) - ISNULL(@AccumlatedDepr,0),0));												-- @InstalledCost - @AccumlatedDepr;
		SELECT @NBVAfterDepreciation = (ISNULL(ISNULL(@NetBookValue,0) - ISNULL(@DepreciationAmount,0),0));										-- @NetBookValue - @DepreciationAmount;
		
		SELECT @LastDeprRunPeriod = PeriodName FROM DBO.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @SelectedAccountingPeriodId 
		SET @DepreciationStartDate = GETUTCDATE();

		IF(@AfterReduceResidual = @AccumlatedDepr)
		BEGIN
			SELECT @FullyDepreciatedStatusId = AssetStatusId FROM DBO.AssetStatus WITH(NOLOCK) WHERE Name = 'FULLY DEPRECIATED' AND MasterCompanyId = @MasterCompanyId
			
			UPDATE DBO.AssetInventory
			SET AssetStatusId = @FullyDepreciatedStatusId
			WHERE AssetInventoryId = @AssetInventoryId
		END

		IF(@InServiceDate = NULL)
		BEGIN
			SET @InServiceDate = GETUTCDATE();
		END

		IF(@SerialNumber = NULL)
		BEGIN
			SET @SerialNumber = '';
		END

		IF(@NBVAfterDepreciation < 0)
		BEGIN
			SET @NBVAfterDepreciation = 0;
		END

		IF @AccumlatedDepr <= @AfterReduceResidual
		BEGIN

			IF NOT EXISTS(SELECT * FROM DBO.[AssetDepreciationHistory] WITH(NOLOCK) WHERE AssetInventoryId = @AssetInventoryId and AccountingCalenderId = @SelectedAccountingPeriodId)
			BEGIN

				INSERT INTO DBO.[AssetDepreciationHistory]

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
			END
		END

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
            , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@AssetInventoryId, '') AS VARCHAR(100))
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