/*************************************************************                 
 ** File:   [USP_GetAccountingIntegrationSetup_ById]      
 ** Author:     Devendra Shekh  
 ** Description: This stored procedure is used to populate Accounting Integration Setup by Id.          
 ** Purpose:                
 ** Date:         25/10/2024	[dd/mm/yyyy]
 **************************************************************                 
 ** Change History                 
 **************************************************************                 
 ** PR   Date         Author				Change Description                  
 ** --   --------     -------			--------------------------------                
    1    25/10/2024   Devendra Shekh		Fixed Management Structure binding      

EXEC [USP_GetAccountingIntegrationSetup_ById] 1
**************************************************************/      
CREATE   PROCEDURE [dbo].[USP_GetAccountingIntegrationSetup_ById]      
@IntegrationTypeId INT = NULL,
@MasterCompanyId INT = NULL
AS      
BEGIN      
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
    SET NOCOUNT ON      

    BEGIN TRY      
        BEGIN 
            SELECT 
                [AccountingIntegrationSetupId],
                [IntegrationId],
                [ClientId],
                [ClientSecret],
                [RedirectUrl],
                [Environment],
                [MasterCompanyId],
                [CreatedBy],
                [UpdatedBy],
                [CreatedDate],
                [UpdatedDate],
                [IsActive],
                [IsDeleted],
                [IsEnabled],
                [APIKey],
                [IsDefault]
            FROM [DBO].[AccountingIntegrationSetup] WITH (NOLOCK) 
            WHERE MasterCompanyId = @MasterCompanyId AND ISNULL([IsDefault], 0) = 1 AND IntegrationId = @IntegrationTypeId
        END
    END TRY          
    BEGIN CATCH      
        DECLARE 
            @ErrorLogID INT, 
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            @DatabaseName VARCHAR(100) = db_name(), 
            @AdhocComments VARCHAR(150) = 'USP_GetAccountingIntegrationSetup_ById',       
            @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + ISNULL(CAST(@MasterCompanyId AS VARCHAR), '') + '''',      
            @ApplicationName VARCHAR(100) = 'PAS'
			-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------   
        EXEC spLogException       
            @DatabaseName = @DatabaseName,      
            @AdhocComments = @AdhocComments,      
            @ProcedureParameters = @ProcedureParameters,      
            @ApplicationName = @ApplicationName,      
            @ErrorLogID = @ErrorLogID OUTPUT;      

        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);      
        RETURN(1);      
    END CATCH      
END