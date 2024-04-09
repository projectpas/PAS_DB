
/*************************************************************           
 ** File:   [SaveAssetDepreciationMonthRemovalData]           
 ** Author:  Abhishek Jirawla
 ** Description: This stored procedure is used to remove asset inventory depericiation from specific month data
 ** Purpose:         
 ** Date:   04-04-2024  
 ** PARAMETERS: 
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		     Change Description            
 ** --   --------     -------		     --------------------------------          
    1    04/04/2024   Abhishek Jirawla   Created

************************************************************************/

CREATE PROCEDURE [dbo].[SaveAssetDepreciationMonthRemovalData] 
@AssetId VARCHAR(30) = NULL,
@AssetInventoryId BIGINT = NULL,
@CURRENCY VARCHAR(30) = NULL,
@DepreciableLife BIGINT = NULL,
@DepreciationMethod VARCHAR(30) = NULL,
@DepreciationFrequencyName VARCHAR(30) = NULL,
@InstalledCost DECIMAL(18,2) = NULL,
@MasterCompanyId BIGINT = NULL,
@IsActive BIT = NULL,
@IsDeleted BIT = NULL,
@CreatedBy VARCHAR(30) = NULL,
@CreatedDate DATETIME = NULL,
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
		DECLARE @LastDeprRunPeriod VARCHAR(30);
		DECLARE @DepreciationStartDate DATETIME;

		SELECT @DepreciationAmount = DepreciationAmount, @AccumlatedDepr = [AccumlatedDepr], @NetBookValue = NetBookValue, @NBVAfterDepreciation = NBVAfterDepreciation 
		FROM AssetDepreciationHistory 
		WHERE [AssetInventoryId] = @AssetInventoryId AND [ID] = (SELECT MAX(ID) FROM AssetDepreciationHistory WHERE [AssetInventoryId] = @AssetInventoryId AND IsDelete = 0) AND IsDelete = 0
		
		SELECT @LastDeprRunPeriod = PeriodName FROM AccountingCalendar WHERE AccountingCalendarId = @SelectedAccountingPeriodId 

		SELECT @DepreciationStartDate = DepreciationStartDate FROM AssetInventory WHERE AssetInventoryId = @AssetInventoryId

		IF NOT EXISTS(SELECT * FROM [AssetDepreciationMonthRemoval] WHERE AssetInventoryId = @AssetInventoryId AND AccountingCalenderId = @SelectedAccountingPeriodId AND IsDeleted = 0)
		BEGIN

			INSERT INTO [AssetDepreciationMonthRemoval]

			(AssetId, AssetInventoryId, DepreciableStatus, Currency, AccountingCalenderId, DepreciationLife, DepreciationMethod, DepreciationFrequency,
				DepreciationStartDate, InstalledCost, DepreciationAmount, AccumlatedDepr, NetBookValue, NBVAfterDepreciation, LastDeprRunPeriod, MasterCompanyId,
				IsActive, IsDeleted, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate)
		
			VALUES (
					@AssetId,
					@AssetInventoryId,
					'Depreciating',
					@CURRENCY,
					@SelectedAccountingPeriodId,
					@DepreciableLife,
					@DepreciationMethod,
					@DepreciationFrequencyName,
					@DepreciationStartDate,
					@InstalledCost,
					@DepreciationAmount,
					@AccumlatedDepr,
					@NetBookValue,
					@NBVAfterDepreciation,
					@LastDeprRunPeriod,
					@MasterCompanyId,
					@IsActive,
					@IsDeleted,
					@CreatedBy,
					@CreatedDate,
					@UpdatedBy,
					@UpdatedDate					
				)
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
            , @AdhocComments     VARCHAR(150)    = 'SaveAssetDepreciationMonthRemovalData' 
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