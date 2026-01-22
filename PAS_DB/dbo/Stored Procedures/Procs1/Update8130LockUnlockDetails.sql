/*************************************************************               
 ** File:   [Update8130LockUnlockDetails]               
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to update 8130 form islock data 
 ** Purpose:             
 ** Date:   17/12/2024        
 ** PARAMETERS:               
 ** RETURN VALUE:             
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author       Change Description                
 ** --   --------     -------  --------------------------------               
	1    17-12-2024   Moin Bloch   Created
	2    19-12-2024   Moin Bloch   Update for 8130 form islock data 
	3    11-02-2025   Moin Bloch   Update for 8130 serial number when update 
    
-- EXEC [dbo].[Update8130LockUnlockDetails] 573,559    
**************************************************************/ 
CREATE   PROCEDURE [dbo].[Update8130LockUnlockDetails]
@WorkorderId BIGINT,
@WorkOrderPartNoId BIGINT,
@SubWorkOrderId BIGINT,
@SubWOPartNoId BIGINT,
@IsWorkOrder BIT,
@SerialNumber VARCHAR(50)=''
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON   

	BEGIN TRY
	BEGIN TRANSACTION
	
	DECLARE @WorkOrderSettlementId INT = 0;
	SELECT @WorkOrderSettlementId = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE [WorkOrderSettlementName] = 'Release Certs (e.g. 8130) Reviewed';
	
	IF(@IsWorkOrder=1)
	BEGIN
		UPDATE [dbo].[Work_ReleaseFrom_8130] SET [IsLocked] = 0, [Batchnumber] = @SerialNumber,[PDFPath] = NULL WHERE [WorkorderId] = @WorkorderId AND [workOrderPartNoId] = @workOrderPartNoId;  
		UPDATE [dbo].[WorkOrderSettlementDetails] SET [IsMastervalue] = 0 WHERE [WorkOrderSettlementId] = @WorkOrderSettlementId AND [WorkOrderId] = @WorkorderId AND [workOrderPartNoId] = @workOrderPartNoId; 
	END
	ELSE
	BEGIN	
		UPDATE [dbo].[SubWorkOrder_ReleaseFrom_8130] SET [IsLocked] = 0,[PDFPath] = NULL,[Batchnumber] = @SerialNumber  WHERE [SubWorkOrderId] = @SubWorkOrderId AND [SubWOPartNoId] = @SubWOPartNoId;  
		UPDATE [dbo].[SubWorkOrderSettlementDetails] SET [IsMastervalue] = 0 WHERE [WorkOrderSettlementId] = @WorkOrderSettlementId AND [SubWorkOrderId] = @SubWorkOrderId AND [SubWOPartNoId] = @SubWOPartNoId;
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
	  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SubWorkOrderId, '') as Varchar(100)) + 
											  '@Parameter2 = '''+ CAST(ISNULL(@SubWOPartNoId, '') as Varchar(100)) 	
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