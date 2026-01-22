
/*************************************************************           
 ** File:   [usp_GetWorkOrderBacklogReport]           
 ** Author:   Swetha  
 ** Description: Get Data for WorkOrderBacklog Report
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
    1					Swetha		Created
	2	        		Swetha		Added Transaction & NO LOCK
	3	30-Nov-2021		Hemant		Updated Managment Structure Details and Date filter Condition
     
EXECUTE   [dbo].[usp_GetWorkOrderBacklogReport] 'WO Opened','','','','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetWorkOrderBacklogReport] @stage varchar(40) = NULL,
@description varchar(40) = NULL,
@Fromdate datetime = NULL,
@Todate datetime = NULL,
@mastercompanyid varchar(200),
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
        UPPER(WOPN.Level1) AS LEVEL1,
		UPPER(WOPN.Level2) AS LEVEL2,
		UPPER(WOPN.Level3) AS LEVEL3,
		UPPER(WOPN.Level4) AS LEVEL4,
        UPPER(IM.partnumber) 'MPN',
        UPPER(IM.PartDescription) 'MPN Description',
        UPPER(WO.WorkOrderNum) 'WO Num',
        UPPER(RCW.serialnumber) 'Serial Num',
        UPPER(WOT.Description) 'WO Type',
        UPPER(s.Stage) 'Stage',
        UPPER(st.Description) 'Status',
        WOPN.ReceivedDate 'ReceivedDate',
        WO.OpenDate 'Open Date',
        STL.purchaseorderunitcost ' Original Value',
        WOC.partscost 'Parts Added',
        WOC.LaborCost 'Labor',
        WOC.OverHeadCost 'Overhead',
        WOC.ChargesCost + WOC.FreightCost 'Misc Charge',
        WOC.OtherCost 'Other',
        (STL.PurchaseOrderUnitCost + WOC.PartsCost + WOC.LaborCost + WOC.OverHeadCost + WOC.OtherCost) 'Total',
        'N/A' 'Transferred Out',
        'N/A' 'Transferred to WO',
        'N/A' 'Transferred to Inventory',
        (STL.PurchaseOrderUnitCost + WOC.PartsCost + WOC.LaborCost + WOC.OverHeadCost + WOC.OtherCost) 'NetWIP',
        DATEDIFF(DAY, RCW.ReceivedDate, GETDATE()) AS 'WO Age (Days)',
        UPPER(E.FirstName + ' ' + E.LastName) 'Tech Name'
      FROM DBO.WorkOrder WO WITH (NOLOCK)
      LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
        ON WO.WorkOrderId = WOPN.WorkOrderId
        LEFT JOIN DBO.WorkOrderStage s WITH (NOLOCK)
          ON WOPN.WorkOrderStageId = s.WorkOrderStageId
        LEFT JOIN DBO.WorkOrderStatus st WITH (NOLOCK)
          ON WOPN.WorkOrderStatusId = ST.Id
        LEFT JOIN DBO.WorkOrderType WOT WITH (NOLOCK)
          ON WO.WorkOrderTypeId = WOT.Id
        JOIN DBO.WorkOrderMPNCostDetails WOC WITH (NOLOCK)
          ON WOPN.ID = WOC.WOPartNoId
        LEFT JOIN DBO.ReceivingCustomerWork RCW WITH (NOLOCK)
          ON WO.ReceivingCustomerWorkId = RCW.ReceivingCustomerWorkId
        LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK)
          ON WOPN.itemmasterId = IM.itemmasterid
        LEFT JOIN DBO.Stockline STL WITH (NOLOCK)
          ON WOPN.StockLineId = STL.StockLineId and stl.IsParent=1
        LEFT JOIN DBO.Employee E WITH (NOLOCK)
          ON WOPN.TechnicianId = E.EmployeeId
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON WO.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = WOPN.ManagementStructureId

      WHERE (WOT.Description IN (@description) OR @description = ' ')
      AND (s.stage IN (@stage) OR @stage = ' ')
      AND CAST(WO.opendate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)
      AND WO.mastercompanyid = @mastercompanyid

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
            @AdhocComments varchar(150) = '[usp_GetWorkOrderBacklogReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@stage, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
            '@Parameter6 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
            '@Parameter7 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +
            '@Parameter8 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +
            '@Parameter8 = ''' + CAST(ISNULL(@description, '') AS varchar),
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