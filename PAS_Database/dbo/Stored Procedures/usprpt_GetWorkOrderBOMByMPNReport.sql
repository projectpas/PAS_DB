
/*************************************************************
 ** File:   [usprpt_GetWorkOrderBOMByMPNReport]
 ** Author: Hemant
 ** Description: [PN-18384] Bill of Material (BOM) by MPN - one row per BOM component
 **              (WorkOrderMaterials + WorkOrderMaterialsKit) of a Work Order MPN that has
 **              been Invoiced. Registered as Reports > Work Order Reports > Bill of Material (BOM) by MPN.
 ** Date:   21/October/2026
 ** PARAMETERS: @PageNumber, @PageSize, @mastercompanyid, @xmlFilter
 **             (Filters: "From Invoice Date", "To Invoice Date", "MPN", "Customer", "Work Scope",
 **              Level1-10 Management Structure, grid column filters "columnFilter_<field>"),
 **             @SortColumn, @SortOrder
 ** RETURN VALUE: paged result set, one row per BOM component line
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date               Author    Change Description
 ** --   --------           -------   ---------------------------
    1    21/October/2026    Hemant    [PN-18384] Created.
    2    22/October/2026    Hemant    [PN-18384] Added WO MPN (woMPN) column after WO Num.
    3    22/October/2026    Hemant    [PN-18384] Column filter / sort on Management Structure level1-10.
    4    22/October/2026    Hemant    [PN-18384] Open / Invoice / Shipped Date column filters use a date picker (yyyy-MM-dd).
 **************************************************************
 EXEC usprpt_GetWorkOrderBOMByMPNReport @PageNumber=1,@PageSize=100,@mastercompanyid=1,@xmlFilter='<ArrayOfFilter><Filter><FieldName>From Invoice Date</FieldName><FieldValue>9/1/2026</FieldValue></Filter><Filter><FieldName>To Invoice Date</FieldName><FieldValue>10/21/2026</FieldValue></Filter></ArrayOfFilter>'
**************************************************************/
CREATE   PROCEDURE [dbo].[usprpt_GetWorkOrderBOMByMPNReport]
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

  DECLARE @FromInvoiceDate VARCHAR(MAX) = NULL,
    @ToInvoiceDate VARCHAR(MAX) = NULL,
    @MPN VARCHAR(MAX) = NULL,
    @Customer VARCHAR(MAX) = NULL,
    @WorkScope VARCHAR(MAX) = NULL,
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
      @FromInvoiceDate = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'From Invoice Date' THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @FromInvoiceDate END,
      @ToInvoiceDate   = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'To Invoice Date'   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @ToInvoiceDate END,
      @MPN             = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'MPN'               THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @MPN END,
      @Customer        = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Customer'          THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Customer END,
      @WorkScope       = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)') = 'Work Scope'        THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @WorkScope END,
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

    -- Grid column-level filters, sent by the report screen as 'columnFilter_<fieldName>' (contains match)
    DECLARE @ColumnFilters TABLE (FieldName VARCHAR(100), FieldValue VARCHAR(500));
    INSERT INTO @ColumnFilters (FieldName, FieldValue)
    SELECT REPLACE(filterby.value('(FieldName/text())[1]','VARCHAR(100)'), 'columnFilter_', ''),
           LTRIM(RTRIM(filterby.value('(FieldValue/text())[1]','VARCHAR(500)')))
    FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE(filterby)
    WHERE filterby.value('(FieldName/text())[1]','VARCHAR(100)') LIKE 'columnFilter[_]%'
      AND ISNULL(LTRIM(RTRIM(filterby.value('(FieldValue/text())[1]','VARCHAR(500)'))),'') <> '';

    DECLARE @FromInvoiceDt DATE = TRY_CONVERT(DATE, @FromInvoiceDate, 101);
    DECLARE @ToInvoiceDt DATE = TRY_CONVERT(DATE, @ToInvoiceDate, 101);

    DECLARE @MSModuleID INT, @WOModuleId INT, @SubModuleId INT;
    SELECT @MSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH (NOLOCK) WHERE UPPER([ModuleName]) = 'WORKORDERMPN';
    SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'WorkOrder';
    SELECT @SubModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN';

    SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END
    DECLARE @EffectivePageSize INT = ISNULL(NULLIF(@PageSize,0), 2147483647);

    ;WITH BOMCTE AS (
      SELECT
        WO.WorkOrderNum AS woNum,
        WOIM.partnumber AS woMPN,
        IM.partnumber AS bomPN,
        CASE WHEN IM.IsPma = 1 THEN 'PMA' ELSE 'OEM' END AS oemPma,
        IM.PartDescription AS pnDescription,
        C.Code AS cond,
        ISNULL(BOM.Quantity,0) AS qty,
        CAST(ISNULL(BOM.UnitCost,0) AS DECIMAL(18,2)) AS unitcost,
        CAST(ISNULL(BOM.Quantity,0) * ISNULL(BOM.UnitCost,0) AS DECIMAL(18,2)) AS extCost,
        UPPER(WOPN.WorkScope) AS workScope,
        UPPER(CU.[Name]) AS customer,
        UPPER(WTG.Stage) AS stage,
        CAST(WO.OpenDate AS DATE) AS opendate,
        CAST(INV.InvoiceDate AS DATE) AS invoicedate,
        CAST(SHIP.ShipDate AS DATE) AS shipdate,

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

      FROM dbo.WorkOrder WO WITH (NOLOCK)

      INNER JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK)
        ON WOPN.WorkOrderId = WO.WorkOrderId

      -- WO MPN (the part being worked on)
      INNER JOIN dbo.ItemMaster WOIM WITH (NOLOCK)
        ON WOIM.ItemMasterId = WOPN.RevisedItemMasterId

      INNER JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK)
        ON WOWF.WorkOrderPartNoId = WOPN.ID

      -- BOM components: WO materials + kit materials of the MPN's workflow
      INNER JOIN (
        SELECT WOM.WorkFlowWorkOrderId, WOM.ItemMasterId, WOM.ConditionCodeId, WOM.Quantity, WOM.UnitCost
        FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)
        WHERE WOM.IsActive = 1 AND ISNULL(WOM.IsDeleted,0) = 0
        UNION ALL
        SELECT WOMK.WorkFlowWorkOrderId, WOMK.ItemMasterId, WOMK.ConditionCodeId, WOMK.Quantity, WOMK.UnitCost
        FROM dbo.WorkOrderMaterialsKit WOMK WITH (NOLOCK)
        WHERE WOMK.IsActive = 1 AND ISNULL(WOMK.IsDeleted,0) = 0
      ) BOM
        ON BOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId

      INNER JOIN dbo.ItemMaster IM WITH (NOLOCK)
        ON IM.ItemMasterId = BOM.ItemMasterId

      -- Invoiced records only: latest 'Invoiced' (non-proforma, current version) invoice date of the MPN.
      -- CROSS APPLY + MAX keeps one row per BOM line even when the MPN has more than one invoice.
      CROSS APPLY
      (
        SELECT MAX(BI.InvoiceDate) AS InvoiceDate
        FROM dbo.BillingInvoicing BI WITH (NOLOCK)
        INNER JOIN dbo.BillingInvoicingItems BII WITH (NOLOCK)
          ON BII.BillingInvoicingId = BI.BillingInvoicingId
         AND ISNULL(BII.IsVersionIncrease,0) = 0
         AND ISNULL(BII.IsPerformaInvoice,0) = 0
         AND BII.SubModuleId = @SubModuleId
        WHERE BI.ModuleId = @WOModuleId
          AND BI.ReferenceId = WO.WorkOrderId
          AND BII.SubReferenceId = WOPN.ID
          AND BI.InvoiceStatus = 'Invoiced'
          AND ISNULL(BI.IsVersionIncrease,0) = 0
      ) INV

      INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK)
        ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = WOPN.ID

      LEFT JOIN dbo.Condition C WITH (NOLOCK)
        ON C.ConditionId = BOM.ConditionCodeId

      LEFT JOIN dbo.Customer CU WITH (NOLOCK)
        ON CU.CustomerId = WO.CustomerId

      LEFT JOIN dbo.WorkOrderStage WTG WITH (NOLOCK)
        ON WTG.WorkOrderStageId = WOPN.WorkOrderStageId

      -- Latest ship date of the MPN (one row per MPN, no duplicate report rows)
      OUTER APPLY
      (
        SELECT MAX(WOS.ShipDate) AS ShipDate
        FROM dbo.WorkOrderShippingItem WOSI WITH (NOLOCK)
        INNER JOIN dbo.WorkOrderShipping WOS WITH (NOLOCK)
          ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId
        WHERE WOSI.WorkOrderPartNumId = WOPN.ID
          AND WOSI.IsActive = 1 AND ISNULL(WOSI.IsDeleted,0) = 0
          AND WOS.IsActive = 1 AND ISNULL(WOS.IsDeleted,0) = 0
      ) SHIP

      WHERE WO.MasterCompanyId = @mastercompanyid
        AND ISNULL(WO.IsDeleted,0) = 0
        AND INV.InvoiceDate IS NOT NULL
        AND (@FromInvoiceDt IS NULL OR CAST(INV.InvoiceDate AS DATE) >= @FromInvoiceDt)
        AND (@ToInvoiceDt IS NULL OR CAST(INV.InvoiceDate AS DATE) <= @ToInvoiceDt)
        AND (ISNULL(@MPN,'') = '' OR WOPN.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@MPN,',')))
        AND (ISNULL(@Customer,'') = '' OR WO.CustomerId IN (SELECT Item FROM DBO.SPLITSTRING(@Customer,',')))
        AND (ISNULL(@WorkScope,'') = '' OR WOPN.WorkOrderScopeId IN (SELECT Item FROM DBO.SPLITSTRING(@WorkScope,',')))
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
      B.woNum,
      B.woMPN,
      B.bomPN,
      B.oemPma,
      B.pnDescription,
      B.cond,
      B.qty,
      B.unitcost,
      B.extCost,
      B.workScope,
      B.customer,
      B.stage,
      B.opendate,
      B.invoicedate,
      B.shipdate,
      B.level1,
      B.level2,
      B.level3,
      B.level4,
      B.level5,
      B.level6,
      B.level7,
      B.level8,
      B.level9,
      B.level10
    FROM BOMCTE B
    -- Column-level filters: keep the row only when every entered column filter matches its column
    WHERE NOT EXISTS (
      SELECT 1
      FROM @ColumnFilters F
      WHERE NOT EXISTS (
        SELECT 1
        FROM (VALUES
          ('woNum', B.woNum), ('woMPN', B.woMPN), ('bomPN', B.bomPN), ('oemPma', B.oemPma), ('pnDescription', B.pnDescription),
          ('cond', B.cond), ('qty', CAST(B.qty AS VARCHAR(50))), ('unitcost', CAST(B.unitcost AS VARCHAR(50))),
          ('extCost', CAST(B.extCost AS VARCHAR(50))), ('workScope', B.workScope), ('customer', B.customer),
          -- date columns: the grid's date picker sends yyyy-MM-dd
          ('stage', B.stage), ('opendate', CONVERT(VARCHAR(10), B.opendate, 23)),
          ('invoicedate', CONVERT(VARCHAR(10), B.invoicedate, 23)), ('shipdate', CONVERT(VARCHAR(10), B.shipdate, 23)),
          ('level1', B.level1), ('level2', B.level2), ('level3', B.level3), ('level4', B.level4), ('level5', B.level5),
          ('level6', B.level6), ('level7', B.level7), ('level8', B.level8), ('level9', B.level9), ('level10', B.level10)
        ) V(FieldName, FieldValue)
        WHERE V.FieldName = F.FieldName
          AND V.FieldValue LIKE '%' + F.FieldValue + '%'
      )
    )
    ORDER BY
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'woNum')         THEN B.woNum END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'woNum')         THEN B.woNum END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'woMPN')         THEN B.woMPN END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'woMPN')         THEN B.woMPN END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'bomPN')         THEN B.bomPN END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'bomPN')         THEN B.bomPN END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'oemPma')        THEN B.oemPma END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'oemPma')        THEN B.oemPma END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'pnDescription') THEN B.pnDescription END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'pnDescription') THEN B.pnDescription END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'cond')          THEN B.cond END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'cond')          THEN B.cond END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'qty')           THEN B.qty END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'qty')           THEN B.qty END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'unitcost')      THEN B.unitcost END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'unitcost')      THEN B.unitcost END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'extCost')       THEN B.extCost END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'extCost')       THEN B.extCost END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'workScope')     THEN B.workScope END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'workScope')     THEN B.workScope END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'customer')      THEN B.customer END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'customer')      THEN B.customer END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'stage')         THEN B.stage END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'stage')         THEN B.stage END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'opendate')      THEN B.opendate END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'opendate')      THEN B.opendate END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'invoicedate')   THEN B.invoicedate END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'invoicedate')   THEN B.invoicedate END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'shipdate')      THEN B.shipdate END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'shipdate')      THEN B.shipdate END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level1')      THEN B.level1 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level1')      THEN B.level1 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level2')      THEN B.level2 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level2')      THEN B.level2 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level3')      THEN B.level3 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level3')      THEN B.level3 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level4')      THEN B.level4 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level4')      THEN B.level4 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level5')      THEN B.level5 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level5')      THEN B.level5 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level6')      THEN B.level6 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level6')      THEN B.level6 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level7')      THEN B.level7 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level7')      THEN B.level7 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level8')      THEN B.level8 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level8')      THEN B.level8 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level9')      THEN B.level9 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level9')      THEN B.level9 END DESC,
      CASE WHEN (@SortOrder = 1  AND @SortColumn = 'level10')     THEN B.level10 END ASC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level10')     THEN B.level10 END DESC,
      B.invoicedate DESC, B.woNum, B.bomPN
    OFFSET ((@PageNumber - 1) * @EffectivePageSize) ROWS
    FETCH NEXT @EffectivePageSize ROWS ONLY;

  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID INT,
      @DatabaseName VARCHAR(100) = DB_NAME()
      -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
      ,@AdhocComments VARCHAR(150) = '[usprpt_GetWorkOrderBOMByMPNReport]'
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
