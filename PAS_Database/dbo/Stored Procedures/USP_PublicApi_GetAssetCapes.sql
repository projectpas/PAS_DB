
/*************************************************************
 ** File:   [USP_PublicApi_GetAssetCapes]
 ** Author: Bhargav Saliya
 ** Description: Capabilities (part numbers) of the assets on one page (@AssetRecordIds: comma separated),
 **              the PartNumber / PartDescription of the PAS Asset List. Stock items only, as dbo.GetAssetList.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/assets (capabilities)
 ** Date:   23/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/11/2026   Bhargav Saliya    Created

  EXEC [dbo].[USP_PublicApi_GetAssetCapes] @MasterCompanyId = 1, @AssetRecordIds = '1,2,3'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetAssetCapes]
    @MasterCompanyId INT,
    @AssetRecordIds  VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            AC.[AssetRecordId],   -- used by the API to attach the capabilities; not returned to clients
            IM.[partnumber] AS [PartNumber],
            NULLIF(LTRIM(RTRIM(IM.[PartDescription])), '') AS [PartDescription],
            NULLIF(LTRIM(RTRIM(IM.[ManufacturerName])), '') AS [Manufacturer]
        FROM [dbo].[AssetCapes] AC WITH (NOLOCK)
        INNER JOIN [dbo].[Asset] A WITH (NOLOCK) ON A.[AssetRecordId] = AC.[AssetRecordId] AND A.[MasterCompanyId] = @MasterCompanyId
        INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = AC.[ItemMasterId] AND ISNULL(IM.[IsNonStock], 0) = 0
        WHERE AC.[AssetRecordId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@AssetRecordIds, ','))
          AND ISNULL(AC.[IsDeleted], 0) = 0
          AND ISNULL(AC.[IsActive], 1) = 1
        ORDER BY AC.[AssetRecordId], AC.[AssetCapesId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetAssetCapes'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@AssetRecordIds, '') AS VARCHAR(100))
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