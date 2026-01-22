/*************************************************************
 ** File:   [USP_GetWOTaskInstructionsByWOTaskId]
 ** Author: Vishal Suthar
 ** Description: This stored procedure is used to get WO Task Instruction by WO Task Id
 ** Purpose:
 ** Date:   01/07/2025
    
 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    01/07/2025   Vishal Suthar		Created

EXEC [dbo].[USP_GetWOTaskInstructionsByWOTaskId] 8
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWOTaskInstructionsByWOTaskId]
	@WorkOrderTaskId bigint = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT *
		FROM DBO.WorkOrderTaskInstruction WOTI WITH (NOLOCK) 
		LEFT JOIN DBO.WorkOrderTask WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOTI.WorkOrderTaskId
		WHERE WOTI.WorkOrderTaskId = @WorkOrderTaskId
		ORDER BY WOTI.SequenceNumber;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetWOTaskInstructionsByWOTaskId'
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