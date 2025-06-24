/*************************************************************           
 ** File:   [GetExchangeBillingList]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to GetExchangeBillingList
 ** Purpose:         
 ** Date:   06/09/2025      
          
 ** PARAMETERS: @ExchangeSalesOrderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/09/2025   Ekta Chandegra     Created
	2    06/20/2025   Ekta Chandegra     Get correct billing amount when flat rates are added


 EXEC GetExchangeBillingList @ExchangeSalesOrderId=188
************************************************************************/ 
CREATE   PROCEDURE [dbo].[GetExchangeBillingList]
    @ExchangeSalesOrderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @ExchangeStatusId INT;
		SELECT @ExchangeStatusId = ExchangeStatusId  FROM [dbo].[ExchangeStatus] WITH(NOLOCK) WHERE Name = 'Cancelled';

		SELECT DISTINCT
			sqe.ExchangeSalesOrderScheduleBillingId,
			sqe.ExchangeSalesOrderPartId,
			sqe.ExchangeSalesOrderId,
			sqe.ScheduleBillingDate,
			sqe.PeriodicBillingAmount,
			sqe.Cogs,
			sqe.CogsAmount,
			sqe.Qty,
			sqe.BillingTypeId,
			sqe.Notes,
			sqe.Memo,
			ISNULL(sqe.UnitOfMeasureId, um.UnitOfMeasureId) AS UnitOfMeasureId,
			ISNULL(sqe.BillingAmount, 0) AS BillingAmount,
			CAST(1 AS BIT) AS isEditPart,
			sqe.Type,
			ebt.Description AS BillingType,
			sqe.StatusId,
			ISNULL(essp.ExchangeSalesOrderShippingId, 0) AS ExchangeSalesOrderShippingId,
			sqe.IsPartEntry,
			ISNULL(esbi.InvoiceStatus, '') AS InvoiceStatus,
			ISNULL(esbi.SOBillingInvoicingId, 0) AS SOBillingInvoicingId,
			ISNULL(esbi.InvoiceNo, '-') AS InvoiceNumber,
			ISNULL(esbi.BillingId, 0) AS BillingId,
			sqe.MarkupPercentageId,
			sqe.ExtendedCost
		FROM  [dbo].[ExchangeSalesOrderScheduleBilling] sqe WITH(NOLOCK)
		LEFT JOIN [dbo].[ExchangeSalesOrderPart] part WITH(NOLOCK) ON sqe.ExchangeSalesOrderPartId = part.ExchangeSalesOrderPartId
		LEFT JOIN [dbo].[ExchangeSalesOrder] eso WITH(NOLOCK) ON part.ExchangeSalesOrderId = eso.ExchangeSalesOrderId
		LEFT JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
		LEFT JOIN [dbo].[UnitOfMeasure] um WITH(NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
		LEFT JOIN [dbo].[ExchangeBillingType] ebt WITH(NOLOCK) ON sqe.BillingTypeId = ebt.ExchangeBillingTypeId
		LEFT JOIN [dbo].[ExchangeSalesOrderShipping] essp WITH(NOLOCK) ON sqe.ExchangeSalesOrderId = essp.ExchangeSalesOrderId
		LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] esbii WITH(NOLOCK) ON sqe.ExchangeSalesOrderScheduleBillingId = esbii.ExchangeSalesOrderScheduleBillingId AND ISNULL(esbii.IsDeleted,0) = 0
		LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] esbi WITH(NOLOCK) ON esbii.SOBillingInvoicingId = esbi.SOBillingInvoicingId
		WHERE sqe.ExchangeSalesOrderId = @ExchangeSalesOrderId AND sqe.StatusId != @ExchangeStatusId
		ORDER BY sqe.ExchangeSalesOrderScheduleBillingId;

		---------------------------------------------
		-- 1. Flat Rate Charge
		---------------------------------------------
		DECLARE @ChargesBillingTypeId INT , @FreightsBillingTypeId INT, @ChargesDescription NVARCHAR(50), @FreightsDescription NVARCHAR(50);

		SELECT @ChargesBillingTypeId = ExchangeBillingTypeId FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE Description = 'Charges'
		SELECT @FreightsBillingTypeId = ExchangeBillingTypeId FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE Description = 'FREIGHT';

		SELECT @ChargesDescription = Description FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE ExchangeBillingTypeId = @ChargesBillingTypeId;
		SELECT @FreightsDescription = Description FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE ExchangeBillingTypeId = @FreightsBillingTypeId;

		IF EXISTS (
			SELECT 1 FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)
			WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId 
			  AND IsChargeFlatRate = 1 
			  AND ISNULL(IsChargeFlatRateInsert, 0) = 0
		)
		BEGIN
			SELECT 
				NULL AS ExchangeSalesOrderFreightId,
				NULL AS ExchangeSalesOrderChargesId,
				0 AS ExchangeSalesOrderScheduleBillingId,
				0 AS ExchangeSalesOrderPartId,
				GETUTCDATE() AS ScheduleBillingDate,
				0 AS Cogs,
				ChargeFlatRate AS CogsAmount,
				@ChargesBillingTypeId AS BillingTypeId, -- Charges
				'' AS Notes,
				'' AS Memo,
				NULL AS UnitOfMeasureId,
				CAST(1 AS BIT) AS isEditPart,
				ChargeFlatRate AS BillingAmount,
				ExchangeSalesOrderId,
				1 AS Qty,
				ChargeFlatRate AS PeriodicBillingAmount,
				@ChargesDescription AS Type,
				1 AS StatusId,
				0 AS BillingId,
				0 AS MarkupPercentageId,
				ChargeFlatRate AS ExtendedCost,
				CAST(1 AS BIT) AS IsCharge,
				CAST(0 AS BIT) AS IsFreight,
				CAST(1 AS BIT) AS IsChargeFlatRate,
				CAST(0 AS BIT) AS IsFreightFlatRate,
				NULL AS ExchangeSalesOrderMarginSummaryId
			FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)
			WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId;
		END

		---------------------------------------------
		-- 2. Flat Rate Freight
		---------------------------------------------
		IF EXISTS (
			SELECT 1 FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)
			WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId 
			  AND IsFreightFlatRate = 1 
			  AND ISNULL(IsFreightFlatRateInsert, 0) = 0
		)
		BEGIN
			SELECT 
				NULL AS ExchangeSalesOrderFreightId,
				NULL AS ExchangeSalesOrderChargesId,
				0 AS ExchangeSalesOrderScheduleBillingId,
				0 AS ExchangeSalesOrderPartId,
				GETUTCDATE() AS ScheduleBillingDate,
				0 AS Cogs,
				FreightFlatRate AS CogsAmount,
				@FreightsBillingTypeId AS BillingTypeId, -- Freight
				'' AS Notes,
				'' AS Memo,
				NULL AS UnitOfMeasureId,
				CAST(1 AS BIT) AS isEditPart,
				FreightFlatRate AS BillingAmount,
				ExchangeSalesOrderId,
				1 AS Qty,
				FreightFlatRate AS PeriodicBillingAmount,
				@FreightsDescription AS Type,
				1 AS StatusId,
				0 AS BillingId,
				0 AS MarkupPercentageId,
				FreightFlatRate AS ExtendedCost,
				CAST(0 AS BIT) AS IsCharge,
				CAST(1 AS BIT) AS IsFreight,
				CAST(0 AS BIT) AS IsChargeFlatRate,
				CAST(1 AS BIT) AS IsFreightFlatRate,
				NULL AS ExchangeSalesOrderMarginSummaryId
			FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)
			WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId;
		END

		---------------------------------------------
		-- 3. Charge from Margin Summary
		---------------------------------------------
		ELSE IF EXISTS (
			SELECT 1
			FROM [dbo].[ExchangeSalesOrderCharges] ch WITH(NOLOCK)
			INNER JOIN [dbo].[ExchangeSalesOrderMarginSummary] ms WITH(NOLOCK) ON ch.ExchangeSalesOrderId = ms.ExchangeSalesOrderId
			WHERE ch.ExchangeSalesOrderId = @ExchangeSalesOrderId
			  AND ISNULL(ch.IsDeleted, 0) = 0
			  AND ISNULL(ch.IsInsert, 0) = 0
			  AND ms.OtherCharges > 0
			  AND ISNULL(ms.IsChargeInsert, 0) = 0
		)
		BEGIN
			SELECT 
				NULL AS ExchangeSalesOrderFreightId,
				NULL AS ExchangeSalesOrderChargesId,
				0 AS ExchangeSalesOrderScheduleBillingId,
				0 AS ExchangeSalesOrderPartId,
				GETUTCDATE() AS ScheduleBillingDate,
				0 AS Cogs,
				ch.ExtendedCost AS CogsAmount,
				@ChargesBillingTypeId AS BillingTypeId, -- Charges
				'' AS Notes,
				'' AS Memo,
				ch.UomId AS UnitOfMeasureId,
				CAST(1 AS BIT) AS isEditPart,
				ms.OtherCharges AS BillingAmount,
				ch.ExchangeSalesOrderId,
				1 AS Qty,
				ms.OtherCharges AS PeriodicBillingAmount,
				@ChargesDescription AS Type,
				1 AS StatusId,
				0 AS BillingId,
				0 AS MarkupPercentageId,
				ms.OtherCharges AS ExtendedCost,
				CAST(1 AS BIT) AS IsCharge,
				CAST(0 AS BIT) AS IsFreight,
				CAST(0 AS BIT) AS IsChargeFlatRate,
				CAST(0 AS BIT) AS IsFreightFlatRate,
				ms.ExchangeSalesOrderMarginSummaryId
			FROM [dbo].[ExchangeSalesOrderCharges] ch WITH(NOLOCK)
			INNER JOIN [dbo].[ExchangeSalesOrderMarginSummary] ms WITH(NOLOCK) ON ch.ExchangeSalesOrderId = ms.ExchangeSalesOrderId
			WHERE ch.ExchangeSalesOrderId = @ExchangeSalesOrderId
			  AND ISNULL(ch.IsDeleted, 0) = 0
			  AND ISNULL(ch.IsInsert, 0) = 0
			  AND ms.OtherCharges > 0
			  AND ISNULL(ms.IsChargeInsert, 0) = 0;
		END

		---------------------------------------------
		-- 4. Freight from Margin Summary
		---------------------------------------------
		ELSE IF EXISTS (
			SELECT 1
			FROM [dbo].[ExchangeSalesOrderFreight] f WITH(NOLOCK)
			INNER JOIN [dbo].[ExchangeSalesOrderMarginSummary] m WITH(NOLOCK) ON f.ExchangeSalesOrderId = m.ExchangeSalesOrderId
			WHERE f.ExchangeSalesOrderId = @ExchangeSalesOrderId
			  AND ISNULL(f.IsDeleted, 0) = 0
			  AND ISNULL(f.IsInsert, 0) = 0
			  AND m.FreightAmount > 0
			  AND ISNULL(m.IsFreightInsert, 0) = 1
		)
		BEGIN
			SELECT 
				NULL AS ExchangeSalesOrderFreightId,
				NULL AS ExchangeSalesOrderChargesId,
				0 AS ExchangeSalesOrderScheduleBillingId,
				0 AS ExchangeSalesOrderPartId,
				GETUTCDATE() AS ScheduleBillingDate,
				0 AS Cogs,
				f.Amount AS CogsAmount,
				@FreightsBillingTypeId AS BillingTypeId, -- Freight
				'' AS Notes,
				'' AS Memo,
				NULL AS UnitOfMeasureId,
				CAST(1 AS BIT) AS isEditPart,
				m.FreightAmount AS BillingAmount,
				m.ExchangeSalesOrderId,
				1 AS Qty,
				m.FreightAmount AS PeriodicBillingAmount,
				@FreightsDescription AS Type,
				1 AS StatusId,
				0 AS BillingId,
				0 AS MarkupPercentageId,
				m.FreightAmount AS ExtendedCost,
				CAST(0 AS BIT) AS IsCharge,
				CAST(1 AS BIT) AS IsFreight,
				CAST(0 AS BIT) AS IsChargeFlatRate,
				CAST(0 AS BIT) AS IsFreightFlatRate,
				m.ExchangeSalesOrderMarginSummaryId
			FROM [dbo].[ExchangeSalesOrderFreight] f WITH(NOLOCK)
			JOIN [dbo].[ExchangeSalesOrderMarginSummary] m WITH(NOLOCK) ON f.ExchangeSalesOrderId = m.ExchangeSalesOrderId
			WHERE f.ExchangeSalesOrderId = @ExchangeSalesOrderId
			  AND ISNULL(f.IsDeleted, 0) = 0
			  AND ISNULL(f.IsInsert, 0) = 0
			  AND m.FreightAmount > 0
			  AND ISNULL(m.IsFreightInsert, 0) = 1;
		END

		---------------------------------------------
		-- 5. Regular Charges
		---------------------------------------------
		ELSE
		BEGIN
			SELECT 
				NULL AS ExchangeSalesOrderFreightId,
				cc.ExchangeSalesOrderChargesId,
				0 AS ExchangeSalesOrderScheduleBillingId,
				0 AS ExchangeSalesOrderPartId,
				GETUTCDATE() AS ScheduleBillingDate,
				0 AS Cogs,
				cc.ExtendedCost AS CogsAmount,
				@ChargesBillingTypeId AS BillingTypeId,
				'' AS Notes,
				'' AS Memo,
				cc.UomId AS UnitOfMeasureId,
				CAST(1 AS BIT) AS isEditPart,
				cc.BillingAmount AS BillingAmount,
				cc.ExchangeSalesOrderId,
				cc.Quantity AS Qty,
				cc.BillingRate AS PeriodicBillingAmount,
				@ChargesDescription AS Type,
				1 AS StatusId,
				0 AS BillingId,
				0 AS MarkupPercentageId,
				cc.BillingAmount AS ExtendedCost,
				CAST(0 AS BIT) AS IsCharge,
				CAST(0 AS BIT) AS IsFreight,
				CAST(0 AS BIT) AS IsChargeFlatRate,
				CAST(0 AS BIT) AS IsFreightFlatRate,
				NULL AS ExchangeSalesOrderMarginSummaryId
			FROM [dbo].[ExchangeSalesOrderCharges] cc WITH(NOLOCK)
			WHERE cc.ExchangeSalesOrderId = @ExchangeSalesOrderId
			  AND ISNULL(cc.IsInsert, 0) = 0
			  AND ISNULL(cc.IsDeleted, 0) = 0;

			-- Also include: Regular Freight (BillingMethodId != 3)
			SELECT 
				f.ExchangeSalesOrderFreightId,
				NULL AS ExchangeSalesOrderChargesId,
				0 AS ExchangeSalesOrderScheduleBillingId,
				0 AS ExchangeSalesOrderPartId,
				GETUTCDATE() AS ScheduleBillingDate,
				0 AS Cogs,
				f.Amount AS CogsAmount,
				@FreightsBillingTypeId AS BillingTypeId,
				'' AS Notes,
				'' AS Memo,
				f.UOMId AS UnitOfMeasureId,
				CAST(1 AS BIT) AS isEditPart,
				f.BillingAmount AS BillingAmount,
				f.ExchangeSalesOrderId,
				1 AS Qty,
				f.BillingAmount AS PeriodicBillingAmount,
				@FreightsDescription AS Type,
				1 AS StatusId,
				0 AS BillingId,
				0 AS MarkupPercentageId,
				f.BillingAmount AS ExtendedCost,
				CAST(0 AS BIT) AS IsCharge,
				CAST(0 AS BIT) AS IsFreight,
				CAST(0 AS BIT) AS IsChargeFlatRate,
				CAST(0 AS BIT) AS IsFreightFlatRate,
				NULL AS ExchangeSalesOrderMarginSummaryId
			FROM [dbo].[ExchangeSalesOrderFreight] f WITH(NOLOCK)
			WHERE f.ExchangeSalesOrderId = @ExchangeSalesOrderId
			  AND ISNULL(f.IsInsert, 0) = 0
			  AND ISNULL(f.IsDeleted, 0) = 0
			  AND ISNULL(f.BillingMethodId, 0) != @FreightsBillingTypeId;
		END
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetExchangeBillingList'     
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