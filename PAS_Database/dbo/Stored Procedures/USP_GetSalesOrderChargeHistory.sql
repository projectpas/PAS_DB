/***************************************************************  
 ** File:   [USP_GetSalesOrderChargeHistory]             
 ** Author:   Shrey Chandegara
 ** Description: Get Sales Order Charge History
 ** Date:  01-04-2025
            
  ** Change   
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    03-04-2025		Shrey Chandegara		Created  	
		
	exec dbo.USP_GetSalesOrderChargeHistory 760,228
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSalesOrderChargeHistory]
@SalesOrderChargeId BIGINT,
@EmployeeId BIGINT

AS 
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @TANDMId BIGINT = 0,@ActualId BIGINT = 0,@FlatId BIGINT = 0;
	SET @TANDMId = (SELECT BillingMethodId FROM [dbo].[BillingMethod] WITH(NOLOCK) WHERE Description = 'T&M');
	SET @ActualId = (SELECT BillingMethodId FROM [dbo].[BillingMethod] WITH(NOLOCK) WHERE Description = 'Actual');
	SET @FlatId = (SELECT BillingMethodId FROM [dbo].[BillingMethod] WITH(NOLOCK) WHERE Description = 'Flate Rate');

	DECLARE @TANDM VARCHAR(250) = '',@Actual VARCHAR(250) = '',@Flat VARCHAR(250) = '';
	SET @TANDM = (SELECT Description FROM [dbo].[BillingMethod] WITH(NOLOCK) WHERE BillingMethodId = @TANDMId);
	SET @Actual = (SELECT Description FROM [dbo].[BillingMethod] WITH(NOLOCK) WHERE BillingMethodId = @ActualId);
	SET @Flat = (SELECT Description FROM [dbo].[BillingMethod] WITH(NOLOCK) WHERE BillingMethodId = @FlatId);

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
			soc.AuditSalesOrderChargesId,
			soc.SalesOrderChargesId,
			soc.SalesOrderQuoteId,
			soc.SalesOrderPartId,
			soc.ChargesTypeId,
			ct.ChargeType AS ChargeType,
			soc.Description,
			soc.Quantity,
			soc.UnitCost,
			soc.ExtendedCost,
			soc.MarkupFixedPrice,
			soc.VendorId,
			ISNULL(v.VendorName, '') AS VendorName,
			soc.BillingMethodId,
			CASE 
				WHEN soc.BillingMethodId = @TANDMId THEN @TANDM
				WHEN soc.BillingMethodId = @ActualId THEN @Actual
				WHEN soc.BillingMethodId = @FlatId THEN @Flat
				ELSE ''
			END AS BillingMethodName,
			soc.BillingRate,
			soc.BillingAmount,
			soc.MarkupPercentageId,
			soc.CreatedBy,
			(Cast(DBO.ConvertUTCtoLocal(soc.CreatedDate, @CurrntEmpTimeZoneDesc) as DATETIME)) CreatedDate,
			(Cast(DBO.ConvertUTCtoLocal(soc.UpdatedDate, @CurrntEmpTimeZoneDesc) as DATETIME)) UpdatedDate,
			soc.IsActive,
			soc.IsDeleted,
			soc.MasterCompanyId,
			soc.HeaderMarkupId,
			soc.HeaderMarkupPercentageId,
			soc.UpdatedBy,
			soc.RefNum,
			ISNULL(gl.AccountName, '') AS GLAccountName,
			soc.UOMId,
			ISNULL(um.ShortName, '') AS UOM
		FROM [dbo].[SalesOrderChargesAudit] soc WITH (NOLOCK)
		INNER JOIN [dbo].[Charge] ct WITH (NOLOCK) ON soc.ChargesTypeId = ct.ChargeId
		LEFT JOIN [dbo].[UnitOfMeasure] um WITH (NOLOCK) ON soc.UOMId = um.UnitOfMeasureId
		LEFT JOIN [dbo].[Vendor] v WITH (NOLOCK) ON soc.VendorId = v.VendorId
		LEFT JOIN [dbo].[GLAccount] gl WITH (NOLOCK) ON ct.GLAccountId = gl.GLAccountId
		WHERE soc.SalesOrderChargesId = @SalesOrderChargeId
		ORDER BY soc.AuditSalesOrderChargesId DESC;

	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSalesOrderChargeHistory' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderChargeId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END