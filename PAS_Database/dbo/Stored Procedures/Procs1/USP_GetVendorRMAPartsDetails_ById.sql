/*************************************************************             
 ** File:   [USP_GetVendorRMAPartsDetails_ById]            
 ** Author:   Devendra    
 ** Description: Get Vendor RMA Parts data by vendorrmaid and credit memo id  
 ** Purpose:           
 ** Date:   27-June-2023         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date     Author     Change Description              
 ** --   --------   -------   --------------------------------            
 1 27-June-2023  Devendra  created  
       
EXECUTE   [dbo].[USP_GetVendorRMAPartsDetails_ById] 37,1  
**************************************************************/  
Create   PROCEDURE [dbo].[USP_GetVendorRMAPartsDetails_ById]  
@VRMAId bigint,  
@VendorCreditMemoId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN   
      
    SELECT   
     vcm.VendorCreditMemoId,  
     vcm.VendorRMAId,  
     vcm.VendorCreditMemoNumber,  
     vcm.VendorCreditMemoStatusId,  
     vcm.ApplierdAmt,  
     vcm.OriginalAmt,  
     vcm.RefundAmt,  
     vrmd.RMANum,  
     vcm.CurrencyId,  
     vcm.RefundDate,  
     vcm.MasterCompanyId,  
     vcm.CreatedBy,  
     vcm.CreatedDate,  
     vcm.UpdatedBy,  
     vcm.UpdatedDate,  
     vcm.IsActive,  
     vcm.IsDeleted,  
     ISNULL(cu.Code, '') as 'Currency',  
     v.VendorName as 'Vendor',  
     im.partnumber,  
     im.PartDescription,  
     sl.StockLineNumber,  
     sl.SerialNumber,  
     ISNULL(vrmd.Qty, 0) AS 'Qty',  
     vrmd.ItemMasterId,  
     vrmd.StockLineId,  
     vrmd.VendorRMADetailId,
	 ISNULL(sl.UnitCost, 0) AS 'UnitCost',
	 (vrmd.Qty * sl.UnitCost) as 'ExtendedCost'
    FROM [DBO].[VendorCreditMemo] vcm WITH (NOLOCK)   
    LEFT JOIN [dbo].[Currency] cu WITH(NOLOCK) on vcm.CurrencyId = cu.CurrencyId  
    LEFT JOIN [dbo].[VendorRMA] vrm WITH(NOLOCK) on vcm.VendorRMAId = vrm.VendorRMAId  
    LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) on vrm.VendorId = v.VendorId  
    LEFT JOIN [dbo].[VendorRMADetail] vrmd WITH(NOLOCK) on vrm.VendorRMAId = vrmd.VendorRMAId  
    LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) on vrmd.ItemMasterId = im.ItemMasterId  
    LEFT JOIN [dbo].[Stockline] sl WITH(NOLOCK) on vrmd.StockLineId = sl.StockLineId  
    WHERE vrmd.[VendorRMAId] = @VRMAId and vcm.VendorCreditMemoId = @VendorCreditMemoId  
                  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    --PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorRMAPartsDetails_ById'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VRMAId, '') + ''  
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