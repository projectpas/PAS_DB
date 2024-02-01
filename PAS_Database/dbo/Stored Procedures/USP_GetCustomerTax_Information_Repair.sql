/*************************************************************           
 ** File:   [USP_GetCustomerTax_Information_ProductSale]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get Customer Tax Information based on Repair
 ** Purpose:         
 ** Date:   01/02/2024        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/02/2024   Moin Bloch    Created
     
-- EXEC [USP_GetCustomerTax_Information_Repair] 3932,5064,19,0,0
**************************************************************/
create    PROCEDURE [dbo].[USP_GetCustomerTax_Information_Repair] 
@CustomerId BIGINT,
@SiteId BIGINT,   -- ship to site
@OriginSiteId BIGINT, -- origin site
@TotalSalesTax DECIMAL(18,2) OUTPUT,
@TotalOtherTax DECIMAL(18,2) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	DECLARE @SalesTax Decimal(18,2) = 0;
	DECLARE @OtherTax Decimal(18,2) = 0;

	SELECT @SalesTax = SUM(CAST(ISNULL(TR.TaxRate,0) AS DECIMAL(18,2))) 
	FROM [dbo].[CustomerTaxTypeRateMapping] CTTR WITH(NOLOCK)
	INNER JOIN [dbo].[TaxType] TT WITH(NOLOCK) ON CTTR.TaxTypeId = TT.TaxTypeId
	INNER JOIN [dbo].[TaxRate] TR WITH(NOLOCK) ON CTTR.TaxRateId = TR.TaxRateId
	WHERE CustomerId = @CustomerId 
	  AND SiteId = @SiteId 
	  AND ShipFromSiteId = @OriginSiteId 
	  AND IsRepair = 1
	  AND IsTaxExempt = 0
	  AND TT.Code='SALES TAX' 
	  AND CTTR.IsDeleted=0 
	  AND CTTR.IsActive=1;

	SELECT @OtherTax = SUM(CAST(ISNULL(TR.TaxRate,0) AS DECIMAL(18,2))) 
	FROM [dbo].[CustomerTaxTypeRateMapping] CTTR WITH(NOLOCK)
	INNER JOIN [dbo].[TaxType] TT WITH(NOLOCK) ON CTTR.TaxTypeId = TT.TaxTypeId
	INNER JOIN [dbo].[TaxRate] TR WITH(NOLOCK) ON CTTR.TaxRateId = TR.TaxRateId
	WHERE CustomerId=@CustomerId 
	  AND SiteId=@SiteId 
	  AND ShipFromSiteId = @OriginSiteId 
	  AND IsRepair = 1
	  AND IsTaxExempt = 0
	  AND (TT.Code != 'SALES TAX' OR TT.Code IS NULL) 
	  AND CTTR.IsDeleted=0 
	  AND CTTR.IsActive=1;

	SET  @TotalSalesTax = ISNULL(@SalesTax,0) 
	SET  @TotalOtherTax = ISNULL(@OtherTax,0)

  END TRY

  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[USP_GetCustomerTax_Information_Repair]',
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