CREATE    PROCEDURE [DBO].[USP_SetDefaultReportingStructure]  
(  
  @Id bigint = NULL
)  
AS  
BEGIN  
 SET NOCOUNT ON;      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED       
 BEGIN TRY  
  BEGIN TRAN
	UPDATE dbo.ReportingStructure SET IsDefault = 0;

	UPDATE dbo.ReportingStructure SET IsDefault = 1 WHERE ReportingStructureId = @Id;

  COMMIT TRAN

 END TRY  
 BEGIN CATCH  
 IF(@@TRANCOUNT > 1)
	ROLLBACK

  DECLARE @ErrorLogID INT      
    ,@DatabaseName VARCHAR(100) = db_name()      
    -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
    ,@AdhocComments VARCHAR(150) = 'USP_SetDefaultReportingStructure'      
    ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@Id, '') AS varchar(100))      
  ,@ApplicationName VARCHAR(100) = 'PAS'      
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
    EXEC spLogException @DatabaseName = @DatabaseName      
  ,@AdhocComments = @AdhocComments      
  ,@ProcedureParameters = @ProcedureParameters      
  ,@ApplicationName = @ApplicationName      
  ,@ErrorLogID = @ErrorLogID OUTPUT;      
      
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)      
      
    RETURN (1);    
 END CATCH  
END