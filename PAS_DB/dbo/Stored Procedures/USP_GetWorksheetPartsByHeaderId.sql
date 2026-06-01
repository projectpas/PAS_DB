

/*************************************************************             
 ** File:   [USP_GetWorksheetPartsByHeaderId]        
 ** Author:   
 ** Description: This stored procedure is used to get records from [WorksheetHeader].
 ** Purpose:           
 ** Date:  [14-May-2026] 
            
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author              Change Description              
 ** --   --------     -------          --------------------------------     
    1    14/05/2026                        Created [PN-16408]
**************************************************************/


CREATE PROCEDURE [dbo].[USP_GetWorksheetPartsByHeaderId]
    @WorksheetHeaderId BIGINT, @MasterCompanyId INT

AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
    BEGIN TRY

        SELECT *
        FROM   [dbo].[WorksheetPart] WITH (NOLOCK)
        WHERE  WorksheetHeaderId = @WorksheetHeaderId AND MasterCompanyId = @MasterCompanyId
          AND  IsDeleted         = 0
        ORDER BY WorksheetPartId ASC;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID          INT,
                @DatabaseName        VARCHAR(100) = DB_NAME(),
                @AdhocComments       VARCHAR(150) = 'USP_GetWorksheetPartsByHeaderId',
                @ProcedureParameters VARCHAR(3000) = '@WorksheetHeaderId = ' + ISNULL(CAST(@WorksheetHeaderId AS VARCHAR(20)), 'NULL'),
                @ApplicationName     VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR(
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16, 1, @ErrorLogID
        );
        RETURN(1);
    END CATCH
END