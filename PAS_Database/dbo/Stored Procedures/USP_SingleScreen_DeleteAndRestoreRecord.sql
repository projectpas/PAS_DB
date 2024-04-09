/***************************************************************  
 ** File:   [USP_SingleScreen_DeleteAndRestoreRecord]             
 ** Author:   Vishal Suthar  
 ** Description: This stored procedure is used to delete/restore data for single screen pages
 ** Purpose:           
 ** Date:   04/04/2024  
            
 ** Change History             
 **************************************************************             
 ** PR   Date         Author  		Change Description              
 ** --   --------     -------		--------------------------------            
    1    04/04/2024   Vishal Suthar	Created  

**************************************************************/
-- EXEC  USP_SingleScreen_DeleteAndRestoreRecord 10, 'assetlocation'
CREATE   PROCEDURE [dbo].[USP_SingleScreen_DeleteAndRestoreRecord]  
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
    DECLARE @PrimaryColumn AS VARCHAR(100);  
  
    IF (NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = @PageName))  
    BEGIN  
      SET @Erorr = @PageName + ' Screen table is not available';  
      RAISERROR (@Erorr, 16, 1);  
      RETURN  
    END  
  
    IF (NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @PageName AND COLUMN_NAME = 'IsDeleted'))  
    BEGIN  
      SET @Erorr = ' IsDeleted column is not available in ' + @PageName;  
      RAISERROR (@Erorr, 16, 1)  
      RETURN  
    END  
 
	EXEC [DBO].[USP_InsertAuditDataForSingleScreen] @ID,@PageName,@PrimaryKey 

    SET @Query = 'UPDATE [' + @PageName + '] SET IsDeleted  =' + CAST(@Status AS VARCHAR) + '  WHERE ' + @PrimaryKey + ' = ' + CAST(@ID AS VARCHAR)  
    EXEC (@Query)  
  END TRY  
  BEGIN CATCH  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,@AdhocComments varchar(150) = 'USP_SingleScreen_DeleteAndRestoreRecord',  
            @ProcedureParameters varchar(3000) = '@ID = ''' + CAST(ISNULL(@ID, '') AS varchar(100))  
            + '@PageName = ''' + CAST(ISNULL(@PageName, '') AS varchar(100))  
            + '@Status = ''' + CAST(ISNULL(@Status, '') AS varchar(100))  
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