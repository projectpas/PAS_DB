/***************************************************************  
** File:   [USP_SingleScreen_UpdateActiveInActiveStatus]             
** Author:   Dipak Karena  
** Description: This stored procedure is used to update active- inactive status for single screen pages
** Purpose:           
** Date:   05/17/2022  
            
** Change History             
**************************************************************             
** PR   Date         Author  		Change Description              
** --   --------     -------		--------------------------------            
   1    05/17/2022   Dipak Karena	Created  
       
**************************************************************/
--EXEC  USP_SingleScreen_UpdateActiveInActiveStatus 10, 0, 'assetlocation'
CREATE     PROCEDURE [dbo].[USP_SingleScreen_UpdateActiveInActiveStatus]   
 @ID INT = NULL,  
 @Status BIT = NULL,  
 @PageName VARCHAR(100) = NULL,  
 @PrimaryKey VARCHAR(100) = NULL  
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  BEGIN TRY  
    DECLARE @Erorr AS VARCHAR;  
    DECLARE @Query AS VARCHAR(MAX);  
  
    IF (NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = @PageName))  
    BEGIN  
      SET @Erorr = @PageName + ' Screen table is not available';  
      RAISERROR (@Erorr, 16, 1);  
      RETURN  
    END  
  
    IF (NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @PageName AND COLUMN_NAME = 'IsActive'))  
    BEGIN  
      SET @Erorr = ' Is active column is not available in ' + @PageName;  
      RAISERROR (@Erorr, 16, 1)  
      RETURN  
    END  
  
	EXEC [DBO].[USP_InsertAuditDataForSingleScreen] @ID,@PageName,@PrimaryKey 

    SET @Query = 'UPDATE [' + @PageName + '] SET IsActive =' + CAST(@Status AS VARCHAR) + ' WHERE ' + @PrimaryKey + ' = ' + CAST(@ID AS VARCHAR)  
  
    EXEC (@Query)  
  END TRY  
  BEGIN CATCH  
    DECLARE @ErrorLogID INT,  
            @DatabaseName VARCHAR(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,@AdhocComments VARCHAR(150) = 'USP_SingleScreen_UpdateActiveInActiveStatus',  
            @ProcedureParameters VARCHAR(3000) = '@ID = ''' + CAST(ISNULL(@ID, '') AS VARCHAR(100))  
            + '@PageName = ''' + CAST(ISNULL(@PageName, '') AS VARCHAR(100))  
            + '@Status = ''' + CAST(ISNULL(@Status, '') AS VARCHAR(100))  
            + '@PrimaryKey = ''' + CAST(ISNULL(@PrimaryKey, '') AS VARCHAR(100)),  
            @ApplicationName VARCHAR(100) = 'PAS'  
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC spLogException @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
  END CATCH  
END