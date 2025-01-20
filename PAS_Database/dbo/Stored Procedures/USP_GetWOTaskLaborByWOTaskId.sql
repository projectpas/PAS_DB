/*************************************************************
 ** File:   [USP_GetWOTaskLaborByWOTaskId]
 ** Author: Vishal Suthar
 ** Description: This stored procedure is used to get WO Task Instruction by WO Task Id
 ** Purpose:
 ** Date:   01/17/2025
    
 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    01/17/2025   Vishal Suthar		Created

EXEC [dbo].[USP_GetWOTaskLaborByWOTaskId] 57
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWOTaskLaborByWOTaskId]
	@WorkOrderTaskId bigint = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT 
		STRING_AGG(EE.[Description], ',') AS Expretise,
		SUM(WOL.TotalCost) AS BillingAmount
		FROM DBO.WorkOrderLabor WOL WITH (NOLOCK) 
		INNER JOIN DBO.WorkOrderLaborHeader WOLH WITH (NOLOCK) ON WOL.WorkOrderLaborHeaderId = WOLH.WorkOrderLaborHeaderId
		LEFT JOIN DBO.EmployeeExpertise EE WITH (NOLOCK) ON WOL.ExpertiseId = EE.EmployeeExpertiseId
		LEFT JOIN DBO.WorkOrderTask WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOL.TaskId AND WOT.WorkOrderId = WOLH.WorkOrderId
		WHERE WOT.WorkOrderTaskId = @WorkOrderTaskId;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetWOTaskLaborByWOTaskId'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@WorkOrderTaskId AS varchar(10)) ,'') +''
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