/*************************************************************             
 ** File:   [USP_GetBulkStockScrapCertificateForPDF]             
 ** Author:  AMIT GHEDIYA  
 ** Description: This stored procedure is used to Get Bulk Stockline Scrap Certificate Adjustment Details  
 ** Purpose:           
 ** Date:   16/06/2026
            
 ** PARAMETERS: @BulkStkLineAdjId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date            Author                 Change Description              
 ** --   --------       -----------				--------------------------------            
    1    16/06/2026     Moin Bloch			Created
       
-- EXEC USP_GetBulkStockScrapCertificateForPDF 1
  
************************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetBulkStockScrapCertificateForPDF]
@BulkStockScrapCertificateId BIGINT
AS
BEGIN
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  

    SELECT
        c.BulkStockScrapCertificateId,
        c.BulkStkLineAdjId,
        c.BulkStkLineAdjDetailsId,
        c.StockLineId,
        c.IsExternal,
        c.ScrapedByEmployeeId,
        c.ScrapedByVendorId,
        c.CertifiedById,
        c.ScrapReasonId,
        c.ScrapCertificateDate,
        c.MasterCompanyId,
        c.CreatedBy,
        c.CreatedDate,
        c.UpdatedBy,
        c.UpdatedDate,
        c.IsActive,
        c.IsDeleted,
        ISNULL(sl.PartNumber, '')            AS PartNumber,
        ISNULL(sl.SerialNumber, '')          AS SerialNumber,
        ISNULL(sl.StockLineNumber, '')       AS StockLineNumber,
        sl.ManagementStructureId,           
		ISNULL(MF.[Name], '')               AS Manufacturer,
        ISNULL(sr.Reason, '')               AS ScrapReason,
        ISNULL(emp.FirstName + ' ' + emp.LastName, '') AS ScrapedByEmployee,
        ISNULL(v.VendorName, '')            AS ScrapedByVendor,
        ISNULL(certEmp.FirstName + ' ' + certEmp.LastName, '') AS CertifiedBy,
		ISNULL(sl.ControlNumber,'') AS ControlNumber,
		ISNULL(bs.BulkStkLineAdjNumber,'') AS BulkStkLineAdjNumber
    FROM [dbo].[BulkStockScrapCertificate] c WITH(NOLOCK)
	LEFT JOIN [dbo].[BulkStockLineAdjustment]   bs      WITH(NOLOCK) ON bs.BulkStkLineAdjId  = c.BulkStkLineAdjId
    LEFT JOIN [dbo].[StockLine]   sl                    WITH(NOLOCK) ON sl.StockLineId  =      c.StockLineId
    LEFT JOIN [dbo].[ScrapReason] sr                    WITH(NOLOCK) ON sr.Id           =      c.ScrapReasonId
	LEFT JOIN [dbo].[Manufacturer] MF                   WITH(NOLOCK) ON sl.ManufacturerId =    MF.ManufacturerId
    LEFT JOIN [dbo].[Employee]    emp                   WITH(NOLOCK) ON emp.EmployeeId  =      c.ScrapedByEmployeeId
    LEFT JOIN [dbo].[Vendor]      v                     WITH(NOLOCK) ON v.VendorId      =      c.ScrapedByVendorId
    LEFT JOIN [dbo].[Employee]    certEmp               WITH(NOLOCK) ON certEmp.EmployeeId =   c.CertifiedById
    WHERE c.BulkStockScrapCertificateId = @BulkStockScrapCertificateId
      AND c.IsDeleted = 0;
	
END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_GetBulkStockScrapCertificateForPDF'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@BulkStockScrapCertificateId, '') + ''  
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