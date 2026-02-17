/*********************             
 ** File:        [dbo].[usp_Get_AuditLogDisplayColumnsByModule]        
 ** Author:      AYUSHI PATEL    
 ** Description: Returns ColumnName + DisplayName for a ModuleId  
 ** Purpose:     Used by UI to map audit log column headers  
 ** Date:        18-DEC-2025  
            
 ** PARAMETERS:             
 **   @ModuleId - maps to Module.ModuleId           
           
 ** RETURN VALUE:             
 **   ColumnName, DisplayName  
 **********************             
 ** Change History             
 **********************             
 ** S NO   Date           Author              Change Description              
 ** --     --------       -------------       --------------------------------            
    1      18-DEC-2025    AYUSHI PATEL        Created  
    2      16-FEB-2026    DIVYESH KATHIRIYA   Set Table Name for SalesOrderQuote.

    EXEC usp_Get_AuditLogDisplayColumnsByModule @ModuleId=7
**********************/

CREATE PROC [dbo].[usp_Get_AuditLogDisplayColumnsByModule]
    @ModuleId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY 
    DECLARE @TableName VARCHAR(128);

    SELECT @TableName = ModuleName 
    FROM dbo.Module WITH (NOLOCK)
    WHERE ModuleId = @ModuleId;  

    IF(@TableName = 'SalesQuote')
    BEGIN
        SET @TableName = 'SalesOrderQuote';
    END 

    IF @TableName IS NULL
    BEGIN
        SELECT TOP 0 
            ColumnName,
            DisplayName,
            SeqNo
        FROM dbo.AuditLogDisplayColumns;
        RETURN;
    END

    SELECT 
        ColumnName,
        DisplayName,
        SeqNo
    FROM dbo.AuditLogDisplayColumns WITH (NOLOCK)
    WHERE TableName = @TableName 
    ORDER BY SeqNo;

END TRY      
  BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'usp_Get_AuditLogDisplayColumnsByModule'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ModuleId, '') + ''  
            , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
            exec spLogException   
                    @DatabaseName           = @DatabaseName  
                    , @AdhocComments          = @AdhocComments  
                    , @ProcedureParameters = @ProcedureParameters  
                    , @ApplicationName        =  @ApplicationName  
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
            RETURN(1);  
 END CATCH          
END