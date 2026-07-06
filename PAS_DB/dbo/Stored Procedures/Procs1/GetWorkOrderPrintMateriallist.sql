/*******           
 ** File:   [GetWorkOrderPrintPdfData]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Work order Print  Details    
 ** Purpose:         
 ** Date:   12/30/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 ********           
  ** Change History           
 ********           
 ** PR   Date         Author		 Change Description            
 ** --   --------     -------		 --------------------------------          
    1    06/02/2020   Subhash Saliya Created
    2    03/27/2023   Vishal Suthar  Modified to include KIT material data
    3    12/04/2023   Bhargav Saliya Added Case For material data(>Dont get Sub WO material)
	4    19/01/2026   Moin Bloch     Added PONum
	5    21/01/2026   Moin Bloch     Added StockLineNumber,ControlNumber
	6    10/02/2026   Amit Ghediya   Added WorkOrderNumber for Stockline lines where the part line is associated to a WO (PN-15419)
	7    20/02/2026   Amit Ghediya   Added RO NUM,SerialNumber , TenderedQTY (PN-15533)
	8    23/02/2026   Amit Ghediya   Added RO NUM,SerialNumber , TenderedQTY (PN-15533)
	9    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
--EXEC [GetWorkOrderPrintMateriallist] 10148,10350,10212
********/
CREATE   PROCEDURE [dbo].[GetWorkOrderPrintMateriallist]
	@WorkorderId bigint,
	@workOrderPartNoId bigint,
	@workFlowWorkOrderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		
		DECLARE @ProvisionId BIGINT = (SELECT ProvisionId FROM [Provision] WHERE [Description] = 'SUB WORK ORDER');

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				SELECT  SUM(WOMS.Quantity) AS Quantity,
				        SUM(WOMS.QtyIssued) AS QuantityIssued,
						imt.partnumber AS partnumber,
						imt.PartDescription AS PartDescription,
						CASE WHEN 
							ISNULL(WOMS.RepairOrderId,0) > 0 THEN RO.RepairOrderNumber 
						ELSE 
							CASE WHEN 
								 ISNULL(STK.RepairOrderId,0) > 0 THEN STK.RepairOrderNumber 
							ELSE 
								STK.PurchaseOrderNumber 
							END
						END AS PONum,
						STK.StockLineNumber,
						STK.ControlNumber,
						CASE WHEN ISNULL(STK.[IsTurnIn],0) = 1 THEN ISNULL(STK.[WorkOrderNumber],'') ELSE '' END AS WorkOrderNumber,
						STK.SerialNumber,
						WOMS.QuantityTurnIn AS TenderedQTY
				FROM [dbo].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
				INNER JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON STk.StockLineId = WOMS.StockLineId
				LEFT JOIN  [dbo].[ItemMaster] imt WITH(NOLOCK) ON imt.ItemMasterId = WOMS.ItemMasterId
				 AND ISNULL(imt.IsNonStock,0) = 0 LEFT JOIN  [dbo].[RepairOrder] RO WITH(NOLOCK) ON RO.RepairOrderId = WOMS.RepairOrderId
				WHERE WOM.WorkFlowWorkOrderId = @workFlowWorkOrderId AND WOMS.IsDeleted = 0 AND WOMS.ProvisionId <> @ProvisionId
				GROUP BY WOMS.RepairOrderId,STK.PurchaseOrderNumber,imt.partnumber,imt.PartDescription,STK.StockLineNumber,
						 STK.ControlNumber,STK.IsTurnIn,STK.WorkOrderNumber,STK.SerialNumber,STK.RepairOrderId,STK.RepairOrderNumber,RO.RepairOrderNumber,WOMS.QuantityTurnIn

				UNION ALL

				SELECT  SUM(WOMS.Quantity) AS Quantity,
				        SUM(WOMS.QtyIssued) AS QuantityIssued,
						imt.partnumber AS partnumber,
						imt.PartDescription AS PartDescription,
						CASE WHEN 
							ISNULL(WOMS.RepairOrderId,0) > 0 THEN RO.RepairOrderNumber 
						ELSE 
							CASE WHEN 
								ISNULL(STK.RepairOrderId,0) > 0 THEN STK.RepairOrderNumber 
							ELSE 
								STK.PurchaseOrderNumber 
							END
						END AS PONum,
						STK.StockLineNumber,
						STK.ControlNumber,
						CASE WHEN ISNULL(STK.[IsTurnIn],0) = 1 THEN ISNULL(STK.[WorkOrderNumber],'') ELSE '' END AS WorkOrderNumber,
						STK.SerialNumber,
						WOMS.QuantityTurnIn AS TenderedQTY
				FROM [dbo].[WorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrderMaterialsKit] WOM WITH(NOLOCK) ON WOM.WorkOrderMaterialsKitId= WOMS.WorkOrderMaterialsKitId
				INNER JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON STk.StockLineId = WOMS.StockLineId
				LEFT JOIN [dbo].[ItemMaster] imt WITH(NOLOCK) ON imt.ItemMasterId = WOMS.ItemMasterId
				 AND ISNULL(imt.IsNonStock,0) = 0 LEFT JOIN  [dbo].[RepairOrder] RO WITH(NOLOCK) ON RO.RepairOrderId = WOMS.RepairOrderId
				WHERE WOM.WorkFlowWorkOrderId = @workFlowWorkOrderId AND WOMS.IsDeleted = 0
				GROUP BY WOMS.RepairOrderId,STK.PurchaseOrderNumber,imt.partnumber,imt.PartDescription,STK.StockLineNumber,
						 STK.ControlNumber,STK.IsTurnIn,STK.WorkOrderNumber,STK.SerialNumber,STK.RepairOrderId,STK.RepairOrderNumber,RO.RepairOrderNumber,WOMS.QuantityTurnIn
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderPrintMateriallist' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '''
													   @Parameter2 = ' + ISNULL(@workOrderPartNoId ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
------------------------------------PLEASE DO NOT EDIT BELOW--------------------------------------------------------------------
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