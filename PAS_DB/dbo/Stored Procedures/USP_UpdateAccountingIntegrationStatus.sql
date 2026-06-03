/*************************************************************           
 ** File:   [USP_UpdateAccountingIntegrationStatus]           
 ** Author:    Moin Bloch
 ** Description:  
 ** Purpose:         
 ** Date:   03/06/2026          
 ** PARAMETERS:          
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------  
	1    03/06/2026     Moin Bloch	     CREATED
**************************************************************/ 
CREATE PROCEDURE [dbo].[USP_UpdateAccountingIntegrationStatus]    
    @IntegrationId      INT,
    @IntigrationStatus  VARCHAR(50),
	@MasterCompanyId    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION

            UPDATE [dbo].[AccountingIntegrationSettings]
               SET [IntigrationStatus] = @IntigrationStatus,
                   [UpdatedDate]       = GETUTCDATE()                   
             WHERE [MasterCompanyId]   = @MasterCompanyId
               AND [IntegrationId]     = @IntegrationId              

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID            INT,
                @DatabaseName          VARCHAR(100) = DB_NAME(),
                @AdhocComments         VARCHAR(150)  = 'USP_UpdateAccountingIntegrationStatus',
                @ProcedureParameters   VARCHAR(3000) =
                    '@MasterCompanyId = '  + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(50)) +
                    ', @IntegrationId = '  + CAST(ISNULL(@IntegrationId,   '') AS VARCHAR(50)) +
                    ', @IntigrationStatus = ' + ISNULL(@IntigrationStatus, ''),
                @ApplicationName       VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName         = @DatabaseName,
            @AdhocComments        = @AdhocComments,
            @ProcedureParameters  = @ProcedureParameters,
            @ApplicationName      = @ApplicationName,
            @ErrorLogID           = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END