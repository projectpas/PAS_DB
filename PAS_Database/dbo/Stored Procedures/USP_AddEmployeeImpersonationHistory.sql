/*************************************************************             
 ** File:   [USP_AddEmployeeImpersonationHistory]           
 ** Author:   Bhargav Saliya 
 ** Description: This stored procedure is used to add a record when we perform impersonation.
 ** Jira Id: PN-15456
 ** Purpose:           
 ** Date:   
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author              Change Description              
 ** --   --------     -------          --------------------------------     
    1    26/02/2026   Bhargav Saliya       PN-15456: Created
    2    12/03/2026   Bhargav Saliya       PN-15747: Modified
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_AddEmployeeImpersonationHistory]  
@ImpersonatedEmployeeId BIGINT,  
@MasterCompanyId INT,
@ImpersonatedByEmployeeId BIGINT,
@CurrentUserMasterCompanyId INT
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
	BEGIN TRY  
	DECLARE @ImpersonatedBy VARCHAR(256) ;
	DECLARE @Impersonated VARCHAR(256);	
	DECLARE @CompanyName VARCHAR(500);
	DECLARE @CompanyCode VARCHAR(100)

	SELECT @ImpersonatedBy = (SELECT ISNULL(FirstName,'') + ' ' + ISNULL(LastName,'')
	FROM dbo.[Employee] WITH(NOLOCK) 
	WHERE EmployeeId = @ImpersonatedByEmployeeId and MasterCompanyId =  @CurrentUserMasterCompanyId);
	
	SELECT @Impersonated = ASP.FullName
	FROM dbo.[AspNetUsers] ASP WITH(NOLOCK) 
	WHERE EmployeeId = @ImpersonatedEmployeeId and MasterCompanyId =  @MasterCompanyId;

	SELECT @CompanyName = [CompanyName], @CompanyCode = [MasterCompanyCode] FROM dbo.[MasterCompany] WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId;

	IF(ISNULL(@ImpersonatedEmployeeId, 0) > 0 AND ISNULL(@ImpersonatedByEmployeeId, 0) > 0)
	BEGIN
		INSERT INTO dbo.[EmployeeImpersonationHistory]
			([ImpersonatedByEmployeeId],[ImpersonatedBy],[ImpersonatedEmployeeId],[Impersonated],[CompanyName],[CompanyCode],[CompanyId],[IsActive],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate])
		VALUES(@ImpersonatedByEmployeeId,@ImpersonatedBy,@ImpersonatedEmployeeId,@Impersonated,@CompanyName,@CompanyCode,@MasterCompanyId,1,@CurrentUserMasterCompanyId,@ImpersonatedBy,GETUTCDATE(),@ImpersonatedBy,GETUTCDATE())
	END
	

	END TRY      
	BEGIN CATCH        
	IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_AddEmployeeImpersonationHistory'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ImpersonatedEmployeeId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END