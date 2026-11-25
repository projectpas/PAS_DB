
/*************************************************************
 ** File:   [USP_PublicApi_GetPublicationParts]
 ** Author: Bhargav Saliya
 ** Description: Part numbers mapped to the publications on one page (@PublicationRecordIds: comma separated),
 **              the active mappings of the PAS Publication PN Mapping tab. Stock items only, as the PAS list.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/publications (part numbers)
 ** Date:   23/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/11/2026   Bhargav Saliya    Created

  EXEC [dbo].[USP_PublicApi_GetPublicationParts] @MasterCompanyId = 1, @PublicationRecordIds = '1,2,3'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetPublicationParts]
    @MasterCompanyId      INT,
    @PublicationRecordIds VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            PIM.[PublicationRecordId],   -- used by the API to attach the part numbers; not returned to clients
            IM.[partnumber] AS [PartNumber],
            NULLIF(LTRIM(RTRIM(IM.[PartDescription])), '') AS [PartDescription],
            NULLIF(LTRIM(RTRIM(IM.[ManufacturerName])), '') AS [Manufacturer],
            NULLIF(LTRIM(RTRIM(PIM.[Notes])), '') AS [Notes]
        FROM [dbo].[PublicationItemMasterMapping] PIM WITH (NOLOCK)
        INNER JOIN [dbo].[Publication] PU WITH (NOLOCK) ON PU.[PublicationRecordId] = PIM.[PublicationRecordId] AND PU.[MasterCompanyId] = @MasterCompanyId
        INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = PIM.[ItemMasterId] AND ISNULL(IM.[IsNonStock], 0) = 0
        WHERE PIM.[PublicationRecordId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@PublicationRecordIds, ','))
          AND ISNULL(PIM.[IsDeleted], 0) = 0
          AND ISNULL(PIM.[IsActive], 0) = 1
        ORDER BY PIM.[PublicationRecordId], PIM.[PublicationItemMasterMappingId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetPublicationParts'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@PublicationRecordIds, '') AS VARCHAR(100))
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