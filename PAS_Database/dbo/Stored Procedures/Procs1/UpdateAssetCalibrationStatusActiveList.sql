-- =============================================
-- Author:		Ayesha Sultana
-- Create date: 26-10-2023
-- Description:	This stored procedure is used Update Status on Inventory which calibration is in due.
-- =============================================

/*************************************************************   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    26-10-2023   Ayesha Sultana		Created
    2    17-11-2023   Devendra SHekh		changes for status update

	EXEC [UpdateAssetCalibrationStatusActiveList]

**************************************************************/

CREATE   PROCEDURE [dbo].[UpdateAssetCalibrationStatusActiveList]
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
			
				DECLARE @TotalRec BIGINT = 0, @StartCount BIGINT = 1, @DepreciationId BIGINT = 0, @InventoryId BIGINT = 0,
				@DepreciationName VARCHAR(150), @lastCalibrationDate DateTime2, @DueDate DateTime2, @FrequencyDays BIGINT = 0,
				@MonthDepreciation VARCHAR(150), @QuaterlyDepreciation VARCHAR(150), @YearlyDepreciation VARCHAR(150),
				@MTHLYDepreciation VARCHAR(150), @QTLYDepreciation VARCHAR(150), @YRLYDepreciation VARCHAR(150);

				IF OBJECT_ID(N'tempdb..#tmpAssetInventory') IS NOT NULL  
				BEGIN  
					DROP TABLE #tmpAssetInventory 
				END  
				
				CREATE TABLE #tmpAssetInventory(
					[Id] [BIGINT] IDENTITY(1,1) NOT NULL,
					[AssetInventoryId] [BIGINT] NULL,
					[InventoryStatusId] [BIGINT] NULL,
					[CalibrationDate] [dateTime2] NULL,
					[CalibrationFrequencyDays] [BIGINT] NULL,
					[NextCalibrationDate] [dateTime2] NULL,
					[LastCalibrationDate] [dateTime2] NULL,
					[DepreciationFrequencyName] [varchar](150) NULL,
					[DepreciationFrequencyId] [BIGINT] NULL,
					[CreatedDate] [dateTime2] NULL,
					[EntryDate] [dateTime2] NULL,
				)  
		
				SET @MonthDepreciation = (SELECT TOP 1 UPPER([Name]) FROM [dbo].[AssetDepreciationFrequency] WITH(NOLOCK) WHERE UPPER([Name]) = 'MONTHLY')
				SET @QuaterlyDepreciation = (SELECT TOP 1 UPPER([Name]) FROM [dbo].[AssetDepreciationFrequency] WITH(NOLOCK) WHERE UPPER([Name]) = 'QUATERLY')
				SET @YearlyDepreciation = (SELECT TOP 1 UPPER([Name]) FROM [dbo].[AssetDepreciationFrequency] WITH(NOLOCK) WHERE UPPER([Name]) = 'YEARLY')

				SET @MTHLYDepreciation = (SELECT TOP 1 UPPER([Name]) FROM [dbo].[AssetDepreciationFrequency] WITH(NOLOCK) WHERE UPPER([Name]) = 'MTHLY')
				SET @QTLYDepreciation = (SELECT TOP 1 UPPER([Name]) FROM [dbo].[AssetDepreciationFrequency] WITH(NOLOCK) WHERE UPPER([Name]) = 'QTLY')
				SET @YRLYDepreciation = (SELECT TOP 1 UPPER([Name]) FROM [dbo].[AssetDepreciationFrequency] WITH(NOLOCK) WHERE UPPER([Name]) = 'YRLY')


				INSERT INTO #tmpAssetInventory( [AssetInventoryId], [InventoryStatusId], [CalibrationDate], [NextCalibrationDate], [LastCalibrationDate],[DepreciationFrequencyName], 
							[DepreciationFrequencyId], [CreatedDate], [EntryDate])
				SELECT DISTINCT  AIN.AssetInventoryId, AIN.InventoryStatusId, CalibrationDate, NextCalibrationDate, LastCalibrationDate, AIN.[DepreciationFrequencyName], 
								 AIN.[DepreciationFrequencyId], AIN.[CreatedDate], AIN.[EntryDate]
				FROM dbo.AssetInventory AIN WITH(NOLOCK)
					JOIN dbo.CalibrationManagment CM WITH(NOLOCK) ON AIN.AssetInventoryId = CM.AssetInventoryId
					--JOIN dbo.Asset AC WITH(NOLOCK) ON AIN.AssetRecordId = AIN.AssetRecordId AND AIN.CalibrationRequired=1
					WHERE AIN.InventoryStatusId = (SELECT [AssetInventoryStatusId] FROM [dbo].[AssetInventoryStatus] WITH(NOLOCK) WHERE [Status] = 'Available') AND AIN.CalibrationRequired=1

				SELECT * FROM #tmpAssetInventory
				SET @TotalRec = (SELECT COUNT(Id) FROM #tmpAssetInventory)

				WHILE(@StartCount <= @TotalRec)
				BEGIN

					SELECT @DepreciationId = [DepreciationFrequencyId], @DepreciationName = [DepreciationFrequencyName], @InventoryId = [AssetInventoryId],
						   @lastCalibrationDate = ISNULL([LastCalibrationDate], [EntryDate]) FROM #tmpAssetInventory WHERE Id = @StartCount

					IF(UPPER(@DepreciationName) = @YearlyDepreciation OR UPPER(@DepreciationName) = @YRLYDepreciation)
					BEGIN

						SET @DueDate = DATEADD(YEAR, 1, @lastCalibrationDate)
						SET @FrequencyDays = DATEDIFF(DAY, @lastCalibrationDate, @DueDate)

						UPDATE AIN
						SET StatusNote = 'Calibration Due', InventoryStatusId =  (SELECT [AssetInventoryStatusId] FROM [dbo].[AssetInventoryStatus] WITH(NOLOCK) WHERE [Status] = 'UnAvailable')
						FROM dbo.AssetInventory AIN WITH(NOLOCK)
							--JOIN dbo.CalibrationManagment CM WITH(NOLOCK) ON AIN.AssetInventoryId = CM.AssetInventoryId
							--JOIN dbo.AssetInventory AIN WITH(NOLOCK) ON AIN.AssetRecordId = CM.AssetRecordId
						WHERE DATEDIFF(DAY, @lastCalibrationDate, GETDATE()) >= @FrequencyDays AND AIN.AssetInventoryId = @InventoryId

					END
					ELSE IF(UPPER(@DepreciationName) = @QuaterlyDepreciation OR UPPER(@DepreciationName) = @QTLYDepreciation)
					BEGIN
						
						SET @DueDate = DATEADD(MONTH, 4, @lastCalibrationDate)
						SET @FrequencyDays = DATEDIFF(DAY, @lastCalibrationDate, @DueDate)

						UPDATE AIN
						SET StatusNote = 'Calibration Due', InventoryStatusId =  (SELECT [AssetInventoryStatusId] FROM [dbo].[AssetInventoryStatus] WITH(NOLOCK) WHERE [Status] = 'UnAvailable')
						FROM dbo.AssetInventory AIN WITH(NOLOCK)
						WHERE DATEDIFF(DAY, @lastCalibrationDate, GETDATE()) >= @FrequencyDays AND AIN.AssetInventoryId = @InventoryId

					END
					ELSE IF(UPPER(@DepreciationName) = @MonthDepreciation OR UPPER(@DepreciationName) = @MTHLYDepreciation )
					BEGIN
						
						SET @DueDate = DATEADD(MONTH, 1, @lastCalibrationDate)
						SET @FrequencyDays = DATEDIFF(DAY, @lastCalibrationDate, @DueDate)

						UPDATE AIN
						SET StatusNote = 'Calibration Due', InventoryStatusId =  (SELECT [AssetInventoryStatusId] FROM [dbo].[AssetInventoryStatus] WITH(NOLOCK) WHERE [Status] = 'UnAvailable')
						FROM dbo.AssetInventory AIN WITH(NOLOCK)
						WHERE DATEDIFF(DAY, @lastCalibrationDate, GETDATE()) >= @FrequencyDays AND AIN.AssetInventoryId = @InventoryId

					END
					
					SET @StartCount = @StartCount + 1
				END

				--UPDATE AIN
				--	SET StatusNote='Calibration Due'
				--	FROM dbo.AssetCalibration AC WITH(NOLOCK)
				--		JOIN dbo.CalibrationManagment CM WITH(NOLOCK) ON AC.AssetRecordId = CM.AssetRecordId
				--		JOIN dbo.AssetInventory AIN WITH(NOLOCK) ON AIN.AssetRecordId = CM.AssetRecordId
				--	WHERE DATEDIFF(DAY, NextCalibrationDate, GETDATE()) >= AC.CalibrationFrequencyDays AND AIN.InventoryStatusId = 1

				--UPDATE AIN
				--	SET StatusNote='Check into WO #' + WO.WorkOrderNum
				--	FROM dbo.AssetInventory AIN WITH(NOLOCK)
				--		JOIN CheckInCheckOutWorkOrderAsset CIWOA WITH(NOLOCK) ON AIN.AssetInventoryId=CIWOA.AssetInventoryId
				--		JOIN WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = CIWOA.WorkOrderId
				--	WHERE AIN.InventoryStatusId = 4

				--UPDATE AIN
				--	SET StatusNote='Check out to WO #' + WO.WorkOrderNum
				--	FROM dbo.AssetInventory AIN WITH(NOLOCK)
				--		JOIN CheckInCheckOutWorkOrderAsset CIWOA WITH(NOLOCK) ON AIN.AssetInventoryId=CIWOA.AssetInventoryId
				--		JOIN WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = CIWOA.WorkOrderId
				--	WHERE AIN.InventoryStatusId = 2

				--UPDATE AIN
				--	SET StatusNote='This Inventory is been sold out'
				--	FROM dbo.AssetInventory AIN WITH(NOLOCK)
				--	WHERE AIN.InventoryStatusId = 11

				--UPDATE AIN
				--	SET StatusNote='This Inventory is Damaged'
				--	FROM dbo.AssetInventory AIN WITH(NOLOCK)
				--	WHERE AIN.InventoryStatusId = 13

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateAssetCalibrationStatusActiveList' 
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