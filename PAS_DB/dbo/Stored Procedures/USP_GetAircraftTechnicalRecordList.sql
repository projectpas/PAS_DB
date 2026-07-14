/*********************
** File:        [USP_GetAircraftTechnicalRecordList]
** Description: Returns paged/filtered/sorted aircraft technical record list
**              (registry + publication + latest worksheet/work order info).
** Purpose:     Aircraft Technical Records grid (PN-16449)
** Date:        18/05/2026
**
** RETURN VALUE: Result set with TotalRecords column for pagination.
*******************************************************************************
** Change History
*******************************************************************************
** PR   Date         Author				Change Description
** --   ----------   -------------		--------------------------------
** 1    18/05/2026   Moin Bloch         Created [PN-16449]
** 2    20/05/2026	 Moin Bloch			Added IsMtceRecordUpdated [PN-16449]
** 3    22/05/2026	 Moin Bloch			Fixed Duplicate Issue [PN-16449]
** 4    22/05/2026	 Moin Bloch			Fixed Duplicate Issue [PN-16449]
** 5    22/05/2026	 Amit Ghediya	    Get WSheet & wo data [PN-16546]
** 6    22/05/2026	 Bhargav Saliya		Added MtceRecordUpdated Filter [PN-16567]
** 7    10/06/2026	 Amit Ghediya		Update name WorksheetNumber to WorksheetNum due to use in other [PN-16797]
** 8    15/06/2026	 Amit Ghediya		Update TotalRecords when filter not worked.
** 9    16/06/2026	 Amit Ghediya		Get AircraftPublicationId for records [PN-16797]
** 10   07/07/2026	 <AI>			Standards & performance pass (no logic change):
**										- CREATE OR ALTER, SET XACT_ABORT ON
**										- Single lookup for Module IDs
**										- LEFT JOIN + ROW_NUMBER derived tables converted to OUTER APPLY TOP(1)
**										  so they evaluate only for qualifying rows
**										- MtceRecordUpdated reuses MR aggregate instead of a second EXISTS probe
** 13   13/07/2026	 Amit Ghediya		Replaced EntityType string column with IsAircraftSerialNum
**										bit flag (1 = AC Serial Num, 0 = Component Serial Num). [PN-17223]
*******************************************************************************/
--EXEC dbo.USP_GetAircraftTechnicalRecordList @PageNumber=1,@PageSize=20,@SortColumn=NULL,@SortOrder=N'ASC',
--@GlobalFilter=NULL,@TailNumber=NULL,@AircraftMake=NULL,@AircraftModel=NULL,@SerialNumber=NULL,@PubDate=NULL,
--@PublicationType=NULL,@PubNum=NULL,@RevisionNum=NULL,@PublishedBy=NULL,@IsActive=NULL,@IsDeleted=0,@MasterCompanyId=1

