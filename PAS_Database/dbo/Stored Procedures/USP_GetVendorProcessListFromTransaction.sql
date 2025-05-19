/*******************************************************************************************
 ** File:   [USP_GetVendorProcessListFromTransaction]           
 ** Author:  Ayushi Patel
 ** Description: Returns active, non-deleted VendorProcess1099 records for a given VendorId along with Master1099 details.
 ** Purpose:         
 ** Date:   07/05/2025      
          
 ** PARAMETERS: 
    @VendorId BIGINT
         
 ** RETURN VALUE:          
 *******************************************************************************************           
 ** Change History           
 *******************************************************************************************           
 ** PR   Date         Author		        Change Description            
 ** --   --------     -------		    --------------------------------          
    1    07/05/2025  Ayushi Patel	    Created
     
-- EXEC USP_GetVendorProcessListFromTransaction @VendorId = 123
********************************************************************************************/
CREATE   PROCEDURE USP_GetVendorProcessListFromTransaction
(
    @VendorId BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        SELECT DISTINCT
            vp.VendorProcess1099Id,
            vp.Master1099Id,
            vp.IsDefaultCheck,
            vp.IsDefaultRadio,
            m1099.Description,
            m1099.Name,
            vp.CreatedBy,
            vp.UpdatedBy,
            vp.MasterCompanyId
        FROM DBO.Master1099 m1099 WITH (NOLOCK)
        LEFT JOIN DBO.VendorProcess1099 vp WITH (NOLOCK) ON m1099.Master1099Id = vp.Master1099Id
        WHERE
            vp.VendorId = @VendorId
            AND ISNULL(m1099.IsDeleted, 0) = 0
            AND ISNULL(m1099.IsActive, 0) = 1
            AND ISNULL(vp.IsDeleted, 0) = 0
            AND ISNULL(vp.IsActive, 0) = 1;
    END TRY
    BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorProcessListFromTransaction' 
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