
/*************************************************************           
 ** File:   [usp_GetManagementStructureLevel1]           
 ** Author:   Subhash  
 ** Description: Get Data for GetManagementStructureLevel2 Report
 ** Purpose:         
 ** Date:   04-Octomber-2020       
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author    Change Description            
 ** --   --------     -------    --------------------------------          
    1                 Subhash Created

     
EXECUTE   [dbo].[usp_GetManagementStructureLevel1] '4',4
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetManagementStructureLevel1] 
@mastercompanyid int


AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
 
    BEGIN TRANSACTION

			      select ManagementStructureId as LEVEL1, UPPER(Code + '-' +  [Name])  as CO from dbo.ManagementStructure 
					Where ParentId is null and (MasterCompanyId = @mastercompanyid)
	



    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION



    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetManagementStructureLevel1]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),
       
            @ApplicationName varchar(100) = 'PAS'

    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

    RETURN (1);
  END CATCH

END