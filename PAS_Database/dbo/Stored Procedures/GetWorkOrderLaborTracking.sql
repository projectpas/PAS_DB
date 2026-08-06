/*************************************************************             
 ** File:   [GetWorkOrderLaborTracking]             
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used Get Work Order Labor Tracking 
 ** Purpose:           
 ** Date:   02/09/2025
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    02/09/2025		 Moin Bloch			Created  
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	EXEC [dbo].[GetWorkOrderLaborTracking] 13
************************************************************************/   
CREATE   PROCEDURE [dbo].[GetWorkOrderLaborTracking]    
@EmployeeId BIGINT
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN  
		SELECT WO.[WorkOrderNum],
			   CASE WHEN WO.[WorkOrderFormTypeId] = 1 THEN WOT.[TaskName] ELSE TSK.[Description] END AS [TaskName],
			   ITM.[PartNumber]			   
		 FROM [dbo].[WorkOrderLaborTracking] WLT WITH(NOLOCK)  	
		 LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WLT.[TaskId] = TSK.[TaskId]
		 LEFT JOIN [dbo].[WorkOrderTask] WOT  WITH(NOLOCK) ON WOT.WorkOrderTaskId = WLT.TaskId
		 LEFT JOIN [dbo].[WorkOrderLabor] WOL WITH(NOLOCK) ON WLT.[WorkOrderLaborId] = WOL.[WorkOrderLaborId]
		 LEFT JOIN [dbo].[WorkOrderLaborHeader] WLH WITH(NOLOCK) ON WOL.[WorkOrderLaborHeaderId] = WLH.[WorkOrderLaborHeaderId]
		 LEFT JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.[WorkOrderId] = WLH.[WorkOrderId]
		 LEFT JOIN [dbo].[WorkOrderWorkFlow] WOF WITH(NOLOCK) ON WLH.[WorkFlowWorkOrderId] = WOF.[WorkFlowWorkOrderId]		 
		 LEFT JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOF.[WorkOrderPartNoId] = WOP.[ID]
		 LEFT JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON WOP.[ItemMasterId] = ITM.[ItemMasterId]
		  AND ISNULL(ITM.IsNonStock,0) = 0
		 WHERE WLT.[EmployeeId] = @EmployeeId AND ISNULL(WLT.[IsCompleted],0) = 0
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderLaborTracking'                 
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))  
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