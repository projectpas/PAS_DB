/*************************************************************           
 ** File:   [USP_CheckWOMarerialsExist]           
 ** Author:  HEMANT SALIYA
 ** Description: This stored procedure is used TO Check Materilas are exist or not
 ** Purpose:         
 ** Date:   01/19/2024      
          
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    01/19/2024   HEMANT SALIYA			Created

     
exec [USP_ReOpenSubWorkOrderByPartId] 

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_CheckWOMarerialsExist]
@WorkOrderId BIGINT = NULL,
@WorkOrderWorkflowId BIGINT = NULL,
@ItemMasterId BIGINT = NULL,
@ConditionId BIGINT = NULL,
@TaskId BIGINT = NULL,
@Item VARCHAR(MAX) = NULL,
@Figure VARCHAR(MAX) = NULL
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		SELECT TOP 1 * FROM dbo.WorkOrderMaterials WITH(NOLOCK) 
		WHERE ItemMasterId = @ItemMasterId AND ConditionCodeId = @ConditionId AND TaskId = @TaskId AND isnull(Item, '') = @Item AND isnull(Figure, '') = @Figure 
		AND WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WorkOrderId = @WorkOrderId
	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			 
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_CheckWOMarerialsExist'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END