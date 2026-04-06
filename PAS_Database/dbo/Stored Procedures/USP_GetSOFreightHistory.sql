/*************************************************************           
 ** File:   [USP_GetSOFreightHistory]           
 ** Author:   Vishal Suthar
 ** Description: Get Sales Order Freight History By Id
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
CREATE   PROCEDURE [dbo].[USP_GetSOFreightHistory]
    @SalesOrderFreightId BIGINT,
    @EmployeeId          BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @TimeZone VARCHAR(100);

		SELECT @TimeZone = COALESCE(ETZ.[Description], LTZ.[Description])
        FROM dbo.Employee E WITH (NOLOCK)
        LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
        LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
        LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
        WHERE E.EmployeeId = @EmployeeId;

        SELECT
            sf.AuditSalesOrderFreightId,
            sf.SalesOrderFreightId,
            sf.SalesOrderQuoteId,
            sf.SalesOrderId,
            sf.SalesOrderPartId,
            sf.Amount,
            sf.CreatedBy,
            CreatedDate  = CONVERT(DATETIME, SWITCHOFFSET(CONVERT(DATETIMEOFFSET, sf.CreatedDate),  DATENAME(TzOffset, SYSDATETIMEOFFSET() AT TIME ZONE @TimeZone))),
            sf.IsActive,
            sf.IsDeleted,
            sf.MasterCompanyId,
            sf.Memo,
            sf.ShipViaId,
            sf.UpdatedBy,
            UpdatedDate  = CONVERT(DATETIME, SWITCHOFFSET(CONVERT(DATETIMEOFFSET, sf.UpdatedDate),  DATENAME(TzOffset, SYSDATETIMEOFFSET() AT TIME ZONE @TimeZone))),
            sf.Weight,
            ShipVia      = sv.Name,
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
            BillingMethodName = CASE sf.BillingMethodId
                                    WHEN 1 THEN 'T&M'
                                    WHEN 2 THEN 'Actual'
                                    ELSE ''
                                END,
            sf.BillingRate,
            sf.BillingAmount,
            UOM          = ISNULL(sf.UOMName, ''),
            DimensionUOM = ISNULL(sf.DimensionUOMName, ''),
            Currency     = ISNULL(cur.Code, '')
        FROM dbo.SalesOrderFreightAudit sf WITH (NOLOCK)
        INNER JOIN dbo.ShippingVia sv   WITH (NOLOCK) ON sf.ShipViaId  = sv.ShippingViaId
        LEFT  JOIN dbo.Currency cur     WITH (NOLOCK) ON sf.CurrencyId = cur.CurrencyId
        WHERE sf.SalesOrderFreightId = @SalesOrderFreightId
        ORDER BY sf.AuditSalesOrderFreightId DESC;

    END TRY
    BEGIN CATCH

        DECLARE @ErrorLogID INT
            ,@DatabaseName VARCHAR(100) = db_name()
            ,@AdhocComments VARCHAR(150) = 'USP_GetSOFreightHistory'
            ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderFreightId, '') AS VARCHAR(100))
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