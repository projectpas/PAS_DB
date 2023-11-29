/*************************************************************           
 ** File:   [USP_GetVendorCreditMemoDetails_ById]          
 ** Author:   Hemant  
 ** Description: Get Data to edit vendor credit memo
 ** Purpose:         
 ** Date:   21-June-2023       
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date				 Author  			Change Description            
 ** --   --------			-------			--------------------------------          
	1	22-June-2023		Devendra		created
     
EXECUTE   [dbo].[USP_GetVendorCreditMemoDetails_ById] 63
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetVendorCreditMemoDetails_ById]
@VendorCreditMemoId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 

			DECLARE @VendorRMAId BIGINT;
			SET @VendorRMAId = (SELECT ISNULL(VendorRMAId,0) VendorRMAId FROM [VendorCreditMemo] WHERE VendorCreditMemoId = @VendorCreditMemoId)

			IF (@VendorRMAId > 0)
				BEGIN
					SELECT 
					vcm.VendorCreditMemoId,
					vcm.VendorRMAId,
					vcm.VendorCreditMemoNumber,
					vcm.VendorCreditMemoStatusId,
					vcm.ApplierdAmt,
					vcm.OriginalAmt,
					vcm.RefundAmt,
					vcm.RMANum,
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
					vrm.VendorId
				FROM [DBO].[VendorCreditMemo] vcm WITH (NOLOCK)	
				LEFT JOIN [dbo].[Currency] cu WITH(NOLOCK) on vcm.CurrencyId = cu.CurrencyId
				LEFT JOIN [dbo].[VendorRMA] vrm WITH(NOLOCK) on vcm.VendorRMAId = vrm.VendorRMAId
				LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) on vrm.VendorId = v.VendorId
				LEFT JOIN [dbo].[VendorRMADetail] vrmd WITH(NOLOCK) on vrm.VendorRMAId = vrmd.VendorRMAId
				LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) on vrmd.ItemMasterId = im.ItemMasterId
				WHERE vcm.VendorCreditMemoId = @VendorCreditMemoId
				END
			ELSE 
				BEGIN
					SELECT 
					vcm.VendorCreditMemoId,
					vcm.VendorRMAId,
					vcm.VendorCreditMemoNumber,
					vcm.VendorCreditMemoStatusId,
					vcm.ApplierdAmt,
					vcm.OriginalAmt,
					vcm.RefundAmt,
					vcm.RMANum,
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
					vcm.VendorId
				FROM [DBO].[VendorCreditMemo] vcm WITH (NOLOCK)	
				LEFT JOIN [dbo].[VendorCreditMemoDetail] vcmd WITH(NOLOCK) on vcm.VendorCreditMemoId = vcmd.VendorCreditMemoId
				LEFT JOIN [dbo].[Currency] cu WITH(NOLOCK) on vcm.CurrencyId = cu.CurrencyId
				LEFT JOIN [dbo].[VendorRMA] vrm WITH(NOLOCK) on vcm.VendorRMAId = vrm.VendorRMAId
				LEFT JOIN [dbo].[VendorRMADetail] vrmd WITH(NOLOCK) on vrm.VendorRMAId = vrmd.VendorRMAId
				LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) on vrmd.ItemMasterId = im.ItemMasterId
				LEFT JOIN [dbo].[Stockline] stk WITH(NOLOCK) on vcmd.StockLineId = stk.StockLineId
				LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) on vcm.VendorId = v.VendorId
				WHERE vcm.VendorCreditMemoId = @VendorCreditMemoId
				END		
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorCreditMemoDetails_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorCreditMemoId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END