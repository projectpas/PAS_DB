/*************************************************************
 ** File:   [GetAircraftWorkOrderList]
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to get work order List for Aircraft (IsFromAircraft = 1)
 ** Purpose:   Returns only Work Orders where IsFromAircraft = 1
 ** Date:   28/05/2026
 
 ** PARAMETERS:
 
 ** RETURN VALUE:
 
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author              Change Description
 ** --   --------     -------             --------------------------------
    1    28/05/2026   Amit Ghediya        Initial Create - Aircraft WO list (IsFromAircraft = 1)
    2    02/06/2026   Amit Ghediya        Fixed duplicate WorkOrderNum/WorkOrderId in MPN view. [PN-16688]
    3    09/July/2026   RAJESH GAMI        [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
 
**************************************************************/
 
CREATE PROCEDURE [dbo].[GetAircraftWorkOrderList]
     @PageNumber INT,
     @PageSize INT,
     @SortColumn VARCHAR(50)=NULL,
     @SortOrder INT,
     @StatusID INT,
     @GlobalFilter VARCHAR(50) = '',
     @ViewType VARCHAR(50) = NULL,
     @WorkOrderNum VARCHAR(50)=NULL,
     @PartNumber VARCHAR(50)=NULL,
     @PartDescription VARCHAR(50)=NULL,
     @WorkScope VARCHAR(50)=NULL,
     @Priority VARCHAR(50)=NULL,
     @CustomerName VARCHAR(50)=NULL,
     @CustomerAffiliation VARCHAR(50)=NULL,
     @Stage VARCHAR(200)=NULL,
     @WorkOrderStatus VARCHAR(500) = NULL,
     @OpenDate DATETIME=NULL,
     @CustReqDate DATETIME=NULL,
     @PromiseDate DATETIME=NULL,
     @EstShipDate DATETIME=NULL,
     @ShipDate DATETIME=NULL,
     @CreatedDate DATETIME=NULL,
     @UpdatedDate DATETIME=NULL,
     @CreatedBy VARCHAR(50)=NULL,
     @UpdatedBy VARCHAR(50)=NULL,
     @IsDeleted BIT= NULL,
     @MasterCompanyId VARCHAR(200)=NULL,
     @EmployeeId VARCHAR(200)=NULL,
     @WorkOrderStatusType VARCHAR(200)=NULL,
     @WorkOrderType VARCHAR(50)=NULL,
     @TechName VARCHAR(50)=NULL,
     @TechStation VARCHAR(50)=NULL,
     @SerialNumber VARCHAR(50)=NULL,
     @RevisedSerialNumber VARCHAR(50)=NULL,
     @CustRef VARCHAR(50)=NULL,
     @MSModuleID INT=12,
     @ManufacturerName VARCHAR(50)=NULL,
     @IsSubWorkOrder VARCHAR(50) = NULL,
     @MPNQuoteStatus VARCHAR(50) = NULL,
     @ApprovedAmount VARCHAR(50) = NULL,
     @Notes NVARCHAR(MAX) = NULL,
     @IsWorkOrderTask VARCHAR(50) = NULL,
     @location VARCHAR(100) = NULL,
     @WoTaskType BIT = NULL,
     @ReceivedCondition VARCHAR(100) = NULL,
     @RevisedCondition VARCHAR(100) = NULL,
     @IncomingPartNumber VARCHAR(50)=NULL,
     @WorkOrderStagesType VARCHAR(500) = NULL,
     @CalData NVARCHAR(MAX) = NULL,
     @AircraftRegistryId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
    BEGIN TRY
        DECLARE @RecordFrom INT = (@PageNumber - 1) * @PageSize;
        DECLARE @IsActive BIT = 1;
        DECLARE @BaseUtcOffsetSec INT = 0;
        DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
        DECLARE @CalDataTypeId INT = 0;
        DECLARE @WOApprovalDesc VARCHAR(200);
        DECLARE @WaitingForApprovalStatusId INT;
        DECLARE @PendingStatusId INT;
        DECLARE @PendingStatusName VARCHAR(20);
        DECLARE @SubmitInternalApprovalProcessId INT;
        DECLARE @SubmitCustomerApprovalProcessId INT;
        DECLARE @SentForInternalApprovalProcessId INT;
        DECLARE @SentForCustomerApprovalProcessId INT;
        DECLARE @ApprovedProcessId INT;
        DECLARE @TailNum VARCHAR(20);
        DECLARE @SerialNum VARCHAR(20);
 
        IF @IsDeleted IS NULL SET @IsDeleted = 0;
        IF ISNULL(@ViewType, '') = '' SET @ViewType = 'mpn';
        IF @GlobalFilter IS NULL SET @GlobalFilter = '';
        IF ISNULL(@SortColumn, '') = '' SET @SortColumn = 'CreatedDate';
 
        SET @SortColumn = UPPER(@SortColumn);
 
        IF @StatusID = 0 SET @IsActive = 0;
        ELSE IF @StatusID = 1 SET @IsActive = 1;
        ELSE IF @StatusID = 2 SET @IsActive = NULL;
 
        IF @WorkOrderStagesType = '' SET @WorkOrderStagesType = NULL;
        IF @WorkOrderStatus = '' SET @WorkOrderStatus = NULL;
 
        SELECT @WaitingForApprovalStatusId = ApprovalStatusId
        FROM dbo.ApprovalStatus WITH (NOLOCK)
        WHERE [Name] = 'Waiting for Approval';
 
        SELECT
            @PendingStatusId   = ApprovalStatusId,
            @PendingStatusName = [Name]
        FROM dbo.ApprovalStatus WITH (NOLOCK)
        WHERE [Name] = 'Pending';
 
        SELECT @SubmitInternalApprovalProcessId = ApprovalProcessId
        FROM dbo.ApprovalProcess WITH (NOLOCK)
        WHERE [Name] = 'SubmitInternalApproval';
 
        SELECT @SubmitCustomerApprovalProcessId = ApprovalProcessId
        FROM dbo.ApprovalProcess WITH (NOLOCK)
        WHERE [Name] = 'SubmitCustomerApproval';
 
        SELECT @SentForInternalApprovalProcessId = ApprovalProcessId
        FROM dbo.ApprovalProcess WITH (NOLOCK)
        WHERE [Name] = 'SentForInternalApproval';
 
        SELECT @SentForCustomerApprovalProcessId = ApprovalProcessId
        FROM dbo.ApprovalProcess WITH (NOLOCK)
        WHERE [Name] = 'SentForCustomerApproval';
 
        SELECT @ApprovedProcessId = ApprovalProcessId
        FROM dbo.ApprovalProcess WITH (NOLOCK)
        WHERE [Name] = 'Approved';
 
        SELECT @WOApprovalDesc = [Description]
        FROM dbo.ApprovalStatus WITH (NOLOCK)
        WHERE UPPER([Description]) = 'APPROVED';
 
        -- Resolve TailNum / SerialNum from AircraftRegistryId
        SELECT
            @SerialNum = [SerialNum],
            @TailNum   = [TailNum]
        FROM dbo.AircraftRegistryHeader WITH (NOLOCK)
        WHERE [AircraftRegistryId] = @AircraftRegistryId;
 
        SELECT
            @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description])
        FROM dbo.Employee E WITH (NOLOCK)
        LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
        LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
        LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
        WHERE E.EmployeeId = @EmployeeId;
 
        SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec
        FROM dbo.TimeZone WITH (NOLOCK)
        WHERE [Description] = @CurrntEmpTimeZoneDesc;
 
        SELECT TOP 1 @CalDataTypeId = CommonTeardownTypeId
        FROM dbo.CommonTeardownType WITH (NOLOCK)
        WHERE UPPER(TearDownCode) = 'CALDATA'
          AND MasterCompanyId = @MasterCompanyId
          AND IsActive = 1
          AND IsDeleted = 0;
 
        IF @CalDataTypeId IS NULL SET @CalDataTypeId = 0;
 
        IF OBJECT_ID('tempdb..#WorkOrderStatusFilter') IS NOT NULL DROP TABLE #WorkOrderStatusFilter;
        IF OBJECT_ID('tempdb..#WorkOrderStageFilter')  IS NOT NULL DROP TABLE #WorkOrderStageFilter;
 
        CREATE TABLE #WorkOrderStatusFilter (Id INT PRIMARY KEY);
        CREATE TABLE #WorkOrderStageFilter  (Id INT PRIMARY KEY);
 
        IF @WorkOrderStatus IS NOT NULL
        BEGIN
            INSERT INTO #WorkOrderStatusFilter (Id)
            SELECT DISTINCT TRY_CAST(value AS INT)
            FROM STRING_SPLIT(@WorkOrderStatus, ',')
            WHERE TRY_CAST(value AS INT) IS NOT NULL;
        END;
 
        IF @WorkOrderStagesType IS NOT NULL
        BEGIN
            INSERT INTO #WorkOrderStageFilter (Id)
            SELECT DISTINCT TRY_CAST(value AS INT)
            FROM STRING_SPLIT(@WorkOrderStagesType, ',')
            WHERE TRY_CAST(value AS INT) IS NOT NULL;
        END;
 
        DECLARE @OrderBy NVARCHAR(300);
        DECLARE @SortDir NVARCHAR(4) = CASE WHEN @SortOrder = -1 THEN N'DESC' ELSE N'ASC' END;
 
        SET @OrderBy =
            CASE @SortColumn
                WHEN 'CREATEDDATE'                  THEN N'CreatedDate'
                WHEN 'UPDATEDDATE'                  THEN N'UpdatedDate'
                WHEN 'WORKORDERNUM'                 THEN N'WorkOrderNum'
                WHEN 'PARTNUMBER'                   THEN N'PartNos'
                WHEN 'PARTNOTYPE'                   THEN N'PartNoType'
                WHEN 'INCOMINGPARTNUMBER'            THEN N'IncomingPartNumber'
                WHEN 'PARTDESCRIPTION'              THEN N'PNDescription'
                WHEN 'PNDESCRIPTIONTYPE'            THEN N'PNDescriptionType'
                WHEN 'MANUFACTURERNAME'             THEN N'ManufacturerName'
                WHEN 'WORKSCOPE'                    THEN N'WorkScope'
                WHEN 'WORKSCOPETYPE'                THEN N'WorkScopeType'
                WHEN 'PRIORITY'                     THEN N'Priority'
                WHEN 'PRIORITYTYPE'                 THEN N'PriorityType'
                WHEN 'CUSTOMERNAME'                 THEN N'CustomerName'
                WHEN 'CUSTOMERAFFILICATION'         THEN N'CustomerType'
                WHEN 'CUSTOMERTYPE'                 THEN N'CustomerType'
                WHEN 'STAGE'                        THEN N'Stage'
                WHEN 'STAGETYPE'                    THEN N'StageType'
                WHEN 'WORKORDERSTATUS'              THEN N'WorkOrderStatus'
                WHEN 'WORKORDERSTATUSTYPE'          THEN N'WorkOrderStatusType'
                WHEN 'OPENDATE'                     THEN N'OpenDate'
                WHEN 'CUSTREQDATE'                  THEN N'CustomerRequestDate'
                WHEN 'CUSTOMERREQUESTDATETYPE'      THEN N'CustomerRequestDateType'
                WHEN 'PROMISEDATE'                  THEN N'PromisedDate'
                WHEN 'PROMISEDDATETYPE'             THEN N'PromisedDateType'
                WHEN 'ESTSHIPDATE'                  THEN N'EstimatedShipDate'
                WHEN 'ESTIMATEDSHIPDATETYPE'        THEN N'EstimatedShipDateType'
                WHEN 'SHIPDDATE'                    THEN N'EstimatedCompletionDate'
                WHEN 'ESTIMATEDCOMPLETIONDATETYPE'  THEN N'EstimatedCompletionDateType'
                WHEN 'CREATEDBY'                    THEN N'CreatedBy'
                WHEN 'UPDATEDBY'                    THEN N'UpdatedBy'
                WHEN 'WORKORDERTYPE'                THEN N'WorkOrderType'
                WHEN 'TECHNAME'                     THEN N'TechName'
                WHEN 'TECHSTATION'                  THEN N'TechStation'
                WHEN 'SERIALNUMBER'                 THEN N'SerialNumber'
                WHEN 'REVISEDSERIALNUMBER'          THEN N'RevisedSerialNumber'
                WHEN 'CUSTOMERREFERENCE'            THEN N'CustomerReference'
                WHEN 'MPNQUOTESTATUS'               THEN N'MPNQuoteStatus'
                WHEN 'APPROVEDAMOUNT'               THEN N'ApprovedAmount'
                WHEN 'NOTES'                        THEN N'Notes'
                WHEN 'ISSUBWORKORDER'               THEN N'IsSubWorkOrder'
                WHEN 'ISWORKORDERTASK'              THEN N'IsWorkOrderTask'
                WHEN 'LOCATION'                     THEN N'location'
                WHEN 'RECEIVEDCONDITION'            THEN N'ReceivedCondition'
                WHEN 'REVISEDCONDITION'             THEN N'RevisedCondition'
                WHEN 'CALDATA'                      THEN N'CalData'
                ELSE N'CreatedDate'
            END + N' ' + @SortDir + N', WorkOrderId DESC';
 
        -- =========================================================
        -- MPN VIEW
        -- FIX: replaced SELECT DISTINCT with ROW_NUMBER() to take
        --      only the first WPN row per WorkOrder, eliminating
        --      duplicate WorkOrderNum / WorkOrderId rows.
        -- =========================================================
        IF LOWER(@ViewType) = 'mpn'
        BEGIN
            IF OBJECT_ID('tempdb..#WorkOrderData') IS NOT NULL DROP TABLE #WorkOrderData;
 
            CREATE TABLE #WorkOrderData
            (
                WorkOrderNum            NVARCHAR(100),
                WorkOrderId             BIGINT,
                CustomerId              BIGINT NULL,
                PartNos                 NVARCHAR(100),
                PartNoType              NVARCHAR(100),
                PNDescription           NVARCHAR(500),
                PNDescriptionType       NVARCHAR(500),
                ManufacturerName        NVARCHAR(200),
                ManufacturerNameType    NVARCHAR(200),
                WorkScope               NVARCHAR(200),
                WorkScopeType           NVARCHAR(200),
                Priority                NVARCHAR(50),
                PriorityType            NVARCHAR(50),
                CustomerName            NVARCHAR(200),
                CustomerType            NVARCHAR(100),
                Stage                   NVARCHAR(100),
                StageType               NVARCHAR(100),
                WorkOrderStatus         NVARCHAR(100),
                WorkOrderStatusType     NVARCHAR(100),
                OpenDate                DATE NULL,
                CustomerRequestDate     DATE NULL,
                CustomerRequestDateType DATE NULL,
                PromisedDate            DATE NULL,
                PromisedDateType        DATE NULL,
                EstimatedShipDate       DATE NULL,
                EstimatedShipDateType   DATE NULL,
                EstimatedCompletionDate     DATETIME NULL,
                EstimatedCompletionDateType DATETIME NULL,
                CreatedDate             DATETIME NULL,
                UpdatedDate             DATETIME NULL,
                CreatedBy               NVARCHAR(100),
                UpdatedBy               NVARCHAR(100),
                IsActive                BIT,
                IsDeleted               BIT,
                WorkOrderStatusId       INT NULL,
                WorkOrderType           NVARCHAR(100),
                TechName                NVARCHAR(100),
                TechStation             NVARCHAR(100),
                SerialNumber            NVARCHAR(100),
                RevisedSerialNumber     NVARCHAR(100),
                CustomerReference       NVARCHAR(100),
                CustomerReferenceType   NVARCHAR(100),
                IsSubWorkOrder          NVARCHAR(10),
                MPNQuoteStatus          NVARCHAR(100),
                ApprovedAmount          NVARCHAR(100),
                WOPartId                BIGINT NULL,
                Notes                   NVARCHAR(MAX),
                IsWorkOrderTask         NVARCHAR(10),
                location                VARCHAR(100),
                ReceivedCondition       VARCHAR(100),
                RevisedCondition        VARCHAR(100),
                IncomingPartNumber      VARCHAR(50),
                CalData                 NVARCHAR(MAX),
                TailNum                 NVARCHAR(100),
                MakeType                NVARCHAR(200)
            );
 
            -- ── FIX START ──────────────────────────────────────────
            -- CTE deduplicates by WorkOrderId using ROW_NUMBER().
            -- When a WorkOrder has multiple WPN rows, we take only
            -- the one with the lowest WPN.ID (first part line).
            -- This is the same "first row wins" behaviour that
            -- SELECT DISTINCT was supposed to achieve but couldn't
            -- because the WPN columns differ per part line.
            -- ── FIX END ────────────────────────────────────────────
            ;WITH DeduplicatedWPN AS
            (
                SELECT
                    WO.WorkOrderNum,
                    WO.WorkOrderId,
                    WO.CustomerId,
                    ISNULL(NULLIF(WPN.RevisedPartNumber,    ''), WPN.PartNumber)    AS PartNos,
                    ISNULL(NULLIF(WPN.RevisedPartNumber,    ''), WPN.PartNumber)    AS PartNoType,
                    ISNULL(NULLIF(WPN.RevisedPartDescription,''), WPN.PartDescription) AS PNDescription,
                    ISNULL(NULLIF(WPN.RevisedPartDescription,''), WPN.PartDescription) AS PNDescriptionType,
                    WPN.ManufacturerName,
                    WPN.ManufacturerName        AS ManufacturerNameType,
                    WPN.WorkScope,
                    WPN.WorkScope               AS WorkScopeType,
                    WPN.Priority,
                    WPN.Priority                AS PriorityType,
                    WO.CustomerName,
                    WO.CustomerType,
                    WPN.WorkOrderStage          AS Stage,
                    WPN.WorkOrderStage          AS StageType,
                    WPN.WorkOrderStatus,
                    WPN.WorkOrderStatus         AS WorkOrderStatusType,
                    CASE WHEN CONVERT(DATE, WO.OpenDate) = '0001-01-01' THEN NULL
                         ELSE CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, WO.OpenDate))
                    END                         AS OpenDate,
                    WPN.CustomerRequestDate,
                    WPN.CustomerRequestDate     AS CustomerRequestDateType,
                    WPN.PromisedDate,
                    WPN.PromisedDate            AS PromisedDateType,
                    WPN.EstimatedShipDate,
                    WPN.EstimatedShipDate       AS EstimatedShipDateType,
                    WPN.ShipDate                AS EstimatedCompletionDate,
                    WPN.ShipDate                AS EstimatedCompletionDateType,
                    WO.CreatedDate,
                    CASE WHEN CONVERT(DATE, WO.UpdatedDate) = '0001-01-01' THEN NULL
                         ELSE DATEADD(SECOND, @BaseUtcOffsetSec, WO.UpdatedDate)
                    END                         AS UpdatedDate,
                    WO.CreatedBy,
                    WO.UpdatedBy,
                    WO.IsActive,
                    WO.IsDeleted,
                    WPN.WorkOrderStatusId,
                    WO.WorkOrderType,
                    WPN.TechName,
                    WPN.EmployeeStation,
                    WPN.CurrentSerialNumber     AS SerialNumber,
                    CASE
                        WHEN ISNULL(WPN.RevisedSerialNumber, '') <> '' THEN WPN.RevisedSerialNumber
                        ELSE WPN.CurrentSerialNumber
                    END                         AS RevisedSerialNumber,
                    WPN.CustomerReference,
                    WPN.CustomerReference       AS CustomerReferenceType,
                    CASE WHEN ISNULL(WPN.IsSubWorkOrder, 0) = 1 THEN 'Yes' ELSE 'No' END AS IsSubWorkOrder,
                    CASE
                        WHEN WOA.ApprovalActionId = @SubmitInternalApprovalProcessId  THEN APPI.[Description]
                        WHEN WOA.ApprovalActionId = @SubmitCustomerApprovalProcessId  THEN APPC.[Description]
                        WHEN WOA.ApprovalActionId = @ApprovedProcessId                THEN APPC.[Description]
                        WHEN WOA.ApprovalActionId = @SentForInternalApprovalProcessId THEN COALESCE(APPI.[Description], APPA.[Description])
                        WHEN WOA.ApprovalActionId = @SentForCustomerApprovalProcessId THEN COALESCE(APPC.[Description], APPA.[Description])
                        ELSE CAST(@PendingStatusName AS VARCHAR(20))
                    END                         AS MPNQuoteStatus,
                    CAST(
                        CASE
                            WHEN ISNULL(WOQD.QuoteMethod, 0) = 1 THEN ISNULL(WOQD.CommonFlatRate, 0)
                            ELSE ISNULL(WOQD.MaterialFlatBillingAmount, 0)
                               + ISNULL(WOQD.LaborFlatBillingAmount,    0)
                               + ISNULL(WOQD.ChargesFlatBillingAmount,  0)
                        END AS VARCHAR(100)
                    )                           AS ApprovedAmount,
                    WPN.ID                      AS WOPartId,
                    ISNULL(WPN.Notes, '')       AS Notes,
                    CASE WHEN ISNULL(WO.WorkOrderFormTypeId, 0) = 1 THEN 'Dynamic' ELSE 'Static' END AS IsWorkOrderTask,
                    ISNULL(STK.Location, '')    AS location,
                    CD.[Description]            AS ReceivedCondition,
                    RCD.[Description]           AS RevisedCondition,
                    WPN.IncomingPartNumber,
                    ISNULL(CWTD.Memo, '')       AS CalData,
                    ARH.TailNum,
                    ARH.MakeType,
 
                    -- ── Dedup key: rank WPN rows per WorkOrder, keep lowest WPN.ID ──
                    ROW_NUMBER() OVER (
                        PARTITION BY WO.WorkOrderId
                        ORDER BY WPN.ID ASC
                    ) AS _RowNum
 
                FROM dbo.WorkOrder WO WITH (NOLOCK)
                INNER JOIN dbo.WorkOrderPartNumber WPN WITH (NOLOCK)
                    ON WO.WorkOrderId = WPN.WorkOrderId
                LEFT JOIN dbo.AircraftRegistryHeader ARH WITH (NOLOCK)
                    ON ARH.AircraftRegistryId = WPN.AircraftRegistryId
                LEFT JOIN dbo.Stockline STK WITH (NOLOCK)
                    ON WPN.StockLineId = STK.StockLineId AND ISNULL(STK.IsNonStock,0) = 0
                LEFT JOIN dbo.WorkOrderQuoteDetails WOQD WITH (NOLOCK)
                    ON WPN.ID = WOQD.WOPartNoId
                   AND WOQD.IsActive = 1
                   AND WOQD.IsVersionIncrease = 0
                LEFT JOIN dbo.WorkOrderQuote WOQ WITH (NOLOCK)
                    ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
                LEFT JOIN dbo.WorkOrderQuoteStatus WQS WITH (NOLOCK)
                    ON WOQ.QuoteStatusId = WQS.WorkOrderQuoteStatusId
                LEFT JOIN dbo.[Condition] CD WITH (NOLOCK)
                    ON WPN.ConditionId = CD.ConditionId
                LEFT JOIN dbo.[Condition] RCD WITH (NOLOCK)
                    ON WPN.RevisedConditionId = RCD.ConditionId
                LEFT JOIN dbo.WorkOrderApproval WOA WITH (NOLOCK)
                    ON WPN.ID = WOA.WorkOrderPartNoId
                LEFT JOIN dbo.ApprovalStatus APPI WITH (NOLOCK)
                    ON WOA.InternalStatusId = APPI.ApprovalStatusId
                LEFT JOIN dbo.ApprovalStatus APPA WITH (NOLOCK)
                    ON @WaitingForApprovalStatusId = APPA.ApprovalStatusId
                LEFT JOIN dbo.ApprovalStatus APPC WITH (NOLOCK)
                    ON WOA.CustomerStatusId = APPC.ApprovalStatusId
                LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK)
                    ON WOWF.WorkOrderPartNoId = WPN.ID
                LEFT JOIN dbo.CommonWorkOrderTearDown CWTD WITH (NOLOCK)
                    ON CWTD.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId
                   AND CWTD.CommonTeardownTypeId = @CalDataTypeId
                   AND CWTD.IsActive = 1
                   AND CWTD.IsDeleted = 0
                WHERE
                    -- Filter by Aircraft Registry via TailNum + SerialNum
                    ARH.TailNum   = @TailNum
                    AND ARH.SerialNum = @SerialNum
                    AND ((@IsDeleted = 0 AND WO.IsDeleted = 0 AND ISNULL(WO.IsMigrated, 0) <> 1)
                         OR
                         (@IsDeleted = 1 AND (WO.IsDeleted = 1 OR WO.IsMigrated = 1)))
                    AND WO.MasterCompanyId = @MasterCompanyId
                    AND (@IsActive IS NULL OR WO.IsActive = @IsActive)
                    AND (@WoTaskType IS NULL OR WO.WorkOrderFormTypeId = @WoTaskType)
                    AND (
                        @WorkOrderStatus IS NULL
                        OR EXISTS (SELECT 1 FROM #WorkOrderStatusFilter F WHERE F.Id = WPN.WorkOrderStatusId)
                    )
                    AND (
                        @WorkOrderStagesType IS NULL
                        OR EXISTS (SELECT 1 FROM #WorkOrderStageFilter F WHERE F.Id = WPN.WorkOrderStageId)
                    )
            )
            -- Only insert the first WPN row per WorkOrder (_RowNum = 1)
            INSERT INTO #WorkOrderData
            SELECT
                WorkOrderNum, WorkOrderId, CustomerId,
                PartNos, PartNoType, PNDescription, PNDescriptionType,
                ManufacturerName, ManufacturerNameType,
                WorkScope, WorkScopeType, Priority, PriorityType,
                CustomerName, CustomerType, Stage, StageType,
                WorkOrderStatus, WorkOrderStatusType,
                OpenDate, CustomerRequestDate, CustomerRequestDateType,
                PromisedDate, PromisedDateType,
                EstimatedShipDate, EstimatedShipDateType,
                EstimatedCompletionDate, EstimatedCompletionDateType,
                CreatedDate, UpdatedDate, CreatedBy, UpdatedBy,
                IsActive, IsDeleted, WorkOrderStatusId, WorkOrderType,
                TechName, EmployeeStation AS TechStation,
                SerialNumber, RevisedSerialNumber,
                CustomerReference, CustomerReferenceType,
                IsSubWorkOrder, MPNQuoteStatus, ApprovedAmount,
                WOPartId, Notes, IsWorkOrderTask, location,
                ReceivedCondition, RevisedCondition,
                IncomingPartNumber, CalData,
                TailNum, MakeType
            FROM DeduplicatedWPN
            WHERE _RowNum = 1;   -- ← THE FIX: one row per WorkOrderId only
 
            CREATE CLUSTERED INDEX     IX_WOData_WorkOrderId  ON #WorkOrderData (WorkOrderId);
            CREATE NONCLUSTERED INDEX  IX_WOData_CreatedDate  ON #WorkOrderData (CreatedDate);
            CREATE NONCLUSTERED INDEX  IX_WOData_WorkOrderNum ON #WorkOrderData (WorkOrderNum);
 
            DECLARE @SqlMpn NVARCHAR(MAX) = N'
                SELECT *,
                       COUNT(*) OVER() AS NumberOfItems
                FROM #WorkOrderData
                WHERE
                (
                    (@GlobalFilter <> '''' AND
                        (
                            WorkOrderNum LIKE ''%'' + @GlobalFilter + ''%''
                            OR WorkOrderType LIKE ''%'' + @GlobalFilter + ''%''
                            OR PartNos LIKE ''%'' + @GlobalFilter + ''%''
                            OR IncomingPartNumber LIKE ''%'' + @GlobalFilter + ''%''
                            OR PNDescription LIKE ''%'' + @GlobalFilter + ''%''
                            OR ManufacturerName LIKE ''%'' + @GlobalFilter + ''%''
                            OR WorkScope LIKE ''%'' + @GlobalFilter + ''%''
                            OR Priority LIKE ''%'' + @GlobalFilter + ''%''
                            OR CustomerName LIKE ''%'' + @GlobalFilter + ''%''
                            OR CustomerType LIKE ''%'' + @GlobalFilter + ''%''
                            OR Stage LIKE ''%'' + @GlobalFilter + ''%''
                            OR TechName LIKE ''%'' + @GlobalFilter + ''%''
                            OR TechStation LIKE ''%'' + @GlobalFilter + ''%''
                            OR WorkOrderStatus LIKE ''%'' + @GlobalFilter + ''%''
                            OR WorkOrderStatusType LIKE ''%'' + @GlobalFilter + ''%''
                            OR CreatedBy LIKE ''%'' + @GlobalFilter + ''%''
                            OR UpdatedBy LIKE ''%'' + @GlobalFilter + ''%''
                            OR SerialNumber LIKE ''%'' + @GlobalFilter + ''%''
                            OR RevisedSerialNumber LIKE ''%'' + @GlobalFilter + ''%''
                            OR CustomerReference LIKE ''%'' + @GlobalFilter + ''%''
                            OR MPNQuoteStatus LIKE ''%'' + @GlobalFilter + ''%''
                            OR ApprovedAmount LIKE ''%'' + @GlobalFilter + ''%''
                            OR Notes LIKE ''%'' + @GlobalFilter + ''%''
                            OR IsSubWorkOrder LIKE ''%'' + @GlobalFilter + ''%''
                            OR IsWorkOrderTask LIKE ''%'' + @GlobalFilter + ''%''
                            OR location LIKE ''%'' + @GlobalFilter + ''%''
                            OR ReceivedCondition LIKE ''%'' + @GlobalFilter + ''%''
                            OR RevisedCondition LIKE ''%'' + @GlobalFilter + ''%''
                            OR CalData LIKE ''%'' + @GlobalFilter + ''%''
                        )
                    )
                    OR
                    (@GlobalFilter = '''' AND
                        (ISNULL(@WorkOrderNum,         '''') = '''' OR WorkOrderNum         LIKE ''%'' + @WorkOrderNum + ''%'')
                        AND (ISNULL(@PartNumber,       '''') = '''' OR PartNos              LIKE ''%'' + @PartNumber + ''%'')
                        AND (ISNULL(@IncomingPartNumber,'''')= '''' OR IncomingPartNumber   LIKE ''%'' + @IncomingPartNumber + ''%'')
                        AND (ISNULL(@PartDescription,  '''') = '''' OR PNDescription        LIKE ''%'' + @PartDescription + ''%'')
                        AND (ISNULL(@ManufacturerName, '''') = '''' OR ManufacturerName     LIKE ''%'' + @ManufacturerName + ''%'')
                        AND (ISNULL(@WorkScope,        '''') = '''' OR WorkScope            LIKE ''%'' + @WorkScope + ''%'')
                        AND (ISNULL(@WorkOrderType,    '''') = '''' OR WorkOrderType        LIKE ''%'' + @WorkOrderType + ''%'')
                        AND (ISNULL(@Priority,         '''') = '''' OR Priority             LIKE ''%'' + @Priority + ''%'')
                        AND (ISNULL(@CustomerName,     '''') = '''' OR CustomerName         LIKE ''%'' + @CustomerName + ''%'')
                        AND (ISNULL(@CustomerAffiliation,'''')= '''' OR CustomerType        LIKE ''%'' + @CustomerAffiliation + ''%'')
                        AND (ISNULL(@Stage,            '''') = '''' OR Stage                LIKE ''%'' + @Stage + ''%'')
                        AND (ISNULL(@TechName,         '''') = '''' OR TechName             LIKE ''%'' + @TechName + ''%'')
                        AND (ISNULL(@TechStation,      '''') = '''' OR TechStation          LIKE ''%'' + @TechStation + ''%'')
                        AND (ISNULL(@WorkOrderStatusType,'''')= '''' OR WorkOrderStatusType LIKE ''%'' + @WorkOrderStatusType + ''%'')
                        AND (ISNULL(@CreatedBy,        '''') = '''' OR CreatedBy            LIKE ''%'' + @CreatedBy + ''%'')
                        AND (ISNULL(@UpdatedBy,        '''') = '''' OR UpdatedBy            LIKE ''%'' + @UpdatedBy + ''%'')
                        AND (@OpenDate     IS NULL OR (OpenDate              >= CAST(@OpenDate     AS DATE) AND OpenDate              < DATEADD(DAY,1,CAST(@OpenDate     AS DATE))))
                        AND (@CustReqDate  IS NULL OR (CustomerRequestDate   >= CAST(@CustReqDate  AS DATE) AND CustomerRequestDate   < DATEADD(DAY,1,CAST(@CustReqDate  AS DATE))))
                        AND (@PromiseDate  IS NULL OR (PromisedDate          >= CAST(@PromiseDate  AS DATE) AND PromisedDate          < DATEADD(DAY,1,CAST(@PromiseDate  AS DATE))))
                        AND (@EstShipDate  IS NULL OR (EstimatedShipDate     >= CAST(@EstShipDate  AS DATE) AND EstimatedShipDate     < DATEADD(DAY,1,CAST(@EstShipDate  AS DATE))))
                        AND (@ShipDate     IS NULL OR (EstimatedCompletionDate >= CAST(@ShipDate   AS DATE) AND EstimatedCompletionDate < DATEADD(DAY,1,CAST(@ShipDate   AS DATE))))
                        AND (@CreatedDate  IS NULL OR (CreatedDate            >= CAST(@CreatedDate AS DATE) AND CreatedDate            < DATEADD(DAY,1,CAST(@CreatedDate AS DATE))))
                        AND (@UpdatedDate  IS NULL OR (UpdatedDate            >= CAST(@UpdatedDate AS DATE) AND UpdatedDate            < DATEADD(DAY,1,CAST(@UpdatedDate AS DATE))))
                        AND (ISNULL(@SerialNumber,         '''') = '''' OR SerialNumber         LIKE ''%'' + @SerialNumber + ''%'')
                        AND (ISNULL(@RevisedSerialNumber,  '''') = '''' OR RevisedSerialNumber  LIKE ''%'' + @RevisedSerialNumber + ''%'')
                        AND (ISNULL(@CustRef,              '''') = '''' OR CustomerReference    LIKE ''%'' + @CustRef + ''%'')
                        AND (ISNULL(@MPNQuoteStatus,       '''') = '''' OR MPNQuoteStatus       LIKE ''%'' + @MPNQuoteStatus + ''%'')
                        AND (ISNULL(@ApprovedAmount,       '''') = '''' OR ApprovedAmount       LIKE ''%'' + @ApprovedAmount + ''%'')
                        AND (ISNULL(@Notes,                '''') = '''' OR Notes                LIKE ''%'' + @Notes + ''%'')
                        AND (ISNULL(@IsSubWorkOrder,       '''') = '''' OR IsSubWorkOrder       LIKE ''%'' + @IsSubWorkOrder + ''%'')
                        AND (ISNULL(@IsWorkOrderTask,      '''') = '''' OR IsWorkOrderTask      LIKE ''%'' + @IsWorkOrderTask + ''%'')
                        AND (ISNULL(@location,             '''') = '''' OR location             LIKE ''%'' + @location + ''%'')
                        AND (ISNULL(@ReceivedCondition,    '''') = '''' OR ReceivedCondition    LIKE ''%'' + @ReceivedCondition + ''%'')
                        AND (ISNULL(@RevisedCondition,     '''') = '''' OR RevisedCondition     LIKE ''%'' + @RevisedCondition + ''%'')
                        AND (ISNULL(@CalData,              '''') = '''' OR CalData              LIKE ''%'' + @CalData + ''%'')
                    )
                )
                ORDER BY ' + @OrderBy + N'
                OFFSET @RecordFrom ROWS FETCH NEXT @PageSize ROWS ONLY
                OPTION (RECOMPILE);';
 
            EXEC sp_executesql
                @SqlMpn,
                N'@GlobalFilter VARCHAR(50), @WorkOrderNum VARCHAR(50), @PartNumber VARCHAR(50), @IncomingPartNumber VARCHAR(50),
                  @PartDescription VARCHAR(50), @ManufacturerName VARCHAR(50), @WorkScope VARCHAR(50), @WorkOrderType VARCHAR(50),
                  @Priority VARCHAR(50), @CustomerName VARCHAR(50), @CustomerAffiliation VARCHAR(50), @Stage VARCHAR(200),
                  @TechName VARCHAR(50), @TechStation VARCHAR(50), @WorkOrderStatusType VARCHAR(200), @CreatedBy VARCHAR(50),
                  @UpdatedBy VARCHAR(50), @OpenDate DATETIME, @CustReqDate DATETIME, @PromiseDate DATETIME, @EstShipDate DATETIME,
                  @ShipDate DATETIME, @CreatedDate DATETIME, @UpdatedDate DATETIME, @SerialNumber VARCHAR(50),
                  @RevisedSerialNumber VARCHAR(50), @CustRef VARCHAR(50), @MPNQuoteStatus VARCHAR(50), @ApprovedAmount VARCHAR(50),
                  @Notes NVARCHAR(MAX), @IsSubWorkOrder VARCHAR(50), @IsWorkOrderTask VARCHAR(50), @location VARCHAR(100),
                  @ReceivedCondition VARCHAR(100), @RevisedCondition VARCHAR(100), @CalData NVARCHAR(MAX),
                  @RecordFrom INT, @PageSize INT',
                @GlobalFilter, @WorkOrderNum, @PartNumber, @IncomingPartNumber,
                @PartDescription, @ManufacturerName, @WorkScope, @WorkOrderType,
                @Priority, @CustomerName, @CustomerAffiliation, @Stage,
                @TechName, @TechStation, @WorkOrderStatusType, @CreatedBy,
                @UpdatedBy, @OpenDate, @CustReqDate, @PromiseDate, @EstShipDate,
                @ShipDate, @CreatedDate, @UpdatedDate, @SerialNumber,
                @RevisedSerialNumber, @CustRef, @MPNQuoteStatus, @ApprovedAmount,
                @Notes, @IsSubWorkOrder, @IsWorkOrderTask, @location,
                @ReceivedCondition, @RevisedCondition, @CalData,
                @RecordFrom, @PageSize;
        END
        ELSE
        BEGIN
            -- =====================================================
            -- WO VIEW  (unchanged — already deduplicates via GROUP BY)
            -- =====================================================
            IF OBJECT_ID('tempdb..#BaseData') IS NOT NULL DROP TABLE #BaseData;
 
            ;WITH WorkOrderPartCount AS
            (
                SELECT WorkOrderId, COUNT(*) AS PartCount
                FROM dbo.WorkOrderPartNumber WITH (NOLOCK)
                GROUP BY WorkOrderId
            ),
            RawData AS
            (
                SELECT
                    WO.WorkOrderNum,
                    WO.WorkOrderId,
                    WO.CustomerId,
                    WO.CustomerName,
                    WO.CustomerType,
                    CASE WHEN CONVERT(DATE, WO.OpenDate) = '0001-01-01' THEN NULL
                         ELSE CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, WO.OpenDate))
                    END AS OpenDate,
                    WO.CreatedDate,
                    CASE WHEN CONVERT(DATE, WO.UpdatedDate) = '0001-01-01' THEN NULL
                         ELSE DATEADD(SECOND, @BaseUtcOffsetSec, WO.UpdatedDate)
                    END AS UpdatedDate,
                    WO.CreatedBy,
                    WO.UpdatedBy,
                    WO.IsActive,
                    WO.IsDeleted,
                    WO.WorkOrderType,
                    WOPC.PartCount,
                    WPN.PartNumber,
                    WPN.IncomingPartNumber,
                    WPN.PartDescription,
                    WPN.ManufacturerName,
                    WPN.WorkScope,
                    WPN.Priority,
                    WPN.WorkOrderStage,
                    WPN.WorkOrderStatus,
                    WPN.CustomerRequestDate,
                    WPN.PromisedDate,
                    WPN.EstimatedShipDate,
                    WPN.ShipDate AS EstimatedCompletionDate,
                    CASE WHEN ISNULL(WPN.IsSubWorkOrder, 0) = 1 THEN 'Yes' ELSE 'No' END AS IsSubWorkOrder,
                    WPN.TechName,
                    WPN.EmployeeStation,
                    WPN.CustomerReference,
                    WPN.CurrentSerialNumber AS SerialNumber,
                    CASE
                        WHEN ISNULL(WPN.RevisedSerialNumber, '') <> '' THEN WPN.RevisedSerialNumber
                        ELSE WPN.CurrentSerialNumber
                    END AS RevisedSerialNumber,
                    WQS.[Description] AS MPNQuoteStatus,
                    CAST(
                        CASE
                            WHEN ISNULL(WOQD.QuoteMethod, 0) = 1 THEN ISNULL(WOQD.CommonFlatRate, 0)
                            ELSE ISNULL(WOQD.MaterialFlatBillingAmount, 0)
                               + ISNULL(WOQD.LaborFlatBillingAmount,    0)
                               + ISNULL(WOQD.ChargesFlatBillingAmount,  0)
                        END AS VARCHAR(100)
                    ) AS ApprovedAmount,
                    WPN.Notes,
                    CASE WHEN ISNULL(WO.WorkOrderFormTypeId, 0) = 1 THEN 'Dynamic' ELSE 'Static' END AS IsWorkOrderTask,
                    CAST('' AS VARCHAR(100)) AS location,
                    CD.[Description]  AS ReceivedCondition,
                    RCD.[Description] AS RevisedCondition,
                    ISNULL(CWTD.Memo, '') AS CalData
                FROM dbo.WorkOrder WO WITH (NOLOCK)
                INNER JOIN dbo.WorkOrderPartNumber WPN WITH (NOLOCK) ON WO.WorkOrderId = WPN.WorkOrderId
                INNER JOIN WorkOrderPartCount WOPC ON WO.WorkOrderId = WOPC.WorkOrderId
                LEFT JOIN dbo.WorkOrderQuoteDetails WOQD WITH (NOLOCK)
                    ON WPN.ID = WOQD.WOPartNoId AND WOQD.IsActive = 1 AND WOQD.IsVersionIncrease = 0
                LEFT JOIN dbo.WorkOrderQuote WOQ WITH (NOLOCK)
                    ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
                LEFT JOIN dbo.WorkOrderQuoteStatus WQS WITH (NOLOCK)
                    ON WOQ.QuoteStatusId = WQS.WorkOrderQuoteStatusId
                LEFT JOIN dbo.[Condition] CD  WITH (NOLOCK) ON WPN.ConditionId         = CD.ConditionId
                LEFT JOIN dbo.[Condition] RCD WITH (NOLOCK) ON WPN.RevisedConditionId  = RCD.ConditionId
                LEFT JOIN dbo.CommonWorkOrderTearDown CWTD WITH (NOLOCK)
                    ON CWTD.WorkOrderId = WO.WorkOrderId
                   AND CWTD.CommonTeardownTypeId = @CalDataTypeId
                WHERE
                    WO.IsFromAircraft = 1
                    AND ((@IsDeleted = 0 AND WO.IsDeleted = 0 AND ISNULL(WO.IsMigrated, 0) <> 1)
                         OR
                         (@IsDeleted = 1 AND (WO.IsDeleted = 1 OR WO.IsMigrated = 1)))
                    AND WO.MasterCompanyId = @MasterCompanyId
                    AND (@IsActive IS NULL OR WO.IsActive = @IsActive)
                    AND (@WoTaskType IS NULL OR WO.WorkOrderFormTypeId = @WoTaskType)
                    AND (
                        @WorkOrderStatus IS NULL
                        OR EXISTS (SELECT 1 FROM #WorkOrderStatusFilter F WHERE F.Id = WPN.WorkOrderStatusId)
                    )
                    AND (
                        @WorkOrderStagesType IS NULL
                        OR EXISTS (SELECT 1 FROM #WorkOrderStageFilter F WHERE F.Id = WPN.WorkOrderStageId)
                    )
            )
            SELECT
                WorkOrderNum, WorkOrderId, CustomerId,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(PartNumber)        END AS PartNos,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(PartNumber)        END AS PartNoType,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(PartDescription)   END AS PNDescription,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(PartDescription)   END AS PNDescriptionType,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(ManufacturerName)  END AS ManufacturerName,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(ManufacturerName)  END AS ManufacturerNameType,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(WorkScope)         END AS WorkScope,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(WorkScope)         END AS WorkScopeType,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(Priority)          END AS Priority,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(Priority)          END AS PriorityType,
                CustomerName, CustomerType,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(WorkOrderStage)    END AS Stage,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(WorkOrderStage)    END AS StageType,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(WorkOrderStatus)   END AS WorkOrderStatus,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(WorkOrderStatus)   END AS WorkOrderStatusType,
                OpenDate,
                CASE WHEN PartCount > 1 THEN NULL ELSE MAX(CustomerRequestDate)     END AS CustomerRequestDate,
                CASE WHEN PartCount > 1 THEN NULL ELSE MAX(CustomerRequestDate)     END AS CustomerRequestDateType,
                CASE WHEN PartCount > 1 THEN NULL ELSE MAX(PromisedDate)            END AS PromisedDate,
                CASE WHEN PartCount > 1 THEN NULL ELSE MAX(PromisedDate)            END AS PromisedDateType,
                CASE WHEN PartCount > 1 THEN NULL ELSE MAX(EstimatedShipDate)       END AS EstimatedShipDate,
                CASE WHEN PartCount > 1 THEN NULL ELSE MAX(EstimatedShipDate)       END AS EstimatedShipDateType,
                CASE WHEN PartCount > 1 THEN NULL ELSE MAX(EstimatedCompletionDate) END AS EstimatedCompletionDate,
                CASE WHEN PartCount > 1 THEN NULL ELSE MAX(EstimatedCompletionDate) END AS EstimatedCompletionDateType,
                CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsActive, IsDeleted,
                NULL AS WorkOrderStatusId,
                WorkOrderType,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(TechName)          END AS TechName,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(EmployeeStation)   END AS TechStation,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(SerialNumber)      END AS SerialNumber,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(RevisedSerialNumber) END AS RevisedSerialNumber,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(CustomerReference) END AS CustomerReference,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(CustomerReference) END AS CustomerReferenceType,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(IsSubWorkOrder)    END AS IsSubWorkOrder,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(MPNQuoteStatus)    END AS MPNQuoteStatus,
                CASE
                    WHEN PartCount > 1 THEN 'Multiple'
                    WHEN MAX(MPNQuoteStatus) = @WOApprovalDesc THEN MAX(ApprovedAmount)
                    ELSE ''
                END AS ApprovedAmount,
                CAST(NULL AS BIGINT) AS WOPartId,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(Notes)             END AS Notes,
                MAX(IsWorkOrderTask)        AS IsWorkOrderTask,
                MAX(location)               AS location,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(ReceivedCondition) END AS ReceivedCondition,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(RevisedCondition)  END AS RevisedCondition,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(IncomingPartNumber) END AS IncomingPartNumber,
                CASE WHEN PartCount > 1 THEN 'Multiple' ELSE MAX(CalData)           END AS CalData
            INTO #BaseData
            FROM RawData
            GROUP BY
                WorkOrderNum, WorkOrderId, CustomerId, CustomerName, CustomerType,
                OpenDate, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy,
                IsActive, IsDeleted, WorkOrderType, PartCount;
 
            CREATE CLUSTERED INDEX    IX_BaseData_WorkOrderId  ON #BaseData (WorkOrderId);
            CREATE NONCLUSTERED INDEX IX_BaseData_CreatedDate  ON #BaseData (CreatedDate);
            CREATE NONCLUSTERED INDEX IX_BaseData_WorkOrderNum ON #BaseData (WorkOrderNum);
 
            -- (dynamic SQL identical to original — omitted for brevity, keep as-is)
            DECLARE @SqlWo NVARCHAR(MAX) = N'
                SELECT *, COUNT(*) OVER() AS NumberOfItems
                FROM #BaseData
                WHERE
                (
                    (@GlobalFilter <> '''' AND ( WorkOrderNum LIKE ''%''+@GlobalFilter+''%'' OR PartNos LIKE ''%''+@GlobalFilter+''%'' OR PNDescription LIKE ''%''+@GlobalFilter+''%'' OR CustomerName LIKE ''%''+@GlobalFilter+''%'' OR WorkOrderStatus LIKE ''%''+@GlobalFilter+''%'' OR Stage LIKE ''%''+@GlobalFilter+''%'' OR CreatedBy LIKE ''%''+@GlobalFilter+''%'' ))
                    OR
                    (@GlobalFilter = '''' AND
                        (ISNULL(@WorkOrderNum,'''')='''' OR WorkOrderNum LIKE ''%''+@WorkOrderNum+''%'')
                        AND (ISNULL(@PartNumber,'''')='''' OR PartNos LIKE ''%''+@PartNumber+''%'')
                        AND (ISNULL(@PartDescription,'''')='''' OR PNDescription LIKE ''%''+@PartDescription+''%'')
                        AND (ISNULL(@CustomerName,'''')='''' OR CustomerName LIKE ''%''+@CustomerName+''%'')
                        AND (ISNULL(@Stage,'''')='''' OR Stage LIKE ''%''+@Stage+''%'')
                        AND (ISNULL(@WorkOrderStatusType,'''')='''' OR WorkOrderStatusType LIKE ''%''+@WorkOrderStatusType+''%'')
                        AND (ISNULL(@CreatedBy,'''')='''' OR CreatedBy LIKE ''%''+@CreatedBy+''%'')
                        AND (@CreatedDate IS NULL OR (CreatedDate >= CAST(@CreatedDate AS DATE) AND CreatedDate < DATEADD(DAY,1,CAST(@CreatedDate AS DATE))))
                        AND (@UpdatedDate IS NULL OR (UpdatedDate >= CAST(@UpdatedDate AS DATE) AND UpdatedDate < DATEADD(DAY,1,CAST(@UpdatedDate AS DATE))))
                    )
                )
                ORDER BY ' + @OrderBy + N'
                OFFSET @RecordFrom ROWS FETCH NEXT @PageSize ROWS ONLY OPTION(RECOMPILE);';
 
            EXEC sp_executesql @SqlWo,
                N'@GlobalFilter VARCHAR(50),@WorkOrderNum VARCHAR(50),@PartNumber VARCHAR(50),@PartDescription VARCHAR(50),
                  @CustomerName VARCHAR(50),@Stage VARCHAR(200),@WorkOrderStatusType VARCHAR(200),@CreatedBy VARCHAR(50),
                  @UpdatedBy VARCHAR(50),@CreatedDate DATETIME,@UpdatedDate DATETIME,@RecordFrom INT,@PageSize INT',
                @GlobalFilter,@WorkOrderNum,@PartNumber,@PartDescription,
                @CustomerName,@Stage,@WorkOrderStatusType,@CreatedBy,
                @UpdatedBy,@CreatedDate,@UpdatedDate,@RecordFrom,@PageSize;
        END
 
        IF OBJECT_ID('tempdb..#WorkOrderStatusFilter') IS NOT NULL DROP TABLE #WorkOrderStatusFilter;
        IF OBJECT_ID('tempdb..#WorkOrderStageFilter')  IS NOT NULL DROP TABLE #WorkOrderStageFilter;
        IF OBJECT_ID('tempdb..#WorkOrderData')         IS NOT NULL DROP TABLE #WorkOrderData;
        IF OBJECT_ID('tempdb..#BaseData')              IS NOT NULL DROP TABLE #BaseData;
 
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage  NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT            = ERROR_SEVERITY();
        DECLARE @ErrorState    INT            = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END