/***************************************************************  
 ** File:   [USP_SingleScreen_GetSingleScreenDataById]             
 ** Author:   Vishal Suthar  
 ** Description: This stored procedure is used to get data by id 
 ** Purpose:           
 ** Date:   04/02/2024  
            
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  		Change Description              
 ** --   --------     -------		--------------------------------            
    1    04/02/2024   Vishal Suthar	Created  

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SingleScreen_GetSingleScreenDataById] 
	@ID int = NULL,
	@PageName varchar(100) = NULL,
	@PrimaryKey varchar(100) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
    DECLARE @Erorr AS varchar(max);
    DECLARE @Query AS varchar(max) = '';

    IF (NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = @PageName))
    BEGIN
      SET @Erorr = @PageName + ' Screen table is not available';
      RAISERROR (@Erorr, 16, 1);
      RETURN
    END

    SET @Query = 'SELECT * FROM [' + @PageName + '] WITH (NOLOCK) WHERE ' + @PrimaryKey + ' = ' + CAST(@ID AS varchar)
    EXEC (@Query)
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_SingleScreen_GetSingleScreenDataById',
            @ProcedureParameters varchar(max) = '@ID = ''' + CAST(ISNULL(@ID, '') AS varchar(max))
            + '@PageName = ''' + CAST(ISNULL(@PageName, '') AS varchar(max))
            + '@PrimaryKey = ''' + CAST(ISNULL(@PrimaryKey, '') AS varchar(max)),
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