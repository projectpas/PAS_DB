/***************************************************************  
 ** File:   [USP_GetVendorNameAndCodewithId]             
 ** Author: Ayushi Patel 
 ** Description: Get Vendor Name, Code, Currency Code, etc., by VendorId
 ** Purpose:   
 ** Date:  27-May-2025  
            
 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    2025-05-27		  Ayushi Patel				Created

	exec [USP_GetVendorNameAndCodewithId] 4787
*************************************************************/
CREATE PROCEDURE [dbo].[USP_GetVendorNameAndCodewithId]
    @VendorId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
    BEGIN TRY
        SELECT 
            v.VendorId,
            v.VendorName,
            v.VendorCode,
            v.VendorParentId,
            v.IsVendorAlsoCustomer,
            v.CurrencyId,
            currency = cu.Code,
            v.IsVendorOnHold
        FROM dbo.Vendor v WITH (NOLOCK)
        LEFT JOIN dbo.Currency cu WITH (NOLOCK) ON v.CurrencyId = cu.CurrencyId
        WHERE v.VendorId = @VendorId;
    END TRY

    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_GetVendorNameAndCodewithId',
                @ProcedureParameters VARCHAR(3000) = '@VendorId = ' + CAST(ISNULL(@VendorId, 0) AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected error occurred in the database. Please let the support team know of the error number: %d',
            16, 1, @ErrorLogID
        );
        RETURN (1);
    END CATCH
END