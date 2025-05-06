/*******************************************************************************************
** File:   [GetVendorROMemoList]           
** Author:  Ayushi Patel
** Description: This stored procedure is used to get RO Memo list for a vendor
** Date:   01/05/2025      

** PARAMETERS: 
    @VendorId BIGINT
         
 ** RETURN VALUE:  Vendor Po Memo list           
 *******************************************************************************************           
 ** Change History           
 *******************************************************************************************           
 ** PR   Date         Author		        Change Description            
 ** --   --------     -------		    --------------------------------          
    1    01/05/2025  Ayushi Patel	    Created
     
-- exec [dbo].[GetVendorROMemoList] @VendorId=1
*******************************************************************************************/
CREATE   PROCEDURE [dbo].[GetVendorROMemoList]
    @VendorId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    BEGIN TRY
        SELECT DISTINCT 
            'RO' AS Module,
            ro.RepairOrderId AS OrderNumberId,
            ro.RepairOrderNumber AS OrderNumber,
            ro.RoMemo AS Notes
        FROM 
            dbo.RepairOrder ro WITH (NOLOCK)
        WHERE 
            ISNULL(ro.IsDeleted,0) = 0
            AND ISNULL(ro.IsActive,0) = 1
            AND ro.VendorId = @VendorId;
    END TRY
    BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetVendorROMemoList' 
            , @ProcedureParameters VARCHAR(3000)  = ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
					  @DatabaseName        = @DatabaseName
                    , @AdhocComments       = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName     =  @ApplicationName
                    , @ErrorLogID          = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END