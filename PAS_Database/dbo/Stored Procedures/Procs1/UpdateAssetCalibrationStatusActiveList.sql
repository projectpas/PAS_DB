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
    3    13-12-2023   Devendra SHekh		changes for status update

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
				@NextCalibrationDate DateTime2, @lastCalibrationDate DateTime2, @CalibrationFrequencyDays BIGINT = 0, @DayTillNextCal BIGINT = 0;

				IF OBJECT_ID(N'tempdb..#tmpAssetInventory') IS NOT NULL  
				BEGIN  
					DROP TABLE #tmpAssetInventory 
				END  
				
				CREATE TABLE #tmpAssetInventory(
					[Id] [BIGINT] IDENTITY(1,1) NOT NULL,
					[AssetInventoryId] [BIGINT] NULL,
					[CalibrationId] [BIGINT] NULL,
					[InventoryStatusId] [BIGINT] NULL,
					[DayTillNextCal] [BIGINT] NULL,
					[CalibrationDate] [dateTime2] NULL,
					[CalibrationFrequencyDays] [BIGINT] NULL,
					[CalibrationFrequencyMonths] [INT] NULL,
					[NextCalibrationDate] [dateTime2] NULL,
					[LastCalibrationDate] [dateTime2] NULL,
					[DepreciationFrequencyName] [varchar](150) NULL,
					[DepreciationFrequencyId] [BIGINT] NULL,
					[CreatedDate] [dateTime2] NULL,
					[EntryDate] [dateTime2] NULL,
				)  

				INSERT INTO #tmpAssetInventory( [AssetInventoryId], [CalibrationId], [InventoryStatusId], 
							[DayTillNextCal],
							[CalibrationDate], [CalibrationFrequencyDays], [CalibrationFrequencyMonths], [NextCalibrationDate], [LastCalibrationDate],[DepreciationFrequencyName], 
							[DepreciationFrequencyId], [CreatedDate], [EntryDate])
				SELECT DISTINCT	AIN.AssetInventoryId, [CalibrationId], AIN.InventoryStatusId, 
								DATEDIFF(day, getDate(), CASE WHEN ISNULL(NextCalibrationDate, '') != '' THEN NextCalibrationDate  ELSE DATEADD(DAY, ISNULL(CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(CalibrationFrequencyMonths,0),
								(CASE WHEN ISNULL(LastCalibrationDate, '') != '' THEN LastCalibrationDate ELSE CalibrationDate END))) END) AS DayTillNextCal,
								CalibrationDate, [CalibrationFrequencyDays], [CalibrationFrequencyMonths], NextCalibrationDate, LastCalibrationDate, AIN.[DepreciationFrequencyName], 
								AIN.[DepreciationFrequencyId], AIN.[CreatedDate], AIN.[EntryDate]
				FROM dbo.AssetInventory AIN WITH(NOLOCK)
					JOIN dbo.CalibrationManagment CM WITH(NOLOCK) ON AIN.AssetInventoryId = CM.AssetInventoryId
					WHERE AIN.InventoryStatusId = (SELECT [AssetInventoryStatusId] FROM [dbo].[AssetInventoryStatus] WITH(NOLOCK) WHERE [Status] = 'Available') AND AIN.CalibrationRequired=1

				--select * from #tmpAssetInventory

				SET @TotalRec = (SELECT COUNT(Id) FROM #tmpAssetInventory)

				WHILE(@StartCount <= @TotalRec)
				BEGIN

					SELECT @DepreciationId = [DepreciationFrequencyId], @InventoryId = [AssetInventoryId], @CalibrationFrequencyDays = [CalibrationFrequencyDays],
						   @lastCalibrationDate = ISNULL([LastCalibrationDate], [EntryDate]), @NextCalibrationDate = CONVERT(date, ISNULL([NextCalibrationDate], [EntryDate])),
						   @DayTillNextCal = DayTillNextCal
						   FROM #tmpAssetInventory WHERE Id = @StartCount

					UPDATE AIN
					SET StatusNote = 'Calibration Due', InventoryStatusId = (SELECT [AssetInventoryStatusId] FROM [dbo].[AssetInventoryStatus] WITH(NOLOCK) WHERE [Status] = 'UnAvailable')
					FROM dbo.AssetInventory AIN WITH(NOLOCK)
					WHERE @DayTillNextCal < 0 AND AIN.AssetInventoryId = @InventoryId

					PRINT @InventoryId
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