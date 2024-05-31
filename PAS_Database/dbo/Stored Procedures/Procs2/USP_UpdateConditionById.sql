/*************************************************************
 ** File:   [USP_UpdateConditionById]
 ** Author:   Devendra shekh
 ** Description: This stored procedure is used to Update condition id and name for workordersettlement
 ** Purpose:
 ** Date:   9th August 2023
 ** PARAMETERS: 
 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    08/09/2023			Devendra shekh			  Created
    2    01/31/2023			Devendra shekh			  changes for condition Update
	3    05/31/2024			Hemant Saliya			  Correced WOP condition Updates


exec dbo.USP_UpdateConditionById @WOPartNoId =3696,@WOId=4201,@ConditionId=10
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateConditionById]      
@WOPartNoId  bigint,
@WOId  bigint,
@ConditionId  bigint
AS    
BEGIN    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON   
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
					IF OBJECT_ID('tempdb..#Results') IS NOT NULL
						DROP TABLE #Results

					DECLARE @WOBillingId BIGINT = 0;

					SELECT * INTO #Results FROM(SELECT BillingInvoicingId FROM WorkOrderBillingInvoicing t2 WHERE t2.WorkOrderId = @WOId AND t2.IsVersionIncrease = 0 GROUP BY BillingInvoicingId) A

					SELECT @WOBillingId = ISNULL(WBI.BillingInvoicingId,0) 
					FROM [dbo].WorkOrderBillingInvoicing WBI WITH(NOLOCK) WHERE WBI.WorkOrderId = @WOId AND WBI.IsVersionIncrease = 0 
					ORDER BY WBI.BillingInvoicingId DESC

					UPDATE dbo.WorkOrderPartNumber SET RevisedConditionId = @ConditionId   WHERE ID = @WOPartNoId;

					IF(@WOBillingId > 0)
					BEGIN
						UPDATE dbo.WorkOrderBillingInvoicing SET ConditionId = @ConditionId   WHERE BillingInvoicingId IN (SELECT BillingInvoicingId FROM #Results);
						UPDATE dbo.WorkOrderBillingInvoicingItem SET ConditionId = @ConditionId   WHERE BillingInvoicingId IN (SELECT BillingInvoicingId FROM #Results);
					END					

			END
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateConditionById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' +  CAST(ISNULL(@WOPartNoId, '') as varchar(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END