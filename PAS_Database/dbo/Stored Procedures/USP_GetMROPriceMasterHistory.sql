/*********************           
 ** File:   [USP_GetMROPriceMasterHistory]           
 ** Author: Priyansh Patel
 ** Description: This stored procedure returns all MRO Price Master records History         
 ** Date:   16/10/2025

 **********************           
  ** Change History           
 **********************           
 ** PR   Date          Author  			Change Description            
 ** --   --------      -------			---------------------------     
    1    16/10/2025    Priyansh Patel   Created
**********************/
-- Example: EXEC USP_GetMROPriceMasterHistory 1001

CREATE PROCEDURE [dbo].[USP_GetMROPriceMasterHistory] 
    @MROPriceMasterId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN
            SELECT 
                  MPM.[MROPriceMasterAuditId],
                  MPM.[MROPriceMasterId],
                  MPM.[ItemMasterId],
                  MPM.[MasterCompanyId],
                  MPM.[CustomerId],
                  MPM.[WorkscopeId],
                  MPM.[UnitPrice],
				   MPM.[CurrencyId],
                  MPM.[StartDate],
				  MPM.[EndDate],
                  MPM.[CreatedBy],
                  MPM.[CreatedDate],
                  MPM.[UpdatedBy],
                  MPM.[UpdatedDate],
                  MPM.[IsActive],
                  MPM.[IsDeleted]
            FROM [dbo].[MROPriceMasterAudit] MPM WITH(NOLOCK)
            WHERE MPM.[MROPriceMasterId] = @MROPriceMasterId
            ORDER BY MPM.[UpdatedDate] DESC;
        END
    END TRY



 BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            PRINT 'ROLLBACK';
            ROLLBACK TRAN;
        END

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = '[USP_GetMROPriceMasterHistory]',
                @ProcedureParameters VARCHAR(3000) = 
                    '@MROPriceMasterId=''' + CAST(ISNULL(@MROPriceMasterId, 0) AS VARCHAR(100)),
                @ApplicationName VARCHAR(100) = 'PAS';
        -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END