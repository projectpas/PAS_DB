/*************************************************************           
 ** File:   [Get QuickBooks Settings By Master Company]           
 ** Author:    HEMANT SALIYA
 ** Description:  
 ** Purpose:         
 ** Date:   07-AUG-2024        
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------  
	1    08/06/2020   HEMANT SALIYA	     CREATED


EXEC USP_GetQuickBooksSettingsByMasterCompany 1 , 1

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetQuickBooksSettingsByMasterCompany]
	@IntegrationTypeId INT,
	@MasterCompanyId INT = NULL

AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		SELECT AccountingIntegrationSetupId,
			IntegrationId,
			ClientId,
			ClientSecret,
			RedirectUrl,
			Environment,
			MasterCompanyId,
			CreatedBy,
			UpdatedBy,
			CreatedDate,
			UpdatedDate,
			IsActive,
			IsDeleted 
		FROM dbo.AccountingIntegrationSetup WITH(NOLOCK) 
		WHERE @MasterCompanyId = @MasterCompanyId AND IntegrationId = @IntegrationTypeId 
			
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetAccIntegrationList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@IntegrationTypeId, '') AS VARCHAR(100))
			  + '@Parameter2 = ''' + CAST(ISNULL(@masterCompanyID, '') AS VARCHAR(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END