/***************************************************************  
 ** File:  [USP_InsertAuditDataForSingleScreen]             
 ** Author:  Satish Gohil
 ** Description: This stored procedure main purpose is Manage the Audit history of Single Screen
 ** Purpose:
 ** Date:   12/19/2022
            
 ** Change History             
 ****************************************************************             
 ** PR   Date         Author  		Change Description              
 ** --   --------     -------		--------------------------------            
    1    12/19/2022   Satish Gohil	Created

*****************************************************************/

CREATE   PROCEDURE [dbo].[USP_InsertAuditDataForSingleScreen]
(
	@ID BIGINT,
	@PageName Varchar(100) =NULL,
	@PrimaryKey VARCHAR(100) = NULL 
)
AS
BEGIN
	BEGIN TRY
		DECLARE @Where AS varchar(500);    
		SET @Where = ' WHERE ' + @PrimaryKey + '=' + CAST(@ID AS varchar(100));    
    
		DECLARE @AuditFields AuditFields;
    
		INSERT INTO @AuditFields (FieldName, FieldValue)    
		EXEC [dbo].[USP_GenerateFieldNameValueList] @PageName, @Where 

		IF EXISTS (SELECT TOP 1 * FROM @AuditFields)    
		BEGIN    
			EXECUTE USP_Audit_AuditHistory @PageName, @AuditFields    
		END  

	END TRY
	BEGIN CATCH
		
		DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,@AdhocComments varchar(150) = 'USP_InsertAuditDataForSingleScreen',  
            @ProcedureParameters varchar(3000) = '@ID = ''' + CAST(ISNULL(@ID, '') AS varchar(100))  
            + '@PageName = ''' + CAST(ISNULL(@PageName, '') AS varchar(100))  
            + '@PrimaryKey = ''' + CAST(ISNULL(@PrimaryKey, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'  
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC spLogException @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
		
	END CATCH
END