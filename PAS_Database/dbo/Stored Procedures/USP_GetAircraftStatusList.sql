/************************************************************
** File:        [USP_GetAircraftStatusList]
** Author:      Priyansh Patel
** Description: Get Aircraft Status List By MasterComapny Id
** 
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    30/03/2026   Priyansh Patel  Created [PN-15841]

EXEC USP_GetAircraftStatusList 1
************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetAircraftStatusList]
    @MasterCompanyId    INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY

       SELECT  [AircraftStatusId],[Name],[Description],[SequenceNo],[MasterCompanyId], [CreatedBy],[CreatedDate], [UpdatedBy],[UpdatedDate],[IsActive], [IsDeleted]
    FROM [dbo].[AircraftStatus] WITH (NOLOCK)
    WHERE MasterCompanyId = @MasterCompanyId AND ISNULL(IsActive, 0)  = 1 AND ISNULL(IsDeleted, 0) = 0
    ORDER BY SequenceNo ASC;

    END TRY
    BEGIN CATCH
        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_GetAircraftRegistryList',
            @ProcedureParameters VARCHAR(3000) =
                '@MasterCompanyId = '    + ISNULL(CAST(@MasterCompanyId   AS VARCHAR(20)), 'NULL') ,
            @ApplicationName     VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR(
            'Unexpected error in the database. Please provide error number %d to the support team.',
            16, 1, @ErrorLogID
        );

        RETURN 1;

    END CATCH;
END;