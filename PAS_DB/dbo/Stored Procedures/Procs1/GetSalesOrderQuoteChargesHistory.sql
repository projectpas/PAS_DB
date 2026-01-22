/*************************************************************             
 ** File:   [GetSalesOrderQuoteChargesHistory]            
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used GetSalesOrderQuoteChargesHistory
 ** Purpose:           
 ** Date:  16/12/2024        
            
 ** PARAMETERS: @SalesOrderQuoteChargesId bigint 
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    16/12/2024		EKTA CHANDEGRA	 Created  
	2    27/02/2025     Ayushi Patel     converted the date into utc (created , updated) , Added a case to get timeZone

 EXEC GetSalesOrderQuoteChargesHistory 281 
************************************************************************/  
CREATE   PROCEDURE [dbo].[GetSalesOrderQuoteChargesHistory]
    @SalesOrderQuoteChargesId BIGINT,
	@EmployeeId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
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
						E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

		SELECT DISTINCT
			soc.AuditSalesOrderQuoteChargesId,
			soc.SalesOrderQuoteChargesId,
			soc.SalesOrderQuoteId,
			soc.SalesOrderQuotePartId,
			soc.ChargesTypeId,
			ct.ChargeType,
			ISNULL(soc.Description,'') AS Description,
			ISNULL(soc.Quantity,0) AS Quantity,
			ISNULL(soc.UnitCost,0) AS UnitCost,
			ISNULL(soc.ExtendedCost,0) AS ExtendedCost,
			ISNULL(soc.MarkupFixedPrice,0) AS MarkupFixedPrice,
			ISNULL(soc.VendorId,0) AS VendorId,
			ISNULL(soc.VendorName,'') AS VendorName,
			soc.BillingMethodId,
			'' AS BillingMethodName,
			ISNULL(soc.BillingRate,0) AS BillingRate,
			ISNULL(soc.BillingAmount,0) AS BillingAmount,
			ISNULL(soc.MarkupPercentageId,0) AS MarkupPercentageId,
			soc.CreatedBy,
			--soc.CreatedDate,
			case when CAST(soc.CreatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(soc.CreatedDate, @CurrntEmpTimeZoneDesc) as datetime))end CreatedDate,
			soc.IsActive,
			soc.IsDeleted,
			soc.MasterCompanyId,
			soc.HeaderMarkupId,
			soc.HeaderMarkupPercentageId,
			soc.UpdatedBy,
			--soc.UpdatedDate,
			case when CAST(soc.UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(soc.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime))end UpdatedDate,
			ISNULL(soc.RefNum,'') AS RefNum,
			ISNULL(gl.AccountName, '') AS GLAccountName,
			ISNULL(uom.ShortName, '') AS UOMName
		FROM [dbo].[SalesOrderQuoteChargesAudit] soc WITH(NOLOCK)
		INNER JOIN [dbo].[Charge] ct WITH(NOLOCK) ON soc.ChargesTypeId = ct.ChargeId
		LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON ct.GLAccountId = gl.GLAccountId
		LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON soc.UnitOfMeasureId = uom.UnitOfMeasureId
		WHERE soc.SalesOrderQuoteChargesId = @SalesOrderQuoteChargesId
		AND soc.ChargeName IS NOT NULL
		ORDER BY soc.AuditSalesOrderQuoteChargesId DESC;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderQuoteChargesHistory'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderQuoteChargesId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
            RETURN(1); 
	END CATCH
END;