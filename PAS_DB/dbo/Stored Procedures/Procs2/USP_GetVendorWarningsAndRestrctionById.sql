/*************************************************************           
 ** File:   [USP_GetVendorWarningsAndRestrctionById]           
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used to GetVendor WarningsAndRestrction list.
 ** Purpose:         
 ** Date:   21/09/2023      
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    21/09/2023   AMIT GHEDIYA  Created
     
-- EXEC USP_GetVendorWarningsAndRestrctionById '130,20,12,2500,2501,94',7  
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetVendorWarningsAndRestrctionById]  
	@VendorId VARCHAR(MAX),
	@VendorWarningListId BIGINT
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  

    SELECT VW.VendorWarningId,
           VW.WarningMessage,
           VW.Warning,
           VW.RestrictMessage,
           VW.[Restrict],
		   VR.[VendorName],
		   VR.VendorId
	FROM [dbo].[VendorWarning] VW WITH (NOLOCK)
	INNER JOIN [dbo].[Vendor] VR WITH (NOLOCK) ON VW.VendorId = VR.VendorId
	WHERE VW.IsDeleted = 0 AND VW.IsActive = 1 AND (VW.Warning = 1 OR VW.[Restrict] = 1)
		AND VW.VendorWarningListId = @vendorWarningListId AND VW.VendorId IN(SELECT Item
FROM dbo.SplitString(@VendorId, ','));
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_VendorCreditMemoDetailsByVendorId'   
              , @ProcedureParameters VARCHAR(3000)  = '@VendorId = '''+ ISNULL(@VendorId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END