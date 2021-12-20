




/*************************************************************           
 ** File:   [USP_GetSOQApprovalList]          
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

EXEC [dbo].[USP_GetSOQApprovalList]  71
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetSOQApprovalList] 
(
	@SalesOrderQuoteId BIGINT = NULL
)
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON

    BEGIN TRY
    BEGIN TRANSACTION
      BEGIN
		
		IF OBJECT_ID(N'tempdb..#tmpSalesOrderQuotePart') IS NOT NULL
		BEGIN
			DROP TABLE #tmpSalesOrderQuotePart
		END

		CREATE TABLE #tmpSalesOrderQuotePart (
			SalesOrderQuotePartId BIGINT,
			SalesOrderQuoteId BIGINT, 
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
			SELECT MIN(SalesOrderQuotePartId) SalesOrderQuotePartId, SalesOrderQuoteId, ItemMasterId, ConditionId, SUM(QtyQuoted) Qty,
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
			FROM DBO.SalesOrderQuotePart soqp WITH (NOLOCK) WHERE IsActive = 1 AND IsDeleted = 0 AND SalesOrderQuoteId = @SalesOrderQuoteId
			GROUP BY ItemMasterId, ConditionId, SalesOrderQuoteId
		)  
		INSERT INTO #tmpSalesOrderQuotePart
		SELECT SalesOrderQuotePartId, SalesOrderQuoteId, ItemMasterId, ConditionId, Qty,
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
			soq.SalesOrderQuoteNumber,
			soq.Version,
			soq.CustomerId,
			soqp.SalesOrderQuotePartId AS SalesOrderQuotePartId,
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
			sqp.SalesOrderQuoteApprovalId AS SalesOrderQuoteApprovalId,
			sqp.InternalApprovedById AS InternalApprovedById,
			sqp.CustomerApprovedById AS CustomerApprovedById,
			sqp.RejectedById,
			sqp.RejectedByName,
			sqp.RejectedDate,
			sqp.InternalRejectedById,
			sqp.InternalRejectedByName,
			sqp.InternalRejectedDate,
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
			(SELECT SUM(BillingAmount) FROM DBO.SalesOrderQuoteCharges WITH (NOLOCK) WHERE SalesOrderQuoteId = soq.SalesOrderQuoteId AND IsActive = 1 AND IsDeleted = 0 AND SalesOrderQuotePartId = soqp.SalesOrderQuotePartId) IS NULL THEN 
			0 ELSE 
			(SELECT SUM(BillingAmount) FROM DBO.SalesOrderQuoteCharges WITH (NOLOCK) WHERE SalesOrderQuoteId = soq.SalesOrderQuoteId AND IsActive = 1 AND IsDeleted = 0 AND SalesOrderQuotePartId = soqp.SalesOrderQuotePartId) END) AS TotalSales,
			soq.IsEnforceApproval,
			soq.EnforceEffectiveDate
		FROM SalesOrderQuote soq WITH (NOLOCK)
		INNER JOIN #tmpSalesOrderQuotePart soqp ON soq.SalesOrderQuoteId = soqp.SalesOrderQuoteId
		INNER JOIN SalesOrderQuotePart sop WITH (NOLOCK) ON sop.SalesOrderQuotePartId = soqp.SalesOrderQuotePartId
		LEFT JOIN SalesOrderQuoteApproval sqp WITH (NOLOCK) ON soqp.SalesOrderQuotePartId = sqp.SalesOrderQuotePartId
		LEFT JOIN ItemMaster im WITH (NOLOCK) ON soqp.ItemMasterId = im.ItemMasterId
		LEFT JOIN Employee app WITH (NOLOCK) ON sqp.InternalApprovedById = app.EmployeeId
		LEFT JOIN Contact con WITH (NOLOCK) ON sqp.CustomerApprovedById = con.ContactId
		WHERE soq.IsDeleted = 0 AND sop.IsDeleted = 0 AND soq.SalesOrderQuoteId = @SalesOrderQuoteId

	  END
    COMMIT TRANSACTION

  END TRY
  BEGIN CATCH
    IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments varchar(150) = 'USP_GetSOQApprovalList'
		,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@SalesOrderQuoteId, '') + ''
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