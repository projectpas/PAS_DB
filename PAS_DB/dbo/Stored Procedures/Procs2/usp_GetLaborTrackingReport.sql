/*************************************************************           
 ** File:   [usp_GetLaborTrackingReport]           
 ** Author:   Swetha  
 ** Description: Get Data for LaborTracking Report 
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author    Change Description            
 ** --   --------     -------    --------------------------------          
    1                 Swetha Created
    2				  Swetha Added Transaction & NO LOCK
	3	01/31/2024    Devendra Shekh	added isperforma Flage for WO
     
EXECUTE   [dbo].[usp_GetLaborTrackingReport] '','2019-04-25','2021-07-25','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetLaborTrackingReport] @itemmasterid varchar(40) = NULL,
@Fromdate datetime,
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
        DROP TABLE #managmetnstrcture
      END

      CREATE TABLE #managmetnstrcture (
        id bigint NOT NULL IDENTITY,
        managementstructureid bigint NULL,
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

      SELECT DISTINCT
        CASE
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL AND
            level1.code + '-' + level1.NAME IS NOT NULL THEN level1.code + '-' + level1.NAME
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL THEN level2.code + '-' + level2.NAME
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
          WHEN level4.code + '-' + level4.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
          ELSE ''
        END AS LEVEL1,
        CASE
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL AND
            level1.code + '-' + level1.NAME IS NOT NULL THEN level2.code + '-' + level2.NAME
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
          ELSE ''
        END AS LEVEL2,
        CASE
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL AND
            level1.code + '-' + level1.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
          ELSE ''
        END AS LEVEL3,
        CASE
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL AND
            level1.code + '-' + level1.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
          ELSE ''
        END AS LEVEL4,
        WO.workordernum 'WO Num',
        CONVERT(varchar, WO.OpenDate, 101) 'Open Date',
        WS.workscopecode 'Work Scope',
        (IM.partnumber) 'PN',
        (IM.partdescription) 'PN Description',
        Task.description 'Task',
        RCW.ReceivedDate 'Received Date',
        WOQ.sentDate 'Quote Date',
        WOQ.approveddate 'Approved Date',
        WOS.ShipDate 'Shipped Date ',
        --Datediff(day,WOQ.approveddate,WOS.ShipDate)+Datediff(day,WOQ.sentDate,RCW.ReceivedDate)  'Actual',
        --WOPN.TATDaysStandard 'Standard',
        SUM(WOL.Adjustments) 'Adj',
        SUM(WOL.AdjustedHours) 'Adj Hrs',
        SUM(WOL.Hours) 'Hours',
        EMPEXP.description 'Technician',
        WorkOrderStage.code + '-' + WorkOrderStage.Stage 'Stage Code',
        WOST.Description 'Status',
        SUM(WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount) 'Quote Revenue',
        SUM(WOMPN.ActualRevenue) 'Inv Rev',
        WOBI.invoiceno 'Inv No'
      FROM DBO.WorkOrderLaborHeader WOLH WITH (NOLOCK)
      LEFT JOIN DBO.WorkOrderLabor WOL WITH (NOLOCK)
        ON WOLH.WorkOrderLaborHeaderId = WOL.WorkOrderLaborHeaderId
        LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK)
          ON WOLH.WorkOrderId = WO.WorkOrderId
        JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK)
          ON WOLH.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId
        JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK)
          ON wowf.WorkOrderId = WOPN.WorkOrderId
        LEFT JOIN DBO.WorkOrderMPNCostDetails WOMPN WITH (NOLOCK)
          ON WO.WorkOrderId = WOMPN.WorkOrderId
        LEFT JOIN DBO.WorkOrderStage WITH (NOLOCK)
          ON WOPN.WorkOrderStageId = WorkOrderStage.WorkOrderStageId
        LEFT JOIN DBO.WorkScope AS WS WITH (NOLOCK)
          ON WOPN.WorkOrderScopeId = WS.WorkScopeId
        LEFT JOIN DBO.WorkOrderStatus WOST WITH (NOLOCK)
          ON WOPN.WorkOrderStatusId = WOST.Id
        LEFT JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK)
          ON WO.WorkOrderId = WOQ.WorkOrderId
        LEFT JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK)
          ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
        LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK)
          ON WOPN.ItemMasterId = im.ItemMasterId
        INNER JOIN DBO.Task WITH (NOLOCK)
          ON WOL.taskid = task.taskid
        LEFT JOIN DBO.EmployeeExpertise EMPEXP WITH (NOLOCK)
          ON WOL.ExpertiseId = EMPEXP.EmployeeExpertiseId
        LEFT JOIN DBO.Receivingcustomerwork RCW WITH (NOLOCK)
          ON WO.WorkOrderId = RCW.WorkOrderId
        LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK)
          ON WOS.WorkOrderId = WO.WorkOrderId
        LEFT JOIN DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
          ON WO.WorkOrderId = WOBI.WorkOrderId
        LEFT OUTER JOIN mastercompany MC WITH (NOLOCK)
          ON WOPN.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = WOPN.ManagementStructureId
        JOIN DBO.ManagementStructure level4 WITH (NOLOCK)
          ON WOPN.ManagementStructureId = level4.ManagementStructureId
        LEFT JOIN DBO.ManagementStructure level3 WITH (NOLOCK)
          ON level4.ParentId = level3.ManagementStructureId
        LEFT JOIN DBO.ManagementStructure level2 WITH (NOLOCK)
          ON level3.ParentId = level2.ManagementStructureId
        LEFT JOIN DBO.ManagementStructure level1 WITH (NOLOCK)
          ON level2.ParentId = level1.ManagementStructureId

      WHERE im.partnumber IN (@itemmasterid)
      OR @itemmasterid = ' '
      AND WO.opendate BETWEEN (@Fromdate) AND (@Todate)
      AND WOPN.mastercompanyid = @mastercompanyid
	  AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0
      GROUP BY workordernum,
               im.partnumber,
               wost.description,
               WOBI.invoiceno,
               workorderstage.code + '-'
               + workorderstage.stage,
               WOST.description,
               (IM.partdescription),
               task.description,
               RCW.receiveddate,
               WOQ.sentdate,
               WOQ.approveddate,
               WOS.shipdate,
               CONVERT(varchar, WO.opendate, 101),
               WS.workscopecode,
               EMPEXP.description,
               CASE
                 WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
                   level3.code + '-' + level3.NAME IS NOT NULL AND
                   level2.code + '-' + level2.NAME IS NOT NULL AND
                   level1.code + '-' + level1.NAME IS NOT NULL THEN level1.code + '-' + level1.NAME
                 WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
                   level3.code + '-' + level3.NAME IS NOT NULL AND
                   level2.code + '-' + level2.NAME IS NOT NULL THEN level2.code + '-' + level2.NAME
                 WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
                   level3.code + '-' + level3.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
                 WHEN level4.code + '-' + level4.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
                 ELSE ''
               END,
               CASE
                 WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
                   level3.code + '-' + level3.NAME IS NOT NULL AND
                   level2.code + '-' + level2.NAME IS NOT NULL AND
                   level1.code + '-' + level1.NAME IS NOT NULL THEN level2.code + '-' + level2.NAME
                 WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
                   level3.code + '-' + level3.NAME IS NOT NULL AND
                   level2.code + '-' + level2.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
                 WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
                   level3.code + '-' + level3.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
                 ELSE ''
               END,
               CASE
                 WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
                   level3.code + '-' + level3.NAME IS NOT NULL AND
                   level2.code + '-' + level2.NAME IS NOT NULL AND
                   level1.code + '-' + level1.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
                 WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
                   level3.code + '-' + level3.NAME IS NOT NULL AND
                   level2.code + '-' + level2.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
                 ELSE ''
               END,
               CASE
                 WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
                   level3.code + '-' + level3.NAME IS NOT NULL AND
                   level2.code + '-' + level2.NAME IS NOT NULL AND
                   level1.code + '-' + level1.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
                 ELSE ''
               END

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
            @AdhocComments varchar(150) = '[usp_GetLaborTrackingReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@itemmasterid, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
            '@Parameter6 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
            '@Parameter7 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +
            '@Parameter8 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'

    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

    RETURN (1);
  END CATCH

  IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
  BEGIN
    DROP TABLE #managmetnstrcture
  END
END