
/*************************************************************
 ** File:   [usprpt_GetToolingReportData]
 ** Author: Claude (Rajesh Gami)
 ** Description: [PN-17979] Tooling Report - for each Work Order asset check-in/check-out
 **              event, returns the tool (AssetInventory), the Work Order and MPN/task it
 **              was checked in against, and the check-in/check-out/MPN receive-ship dates.
 **              Registered as Reports > Asset Reports > Tooling Report (single mode, no
 **              radio-button variant, unlike the LOT Commission Reports pattern this was
 **              built from).
 ** Date:   18/September/2026
 ** PARAMETERS: @PageNumber, @PageSize, @mastercompanyid, @xmlFilter
 **             (Filters: "From Check In Date", "To Check In Date", "Tool Id", "Serial Num",
 **              "WO Num", "MPN"), @SortColumn, @SortOrder
 ** RETURN VALUE: paged result set, one row per (Work Order asset check-in/check-out) event
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author                          Change Description
 ** --   --------     -------                         ---------------------------
    1    18/September/2026   Claude (Rajesh Gami)   [PN-17979] Created. Built from Rajesh's
         base SELECT (WorkOrderAssets/CheckInCheckOutWorkOrderAsset/WorkOrder/WorkOrderPartNumber/
         AssetInventory/Task/WorkOrderTask, with the Dup OUTER APPLY for the sequenced-task-name
         branch), wrapped in the paging/global-filter/sort pattern from
         usprpt_GetLotCommissionReportCashPosted. The base query Rajesh sent ended right at
         "WHERE" with no conditions, so the WHERE clause below (date range + 4 GlobalFilter
         fields + tenant scoping) was written from the GlobalFilter rows in his PN-17979 DATA
         SCRIPT, not dictated - please review the two ASSUMPTION comments below (Tool Id /
         MPN filter columns) and the sortable-column list, and correct if off.
    2    18/September/2026   Claude (Rajesh Gami)   [PN-17979] Added Level1-Level10 management-
         structure hierarchy filtering, per Rajesh's instruction: parses @Level1..@Level10 out
         of @xmlFilter (same pattern as usprpt_GetLotCommissionReportCashPosted's Level1-10),
         resolves @ModuleID from dbo.ManagementStructureModule where ModuleName='WorkOrderMPN'
         (no MasterCompanyId scoping - added defensively at first, then explicitly removed per
         Rajesh 18-Sep-2026: this lookup is not tenant-specific), INNER JOINs
         dbo.WorkOrderManagementStructureDetails MSD on
         MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOP.ID (exactly as given - note this is
         an INNER JOIN, so a WorkOrderPartNumber row with no MSD entry for this module drops out
         of the report entirely; flag if that's not intended), and filters on
         MSD.Level1Id..Level10Id via the same comma-split SPLITSTRING pattern as Tool Id/WO Num/
         MPN below.
    3    18/September/2026   Claude (Rajesh Gami)   [PN-17979] Added level1..level10 output
         columns (UPPER(MSD.Level1Name)..UPPER(MSD.Level10Name)) to both the CTE and the final
         SELECT, alongside the existing Level1Id..Level10Id WHERE filtering from PR 2. NOTE: no
         FieldsMaster rows added for these in the registration script - usprpt_GetLotCommission-
         ReportCashPosted's own level1/level2/level3/level4/pn output columns aren't registered
         in FieldsMaster either (grepped PN-17830_Step1_ModuleAndReportRegistration.sql, no
         'level' hits), so leaving these unregistered matches that precedent rather than
         guessing they should be visible grid columns. If Tooling Report actually needs
         level1-10 as visible/exportable columns (not just filter-context), say so and I'll add
         the FieldsMaster rows.
 **************************************************************
 EXEC usprpt_GetToolingReportData @PageNumber=1,@PageSize=100,@mastercompanyid=1,@xmlFilter='<ArrayOfFilter><Filter><FieldName>From Check In Date</FieldName><FieldValue>9/1/2026</FieldValue></Filter><Filter><FieldName>To Check In Date</FieldName><FieldValue>9/18/2026</FieldValue></Filter></ArrayOfFilter>'
**************************************************************/
CREATE PROCEDURE [dbo].[usprpt_GetToolingReportData]
@PageNumber INT = 1,
@PageSize INT = NULL,
@mastercompanyid INT,
@xmlFilter XML,
@SortColumn VARCHAR(50) = NULL,
@SortOrder INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  DECLARE @FromCheckInDate VARCHAR(MAX) = NULL,
    @ToCheckInDate VARCHAR(MAX) = NULL,
    @ToolId VARCHAR(MAX) = NULL,
    @SerialNum VARCHAR(MAX) = NULL,
    @WONum VARCHAR(MAX) = NULL,
    @MPN VARCHAR(MAX) = NULL,
    @Level1 VARCHAR(MAX) = NULL,
    @Level2 VARCHAR(MAX) = NULL,
    @Level3 VARCHAR(MAX) = NULL,
    @Level4 VARCHAR(MAX) = NULL,
    @Level5 VARCHAR(MAX) = NULL,
    @Level6 VARCHAR(MAX) = NULL,
    @Level7 VARCHAR(MAX) = NULL,
    @Level8 VARCHAR(MAX) = NULL,
    @Level9 VARCHAR(MAX) = NULL,
    @Level10 VARCHAR(MAX) = NULL

  BEGIN TRY
    SELECT
      @FromCheckInDate = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'From Check In Date' THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @FromCheckInDate END,
      @ToCheckInDate   = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'To Check In Date'   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @ToCheckInDate END,
      @ToolId          = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Tool Id'            THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @ToolId END,
      @SerialNum       = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Serial Num'         THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @SerialNum END,
      @WONum           = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'WO Num'             THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @WONum END,
      @MPN             = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'MPN'                THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @MPN END,
      @Level1  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level1'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level1 END,
      @Level2  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level2'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level2 END,
      @Level3  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level3'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level3 END,
      @Level4  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level4'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level4 END,
      @Level5  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level5'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level5 END,
      @Level6  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level6'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level6 END,
      @Level7  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level7'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level7 END,
      @Level8  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level8'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level8 END,
      @Level9  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level9'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level9 END,
      @Level10 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level10' THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Level10 END
    FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE(filterby)

    DECLARE @FromCheckInDt DATE = TRY_CONVERT(DATE, @FromCheckInDate, 101);
    DECLARE @ToCheckInDt DATE = TRY_CONVERT(DATE, @ToCheckInDate, 101);

    -- [PN-17979] Level1-10 management-structure hierarchy lookup for WorkOrderPartNumber.
    -- Not scoped to @mastercompanyid on purpose - Rajesh confirmed ManagementStructureModule's
    -- 'WorkOrderMPN' row is not tenant-specific here, so MasterCompanyId is intentionally left
    -- out of this lookup (my first draft added it defensively; removed per his instruction).
    DECLARE @ModuleID INT;
    SELECT @ModuleID = ManagementStructureModuleId
    FROM dbo.ManagementStructureModule WITH (NOLOCK)
    WHERE ModuleName = 'WorkOrderMPN';

    SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END
    -- [PN-17979] Single-source query (no multi-branch UNION like the LOT Commission Report),
    DECLARE @EffectivePageSize INT = ISNULL(NULLIF(@PageSize,0), 2147483647);

    ;WITH ToolingCTE AS (
      SELECT
        AI.AssetId AS toolId,
        AI.Name AS toolNum,
        AI.SerialNo AS serialNum,
        '' AS checkedInCalStatus,
        '' AS checkedOutCalStatus,
        '' AS currCalStatus,
        WO.WorkOrderNum AS woNum,
        WOP.RevisedPartNumber AS mpn,
        WOP.RevisedSerialNumber AS mpnSerialNum,

        CASE
            WHEN ISNULL(WO.WorkOrderFormTypeId, 0) = 1
            THEN
                CASE
                    WHEN ISNULL(Dup.TaskCount, 0) > 1
                         AND ISNULL(WOT.SequenceNumber, '') <> ''
                    THEN WOT.SequenceNumber + ' - ' + WOT.TaskName
                    ELSE WOT.TaskName
                END
            ELSE T.Description
        END AS task,

        CIN.CheckInDate AS checkInWODateRaw,
        CIN.CheckOutDate AS checkOutWODateRaw,
        WOP.ReceivedDate AS mpnReceivedDateRaw,
        WOP.ShipDate AS mpnShippedDateRaw,

        UPPER(MSD.Level1Name) AS level1,
        UPPER(MSD.Level2Name) AS level2,
        UPPER(MSD.Level3Name) AS level3,
        UPPER(MSD.Level4Name) AS level4,
        UPPER(MSD.Level5Name) AS level5,
        UPPER(MSD.Level6Name) AS level6,
        UPPER(MSD.Level7Name) AS level7,
        UPPER(MSD.Level8Name) AS level8,
        UPPER(MSD.Level9Name) AS level9,
        UPPER(MSD.Level10Name) AS level10

      FROM dbo.WorkOrderAssets WOA WITH(NOLOCK)

      INNER JOIN dbo.CheckInCheckOutWorkOrderAsset CIN WITH(NOLOCK)
        ON WOA.WorkOrderAssetId = CIN.WorkOrderAssetId

      INNER JOIN dbo.WorkOrder WO WITH(NOLOCK)
        ON CIN.WorkOrderId = WO.WorkOrderId

      INNER JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
        ON CIN.WorkOrderPartNoId = WOP.ID

      INNER JOIN dbo.AssetInventory AI WITH(NOLOCK)
        ON CIN.AssetInventoryId = AI.AssetInventoryId

      INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK)
        ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOP.ID

      LEFT JOIN dbo.Task T WITH(NOLOCK)
        ON T.TaskId = WOA.TaskId

      LEFT JOIN dbo.WorkOrderTask WOT WITH(NOLOCK)
        ON WOT.WorkOrderTaskId = WOA.TaskId

      OUTER APPLY
      (
        SELECT COUNT(*) AS TaskCount
        FROM dbo.WorkOrderTask WOTDup WITH(NOLOCK)
        WHERE WOTDup.WorkOrderId = WO.WorkOrderId
          AND WOTDup.WorkOrderPartNumberId = WOP.ID
          AND WOTDup.TaskId = WOT.TaskId
          AND WOTDup.IsActive = 1
          AND ISNULL(WOTDup.IsDeleted,0) = 0
      ) Dup

      WHERE WO.MasterCompanyId = @mastercompanyid
        AND ISNULL(WO.IsDeleted,0) = 0
        AND ISNULL(AI.IsDeleted,0) = 0
        AND (@FromCheckInDt IS NULL OR CAST(CIN.CheckInDate AS DATE) >= @FromCheckInDt)
        AND (@ToCheckInDt IS NULL OR CAST(CIN.CheckInDate AS DATE) <= @ToCheckInDt)
        AND (ISNULL(@ToolId,'') = '' OR AI.AssetRecordId IN (SELECT Item FROM DBO.SPLITSTRING(@ToolId,',')))
        AND (ISNULL(@SerialNum,'') = '' OR AI.SerialNo LIKE '%' + @SerialNum + '%')
        AND (ISNULL(@WONum,'') = '' OR WO.WorkOrderId IN (SELECT Item FROM DBO.SPLITSTRING(@WONum,',')))
        AND (ISNULL(@MPN,'') = '' OR WOP.RevisedItemmasterid IN (SELECT Item FROM DBO.SPLITSTRING(@MPN,',')))
        AND (ISNULL(@Level1,'')  = '' OR MSD.Level1Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
        AND (ISNULL(@Level2,'')  = '' OR MSD.Level2Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
        AND (ISNULL(@Level3,'')  = '' OR MSD.Level3Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
        AND (ISNULL(@Level4,'')  = '' OR MSD.Level4Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
        AND (ISNULL(@Level5,'')  = '' OR MSD.Level5Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
        AND (ISNULL(@Level6,'')  = '' OR MSD.Level6Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
        AND (ISNULL(@Level7,'')  = '' OR MSD.Level7Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
        AND (ISNULL(@Level8,'')  = '' OR MSD.Level8Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
        AND (ISNULL(@Level9,'')  = '' OR MSD.Level9Id  IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
        AND (ISNULL(@Level10,'') = '' OR MSD.Level10Id IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
    )
    SELECT
      COUNT(1) OVER () AS TotalRecordsCount,
      toolId,
      toolNum,
      serialNum,
      checkedInCalStatus,
      checkedOutCalStatus,
      currCalStatus,
      woNum,
      mpn,
      mpnSerialNum,
      task,
      FORMAT(checkInWODateRaw, 'MM-dd-yyyy') AS checkInWODate,
      FORMAT(checkOutWODateRaw, 'MM-dd-yyyy') AS checkOutWODate,
      FORMAT(mpnReceivedDateRaw, 'MM-dd-yyyy') AS mpnReceivedDate,
      FORMAT(mpnShippedDateRaw, 'MM-dd-yyyy') AS mpnShippedDate,
      level1,
      level2,
      level3,
      level4,
      level5,
      level6,
      level7,
      level8,
      level9,
      level10
    FROM ToolingCTE
    ORDER BY
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'toolNum')       THEN toolNum END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'toolNum')       THEN toolNum END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'serialNum')     THEN serialNum END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'serialNum')     THEN serialNum END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'woNum')         THEN woNum END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'woNum')         THEN woNum END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'checkInWODate') THEN checkInWODateRaw END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'checkInWODate') THEN checkInWODateRaw END DESC,
      checkInWODateRaw DESC
    OFFSET ((@PageNumber - 1) * @EffectivePageSize) ROWS
    FETCH NEXT @EffectivePageSize ROWS ONLY;

  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID INT,
      @DatabaseName VARCHAR(100) = DB_NAME()
      -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
      ,@AdhocComments VARCHAR(150) = '[usprpt_GetToolingReportData]'
      ,@ProcedureParameters VARCHAR(3000) = '@PageNumber = ''' + CAST(ISNULL(@PageNumber,'') AS VARCHAR(100)) +
        ''', @PageSize = ''' + CAST(ISNULL(@PageSize,'') AS VARCHAR(100)) +
        ''', @mastercompanyid = ''' + CAST(ISNULL(@mastercompanyid,'') AS VARCHAR(100)) +
        ''', @xmlFilter = ''' + CAST(ISNULL(@xmlFilter,'') AS VARCHAR(MAX))
      ,@ApplicationName VARCHAR(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END
