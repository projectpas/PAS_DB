/*************************************************************
 ** File:   [usprpt_GetDocumentExpirationReport]
 ** Author: SAHDEV SALIYA
 ** Description: Document Expiration Report - documents from all modules (CommonDocumentDetails) with their
 **              expiration details, one row per attached file (AttachmentDetails).
 **              Registered as ReportMaster ModuleId 74 (Reports > Other Reports > Document Expiration Report).
 ** RETURN VALUE: paged result set, one row per document file
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date               Author          Change Description
 ** --   --------           -------         ---------------------------
    1    26/Oct/2026    SAHDEV SALIYA       Created.
 **************************************************************
 EXEC usprpt_GetDocumentExpirationReport @PageNumber=1,@PageSize=100,@mastercompanyid=1,@xmlFilter='<ArrayOfFilter><Filter><FieldName>columnFilter_daysToExpiration</FieldName><FieldValue>&lt;30</FieldValue></Filter></ArrayOfFilter>'
**************************************************************/
CREATE    PROCEDURE [dbo].[usprpt_GetDocumentExpirationReport]
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

  DECLARE @ModuleIds VARCHAR(MAX) = NULL,
    @DocumentTypeIds VARCHAR(MAX) = NULL,
    @DocumentName VARCHAR(200) = NULL,
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
      @ModuleIds       = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Module Name'   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(MAX)') ELSE @ModuleIds END,
      @DocumentTypeIds = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Document Type' THEN filterby.value('(FieldValue/text())[1]','VARCHAR(MAX)') ELSE @DocumentTypeIds END,
      @DocumentName    = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Document Name' THEN filterby.value('(FieldValue/text())[1]','VARCHAR(200)') ELSE @DocumentName END,
      @Level1  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level1'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(MAX)') ELSE @Level1 END,
      @Level2  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level2'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(MAX)') ELSE @Level2 END,
      @Level3  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level3'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(MAX)') ELSE @Level3 END,
      @Level4  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level4'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(MAX)') ELSE @Level4 END,
      @Level5  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level5'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(MAX)') ELSE @Level5 END,
      @Level6  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level6'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(MAX)') ELSE @Level6 END,
      @Level7  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level7'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(MAX)') ELSE @Level7 END,
      @Level8  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level8'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(MAX)') ELSE @Level8 END,
      @Level9  = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level9'  THEN filterby.value('(FieldValue/text())[1]','VARCHAR(MAX)') ELSE @Level9 END,
      @Level10 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Level10' THEN filterby.value('(FieldValue/text())[1]','VARCHAR(MAX)') ELSE @Level10 END
    FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE(filterby)

    SET @DocumentName = NULLIF(LTRIM(RTRIM(@DocumentName)), '');

    -- Grid column-level filters, sent by the report screen as 'columnFilter_<fieldName>'
    DECLARE @ColumnFilters TABLE (FieldName VARCHAR(100), FieldValue VARCHAR(500));
    INSERT INTO @ColumnFilters (FieldName, FieldValue)
    SELECT REPLACE(filterby.value('(FieldName/text())[1]','VARCHAR(100)'), 'columnFilter_', ''),
           LTRIM(RTRIM(filterby.value('(FieldValue/text())[1]','VARCHAR(500)')))
    FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE(filterby)
    WHERE filterby.value('(FieldName/text())[1]','VARCHAR(100)') LIKE 'columnFilter[_]%'
      AND ISNULL(LTRIM(RTRIM(filterby.value('(FieldValue/text())[1]','VARCHAR(500)'))),'') <> '';

    -- Date column filters: 'yyyy-MM-dd' = that day, 'from~to' = inclusive range
    DECLARE @FromSubmitted DATE, @ToSubmitted DATE, @FromModified DATE, @ToModified DATE, @FromExpiration DATE, @ToExpiration DATE;
    SELECT
      @FromSubmitted  = CASE WHEN F.FieldName = 'submittedDate'  THEN R.FromDt ELSE @FromSubmitted END,
      @ToSubmitted    = CASE WHEN F.FieldName = 'submittedDate'  THEN R.ToDt   ELSE @ToSubmitted END,
      @FromModified   = CASE WHEN F.FieldName = 'modifiedDate'   THEN R.FromDt ELSE @FromModified END,
      @ToModified     = CASE WHEN F.FieldName = 'modifiedDate'   THEN R.ToDt   ELSE @ToModified END,
      @FromExpiration = CASE WHEN F.FieldName = 'expirationDate' THEN R.FromDt ELSE @FromExpiration END,
      @ToExpiration   = CASE WHEN F.FieldName = 'expirationDate' THEN R.ToDt   ELSE @ToExpiration END
    FROM @ColumnFilters F
    CROSS APPLY (SELECT CHARINDEX('~', F.FieldValue) AS Pos) P
    CROSS APPLY (SELECT TRY_CONVERT(DATE, CASE WHEN P.Pos = 0 THEN F.FieldValue ELSE NULLIF(LEFT(F.FieldValue, P.Pos - 1), '') END, 23) AS FromDt,
                        TRY_CONVERT(DATE, CASE WHEN P.Pos = 0 THEN F.FieldValue ELSE NULLIF(SUBSTRING(F.FieldValue, P.Pos + 1, 20), '') END, 23) AS ToDt) R
    WHERE F.FieldName IN ('submittedDate', 'modifiedDate', 'expirationDate');

    -- Days to Expiration filter: optional operator + number
    DECLARE @DaysOperator VARCHAR(2), @DaysValue INT, @DaysFilter VARCHAR(500);
    SELECT @DaysFilter = REPLACE(FieldValue, ' ', '') FROM @ColumnFilters WHERE FieldName = 'daysToExpiration';
    IF @DaysFilter IS NOT NULL
    BEGIN
      SET @DaysOperator = CASE WHEN LEFT(@DaysFilter, 2) IN ('<=', '>=') THEN LEFT(@DaysFilter, 2)
                               WHEN LEFT(@DaysFilter, 1) IN ('<', '>', '=') THEN LEFT(@DaysFilter, 1)
                               ELSE '=' END;
      SET @DaysValue = TRY_CONVERT(INT, CASE WHEN LEFT(@DaysFilter, 1) IN ('<', '>', '=') THEN SUBSTRING(@DaysFilter, LEN(@DaysOperator) + 1, 20) ELSE @DaysFilter END);
      IF @DaysValue IS NULL SET @DaysOperator = NULL;
    END

    DELETE FROM @ColumnFilters WHERE FieldName IN ('submittedDate', 'modifiedDate', 'expirationDate', 'daysToExpiration');

    DECLARE @IsMSFilter BIT = CASE WHEN CONCAT(@Level1, @Level2, @Level3, @Level4, @Level5, @Level6, @Level7, @Level8, @Level9, @Level10) <> '' THEN 1 ELSE 0 END;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END
    DECLARE @EffectivePageSize INT = ISNULL(NULLIF(@PageSize,0), 2147483647);

    /* ---------- 1. Documents matching the header filters ---------- */
    IF OBJECT_ID('tempdb..#Docs') IS NOT NULL DROP TABLE #Docs;
    CREATE TABLE #Docs (
      RowId BIGINT IDENTITY(1,1) PRIMARY KEY,
      CommonDocumentDetailId BIGINT,
      AttachmentModuleName VARCHAR(100),
      ModuleName VARCHAR(100),
      ReferenceId BIGINT,
      Reference VARCHAR(200),
      DocumentType VARCHAR(50),
      DocumentName VARCHAR(500),
      SubmittedDate DATE,
      ModifiedDate DATE,
      ExpirationDate DATE,
      DaysToExpiration INT,
      DocumentLink VARCHAR(500),
      FileName VARCHAR(500),
      MSSource VARCHAR(10),       -- which *ManagementStructureDetails table holds the parent record's MS
      MSModuleId INT,
      MSReferenceId BIGINT,
      Level1Id BIGINT, Level2Id BIGINT, Level3Id BIGINT, Level4Id BIGINT, Level5Id BIGINT,
      Level6Id BIGINT, Level7Id BIGINT, Level8Id BIGINT, Level9Id BIGINT, Level10Id BIGINT,
      Level1 VARCHAR(200), Level2 VARCHAR(200), Level3 VARCHAR(200), Level4 VARCHAR(200), Level5 VARCHAR(200),
      Level6 VARCHAR(200), Level7 VARCHAR(200), Level8 VARCHAR(200), Level9 VARCHAR(200), Level10 VARCHAR(200)
    );

    INSERT INTO #Docs (CommonDocumentDetailId, AttachmentModuleName, ModuleName, ReferenceId, Reference, DocumentType, DocumentName,
                       SubmittedDate, ModifiedDate, ExpirationDate, DaysToExpiration, DocumentLink, FileName)
    SELECT CDD.CommonDocumentDetailId,
           DMN.[Name],
           DMN.ModuleName,
           CDD.ReferenceId,
           CAST(CDD.ReferenceId AS VARCHAR(200)),   -- replaced by the business reference below where the module is known
           DT.[Name],
           ISNULL(NULLIF(CDD.DocName, ''), AD.[FileName]),
           CAST(CDD.CreatedDate AS DATE),
           CAST(CDD.UpdatedDate AS DATE),
           CAST(CDD.ExpirationDate AS DATE),
           DATEDIFF(DAY, @Today, CAST(CDD.ExpirationDate AS DATE)),
           AD.Link,
           AD.[FileName]
    FROM dbo.CommonDocumentDetails CDD WITH (NOLOCK)
    INNER JOIN dbo.vw_DocumentModuleName DMN ON DMN.AttachmentModuleId = CDD.ModuleId
    LEFT JOIN dbo.DocumentType DT WITH (NOLOCK) ON DT.DocumentTypeId = CDD.DocumentTypeId
    LEFT JOIN dbo.AttachmentDetails AD WITH (NOLOCK) ON AD.AttachmentId = CDD.AttachmentId AND ISNULL(AD.IsActive, 1) = 1 AND ISNULL(AD.IsDeleted, 0) = 0
    WHERE CDD.MasterCompanyId = @mastercompanyid
      AND CDD.IsActive = 1
      AND CDD.IsDeleted = 0
      AND (ISNULL(@ModuleIds,'') = '' OR CDD.ModuleId IN (SELECT Item FROM DBO.SPLITSTRING(@ModuleIds,',')))
      AND (ISNULL(@DocumentTypeIds,'') = '' OR CDD.DocumentTypeId IN (SELECT Item FROM DBO.SPLITSTRING(@DocumentTypeIds,',')))
      AND (@DocumentName IS NULL OR ISNULL(NULLIF(CDD.DocName, ''), AD.[FileName]) LIKE '%' + @DocumentName + '%');

    /* ---------- 2. Business reference and management structure source, per module ---------- */
    DECLARE @MS_WOMPN INT, @MS_SO INT, @MS_SOQ INT, @MS_PO INT, @MS_RO INT, @MS_RFQPO INT, @MS_RFQRO INT,
            @MS_ESO INT, @MS_EXQ INT, @MS_STK INT, @MS_EMP INT, @MS_PUB INT;
    SELECT @MS_WOMPN = MAX(CASE WHEN UPPER(ModuleName) = 'WORKORDERMPN'      THEN ManagementStructureModuleId END),
           @MS_SO    = MAX(CASE WHEN UPPER(ModuleName) = 'SALESORDER'        THEN ManagementStructureModuleId END),
           @MS_SOQ   = MAX(CASE WHEN UPPER(ModuleName) = 'SALESORDERQUOTE'   THEN ManagementStructureModuleId END),
           @MS_PO    = MAX(CASE WHEN UPPER(ModuleName) = 'POHEADER'          THEN ManagementStructureModuleId END),
           @MS_RO    = MAX(CASE WHEN UPPER(ModuleName) = 'ROHEADER'          THEN ManagementStructureModuleId END),
           @MS_RFQPO = MAX(CASE WHEN UPPER(ModuleName) = 'VENDORRFQPOHEADER' THEN ManagementStructureModuleId END),
           @MS_RFQRO = MAX(CASE WHEN UPPER(ModuleName) = 'VENDORRFQROHEADER' THEN ManagementStructureModuleId END),
           @MS_ESO   = MAX(CASE WHEN UPPER(ModuleName) = 'EXCHANGESOHEADER'  THEN ManagementStructureModuleId END),
           @MS_EXQ   = MAX(CASE WHEN UPPER(ModuleName) = 'EXCHANGEQUOTEHEADER' THEN ManagementStructureModuleId END),
           @MS_STK   = MAX(CASE WHEN UPPER(ModuleName) = 'STOCKLINE'         THEN ManagementStructureModuleId END),
           @MS_EMP   = MAX(CASE WHEN UPPER(ModuleName) = 'EMPLOYEEGENERALINFO' THEN ManagementStructureModuleId END),
           @MS_PUB   = MAX(CASE WHEN UPPER(ModuleName) = 'PUBLICATIONHEADER' THEN ManagementStructureModuleId END)
    FROM dbo.ManagementStructureModule WITH (NOLOCK);

    -- Work Order: ReferenceId = WorkOrderWorkFlow.WorkFlowWorkOrderId; MS is on the WO MPN
    UPDATE D SET Reference = WO.WorkOrderNum, MSSource = 'WO', MSModuleId = @MS_WOMPN, MSReferenceId = WOWF.WorkOrderPartNoId
    FROM #Docs D
    INNER JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = D.ReferenceId
    INNER JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOWF.WorkOrderId
    WHERE D.AttachmentModuleName = 'WorkOrder';

    -- Sub Work Order: ReferenceId = SubWorkOrderPartNumber.SubWOPartNoId; MS is the parent WO MPN's
    UPDATE D SET Reference = SWO.SubWorkOrderNo, MSSource = 'WO', MSModuleId = @MS_WOMPN, MSReferenceId = SWO.WorkOrderPartNumberId
    FROM #Docs D
    INNER JOIN dbo.SubWorkOrderPartNumber SWOP WITH (NOLOCK) ON SWOP.SubWOPartNoId = D.ReferenceId
    INNER JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.SubWorkOrderId = SWOP.SubWorkOrderId
    WHERE D.AttachmentModuleName = 'SubWorkOrder';

    UPDATE D SET Reference = WOQ.QuoteNumber
    FROM #Docs D INNER JOIN dbo.WorkOrderQuote WOQ WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'WorkOrderQuote';

    UPDATE D SET Reference = SO.SalesOrderNumber, MSSource = 'SO', MSModuleId = @MS_SO, MSReferenceId = SO.SalesOrderId
    FROM #Docs D INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'SalesOrder';

    UPDATE D SET Reference = SOQ.SalesOrderQuoteNumber, MSSource = 'SO', MSModuleId = @MS_SOQ, MSReferenceId = SOQ.SalesOrderQuoteId
    FROM #Docs D INNER JOIN dbo.SalesOrderQuote SOQ WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'SalesQuote';

    UPDATE D SET Reference = SQ.SpeedQuoteNumber
    FROM #Docs D INNER JOIN dbo.SpeedQuote SQ WITH (NOLOCK) ON SQ.SpeedQuoteId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'SpeedQuote';

    UPDATE D SET Reference = PO.PurchaseOrderNumber, MSSource = 'PO', MSModuleId = @MS_PO, MSReferenceId = PO.PurchaseOrderId
    FROM #Docs D INNER JOIN dbo.PurchaseOrder PO WITH (NOLOCK) ON PO.PurchaseOrderId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'PurchaseOrder';

    UPDATE D SET Reference = RO.RepairOrderNumber, MSSource = 'RO', MSModuleId = @MS_RO, MSReferenceId = RO.RepairOrderId
    FROM #Docs D INNER JOIN dbo.RepairOrder RO WITH (NOLOCK) ON RO.RepairOrderId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'RepairOrder';

    UPDATE D SET Reference = RFQ.VendorRFQPurchaseOrderNumber, MSSource = 'PO', MSModuleId = @MS_RFQPO, MSReferenceId = RFQ.VendorRFQPurchaseOrderId
    FROM #Docs D INNER JOIN dbo.VendorRFQPurchaseOrder RFQ WITH (NOLOCK) ON RFQ.VendorRFQPurchaseOrderId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'VendorRFQPurchaseOrder';

    UPDATE D SET Reference = RFQ.VendorRFQRepairOrderNumber, MSSource = 'RO', MSModuleId = @MS_RFQRO, MSReferenceId = RFQ.VendorRFQRepairOrderId
    FROM #Docs D INNER JOIN dbo.VendorRFQRepairOrder RFQ WITH (NOLOCK) ON RFQ.VendorRFQRepairOrderId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'VendorRFQRepairOrder';

    UPDATE D SET Reference = ESO.ExchangeSalesOrderNumber, MSSource = 'EX', MSModuleId = @MS_ESO, MSReferenceId = ESO.ExchangeSalesOrderId
    FROM #Docs D INNER JOIN dbo.ExchangeSalesOrder ESO WITH (NOLOCK) ON ESO.ExchangeSalesOrderId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'ExchangeSalesOrder';

    UPDATE D SET Reference = EQ.ExchangeQuoteNumber, MSSource = 'EX', MSModuleId = @MS_EXQ, MSReferenceId = EQ.ExchangeQuoteId
    FROM #Docs D INNER JOIN dbo.ExchangeQuote EQ WITH (NOLOCK) ON EQ.ExchangeQuoteId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'ExchangeQuote';

    UPDATE D SET Reference = STL.StockLineNumber, MSSource = 'STK', MSModuleId = @MS_STK, MSReferenceId = STL.StockLineId
    FROM #Docs D INNER JOIN dbo.Stockline STL WITH (NOLOCK) ON STL.StockLineId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'StockLine';

    UPDATE D SET Reference = VRMA.RMANumber
    FROM #Docs D INNER JOIN dbo.VendorRMA VRMA WITH (NOLOCK) ON VRMA.VendorRMAId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'VendorRMA';

    UPDATE D SET Reference = PUB.PublicationId, MSSource = 'PUB', MSModuleId = @MS_PUB, MSReferenceId = PUB.PublicationRecordId
    FROM #Docs D INNER JOIN dbo.Publication PUB WITH (NOLOCK) ON PUB.PublicationRecordId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'Publication';

    UPDATE D SET Reference = LTRIM(RTRIM(CONCAT(EMP.FirstName, ' ', EMP.LastName))), MSSource = 'EMP', MSModuleId = @MS_EMP, MSReferenceId = EMP.EmployeeId
    FROM #Docs D INNER JOIN dbo.Employee EMP WITH (NOLOCK) ON EMP.EmployeeId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'Employee';

    -- Master data without a management structure
    UPDATE D SET Reference = CU.[Name]
    FROM #Docs D INNER JOIN dbo.Customer CU WITH (NOLOCK) ON CU.CustomerId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'Customer';

    UPDATE D SET Reference = V.VendorName
    FROM #Docs D INNER JOIN dbo.Vendor V WITH (NOLOCK) ON V.VendorId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'Vendor';

    UPDATE D SET Reference = LE.[Name]
    FROM #Docs D INNER JOIN dbo.LegalEntity LE WITH (NOLOCK) ON LE.LegalEntityId = D.ReferenceId
    WHERE D.AttachmentModuleName = 'LegalEntity';

    /* ---------- 3. Management structure levels ---------- */
    IF OBJECT_ID('tempdb..#DocMS') IS NOT NULL DROP TABLE #DocMS;
    CREATE TABLE #DocMS (
      RowId BIGINT,
      Level1Id BIGINT, Level2Id BIGINT, Level3Id BIGINT, Level4Id BIGINT, Level5Id BIGINT,
      Level6Id BIGINT, Level7Id BIGINT, Level8Id BIGINT, Level9Id BIGINT, Level10Id BIGINT,
      Level1 VARCHAR(200), Level2 VARCHAR(200), Level3 VARCHAR(200), Level4 VARCHAR(200), Level5 VARCHAR(200),
      Level6 VARCHAR(200), Level7 VARCHAR(200), Level8 VARCHAR(200), Level9 VARCHAR(200), Level10 VARCHAR(200)
    );

    INSERT INTO #DocMS
    SELECT D.RowId, M.Level1Id, M.Level2Id, M.Level3Id, M.Level4Id, M.Level5Id, M.Level6Id, M.Level7Id, M.Level8Id, M.Level9Id, M.Level10Id,
           M.Level1Name, M.Level2Name, M.Level3Name, M.Level4Name, M.Level5Name, M.Level6Name, M.Level7Name, M.Level8Name, M.Level9Name, M.Level10Name
    FROM #Docs D INNER JOIN dbo.WorkOrderManagementStructureDetails M WITH (NOLOCK) ON M.ModuleID = D.MSModuleId AND M.ReferenceID = D.MSReferenceId
    WHERE D.MSSource = 'WO';

    INSERT INTO #DocMS
    SELECT D.RowId, M.Level1Id, M.Level2Id, M.Level3Id, M.Level4Id, M.Level5Id, M.Level6Id, M.Level7Id, M.Level8Id, M.Level9Id, M.Level10Id,
           M.Level1Name, M.Level2Name, M.Level3Name, M.Level4Name, M.Level5Name, M.Level6Name, M.Level7Name, M.Level8Name, M.Level9Name, M.Level10Name
    FROM #Docs D INNER JOIN dbo.SalesOrderManagementStructureDetails M WITH (NOLOCK) ON M.ModuleID = D.MSModuleId AND M.ReferenceID = D.MSReferenceId
    WHERE D.MSSource = 'SO';

    INSERT INTO #DocMS
    SELECT D.RowId, M.Level1Id, M.Level2Id, M.Level3Id, M.Level4Id, M.Level5Id, M.Level6Id, M.Level7Id, M.Level8Id, M.Level9Id, M.Level10Id,
           M.Level1Name, M.Level2Name, M.Level3Name, M.Level4Name, M.Level5Name, M.Level6Name, M.Level7Name, M.Level8Name, M.Level9Name, M.Level10Name
    FROM #Docs D INNER JOIN dbo.PurchaseOrderManagementStructureDetails M WITH (NOLOCK) ON M.ModuleID = D.MSModuleId AND M.ReferenceID = D.MSReferenceId
    WHERE D.MSSource = 'PO';

    INSERT INTO #DocMS
    SELECT D.RowId, M.Level1Id, M.Level2Id, M.Level3Id, M.Level4Id, M.Level5Id, M.Level6Id, M.Level7Id, M.Level8Id, M.Level9Id, M.Level10Id,
           M.Level1Name, M.Level2Name, M.Level3Name, M.Level4Name, M.Level5Name, M.Level6Name, M.Level7Name, M.Level8Name, M.Level9Name, M.Level10Name
    FROM #Docs D INNER JOIN dbo.RepairOrderManagementStructureDetails M WITH (NOLOCK) ON M.ModuleID = D.MSModuleId AND M.ReferenceID = D.MSReferenceId
    WHERE D.MSSource = 'RO';

    INSERT INTO #DocMS
    SELECT D.RowId, M.Level1Id, M.Level2Id, M.Level3Id, M.Level4Id, M.Level5Id, M.Level6Id, M.Level7Id, M.Level8Id, M.Level9Id, M.Level10Id,
           M.Level1Name, M.Level2Name, M.Level3Name, M.Level4Name, M.Level5Name, M.Level6Name, M.Level7Name, M.Level8Name, M.Level9Name, M.Level10Name
    FROM #Docs D INNER JOIN dbo.ExchangeManagementStructureDetails M WITH (NOLOCK) ON M.ModuleID = D.MSModuleId AND M.ReferenceID = D.MSReferenceId
    WHERE D.MSSource = 'EX';

    INSERT INTO #DocMS
    SELECT D.RowId, M.Level1Id, M.Level2Id, M.Level3Id, M.Level4Id, M.Level5Id, M.Level6Id, M.Level7Id, M.Level8Id, M.Level9Id, M.Level10Id,
           M.Level1Name, M.Level2Name, M.Level3Name, M.Level4Name, M.Level5Name, M.Level6Name, M.Level7Name, M.Level8Name, M.Level9Name, M.Level10Name
    FROM #Docs D INNER JOIN dbo.StocklineManagementStructureDetails M WITH (NOLOCK) ON M.ModuleID = D.MSModuleId AND M.ReferenceID = D.MSReferenceId
    WHERE D.MSSource = 'STK';

    INSERT INTO #DocMS
    SELECT D.RowId, M.Level1Id, M.Level2Id, M.Level3Id, M.Level4Id, M.Level5Id, M.Level6Id, M.Level7Id, M.Level8Id, M.Level9Id, M.Level10Id,
           M.Level1Name, M.Level2Name, M.Level3Name, M.Level4Name, M.Level5Name, M.Level6Name, M.Level7Name, M.Level8Name, M.Level9Name, M.Level10Name
    FROM #Docs D INNER JOIN dbo.EmployeeManagementStructureDetails M WITH (NOLOCK) ON M.ModuleID = D.MSModuleId AND M.ReferenceID = D.MSReferenceId
    WHERE D.MSSource = 'EMP';

    -- Publication MS rows are keyed on PublicationRecordId
    INSERT INTO #DocMS
    SELECT D.RowId, M.Level1Id, M.Level2Id, M.Level3Id, M.Level4Id, M.Level5Id, M.Level6Id, M.Level7Id, M.Level8Id, M.Level9Id, M.Level10Id,
           M.Level1Name, M.Level2Name, M.Level3Name, M.Level4Name, M.Level5Name, M.Level6Name, M.Level7Name, M.Level8Name, M.Level9Name, M.Level10Name
    FROM #Docs D INNER JOIN dbo.PublicationManagementStructureDetails M WITH (NOLOCK) ON M.ModuleID = D.MSModuleId AND M.PublicationRecordId = D.MSReferenceId
    WHERE D.MSSource = 'PUB';

    UPDATE D
    SET Level1Id = M.Level1Id, Level2Id = M.Level2Id, Level3Id = M.Level3Id, Level4Id = M.Level4Id, Level5Id = M.Level5Id,
        Level6Id = M.Level6Id, Level7Id = M.Level7Id, Level8Id = M.Level8Id, Level9Id = M.Level9Id, Level10Id = M.Level10Id,
        Level1 = UPPER(M.Level1), Level2 = UPPER(M.Level2), Level3 = UPPER(M.Level3), Level4 = UPPER(M.Level4), Level5 = UPPER(M.Level5),
        Level6 = UPPER(M.Level6), Level7 = UPPER(M.Level7), Level8 = UPPER(M.Level8), Level9 = UPPER(M.Level9), Level10 = UPPER(M.Level10)
    FROM #Docs D
    INNER JOIN #DocMS M ON M.RowId = D.RowId;

    -- Management structure header filter. Documents with no management structure drop out once a level is chosen.
    IF @IsMSFilter = 1
    BEGIN
      DELETE FROM #Docs
      WHERE Level1Id IS NULL
         OR (ISNULL(@Level1,'')  <> '' AND Level1Id  NOT IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
         OR (ISNULL(@Level2,'')  <> '' AND ISNULL(Level2Id, 0)  NOT IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
         OR (ISNULL(@Level3,'')  <> '' AND ISNULL(Level3Id, 0)  NOT IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
         OR (ISNULL(@Level4,'')  <> '' AND ISNULL(Level4Id, 0)  NOT IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
         OR (ISNULL(@Level5,'')  <> '' AND ISNULL(Level5Id, 0)  NOT IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
         OR (ISNULL(@Level6,'')  <> '' AND ISNULL(Level6Id, 0)  NOT IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
         OR (ISNULL(@Level7,'')  <> '' AND ISNULL(Level7Id, 0)  NOT IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
         OR (ISNULL(@Level8,'')  <> '' AND ISNULL(Level8Id, 0)  NOT IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
         OR (ISNULL(@Level9,'')  <> '' AND ISNULL(Level9Id, 0)  NOT IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
         OR (ISNULL(@Level10,'') <> '' AND ISNULL(Level10Id, 0) NOT IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')));
    END

    /* ---------- 4. Grid filters, sort and paging ---------- */
    SELECT
      COUNT(1) OVER () AS TotalRecordsCount,
      D.ModuleName AS moduleName,
      D.Reference AS reference,
      D.DocumentType AS documentType,
      D.DocumentName AS documentName,
      D.CommonDocumentDetailId AS docReference,
      D.SubmittedDate AS submittedDate,
      D.ModifiedDate AS modifiedDate,
      D.ExpirationDate AS expirationDate,
      D.DaysToExpiration AS daysToExpiration,
      D.DocumentLink AS documentLink,
      D.FileName AS fileName,
      D.Level1 AS level1,
      D.Level2 AS level2,
      D.Level3 AS level3,
      D.Level4 AS level4,
      D.Level5 AS level5,
      D.Level6 AS level6,
      D.Level7 AS level7,
      D.Level8 AS level8,
      D.Level9 AS level9,
      D.Level10 AS level10
    FROM #Docs D
    WHERE (@FromSubmitted  IS NULL OR D.SubmittedDate  >= @FromSubmitted)
      AND (@ToSubmitted    IS NULL OR D.SubmittedDate  <= @ToSubmitted)
      AND (@FromModified   IS NULL OR D.ModifiedDate   >= @FromModified)
      AND (@ToModified     IS NULL OR D.ModifiedDate   <= @ToModified)
      AND (@FromExpiration IS NULL OR D.ExpirationDate >= @FromExpiration)
      AND (@ToExpiration   IS NULL OR D.ExpirationDate <= @ToExpiration)
      -- documents without an expiration date drop out whenever the days filter is set
      AND (@DaysOperator IS NULL OR 1 = CASE @DaysOperator
                                          WHEN '<'  THEN CASE WHEN D.DaysToExpiration <  @DaysValue THEN 1 END
                                          WHEN '<=' THEN CASE WHEN D.DaysToExpiration <= @DaysValue THEN 1 END
                                          WHEN '='  THEN CASE WHEN D.DaysToExpiration =  @DaysValue THEN 1 END
                                          WHEN '>=' THEN CASE WHEN D.DaysToExpiration >= @DaysValue THEN 1 END
                                          WHEN '>'  THEN CASE WHEN D.DaysToExpiration >  @DaysValue THEN 1 END
                                        END)
      -- Text column filters: keep the row only when every entered column filter matches its column
      AND NOT EXISTS (
        SELECT 1
        FROM @ColumnFilters F
        WHERE NOT EXISTS (
          SELECT 1
          FROM (VALUES
            ('moduleName', D.ModuleName), ('reference', D.Reference), ('documentType', D.DocumentType),
            ('documentName', D.DocumentName), ('docReference', CAST(D.CommonDocumentDetailId AS VARCHAR(50))),
            ('documentLink', D.FileName),
            ('level1', D.Level1), ('level2', D.Level2), ('level3', D.Level3), ('level4', D.Level4), ('level5', D.Level5),
            ('level6', D.Level6), ('level7', D.Level7), ('level8', D.Level8), ('level9', D.Level9), ('level10', D.Level10)
          ) V(FieldName, FieldValue)
          WHERE V.FieldName = F.FieldName
            AND V.FieldValue LIKE '%' + F.FieldValue + '%'
        )
      )
    ORDER BY
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'moduleName')       THEN D.ModuleName END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'moduleName')       THEN D.ModuleName END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'reference')        THEN D.Reference END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'reference')        THEN D.Reference END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'documentType')     THEN D.DocumentType END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'documentType')     THEN D.DocumentType END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'documentName')     THEN D.DocumentName END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'documentName')     THEN D.DocumentName END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'docReference')     THEN D.CommonDocumentDetailId END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'docReference')     THEN D.CommonDocumentDetailId END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'submittedDate')    THEN D.SubmittedDate END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'submittedDate')    THEN D.SubmittedDate END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'modifiedDate')     THEN D.ModifiedDate END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'modifiedDate')     THEN D.ModifiedDate END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'expirationDate')   THEN D.ExpirationDate END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'expirationDate')   THEN D.ExpirationDate END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'daysToExpiration') THEN D.DaysToExpiration END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'daysToExpiration') THEN D.DaysToExpiration END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'documentLink')     THEN D.FileName END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'documentLink')     THEN D.FileName END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level1')  THEN D.Level1 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level1')  THEN D.Level1 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level2')  THEN D.Level2 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level2')  THEN D.Level2 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level3')  THEN D.Level3 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level3')  THEN D.Level3 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level4')  THEN D.Level4 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level4')  THEN D.Level4 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level5')  THEN D.Level5 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level5')  THEN D.Level5 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level6')  THEN D.Level6 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level6')  THEN D.Level6 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level7')  THEN D.Level7 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level7')  THEN D.Level7 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level8')  THEN D.Level8 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level8')  THEN D.Level8 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level9')  THEN D.Level9 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level9')  THEN D.Level9 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level10') THEN D.Level10 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level10') THEN D.Level10 END DESC,
      -- Default: most urgent first, documents without an expiration date last
      CASE WHEN D.ExpirationDate IS NULL THEN 1 ELSE 0 END, D.ExpirationDate, D.ModuleName, D.Reference, D.RowId
    OFFSET ((@PageNumber - 1) * @EffectivePageSize) ROWS
    FETCH NEXT @EffectivePageSize ROWS ONLY;

  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID INT,
      @DatabaseName VARCHAR(100) = DB_NAME()
      -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
      ,@AdhocComments VARCHAR(150) = '[usprpt_GetDocumentExpirationReport]'
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