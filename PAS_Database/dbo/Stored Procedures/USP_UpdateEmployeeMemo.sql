/*************************************************************           
 ** File:   [USP_UpdateEmployeeMemo]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get UpdateEmployeeMemo List
 ** Purpose:         
 ** Date:   25-08-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    25-08-2025    Sahdev Saliya       Created  

	exec [USP_UpdateEmployeeMemo] 
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateEmployeeMemo]
    @EmployeeId BIGINT,
    @Memo VARCHAR(256) = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY

        IF EXISTS (SELECT 1 FROM [dbo].Employee  WITH(NOLOCK) WHERE EmployeeId = @EmployeeId AND IsDeleted = 0)
        BEGIN
            UPDATE [dbo].Employee
            SET Memo = @Memo,
                UpdatedDate = GETUTCDATE()
            WHERE EmployeeId = @EmployeeId;

        END
    END TRY
    BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_UpdateEmployeeMemo' 
				  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') as varchar(100))   
				  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

				  exec spLogException 
						   @DatabaseName			= @DatabaseName
						 , @AdhocComments			= @AdhocComments
						 , @ProcedureParameters		= @ProcedureParameters
						 , @ApplicationName			= @ApplicationName
						 , @ErrorLogID              = @ErrorLogID OUTPUT ;
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
				  RETURN
	END CATCH
END