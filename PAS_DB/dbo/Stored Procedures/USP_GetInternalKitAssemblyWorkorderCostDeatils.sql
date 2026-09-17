/*************************************************************           
 ** File:   [USP_GetInternalKitAssemblyWorkorderCostDeatils]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get Work Order MPN Cost Details
 ** Purpose:         
 ** Date:   09/09/2026                  
 ** PARAMETERS:          
 ** RETURN VALUE:       
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/09/2026   Moin Bloch	Created

-- EXEC [USP_GetInternalKitAssemblyWorkorderCostDeatils] 4444
**************************************************************/

CREATE PROCEDURE [dbo].[USP_GetInternalKitAssemblyWorkorderCostDeatils]
@WorkOrderId BIGINT 
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
				
               SELECT WOP.[ID]  AS [WorkOrderPartNoId]
					 ,ITM.[partnumber] AS PartNumber
                     ,ISNULL(WOPC.[PartsCost],0) AS MaterialCost
                     ,ISNULL(WOPC.[LaborCost],0) AS LaborCost
					 ,ISNULL(WOPC.[ChargesCost],0) AS ChargesCost	
					 ,ISNULL(WOPC.[FreightCost],0) AS FreightCost	
                     ,ISNULL(WOPC.[OtherCost],0) AS OtherCost                     
					 ,ISNULL(WOP.[KitsToPrepare],0) AS ProducedQty
					 ,ISNULL(ITM.[isSerialized],0)  AS IsSerialized
               FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) 
                LEFT JOIN [dbo].[WorkOrderMPNCostDetails] WOPC WITH(NOLOCK) ON WOP.ID = WOPC.WOPartNoId
               INNER JOIN [dbo].[ItemMaster]  ITM WITH(NOLOCK) ON WOP.ItemMasterId=ITM.ItemMasterId      
               WHERE WOP.[WorkOrderId] = @WorkOrderId 
      
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0			
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetInternalKitAssemblyWorkorderCostDeatils' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END