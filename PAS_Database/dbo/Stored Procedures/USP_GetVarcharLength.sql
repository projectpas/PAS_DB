/***************************************************************  
 ** File:   [[USP_GetVarcharLength]]             
 ** Author:  
 ** Description: 
 ** Purpose:           
 ** Date:   05/02/2026            
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  	         Change Description              
 ** --   -----        ------	         ------------------          
    1   05/02/2026    Nakul Chandigra    Created               

    exec USP_GetVarcharLength 'taxtype'
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetVarcharLength]
    @TableName SYSNAME

AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY

    SELECT
        c.name AS ColumnName,
        t.name AS DataType,
        CASE
            WHEN t.name IN ('varchar','char','binary','varbinary')
                THEN CASE WHEN c.max_length = -1 THEN NULL ELSE c.max_length END

            WHEN t.name IN ('nvarchar','nchar')
                THEN CASE WHEN c.max_length = -1 THEN NULL ELSE c.max_length / 2 END
    
            WHEN t.name IN ('decimal','numeric')
                THEN c.precision 

            ELSE NULL
        END AS MaxLength
    FROM sys.columns c
    JOIN sys.types t
        ON c.user_type_id = t.user_type_id
    WHERE c.object_id = OBJECT_ID(@TableName);

END TRY    
BEGIN CATCH    
    DECLARE @ErrorLogID int,    
            @DatabaseName varchar(100) = DB_NAME()    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
                , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_GetVarcharLength]'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
    EXEC spLogException @DatabaseName = @DatabaseName,    
                        @AdhocComments = @AdhocComments,    
                        @ProcedureParameters = @ProcedureParameters,    
                        @ApplicationName = @ApplicationName,    
                        @ErrorLogID = @ErrorLogID OUTPUT;    
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
  END CATCH    
END