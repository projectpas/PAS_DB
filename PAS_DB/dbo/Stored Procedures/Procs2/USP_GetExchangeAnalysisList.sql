
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_GetExchangeAnalysisList   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_GetExchangeAnalysisList.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:   [USP_GetExchangeAnalysisList]          
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to USP_GetExchangeAnalysisList
 ** Purpose:         
 ** Date:    06/03/2025  

 ** PARAMETERS: @ExchangeSalesOrderId BIGINT , @EmployeeId BIGINT

 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** -----------------------------------------------------------          
    1    06/03/2025  EKTA CHANDEGRA    Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	     
 EXEC USP_GetExchangeAnalysisList @ExchangeSalesOrderId = 150 , @EmployeeId = 223
************************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_GetExchangeAnalysisList]
    @ExchangeSalesOrderId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		-- Get Employee TimeZone (assuming it's a function)
		 DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(
			ETZ.[Description],  -- Prefer Employee's TimeZone description if available
			LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
		)
		FROM 
		dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN 
		dbo.TimeZone ETZ WITH (NOLOCK) 
		ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN 
		dbo.LegalEntity LE WITH (NOLOCK) 
		ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN 
		dbo.TimeZone LTZ WITH (NOLOCK) 
		ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE 
		E.EmployeeId = @EmployeeId;	

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
			ISNULL(sqe.Notes,'') AS Notes,
			ISNULL(sqe.Memo,'') AS Memo,
			ISNULL(sqe.UnitOfMeasureId, um.UnitOfMeasureId) AS UnitOfMeasureId,
			1 AS isEditPart,
			sqe.Type,
			ebt.Description AS BillingType,
			sqe.StatusId,
			0 AS ExchangeSalesOrderShippingId, -- Placeholder if needed later
			sqe.IsPartEntry,
			CASE 
				WHEN esb.InvoiceDate IS NOT NULL THEN (Cast(DBO.ConvertUTCtoLocal(esb.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME))
				ELSE NULL
			END AS InvoiceDate,
			sqe.BillingAmount,
			sqe.ExtendedCost
		FROM [dbo].[ExchangeSalesOrderScheduleBilling] sqe WITH(NOLOCK)
		INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] esbi WITH(NOLOCK) ON sqe.ExchangeSalesOrderScheduleBillingId = esbi.ExchangeSalesOrderScheduleBillingId
		INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] esb WITH(NOLOCK) ON esbi.SOBillingInvoicingId = esb.SOBillingInvoicingId
		LEFT JOIN [dbo].[ExchangeSalesOrderPart] part WITH(NOLOCK) ON sqe.ExchangeSalesOrderPartId = part.ExchangeSalesOrderPartId
		LEFT JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
		 AND ISNULL(itemMaster.IsNonStock,0) = 0
		 LEFT JOIN [dbo].[UnitOfMeasure] um WITH(NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
		LEFT JOIN [dbo].[ExchangeBillingType] ebt WITH(NOLOCK) ON sqe.BillingTypeId = ebt.ExchangeBillingTypeId
		WHERE sqe.ExchangeSalesOrderId = @ExchangeSalesOrderId
		  AND ISNULL(esbi.IsDeleted,0) = 0
		ORDER BY sqe.ExchangeSalesOrderScheduleBillingId;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeAnalysisList'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderId = ''' + CAST(ISNULL(@ExchangeSalesOrderId, '') AS VARCHAR(100)) + '''
													@EmployeeId = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
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
END;