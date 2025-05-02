/*************************************************************           
 ** File:   [USP_SubWorkOrderHeaderDetails]           
 ** Author:   Bhargav Saliya 
 ** Description: Get Data for SubWork Order Header Details    
 ** Purpose:         
 ** Date:   25-April-2025      
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    25-April-2025   Bhargav Saliya		Created
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SubWorkOrderHeaderDetails]
    @WorkOrderId INT,
    @WorkOrderPartNumberId INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		SELECT TOP 1
			wo.WorkOrderNum,
			wowf.WorkFlowWorkOrderId,
			im.PartNumber AS MCPN,
			im.RevisedPart AS RevisedMCPN,
			im.PartDescription AS MCPNDescription,
			sl.SerialNumber AS MCSerialNum,
			cust.Name AS CustName,
			wos.WorkScopeCode AS WorkScope,
			sl.StockLineNumber AS Stockline,
			ISNULL(wop.WorkOrderId, 0) AS WorkFlowId,
			ISNULL(wf.WorkOrderNumber, '') AS WorkFlowNo,
			wo.OpenDate,
			wop.EstimatedCompletionDate,
			wop.WorkOrderStageId AS StageId,
			stage.Stage AS WorkOrderStage,
			wop.WorkOrderStatusId AS StatusId,
			sts.Description AS WorkOrderStatus,
			wop.CMMIds,
			wop.PublicationNo AS WorkOrderCMM,
			wop.IsDER,
			wop.IsPMA,
			wop.WorkOrderScopeId,
			'CREATING' AS SubWorkOrderNo,
			wop.ItemMasterId,
			wo.CustomerId,
			cust.CustomerCode,
			cust.Name AS CustomerName,
			wo.WorkOrderTypeId,
			wo.FunctionalCurrencyId AS CurrencyId,
			wo.CreatedDate,
			wop.ReceivedDate,
			ISNULL(fcu.Code, '') AS FunctionalCurrency,
			ISNULL(rcu.Code, '') AS ReportCurrency,
			CASE WHEN wo.ForeignExchangeRate > 0 THEN wo.ForeignExchangeRate ELSE 0 END AS ForeignExchangeRate,
			wosett.Is813013aeOr14ae
		FROM [dbo].[WorkOrder] wo WITH(NOLOCK)
		INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId
		INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON wop.ItemMasterId = im.ItemMasterId
		INNER JOIN [dbo].[Stockline] sl WITH(NOLOCK) ON wop.StockLineId = sl.StockLineId
		INNER JOIN [dbo].[WorkScope] wos WITH(NOLOCK) ON wop.WorkOrderScopeId = wos.WorkScopeId
		INNER JOIN [dbo].[Customer] cust WITH(NOLOCK) ON wo.CustomerId = cust.CustomerId
		LEFT JOIN [dbo].[Workflow] wf WITH(NOLOCK) ON wop.WorkflowId = wf.WorkflowId
		LEFT JOIN [dbo].[WorkOrderSettings] wosett WITH(NOLOCK) ON wo.WorkOrderTypeId = wosett.WorkOrderTypeId
		INNER JOIN [dbo].[WorkOrderStage] stage WITH(NOLOCK) ON wop.WorkOrderStageId = stage.WorkOrderStageId
		INNER JOIN [dbo].[WorkOrderStatus] sts WITH(NOLOCK) ON wop.WorkOrderStatusId = sts.Id
		INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wo.WorkOrderId = wowf.WorkOrderId
		LEFT JOIN [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON wo.CustomerId = cf.CustomerId
		LEFT JOIN [dbo].[Currency] fcu WITH(NOLOCK) ON wo.FunctionalCurrencyId = fcu.CurrencyId AND fcu.IsActive = 1 AND fcu.IsDeleted = 0
		LEFT JOIN [dbo].[Currency] rcu WITH(NOLOCK) ON wo.ReportCurrencyId = rcu.CurrencyId AND rcu.IsActive = 1 AND rcu.IsDeleted = 0
		WHERE wo.WorkOrderId = @WorkOrderId AND wop.ID = @WorkOrderPartNumberId
	END TRY
	BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_SubWorkOrderHeaderDetails',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderPartNumberId, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'   
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
	END CATCH   
END