/*******************************************************************************************
 ** File:   [USP_GetVendorContactDataByVendorId]          
 ** Author:  Ayushi Patel
 ** Description: Returns Vendor Contact Data By VendorId
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
    2    25/03/2026  Bhargav Saliya	    PN-15807: Added Null able VendorContactId
    3    31/07/2026  Bhargav Saliya	    PN-17507: Added [IsActive] 
     
-- EXEC [USP_GetVendorContactDataByVendorId] NULL , 132 , 20 , 0 ,1
********************************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetVendorContactDataByVendorId]
    @VendorId BIGINT,
	@VendorContactId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        SELECT 
            vc.VendorContactId,
            c.ContactId,
            VendorContact = CONCAT(ISNULL(c.FirstName, ''), ' ', ISNULL(c.LastName, '')),
            WorkPhone = ISNULL(c.WorkPhone, ''),
            c.WorkPhoneExtn,
            ISNULL(vc.IsDefaultContact,0) AS IsDefaultContact,
            FullContactNo = 
                CASE 
                    WHEN ISNULL(c.WorkPhone, '') = '' THEN ''
                    WHEN ISNULL(c.WorkPhoneExtn, '') = '' THEN c.WorkPhone
                    ELSE CONCAT(c.WorkPhone, ' - ', c.WorkPhoneExtn)
                END,
            Email = ISNULL(c.Email, ''),
            ContractReferenceName = ISNULL(v.VendorContractReference, '')
        FROM dbo.VendorContact vc WITH (NOLOCK)
        INNER JOIN dbo.Contact c WITH (NOLOCK) ON vc.ContactId = c.ContactId
        LEFT JOIN dbo.Vendor v WITH (NOLOCK) ON v.VendorId = vc.VendorId
        WHERE vc.VendorId = @VendorId AND ((ISNULL(vc.IsDeleted, 0) = 0 AND ISNULL(vc.IsActive, 0) = 1) OR vc.VendorContactId = @VendorContactId)
    END TRY
    BEGIN CATCH
   DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorContactDataByVendorId'
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