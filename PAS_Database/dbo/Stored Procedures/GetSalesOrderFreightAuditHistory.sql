/*************************************************************           
 ** File:   [GetSalesOrderFreightAuditHistory]           
 ** Author:   Abhishek Jirawla
 ** Description: Get Sales Order Freight Audit History
 ** Purpose:         
 ** Date:   04-Apr-2025  
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    04-Apr-2025   Abhishek Jirawla	Created
     
 EXECUTE [GetSalesOrderFreightAuditHistory] 1, 10
**************************************************************/ 
CREATE   PROCEDURE DBO.GetSalesOrderFreightAuditHistory
    @SalesOrderFreightId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
		SELECT 
			@CurrntEmpTimeZoneDesc = COALESCE(
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
			E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

		SELECT DISTINCT
			sf.AuditSalesOrderFreightId,
			sf.SalesOrderFreightId,
			sf.SalesOrderQuoteId,
			sf.SalesOrderPartId,
			sf.Amount,
			sf.CreatedBy,
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				CASE WHEN CAST(sf.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(sf.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(sf.CreatedDate AS DATETIME)) END CreatedDate,
			sf.IsActive,
			sf.IsDeleted,
			sf.MasterCompanyId,
			sf.Memo,
			sf.ShipViaId,
			sf.UpdatedBy,
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				CASE WHEN CAST(sf.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(sf.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(sf.UpdatedDate AS DATETIME)) END UpdatedDate,
			sf.Weight,
			sv.Name AS ShipVia,
			sf.Length,
			sf.Width,
			sf.Height,
			sf.UOMId,
			sf.DimensionUOMId,
			sf.CurrencyId,
			sf.MarkupFixedPrice,
			sf.MarkupPercentageId,
			sf.HeaderMarkupId,
			sf.HeaderMarkupPercentageId,
			sf.BillingMethodId,
			CASE 
				WHEN sf.BillingMethodId = CAST(1 AS INT) THEN 'TM'
				WHEN sf.BillingMethodId = CAST(2 AS INT) THEN 'Actual'
				ELSE '' 
			END AS BillingMethodName,
			sf.BillingRate,
			sf.BillingAmount,
			sf.UOMName AS UOM,
			sf.DimensionUOMName AS DimensionUOM,
			ISNULL(cur.Code, '') AS Currency
		FROM DBO.SalesOrderFreightAudit sf WITH (NOLOCK)
		LEFT JOIN DBO.ShippingVia sv WITH (NOLOCK) ON sf.ShipViaId = sv.ShippingViaId
		LEFT JOIN DBO.UnitOfMeasure uom WITH (NOLOCK) ON sf.UOMId = uom.UnitOfMeasureId
		LEFT JOIN DBO.UnitOfMeasure duom WITH (NOLOCK) ON sf.DimensionUOMId = duom.UnitOfMeasureId
		LEFT JOIN DBO.Currency cur WITH (NOLOCK) ON sf.CurrencyId = cur.CurrencyId
		WHERE sf.SalesOrderFreightId = @SalesOrderFreightId
		ORDER BY sf.AuditSalesOrderFreightId DESC;

	END TRY    
	BEGIN CATCH      

		DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetSalesOrderChargesBySOId'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderFreightId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END;