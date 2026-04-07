/*************************************************************           
 ** File:   [USP_GetSOQPartsViewForDuplicate]           
 ** Author:   Vishal Suthar
 ** Description: Get Sales Order Quote Parts View For Duplicate
 ** Purpose:         
 ** Date:   04-Apr-2026  
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date          Author          Change Description            
 ** --   --------      -------         --------------------------------          
    1    04-Apr-2026   Vishal Suthar   Created
     
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSOQPartsViewForDuplicate]
    @SalesOrderQuoteId    BIGINT,
    @CurrencyDisplayName  NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        SELECT
            part.SalesOrderQuotePartId,
            part.SalesOrderQuoteId,
            part.ItemMasterId,
            stk.StockLineId,
            qs.StockLineNumber,
            part.FxRate,
            part.QtyQuoted,
            UnitSalePrice        = ISNULL(partc.UnitSalesPrice,         0),
            MarkUpPercentage     = ISNULL(partc.MarkUpPercentage,       0),
            SalesBeforeDiscount  = ISNULL(partc.GrossSaleAmount,        0),
            Discount             = ISNULL(partc.DiscountAmount,         0),
            DiscountAmount       = ISNULL(partc.DiscountAmount,         0),
            NetSales             = ISNULL(partc.NetSaleAmount,          0),
            part.MasterCompanyId,
            part.CreatedBy,
            part.CreatedDate,
            part.UpdatedBy,
            part.UpdatedDate,
            PartNumber           = im.PartNumber,
            PartDescription      = im.PartDescription,
            IsOEM                = ISNULL(qs.OEM,    0),
            IsPMA                = ISNULL(im.IsPma,  0),
            IsDER                = ISNULL(im.IsDER,  0),
            MethodType           = CASE WHEN stk.SalesOrderQuotePartId IS NOT NULL THEN 'S' ELSE 'I' END,
            SerialNumber         = ISNULL(qs.SerialNumber,  ''),
            UnitCost             = ISNULL(partc.UnitCost,               0),
            SalesPriceExtended   = ISNULL(partc.UnitSalesPriceExtended, 0),
            MarkupExtended       = ISNULL(partc.MarkUpAmount,           0),
            SalesDiscountExtended = ISNULL(partc.DiscountAmount,        0),
            NetSalePriceExtended = ISNULL(partc.NetSaleAmount,          0),
            UnitCostExtended     = ISNULL(partc.UnitCostExtended,       0),
            MarginAmount         = ISNULL(partc.MarginAmount,           0),
            MarginAmountExtended = ISNULL(partc.MarginAmount,           0),
            MarginPercentage     = ISNULL(partc.MarginPercentage,       0),
            CurrencyDescription  = @CurrencyDisplayName,
            ConditionId          = ISNULL(cond.ConditionId,             -1),
            ConditionDescription = ISNULL(cond.Description,            ''),
            part.QtyRequested,
            part.PriorityId,
            part.CustomerRequestDate,
            part.EstimatedShipDate,
            part.PromisedDate,
            part.StatusId,
            part.Notes,
            MarkupPerUnit        = ISNULL(partc.MarkUpAmount,           0),
            GrossSalePrice       = ISNULL(partc.GrossSaleAmount,        0),
            TaxPercentage        = ISNULL(partc.TaxPercentage,          0),
            TaxAmount            = ISNULL(partc.TaxAmount,              0),
            part.CurrencyId,
            ControlNumber        = ISNULL(qs.ControlNumber, ''),
            IdNumber             = ISNULL(qs.IdNumber,      '')
        FROM dbo.SalesOrderQuotePartV1 part WITH (NOLOCK)
        LEFT  JOIN dbo.SalesOrderQuoteStocklineV1 stk  WITH (NOLOCK) ON part.SalesOrderQuotePartId = stk.SalesOrderQuotePartId
        INNER JOIN dbo.SalesOrderQuotePartCost partc   WITH (NOLOCK) ON part.SalesOrderQuotePartId = partc.SalesOrderQuotePartId
        LEFT  JOIN dbo.StockLine qs                    WITH (NOLOCK) ON stk.StockLineId = qs.StockLineId
        INNER JOIN dbo.ItemMaster im                   WITH (NOLOCK) ON part.ItemMasterId = im.ItemMasterId
        LEFT  JOIN dbo.Condition cond                  WITH (NOLOCK) ON part.ConditionId = cond.ConditionId
        INNER JOIN dbo.SalesOrderQuoteApproval papr    WITH (NOLOCK) ON part.SalesOrderQuotePartId = papr.SalesOrderQuotePartId
        WHERE part.SalesOrderQuoteId = @SalesOrderQuoteId AND part.IsDeleted = 0;

    END TRY
    BEGIN CATCH

        DECLARE @ErrorLogID INT
            ,@DatabaseName VARCHAR(100) = db_name()
            ,@AdhocComments VARCHAR(150) = 'USP_GetSOQPartsViewForDuplicate'
            ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderQuoteId, '') AS VARCHAR(100))
            ,@ApplicationName VARCHAR(100) = 'PAS'

        EXEC spLogException @DatabaseName = @DatabaseName
            ,@AdhocComments = @AdhocComments
            ,@ProcedureParameters = @ProcedureParameters
            ,@ApplicationName = @ApplicationName
            ,@ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

        RETURN (1);
    END CATCH
END;