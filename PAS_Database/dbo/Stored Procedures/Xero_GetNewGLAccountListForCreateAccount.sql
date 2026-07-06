/*************************************************************           
 ** File:   [Xero_GetNewGLAccountListForCreateAccount]           
 ** Author:   Bhargav Saliya
 ** Description: Get GL Account List to Create GL Account in Xero    
 ** Purpose:         
 ** Date:   27-May-2026      
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    27-May-2026    Bhargav Saliya	Created

 EXECUTE [Xero_GetNewGLAccountListForCreateAccount] 2,1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[Xero_GetNewGLAccountListForCreateAccount]
    @IntegrationTypeId INT = NULL,
    @MasterCompanyId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED   
    BEGIN TRY

        DECLARE @QBIntegrationTypeId INT, @XeroIntegrationTypeId INT,@ModuleId INT;

        SELECT @XeroIntegrationTypeId = IntegrationTypeId FROM dbo.AccountingIntegrationType WITH(NOLOCK) WHERE IntegrationType = 'Xero'
        SELECT @ModuleId = AccountingModuleId FROM [dbo].AccountingModule WITH(NOLOCK) WHERE AccountingModuleName = 'GLAccount';

        IF(ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId)
        BEGIN
            SELECT 
                GA.GLAccountId,
                GA.AccountCode,
                GA.AccountName,
                GA.AccountDescription,
                GA.GLAccountTypeId,
                GA.LedgerId,
                GA.LedgerName,
                GA.MasterCompanyId,
                GA.QuickBooksReferenceId,
                GA.IsUpdated,
                GA.SyncToken,
                '' as GLAccountClassName --GAT.GLAccountClassName
            FROM dbo.GLAccount GA WITH(NOLOCK)
            WHERE ISNULL(GA.QuickBooksReferenceId, '') = '' 
              AND ISNULL(GA.IsUpdated, 0) = 1 
              AND GA.MasterCompanyId = @MasterCompanyId
        END

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT
            ,@DatabaseName VARCHAR(100) = db_name()
            ,@AdhocComments VARCHAR(150) = 'QuickBooks_GetNewGLAccountListForCreateAccount'
            ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@IntegrationTypeId, '') AS VARCHAR(100))
            ,@ApplicationName VARCHAR(100) = 'PAS'

        EXEC spLogException 
             @DatabaseName = @DatabaseName
            ,@AdhocComments = @AdhocComments
            ,@ProcedureParameters = @ProcedureParameters
            ,@ApplicationName = @ApplicationName
            ,@ErrorLogID = @ErrorLogID OUTPUT

        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN(1)
    END CATCH
END