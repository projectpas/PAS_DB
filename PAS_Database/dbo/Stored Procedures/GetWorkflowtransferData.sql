/*************************************************************           
 ** File:   [GetWorkflowtransferData]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get Work Flow Transer Data Details
 ** Purpose:         
 ** Date:   10-03-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    10-03-2025    Sahdev Saliya       Created  
    2    08-04-2025    Devendra Shekh	   Corrected WorkOrderId to WorkFlowWorkOrderId

	-- EXEC [dbo].[GetWorkflowtransferData] 8020
**************************************************************/  
CREATE   PROCEDURE [dbo].[GetWorkflowtransferData]
@workFlowWorkOrderId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
		DECLARE @excharges BIT = 0	
		DECLARE @exEquipments BIT = 0
	    DECLARE @exMaterialList BIT = 0
	    DECLARE @exlaborHeader BIT = 0
		DECLARE @exdirections BIT = 0
		DECLARE @exTask BIT = 0
		DECLARE @workOrderSettings BIT = 0
		DECLARE @WorkflowId BIGINT = NULL

        SELECT @WorkflowId = WorkflowId FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @workFlowWorkOrderId

		IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderCharges] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @workFlowWorkOrderId AND ISNULL([IsFromWorkFlow],0) = 1)
		BEGIN
			SET @excharges = 1;
		END
	    IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderAssets]  WITH(NOLOCK) WHERE [workFlowWorkOrderId] = @workFlowWorkOrderId AND ISNULL([IsFromWorkFlow],0) = 1)
		BEGIN
		    SET @exEquipments = 1;
		END
		IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderMaterials]  WITH(NOLOCK) WHERE [workFlowWorkOrderId] = @workFlowWorkOrderId AND ISNULL([IsFromWorkFlow],0) = 1)
		BEGIN
			SET @exMaterialList = 1;
		END
		IF EXISTS(SELECT TOP 1 wl.WorkOrderLaborId FROM [dbo].[WorkOrderLaborHeader] wlh WITH(NOLOCK) JOIN [dbo].[WorkOrderLabor] wl WITH(NOLOCK) ON wlh.[WorkOrderLaborHeaderId] = wl.[WorkOrderLaborHeaderId] WHERE wlh.[workFlowWorkOrderId] = @workFlowWorkOrderId AND ISNULL(wl.[IsFromWorkFlow],0) = 1)
		BEGIN
			SET @exlaborHeader = 1;
		END
		IF EXISTS(SELECT TOP 1 wt.WorkOrderTaskId FROM [dbo].[WorkOrderTaskInstruction] wti WITH(NOLOCK) JOIN [dbo].[WorkOrderTask] wt WITH(NOLOCK) ON wti.[WorkOrderTaskId] = wt.[WorkOrderTaskId] WHERE wt.[workFlowWorkOrderId] = @workFlowWorkOrderId AND ISNULL(wti.[IsFromWorkFlow],0) = 1)
		BEGIN
			SET @exdirections = 1;
		END
		IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderTask]  WITH(NOLOCK) WHERE [workFlowWorkOrderId] = @workFlowWorkOrderId AND ISNULL([IsFromWorkFlow],0) = 1)
		BEGIN
			SET @exTask = 1;
		END
		IF EXISTS(SELECT TOP 1 wo.WorkOrderId FROM [dbo].[WorkOrderSettings] wos WITH(NOLOCK)
		JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wos.[WorkOrderTypeId] = wo.[WorkOrderTypeId] AND wos.[MasterCompanyId] = wo.[MasterCompanyId]
		JOIN [dbo].[WorkOrderWorkFlow] wof WITH(NOLOCK) ON wof.WorkOrderId = wo.WorkOrderId AND wof.WorkFlowWorkOrderId = @workFlowWorkOrderId
		AND wos.[IsActive] = 1 AND wos.[IsDeleted] = 0 AND [IsTraveler] = 1)
		BEGIN
			SET @workOrderSettings = 1;
		END

		SELECT @WorkflowId as WorkflowId, 
		       @excharges AS ExCharges, 
		       @exEquipments AS ExEquipments,
			   @exMaterialList AS ExMaterialList,
			   @exlaborHeader AS ExLaborHeader,
			   @exdirections AS ExDirections,
			   @exTask AS ExTask,
			   @workOrderSettings AS WorkOrderSettings
		 
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkflowtransferData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@workFlowWorkOrderId, '') AS VARCHAR(250))
												
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