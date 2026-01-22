/*************************************************************           
 ** File:   [USP_CheckVendorDefaultPaymentMethod]           
 ** Author:  Ayushi Patel
 ** Description: This stored procedure is used GetPriceMasterHistoryById
 ** Purpose:         
 ** Date:   13/05/2025      
          
 ** PARAMETERS: @VendorId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    13/05/2025  Ayushi Patel     Created
     
-- exec [dbo].[USP_CheckVendorDefaultPaymentMethod]4784
************************************************************************/
CREATE PROCEDURE [dbo].[USP_CheckVendorDefaultPaymentMethod]
    @VendorId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        SELECT 
            IsCheckPayment = 
                CASE 
                    WHEN EXISTS (
                        SELECT 1 
                        FROM dbo.VendorCheckPayment vcp WITH (NOLOCK)
                        INNER JOIN dbo.CheckPayment cp WITH (NOLOCK)
                            ON vcp.CheckPaymentId = cp.CheckPaymentId
                        WHERE vcp.VendorId = v.VendorId
                          AND ISNULL(cp.IsDeleted,0) = 0 AND ISNULL(cp.IsActive,0) = 1
                    ) THEN CAST(1 AS BIT)
                    ELSE CAST(0 AS BIT)
                END,
            IsDomesticWirePayment =
                CASE 
                    WHEN EXISTS (
                        SELECT 1 
                        FROM dbo.VendorDomesticWirePayment vdp WITH (NOLOCK)
                        WHERE vdp.VendorId = v.VendorId
                    ) THEN CAST(1 AS BIT)
                    ELSE CAST(0 AS BIT)
                END,
            IsInternationlWirePayment =
                CASE 
                    WHEN EXISTS (
                        SELECT 1 
                        FROM dbo.VendorInternationlWirePayment iwp WITH (NOLOCK)
                        WHERE iwp.VendorId = v.VendorId
                    ) THEN CAST(1 AS BIT)
                    ELSE CAST(0 AS BIT)
                END
        FROM dbo.Vendor v WITH (NOLOCK)
        WHERE v.VendorId = @VendorId AND ISNULL(v.IsActive,0) = 1 AND ISNULL(v.IsDeleted,0) = 0;
    END TRY
    BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_CheckVendorDefaultPaymentMethod' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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
END