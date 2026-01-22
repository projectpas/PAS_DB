/*************************************************************             
 ** File:   [USP_GetVendorRMAPart_ByStkId]            
 ** Author:   Devendra    
 ** Description: Get Vendor RMA Parts data by vendorrmaid and stocklineid 
 ** Purpose:           
 ** Date:   27-June-2023         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date     Author     Change Description              
 ** --   --------   -------   --------------------------------            
 1 28-June-2023  Devendra  created  
       
EXECUTE   [dbo].[USP_GetVendorRMAPart_ByStkId] 37,1  
**************************************************************/  
Create   PROCEDURE [dbo].[USP_GetVendorRMAPart_ByStkId]  
@StockLineId bigint,  
@VendorRMAId bigint,
@VendorCreditMemoId bigint
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN   
      
    SELECT   
     vrm.VendorRMAId,  
     vrm.MasterCompanyId,  
     vrm.CreatedBy,  
     vrm.CreatedDate,  
     vrm.UpdatedBy,  
     vrm.UpdatedDate,  
     vrm.IsActive,  
     vrm.IsDeleted,  
     v.VendorName as 'Vendor',
     im.partnumber as 'PN',  
     im.PartDescription as 'PNDescription',  
     sl.StockLineNumber,  
     sl.SerialNumber,  
     ISNULL(vrmd.Qty, 0) AS 'Qty',  
     vrmd.ItemMasterId,  
     vrmd.StockLineId,  
     vrmd.VendorRMADetailId,
	 ISNULL(sl.UnitCost, 0) AS 'UnitCost',
	 (vrmd.Qty * sl.UnitCost) as 'ExtendedCost',
	 vcm.VendorCreditMemoId,
	 vrmd.RMANum,
	 vrmd.StockLineId
    FROM [DBO].[VendorRMA] vrm WITH (NOLOCK)   
    LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) on vrm.VendorId = v.VendorId  
    LEFT JOIN [dbo].[VendorRMADetail] vrmd WITH(NOLOCK) on vrm.VendorRMAId = vrmd.VendorRMAId  
    LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) on vrmd.ItemMasterId = im.ItemMasterId  
    LEFT JOIN [dbo].[Stockline] sl WITH(NOLOCK) on vrmd.StockLineId = sl.StockLineId  
    LEFT JOIN [dbo].[VendorCreditMemo] vcm WITH(NOLOCK) on vcm.VendorRMAId = vrm.VendorRMAId  
    WHERE vrmd.[VendorRMAId] = @VendorRMAId and vrmd.StockLineId = @StockLineId  AND vcm.VendorCreditMemoId = @VendorCreditMemoId
                  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    --PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorRMAPart_ByStkId'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@StockLineId, '') + '@Parameter2 = '''+ ISNULL(@VendorRMAId, '') +''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName         = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END