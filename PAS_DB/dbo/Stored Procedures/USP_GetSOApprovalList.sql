



/*************************************************************           
 ** File:   [USP_GetSOApprovalList]          
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get SO approval list
 ** Purpose:         
 ** Date:   10/08/2021        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author    Change Description            
 ** --   --------     -------		--------------------------------          
    1    10/08/2021   Vishal Suthar Created

EXEC [dbo].[USP_GetSOApprovalList]  126
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetSOApprovalList] 
(
	@SalesOrderId BIGINT = NULL
)
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON

    BEGIN TRY
    BEGIN TRANSACTION
      BEGIN
		IF OBJECT_ID(N'tempdb..#tmpSalesOrderPart') IS NOT NULL
		BEGIN
			DROP TABLE #tmpSalesOrderPart
		END

		CREATE TABLE #tmpSalesOrderPart (
			SalesOrderPartId BIGINT,
			SalesOrderId BIGINT, 
			ItemMasterId BIGINT, 
			ConditionId BIGINT, 
			Qty INT,
			UnitSalePrice NUMERIC(9, 2),
			MarkUpPercentage INT,
			SalesBeforeDiscount  NUMERIC(9, 2),
			Discount INT,
			DiscountAmount  NUMERIC(9, 2),
			NetSales  NUMERIC(9, 2),
			UnitCost  NUMERIC(9, 2),
			SalesPriceExtended  NUMERIC(9, 2),
			MarkupExtended  NUMERIC(9, 2),
			SalesDiscountExtended  NUMERIC(9, 2),
			NetSalePriceExtended  NUMERIC(9, 2),
			UnitCostExtended  NUMERIC(9, 2),
			MarginAmount  NUMERIC(9, 2),
			MarginAmountExtended NUMERIC(9, 2),
			MarginPercentage  NUMERIC(9, 2),
			TaxAmount  NUMERIC(9, 2),
			TaxPercentage  NUMERIC(9, 2),
			TotalSales  NUMERIC(9, 2))

		;WITH cte AS
		(
			SELECT MIN(SalesOrderPartId) SalesOrderPartId, SalesOrderId, ItemMasterId, ConditionId, SUM(Qty) Qty,
			SUM(UnitSalePrice) UnitSalePrice,
			SUM(MarkUpPercentage) MarkUpPercentage,
			SUM(SalesBeforeDiscount) SalesBeforeDiscount,
			SUM(Discount) Discount,
			SUM(DiscountAmount) DiscountAmount,
			SUM(NetSales) NetSales,
			SUM(UnitCost) UnitCost,
			SUM(SalesPriceExtended) SalesPriceExtended,
			SUM(MarkupExtended) MarkupExtended,
			SUM(SalesDiscountExtended) SalesDiscountExtended,
			SUM(NetSalePriceExtended) NetSalePriceExtended,
			SUM(UnitCostExtended) UnitCostExtended,
			SUM(MarginAmount) MarginAmount,
			SUM(MarginAmountExtended) MarginAmountExtended,
			SUM(MarginPercentage) MarginPercentage,
			SUM(TaxAmount) TaxAmount,
			SUM(TaxPercentage) TaxPercentage,
			SUM(soqp.NetSales) + SUM(soqp.TaxAmount) + 
			0 AS TotalSales
			FROM DBO.SalesOrderPart soqp WHERE IsDeleted = 0 AND IsDeleted = 0 AND SalesOrderId = @SalesOrderId
			GROUP BY ItemMasterId, ConditionId, SalesOrderId
		)  
		INSERT INTO #tmpSalesOrderPart
		SELECT SalesOrderPartId, SalesOrderId, ItemMasterId, ConditionId, Qty,
			UnitSalePrice,
			MarkUpPercentage,
			SalesBeforeDiscount,
			Discount,
			DiscountAmount,
			NetSales,
			UnitCost,
			SalesPriceExtended,
			MarkupExtended,
			SalesDiscountExtended,
			NetSalePriceExtended,
			UnitCostExtended,
			MarginAmount,
			MarginAmountExtended,
			MarginPercentage,
			TaxAmount,
			TaxPercentage,
			TotalSales
		FROM cte

		SELECT soq.SalesOrderQuoteId,
			soq.SalesOrderNumber,
			soq.Version,
			soq.CustomerId,
			soq.SalesOrderId AS SalesOrderId,
			soqp.SalesOrderPartId AS SalesOrderPartId,
			sop.SalesOrderQuotePartId AS SalesOrderQuotePartId,
			sop.ItemMasterId AS ItemMasterId,
			im.PartNumber AS PartNumber,
			im.PartDescription AS PartDescription,
			soq.OpenDate,
			soq.CreatedDate,
			soq.ApprovedDate,
			soq.StatusChangeDate,
			sop.StockLineId AS StockLineId,
			sop.MethodType AS MethodType,
			sqp.InternalApprovedDate,
			sqp.InternalSentDate,
			app.FirstName + ' ' + app. LastName AS InternalApprovedBy,
			sqp.CustomerApprovedDate,
			sqp.CustomerSentDate,
			con.FirstName + ' ' + con.LastName AS CustomerApprovedBy,
			sqp.SalesOrderApprovalId AS SalesOrderApprovalId,
			sqp.InternalApprovedById AS InternalApprovedById,
			sqp.CustomerApprovedById AS CustomerApprovedById,
			sqp.RejectedById,
			sqp.RejectedByName,
			sqp.RejectedDate,
			sqp.InternalMemo,
			sqp.CustomerMemo,
			sqp.CreatedBy,
			sqp.UpdatedBy,
			sqp.UpdatedDate,
			1 AS IsActive,
			0 AS IsDeleted,
			sqp.ApprovalActionId AS ApprovalActionId,
			sqp.ApprovalActionId AS ActionStatus,
			sqp.InternalStatusId AS InternalStatusId,
			CASE WHEN sqp.CustomerStatusId IS null THEN 1 ELSE sqp.CustomerStatusId END AS CustomerStatusId,
			1 AS IsInternalApprove,
			soqp.Qty,
			soqp.UnitSalePrice,
			soqp.MarkUpPercentage,
			soqp.SalesBeforeDiscount,
			soqp.Discount,
			soqp.DiscountAmount,
			soqp.NetSales,
			soqp.UnitCost,
			soqp.SalesPriceExtended,
			soqp.MarkupExtended,
			soqp.SalesDiscountExtended,
			soqp.NetSalePriceExtended,
			soqp.UnitCostExtended,
			soqp.MarginAmount,
			soqp.MarginAmountExtended,
			soqp.MarginPercentage,
			soqp.TaxAmount,
			soqp.TaxPercentage,
			sop.TaxType,
			soqp.NetSales + soqp.TaxAmount + 
			(CASE WHEN
			(SELECT SUM(BillingAmount) FROM DBO.SalesOrderCharges WHERE SalesOrderId = soq.SalesOrderId AND IsActive = 1 AND IsDeleted = 0 AND SalesOrderPartId = soqp.SalesOrderPartId) IS NULL THEN 
			0 ELSE 
			(SELECT SUM(BillingAmount) FROM DBO.SalesOrderCharges WHERE SalesOrderId = soq.SalesOrderId AND IsActive = 1 AND IsDeleted = 0 AND SalesOrderPartId = soqp.SalesOrderPartId) END) AS TotalSales,
			soq.IsEnforceApproval,
			soq.EnforceEffectiveDate
		FROM SalesOrder soq
		INNER JOIN #tmpSalesOrderPart soqp ON soq.SalesOrderId = soqp.SalesOrderId
		INNER JOIN SalesOrderPart sop ON sop.SalesOrderPartId = soqp.SalesOrderPartId
		LEFT JOIN SalesOrderApproval sqp ON soqp.SalesOrderPartId = sqp.SalesOrderPartId
		LEFT JOIN ItemMaster im ON soqp.ItemMasterId = im.ItemMasterId
		LEFT JOIN Employee app ON sqp.InternalApprovedById = app.EmployeeId
		LEFT JOIN Contact con ON sqp.CustomerApprovedById = con.ContactId
		WHERE sop.IsDeleted = 0 AND sop.IsDeleted = 0 AND soq.SalesOrderId = @SalesOrderId
	  END
    COMMIT TRANSACTION

  END TRY
  BEGIN CATCH
    IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments varchar(150) = 'USP_GetSOApprovalList'
		,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@SalesOrderId, '') + ''
		,@ApplicationName varchar(100) = 'PAS'
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