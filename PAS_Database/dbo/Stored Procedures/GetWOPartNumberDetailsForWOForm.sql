/*************************************************************           
 ** File:   [GetWOPartNumberDetailsForWOForm]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get WO Part Number Details For WO Form Details
 ** Purpose:         
 ** Date:   12-03-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    12-03-2025    Sahdev Saliya       Created  

**************************************************************/  
create   PROCEDURE [dbo].[GetWOPartNumberDetailsForWOForm]
@workOrderPartNoId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY

    SELECT TOP 1
        wp.ID AS workOrderPartNoId,
        ISNULL(wop.PickTicketId, 0) AS PickTicketId,
        ISNULL(wps.PackagingSlipId, 0) AS PackagingSlipId,
        ISNULL(CONVERT(VARCHAR, wp.WOFPrintDate, 120), '') AS WOFPrintDate,
        CASE WHEN sw.SubWorkOrderId IS NOT NULL THEN 1 ELSE 0 END AS isSubWO,
        CASE WHEN swf.SubWorkOrderId IS NOT NULL THEN 1 ELSE 0 END AS isSub8130,
        ISNULL(wp.IsFinishGood, 0) AS isFinishGood
    FROM [dbo].WorkOrderPartNumber wp WITH(NOLOCK)
    LEFT JOIN [dbo].WOPickTicket wop WITH(NOLOCK) ON wp.ID = wop.OrderPartId
    LEFT JOIN [dbo].WorkOrderPackaginSlipItems wps WITH(NOLOCK) ON wop.PickTicketId = wps.WOPickTicketId AND wop.OrderPartId = wps.WOPartNoId
    LEFT JOIN [dbo].SubWorkOrder sw WITH(NOLOCK) ON wp.WorkOrderId = sw.WorkOrderId AND wp.ID = sw.WorkOrderPartNumberId
    LEFT JOIN [dbo].SubWorkOrder_ReleaseFrom_8130 swf WITH(NOLOCK) ON sw.SubWorkOrderId = swf.SubWorkOrderId
    WHERE wp.ID = @workOrderPartNoId;

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWOPartNumberDetailsForWOForm' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@workOrderPartNoId, '') AS VARCHAR(250))
												
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH    
END