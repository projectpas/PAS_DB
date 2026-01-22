--EXEC USP_GetCustomerTax 13,8
CREATE PROCEDURE [dbo].[USP_GetCustomerTax] 
(
	@CustomerId bigint,
	@SiteId bigint
)
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	DECLARE @SalesTax Decimal(18,2);
	DECLARE @OtherTax Decimal(18,2);
	SELECT @SalesTax = SUM(CAST(ISNULL(TR.TaxRate,0) as Decimal(18,2))) FROM CustomerTaxTypeRateMapping CTTR WITH(NOLOCK)
	INNER JOIN dbo.TaxType TT WITH(NOLOCK) ON CTTR.TaxTypeId = TT.TaxTypeId
	INNER JOIN dbo.TaxRate TR WITH(NOLOCK) ON CTTR.TaxRateId = TR.TaxRateId
	WHERE CustomerId=@CustomerId AND SiteId=@SiteId AND TT.Code='SALES TAX' AND CTTR.IsDeleted=0 AND CTTR.IsActive=1;


	SELECT @OtherTax = SUM(CAST(ISNULL(TR.TaxRate,0) as Decimal(18,2))) FROM CustomerTaxTypeRateMapping CTTR WITH(NOLOCK)
	INNER JOIN dbo.TaxType TT WITH(NOLOCK) ON CTTR.TaxTypeId = TT.TaxTypeId
	INNER JOIN dbo.TaxRate TR WITH(NOLOCK) ON CTTR.TaxRateId = TR.TaxRateId
	WHERE CustomerId=@CustomerId AND SiteId=@SiteId AND (TT.Code != 'SALES TAX' OR TT.Code is null) AND CTTR.IsDeleted=0 AND CTTR.IsActive=1;

	SELECT ISNULL(@SalesTax,0) as SalesTax,ISNULL(@OtherTax,0) as OtherTax;
  END TRY

  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[USP_GetCustomerTax]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END