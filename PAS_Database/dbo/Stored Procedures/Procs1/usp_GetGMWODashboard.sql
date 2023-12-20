/*************************************************************           
 ** File:   [usp_GetGMWODashboard]           
 ** Author:   Swetha  
 ** Description: Get Data for GMWODashboard 
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
     
EXECUTE   [dbo].[usp_GetGMWODashboard] 
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetGMWODashboard]
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION
      SELECT
        C.Name AS Customers,
        WOBI.GrandTotal AS MROBilling,
        WOC.margin AS MROGM,
        '?' AS Manufacturer,
        '?' AS Other,
        IG.Description AS ItemGroup,
        IM.partnumber AS Part,
        IM.PartDescription,
        WOPN.Quantity,
        WOBI.invoicedate 'MRO DATE',
        WOS.Stage AS Stages,
        WOS.code AS 'Stage Code',
        WO.WorkOrderId AS WO,
        STL.unitsalesprice AS WO_Value
      FROM dbo.WorkOrderBillingInvoicing AS WOBI WITH (NOLOCK)
      LEFT JOIN dbo.WorkOrder AS wo WITH (NOLOCK)
        ON WOBI.WorkOrderId = wo.WorkOrderId
        INNER JOIN dbo.Customer AS C WITH (NOLOCK)
          ON WOBI.CustomerId = C.CustomerId
        INNER JOIN dbo.WorkOrderPartNumber AS WOPN WITH (NOLOCK)
          ON WOBI.WorkOrderId = WOPN.workorderid
        INNER JOIN dbo.WorkOrderStage WOS WITH (NOLOCK)
          ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId
        LEFT JOIN dbo.WorkOrderStatus WOST WITH (NOLOCK)
          ON WOPN.WorkOrderStatusId = WOST.Id
        INNER JOIN dbo.Stockline AS STL WITH (NOLOCK)
          ON WO.WorkOrderId = STL.WorkOrderId
        LEFT JOIN WorkOrderMPNCostDetails WOC WITH (NOLOCK)
          ON WO.WorkOrderId = WOC.WorkOrderId
        INNER JOIN dbo.ItemMaster AS IM WITH (NOLOCK)
          ON WOBI.itemmasterId = IM.ItemMasterId
        LEFT JOIN dbo.ItemGroup AS IG WITH (NOLOCK)
          ON IM.ItemGroupId = IG.ItemGroupId
    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[usp_GetGMWODashboard]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''',
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
END