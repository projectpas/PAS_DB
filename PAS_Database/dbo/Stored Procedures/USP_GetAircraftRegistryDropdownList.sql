/*************************************************************             
 ** File:  [USP_GetAircraftRegistryDropdownList]
 ** Author:  Amit Ghediya  
 ** Description: 
 ** Purpose:           
 ** Date:   17/06/2026            
 ** PARAMETERS:            
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		--------------------------------            
    1    17/06/2026   Amit Ghediya		Created  
	
--  EXEC [dbo].[USP_GetAircraftRegistryDropdownList] 11,1,1
************************************************************************/  
CREATE     PROCEDURE [dbo].[USP_GetAircraftRegistryDropdownList]
	@MakeTypeId     BIGINT=NULL,
    @AircraftModelId BIGINT=NULL,
    @MasterCompanyId INT=NULL
AS
BEGIN
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;   
 BEGIN TRY 

		SET NOCOUNT ON;

		SELECT
			ARH.AircraftRegistryId,
			ARH.AircraftRegistryNumber
		FROM dbo.AircraftRegistryHeader ARH WITH (NOLOCK)
		WHERE ARH.MakeTypeId        = @MakeTypeId
		  AND ARH.AircraftModelId   = @AircraftModelId
		  AND ARH.MasterCompanyId   = @MasterCompanyId
		  AND ARH.IsActive          = 1
		  AND ARH.IsDeleted         = 0
		ORDER BY ARH.AircraftRegistryNumber desc;
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
              , @AdhocComments     VARCHAR(150)    = '[USP_GetAircraftRegistryDropdownList]'   
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