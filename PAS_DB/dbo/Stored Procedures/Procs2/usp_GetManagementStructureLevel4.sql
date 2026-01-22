
/*************************************************************           
 ** File:   [usp_GetManagementStructureLevel4]           
 ** Author:   Subhash  
 ** Description: Get Data for GetManagementStructureLevel4 Report
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

     
EXECUTE   [dbo].[usp_GetManagementStructureLevel4] '4',4
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetManagementStructureLevel4] 
@Level3 varchar(max) = NULL,
@mastercompanyid int


AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
 
    BEGIN TRANSACTION

				 IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
				  BEGIN
					DROP TABLE #ManagmetnStrcture
				  END
				  CREATE TABLE #ManagmetnStrcture (
					ID bigint NOT NULL IDENTITY,
					ManagementStructureId bigint NULL,
				  )

			    INSERT INTO #ManagmetnStrcture (ManagementStructureId)
				  SELECT
					item
				  FROM dbo.[SplitString](@Level3, ',')

				declare @count int = 0
				select @count = ManagementStructureId from dbo.ManagementStructure 
					Where ParentId in ( select ManagementStructureId FROM #ManagmetnStrcture) AND (MasterCompanyId = @mastercompanyid)

				if(isnull(@count,0) != 0)
				begin

					select ManagementStructureId as LEVEL4, UPPER(Code + '-' +  [Name])  as DEPT from dbo.ManagementStructure 
					Where ParentId in ( select ManagementStructureId FROM #ManagmetnStrcture) AND (MasterCompanyId = @mastercompanyid)
					UNION
					select  0 as LEVEL4, 'NULL' as DEPT
				end
				else 
				begin
					select  0 as LEVEL4, 'Select All' as DEPT
				end
	



    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION

	 IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
    BEGIN
      DROP TABLE #managmetnstrcture
    END


    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetManagementStructureLevel4]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@Level3, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),
       
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

  IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
  BEGIN
    DROP TABLE #managmetnstrcture
  END
END