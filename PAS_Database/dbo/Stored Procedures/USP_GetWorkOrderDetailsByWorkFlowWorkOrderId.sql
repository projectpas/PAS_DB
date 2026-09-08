/*************************************************************           
 ** File:   [USP_GetWorkOrderDetailsByWorkFlowWorkOrderId]        
 ** Author:  Ayushi Patel
 ** Description: This stored procedure is used to get WorkOrderDetails by WorkFlowWorkOrderId
 ** Purpose:         
 ** Date:   17/04/2025     
          
 ** PARAMETERS: @WorkFlowWorkOrderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
	1    17/04/2025  Ayushi Patel       Created
	2    03/09/2026  Ayushi Patel       [PN-16102]Added CustomerReference from WorkOrderPartNumber

************************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetWorkOrderDetailsByWorkFlowWorkOrderId]
    @WorkFlowWorkOrderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT TOP 1
			wo.WorkOrderNum,
			c.Name AS CustomerName,
			wopn.CustomerReference
		FROM dbo.WorkOrderWorkFlow wowf WITH (NOLOCK)
		INNER JOIN dbo.WorkOrder wo WITH (NOLOCK)  ON wowf.WorkOrderId = wo.WorkOrderId
		INNER JOIN dbo.Customer c WITH (NOLOCK)  ON wo.CustomerId = c.CustomerId
		LEFT JOIN dbo.WorkOrderPartNumber wopn WITH (NOLOCK) ON wopn.ID = wowf.WorkOrderPartNoId
		WHERE wowf.WorkFlowWorkOrderId = @WorkFlowWorkOrderId;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderDetailsByWorkFlowWorkOrderId' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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