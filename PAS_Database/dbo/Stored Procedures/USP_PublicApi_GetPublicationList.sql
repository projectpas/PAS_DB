
/*************************************************************
 ** File:   [USP_PublicApi_GetPublicationList]
 ** Author: Bhargav Saliya
 ** Description: Publications of the company (PAS Publication List, publication view), oldest first.
 **              Published By Name and Verified By follow the same logic as dbo.GetPublicationViewList.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/publications
 ** Date:   23/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/11/2026   Bhargav Saliya    Created

  EXEC [dbo].[USP_PublicApi_GetPublicationList] @MasterCompanyId = 1, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetPublicationList]
    @MasterCompanyId INT,
    @PageNumber      INT,
    @PageSize        INT,
    @PublicationId   VARCHAR(100) = NULL,
    @IsActive        BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @ManufacturerModuleId INT = (SELECT TOP (1) [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'Manufacturer');
        DECLARE @VendorModuleId INT = (SELECT TOP (1) [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'Vendor');

        ;WITH PagedPublication AS
        (
            SELECT PU.[PublicationRecordId], COUNT(1) OVER () AS [TotalRecords]
            FROM [dbo].[Publication] PU WITH (NOLOCK)
            WHERE PU.[MasterCompanyId] = @MasterCompanyId
              AND ISNULL(PU.[IsDeleted], 0) = 0
              AND (@PublicationId IS NULL OR PU.[PublicationId] = @PublicationId)
              AND (@IsActive IS NULL OR PU.[IsActive] = @IsActive)
            ORDER BY PU.[PublicationRecordId]
            OFFSET (@PageNumber - 1) * @PageSize ROWS
            FETCH NEXT @PageSize ROWS ONLY
        )
        SELECT
            PU.[PublicationRecordId],   -- used by the API to attach the part numbers; not returned to clients
            PU.[PublicationId],
            NULLIF(LTRIM(RTRIM(PU.[Description])), '') AS [Description],
            PT.[Name] AS [PublicationType],
            PM.[ModuleName] AS [PublishedBy],
            NULLIF(CASE WHEN PU.[PublishedById] = @ManufacturerModuleId THEN M.[Name]
                        WHEN PU.[PublishedById] = @VendorModuleId THEN V.[VendorName]
                        ELSE PU.[PublishedByOthers] END, '') AS [PublishedByName],
            NULLIF(LTRIM(RTRIM(PU.[RevisionNum])), '') AS [RevisionNumber],
            PU.[revisionDate] AS [RevisionDate],
            PU.[NextReviewDate],
            PU.[ExpirationDate],
            LOC.[Name] AS [Location],
            NULLIF(LTRIM(RTRIM(PU.[Fleet])), '') AS [Fleet],
            CASE WHEN ISNULL(PU.[VerifiedBy], 0) = 0 THEN NULL
                 ELSE NULLIF(LTRIM(RTRIM(ISNULL(E.[FirstName], '') + ' ' + ISNULL(E.[LastName], ''))), '') END AS [VerifiedBy],
            PU.[VerifiedDate],
            NULLIF(LTRIM(RTRIM(PU.[URL])), '') AS [Url],
            CAST(ISNULL(PU.[IsActive], 0) AS BIT) AS [IsActive],
            PU.[CreatedDate],
            PU.[UpdatedDate],
            P.[TotalRecords]
        FROM PagedPublication P
        INNER JOIN [dbo].[Publication] PU WITH (NOLOCK) ON PU.[PublicationRecordId] = P.[PublicationRecordId]
        LEFT JOIN [dbo].[PublicationType] PT WITH (NOLOCK) ON PT.[PublicationTypeId] = PU.[PublicationTypeId]
        LEFT JOIN [dbo].[Module] PM WITH (NOLOCK) ON PM.[ModuleId] = PU.[PublishedById]
        LEFT JOIN [dbo].[Manufacturer] M WITH (NOLOCK) ON M.[ManufacturerId] = PU.[PublishedByRefId]
        LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON V.[VendorId] = PU.[PublishedByRefId]
        LEFT JOIN [dbo].[Location] LOC WITH (NOLOCK) ON LOC.[LocationId] = PU.[LocationId]
        LEFT JOIN [dbo].[Employee] E WITH (NOLOCK) ON E.[EmployeeId] = PU.[VerifiedBy]
        ORDER BY PU.[PublicationRecordId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetPublicationList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@PublicationId, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@IsActive, '') AS VARCHAR(100))
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