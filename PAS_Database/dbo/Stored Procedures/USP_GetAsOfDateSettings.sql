/*************************************************************             
 ** File:  [USP_GetAsOfDateSettings]
 ** Author:  Moin Bloch  
 ** Description: This stored procedure is used to get As Of Date Settings
 ** Purpose:           
 ** Date:   22/09/2025            
 ** PARAMETERS:            
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		--------------------------------            
    1    22/09/2025   MOIN BLOCH		Created  
	2    25/09/2025   Devendra Shekh	Added GroupById 

--  EXEC [dbo].[USP_GetAsOfDateSettings] 1
************************************************************************/  
CREATE     PROCEDURE [dbo].[USP_GetAsOfDateSettings]
@MasterCompanyId INT=NULL
AS
BEGIN
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;   
 BEGIN TRY 

    SELECT 
        [Id],
        [SiteIds],
        [WarehouseIds],
        [LocationIds],
        [ShelfIds],
        [BinIds],
        [Level1Ids],
        [Level2Ids],
        [Level3Ids],
        [Level4Ids],
        [Level5Ids],
        [Level6Ids],
        [Level7Ids],
        [Level8Ids],
        [Level9Ids],
        [Level10Ids],
        [IsWeeklyOrMonthly],
        [ExecutionDate],
        [WeeklyName],
        [ExcludedLocations],
        [MasterCompanyId],
        [CreatedBy],
        [UpdatedBy],
        [CreatedDate],
        [UpdatedDate],
        [IsActive],
        [IsDeleted],
        [GroupById]
   FROM [dbo].[AsOfDateSettings]
   WHERE [MasterCompanyId] = @MasterCompanyId    

 END TRY   
 BEGIN CATCH        
  IF @@trancount > 0  
  PRINT 'ROLLBACK'      
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = '[USP_GetAsOfDateSettings]'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL('', '') AS VARCHAR(100))              
             + '@Parameter4 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))              
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters    = @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
 END CATCH  
END