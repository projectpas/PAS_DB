/*************************************************************           
 ** File:  [USP_GetVendorWarningWithId]  
 ** Author:   Ayushi Patel
 ** Description: Get vendor-level restriction/warning/allow flags and related warning messages.
 ** Purpose:  Fetch Vendor IsAllow, IsRestrict, IsWarning flags with nested vendor warning data         
 ** Date:   02-07-2025
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR     Date         Author		     	Change Description            
 ** --    --------     -------			-------------------------------          
    1     02-07-2025   Ayushi Patel		Created
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetVendorWarningWithId]
    @VendorId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT 
            ISNULL(V.IsAllow,0) AS IsAllow,
            ISNULL(V.IsRestrict,0) AS IsRestrict,
            ISNULL(V.IsWarning,0) AS IsWarning,
            V.VendorId,
            V.UpdatedBy,
            VW.VendorWarningId,
            VW.VendorWarningListId,
            VW.WarningMessage,
            VW.RestrictMessage,
            VW.MasterCompanyId,
            VW.CreatedBy,
            VW.UpdatedBy AS WarningUpdatedBy,
            VW.CreatedDate,
            VW.UpdatedDate,
            ISNULL(VW.IsActive,0) AS IsActive,
            VW.Allow,
            VW.[Restrict],
            VW.Warning
        FROM dbo.Vendor V WITH (NOLOCK)
        LEFT JOIN dbo.VendorWarning VW WITH (NOLOCK) ON V.VendorId = VW.VendorId AND VW.IsActive = 1
        WHERE V.VendorId = @VendorId;
    END TRY
    BEGIN CATCH
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorWarningWithId' 
            , @ProcedureParameters VARCHAR(3000)  = ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName			=  @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
    END CATCH
END