/*************************************************************
 ** File:   [USP_GetSWOTaskLaborByWOTaskId]
 ** Author: Vishal Suthar
 ** Description: This stored procedure is used to get SWO Task Instruction by SWO Task Id
 ** Purpose:
 ** Date:   03/28/2025
    
 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    03/28/2025   Vishal Suthar		Created

EXEC [dbo].[USP_GetSWOTaskLaborByWOTaskId] 57
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSWOTaskLaborByWOTaskId]
	@SubWorkOrderTaskId bigint = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT 
		STRING_AGG(EE.[Description], ',') AS Expretise,
		SUM(WOL.TotalCost) AS BillingAmount
		FROM DBO.SubWorkOrderLabor WOL WITH (NOLOCK) 
		INNER JOIN DBO.SubWorkOrderLaborHeader WOLH WITH (NOLOCK) ON WOL.SubWorkOrderLaborHeaderId = WOLH.SubWorkOrderLaborHeaderId
		LEFT JOIN DBO.EmployeeExpertise EE WITH (NOLOCK) ON WOL.ExpertiseId = EE.EmployeeExpertiseId
		LEFT JOIN DBO.SubWorkOrderTask WOT WITH (NOLOCK) ON WOT.SubWorkOrderTaskId = WOL.TaskId AND WOT.WorkOrderId = WOLH.WorkOrderId
		WHERE WOT.SubWorkOrderTaskId = @SubWorkOrderTaskId;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetSWOTaskLaborByWOTaskId'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@SubWorkOrderTaskId AS varchar(10)) ,'') +''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException
                @DatabaseName           =  @DatabaseName
                , @AdhocComments          =  @AdhocComments
                , @ProcedureParameters    =  @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
  END CATCH
END