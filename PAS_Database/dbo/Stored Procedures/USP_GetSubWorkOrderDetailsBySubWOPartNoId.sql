/*************************************************************           
 ** File:   [USP_GetSubWorkOrderDetailsBySubWOPartNoId]        
 ** Author:  Ayushi Patel
 ** Description: This stored procedure is used to get Sub WorkOrder details by SubWOPartNoId
 ** Purpose: To fetch SubWorkOrder number, WorkOrder number, and Customer name
 ** Date:   17/04/2025     
          
 ** PARAMETERS:  @SubWOPartNoId BIGINT
         
 ** RETURN VALUE: WorkOrderNum, SubWorkOrderNo, CustomerName           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		    Change Description            
 ** --   --------     -------		--------------------------------          
	1    17/04/2025  Ayushi Patel     Created
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetSubWorkOrderDetailsBySubWOPartNoId]
    @SubWOPartNoId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT TOP 1
            wo.WorkOrderNum,
            swo.SubWorkOrderNo,
            c.Name AS CustomerName
        FROM dbo.SubWorkOrderPartNumber sub WITH (NOLOCK)
        INNER JOIN dbo.SubWorkOrder swo WITH (NOLOCK) ON sub.SubWorkOrderId = swo.SubWorkOrderId
        INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) ON sub.WorkOrderId = wo.WorkOrderId
        INNER JOIN dbo.Customer c WITH (NOLOCK) ON wo.CustomerId = c.CustomerId
        WHERE sub.SubWOPartNoId = @SubWOPartNoId;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, 
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_GetSubWorkOrderDetailsBySubWOPartNoId',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ( 'Unexpected error occurred in the database. Please let the support team know of the error number: %d',16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END