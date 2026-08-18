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
	5    12/30/2024   Devendra Shekh	added Missing Fields for WPN update
	6    04/30/2025   Rajesh Gami	    added Missing Fields for WPN update (Revised Part Number and Description)  
	7    02/09/2026   Moin Bloch	    added CreditTermId 
	8    29/06/2026   Bhargav Saliya	Get Terms and Id From WO Table [PN-17040]
	9    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
-- EXEC [UpdateWorkOrderColumnsWithId] 8792
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
					WO.CustomerName = C.[Name],
					WO.CustomerType = CA.[AccountType],
					WO.CreditLimit = CF.[CreditLimit],
					WO.CreditTerms = WO.[CreditTerms],
					WO.CreditTermId = WO.[CreditTermId],
					WO.WorkOrderType = WT.[Description]
				FROM [dbo].[WorkOrder] WO WITH(NOLOCK)
					INNER JOIN [dbo].[Customer] C WITH(NOLOCK) ON WO.CustomerId = C.CustomerId
					INNER JOIN [dbo].[CustomerAffiliation] CA WITH(NOLOCK) ON C.CustomerAffiliationId = CA.CustomerAffiliationId
					 LEFT JOIN [dbo].[CustomerFinancial] CF  WITH(NOLOCK) ON C.CustomerId = CF.CustomerId
					 LEFT JOIN [dbo].[WorkOrderType] WT WITH(NOLOCK) ON WO.WorkOrderTypeId = WT.Id  
				WHERE WO.WorkOrderId = @WorkOrderId

				UPDATE WPN SET 
					WPN.WorkScope = WS.WorkScopeCode,
					WPN.RevisedConditionId = CASE WHEN ISNULL(WPN.RevisedConditionId, 0) > 0 THEN WPN.RevisedConditionId ELSE WPN.ConditionId END,
					WPN.[WorkOrderStage] = WOSG.[Code] + '-' + WOSG.[Stage],
					WPN.[PartDescription] = IM.[PartDescription],
					WPN.[PartNumber] = IM.[PartNumber],
					WPN.[RevisedPartDescription] = RIM.[PartDescription],
					WPN.[RevisedPartNumber] = RIM.[PartNumber],
					WPN.[WorkOrderStatus] = WOS.[Description],
					WPN.[Priority] = PR.[Description], 
					WPN.[ManufacturerName] = IM.[ManufacturerName],
					WPN.[TechName] = UPPER(EMP.FirstName + ' ' + EMP.LastName),
					WPN.[EmployeeStation] = UPPER(EMPS.StationName)
				FROM [dbo].[WorkOrder] WO WITH(NOLOCK)
					JOIN [dbo].[WorkOrderPartNumber] WPN WITH(NOLOCK) ON WO.WorkOrderId = WPN.WorkOrderId
					JOIN [dbo].[WorkScope] WS WITH(NOLOCK) ON WPN.WorkOrderScopeId = WS.WorkScopeId
					LEFT JOIN [dbo].[WorkOrderStage] WOSG WITH(NOLOCK) ON WPN.WorkOrderStageId = WOSG.WorkOrderStageId
					LEFT JOIN [dbo].[WorkOrderStatus] WOS WITH(NOLOCK) ON WOS.Id = WPN.WorkOrderStatusId  
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId
					 AND ISNULL(IM.IsNonStock,0) = 0
					LEFT JOIN [dbo].[ItemMaster] RIM WITH(NOLOCK) ON RIM.ItemMasterId = WPN.RevisedItemMasterId         
					 AND ISNULL(RIM.IsNonStock,0) = 0
					LEFT JOIN [dbo].[Priority] PR WITH(NOLOCK) ON WPN.WorkOrderPriorityId = PR.PriorityId  
					LEFT JOIN [dbo].[Employee] EMP WITH(NOLOCK) ON EMP.EmployeeId = WPN.TechnicianId  
					LEFT JOIN [dbo].[EmployeeStation] EMPS WITH(NOLOCK) ON WPN.TechStationId = EMPS.EmployeeStationId
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
			  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))  
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