/*************************************************************           
 ** File:   [usp_GetMainWODashboardsample]           
 ** Author:   Swetha  
 ** Description: Get Data for MainWODashboard sample 
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
     
EXECUTE   [dbo].[usp_GetMainWODashboardsample] 
**************************************************************/

CREATE PROCEDURE [dbo].[usp_GetMainWODashboardsample]
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION

      SELECT
        C.Name AS Customers,
        IG.Description AS ItemGroup,
        IM.partnumber AS Part,
        (WOPN.EstimatedShipDate) 'MRO DATE',
        (WOMPN.revenue) 'Revenue',
        (WOPN.Quantity),
        STUFF((SELECT
          ', ' + CC.Description
        FROM dbo.ClassificationMapping cm
        INNER JOIN dbo.CustomerClassification CC WITH (NOLOCK)
          ON CC.CustomerClassificationId = CM.ClasificationId
        WHERE cm.ReferenceId = C.CustomerId
        FOR xml PATH ('')), 1, 1, '') 'CustomerClassification',
        WOS.stage 'BACKLOG',
        WOST.status 'STATUS'
      FROM dbo.WorkOrder AS WO WITH (NOLOCK)
      LEFT JOIN dbo.Customer AS C WITH (NOLOCK)
        ON WO.CustomerId = C.CustomerId
        LEFT JOIN dbo.WorkOrderPartNumber AS WOPN WITH (NOLOCK)
          ON WO.WorkOrderId = WOPN.WorkOrderId
        LEFT JOIN dbo.WorkOrderMPNCostDetails WOMPN WITH (NOLOCK)
          ON WO.WorkOrderId = WOMPN.WorkOrderId
        LEFT JOIN dbo.WorkOrderStage WOS WITH (NOLOCK)
          ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId
        LEFT JOIN dbo.WorkOrderStatus WOST WITH (NOLOCK)
          ON WOPN.WorkOrderStatusId = WOST.Id
        LEFT JOIN dbo.ItemMaster AS IM WITH (NOLOCK)
          ON WOPN.itemmasterId = IM.ItemMasterId
        LEFT JOIN dbo.ItemGroup AS IG WITH (NOLOCK)
          ON IM.ItemGroupId = IG.ItemGroupId

    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetMainWODashboardsample]',
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