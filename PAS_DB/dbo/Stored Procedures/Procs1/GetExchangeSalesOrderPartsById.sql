/*************************************************************           
 ** File:   [GetExchangeSalesOrderPartsById]          
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to GetExchangeSalesOrderPartsById
 ** Purpose:         
 ** Date:    06/05/2025  

 ** PARAMETERS: @ExchangeSalesOrderId BIGINT 

 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** ----------------------------------------------------------          
    1    06/05/2025  EKTA CHANDEGRA    Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	     
 EXEC GetExchangeSalesOrderPartsById @ExchangeSalesOrderId = 150 
************************************************************************/ 
CREATE   PROCEDURE [dbo].[GetExchangeSalesOrderPartsById]
    @ExchangeSalesOrderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @ApprovedStatusId INT, @ExchangeBillingTypeId INT;

        SELECT @ApprovedStatusId = ApprovalStatusId 
        FROM [dbo].[ApprovalStatus] WITH(NOLOCK) 
        WHERE Name = 'Approved';

        SELECT @ExchangeBillingTypeId = ExchangeBillingTypeId 
        FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) 
        WHERE Description = 'EXCH FEE';

        ;WITH QtyToShipCTE AS (
            SELECT ExchangeSalesOrderPartId, SUM(QtyToShip) AS QtyToShip
            FROM [dbo].[ExchangeSOPickTicket] WITH(NOLOCK)
            WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId
              AND ISNULL(IsActive, 0) = 1
              AND ISNULL(IsDeleted, 0) = 0
            GROUP BY ExchangeSalesOrderPartId
        )

        SELECT DISTINCT
            part.ExchangeSalesOrderPartId,
            part.ExchangeSalesOrderId,
            part.ExchangeQuotePartId,
            part.ExchangeQuoteId,
            part.ItemMasterId,
            part.StockLineId,
			qs.StocklineNumber,
            ISNULL(qs.SerialNumber, '') AS SerialNumber,
            part.MasterCompanyId,
            part.CreatedBy,
            part.CreatedDate,
            part.UpdatedBy,
            part.UpdatedDate,
            im.PartNumber,
            im.PartDescription,
            ISNULL(cp.ConditionId, 0) AS ConditionId,
            ISNULL(cp.Description, '') AS ConditionDescription,
            cur.Code AS CurrencyDescription,
            fcur.Code AS reportCur,
            CASE 
                WHEN EXISTS (
                    SELECT 1 
                    FROM [dbo].[ExchangeQuoteApproval] a WITH(NOLOCK)
                    WHERE a.ExchangeQuotePartId = part.ExchangeQuotePartId 
                      AND ISNULL(a.IsDeleted,0) = 0 
                      AND a.CustomerStatusId = @ApprovedStatusId
                ) THEN 1 ELSE 0 
            END AS IsApproved,
            ISNULL(part.ExchangeCurrencyId, 0) AS ExchangeCurrencyId,
            part.LoanCurrencyId,
            part.ExchangeListPrice,
            part.EntryDate,
            part.ExchangeOverhaulPrice,
            part.ExchangeCorePrice,
            part.EstOfFeeBilling,
            part.BillingStartDate,
            part.ExchangeOutrightPrice,
            part.DaysForCoreReturn,
            part.BillingIntervalDays,
            part.ExchangeOverhaulCost,
            cur.Code AS Currency,
            ISNULL(part.CurrencyId, 0) AS CurrencyId,
            part.DepositeAmount,
            part.CoreDueDate,
            part.IsConvertedToSalesOrder,
            part.CustomerRequestDate,
            part.PromisedDate,
            part.EstimatedShipDate,
            part.ExpectedCoreSN,
            ISNULL(uom.ShortName, '') AS UOM,
            rpart.QtyToReserve AS QtyReserved,
            ISNULL(qs.ControlNumber, '') AS ControlNumber,
            ISNULL(qs.IdNumber, '') AS IdNumber,
            ISNULL(q.OpenDate, GETDATE()) AS QuoteDate,
            ISNULL(qs.QuantityAvailable, 0) AS QtyAvailable,
            ISNULL(qs.QuantityOnHand, 0) AS QuantityOnHand,
            ISNULL(q.ExchangeQuoteNumber, '') AS ExchangeQuoteNumber,
            ISNULL(part.PriorityId, 2) AS PriorityId,
            ISNULL(pri.Description, 'Routine') AS PriorityName,
            part.ExpecedCoreCond,
            ISNULL(part.ExpectedCoreRetDate, GETDATE()) AS ExpectedCoreRetDate,
            ISNULL(rcw.ReceivedDate, part.CoreRetDate) AS CoreRetDate,
            rcw.ReceivingNumber AS CoreRetNum,
            part.CoreStatusId,
            part.Notes,
            part.QtyRequested,
            part.Qty,
            part.QtyQuoted,
            part.UnitCost,
            soq.CustomerReference,
            CASE 
                WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMADER'
                WHEN im.IsPma = 1 THEN 'PMA'
                WHEN im.IsDER = 1 THEN 'DER'
                ELSE 'OEM'
            END AS StockType,
            part.IsExpCoreSN,
            im.ManufacturerName,
            ISNULL(qship.QtyToShip, 0) AS QtyToShip
        FROM [dbo].[ExchangeSalesOrderPart] part WITH(NOLOCK)
        LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON part.StockLineId = qs.StockLineId
        LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON part.ItemMasterId = im.ItemMasterId
         AND ISNULL(im.IsNonStock,0) = 0
         LEFT JOIN [dbo].[Condition] cp WITH(NOLOCK) ON part.ConditionId = cp.ConditionId
        LEFT JOIN [dbo].[ExchangeSalesOrder] soq WITH(NOLOCK) ON part.ExchangeSalesOrderId = soq.ExchangeSalesOrderId
        LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON im.ConsumeUnitOfMeasureId = uom.UnitOfMeasureId
        LEFT JOIN [dbo].[ExchangeSalesOrderReserveParts] rpart WITH(NOLOCK) ON part.ExchangeSalesOrderPartId = rpart.ExchangeSalesOrderPartId
        LEFT JOIN [dbo].[ExchangeQuote] q WITH(NOLOCK) ON part.ExchangeQuoteId = q.ExchangeQuoteId
        LEFT JOIN [dbo].[Priority] pri WITH(NOLOCK) ON part.PriorityId = pri.PriorityId
        OUTER APPLY (
            SELECT TOP 1 rcw.ReceivedDate, rcw.ReceivingNumber 
            FROM [dbo].[ReceivingCustomerWork] rcw WITH(NOLOCK) 
            WHERE rcw.ExchangeSalesOrderId = soq.ExchangeSalesOrderId 
            ORDER BY rcw.ReceivedDate DESC
        ) rcw
        LEFT JOIN [dbo].[Currency] cur WITH(NOLOCK) ON part.CurrencyId = cur.CurrencyId
        LEFT JOIN [dbo].[Currency] fcur WITH(NOLOCK) ON part.ExchangeCurrencyId = fcur.CurrencyId
        LEFT JOIN QtyToShipCTE qship ON part.ExchangeSalesOrderPartId = qship.ExchangeSalesOrderPartId
        WHERE part.ExchangeSalesOrderId = @ExchangeSalesOrderId
          AND ISNULL(part.IsDeleted,0) = 0
        ORDER BY part.ExchangeSalesOrderPartId;

        -- Schedule Billing
        SELECT
            sb.ExchangeSalesOrderScheduleBillingId,
            sb.ExchangeSalesOrderPartId,
            sb.ExchangeSalesOrderId,
            sb.ScheduleBillingDate,
            sb.PeriodicBillingAmount,
            sb.Cogs,
            sb.CogsAmount,
            sb.Qty,
            sb.BillingTypeId,
            sb.UnitOfMeasureId,
            sb.Type,
            sb.StatusId,
            sb.ExchangeSalesOrderFreightId,
            sb.IsPartEntry,
            sb.BillingAmount,
            sb.MarkupPercentageId,
            sb.ExtendedCost
        FROM [dbo].[ExchangeSalesOrderScheduleBilling] sb WITH(NOLOCK)
        WHERE sb.ExchangeSalesOrderId = @ExchangeSalesOrderId
          AND sb.BillingTypeId = @ExchangeBillingTypeId;

	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetExchangeSalesOrderPartsById'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderId = ''' + CAST(ISNULL(@ExchangeSalesOrderId, '') AS VARCHAR(100)) 
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);
	END CATCH
END