/*************************************************************           
 ** File:   [PROCInsertVendorCreditMemoDetails]          
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to add / update vendor credit memo
 ** Purpose:         
 ** Date:   06/13/2023        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author					Change Description            
 ** --   --------     -------				--------------------------------          
    1    06/27/2023   Devendra Shekh			Created
	2    06-04-2026	  Amit Ghediya				UOM Conversion Changes [PN-15140]
    3    01/05/2026   Ayushi Patel				[PN-16258]Fixed: Stock type Credit Memo parts not saving due to INNER JOIN failure when VendorRMADetailId = 0 Changed to LEFT JOIN with dual ItemMaster path. 
declare @p1 dbo.VendorCreditMemoDetailType
insert into @p1 values(0,1,61,37,5,116,0,0,'2023-06-27 07:41:33.0540000',N'<p>fewfw</p>',1,N'ADMIN User',N'ADMIN User','2023-06-27 10:41:34.3649874','2023-06-27 10:41:34.3649901',1,0)

exec dbo.PROCInsertVendorCreditMemoDetails @TableVendorCreditMemoDetailType=@p1
**************************************************************/
   
CREATE   PROCEDURE [dbo].[PROCInsertVendorCreditMemoDetails](@TableVendorCreditMemoDetailType VendorCreditMemoDetailType READONLY)    
AS    
BEGIN    
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
  BEGIN TRY  
   BEGIN TRANSACTION  
    BEGIN  
	 DECLARE @VendorCreditMemoId AS bigint = 0; 
     IF((SELECT COUNT(VendorCreditMemoId) FROM @TableVendorCreditMemoDetailType) > 0 )  
     BEGIN  
      SET @VendorCreditMemoId = (SELECT TOP 1 VendorCreditMemoId FROM @TableVendorCreditMemoDetailType);  
		MERGE dbo.VendorCreditMemoDetail AS TARGET  
		USING
		(
			SELECT 
				SRC.*,
				([dbo].[fn_ConvertUOM](ISNULL(SRC.Qty, 0),IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,0,IM.MasterCompanyId)) AS ConvertedQty,
				([dbo].[fn_ConvertUOM](ISNULL(SRC.UnitCost, 0),IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,1,IM.MasterCompanyId)) AS ConvertedUnitCost
			FROM @TableVendorCreditMemoDetailType SRC 
			LEFT JOIN DBO.VendorRMADetail RMAD WITH (NOLOCK) ON SRC.VendorRMADetailId = RMAD.VendorRMADetailId
			LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON RMAD.ItemMasterId = IM.ItemMasterId
			LEFT JOIN DBO.Stockline SL WITH (NOLOCK) ON SRC.StockLineId = SL.StockLineId AND SRC.VendorRMADetailId = 0
            LEFT JOIN DBO.ItemMaster IM_STK WITH (NOLOCK) ON SL.ItemMasterId = IM_STK.ItemMasterId
		) AS SOURCE

		ON TARGET.VendorCreditMemoId = SOURCE.VendorCreditMemoId  
		AND TARGET.VendorCreditMemoDetailId = SOURCE.VendorCreditMemoDetailId  

		WHEN MATCHED THEN  
			UPDATE SET   
				TARGET.VendorCreditMemoId = SOURCE.VendorCreditMemoId,  
				TARGET.VendorRMADetailId = SOURCE.VendorRMADetailId,  
				TARGET.VendorRMAId = SOURCE.VendorRMAId,  
				TARGET.Qty = SOURCE.Qty,
				TARGET.OriginalAmt = SOURCE.OriginalAmt,  
				TARGET.ApplierdAmt = SOURCE.ApplierdAmt,  
				TARGET.RefundAmt = SOURCE.RefundAmt,  
				TARGET.RefundDate = SOURCE.RefundDate,  
				TARGET.Notes = SOURCE.Notes,  
				TARGET.UpdatedBy = SOURCE.UpdatedBy,  
				TARGET.UpdatedDate = GETUTCDATE(),  
				TARGET.IsActive = SOURCE.IsActive,  
				TARGET.IsDeleted = SOURCE.IsDeleted,
				TARGET.UnitCost = SOURCE.UnitCost,
				TARGET.StockLineId = SOURCE.StockLineId  

		WHEN NOT MATCHED BY TARGET THEN  
			INSERT (
				VendorCreditMemoId,
				VendorRMADetailId,
				VendorRMAId,
				Qty,
				OriginalAmt,
				ApplierdAmt,
				RefundAmt,
				RefundDate,
				Notes,
				MasterCompanyId,
				CreatedBy,
				CreatedDate,
				UpdatedBy,
				UpdatedDate,
				IsActive,
				IsDeleted,
				UnitCost,
				StockLineId
			)  
			VALUES (
				SOURCE.VendorCreditMemoId,
				SOURCE.VendorRMADetailId,
				SOURCE.VendorRMAId,
				SOURCE.ConvertedQty,         
				SOURCE.OriginalAmt,
				SOURCE.ApplierdAmt,
				SOURCE.RefundAmt,
				SOURCE.RefundDate,
				SOURCE.Notes,
				SOURCE.MasterCompanyId,
				SOURCE.CreatedBy,
				GETUTCDATE(),
				SOURCE.UpdatedBy,
				GETUTCDATE(),
				SOURCE.IsActive,
				SOURCE.IsDeleted,
				SOURCE.ConvertedUnitCost,    
				SOURCE.StockLineId
			);
	 END  
      
    END  
   COMMIT  TRANSACTION  
  END TRY    
  BEGIN CATCH        
   IF @@trancount > 0  
   PRINT 'ROLLBACK'  
            ROLLBACK TRAN;  
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'PROCInsertVendorCreditMemoDetails'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL('', '') + ''                  
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