/*************************************************************           
 ** File:   [UpdateWorkOrderColumnsWithId]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used WO Details based in WO Id.    
 ** Purpose:         
 ** Date:   12/30/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/30/2020   Hemant Saliya Created
	2    07/19/2021   Hemant Saliya Added SP Call for WO Status Update
	3    07/19/2021   Hemant Saliya Added Is NUll Condition
	4    10/21/2024   Devendra Shekh	added Fields for WPN update
     
-- EXEC [UpdateWorkOrderColumnsWithId] 6
**************************************************************/

CREATE   PROCEDURE [dbo].[UpdateWorkOrderColumnsWithId]
	@WorkOrderId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				UPDATE WO SET 
					WO.CustomerName = C.Name,
					WO.CustomerType = CA.AccountType,
					WO.CreditLimit = CF.CreditLimit,
					WO.CreditTerms = CT.Name,
					WO.WorkOrderType = WT.[Description]
				FROM [dbo].[WorkOrder] WO WITH(NOLOCK)
					INNER JOIN dbo.Customer C WITH(NOLOCK) ON WO.CustomerId = C.CustomerId
					INNER JOIN dbo.CustomerAffiliation CA WITH(NOLOCK) ON C.CustomerAffiliationId = CA.CustomerAffiliationId
					LEFT JOIN dbo.CustomerFinancial CF  WITH(NOLOCK) ON C.CustomerId = CF.CustomerId
					LEFT JOIN dbo.CreditTerms CT WITH(NOLOCK) ON CF.CreditTermsId = CT.CreditTermsId
					LEFT JOIN [dbo].[WorkOrderType] WT WITH(NOLOCK) ON WO.WorkOrderTypeId = WT.Id  
				WHERE WO.WorkOrderId = @WorkOrderId

				UPDATE WPN SET 
					WPN.WorkScope = WS.WorkScopeCode,
					WPN.RevisedConditionId = CASE WHEN ISNULL(WPN.RevisedConditionId, 0) > 0 THEN WPN.RevisedConditionId ELSE WPN.ConditionId END,
					WPN.[WorkOrderStage] = WOSG.[Code] + '-' + WOSG.[Stage]
				FROM [dbo].[WorkOrder] WO WITH(NOLOCK)
					JOIN dbo.WorkOrderPartNumber WPN WITH(NOLOCK) ON WO.WorkOrderId = WPN.WorkOrderId
					JOIN dbo.WorkScope WS WITH(NOLOCK) ON WPN.WorkOrderScopeId = WS.WorkScopeId
					LEFT JOIN [dbo].[WorkOrderStage] WOSG WITH(NOLOCK) ON WPN.WorkOrderStageId = WOSG.WorkOrderStageId
				WHERE WO.WorkOrderId = @WorkOrderId

				EXEC UpdateWorkOrderStatuByWOId @WorkOrderId
		
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderColumnsWithId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''
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