/*************************************************************           
 ** File:   [GetWorkOrderSummarisedChargesData]           
 ** Author:   Hemant Saliya
 ** Description: Get Work Order Summarised Chanrges Details List    
 ** Purpose:         
 ** Date:   03-Feb-2021        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/03/2020   Hemant Saliya Created
     
 EXECUTE [GetWorkOrderSummarisedChargesData] 365

**************************************************************/ 

CREATE PROCEDURE [dbo].[GetWorkOrderSummarisedChargesData]
@WorkOrderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				SELECT DISTINCT
					IM.partnumber,
					IM.RevisedPart AS RevisedPartNo,
					IM.PartDescription,
					ISNULL(SUM(WC.UnitCost), 0) AS UnitCost,
					ISNULL(SUM(WC.ExtendedCost), 0) AS ExtendedCost,
					ISNULL(SUM(WC.UnitCost), 0) AS UnitPrice,
					ISNULL(SUM(WC.UnitCost), 0) AS ExtendedUnitPrice,
					ISNULL(SUM(WC.Quantity), 0) AS Quantity,
					CASE WHEN COUNT(WC.WorkOrderChargesId) > 1 THEN 'Multiple' 
					ELSE (SELECT c.ChargeType FROM dbo.Charge C WITH(NOLOCK) JOIN dbo.WorkOrderCharges WOC ON C.ChargeId = WOC.ChargesTypeId 
					WHERE WOC.WorkOrderId = @WorkOrderId AND WOC.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId AND WOC.IsDeleted = 0 AND WOC.IsActive = 1) END AS ChargeType,

					CASE WHEN COUNT(WC.WorkOrderChargesId) > 1 THEN 'Multiple' 
					ELSE (SELECT V.VendorName FROM dbo.Vendor V WITH(NOLOCK) JOIN dbo.WorkOrderCharges WOC ON V.VendorId = WOC.VendorId 
					WHERE WOC.WorkOrderId = @WorkOrderId AND WOC.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId AND WOC.IsDeleted = 0 AND WOC.IsActive = 1) END AS Vendor,

					CASE WHEN COUNT(WC.WorkOrderChargesId) > 1 THEN 'Multiple' 
					ELSE (SELECT T.Description FROM dbo.Task T WITH(NOLOCK) JOIN dbo.WorkOrderCharges WOC ON T.TaskId = WOC.TaskId 
					WHERE WOC.WorkOrderId = @WorkOrderId AND WOC.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId AND WOC.IsDeleted = 0 AND WOC.IsActive = 1) END AS Task,

					CASE WHEN COUNT(WC.WorkOrderChargesId) > 1 THEN 'Multiple' 
					ELSE (SELECT WOC.ReferenceNo FROM dbo.WorkOrderCharges WOC WITH(NOLOCK) WHERE WOC.WorkOrderId = @WorkOrderId AND WOC.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId AND WOC.IsDeleted = 0 AND WOC.IsActive = 1) END AS RefNum,
					
					WOP.WorkOrderId,
					WOWF.WorkFlowWorkOrderId
				FROM dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) 
					JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID
					JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WOP.ItemMasterId
					LEFT JOIN dbo.WorkOrderCharges WC WITH(NOLOCK) ON WOWF.WorkFlowWorkOrderId = WC.WorkFlowWorkOrderId
				WHERE WOP.IsDeleted = 0 AND WOP.WorkOrderId = @WorkOrderId AND WC.IsDeleted = 0 AND WC.IsActive = 1
				GROUP BY IM.partnumber, Im.PartDescription, IM.RevisedPart, WOP.WorkOrderId, WOWF.WorkFlowWorkOrderId 

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderSummarisedChargesData' 
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