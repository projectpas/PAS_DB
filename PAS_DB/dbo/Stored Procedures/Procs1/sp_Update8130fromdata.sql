/*************************************************************               
 ** File:   [sp_Update8130fromdata]               
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
    
-- EXEC [dbo].[sp_Update8130fromdata] 4656,4219  
   EXEC [dbo].[sp_Update8130fromdata] 4655,4218
**************************************************************/   
CREATE Procedure [dbo].[sp_Update8130fromdata]
@WorkorderId BIGINT,
@workOrderPartNoId BIGINT,
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
		IF OBJECT_ID(N'tempdb..#8130Detail') IS NOT NULL
		BEGIN
			DROP TABLE #8130Detail
		END

		CREATE TABLE #8130Detail
		(
			[ID] BIGINT NOT NULL IDENTITY,		
			[FormTypeId] INT NULL,
			[IsLocked] BIT NULL
		)

		INSERT INTO #8130Detail ([FormTypeId],[IsLocked])
		SELECT [FormTypeId],[IsLocked] FROM [dbo].[Work_ReleaseFrom_8130] WITH(NOLOCK)
		WHERE [WorkorderId] = @WorkorderId AND [workOrderPartNoId] = @workOrderPartNoId  
		
		DECLARE @TotCount AS INT;
		DECLARE @Count INT = 0;
		DECLARE @LoopID AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #8130Detail;

		WHILE (@LoopID <= @TotCount)
		BEGIN		
			DECLARE @IsLocked BIT = 0
		
			SELECT @IsLocked = [IsLocked] FROM #8130Detail WHERE [ID] = @LoopID;
			IF(@IsLocked = 1)
			BEGIN
				SET @Count = @Count + 1;
			END		
		
			SET @LoopID = @LoopID + 1;
		END		
		IF(@TotCount = @Count)
		BEGIN
			UPDATE [WorkOrderPartNumber] SET [IsLocked] = 1 WHERE [WorkOrderId] = @WorkorderId AND [ID] = @workOrderPartNoId;  
			UPDATE [WorkOrderSettlementDetails] SET [IsMastervalue] = 1 WHERE [WorkOrderSettlementId] = @WorkOrderSettlementId AND [WorkOrderId] = @WorkorderId AND [workOrderPartNoId] = @workOrderPartNoId; 
		END
		ELSE
		BEGIN
			UPDATE [WorkOrderPartNumber] SET [IsLocked] = 0 WHERE [WorkOrderId] = @WorkorderId AND [ID] = @workOrderPartNoId;  
			UPDATE [WorkOrderSettlementDetails] SET [IsMastervalue] = 0 WHERE [WorkOrderSettlementId] = @WorkOrderSettlementId AND [WorkOrderId] = @WorkorderId AND [workOrderPartNoId] = @workOrderPartNoId; 
		END	
	END
	ELSE
	BEGIN
		UPDATE [dbo].[Work_ReleaseFrom_8130] SET [IsLocked] = 1 WHERE [WorkorderId] = @WorkorderId AND [workOrderPartNoId] = @workOrderPartNoId;  
		UPDATE [dbo].[WorkOrderPartNumber] SET [IsLocked] = 1 WHERE [WorkOrderId] = @WorkorderId AND [ID] = @workOrderPartNoId;  
		UPDATE [dbo].[WorkOrderSettlementDetails] SET [IsMastervalue] = 1 WHERE [WorkOrderSettlementId] = @WorkOrderSettlementId AND [WorkOrderId] = @WorkorderId AND [workOrderPartNoId] = @workOrderPartNoId; 		
	END
			
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRANSACTION;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	  , @AdhocComments     VARCHAR(150)    = 'sp_Update8130fromdata' 
	  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@WorkorderId, '') AS VARCHAR(100)) + 
											  '@Parameter2 = '''+ CAST(ISNULL(@workOrderPartNoId, '') AS VARCHAR(100)) 	
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