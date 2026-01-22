/*************************************************************           
 ** File:   [GetSWOWorkflowTransferData]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Get Sub Work Order Work Flow Transer Data Details
 ** Purpose:         
 ** Date:   07-02-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date			Author			Change Description              
 ** --   --------		-------         --------------------------------            
    1    07-02-2025		Vishal Suthar   Created

-- EXEC [dbo].[GetSWOWorkflowTransferData] 8020
**************************************************************/  
CREATE   PROCEDURE [dbo].[GetSWOWorkflowTransferData]
	@WorkflowId BIGINT,
	@subWOPartNoId BIGINT
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
		DECLARE @workOrderSettings BIT = 0;

		IF EXISTS(SELECT 1 FROM [dbo].[SubWorkOrderCharges] WITH(NOLOCK) WHERE [SubWOPartNoId] = @subWOPartNoId AND ISNULL([IsFromWorkFlow],0) = 1)
		BEGIN
			SET @excharges = 1;
		END
	    IF EXISTS(SELECT 1 FROM [dbo].[SubWorkOrderAsset] WITH(NOLOCK) WHERE [SubWOPartNoId] = @subWOPartNoId AND ISNULL([IsFromWorkFlow],0) = 1)
		BEGIN
		    SET @exEquipments = 1;
		END
		IF EXISTS(SELECT 1 FROM [dbo].[SubWorkOrderMaterials] WITH(NOLOCK) WHERE [SubWOPartNoId] = @subWOPartNoId AND ISNULL([IsFromWorkFlow],0) = 1)
		BEGIN
			SET @exMaterialList = 1;
		END
		IF EXISTS(SELECT TOP 1 wl.SubWorkOrderLaborId FROM [dbo].[SubWorkOrderLaborHeader] wlh WITH(NOLOCK) JOIN [dbo].[SubWorkOrderLabor] wl WITH(NOLOCK) ON wlh.[SubWorkOrderLaborHeaderId] = wl.[SubWorkOrderLaborHeaderId] WHERE wlh.[SubWOPartNoId] = @subWOPartNoId AND ISNULL(wl.[IsFromWorkFlow],0) = 1)
		BEGIN
			SET @exlaborHeader = 1;
		END
		IF EXISTS(SELECT TOP 1 wt.SubWorkOrderTaskId FROM [dbo].[SubWorkOrderTaskInstruction] wti WITH(NOLOCK) JOIN [dbo].[SubWorkOrderTask] wt WITH(NOLOCK) ON wti.[SubWorkOrderTaskId] = wt.[SubWorkOrderTaskId] WHERE wt.[SubWOPartNoId] = @subWOPartNoId AND ISNULL(wti.[IsFromWorkFlow],0) = 1)
		BEGIN
			SET @exdirections = 1;
		END
		IF EXISTS(SELECT 1 FROM [dbo].[SubWorkOrderTask]  WITH(NOLOCK) WHERE [SubWOPartNoId] = @subWOPartNoId AND ISNULL([IsFromWorkFlow],0) = 1)
		BEGIN
			SET @exTask = 1;
		END

		IF EXISTS(SELECT TOP 1 wo.WorkOrderId FROM [dbo].[WorkOrderSettings] wos WITH(NOLOCK)
		JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wos.[WorkOrderTypeId] = wo.[WorkOrderTypeId] AND wos.[MasterCompanyId] = wo.[MasterCompanyId]
		JOIN [dbo].[WorkOrderWorkFlow] wof WITH(NOLOCK) ON wof.WorkOrderId = wo.WorkOrderId AND wof.WorkFlowWorkOrderId = @subWOPartNoId
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
            , @AdhocComments     VARCHAR(150)    = 'GetSWOWorkflowTransferData' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@subWOPartNoId, '') AS VARCHAR(250))
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