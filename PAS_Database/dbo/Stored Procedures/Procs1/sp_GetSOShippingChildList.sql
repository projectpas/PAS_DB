/**********************           
 ** File:   [sp_GetSOShippingChildList]           
 ** Author:   
 ** Description: Returns shipping child list for a given SalesOrder part.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
 **   @SalesOrderId      bigint
 **   @SalesOrderPartId  bigint
 **   @ConditionId       bigint
         
 ** RETURN VALUE: Result set of shipping line items
  
 **********************           
 ** Change History           
 **********************           
 ** PR   Date          Author            Change Description            
 ** --   ----------    ---------------   --------------------------------          
    1    01/31/2024    Amit Ghediya      Added IsPerforma for Billing
    2    10/15/2024    Vishal Suthar     Modified to use new SO part tables
    3    11/26/2024    Amit Ghediya      Get ECCN, HSCODE, Weight, LWH for billing
    4    16/06/2025    Rajesh Gami       Replaced new billing invoicing table with old (SO)
    5    11/07/2025    Rajesh Gami       Get SOShipping ID from Billing Invoicing if posted
    6    10/11/2025    Rajesh Gami       Added [UPSPdfPath]
    7    12/01/2026    Vishal Suthar     Fixed duplicate shipping records for same stockline (SA multi-invoice)
    8    31/03/2026    Moin Bloch        Added UOM changes PN-15067
    9	 19/06/2026	   Ayushi		     [PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
    10   09/July/2026   Rajesh Gami       [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	11	20/July/2026 RAJESH GAMI     [PN-17350] - Removed IsNonStock=0 filter so Non-Stock stockline fields populate correctly on the shipping list.
    12   24/Aug/2026   Kishor Makwana    [PN-17439] - Fixed @SalesOrderPartId filter to match the real SalesOrderPartV1 PK (sop.SalesOrderPartId) instead of ItemMasterId, and stopped hardcoding ItemNo to 0, so duplicate Part+Condition lines (different SequenceNumber) no longer show each other's shipping/pick ticket rows.
 EXEC [dbo].[sp_GetSOShippingChildList] 1272, 318, 7
**********************/
CREATE PROCEDURE [dbo].[sp_GetSOShippingChildList]
    @SalesOrderId     BIGINT,
    @SalesOrderPartId BIGINT,
    @ConditionId      BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @soModuleId INT = (
            SELECT TOP 1 ModuleId
            FROM   dbo.Module WITH (NOLOCK)
            WHERE  ModuleName = 'SalesOrder'
        );
        DECLARE @masterCompanyId BIGINT = (SELECT TOP 1 MasterCompanyId FROM dbo.SalesOrder WITH(NOLOCK) WHERE SalesOrderId = @SalesOrderId)
        SELECT DISTINCT
            sopt.SOPickTicketId,
            sos.SalesOrderShippingId,

            -- ShipDate and SOShippingNum: only populate when shipping item exists
            IIF(sosi.SalesOrderPartId IS NOT NULL, sos.ShipDate,      NULL) AS ShipDate,
            IIF(sosi.SalesOrderPartId IS NOT NULL, sos.SOShippingNum,  NULL) AS SOShippingNum,

            sopt.SOPickTicketNumber,

            -- QtyToShip converted to consume UOM
            ISNULL(CASE WHEN ISNULL(imt.StockUnitOfMeasure,'') = ISNULL(imt.ConsumeUnitOfMeasure,'') THEN ISNULL(sopt.QtyToShip,0) ELSE [dbo].[fn_ConvertUOM](ISNULL(sopt.QtyToShip,0),imt.StockUnitOfMeasure,imt.ConsumeUnitOfMeasure,0,so.MasterCompanyId) END,0) AS QtyToShip,

            so.SalesOrderNumber,
            imt.PartNumber,
            imt.PartDescription,
            sl.StockLineNumber,
            sl.SerialNumber,
            cr.[Name]                                                         AS CustomerName,
            soc.CustomsValue,
            soc.CommodityCode,

            -- QtyShipped converted to consume UOM
            ISNULL(CASE WHEN ISNULL(imt.StockUnitOfMeasure,'') = ISNULL(imt.ConsumeUnitOfMeasure,'') THEN ISNULL(sosi.QtyShipped,0) ELSE [dbo].[fn_ConvertUOM](ISNULL(sosi.QtyShipped,0),imt.StockUnitOfMeasure,imt.ConsumeUnitOfMeasure,0,so.MasterCompanyId) END,0) AS QtyShipped,

            sop.SequenceNumber                                               AS ItemNo,

            sos.SalesOrderId,
            COALESCE(sosi.SalesOrderPartId, sop.SalesOrderPartId)            AS SalesOrderPartId,
            sos.AirwayBill,
            SPB.PackagingSlipNo,
            SPB.PackagingSlipId,
            IIF(sos.SalesOrderShippingId IS NOT NULL, sos.SmentNum, 0)       AS SmentNo,

            -- SOShippingId: only return when invoice is posted
            IIF(ISNULL(InvoiceData.IsInvoicePosted, 0) = 1,
                InvoiceData.ShippingId, 0)                                    AS SOShippingId,

            sosi.FedexPdfPath,
            Stk.ECCN,
            Stk.HSCODE,
            Stk.[Weight],
            Stk.SizeLength,
            Stk.SizeWidth,
            Stk.SizeHeight,
            ISNULL(sosi.UPSPdfPath, '')                                       AS UpsPdfPath

        FROM       [dbo].[SOPickTicket]            sopt WITH (NOLOCK)

        INNER JOIN [dbo].[SalesOrderPartV1]        sop  WITH (NOLOCK)
                ON sop.SalesOrderId    = sopt.SalesOrderId
               AND sop.SalesOrderPartId = sopt.SalesOrderPartId

         LEFT JOIN [dbo].[SalesOrderStocklineV1]   stk  WITH (NOLOCK)
                ON stk.SalesOrderStocklineId = sopt.SalesOrderPartStocklineId

         LEFT JOIN [dbo].[SalesOrderShippingItem]  sosi WITH (NOLOCK)
                ON sosi.SalesOrderPartId = sop.SalesOrderPartId
               AND sosi.SOPickTicketId   = sopt.SOPickTicketId

         LEFT JOIN [dbo].[SalesOrderShipping]      sos  WITH (NOLOCK)
                ON sos.SalesOrderShippingId = sosi.SalesOrderShippingId
               AND sos.SalesOrderId         = sopt.SalesOrderId
	  INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId  
	  LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId  
	  LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = stk.StockLineId  
	  LEFT JOIN DBO.SalesOrderCustomsInfo soc WITH (NOLOCK) ON soc.SalesOrderShippingId = sos.SalesOrderShippingId  
	  LEFT JOIN DBO.Customer cr WITH (NOLOCK)  on cr.CustomerId = so.CustomerId  
	  LEFT JOIN DBO.SalesOrderPackaginSlipItems SPI WITH (NOLOCK) ON sopt.SOPickTicketId = SPI.SOPickTicketId   
		 AND SPI.SalesOrderPartId = sop.SalesOrderPartId AND SPI.MasterCompanyId = @masterCompanyId AND ISNULL(SPI.IsDeleted,0) = 0
	  LEFT JOIN DBO.SalesOrderPackaginSlipHeader SPB WITH (NOLOCK) ON SPB.PackagingSlipId = SPI.PackagingSlipId  AND SPB.SalesOrderId = sopt.SalesOrderId AND ISNULL(SPB.IsDeleted,0) = 0
	  --LEFT JOIN DBO.BillingInvoicingItems SOBI  WITH (NOLOCK) ON sosi.SalesOrderShippingId = SOBI.ShippingId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND SOBI.ModuleId = @soModuleId AND ISNULL(SOBI.IsVersionIncrease,0) = 0
	  --LEFT JOIN DBO.BillingInvoicing BI  WITH (NOLOCK) ON SOBI.BillingInvoicingId = BI.BillingInvoicingId AND BI.ModuleId = @soModuleId AND ISNULL(BI.IsVersionIncrease,0) = 0 
        OUTER APPLY
        (
            -- Get the latest non-proforma, non-version-increase billing invoice for this shipping line
            SELECT TOP 1
                SOBI.ShippingId,
                BI.IsInvoicePosted
            FROM       [dbo].[BillingInvoicingItems] SOBI WITH (NOLOCK)
            INNER JOIN [dbo].[BillingInvoicing]      BI   WITH (NOLOCK)
                    ON BI.BillingInvoicingId = SOBI.BillingInvoicingId
            WHERE  SOBI.ShippingId            = sosi.SalesOrderShippingId
              AND  ISNULL(SOBI.IsPerformaInvoice,  0) = 0
              AND  SOBI.ModuleId                       = @soModuleId
              AND  ISNULL(SOBI.IsVersionIncrease, 0)  = 0
              AND  BI.ModuleId                         = @soModuleId
              AND  ISNULL(BI.IsVersionIncrease,   0)  = 0
            ORDER BY BI.BillingInvoicingId DESC
        ) InvoiceData

        WHERE  sopt.SalesOrderId  = @SalesOrderId
          AND  sop.SalesOrderPartId = @SalesOrderPartId
          AND  sop.ConditionId    = @ConditionId
          AND  sopt.IsConfirmed   = 1 AND sopt.MasterCompanyId = @masterCompanyId;  -- Avoid ISNULL() to allow index seek

    END TRY
    BEGIN CATCH

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'sp_GetSOShippingChildList',
            -- FIX: corrected malformed string — all three params included with proper quoting
            @ProcedureParameters VARCHAR(3000) =
                '@SalesOrderId = '     + CAST(ISNULL(@SalesOrderId,     '') AS VARCHAR(100)) + ', ' +
                '@SalesOrderPartId = ' + CAST(ISNULL(@SalesOrderPartId, '') AS VARCHAR(100)) + ', ' +
                '@ConditionId = '      + CAST(ISNULL(@ConditionId,      '') AS VARCHAR(100)),
            @ApplicationName     VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName         = @DatabaseName,
            @AdhocComments        = @AdhocComments,
            @ProcedureParameters  = @ProcedureParameters,
            @ApplicationName      = @ApplicationName,
            @ErrorLogID           = @ErrorLogID OUTPUT;

        RAISERROR(
            'Unexpected error in database. Please contact support with error number: %d',
            16, 1, @ErrorLogID
        );
        RETURN(1);

    END CATCH
END;