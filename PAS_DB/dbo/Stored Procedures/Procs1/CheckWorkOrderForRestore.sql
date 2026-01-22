/*************************************************************               
 ** File:   [CheckWorkOrderForRestore]               
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to check work order before restoring
 ** Purpose:             
 ** Date:   08/22/2025
 ** PARAMETERS:               
 ** RETURN VALUE:             
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------			--------------------------------               
	1    08/22/2025   Vishal Suthar		Created
    
-- EXEC [dbo].[CheckWorkOrderForRestore] 4724,15,'Jim Roberts'  
**************************************************************/ 
CREATE   PROCEDURE [dbo].[CheckWorkOrderForRestore]
	@ReferenceId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON   
	BEGIN TRY
		
	DECLARE @MasterCompanyId BIGINT;
	DECLARE @ClosedWorkOrderStatusId BIGINT;
	DECLARE @CurrentSerialNumber VARCHAR(100);
	DECLARE @RevisedSerialNumber VARCHAR(100);

	SELECT @MasterCompanyId = MasterCompanyId, @CurrentSerialNumber = CurrentSerialNumber, @RevisedSerialNumber = RevisedSerialNumber 
	FROM DBO.WorkOrderPartNumber WITH (NOLOCK) WHERE WorkOrderId = @ReferenceId;

	SELECT @ClosedWorkOrderStatusId = Id FROM DBO.WorkOrderStatus WITH (NOLOCK) WHERE StatusCode = 'CLOSED';

	IF @RevisedSerialNumber IS NOT NULL
	BEGIN
		IF EXISTS (SELECT 1 FROM DBO.WorkOrderPartNumber WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId
				AND UPPER(RevisedSerialNumber) = UPPER(@RevisedSerialNumber) AND WorkOrderId <> @ReferenceId AND IsDeleted = 0 AND WorkOrderStatusId <> @ClosedWorkOrderStatusId)
		BEGIN
			SELECT 1 AS ReferenceId; -- Duplicate found
		END
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT 1 FROM DBO.WorkOrderPartNumber WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId
				AND UPPER(CurrentSerialNumber) = UPPER(@CurrentSerialNumber) AND WorkOrderId <> @ReferenceId AND IsDeleted = 0 AND WorkOrderStatusId <> @ClosedWorkOrderStatusId)
		BEGIN
			SELECT 1 AS ReferenceId; -- Duplicate found
		END
	END

	-- No duplicates found
    SELECT 0 AS ReferenceId;

	END TRY    
	BEGIN CATCH      
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	  , @AdhocComments     VARCHAR(150)    = 'CheckWorkOrderForRestore' 
	  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@ReferenceId, '') AS VARCHAR(100)) 
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