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
    2    01/04/2022   Vishal Suthar Added Internal Sent fields
    3    09/27/2024   Vishal Suthar Modified the query to use new so part tables
	4    21/jul/2025  Bhargav Saliya  Select UOM
	5    28/Aug/2025  Amit Ghediya		Select Condition
	6    05/01/2026   Moin Bloch		UOM Related Changes
	7    07/01/2026   Rajesh Gami		Added MasterCompanyId Parameter While Calling UOM Conversion Function
	8    11/05/2026   Bhargav Saliya	Modified UOM Related Changes [PN-16192]
	9    18/06/2026   Bhargav Saliya	Added Case For Skip UOM Function If FROM uom and TO uom Both are Same
	10   29/06/2026   Bhargav saliya    Already saved extended margin amt in table so no need to calculate with qty
	11    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	12    20/July/2026			 RAJESH GAMI						[PN-17350] - Removed IsNonStock=0 filter from ItemMaster LEFT JOIN so Non-Stock parts show full details in the SO approval list.
	13   09/07/2026   Bhargav Saliya    Get Consume UOM [PN-17163]
EXEC [dbo].[USP_GetSOApprovalList]  1266
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
		--IF OBJECT_ID(N'tempdb..#tmpSalesOrderPart') IS NOT NULL
		--BEGIN
		--	DROP TABLE #tmpSalesOrderPart
		--END

		-- CREATE TABLE #tmpSalesOrderPart (
		-- 	SalesOrderPartId BIGINT,
		-- 	SalesOrderId BIGINT, 
		-- 	ItemMasterId BIGINT, 
		-- 	ConditionId BIGINT, 
		-- 	Qty INT,
		-- 	UnitSalePrice NUMERIC(9, 2),
		-- 	MarkUpPercentage INT,
		-- 	SalesBeforeDiscount   NUMERIC(9, 2),
		-- 	Discount INT,
		-- 	DiscountAmount   NUMERIC(9, 2),
		-- 	NetSales   NUMERIC(9, 2),
		-- 	UnitCost   NUMERIC(9, 2),
		-- 	SalesPriceExtended   NUMERIC(9, 2),
		-- 	MarkupExtended   NUMERIC(9, 2),
		-- 	SalesDiscountExtended   NUMERIC(9, 2),
		-- 	NetSalePriceExtended   NUMERIC(9, 2),
		-- 	UnitCostExtended   NUMERIC(9, 2),
		-- 	MarginAmount   NUMERIC(9, 2),
		-- 	MarginAmountExtended NUMERIC(9, 2),
		-- 	MarginPercentage   NUMERIC(9, 2),
		-- 	TaxAmount   NUMERIC(9, 2),
		-- 	TaxPercentage   NUMERIC(9, 2),
		-- 	TotalSales   NUMERIC(9, 2))

		-- ;WITH cte AS
		-- (
		-- 	SELECT MIN(SalesOrderPartId) SalesOrderPartId, SalesOrderId, ItemMasterId, ConditionId, SUM(Qty) Qty,
		-- 	SUM(UnitSalePrice) UnitSalePrice,
		-- 	SUM(MarkUpPercentage) MarkUpPercentage,
		-- 	SUM(SalesBeforeDiscount) SalesBeforeDiscount,
		-- 	SUM(Discount) Discount,
		-- 	SUM(DiscountAmount) DiscountAmount,
		-- 	SUM(NetSales) NetSales,
		-- 	SUM(UnitCost) UnitCost,
		-- 	SUM(SalesPriceExtended) SalesPriceExtended,
		-- 	SUM(MarkupExtended) MarkupExtended,
		-- 	SUM(SalesDiscountExtended) SalesDiscountExtended,
		-- 	SUM(NetSalePriceExtended) NetSalePriceExtended,
		-- 	SUM(UnitCostExtended) UnitCostExtended,
		-- 	SUM(MarginAmount) MarginAmount,
		-- 	SUM(MarginAmountExtended) MarginAmountExtended,
		-- 	SUM(MarginPercentage) MarginPercentage,
		-- 	SUM(TaxAmount) TaxAmount,
		-- 	SUM(TaxPercentage) TaxPercentage,
		-- 	SUM(soqp.NetSales) + SUM(soqp.TaxAmount) + 
		-- 	0 AS TotalSales
		-- 	FROM DBO.SalesOrderPart soqp WHERE IsDeleted = 0 AND IsDeleted = 0 AND SalesOrderId = @SalesOrderId
		-- 	GROUP BY ItemMasterId, ConditionId, SalesOrderId
		-- )   
		-- INSERT INTO #tmpSalesOrderPart
		-- SELECT SalesOrderPartId, SalesOrderId, ItemMasterId, ConditionId, Qty,
		-- 	UnitSalePrice,
		-- 	MarkUpPercentage,
		-- 	SalesBeforeDiscount,
		-- 	Discount,
		-- 	DiscountAmount,
		-- 	NetSales,
		-- 	UnitCost,
		-- 	SalesPriceExtended,
		-- 	MarkupExtended,
		-- 	SalesDiscountExtended,
		-- 	NetSalePriceExtended,
		-- 	UnitCostExtended,
		-- 	MarginAmount,
		-- 	MarginAmountExtended,
		-- 	MarginPercentage,
		-- 	TaxAmount,
		-- 	TaxPercentage,
		-- 	TotalSales
		-- FROM cte

		-- SELECT soq.SalesOrderQuoteId,
		-- 	soq.SalesOrderNumber,
		-- 	soq.Version,
		-- 	soq.CustomerId,
		-- 	soq.SalesOrderId AS SalesOrderId,
		-- 	soqp.SalesOrderPartId AS SalesOrderPartId,
		-- 	sop.SalesOrderQuotePartId AS SalesOrderQuotePartId,
		-- 	sop.ItemMasterId AS ItemMasterId,
		-- 	im.PartNumber AS PartNumber,
		-- 	im.PartDescription AS PartDescription,
		-- 	soq.OpenDate,
		-- 	soq.CreatedDate,
		-- 	soq.ApprovedDate,
		-- 	soq.StatusChangeDate,
		-- 	sop.StockLineId AS StockLineId,
		-- 	sop.MethodType AS MethodType,
		-- 	sqp.InternalApprovedDate,
		-- 	sqp.InternalSentDate,
		-- 	app.FirstName + ' ' + app. LastName AS InternalApprovedBy,
		-- 	sqp.CustomerApprovedDate,
		-- 	sqp.CustomerSentDate,
		-- 	con.FirstName + ' ' + con.LastName AS CustomerApprovedBy,
		-- 	sqp.SalesOrderApprovalId AS SalesOrderApprovalId,
		-- 	sqp.InternalApprovedById AS InternalApprovedById,
		-- 	sqp.CustomerApprovedById AS CustomerApprovedById,
		-- 	sqp.RejectedById,
		-- 	sqp.RejectedByName,
		-- 	sqp.RejectedDate,
		-- 	sqp.InternalRejectedById,
		-- 	sqp.InternalRejectedByName,
		-- 	sqp.InternalRejectedDate,
		-- 	sqp.InternalSentToId,
		-- 	sqp.InternalSentToName,
		-- 	sqp.InternalSentById,
		-- 	sqp.InternalMemo,
		-- 	sqp.CustomerMemo,
		-- 	sqp.CreatedBy,
		-- 	sqp.UpdatedBy,
		-- 	sqp.UpdatedDate,
		-- 	1 AS IsActive,
		-- 	0 AS IsDeleted,
		-- 	sqp.ApprovalActionId AS ApprovalActionId,
		-- 	sqp.ApprovalActionId AS ActionStatus,
		-- 	sqp.InternalStatusId AS InternalStatusId,
		-- 	CASE WHEN sqp.CustomerStatusId IS null THEN 1 ELSE sqp.CustomerStatusId END AS CustomerStatusId,
		-- 	1 AS IsInternalApprove,
		-- 	soqp.Qty,
		-- 	soqp.UnitSalePrice,
		-- 	soqp.MarkUpPercentage,
		-- 	soqp.SalesBeforeDiscount,
		-- 	soqp.Discount,
		-- 	soqp.DiscountAmount,
		-- 	soqp.NetSales,
		-- 	soqp.UnitCost,
		-- 	soqp.SalesPriceExtended,
		-- 	soqp.MarkupExtended,
		-- 	soqp.SalesDiscountExtended,
		-- 	soqp.NetSalePriceExtended,
		-- 	soqp.UnitCostExtended,
		-- 	soqp.MarginAmount,
		-- 	soqp.MarginAmountExtended,
		-- 	soqp.MarginPercentage,
		-- 	soqp.TaxAmount,
		-- 	soqp.TaxPercentage,
		-- 	sop.TaxType,
		-- 	soqp.NetSales + soqp.TaxAmount + 
		-- 	(CASE WHEN
		-- 	(SELECT SUM(BillingAmount) FROM DBO.SalesOrderCharges WHERE SalesOrderId = soq.SalesOrderId AND IsActive = 1 AND IsDeleted = 0 AND SalesOrderPartId = soqp.SalesOrderPartId) IS NULL THEN 
		-- 	0 ELSE 
		-- 	(SELECT SUM(BillingAmount) FROM DBO.SalesOrderCharges WHERE SalesOrderId = soq.SalesOrderId AND IsActive = 1 AND IsDeleted = 0 AND SalesOrderPartId = soqp.SalesOrderPartId) END) AS TotalSales,
		-- 	soq.IsEnforceApproval,
		-- 	soq.EnforceEffectiveDate
		-- 	FROM SalesOrder soq
		-- 	INNER JOIN #tmpSalesOrderPart soqp ON soq.SalesOrderId = soqp.SalesOrderId
		-- 	INNER JOIN SalesOrderPart sop ON sop.SalesOrderPartId = soqp.SalesOrderPartId
		-- 	LEFT JOIN SalesOrderApproval sqp ON soqp.SalesOrderPartId = sqp.SalesOrderPartId
		-- 	LEFT JOIN ItemMaster im ON soqp.ItemMasterId = im.ItemMasterId
		-- 	LEFT JOIN Employee app ON sqp.InternalApprovedById = app.EmployeeId
		-- 	LEFT JOIN Contact con ON sqp.CustomerApprovedById = con.ContactId
		-- 	WHERE sop.IsDeleted = 0 AND sop.IsDeleted = 0 AND soq.SalesOrderId = @SalesOrderId;


			SELECT DISTINCT so.SalesOrderId,
				so.SalesOrderNumber,
				so.Version,
				so.CustomerId,
				sop.SalesOrderPartId AS SalesOrderPartId,
				sop.ItemMasterId AS ItemMasterId,
				im.PartNumber AS PartNumber,
				im.PartDescription AS PartDescription,
				NULL AS StocklineId,
				so.OpenDate,
				so.CreatedDate,
				so.ApprovedDate,
				so.StatusChangeDate,
				'I' AS MethodType,
				sp.InternalApprovedDate,
				sp.InternalSentDate,
				app.FirstName + ' ' + app. LastName AS InternalApprovedBy,
				sp.CustomerApprovedDate,
				sp.CustomerSentDate,
				con.FirstName + ' ' + con.LastName AS CustomerApprovedBy,
				sp.SalesOrderApprovalId AS SalesOrderApprovalId,
				sp.InternalApprovedById AS InternalApprovedById,
				sp.CustomerApprovedById AS CustomerApprovedById,
				sp.RejectedById,
				sp.RejectedByName,
				sp.RejectedDate,
				sp.InternalRejectedById,
				sp.InternalRejectedByName,
				sp.InternalRejectedDate,
				sp.InternalSentToId,
				sp.InternalSentToName,
				sp.InternalSentById,
				sp.InternalMemo,
				sp.CustomerMemo,
				sp.CreatedBy,
				sp.UpdatedBy,
				sp.UpdatedDate,
				1 AS IsActive,
				0 AS IsDeleted,
				sp.ApprovalActionId AS ApprovalActionId,
				sp.ApprovalActionId AS ActionStatus,
				sp.InternalStatusId AS InternalStatusId,
				CASE WHEN sp.CustomerStatusId IS null THEN 1 ELSE sp.CustomerStatusId END AS CustomerStatusId,
				1 AS IsInternalApprove,
				--sop.QtyOrder Qty,
				ISNULL((CASE WHEN ISNULL(im.[StockUnitOfMeasure],'') = ISNULL(im.[ConsumeUnitOfMeasure],'') THEN ISNULL(sop.[QtyOrder],0) ELSE [dbo].[fn_ConvertUOM](ISNULL(sop.[QtyOrder],0), im.[StockUnitOfMeasure], im.[ConsumeUnitOfMeasure], 0, so.MasterCompanyId) END),0) Qty,
				--sopc.UnitSalesPrice UnitSalePrice,
				ISNULL((CASE WHEN ISNULL(im.[StockUnitOfMeasure],'') = ISNULL(im.[ConsumeUnitOfMeasure],'') THEN ISNULL(sopc.[UnitSalesPrice],0) ELSE [dbo].[fn_ConvertUOM](ISNULL(sopc.[UnitSalesPrice],0), im.[StockUnitOfMeasure], im.[ConsumeUnitOfMeasure], 1, so.MasterCompanyId) END),0) UnitSalePrice,
				sopc.MarkUpPercentage,
				0 SalesBeforeDiscount,
				sopc.DiscountPercentage Discount,
				--sopc.DiscountAmount,
				ISNULL(sopc.DiscountAmount, 0) DiscountAmount,
				--sopc.NetSaleAmount NetSales,
				ISNULL(sopc.NetSaleAmount, 0) NetSales,
				--sopc.UnitCost,
				ISNULL((CASE WHEN ISNULL(im.[StockUnitOfMeasure],'') = ISNULL(im.[ConsumeUnitOfMeasure],'') THEN ISNULL(sopc.[UnitCost],0) ELSE [dbo].[fn_ConvertUOM](ISNULL(sopc.[UnitCost],0), im.[StockUnitOfMeasure], im.[ConsumeUnitOfMeasure], 1, so.MasterCompanyId) END),0) UnitCost,
				--sopc.UnitSalesPriceExtended SalesPriceExtended,
				ISNULL(sopc.UnitSalesPriceExtended, 0) SalesPriceExtended,
				--sopc.MarkUpAmount MarkupExtended,
				ISNULL(sopc.MarkUpAmount, 0) MarkupExtended,
				--sopc.DiscountAmount SalesDiscountExtended,
				ISNULL(sopc.DiscountAmount, 0) SalesDiscountExtended,
				--sopc.NetSaleAmount NetSalePriceExtended,
				ISNULL(sopc.NetSaleAmount, 0) NetSalePriceExtended,
				--sopc.UnitCostExtended,
				ISNULL(sopc.UnitCostExtended, 0) UnitCostExtended,
				--sopc.MarginAmount,
				ISNULL((CASE WHEN ISNULL(im.[StockUnitOfMeasure],'') = ISNULL(im.[ConsumeUnitOfMeasure],'') THEN ISNULL(sopc.[MarginAmount],0) ELSE [dbo].[fn_ConvertUOM](ISNULL(sopc.[MarginAmount],0), im.[StockUnitOfMeasure], im.[ConsumeUnitOfMeasure], 1, so.MasterCompanyId) END),0) MarginAmount,
				--sopc.MarginAmount AS MarginAmountExtended,
				ISNULL((CASE WHEN ISNULL(im.[StockUnitOfMeasure],'') = ISNULL(im.[ConsumeUnitOfMeasure],'') THEN ISNULL(sopc.[MarginAmount],0) ELSE [dbo].[fn_ConvertUOM](ISNULL(sopc.[MarginAmount],0), im.[StockUnitOfMeasure], im.[ConsumeUnitOfMeasure], 1, so.MasterCompanyId) END), 0) MarginAmountExtended,
				sopc.MarginPercentage,
				--sopc.TaxAmount,
				ISNULL((CASE WHEN ISNULL(im.[StockUnitOfMeasure],'') = ISNULL(im.[ConsumeUnitOfMeasure],'') THEN ISNULL(sopc.[TaxAmount],0) ELSE [dbo].[fn_ConvertUOM](ISNULL(sopc.[TaxAmount],0), im.[StockUnitOfMeasure], im.[ConsumeUnitOfMeasure], 1, so.MasterCompanyId) END),0) TaxAmount,
				sopc.TaxPercentage,
				--sop.TaxType,
				'' AS TaxType,
				--sopc.NetSaleAmount + sopc.TaxAmount + 
				ISNULL(sopc.NetSaleAmount, 0)
				+ ISNULL((CASE WHEN ISNULL(im.[StockUnitOfMeasure],'') = ISNULL(im.[ConsumeUnitOfMeasure],'') THEN ISNULL(sopc.[TaxAmount],0) ELSE [dbo].[fn_ConvertUOM](ISNULL(sopc.[TaxAmount],0), im.[StockUnitOfMeasure], im.[ConsumeUnitOfMeasure], 1, so.MasterCompanyId) END),0)
				+ (CASE WHEN
				(SELECT SUM(BillingAmount) FROM DBO.SalesOrderCharges WITH (NOLOCK) WHERE SalesOrderId = so.SalesOrderId AND IsActive = 1 AND IsDeleted = 0 AND SalesOrderPartId = sop.SalesOrderPartId) IS NULL THEN 
				0 ELSE 
				(SELECT SUM(BillingAmount) FROM DBO.SalesOrderCharges WITH (NOLOCK) WHERE SalesOrderId = so.SalesOrderId AND IsActive = 1 AND IsDeleted = 0 AND SalesOrderPartId = sop.SalesOrderPartId) END) AS TotalSales,
				so.IsEnforceApproval,
				so.EnforceEffectiveDate,
				ISNULL(um.ShortName, '') AS UomName,
				ISNULL(UPPER(cond.[Description]),'') AS Condition
		FROM DBO.SalesOrder so WITH (NOLOCK)
		INNER JOIN DBO.SalesOrderPartV1 sop ON so.SalesOrderId = sop.SalesOrderId
		INNER JOIN DBO.SalesOrderPartCost sopc ON sopc.SalesOrderPartId = sop.SalesOrderPartId
		LEFT JOIN DBO.SalesOrderApproval sp WITH (NOLOCK) ON sop.SalesOrderPartId = sp.SalesOrderPartId AND sp.SalesOrderId = @SalesOrderId
		LEFT JOIN DBO.ItemMaster im WITH (NOLOCK) ON sop.ItemMasterId = im.ItemMasterId
		 LEFT JOIN DBO.UnitOfMeasure um WITH (NOLOCK) ON im.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
		LEFT JOIN DBO.Employee app WITH (NOLOCK) ON sp.InternalApprovedById = app.EmployeeId
		LEFT JOIN DBO.Contact con WITH (NOLOCK) ON sp.CustomerApprovedById = con.ContactId
		LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON sop.ConditionId = cond.ConditionId
			WHERE so.IsDeleted = 0 AND sop.IsDeleted = 0 AND so.SalesOrderId = @SalesOrderId;

		    END
        COMMIT TRANSACTION

    END TRY
    BEGIN CATCH
        IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		, @DatabaseName varchar(100) = DB_NAME()
                ----------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------
		, @AdhocComments varchar(150) = 'USP_GetSOApprovalList' 	
		, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderId, '') AS VARCHAR(100)) 
		, @ApplicationName varchar(100) = 'PAS'
		---------PLEASE DO NOT EDIT BELOW---------
		EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END