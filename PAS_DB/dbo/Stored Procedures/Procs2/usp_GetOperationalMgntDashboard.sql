----------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [usp_GetOperationalMgntDashboard]           
 ** Author:   Swetha  
 ** Description: Get Data for OperationalMgntDashboard 
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
     
EXECUTE   [dbo].[usp_GetOperationalMgntDashboard] 
**************************************************************/

CREATE PROCEDURE [dbo].[usp_GetOperationalMgntDashboard]
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION
      SELECT DISTINCT
        IG.description AS ItemGroup,
        STUFF((SELECT
          ', ' + CC.Description
        FROM dbo.ClassificationMapping cm
        INNER JOIN dbo.CustomerClassification CC WITH (NOLOCK)
          ON CC.CustomerClassificationId = CM.ClasificationId
        WHERE cm.ReferenceId = C.CustomerId
        FOR xml PATH ('')), 1, 1, '') 'CustomerClassification',
        C.name AS Customer,
        RCW.quantity,
        IM.partnumber AS Units,
        RO.repairorderid AS Ros,
        WOPN.NTE AS EstHrs,
        WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount AS EstAmt,
        RCW.receiveddate,
        RCW.Level1,
        RCW.level2,
        RCW.Level3,
        RCW.Level4
      FROM DBO.ReceivingCustomerWork RCW WITH (NOLOCK)
      LEFT OUTER JOIN DBO.Customer C WITH (NOLOCK)
        ON RCW.CustomerId = C.CustomerId
        LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK)
          ON RCW.ItemMasterId = IM.ItemMasterId
        LEFT JOIN DBO.ItemGroup IG WITH (NOLOCK)
          ON IM.ItemGroupId = IG.ItemGroupId
        LEFT JOIN DBO.Workorder WO WITH (NOLOCK)
          ON RCW.workorderid = WO.workorderid
        LEFT JOIN DBO.Workorderpartnumber WOPN WITH (NOLOCK)
          ON WO.WorkOrderId = WOPN.WorkOrderId
        LEFT OUTER JOIN DBO.Repairorderpart ROP WITH (NOLOCK)
          ON WO.workorderid = ROP.workorderid AND ROP.ItemTypeId=1
        LEFT OUTER JOIN DBO.RepairOrder RO WITH (NOLOCK)
          ON ROP.repairorderid = RO.repairorderid
        LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK)
          ON wo.WorkOrderId = woq.WorkOrderId
        LEFT JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK)
          ON woq.WorkOrderQuoteId = WOQD.WorkOrderQuoteId

    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetOperationalMgntDashboard]',
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