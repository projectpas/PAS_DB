/*************************************************************           
 ** File:   [USP_GetWOMPNDataByPartNumberId]           
 ** Author:   Bhargav Saliya 
 ** Description: Get Data for WO MPN Data By Part Number Id   
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
    2    06/04/2026      Ayushi Patel	    PN-15908 Update (Added UOM Changes)
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWOMPNDataByPartNumberId]
    @WorkOrderId BIGINT,
    @WorkOrderPartNumberId BIGINT,
    @WorkFlowWorkOrderId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		SELECT TOP 1
        stl.StockLineId,
        im.PartNumber,
        im.PartDescription,
        stl.StockLineNumber,
        stl.SerialNumber,
        --stl.QuantityOnHand AS Quantity,
        ISNULL([dbo].[fn_ConvertUOM](
            ISNULL(stl.QuantityOnHand,0),
            ISNULL(stl.[StockUnitOfMeasure], im.[StockUnitOfMeasure]),
            ISNULL(stl.[ConsumeUnitOfMeasure], im.[ConsumeUnitOfMeasure]),
            0,
            ISNULL(stl.[MasterCompanyId], im.[MasterCompanyId])
        ),0) AS Quantity,
        stl.Condition,
        stl.ControlNumber,
        stl.Site AS siteName,
        stl.Warehouse,
        stl.Location,
        stl.Shelf AS shelfName,
        stl.Bin AS binName,
        ISNULL(cust.Name, '') AS CustomerName,
        ISNULL(cust.CustomerCode, '') AS CustomerCode,
        stl.IdNumber AS ControlId,
        stl.ExpirationDate,
        stl.Manufacturer,
        stl.ReceiverNumber AS Receiver,
        stl.ReceivedDate,
        wo.Memo AS Notes,
        stl.GlAccountName AS Class,
        wo.WorkOrderNum AS WorkOrderNumber,
        wos.Stage AS MPNStage,
        wostatus.Description AS MPNStatus,
        stl.UnitOfMeasure AS UnitOfMeasureName,
        stl.TraceableToName
    FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)
    LEFT JOIN [dbo].[Stockline] stl WITH(NOLOCK) ON wop.StockLineId = stl.StockLineId
    INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON wop.ItemMasterId = im.ItemMasterId
    INNER JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wop.WorkOrderId = wo.WorkOrderId AND wo.WorkOrderId = @WorkOrderId
    LEFT JOIN [dbo].[Customer] cust WITH(NOLOCK) ON wo.CustomerId = cust.CustomerId
    LEFT JOIN [dbo].[WorkOrderStage] wos WITH(NOLOCK) ON wop.WorkOrderStageId = wos.WorkOrderStageId
    LEFT JOIN [dbo].[WorkOrderStatus] wostatus WITH(NOLOCK) ON wop.WorkOrderStatusId = wostatus.Id
    WHERE wop.IsDeleted = 0 AND wop.ID = @WorkOrderPartNumberId
	END TRY
	BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_GetWOMPNDataByPartNumberId',  
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