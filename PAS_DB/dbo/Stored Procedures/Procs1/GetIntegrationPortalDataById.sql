
/*************************************************************           
 ** File: GetIntegrationPortalDataById
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used to get Integration Portal data.
 ** Purpose:         
 ** Date:   25/06/2025        
          
 ** PARAMETERS: 
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		   Change Description            
 ** --   --------     -------		   -------------------------------          
    1    26/06/2025   Amit Ghediya     Created
    
 EXEC GetIntegrationPortalDataById 1 

**************************************************************/ 
    
CREATE   PROCEDURE [dbo].[GetIntegrationPortalDataById]   
	@MasterCompanyId BIGINT
AS    
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	SET NOCOUNT ON  
	BEGIN TRY
			DECLARE @ILSCode VARCHAR(100) = 'ILS';

			SELECT 
				MasterCompanyId,
				IntegrationPortalId,
				Description,
				IsActive,
				IsDeleted
			FROM [dbo].[IntegrationPortal] WITH(NOLOCK)
			WHERE [MasterCompanyId] = @MasterCompanyId AND [Description] = @ILSCode
			ORDER BY MasterCompanyId DESC
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetIntegrationPortalDataById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST('' AS varchar(MAX)) ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END