/*******************************************************************************************
** File:   [GetVendorPOMemoList]           
** Author:  Ayushi Patel
** Description: This stored procedure is used to get PO Memo list for a vendor
** Date:   30/04/2025      

** PARAMETERS: 
    @VendorId BIGINT
         
 ** RETURN VALUE:  Vendor Po Memo list           
 *******************************************************************************************           
 ** Change History           
 *******************************************************************************************           
 ** PR   Date         Author		        Change Description            
 ** --   --------     -------		    --------------------------------          
    1    30/04/2025  Ayushi Patel	    Created
     
-- exec [dbo].[GetVendorPOMemoList] @VendorId=1
*******************************************************************************************/

CREATE   PROCEDURE [dbo].[GetVendorPOMemoList]
    @VendorId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    BEGIN TRY

        SELECT DISTINCT 
            'PO' AS Module,
            po.PurchaseOrderId AS OrderNumberId,
            po.PurchaseOrderNumber AS OrderNumber,
            po.POMemo AS Notes
        FROM 
            dbo.PurchaseOrder po WITH (NOLOCK)
        WHERE 
            ISNULL(po.IsDeleted,0) = 0 
            AND ISNULL(po.IsActive,0) = 1 
            AND po.VendorId = @VendorId;

    END TRY
    BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetVendorPOMemoList' 
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