/*********************
 ** File:   GET EXTERNAL LEASE LIST
 ** Author:  Nakul
 ** Description: Lease ID dropdown for the External webpage usage entry form (ExternalApiController.GetLeases)
 ** Purpose: Returns the company's leases that are not Closed (LeaseStatusId 1 Draft, 2 Active, 3 Closed - same values
 **          as USP_LeaseHeaderList) and not deleted. Pass @LeaseHeaderId to check that one lease is available to the caller.
 ** Date:  30/09/2026

 ************************************************************
  ** Change History
 ************************************************************
  ** PR   Date         Author			Change Description
  ** --   --------     -------			--------------------------------
     1    30/09/2026   Nakul            Created for External webpage usage entry

 exec USP_GetExternalLeaseList @MasterCompanyId=1
 exec USP_GetExternalLeaseList @MasterCompanyId=1, @LeaseHeaderId=16
*************************************************************/
CREATE PROCEDURE [dbo].[USP_GetExternalLeaseList]
    @MasterCompanyId INT,
    @LeaseHeaderId   BIGINT = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @LeaseStatusClosed INT = 3;

        SELECT LH.[LeaseHeaderId],
               LH.[LeaseNumber],
               LH.[LeaseName],
               ISNULL(LH.[LeaseNumber], '') + '-' + ISNULL(LH.[LeaseName], '') AS LeaseDisplayName,
               LH.[LeaseStatusId],
               CASE LH.[LeaseStatusId] WHEN 1 THEN 'Draft' WHEN 2 THEN 'Active' WHEN 3 THEN 'Closed' END AS LeaseStatusName
        FROM [dbo].[LeaseHeader] LH WITH(NOLOCK)
        WHERE LH.[MasterCompanyId] = @MasterCompanyId
          AND LH.[IsDeleted] = 0
          AND LH.[IsActive] = 1
          AND LH.[LeaseStatusId] <> @LeaseStatusClosed
          AND (@LeaseHeaderId IS NULL OR LH.[LeaseHeaderId] = @LeaseHeaderId)
        ORDER BY LH.[LeaseNumber] ASC;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetExternalLeaseList',
                @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) + '''' +
                                                     ', @LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, '') AS VARCHAR(100)) + '''',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
                @DatabaseName           = @DatabaseName,
                @AdhocComments          = @AdhocComments,
                @ProcedureParameters    = @ProcedureParameters,
                @ApplicationName        = @ApplicationName,
                @ErrorLogID             = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in database procedure USP_GetExternalLeaseList. Error Log ID: %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END;
GO
