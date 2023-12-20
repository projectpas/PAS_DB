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


exec dbo.USP_UpdateConditionById @WOPartNoId =3212,@WOId=3765,@ConditionId=11
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
					DECLARE @WOBillingId BIGINT = 0;

					SELECT @WOBillingId = ISNULL(WBI.BillingInvoicingId,0) 
					FROM [dbo].WorkOrderBillingInvoicing WBI WITH(NOLOCK) WHERE WBI.WorkOrderId = @WOId AND WBI.IsVersionIncrease = 0 
					ORDER BY WBI.BillingInvoicingId DESC

					UPDATE dbo.WorkOrderPartNumber SET ConditionId = @ConditionId   WHERE ID = @WOPartNoId;

					IF(@WOBillingId > 0)
					BEGIN
						UPDATE dbo.WorkOrderBillingInvoicing SET ConditionId = @ConditionId   WHERE BillingInvoicingId = @WOBillingId;
						UPDATE dbo.WorkOrderBillingInvoicingItem SET ConditionId = @ConditionId   WHERE BillingInvoicingId = @WOBillingId;
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