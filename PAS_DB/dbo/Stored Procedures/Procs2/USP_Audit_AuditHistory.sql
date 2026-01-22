/*************************************************************               
 ** File:   [USP_Audit_AuditHistory]               
 ** Author:   Vishal Suthar    
 ** Description: This stored procedure is used for audit history  
 ** Date:   13/07/2022            
              
 ** PARAMETERS:  
  
 ** RETURN VALUE:  
  
 **************************************************************  
 ** Change History  
 **************************************************************  
 ** PR   Date        Author     Change Description  
 ** --   --------    --------------- -----------------------  
    1    13/07/2022  Vishal Suthar  Created  
  
**************************************************************/  
CREATE PROCEDURE [dbo].[USP_Audit_AuditHistory]  
(   
 @PageName VARCHAR(100),  
 @AuditFields AuditFields READONLY  
)  
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  BEGIN TRY  
    BEGIN TRANSACTION  
  DECLARE @cols AS NVARCHAR(MAX), @query  AS NVARCHAR(MAX);  
    
  SELECT @cols = STUFF((SELECT ',' + QUOTENAME(FieldName)   
            FROM @AuditFields  
   FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '')  
    
  SET @query = N'  
  ;WITH Xtw AS (SELECT ' + @cols + N' from   
            (  
            select FieldValue, FieldName from @AuditFields  
        ) x  
        pivot   
        (  
            max(FieldValue)  
            for FieldName in (' + @cols + N')  
        ) p)   
     
  INSERT INTO [DBO].' + @PageName + 'Audit   
  (' + @cols + ')  
  SELECT ' + @cols + ' FROM Xtw;'  
  print @query
  EXEC sp_executesql @query, N'@AuditFields AuditFields READONLY', @AuditFields;  
  
    COMMIT TRANSACTION  
  END TRY  
  BEGIN CATCH  
    ROLLBACK TRANSACTION  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,@AdhocComments varchar(150) = 'USP_Audit_AuditHistory',  
            @ProcedureParameters varchar(3000) = '',  
            @ApplicationName varchar(100) = 'PAS'  
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC spLogException @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
    RETURN (1);  
  END CATCH  
END