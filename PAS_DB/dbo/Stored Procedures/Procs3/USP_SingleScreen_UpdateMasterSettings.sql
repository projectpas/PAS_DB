/*************************************************************             
 ** File:   [USP_SingleScreen_UpdateMasterSettings]             
 ** Author: Vishal Suthar  
 ** Description: This stored procedure is used to update module wise settings
 ** Date:   04/02/2024
            
 ** PARAMETERS:             
 @EmailTypeIdId INT
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
  ** PR   Date        Author  	         Change Description              
  ** --   --------    ---------------	 --------------------------------            
     1    04/02/2024  Vishal Suthar		 Created  
       
 EXECUTE USP_SingleScreen_UpdateMasterSettings 'workordermastersettings', 2
**************************************************************/
CREATE PROCEDURE [dbo].[USP_SingleScreen_UpdateMasterSettings]
	@PageName VARCHAR(100),
	@ReferenceId bigint
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    IF (@PageName = 'workordermastersettings')
    BEGIN
		IF EXISTS (SELECT TOP 1 * FROM [DBO].[WorkOrderMasterSettings] WHERE WorkOrderMasterSettingsId = @ReferenceId AND IsDefaultSettings = 1)
		BEGIN
			UPDATE [DBO].[WorkOrderMasterSettings]
			SET IsDefaultSettings = 0
			WHERE WorkOrderMasterSettingsId NOT IN (@ReferenceId)
		END
    END
	ELSE IF (@PageName = 'SalesOrderQuoteMasterSettings')
    BEGIN
		IF EXISTS (SELECT TOP 1 * FROM [DBO].[SalesOrderQuoteMasterSettings] WHERE SalesOrderQuoteMasterSettingsId = @ReferenceId AND IsDefaultSettings = 1)
		BEGIN
			UPDATE [DBO].[SalesOrderQuoteMasterSettings]
			SET IsDefaultSettings = 0
			WHERE SalesOrderQuoteMasterSettingsId NOT IN (@ReferenceId)
		END
    END
	ELSE IF (@PageName = 'SalesOrderMasterSettings')
    BEGIN
		IF EXISTS (SELECT TOP 1 * FROM [DBO].[SalesOrderMasterSettings] WHERE SalesOrderMasterSettingsId = @ReferenceId AND IsDefaultSettings = 1)
		BEGIN
			UPDATE [DBO].[SalesOrderMasterSettings]
			SET IsDefaultSettings = 0
			WHERE SalesOrderMasterSettingsId NOT IN (@ReferenceId)
		END
    END
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_SingleScreen_UpdateMasterSettings',
            @ProcedureParameters varchar(3000) = '@EmployeeId = ''' + CAST(ISNULL(@PageName, '') AS varchar(100))
            + '@MasterCompanyId = ''' + CAST(ISNULL(@ReferenceId, '') AS varchar(100)),
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