/*************************************************************           
 ** File:     [USP_GetStockLineLessQtyCheckList]           
 ** Author:	  Devendra Shekh
 ** Description: This SP IS Used to get StockLine List fot Stk which has Less Qty than requested
 ** Purpose:         
 ** Date:   05/29/2024	      [mm/dd/yyyy]    
 ** PARAMETERS:       
 ** RETURN VALUE:     
 **************************************************************    
 ** Change History           
 **************************************************************           
 ** PR   	Date			Author					Change Description            
 ** --   	--------		-------				--------------------------------     
	1		05/29/2024		Devendra Shekh			CREATED
	1		06/05/2024		HEMANT SALIYA			Updated for Add Provision Condition
	
	EXEC [USP_GetStockLineLessQtyCheckList] 3993, 3510, 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetStockLineLessQtyCheckList]
@WorkOrderId BIGINT,
@WorkFlowWorkOrderId BIGINT,
@MasterCompanyId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @ReplaceProvisionId INT;

				IF OBJECT_ID('tempdb..#Results') IS NOT NULL
					DROP TABLE #Results

				CREATE TABLE #TempStkLineList
				(
					PartNumber VARCHAR(50) NULL,
					PartDescription NVARCHAR(MAX) NULL,
					StockLineId	BIGINT NULL,
					StockLineNumber	VARCHAR(50) NULL,
					ControlNumber VARCHAR(50) NULL,
					SerialNumber VARCHAR(30) NULL,
					Quantity INT NULL,
					QuantityAvailable INT NULL,
					QuantityOnHand INT NULL,
					QuantityIssued INT NULL,
					QuantityReserved INT NULL,
					QuantityRequested INT NULL,
				)

				SELECT @ReplaceProvisionId = ProvisionId FROM dbo.Provision WHERE StatusCode = 'REPLACE'

				--Inserting Materials StockLine Data 
				INSERT INTO #TempStkLineList(PartNumber, PartDescription, StockLineId, StockLineNumber, ControlNumber, SerialNumber,
						Quantity, QuantityAvailable, QuantityOnHand, QuantityIssued, QuantityReserved, QuantityRequested)
				SELECT	STK.PartNumber,
						STK.PNDescription as PartDescription,
						STK.StockLineId,
						STK.StockLineNumber,
						STK.ControlNumber,
						ISNULL(STK.SerialNumber, '') AS SerialNumber,
						ISNULL(STK.Quantity, 0) AS Quantity,
						ISNULL(STK.QuantityAvailable, 0) AS QuantityAvailable,
						STK.QuantityOnHand,
						ISNULL(STK.QuantityIssued, 0) AS QuantityIssued,
						ISNULL(STK.QuantityReserved, 0) AS QuantityReserved,
						ISNULL(WOMS.Quantity,0 ) AS QuantityRequested
				FROM [dbo].[Stockline] STK WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOMS.StockLineId = STK.StockLineId AND ProvisionId = @ReplaceProvisionId
				INNER JOIN [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
				WHERE	WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId 
						AND WOM.WorkOrderId = @WorkOrderId 
						AND WOM.MasterCompanyId = @MasterCompanyId
						AND (ISNULL(WOMS.Quantity,0 ) - (ISNULL(WOMS.QtyIssued, 0) + ISNULL(WOMS.QtyReserved, 0))) > ISNULL(STK.QuantityAvailable, 0)

				--Inserting Materials StockLineKit Data 
				INSERT INTO #TempStkLineList(PartNumber, PartDescription, StockLineId, StockLineNumber, ControlNumber, SerialNumber,
						Quantity, QuantityAvailable, QuantityOnHand, QuantityIssued, QuantityReserved, QuantityRequested)
				SELECT	STK.PartNumber,
						STK.PNDescription as PartDescription,
						STK.StockLineId,
						STK.StockLineNumber,
						STK.ControlNumber,
						ISNULL(STK.SerialNumber, '') AS SerialNumber,
						ISNULL(STK.Quantity, 0) AS Quantity,
						ISNULL(STK.QuantityAvailable, 0) AS QuantityAvailable,
						STK.QuantityOnHand,
						ISNULL(STK.QuantityIssued, 0) AS QuantityIssued,
						ISNULL(STK.QuantityReserved, 0) AS QuantityReserved,
						ISNULL(WOMSK.Quantity,0 ) AS QuantityRequested
				FROM [dbo].[Stockline] STK WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] WOMSK WITH(NOLOCK) ON WOMSK.StockLineId = STK.StockLineId AND ProvisionId = @ReplaceProvisionId
				INNER JOIN [dbo].[WorkOrderMaterialsKit] WOMK WITH(NOLOCK) ON WOMK.WorkOrderMaterialsKitId = WOMSK.WorkOrderMaterialsKitId
				WHERE	WOMK.WorkFlowWorkOrderId = @WorkFlowWorkOrderId 
						AND WOMK.WorkOrderId = @WorkOrderId 
						AND WOMK.MasterCompanyId = @MasterCompanyId
						AND (ISNULL(WOMSK.Quantity,0) - (ISNULL(WOMSK.QtyIssued, 0) + ISNULL(WOMSK.QtyReserved, 0))) > ISNULL(STK.QuantityAvailable, 0)

				SELECT * FROM #TempStkLineList;
				
			END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0				
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetStockLineLessQtyCheckList' 
               ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END