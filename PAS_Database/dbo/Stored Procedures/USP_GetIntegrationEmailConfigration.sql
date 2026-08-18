/*************************************************************                   
 ** File:   [USP_GetIntegrationEmailConfigration]                   
 ** Author:   Moin Bloch  
 ** Description: Get Integration Email Configration   
 ** Purpose:                 
 ** Date:    04/08/2025        
 **************************************************************                   
  ** Change History                   
 **************************************************************                   
 ** PR   Date         Author  Change Description                    
 ** --   --------     -------  ------ --------------------------                  
    1    04/08/2025   Moin Bloch        Created  
    2    15/08/2025   Vishal Suthar    Added new columns AuthTypeId and EmployeeId  
    3    19/08/2025   BHARGAV SALIYA   Added CASE to get [AuthType]  
    4    19/06/2026   Kishor Makwana   Get ClientId, TenantId and ClientSecret and update CASE with Added AuthTypeId = 4
    
-- EXEC USP_GetIntegrationEmailConfigration 1,0,1  
**************************************************************/                     
CREATE   PROCEDURE [dbo].[USP_GetIntegrationEmailConfigration]   
 @MasterCompanyId INT = NULL,  
 @IntegrationEmailConfigId INT = NULL,  
 @Opr INT = NULL  
AS        
BEGIN        
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED        
 SET NOCOUNT ON;        
 BEGIN TRY        
      
 IF(@Opr = 1)  
 BEGIN  
  SELECT [IntegrationEmailConfigId]  
     ,[SmtpUserEmail]  
     ,[smtpserver]  
     ,[SmtpEmailPassword]  
     ,[SmtpPort]  
     ,ISNULL([UseSsl],0) [UseSsl]  
     ,[MasterCompanyId]  
     ,[CreatedBy]  
     ,[UpdatedBy]  
     ,[CreatedDate]  
     ,[UpdatedDate]  
     ,[IsActive]  
     ,[IsDeleted]  
     ,[AuthTypeId]  
     ,[EmployeeId]
     ,[ClientId]
     ,[TenantId]
     ,[ClientSecret]
     ,CASE WHEN ISNULL(AuthTypeId,'') = 1 THEN 'Basic SMTP'  
     WHEN ISNULL(AuthTypeId,'') = 2 THEN 'Google OAuth 2.0'  
     WHEN ISNULL(AuthTypeId,'') = 3 THEN 'Microsoft OAuth 2.0'
     WHEN ISNULL(AuthTypeId,'') = 4 THEN 'Microsoft OAuth 2.0'
     ELSE '' END AS AuthType  
  FROM [dbo].[IntegrationEmailSmtpConfigration] IE WITH(NOLOCK)        
  WHERE IE.[MasterCompanyId] = @MasterCompanyId  
  AND IE.[IsDeleted] = 0  
  AND IE.[IsActive] = 1     
 END  
 IF(@Opr = 2)  
 BEGIN  
  UPDATE [dbo].[IntegrationEmailSmtpConfigration] SET [IsDeleted] = 1 WHERE [IntegrationEmailConfigId] = @IntegrationEmailConfigId  
 END  
             
 END TRY            
 BEGIN CATCH        
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()         
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
        , @AdhocComments     VARCHAR(150)    = 'USP_GetIntegrationEmailConfigration'         
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(1, '') AS varchar(100))               
        + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId  , '') AS varchar(100))     
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