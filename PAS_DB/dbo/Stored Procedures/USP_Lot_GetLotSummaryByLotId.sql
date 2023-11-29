/*************************************************************           
 ** File:   [USP_Lot_GetLotSummaryByLotId]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Get Lot summary by lot id
 ** Date:   05/05/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    05/05/2023   Rajesh Gami     Created
**************************************************************
 EXEC USP_Lot_GetLotSummaryByLotId 81 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_Lot_GetLotSummaryByLotId] 
@LotId bigint =0
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
			DECLARE @LOT_PO_Type VARCHAR(100) = 'PO';DECLARE @LOT_RO_Type VARCHAR(100)= 'RO';
			DECLARE @LOT_SO_Type VARCHAR(100)= 'SO';DECLARE @LOT_WO_Type VARCHAR(100)= 'WO';
			DECLARE @LOT_TransIn_LOT VARCHAR(100) = 'Trans In(Lot)';DECLARE @LOT_TransIn_PO VARCHAR(100) = 'Trans In(PO)';
			DECLARE @LOT_TransIn_RO VARCHAR(100) = 'Trans In(RO)';	DECLARE @LOT_TransIn_SO VARCHAR(100) = 'Trans In(SO)';
			DECLARE @LOT_TransIn_WO VARCHAR(100) = 'Trans In(WO)';	DECLARE @LOT_TransOut_LOT VARCHAR(100) = 'Trans Out(Lot)';
			DECLARE @LOT_TransOut_PO VARCHAR(100) = 'Trans Out(PO)'; DECLARE @LOT_TransOut_RO VARCHAR(100) = 'Trans Out(RO)';
			DECLARE @LOT_TransOut_SO VARCHAR(100) = 'Trans Out(SO)'; DECLARE @LOT_TransOut_WO VARCHAR(100) = 'Trans Out(WO)';	
			DECLARE @OriginalCost decimal(18,2) = 0,@RepairCost decimal(18,2) = 0,@TransferredInCost decimal(18,2) = 0,@TransferredOutCost decimal(18,2) = 0,@OtherCost decimal(18,2) = 0;
			DECLARE @TotalLotCost decimal(18,2) = 0,@RevenueCost decimal(18,2) = 0,@CogsPartCost decimal(18,2) = 0,@CommissionExpense decimal(18,2) = 0,@TotalExpense decimal(18,2) = 0;
			DECLARE @MarginAmount decimal(18,2) = 0,@MarginPercent decimal(18,2) = 0,@LotCostRemaining decimal(18,2) = 0,@OtherSalesExpenses decimal(18,2) = 0,@SoldCost decimal(18,2) = 0,@RemainingCostPercentage decimal(18,2) = 0;
			DECLARE @OriginalCostUnit int=0,@RepairCostUnit int=0,@TransferredInCostUnit int=0,@TransferredOutCostUnit int=0,@OtherCostUnit int=0,@RevenueCostUnit int=0;
			DECLARE @CogsPartCostUnit int=0,@CommissionExpenseUnit int=0,@TotalExpenseUnit int=0,@LotCostRemainingUnit int=0;
			DECLARE @AppModuleId INT = 0;
			SELECT @AppModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Lot';
			
			/************ COST Calculation ***************/
			--SELECT TOP 1 @OriginalCost = ISNULL(OriginalCost,0) FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) WHERE LCD.LotId = @LotId ORDER BY LCD.LotCalculationId DESC
			SELECT TOP 1 @OriginalCost = ISNULL(InitialPOCost,0) FROM DBO.Lot LT WITH(NOLOCK) WHERE LT.LotId = @LotId 
			SELECT @TransferredOutCost = ISNULL(SUM(ISNULL(TransferredOutCost,0)),0)
				   FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) WHERE LCD.LotId = @LotId  AND UPPER(REPLACE([Type],' ','')) = UPPER(REPLACE('Trans Out(Lot)',' ',''))

			SELECT @SoldCost = ISNULL(SUM(ISNULL(ExtSalesUnitPrice,0)),0)
				   FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) WHERE LCD.LotId = @LotId  AND UPPER(REPLACE([Type],' ','')) = UPPER(REPLACE('Trans Out(SO)',' ',''))
			SELECT  @TransferredInCost = ISNULL(SUM(ISNULL(LCD.TransferredInCost,0)),0)
				   FROM 
					DBO.LotCalculationDetails LCD WITH(NOLOCK)
					WHERE LCD.LotId = @LotId AND ISNULL(IsFromPreCostStk,0) = 0 AND UPPER(REPLACE([Type],' ','')) = UPPER(REPLACE('Trans In(Lot)',' ','')) 
					--AND (SELECT ISNULL(LT.IsStockLineUnitCost,0) FROM DBO.LotTransInOutDetails LT WITH(NOLOCK) WHERE LT.LotTransInOutId = LCD.LotTransInOutId ) = 1
			
			SELECT @RepairCost = SUM(ISNULL(RepairCost,0))
				   FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) WHERE LCD.LotId = @LotId

			;WITH Lot_CTE AS(
				SELECT
					 lot.LotId
				,ISNULL(po.PurchaseOrderId,0) PurchaseOrderId				
				,ven.VendorName Vendor
				,ISNULL(ven.VendorCode,'') VendorCode
				,ISNULL(ven.VendorId,0) VendorId		
				,ISNULL((SELECT SUM(ISNULL(PF.Amount,0)) FROM dbo.PurchaseOrderFreight PF WITH(NOLOCK) WHERE PF.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND ISNULL(PF.IsDeleted,0) = 0),0) AS FreightCost
				,ISNULL((SELECT SUM(ISNULL(PC.ExtendedCost,0)) FROM dbo.PurchaseOrderCharges PC WITH(NOLOCK) WHERE PC.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND ISNULL(PC.IsDeleted,0) = 0),0) AS ChargesCost
				,Po.CreatedDate AS PoDate
				,po.PurchaseOrderNumber AS PoNum			
				,part.PartNumber
				,part.PartDescription
				,part.Condition
				,part.Manufacturer
				FROM DBO.PurchaseOrder po WITH(NOLOCK)
					 INNER JOIN DBO.LOT lot WITH(NOLOCK) on po.LotId = lot.LotId
					 INNER JOIN PurchaseOrderPart part WITH(NOLOCK) on part.PurchaseOrderId = po.PurchaseOrderId
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN DBO.Stockline sl WITH(NOLOCK) on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId AND ltCal.ReferenceId = po.PurchaseOrderId AND ltCal.ChildId = part.PurchaseOrderPartRecordId
					 LEFT JOIN DBO.LotSetupMaster lsm WITH(NOLOCK) on lot.LotId = lsm.LotId
					 LEFT JOIN DBO.[Percent] per WITH(NOLOCK) on lsm.MarginPercentageId = per.PercentId
					 LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
					 LEFT JOIN DBO.UnitOfMeasure uom  WITH(NOLOCK) ON sl.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON po.VendorId = ven.VendorId
					 LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AppModuleId,',')) AND MSD.ReferenceID = lot.LotId	AND MSD.EntityMSID = Lot.ManagementStructureId
				 WHERE lot.LotId = @LotId
					   AND (ISNULL((SELECT SUM(ISNULL(PF.Amount,0)) FROM dbo.PurchaseOrderFreight PF WITH(NOLOCK) WHERE PF.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND ISNULL(PF.IsDeleted,0) = 0),0) > 0 
							OR ISNULL((SELECT SUM(ISNULL(PC.ExtendedCost,0)) FROM dbo.PurchaseOrderCharges PC WITH(NOLOCK) WHERE PC.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND ISNULL(PC.IsDeleted,0) = 0),0) >0)
				 )

				Select * INTO #tempTableLT FROM Lot_CTE Group by LotId,PurchaseOrderId,Vendor,VendorCode,VendorId,FreightCost,ChargesCost,PoDate,PoNum,PartNumber,PartDescription,Condition,Manufacturer
				Select @OtherCost = ISNULL( (SUM(ISNULL(FreightCost,0)))+ (SUM(ISNULL(ChargesCost,0))) ,0) from #tempTableLT

			--SET @TotalLotCost = (@OriginalCost + @RepairCost + @TransferredInCost + @OtherCost) - (@TransferredOutCost);
			SET @TotalLotCost = (@OriginalCost + @RepairCost + @TransferredInCost + @OtherCost);

			SET @CommissionExpense = ISNULL((SELECT SUM(ISNULL(CommissionExpense,0)) FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) WHERE LCD.LotId = @LotId),0);
			SET @RevenueCost = ISNULL((SELECT SUM(ISNULL(ExtSalesUnitPrice,0)) FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) WHERE LCD.LotId = @LotId AND REPLACE([Type],' ','') = REPLACE(@LOT_TransOut_SO,' ','') ),0)
			SET @CogsPartCost = ISNULL((SELECT SUM(ISNULL(Cogs,0)) FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) WHERE LCD.LotId = @LotId AND REPLACE([Type],' ','') = REPLACE(@LOT_TransOut_SO,' ','') ),0);
			SET @TotalExpense = @CogsPartCost + @CommissionExpense
			SET @MarginAmount = ISNULL((SELECT SUM(ISNULL(MarginAmount,0)) FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) WHERE LCD.LotId = @LotId AND REPLACE([Type],' ','') = REPLACE(@LOT_TransOut_SO,' ','') ),0);
			SET @MarginPercent = CASE WHEN @RevenueCost >0 THEN (CONVERT(DECIMAL(18,2),(@MarginAmount/@RevenueCost)*100)) ELSE 0 END
			--SET @LotCostRemaining = (@TotalLotCost - @CogsPartCost)
			SET @LotCostRemaining = (CASE WHEN @TotalLotCost - (@TransferredOutCost + @SoldCost) <0 THEN 0 ELSE (@TotalLotCost - (@TransferredOutCost + @SoldCost)) END)
			SET @RemainingCostPercentage = (CASE WHEN @TotalLotCost > 0 THEN ((@LotCostRemaining / @TotalLotCost) * 100) ELSE 0 END)
			SELECT 
				ISNULL(@OriginalCost,0) AS OriginalCost
			   ,ISNULL(@RepairCost,0) AS RepairCost
			   ,ISNULL(@TransferredInCost,0) AS TransferredInCost
			   ,ISNULL(@TransferredOutCost,0) AS TransferredOutCost
			   ,ISNULL(@SoldCost,0) AS SoldCost
			   ,ISNULL(@OtherCost,0) AS OtherCost
			   ,CASE WHEN ISNULL(@TotalLotCost,0) <0 THEN 0 ELSE ISNULL(@TotalLotCost,0) END AS TotalLotCost
			   ,CASE WHEN ISNULL(@LotCostRemaining,0) < 0 THEN 0 ELSE ISNULL(@LotCostRemaining,0) END AS LotCostRemaining   
				,ISNULL(@RemainingCostPercentage,0) AS RemainingCostPercentage
			   
			   ,ISNULL(@RevenueCost,0) AS RevenueCost
			   ,ISNULL(@CogsPartCost,0) AS CogsPartCost
			   ,ISNULL(@CommissionExpense,0) AS CommissionExpense
			   ,ISNULL(@TotalExpense,0) AS TotalExpense
			   ,CASE WHEN ISNULL(@MarginAmount,0) <0 THEN 0 ELSE ISNULL(@MarginAmount,0) END AS MarginAmount
			   ,ISNULL(@MarginPercent,0) AS MarginPercent
	
			   ,ISNULL(@OtherSalesExpenses,0) AS OtherSalesExpenses

			   
			   ,@OriginalCostUnit AS OriginalCostUnit
			   ,@RepairCostUnit AS RepairCostUnit
			   ,@TransferredInCostUnit AS TransferredInCostUnit
			   ,@TransferredOutCostUnit AS TransferredOutCostUnit
			   ,@OtherCostUnit AS OtherCostUnit
			   ,@RevenueCostUnit AS RevenueCostUnit
			   ,@CogsPartCostUnit AS CogsPartCostUnit
			   ,@CommissionExpenseUnit AS CommissionExpenseUnit
			   ,@TotalExpenseUnit AS TotalExpenseUnit

			   ,CASE WHEN @LotCostRemainingUnit <0 THEN 0 ELSE @LotCostRemainingUnit END AS LotCostRemainingUnit
				
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_Lot_GetLotSummaryByLotId]',
            @ProcedureParameters varchar(3000) = '@LotId = ''' + CAST(ISNULL(@LotId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END