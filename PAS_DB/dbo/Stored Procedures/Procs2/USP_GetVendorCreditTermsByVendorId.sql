/*******************************************************************************************
 ** File:   [USP_GetVendorCreditTermsByVendorId]          
 ** Author:  Ayushi Patel
 ** Description: Returns Vendor Credit Terms By VendorId
 ** Purpose:         
 ** Date:   12/05/2025      
          
 ** PARAMETERS: 
   @VendorId BIGINT
         
 ** RETURN VALUE:          
 *******************************************************************************************           
 ** Change History           
 *******************************************************************************************           
 ** PR   Date         Author		        Change Description            
 ** --   --------     -------		    --------------------------------          
    1    12/05/2025  Ayushi Patel	    Created
	2    27/01/2025  Sahdev Saliya      Added NetDays
     
-- EXEC [USP_GetVendorCreditTermsByVendorId] 132
********************************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetVendorCreditTermsByVendorId]
    @VendorId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        SELECT 
            v.CreditTermsId,
            v.CreditLimit,
            ISNULL(ct.Name, '') AS CreditTerms,
			ct.NetDays
        FROM dbo.Vendor v WITH (NOLOCK)
        LEFT JOIN dbo.CreditTerms ct WITH (NOLOCK) ON v.CreditTermsId = ct.CreditTermsId
        WHERE v.VendorId = @VendorId
          AND (ISNULL(ct.IsActive,0) = 1 AND ISNULL(ct.IsDeleted,0) = 0)
    END TRY
    BEGIN CATCH
   DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorCreditTermsByVendorId'
            , @ProcedureParameters VARCHAR(3000)  = ''  
            , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
            exec spLogException   
                    @DatabaseName   = @DatabaseName  
                    , @AdhocComments   = @AdhocComments  
                    , @ProcedureParameters  = @ProcedureParameters  
                    , @ApplicationName   =  @ApplicationName  
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;  
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
            RETURN(1);  
    END CATCH
END