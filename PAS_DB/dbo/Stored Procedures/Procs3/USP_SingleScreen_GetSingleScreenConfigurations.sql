/***************************************************************    
 ** File:   [USP_SingleScreen_GetSingleScreenConfigurations]               
 ** Author:   Vishal Suthar    
 ** Description: This stored procedure is used to get single screen configration data  
 ** Purpose:
 ** Date:   04/01/2024    
              
  ** Change History               
 **************************************************************               
 ** PR   Date         Author  			Change Description              
 ** --   --------     -------			--------------------------------            
    1    04/01/2024   Vishal Suthar		Created
  
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SingleScreen_GetSingleScreenConfigurations] 
	@ScreenCode varchar(100) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
    DECLARE @SingleScreenId bigint;
    DECLARE @SingleScreenFieldId bigint;

    SELECT @SingleScreenId = SingleScreenId FROM DBO.SingleScreen WITH (NOLOCK) WHERE Screencode = @ScreenCode;
    
	SELECT * FROM DBO.SingleScreen WITH (NOLOCK) WHERE Screencode = @ScreenCode;

    SELECT @SingleScreenFieldId = SingleScreenFieldId FROM DBO.SingleScreenField WITH (NOLOCK) WHERE SingleScreenId = @SingleScreenId;

    SELECT * FROM DBO.SingleScreenField WITH (NOLOCK) WHERE SingleScreenId = @SingleScreenId
    ORDER BY SingleScreenId, ISNULL(SortOrder, 0)

    SELECT * FROM DBO.SingleScreenFieldChildren WITH (NOLOCK)
    WHERE SingleScreenFieldId IN (SELECT SingleScreenFieldId
		FROM DBO.SingleScreenField WITH (NOLOCK)
		WHERE SingleScreenId = @SingleScreenId);

    SELECT * FROM DBO.SingleScreenFieldDisplayField WITH (NOLOCK)
    WHERE SingleScreenFieldId IN (SELECT SingleScreenFieldId
		FROM DBO.SingleScreenField WITH (NOLOCK)
		WHERE SingleScreenId = @SingleScreenId);

    SELECT * FROM DBO.SingleScreenReferenceTable WITH (NOLOCK) WHERE SingleScreenId = @SingleScreenId;
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,@AdhocComments varchar(150) = 'USP_SingleScreen_GetSingleScreenConfigurations',
            @ProcedureParameters varchar(max) = '',
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