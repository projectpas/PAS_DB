/*************************************************************               
 ** File:   [sp_SubworkOrderUpdate8130fromdata]               
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to update 8130 form islock data 
 ** Purpose:             
 ** Date:   05/23/2023        
 ** PARAMETERS:               
 ** RETURN VALUE:             
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author       Change Description                
 ** --   --------     -------  --------------------------------              
    1                 Unknown       Created 
	2    17-12-2024   Moin Bloch    Update 8130 Lock / Unlock data 
	3    19-12-2024   Moin Bloch    Update for 8130 form islock data 
    
-- EXEC [dbo].[sp_SubworkOrderUpdate8130fromdata] 573,559    
**************************************************************/ 
CREATE Procedure [dbo].[sp_SubworkOrderUpdate8130fromdata]
@SubWorkOrderId BIGINT,
@SubWOPartNoId BIGINT,
@isFromSettlement BIT=0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON   

	BEGIN TRY
	BEGIN TRANSACTION
	
	DECLARE @WorkOrderSettlementId INT = 0;
	SELECT @WorkOrderSettlementId = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE [WorkOrderSettlementName] = 'Release Certs (e.g. 8130) Reviewed';
	
	IF(ISNULL(@isFromSettlement,0) = 0)
	BEGIN
		IF OBJECT_ID(N'tempdb..#SWO8130Detail') IS NOT NULL
		BEGIN
			DROP TABLE #SWO8130Detail
		END

		CREATE TABLE #SWO8130Detail
		(
			[ID] BIGINT NOT NULL IDENTITY,		
			[FormTypeId] INT NULL,
			[IsLocked] BIT NULL
		)

		INSERT INTO #SWO8130Detail ([FormTypeId],[IsLocked])
		SELECT [FormTypeId],[IsLocked] FROM [dbo].[SubWorkOrder_ReleaseFrom_8130] WITH(NOLOCK)
		WHERE [SubWorkOrderId] = @SubWorkOrderId AND [SubWOPartNoId] = @SubWOPartNoId  
		
		DECLARE @TotCount AS INT;
		DECLARE @Count INT = 0;
		DECLARE @LoopID AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #SWO8130Detail;

		WHILE (@LoopID <= @TotCount)
		BEGIN		
			DECLARE @IsLocked BIT = 0
		
			SELECT @IsLocked = [IsLocked] FROM #SWO8130Detail WHERE [ID] = @LoopID;
			IF(@IsLocked = 1)
			BEGIN
				SET @Count = @Count + 1;
			END		
		
			SET @LoopID = @LoopID + 1;
		END		
		IF(@TotCount = @Count)
		BEGIN
			UPDATE [SubWorkOrderPartNumber] SET [IsLocked] = 1 WHERE [SubWorkOrderId] = @SubWorkOrderId AND [SubWOPartNoId] = @SubWOPartNoId;  
			UPDATE [SubWorkOrderSettlementDetails] SET [IsMastervalue] = 1 WHERE [WorkOrderSettlementId] = @WorkOrderSettlementId AND [SubWorkOrderId] = @SubWorkOrderId AND [SubWOPartNoId] = @SubWOPartNoId;
		END
		ELSE
		BEGIN
			UPDATE [SubWorkOrderPartNumber] SET [IsLocked] = 0 WHERE [SubWorkOrderId] = @SubWorkOrderId AND [SubWOPartNoId] = @SubWOPartNoId;  
			UPDATE [SubWorkOrderSettlementDetails] SET [IsMastervalue] = 0 WHERE [WorkOrderSettlementId] = @WorkOrderSettlementId AND [SubWorkOrderId] = @SubWorkOrderId AND [SubWOPartNoId] = @SubWOPartNoId;
		END	
	END
	ELSE
	BEGIN
		UPDATE [dbo].[SubWorkOrder_ReleaseFrom_8130] SET [IsLocked] = 1 WHERE [SubWorkOrderId] = @SubWorkOrderId AND [SubWOPartNoId] = @SubWOPartNoId;  
		UPDATE [dbo].[SubWorkOrderPartNumber] SET [IsLocked] = 1 WHERE [SubWorkOrderId] = @SubWorkOrderId AND [SubWOPartNoId] = @SubWOPartNoId;  
		UPDATE [dbo].[SubWorkOrderSettlementDetails] SET [IsMastervalue] = 1 WHERE [WorkOrderSettlementId] = @WorkOrderSettlementId AND [SubWorkOrderId] = @SubWorkOrderId AND [SubWOPartNoId] = @SubWOPartNoId;
	END
			
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRANSACTION;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	  , @AdhocComments     VARCHAR(150)    = 'sp_SubworkOrderUpdate8130fromdata' 
	  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SubWorkOrderId, '') AS VARCHAR(100)) + 
											  '@Parameter2 = '''+ CAST(ISNULL(@SubWOPartNoId, '') AS VARCHAR(100)) 	
	  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  exec spLogException 
			   @DatabaseName           = @DatabaseName
			 , @AdhocComments          = @AdhocComments
			 , @ProcedureParameters    = @ProcedureParameters
			 , @ApplicationName        =  @ApplicationName
			 , @ErrorLogID             = @ErrorLogID OUTPUT ;
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
	  RETURN(1);
	END CATCH
END