
/*************************************************************           
 ** File:   [UpdateAssetCalibrationStatus]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Update Calibration Status on Inventory   
 ** Purpose:         
 ** Date:   12/30/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/30/2020   Hemant Saliya Created
     
-- EXEC [UpdateAssetCalibrationStatus] 
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateAssetCalibrationStatus]
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

			DECLARE @UpdatedInventoryStatusId BIGINT;

			SELECT @UpdatedInventoryStatusId = AssetInventoryStatusId FROM dbo.AssetInventoryStatus WITH(NOLOCK) WHERE UPPER([Status]) = 'UNAVAILABLE' AND IsActive = 1 AND IsDeleted = 0;

			IF OBJECT_ID(N'tempdb..#tmpCalibrationRequired') IS NOT NULL
			BEGIN
			DROP TABLE #tmpCalibrationRequired
			END
			
			CREATE TABLE #tmpCalibrationRequired
			(
				 ID BIGINT NOT NULL IDENTITY, 
				 [AssetRecordId] BIGINT NULL,
				 [CalibrationId] BIGINT NULL,
				 [AssetInventoryId] BIGINT NULL,
				 [CalibtrationStatus] INT NULL,
				 [CalibrationDate] DATETIME2(7) NULL,
				 [CalibrationFrequencyDays] INT NULL,
				 [NextCalibrationDate] DATETIME2(7) NULL,
				 [LastCalibrationDate] DATETIME2(7) NULL,				 
			)

			INSERT INTO #tmpCalibrationRequired ([AssetRecordId], [CalibrationId], [AssetInventoryId], [CalibtrationStatus], 
				CalibrationDate, CalibrationFrequencyDays, NextCalibrationDate, LastCalibrationDate)
			SELECT AC.AssetRecordId, CalibrationId, AssetInventoryId, AIN.InventoryStatusId, CalibrationDate,AC.CalibrationFrequencyDays, 
				NextCalibrationDate, LastCalibrationDate
			FROM dbo.AssetCalibration AC WITH(NOLOCK) 
				JOIN dbo.CalibrationManagment CM WITH(NOLOCK) ON AC.AssetRecordId = CM.AssetRecordId
				JOIN dbo.AssetInventory AIN WITH(NOLOCK) ON AIN.AssetRecordId = CM.AssetRecordId
			WHERE AC.CalibrationRequired = 1 AND DATEDIFF(DAY, CalibrationDate, GETDATE()) >= AC.CalibrationFrequencyDays AND AIN.InventoryStatusId = 1

			UPDATE AIN
				SET InventoryStatusId = @UpdatedInventoryStatusId
			FROM dbo.AssetInventory AIN WITH(NOLOCK)
			JOIN #tmpCalibrationRequired tmpCS ON AIN.AssetInventoryId = tmpCS.AssetInventoryId

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderColumnsWithId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL('', '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END