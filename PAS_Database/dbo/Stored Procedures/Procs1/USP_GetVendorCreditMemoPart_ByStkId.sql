/*************************************************************             
 ** File:   [USP_GetVendorCreditMemoPart_ByStkId]            
 ** Author:   Devendra    
 ** Description: Get Vendor RMA Parts data by itemMaster and stocklineid 
 ** Purpose:           
 ** Date:   10-July-2023         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 **	 S NO   Date			 Author			 Change Description              
 **	 --   --------		 -------		--------------------------------            
 1	 10-July-2023			Devendra		created  
 1	 12-July-2023			Devendra		changed quantity to   QuantityAvailable
       
EXECUTE   [dbo].[USP_GetVendorCreditMemoPart_ByStkId] 37,1  
**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetVendorCreditMemoPart_ByStkId]  
@StockLineId bigint,  
@ItemMasterId bigint,  
@VendorId bigint,
@VendorCreditMemoId bigint
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN   
      
    SELECT   
     vcm.VendorRMAId,  
     vcm.MasterCompanyId,  
     vcm.CreatedBy,  
     vcm.CreatedDate,  
     vcm.UpdatedBy,  
     vcm.UpdatedDate,  
     vcm.IsActive,  
     vcm.IsDeleted,  
     v.VendorName as 'Vendor',
     im.partnumber as 'PN',  
     im.PartDescription as 'PNDescription',  
     sl.StockLineNumber,  
     sl.SerialNumber,  
     ISNULL(sl.QuantityAvailable, 0) AS 'Qty',  
     im.ItemMasterId,  
     sl.StockLineId,  
	 ISNULL(sl.UnitCost, 0) AS 'UnitCost',
	 (sl.QuantityAvailable * sl.UnitCost) as 'ExtendedCost',
	 vcm.VendorCreditMemoId,
	 sl.StockLineId
    FROM [DBO].[VendorCreditMemo] vcm WITH (NOLOCK)   
    LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) on v.VendorId  = @VendorId
    LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) on im.ItemMasterId = @ItemMasterId
    LEFT JOIN [dbo].[Stockline] sl WITH(NOLOCK) on sl.StockLineId = @StockLineId  
    WHERE vcm.VendorCreditMemoId = @VendorCreditMemoId
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    --PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorCreditMemoPart_ByStkId'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@StockLineId, '') + '@Parameter2 = '''+ ISNULL(@ItemMasterId, '') +''  
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