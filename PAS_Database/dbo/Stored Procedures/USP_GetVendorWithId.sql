/*****************************************************************************************
** File:        [USP_GetVendorWithId]
** Author:      Ayushi Patel
** Description: This stored procedure returns vendor data by VendorId including related
**              CreditTerms, Currency, and Discount information.
** Purpose:     Used to retrieve detailed vendor info by VendorId.
** Date:        24/04/2025 
**
** Parameters:
** @VendorId BIGINT
**
** Return Value:
**
******************************************************************************************
** Change History
******************************************************************************************
** PR   Date        Author        Change Description
** --   ----------  ------------  --------------------------------------------------------
** 1    24/04/2025  Ayushi Patel    Created
**
** Example: EXEC [USP_GetVendorWithId] 4777
******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetVendorWithId]
    @VendorId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT 
            v.VendorId,
            v.VendorCode,
            v.VendorName,
            v.CreditTermsId,
            v.CreditLimit,
            v.CurrencyId,
            v.DiscountId,
            ISNULL(ct.Name, '') AS CreditTerms,
            ISNULL(cu.Code, '') AS Currency,
            ISNULL(d.DiscontValue, 0) AS DiscontValue,
            v.Is1099Required,
            v.IsAllowNettingAPAR,
            v.TaxIdNumber
        FROM dbo.Vendor v WITH (NOLOCK)
        LEFT JOIN dbo.CreditTerms ct WITH (NOLOCK) ON v.CreditTermsId = ct.CreditTermsId
        LEFT JOIN dbo.Currency cu WITH (NOLOCK) ON v.CurrencyId = cu.CurrencyId
        LEFT JOIN dbo.Discount d WITH (NOLOCK) ON v.DiscountId = d.DiscountId
        WHERE v.VendorId = @VendorId;
    END TRY
    BEGIN CATCH
        DECLARE 
            @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments VARCHAR(150) = 'USP_GetVendorWithId',
            @ProcedureParameters VARCHAR(3000) = '@VendorId=' + CAST(@VendorId AS VARCHAR),
            @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occurred. Contact support with Error ID: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END;