CREATE Procedure [dbo].[sp_Update8130fromdata]
@WorkorderId bigint,
@workOrderPartNoId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON   

	BEGIN TRY
	BEGIN TRANSACTION
		UPDATE [Work_ReleaseFrom_8130] SET IsClosed = 1 WHERE WorkOrderId = @WorkorderId AND workOrderPartNoId = @workOrderPartNoId  
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRANSACTION;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	  , @AdhocComments     VARCHAR(150)    = 'sp_Update8130fromdata' 
	  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@WorkorderId, '') as Varchar(100)) + 
											  '@Parameter2 = '''+ CAST(ISNULL(@workOrderPartNoId, '') as Varchar(100)) 	
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