/*************************************************************
 ** File:   [USP_GetSWOTaskInstructionsByWOTaskId]
 ** Author: Vishal Suthar
 ** Description: This stored procedure is used to get SWO Task Instruction by WO Task Id
 ** Purpose:
 ** Date:   03/21/2025
    
 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    03/21/2025   Vishal Suthar		Created

EXEC [dbo].[USP_GetSWOTaskInstructionsByWOTaskId] 8
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSWOTaskInstructionsByWOTaskId]
	@SubWorkOrderTaskId bigint = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT *
		FROM DBO.SubWorkOrderTaskInstruction WOTI WITH (NOLOCK) 
		LEFT JOIN DBO.SubWorkOrderTask WOT WITH (NOLOCK) ON WOT.SubWorkOrderTaskId = WOTI.SubWorkOrderTaskId
		WHERE WOTI.SubWorkOrderTaskId = @SubWorkOrderTaskId
		ORDER BY WOTI.SequenceNumber;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetSWOTaskInstructionsByWOTaskId'
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