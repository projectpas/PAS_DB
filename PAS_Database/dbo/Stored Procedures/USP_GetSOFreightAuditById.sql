/*************************************************************           
 ** File:   [USP_GetSOFreightAuditById]           
 ** Author:   Vishal Suthar
 ** Description: Get Sales Order Freight Audit By Id
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
CREATE   PROCEDURE [dbo].[USP_GetSOFreightAuditById]
    @SalesOrderFreightId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        SELECT
            sf.AuditSalesOrderFreightId,
            sf.SalesOrderFreightId,
            sf.SalesOrderQuoteId,
            sf.SalesOrderId,
            sf.SalesOrderPartId,
            sf.Amount,
            sf.CreatedBy,
            sf.CreatedDate,
            sf.IsActive,
            sf.IsDeleted,
            sf.MasterCompanyId,
            sf.Memo,
            sf.ShipViaId,
            sf.UpdatedBy,
            sf.UpdatedDate,
            sf.Weight,
            sv.ShipVia,
            sf.Length,
            sf.Width,
            sf.Height,
            sf.UOMId,
            sf.DimensionUOMId,
            sf.CurrencyId,
            sf.MarkupFixedPrice,
            sf.BillingAmount,
            sf.BillingMethodId,
            sf.BillingRate,
            sf.HeaderMarkupId,
            sf.HeaderMarkupPercentageId,
            sf.MarkupPercentageId,
            ISNULL(uom.Description,  '') AS UOM,
            ISNULL(duom.Description, '') AS DimensionUOM,
            ISNULL(cur.Code,         '') AS Currency
        FROM dbo.SalesOrderFreightAudit sf WITH (NOLOCK)
        INNER JOIN dbo.CustomerDomensticShippingShipVia sv WITH (NOLOCK)
               ON sf.ShipViaId = sv.CustomerDomensticShippingShipViaId
        LEFT  JOIN dbo.UnitOfMeasure uom  WITH (NOLOCK) ON sf.UOMId          = uom.UnitOfMeasureId
        LEFT  JOIN dbo.UnitOfMeasure duom WITH (NOLOCK) ON sf.DimensionUOMId  = duom.UnitOfMeasureId
        LEFT  JOIN dbo.Currency cur       WITH (NOLOCK) ON sf.CurrencyId      = cur.CurrencyId
        WHERE sf.IsDeleted = 0
          AND sf.SalesOrderFreightId = @SalesOrderFreightId
        ORDER BY sf.AuditSalesOrderFreightId DESC;

    END TRY
    BEGIN CATCH

        DECLARE @ErrorLogID INT
            ,@DatabaseName VARCHAR(100) = db_name()
            ,@AdhocComments VARCHAR(150) = 'USP_GetSOFreightAuditById'
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