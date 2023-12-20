
/*************************************************************           
 ** File:   [usp_GetTechProductivityReport]           
 ** Author:   Swetha  
 ** Description: Get Data for TechProductivity Report  
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
    1                 Swetha Created
	2	        	  Swetha Added Transaction & NO LOCK
     
EXECUTE   [dbo].[usp_GetTechProductivityReport] '','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetTechProductivityReport] @FirstName varchar(40) = NULL,
@Fromdate datetime,
@Todate datetime,
@mastercompanyid int,
@Level1 varchar(max) = NULL,
@Level2 varchar(max) = NULL,
@Level3 varchar(max) = NULL,
@Level4 varchar(max) = NULL
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
        E.FirstName + E.LastName 'Tech Name',
        ES.StationName 'Tech Station',
        WO.WorkOrderNum 'WO Num',
        '' as  'SO Num',
        WOBI.Invoiceno 'Inv Num',
        WOT.Description 'WO Type',
        IM.partnumber 'PN',
        IM.PartDescription 'PN Description',
        CONVERT(varchar, WO.OpenDate, 101) 'Open Date',
        WOS.code 'Stage Code',
        WOST.Description 'Status',
        WOL.hours 'Billable',
        WOL.Adjustments 'Non Billable',
        WOL.hours + WOL.Adjustments 'Total ',
        '?' 'H_Actual',
        '?' 'H_Target',
        '?' '% of Target',
        WOBI.MaterialValue + WOBI.LaborOverHeadValue + WOBI.MiscChargesValue 'Revenue',
        WOBI.MaterialCost + WOBI.LaborOverheadCost + WOBI.MiscChargesCost 'Total Direct Cost',
        ((WOBI.MaterialValue + WOBI.LaborOverHeadValue + WOBI.MiscChargesValue) - (WOBI.MaterialCost + WOBI.LaborOverheadCost + WOBI.MiscChargesCost)) 'Margin Amount',
        ((WOBI.MaterialValue + WOBI.LaborOverHeadValue + WOBI.MiscChargesValue) - (WOBI.MaterialCost + WOBI.LaborOverheadCost + WOBI.MiscChargesCost)) / NULLIF((WOBI.MaterialValue + WOBI.LaborOverHeadValue + WOBI.MiscChargesValue), 0) 'Margin %',
        '?' 'Employee Cost',
        '?' 'Actual',
        '?' 'Target',

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
        END
        AS
        LEVEL1,
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
        END
        AS
        LEVEL2,
        CASE
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL AND
            level1.code + '-' + level1.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
          ELSE ''
        END
        AS
        LEVEL3,
        CASE
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL AND
            level1.code + '-' + level1.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
          ELSE ''
        END
        AS
        LEVEL4
      FROM DBO.WorkOrder WO WITH (NOLOCK)
      LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
        ON WO.WorkOrderId = WOPN.WorkOrderId
        LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK)
          ON wo.WorkOrderId = woq.WorkOrderId
        LEFT JOIN DBO.WorkOrderType WOT WITH (NOLOCK)
          ON WO.WorkOrderTypeId = WOT.Id
        LEFT JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK)
          ON woq.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
        LEFT JOIN DBO.Employee E WITH (NOLOCK)
          ON WOPN.TechnicianId = E.EmployeeId
        LEFT JOIN DBO.WorkOrderStage WOS WITH (NOLOCK)
          ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId
        LEFT JOIN DBO.WorkOrderStatus WOST WITH (NOLOCK)
          ON WOPN.WorkOrderStatusId = WOST.Id
        LEFT JOIN DBO.WorkOrderLaborHeader WOLH WITH (NOLOCK)
          ON WO.WorkOrderId = WOLH.WorkOrderId
        LEFT JOIN DBO.WorkOrderLabor WOL WITH (NOLOCK)
          ON WOLH.WorkOrderLaborHeaderId = WOL.WorkOrderLaborHeaderId
        LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK)
          ON WOPN.ItemMasterId = IM.ItemMasterId
        LEFT JOIN DBO.customer C WITH (NOLOCK)
          ON WO.CustomerId = C.CustomerId
        --LEFT JOIN DBO.SalesOrder SO WITH (NOLOCK)
        --  ON C.CustomerId = SO.CustomerId
        LEFT JOIN DBO.EmployeeStation ES WITH (NOLOCK)
          ON wopn.TechStationId = ES.EmployeeStationId
        LEFT JOIN DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
          ON WO.WorkOrderId = WOBI.WorkOrderId and wobi.IsVersionIncrease=0
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
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

      WHERE E.firstname IN (@FirstName)
      OR @FirstName = ' '
      AND WOPN.closeddate BETWEEN (@Fromdate) AND (@Todate) and WOPN.IsClosed =1
      AND WOPN.mastercompanyid = @mastercompanyid

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
            @AdhocComments varchar(150) = '[usp_GetTechProductivityReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@firstname, '') AS varchar(100)) +
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