/*
** Recommended supporting indexes (verify against existing indexes before creating):
**
** CREATE INDEX IX_AMP_Registry_Publication
**     ON dbo.AircraftMaintenanceProgram (AircraftRegistryId, AircraftPublicationId)
**     INCLUDE (IsMtceRecordUpdated, ProgramId);
**
** CREATE INDEX IX_WorksheetHeader_ProgramId
**     ON dbo.WorksheetHeader (ProgramId)
**     INCLUDE (WorksheetNumber, CreatedDate, CreatedBy, AircraftInstalledPartDetailsId);
**
** CREATE INDEX IX_WorkOrderPartNumber_ProgramId
**     ON dbo.WorkOrderPartNumber (ProgramId)
**     INCLUDE (WorkOrderId, WorkOrderStatus, WorkOrderStatusId);
**
** CREATE INDEX IX_AircraftEffectivity_Make_Serial
**     ON dbo.AircraftEffectivity (MakeTypeId, SerialNum)
**     INCLUDE (AircraftPublicationId, AircraftEffectivityId);
**
** CREATE INDEX IX_ARH_MasterCompany
**     ON dbo.AircraftRegistryHeader (MasterCompanyId, IsDeleted);
*/
CREATE    PROCEDURE [dbo].[USP_GetAircraftTechnicalRecordList]
@PageNumber           INT          = 1,
@PageSize             INT          = 10,
@SortColumn           VARCHAR(100) = 'AircraftRegistryId',
@SortOrder            VARCHAR(4)   = 'DESC',
@GlobalFilter         VARCHAR(100) = NULL,
@TailNumber           VARCHAR(50)  = NULL,
@AircraftMake         VARCHAR(100) = NULL,
@AircraftModel        VARCHAR(100) = NULL,
@SerialNumber         VARCHAR(100) = NULL,
@PubDate              DATETIME     = NULL, -- TODO: declared but never used in WHERE; confirm and either implement or remove
@PublicationType      VARCHAR(100) = NULL,
@PubNum               VARCHAR(100) = NULL,
@RevisionNum          VARCHAR(50)  = NULL,
@PublishedBy          VARCHAR(100) = NULL,
@IsActive             BIT          = NULL, -- TODO: declared but never used in WHERE; confirm and either implement or remove
@IsDeleted            BIT          = 0,
@MasterCompanyId      INT,
@InspectionDate       DATETIME     = NULL,
@WorksheetNumber      VARCHAR(100) = NULL,
@WorkSheetCompletedBy VARCHAR(100) = NULL,
@WorkOrderNum         VARCHAR(100) = NULL,
@WorkOrderStatus      VARCHAR(100) = NULL,
@WorkSheetStatus      VARCHAR(100) = NULL,
@OpenDate             DATETIME     = NULL,
@MtceRecordUpdated    VARCHAR(50)  = NULL,
@ComplianceDate		  DATETIME     = NULL,
@Ractification        VARCHAR(50)  = NULL,
@ACSection			  VARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        DECLARE @ManufactureTypeId INT,
                @VendorTypeId      INT;

        -- Single lookup instead of two separate queries
        SELECT @VendorTypeId      = MAX(CASE WHEN [ModuleName] = 'Vendor'       THEN [ModuleId] END),
               @ManufactureTypeId = MAX(CASE WHEN [ModuleName] = 'Manufacturer' THEN [ModuleId] END)
        FROM [dbo].[Module] WITH (NOLOCK)
        WHERE [ModuleName] IN ('Vendor', 'Manufacturer');

        ;WITH CTE AS
        (
            SELECT DISTINCT
                ARH.AircraftRegistryId,
                ACE.AircraftEffectivityId,
				ACE.ComplianceDate,
				ACE.Ractification,
				ACS.Section AS ACSection,
                ARH.TailNum       AS TailNumber,
                ARH.MakeType      AS AircraftMake,
                ARH.AircraftModel,
                ARH.SerialNum     AS SerialNumber,
                PUB.PubDate,
                PUT.Name          AS PublicationType,
                PUB.PubNum,
                PUB.RevisionNum,
                CASE
                    WHEN PUB.PublishedById = @ManufactureTypeId THEN ISNULL(M.Name, '')
                    WHEN PUB.PublishedById = @VendorTypeId      THEN ISNULL(V.VendorName, '')
                    ELSE ISNULL(PUB.PublishedByOthers, '')
                END AS PublishedBy,
                PUB.AircraftPublicationId,
                ISNULL(MR.IsMtceRecordUpdated, 0) AS IsMtceRecordUpdated,
                ''  AS MELNumber,
                WS.WorksheetNumber   AS WorksheetNum,
                WS.WorksheetHeaderId AS WorksheetId,
                WS.CreatedDate       AS InspectionDate,
                WS.CreatedBy         AS WorkSheetCompletedBy,
                WSS.WorkSheetStatus  AS WorkSheetStatus,
                WOX.WorkOrderNum,
                WOX.WorkOrderId,
                WOX.OpenDate,
                WOX.WorkOrderStatus,
                ARH.IsActive,
                ARH.IsDeleted,
                ARH.UpdatedDate,
                ARH.UpdatedBy,
                ARH.CreatedDate,
                ARH.CreatedBy,
                ARH.MasterCompanyId,
                -- Reuses MR instead of a second correlated EXISTS on AircraftMaintenanceProgram:
                -- MAX(IsMtceRecordUpdated) = 1 is logically identical to EXISTS(... = 1)
                CASE WHEN ISNULL(MR.IsMtceRecordUpdated, 0) = 1
                     THEN 'YES' ELSE 'NO' END AS MtceRecordUpdated
            FROM [dbo].[AircraftRegistryHeader] ARH WITH (NOLOCK)
            INNER JOIN [dbo].[AircraftEffectivity] ACE WITH (NOLOCK)
                    ON ARH.[MakeTypeId] = ACE.[MakeTypeId]
                   AND (ACE.[AircraftModelId] IS NULL OR ARH.[AircraftModelId] = ACE.[AircraftModelId])
                   AND (ISNULL(ACE.[AircraftSubModel], '') = '' OR ARH.[AircraftSubModel] = ACE.[AircraftSubModel])
                   AND (ISNULL(ACE.[SerialNum], '') = '' OR ARH.[SerialNum] = ACE.[SerialNum])
                   -- Aircraft-level exclusion: skip this (registry, effectivity) match if this specific
                   -- aircraft's serial has been explicitly excluded for the group
                   AND NOT EXISTS (
                       SELECT 1
                       FROM dbo.AircraftEffectivitySerialDetail EXC WITH (NOLOCK)
                       WHERE EXC.IsAircraftSerialNum    = 1
                         AND EXC.IsAffect               = 0
                         AND EXC.IsDeleted              = 0
                         AND EXC.AircraftPublicationId  = ACE.AircraftPublicationId
                         AND EXC.MakeTypeId             = ACE.MakeTypeId
                         AND ISNULL(EXC.AircraftModelId, 0)   = ISNULL(ACE.AircraftModelId, 0)
                         AND ISNULL(EXC.AircraftSubModel, '') = ISNULL(ACE.AircraftSubModel, '')
                         AND EXC.FromSerial             = ARH.SerialNum
                   )
                   -- Component-level match: only enforced when this effectivity row references a
                   -- specific component (ItemMasterId > 0). If no component serial entries were
                   -- configured for the group, component serial is treated as a wildcard.
                   AND (
                       ISNULL(ACE.ItemMasterId, 0) = 0
                       OR NOT EXISTS (
                           SELECT 1 FROM dbo.AircraftEffectivitySerialDetail WITH (NOLOCK)
                           WHERE AircraftPublicationId = ACE.AircraftPublicationId
                             AND MakeTypeId            = ACE.MakeTypeId
                             AND ISNULL(AircraftModelId, 0)   = ISNULL(ACE.AircraftModelId, 0)
                             AND ISNULL(AircraftSubModel, '') = ISNULL(ACE.AircraftSubModel, '')
                             AND ItemMasterId          = ACE.ItemMasterId
                             AND IsAircraftSerialNum   = 0
                             AND IsAffect              = 1
                             AND IsDeleted             = 0
                       )
                       OR EXISTS (
                           SELECT 1
                           FROM dbo.AircraftInstalledPartDetails AIPD WITH (NOLOCK)
                           WHERE AIPD.AircraftRegistryId = ARH.AircraftRegistryId
                             AND AIPD.ItemMasterId       = ACE.ItemMasterId
                             AND AIPD.IsDeleted          = 0
                             AND EXISTS (
                                 SELECT 1
                                 FROM dbo.AircraftEffectivitySerialDetail AECS WITH (NOLOCK)
                                 WHERE AECS.AircraftPublicationId = ACE.AircraftPublicationId
                                   AND AECS.MakeTypeId            = ACE.MakeTypeId
                                   AND ISNULL(AECS.AircraftModelId, 0)   = ISNULL(ACE.AircraftModelId, 0)
                                   AND ISNULL(AECS.AircraftSubModel, '') = ISNULL(ACE.AircraftSubModel, '')
                                   AND AECS.ItemMasterId          = ACE.ItemMasterId
                                   AND AECS.IsAircraftSerialNum   = 0
                                   AND AECS.IsAffect              = 1
                                   AND AECS.IsDeleted             = 0
                                   AND (
                                       (AECS.SerialType = 'Individual' AND AECS.FromSerial = AIPD.SerialNumber)
                                       OR
                                       (AECS.SerialType = 'Range' AND dbo.UFN_SerialInRange(AIPD.SerialNumber, AECS.FromSerial, AECS.ToSerial) = 1)
                                   )
                             )
                             AND NOT EXISTS (
                                 SELECT 1 FROM dbo.AircraftEffectivitySerialDetail EXC2 WITH (NOLOCK)
                                 WHERE EXC2.IsAircraftSerialNum  = 0
                                   AND EXC2.IsAffect             = 0
                                   AND EXC2.IsDeleted            = 0
                                   AND EXC2.AircraftPublicationId = ACE.AircraftPublicationId
                                   AND EXC2.MakeTypeId            = ACE.MakeTypeId
                                   AND ISNULL(EXC2.AircraftModelId, 0)   = ISNULL(ACE.AircraftModelId, 0)
                                   AND ISNULL(EXC2.AircraftSubModel, '') = ISNULL(ACE.AircraftSubModel, '')
                                   AND ISNULL(EXC2.ItemMasterId, 0)      = ACE.ItemMasterId
                                   AND EXC2.FromSerial            = AIPD.SerialNumber
                             )
                       )
                   )
            INNER JOIN [dbo].[AircraftPublication] PUB WITH (NOLOCK)
                    ON ACE.[AircraftPublicationId] = PUB.[AircraftPublicationId]
            LEFT JOIN [dbo].[PublicationType] PUT WITH (NOLOCK)
                    ON PUB.[PublicationTypeId] = PUT.[PublicationTypeId]
            LEFT JOIN [dbo].[Manufacturer] M WITH (NOLOCK)
                    ON PUB.[PublishedByRefId] = M.[ManufacturerId]
            LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK)
                    ON PUB.[PublishedByRefId] = V.[VendorId]
			LEFT JOIN [dbo].[AircraftSection] ACS WITH (NOLOCK)
                    ON ACS.[AircraftSectionId] = ACE.[ACPSectionId]
            -- Aggregate flag: evaluated only for qualifying (registry, publication) pairs
            OUTER APPLY (
                SELECT MAX(CAST(ISNULL(AMP.IsMtceRecordUpdated, 0) AS INT)) AS IsMtceRecordUpdated
                FROM dbo.AircraftMaintenanceProgram AMP WITH (NOLOCK)
                WHERE AMP.AircraftRegistryId    = ARH.AircraftRegistryId
                  AND AMP.AircraftPublicationId = PUB.AircraftPublicationId
            ) MR
            -- Latest worksheet: replaces ROW_NUMBER over the full table with a per-row TOP(1)
            OUTER APPLY (
                SELECT TOP (1)
                       WSH.WorksheetNumber, WSH.WorksheetHeaderId, WSH.CreatedDate, WSH.CreatedBy
                FROM dbo.AircraftMaintenanceProgram AMP WITH (NOLOCK)
                LEFT JOIN dbo.WorksheetHeader WSH WITH (NOLOCK)
                       ON WSH.ProgramId = AMP.ProgramId
                WHERE AMP.AircraftRegistryId    = ARH.AircraftRegistryId
                  AND AMP.AircraftPublicationId = PUB.AircraftPublicationId
                ORDER BY WSH.CreatedDate DESC, WSH.WorksheetHeaderId DESC
            ) WS
            -- Latest work order
            OUTER APPLY (
                SELECT TOP (1)
                       WO.WorkOrderNum, WO.WorkOrderId, WO.OpenDate, WOPN.WorkOrderStatus
                FROM dbo.AircraftMaintenanceProgram AMP WITH (NOLOCK)
                LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK)
                       ON WOPN.ProgramId = AMP.ProgramId
                LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK)
                       ON WO.WorkOrderId = WOPN.WorkOrderId
                WHERE AMP.AircraftRegistryId    = ARH.AircraftRegistryId
                  AND AMP.AircraftPublicationId = PUB.AircraftPublicationId
                ORDER BY WO.WorkOrderId DESC
            ) WOX
            -- Worksheet status
            OUTER APPLY (
                SELECT TOP (1)
                    CASE
                        WHEN AMP.ProgramId IS NULL OR WSH.WorksheetHeaderId IS NULL THEN NULL
                        -- NOTE: the branch below is unreachable (the condition above already
                        -- catches WSH.WorksheetHeaderId IS NULL). Kept as-is per "no logic change";
                        -- confirm intended precedence with the team before removing.
                        WHEN WSH.WorksheetHeaderId IS NULL THEN 'Open'
                        WHEN WOP2.WorkOrderId IS NULL THEN 'Open'
                        WHEN ISNULL(WO2.WorkOrderStatusId, 0) = 2 THEN 'Closed'
                        WHEN UPPER(ISNULL(WOP2.WorkOrderStatus, '')) = 'CLOSED' THEN 'Closed'
                        WHEN ISNULL(
                                CASE WHEN ISNULL(WSH.AircraftInstalledPartDetailsId, 0) > 0
                                     THEN WOP2.WorkOrderStatusId ELSE WO2.WorkOrderStatusId END, 0) = 2
                             THEN 'Closed'
                        ELSE 'In Process'
                    END AS WorkSheetStatus
                FROM dbo.AircraftMaintenanceProgram AMP WITH (NOLOCK)
                LEFT JOIN dbo.WorksheetHeader WSH WITH (NOLOCK)
                       ON WSH.ProgramId = AMP.ProgramId
                LEFT JOIN dbo.WorkOrderPartNumber WOP2 WITH (NOLOCK)
                       ON WOP2.ProgramId = AMP.ProgramId
                LEFT JOIN dbo.WorkOrder WO2 WITH (NOLOCK)
                       ON WO2.WorkOrderId = WOP2.WorkOrderId
                WHERE AMP.AircraftRegistryId    = ARH.AircraftRegistryId
                  AND AMP.AircraftPublicationId = PUB.AircraftPublicationId
                ORDER BY WSH.WorksheetHeaderId DESC, WOP2.WorkOrderId DESC
            ) WSS
            WHERE ARH.MasterCompanyId = @MasterCompanyId
              AND (@IsDeleted IS NULL OR ARH.IsDeleted = @IsDeleted)
        )

        SELECT *,
               COUNT(1) OVER () AS TotalRecords
        FROM CTE
        WHERE
        (
            @GlobalFilter IS NULL
            OR TailNumber                     LIKE '%' + @GlobalFilter + '%'
            OR AircraftMake                   LIKE '%' + @GlobalFilter + '%'
            OR AircraftModel                  LIKE '%' + @GlobalFilter + '%'
            OR SerialNumber                   LIKE '%' + @GlobalFilter + '%'
            OR PublicationType                LIKE '%' + @GlobalFilter + '%'
            OR PubNum                         LIKE '%' + @GlobalFilter + '%'
            OR RevisionNum                    LIKE '%' + @GlobalFilter + '%'
            OR ISNULL(WorksheetNum, '')       LIKE '%' + @GlobalFilter + '%'
            OR ISNULL(WorkSheetCompletedBy,'')LIKE '%' + @GlobalFilter + '%'
            OR ISNULL(WorkOrderNum, '')       LIKE '%' + @GlobalFilter + '%'
            OR ISNULL(WorkOrderStatus, '')    LIKE '%' + @GlobalFilter + '%'
            OR ISNULL(WorkSheetStatus, '')    LIKE '%' + @GlobalFilter + '%'
			OR ACSection					  LIKE '%' + @GlobalFilter + '%'
            OR PublishedBy                    LIKE '%' + @GlobalFilter + '%'
			OR Ractification                  LIKE '%' + @GlobalFilter + '%'
        )
        AND (NULLIF(@TailNumber, '')          IS NULL OR TailNumber      LIKE '%' + @TailNumber + '%')
        AND (NULLIF(@AircraftMake, '')        IS NULL OR AircraftMake    LIKE '%' + @AircraftMake + '%')
        AND (NULLIF(@AircraftModel, '')       IS NULL OR AircraftModel   LIKE '%' + @AircraftModel + '%')
        AND (NULLIF(@SerialNumber, '')        IS NULL OR SerialNumber    LIKE '%' + @SerialNumber + '%')
        AND (NULLIF(@PublicationType, '')     IS NULL OR PublicationType LIKE '%' + @PublicationType + '%')
        AND (NULLIF(@PubNum, '')              IS NULL OR PubNum          LIKE '%' + @PubNum + '%')
        AND (NULLIF(@RevisionNum, '')         IS NULL OR RevisionNum     LIKE '%' + @RevisionNum + '%')
        AND (NULLIF(@PublishedBy, '')         IS NULL OR PublishedBy     LIKE '%' + @PublishedBy + '%')
        AND (NULLIF(@WorksheetNumber, '')     IS NULL OR ISNULL(WorksheetNum, '')        LIKE '%' + @WorksheetNumber + '%')
        AND (@InspectionDate IS NULL OR CAST(InspectionDate AS DATE) = CAST(@InspectionDate AS DATE))
        AND (@OpenDate       IS NULL OR CAST(OpenDate       AS DATE) = CAST(@OpenDate AS DATE))
        AND (NULLIF(@WorkSheetCompletedBy,'') IS NULL OR ISNULL(WorkSheetCompletedBy,'') LIKE '%' + @WorkSheetCompletedBy + '%')
        AND (NULLIF(@WorkOrderNum, '')        IS NULL OR ISNULL(WorkOrderNum, '')        LIKE '%' + @WorkOrderNum + '%')
        AND (NULLIF(@WorkOrderStatus, '')     IS NULL OR ISNULL(WorkOrderStatus, '')     LIKE '%' + @WorkOrderStatus + '%')
		AND (@ComplianceDate       IS NULL OR CAST(ComplianceDate       AS DATE) = CAST(@ComplianceDate AS DATE))
		AND (NULLIF(@Ractification, '')          IS NULL OR Ractification      LIKE '%' + @Ractification + '%')
		AND (NULLIF(@ACSection, '')          IS NULL OR ACSection      LIKE '%' + @ACSection + '%')
        AND (ISNULL(@MtceRecordUpdated, '') = ''
             OR (CASE WHEN ISNULL([IsMtceRecordUpdated], 0) = 1 THEN 'YES' ELSE 'NO' END) LIKE '%' + @MtceRecordUpdated + '%')

        ORDER BY

            CASE WHEN @SortColumn = 'TailNumber'           AND @SortOrder = 'ASC'  THEN TailNumber END ASC,
            CASE WHEN @SortColumn = 'TailNumber'           AND @SortOrder = 'DESC' THEN TailNumber END DESC,

            CASE WHEN @SortColumn = 'AircraftMake'         AND @SortOrder = 'ASC'  THEN AircraftMake END ASC,
            CASE WHEN @SortColumn = 'AircraftMake'         AND @SortOrder = 'DESC' THEN AircraftMake END DESC,

            CASE WHEN @SortColumn = 'AircraftModel'        AND @SortOrder = 'ASC'  THEN AircraftModel END ASC,
            CASE WHEN @SortColumn = 'AircraftModel'        AND @SortOrder = 'DESC' THEN AircraftModel END DESC,

            CASE WHEN @SortColumn = 'SerialNumber'         AND @SortOrder = 'ASC'  THEN SerialNumber END ASC,
            CASE WHEN @SortColumn = 'SerialNumber'         AND @SortOrder = 'DESC' THEN SerialNumber END DESC,

            CASE WHEN @SortColumn = 'WorksheetNum'         AND @SortOrder = 'ASC'  THEN WorksheetNum END ASC,
            CASE WHEN @SortColumn = 'WorksheetNum'         AND @SortOrder = 'DESC' THEN WorksheetNum END DESC,

            CASE WHEN @SortColumn = 'InspectionDate'       AND @SortOrder = 'ASC'  THEN InspectionDate END ASC,
            CASE WHEN @SortColumn = 'InspectionDate'       AND @SortOrder = 'DESC' THEN InspectionDate END DESC,

            CASE WHEN @SortColumn = 'OpenDate'             AND @SortOrder = 'ASC'  THEN OpenDate END ASC,
            CASE WHEN @SortColumn = 'OpenDate'             AND @SortOrder = 'DESC' THEN OpenDate END DESC,

            CASE WHEN @SortColumn = 'WorkSheetCompletedBy' AND @SortOrder = 'ASC'  THEN WorkSheetCompletedBy END ASC,
            CASE WHEN @SortColumn = 'WorkSheetCompletedBy' AND @SortOrder = 'DESC' THEN WorkSheetCompletedBy END DESC,

            CASE WHEN @SortColumn = 'WorkOrderNum'         AND @SortOrder = 'ASC'  THEN WorkOrderNum END ASC,
            CASE WHEN @SortColumn = 'WorkOrderNum'         AND @SortOrder = 'DESC' THEN WorkOrderNum END DESC,

            CASE WHEN @SortColumn = 'WorkOrderStatus'      AND @SortOrder = 'ASC'  THEN WorkOrderStatus END ASC,
            CASE WHEN @SortColumn = 'WorkOrderStatus'      AND @SortOrder = 'DESC' THEN WorkOrderStatus END DESC,

            CASE WHEN @SortColumn = 'WorkSheetStatus'      AND @SortOrder = 'ASC'  THEN WorkSheetStatus END ASC,
            CASE WHEN @SortColumn = 'WorkSheetStatus'      AND @SortOrder = 'DESC' THEN WorkSheetStatus END DESC,

            CASE WHEN @SortColumn = 'MtceRecordUpdated'    AND @SortOrder = 'ASC'  THEN [MtceRecordUpdated] END ASC,
            CASE WHEN @SortColumn = 'MtceRecordUpdated'    AND @SortOrder = 'DESC' THEN [MtceRecordUpdated] END DESC,

			CASE WHEN @SortColumn = 'ComplianceDate'      AND @SortOrder = 'ASC'  THEN ComplianceDate END ASC,
            CASE WHEN @SortColumn = 'ComplianceDate'       AND @SortOrder = 'DESC' THEN ComplianceDate END DESC,

		    CASE WHEN @SortColumn = 'Ractification'       AND @SortOrder = 'ASC'  THEN Ractification END ASC,
            CASE WHEN @SortColumn = 'Ractification'        AND @SortOrder = 'DESC' THEN Ractification END DESC,

			CASE WHEN @SortColumn = 'ACSection'           AND @SortOrder = 'ASC'  THEN ACSection END ASC,
            CASE WHEN @SortColumn = 'ACSection'           AND @SortOrder = 'DESC' THEN ACSection END DESC,

            AircraftRegistryId DESC

        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
        OPTION (RECOMPILE);

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END