/***************************************************************  
 ** File:   [USP_SingleScreen_GetDropdownlistData]             
 ** Author:   Vishal Suthar  
 ** Description: This stored procedure is used to get single screen  dropdown data 
 ** Purpose:           
 ** Date:   04/02/2024
            
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  	Change Description              
 ** --   --------     -------		--------------------------------            
    1    04/02/2024   Vishal Suthar	 Created  

**************************************************************/
-- EXEC USP_SingleScreen_GetDropdownlistData @PageName=N'ManagementStructureType',@MasterCompanyId=1,@SelectFields=N'MSTypeId as id,Name as name',@Filter=N'',@SortBy=N'SequenceNo'
CREATE   PROCEDURE [dbo].[USP_SingleScreen_GetDropdownlistData] 
	@PageName varchar(100) = NULL,
	@SelectFields varchar(max) = NULL,
	@Filter varchar(max) = NULL,
	@SortBy varchar(100) = NULL,
	@MasterCompanyId int = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
    DECLARE @Erorr AS varchar
    DECLARE @FilterQuery AS varchar(max)
    DECLARE @Query AS varchar(max)

    IF (NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = @PageName))
    BEGIN
      SET @Erorr = @PageName + ' Screen table is not available';
      RAISERROR (@Erorr, 16, 1);
      RETURN
    END

    IF (ISNULL(@Filter, '') != '')
    BEGIN
      SET @FilterQuery = 'WHERE ' + @Filter + ' AND (MasterCompanyId =' + CAST(@MasterCompanyId AS varchar) + ' OR MasterCompanyId = 0) '
    END
    ELSE
    BEGIN
      SET @FilterQuery = ' WHERE (MasterCompanyId =' + CAST(@MasterCompanyId AS varchar) + ' OR MasterCompanyId = 0 ) '
    END

    IF (@PageName = 'ManagementStructureType')
    BEGIN
      SET @FilterQuery += ' AND SequenceNo NOT IN (1) ';
      SET @SortBy = 'SequenceNo';
    END

    SET @Query = 'SELECT ' + @SelectFields + ' FROM [' + @PageName + '] WITH (NOLOCK)' + @FilterQuery + ' ORDER BY ' + @SortBy

    EXEC (@Query)
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_SingleScreen_GetDropdownlistData',
            @ProcedureParameters varchar(max) = '@SelectFields = ''' + CAST(ISNULL(@SelectFields, '') AS varchar(max))
            + '@PageName = ''' + CAST(ISNULL(@PageName, '') AS varchar(100))
            + '@Filter = ''' + CAST(ISNULL(@Filter, '') AS varchar(max))
            + '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(max))
            + '@SortBy = ''' + CAST(ISNULL(@SortBy, '') AS varchar(100)),
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