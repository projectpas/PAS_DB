/*************************************************************                 
 ** File:   [USP_GetIntegrationEmailInboxes]                 
 ** Author:   Moin Bloch
 ** Description: Get Integration Email List  Counts        
 ** Purpose:               
 ** Date:    07/08/2025        
 **************************************************************                 
  ** Change History                 
 **************************************************************                 
 ** PR   Date         Author  Change	Description                  
 ** --   --------     -------  ------	--------------------------                
    1    07/08/2025   Moin Bloch   	    Created  
	2    12/08/2025   Moin Bloch   	    Added Trash 
    
-- EXEC USP_GetIntegrationEmailInboxes 1
**************************************************************/                   
CREATE   PROCEDURE [dbo].[USP_GetIntegrationEmailInboxes] 
@MasterCompanyId INT = NULL
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
 BEGIN TRY      
    
	 DECLARE @EmailCount INT = 0,@Inbox INT = 1,@Draft INT = 2,@SentMail INT = 3,@Trash INT = 4

	 SELECT @EmailCount = COUNT(IEC.[IntegrationEmailConfigId]) 		     
	   FROM [dbo].[IntegrationEmailSmtpConfigration] IEC WITH(NOLOCK)	      
	  WHERE IEC.[MasterCompanyId] = @MasterCompanyId
		AND IEC.[IsDeleted] = 0
		AND IEC.[IsActive] = 1

	IF(@EmailCount > 1)
	BEGIN
		SELECT 'All' [SmtpUserEmail],
		       'All' [UserName],
			   (SELECT ISNULL(SUM(IE.[EmailSection]),0)  
				   FROM [dbo].[IntegrationEmail] IE WITH(NOLOCK)	      
				  WHERE IE.[MasterCompanyId] = @MasterCompanyId
					AND IE.[IsDeleted] = 0
					AND IE.[IsActive] = 1) [Inbox],
			   @MasterCompanyId [MasterCompanyId]

        UNION 

		SELECT IEC.[SmtpUserEmail],
		       LEFT(IEC.[SmtpUserEmail], CHARINDEX('@', IEC.[SmtpUserEmail]) - 1) [UserName],
			   (SELECT ISNULL(SUM(CASE WHEN IE.[EmailSection] = @Inbox THEN 1 ELSE 0 END),0)  
				   FROM [dbo].[IntegrationEmail] IE WITH(NOLOCK)	      
				  WHERE IE.[EmailReadBy] = IEC.[SmtpUserEmail]
					AND	IE.[MasterCompanyId] = @MasterCompanyId
					AND IE.[IsDeleted] = 0
					AND IE.[IsActive] = 1) [Inbox],
				IEC.[MasterCompanyId]
	   FROM [dbo].[IntegrationEmailSmtpConfigration] IEC WITH(NOLOCK)	      
	  WHERE IEC.[MasterCompanyId] = @MasterCompanyId
		AND IEC.[IsDeleted] = 0
		AND IEC.[IsActive] = 1
	END
	ELSE
	BEGIN
		SELECT IEC.[SmtpUserEmail],
		       LEFT(IEC.[SmtpUserEmail], CHARINDEX('@', IEC.[SmtpUserEmail]) - 1) [UserName],
			   (SELECT ISNULL(SUM(CASE WHEN IE.[EmailSection] = @Inbox THEN 1 ELSE 0 END),0)  
				   FROM [dbo].[IntegrationEmail] IE WITH(NOLOCK)	      
				  WHERE IE.[EmailReadBy] = IEC.[SmtpUserEmail]
					AND	IE.[MasterCompanyId] = @MasterCompanyId
					AND IE.[IsDeleted] = 0
					AND IE.[IsActive] = 1) [Inbox],
				IEC.[MasterCompanyId]
	   FROM [dbo].[IntegrationEmailSmtpConfigration] IEC WITH(NOLOCK)	      
	  WHERE IEC.[MasterCompanyId] = @MasterCompanyId
		AND IEC.[IsDeleted] = 0
		AND IEC.[IsActive] = 1
		
	END

	SELECT (SELECT ISNULL(SUM(CASE WHEN IE.[EmailSection] = @Trash THEN 1 ELSE 0 END),0)  
				   FROM [dbo].[IntegrationEmail] IE WITH(NOLOCK)	      
				  WHERE IE.[EmailReadBy] = IEC.[SmtpUserEmail]
					AND	IE.[MasterCompanyId] = @MasterCompanyId
					AND IE.[IsDeleted] = 0
					AND IE.[IsActive] = 1) [Trash]				
	   FROM [dbo].[IntegrationEmailSmtpConfigration] IEC WITH(NOLOCK)	      
	  WHERE IEC.[MasterCompanyId] = @MasterCompanyId
		AND IEC.[IsDeleted] = 0
		AND IEC.[IsActive] = 1
	          
 END TRY          
 BEGIN CATCH      
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
        , @AdhocComments     VARCHAR(150)    = 'USP_GetIntegrationEmailInboxes'       
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