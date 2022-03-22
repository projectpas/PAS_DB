CREATE PROCEDURE [dbo].[usp_GetWorkOrderTracking] @Fromdate datetime,
@Todate datetime,
@Level1 varchar(max) = NULL,
@Level2 varchar(max) = NULL,
@Level3 varchar(max) = NULL,
@Level4 varchar(max) = NULL,
@mastercompanyid int
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION

      IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
      BEGIN
        DROP TABLE #ManagmetnStrcture
      END
      CREATE TABLE #ManagmetnStrcture (
        ID bigint NOT NULL IDENTITY,
        ManagementStructureId bigint NULL,
      )



       IF (ISNULL(@Level4, '0') != '0'
        AND ISNULL(@Level3, '0') != '0'
        AND ISNULL(@Level2, '0') != '0'
        AND ISNULL(@Level1, '0') != '0')
      BEGIN
        INSERT INTO #managmetnstrcture (managementstructureid)
          SELECT
            item
          FROM dbo.[Splitstring](@Level4, ',')
      END
      ELSE
      IF  (ISNULL(@Level3, '0') != '0'
        AND ISNULL(@Level2, '0') != '0'
        AND ISNULL(@Level1, '0') != '0')
      BEGIN
        INSERT INTO #managmetnstrcture (managementstructureid)
          SELECT
            item
          FROM dbo.[Splitstring](@Level3, ',')

      END
      ELSE
      IF (ISNULL(@Level2, '0') != '0'
        AND ISNULL(@Level1, '0') != '0')
      BEGIN
        INSERT INTO #managmetnstrcture (managementstructureid)
          SELECT
            item
          FROM dbo.[Splitstring](@Level2, ',')
      END
      ELSE
      IF ISNULL(@Level1, '0') != '0'
      BEGIN
        INSERT INTO #managmetnstrcture (managementstructureid)
          SELECT
            item
          FROM dbo.[Splitstring](@Level1, ',')
      END
      --select * FROM #ManagmetnStrcture
      SELECT DISTINCT
        CASE
          WHEN level4.Code + '-' + level4.Name IS NOT NULL AND
            level3.Code + '-' + level3.Name IS NOT NULL AND
            level2.Code + '-' + level2.Name IS NOT NULL AND
            level1.Code + '-' + level1.Name IS NOT NULL THEN level1.Code + '-' + level1.Name
          WHEN level4.Code + '-' + level4.Name IS NOT NULL AND
            level3.Code + '-' + level3.Name IS NOT NULL AND
            level2.Code + '-' + level2.Name IS NOT NULL THEN level2.Code + '-' + level2.Name
          WHEN level4.Code + '-' + level4.Name IS NOT NULL AND
            level3.Code + '-' + level3.Name IS NOT NULL THEN level3.Code + '-' + level3.Name
          WHEN level4.Code + '-' + level4.Name IS NOT NULL THEN level4.Code + '-' + level4.Name
          ELSE ''
        END AS LEVEL1,
        CASE
          WHEN level4.Code + '-' + level4.Name IS NOT NULL AND
            level3.Code + '-' + level3.Name IS NOT NULL AND
            level2.Code + '-' + level2.name IS NOT NULL AND
            level1.Code + '-' + level1.Name IS NOT NULL THEN level2.Code + '-' + level2.Name
          WHEN level4.Code + '-' + level4.Name IS NOT NULL AND
            level3.Code + '-' + level3.Name IS NOT NULL AND
            level2.Code + '-' + level2.Name IS NOT NULL THEN level3.Code + '-' + level3.Name
          WHEN level4.Code + '-' + level4.Name IS NOT NULL AND
            level3.Code + '-' + level3.Name IS NOT NULL THEN level4.Code + '-' + level4.Name
          ELSE ''
        END AS LEVEL2,
        CASE
          WHEN level4.Code + '-' + level4.Name IS NOT NULL AND
            level3.Code + '-' + level3.Name IS NOT NULL AND
            level2.Code + '-' + level2.Name IS NOT NULL AND
            level1.Code + '-' + level1.Name IS NOT NULL THEN level3.Code + '-' + level3.Name
          WHEN level4.Code + '-' + level4.Name IS NOT NULL AND
            level3.Code + '-' + level3.Name IS NOT NULL AND
            level2.Code + '-' + level2.Name IS NOT NULL THEN level4.Code + '-' + level4.Name
          ELSE ''
        END AS LEVEL3,
        CASE
          WHEN level4.Code + '-' + level4.Name IS NOT NULL AND
            level3.Code + '-' + level3.Name IS NOT NULL AND
            level2.Code + '-' + level2.Name IS NOT NULL AND
            level1.Code + '-' + level1.Name IS NOT NULL THEN level4.Code + '-' + level4.Name
          ELSE ''
        END AS LEVEL4,
        WO.WorkOrderNum 'WO Num',
        IM.partnumber 'PN',
        IM.PartDescription 'PN Description',
        C.Name 'Customer Name',
        WS.WorkScopeCode 'WorkScope',
        DATEDIFF(DAY, RCW.ReceivedDate, GETDATE()) AS 'WO Age (Days)',
        --                        'Days in Stage',
        concat(WOSG.code, '-', WOSG.stage) 'Stage Code',
        WOST.Description 'Status',
        MaterialRevenue + wqd.MaterialCost + MaterialRevenuePercentage +
        LaborCost + LaborRevenuePercentage + ChargesCost + WQD.FreightCost + wqd.OverheadCost 'Value',
        WorkOrderPriority.Description 'Priority',
        CONVERT(varchar, WOPN.ReceivedDate, 101) 'Received Date',
        CONVERT(varchar, woq.SentDate, 101) 'Quote Date',
        CONVERT(varchar, woq.ApprovedDate, 101) 'Quote Approved Date',
        CONVERT(varchar, WOPN.CustomerRequestDate, 101) 'Cust Req Date',
        CONVERT(varchar, WOPN.PromisedDate, 101) 'Promised Date',
        CONVERT(varchar, WOPN.EstimatedCompletionDate, 101) 'Est. Comp Date',
        CONVERT(varchar, WOPN.EstimatedShipDate, 101) 'Est Ship Date',
        CONVERT(varchar, GETDATE(), 101) 'Current Date',
        CASE
          WHEN WOS.ShipDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, WOPN.ReceivedDate) - DATEDIFF(DAY, ApprovedDate, SentDate) + DATEDIFF(DAY, WOS.ShipDate, ApprovedDate)
          WHEN ApprovedDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, WOPN.ReceivedDate) - DATEDIFF(DAY, ApprovedDate, SentDate) + DATEDIFF(DAY, WOS.ShipDate, ApprovedDate)
          WHEN SentDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, WOPN.ReceivedDate)
          WHEN WOPN.ReceivedDate IS NOT NULL THEN DATEDIFF(DAY, WOPN.ReceivedDate, GETDATE())
        END AS 'Current TAT',
        WOPN.TATDaysStandard 'Standard TAT',
        E.FirstName 'Tech Name',
        ES.StationName 'Tech Station',
        DATEDIFF(DAY, WOPN.CustomerRequestDate, GETDATE()) AS 'OTP',
        '?' 'TAT'
      FROM WorkOrderPartNumber WOPN WITH (NOLOCK)
      LEFT JOIN WorkOrder WO WITH (NOLOCK)
        ON WOPN.WorkOrderId = WO.WorkOrderId
        INNER JOIN WorkOrderQuote woq WITH (NOLOCK)
          ON WO.WorkOrderId = woq.WorkOrderId
        LEFT JOIN WorkOrderQuoteDetails wqd WITH (NOLOCK)
          ON woq.WorkOrderQuoteId = wqd.WorkOrderQuoteId
        LEFT JOIN WorkOrderType WITH (NOLOCK)
          ON WO.WorkOrderTypeId = WorkOrderType.Id
        LEFT JOIN WorkOrderPriority WITH (NOLOCK)
          ON WOPN.WorkOrderPriorityId = WorkOrderPriority.ID
        LEFT JOIN WorkScope AS WS WITH (NOLOCK)
          ON WOPN.WorkOrderScopeId = WS.WorkScopeId
        LEFT JOIN WorkOrderStatus WOST WITH (NOLOCK)
          ON WOPN.WorkOrderStatusId = WOST.Id
        LEFT JOIN WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
          ON WO.WorkOrderId = WOBI.WorkOrderId
        LEFT JOIN Customer C WITH (NOLOCK)
          ON WO.CustomerId = C.CustomerId
        LEFT JOIN Receivingcustomerwork RCW WITH (NOLOCK)
          ON WO.ReceivingCustomerWorkId = RCW.ReceivingCustomerWorkId
        LEFT JOIN ItemMaster IM WITH (NOLOCK)
          ON WOPN.ItemMasterId = im.ItemMasterId
        LEFT JOIN WorkOrderShipping AS WOS WITH (NOLOCK)
          ON WOS.WorkOrderId = WO.WorkOrderId
        LEFT JOIN WorkOrderStage WOSG WITH (NOLOCK)
          ON WOPN.WorkOrderStageId = WOSG.WorkOrderStageId
        LEFT JOIN EmployeeStation ES WITH (NOLOCK)
          ON wopn.TechStationId = ES.EmployeeStationId
        LEFT JOIN Employee E WITH (NOLOCK)
          ON WOPN.TechnicianId = E.EmployeeId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = WOPN.ManagementStructureId
        JOIN ManagementStructure level4 WITH (NOLOCK)
          ON WOPN.ManagementStructureId = level4.ManagementStructureId
        LEFT JOIN ManagementStructure level3 WITH (NOLOCK)
          ON level4.ParentId = level3.ManagementStructureId
        LEFT JOIN ManagementStructure level2 WITH (NOLOCK)
          ON level3.ParentId = level2.ManagementStructureId
        LEFT JOIN ManagementStructure level1 WITH (NOLOCK)
          ON level2.ParentId = level1.ManagementStructureId

      WHERE WOPN.ReceivedDate BETWEEN (@FromDate) AND (@ToDate)
	  and WOPN.MasterCompanyId =@mastercompanyid
    COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
    ROLLBACK TRANSACTION
    IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
    BEGIN
      DROP TABLE #managmetnstrcture
    END

    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetWorkOrderTracking]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
            '@Parameter6 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'

    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR (
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
    , 16
    , 1
    , @ErrorLogID
    )

    RETURN (1);

  END CATCH
  IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
  BEGIN
    DROP TABLE #managmetnstrcture
  END
END