/*************************************************************           
 ** File:   [GetVendorCreditMemoPartsById]           
 ** Author: Devendra SHekh
 ** Description: This stored procedure is used to Get Vendor Credit Memo Part Details
 ** Purpose:         
 ** Date:   27/6/2023     
          
 ** PARAMETERS: @VendorCreditMemoId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    27/06/2023  Devendra SHekh     Created
	2    06-04-2026	  Amit Ghediya		UOM Conversion Changes [PN-15140]
    3    08-05-2026  Ayushi Patel       return Qty and UnitCost price as it is [PN-15140] 
	4    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	5    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
-- EXEC [GetVendorCreditMemoPartsById] 30
************************************************************************/
CREATE   PROCEDURE [dbo].[GetVendorCreditMemoPartsById]
@VendorCreditMemoId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	DECLARE @VendorRMAId BIGINT;
	SET @VendorRMAId = (SELECT ISNULL(VendorRMAId,0) VendorRMAId FROM [VendorCreditMemo] WHERE VendorCreditMemoId = @VendorCreditMemoId)


	IF (@VendorRMAId > 0)
		BEGIN
			SELECT CM.[VendorCreditMemoDetailId]
					,CM.[VendorCreditMemoId]
					,CM.[VendorRMADetailId]
					,CM.[VendorRMAId]
					,CM.[Qty]
					,CM.[OriginalAmt]
					,CM.[ApplierdAmt]
					,CM.[RefundAmt]
					,CM.[RefundDate]
					,CM.[Notes]
					,CM.[MasterCompanyId]
					,CM.[CreatedBy]
					,CM.[UpdatedBy]
					,CM.[CreatedDate]
					,CM.[UpdatedDate]
					,CM.[IsActive]
					,CM.[IsDeleted]
					,sl.[SerialNumber]
					,sl.[StockLineNumber]
					,im.[partnumber] as 'PN'
					,im.[PartDescription] as 'PNDescription'
					,v.[VendorName] as 'Vendor'
					,vrmd.ItemMasterId
					,vrmd.StockLineId
					,sl.UnitCost
					,vrmd.RMANum
		  FROM [dbo].[VendorCreditMemoDetail] CM WITH (NOLOCK) 		
			   --LEFT JOIN VendorCreditMemo vcm WITH (NOLOCK) ON CM.VendorCreditMemoId = vcm.VendorCreditMemodId
			   LEFT JOIN VendorRMADetail vrmd WITH (NOLOCK) ON CM.VendorRMADetailId = vrmd.[VendorRMADetailId]
			   LEFT JOIN Stockline sl WITH (NOLOCK) ON vrmd.StockLineId = sl.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
			   LEFT JOIN ItemMaster IM WITH (NOLOCK) ON vrmd.ItemMasterId=IM.ItemMasterId
			    AND ISNULL(IM.IsNonStock,0) = 0
			   LEFT JOIN VendorRMA vr WITH (NOLOCK) ON vr.VendorRMAId = CM.VendorRMAId
			   LEFT JOIN Vendor v WITH (NOLOCK) ON vr.VendorId = v.VendorId
			  WHERE CM.[VendorCreditMemoId] = @VendorCreditMemoId AND CM.IsDeleted = 0 ;
		END
		ELSE 
			BEGIN
				SELECT CM.[VendorCreditMemoDetailId]
					,CM.[VendorCreditMemoId]
					,CM.[VendorRMADetailId]
					,CM.[VendorRMAId]
					,CM.[Qty]
					--,([dbo].[fn_ConvertUOM](ISNULL(CM.[Qty], 0),IM.[StockUnitOfMeasure], IM.[PurchaseUnitOfMeasure],0,IM.[MasterCompanyId])) AS 'Qty'
					,CM.[OriginalAmt]
					,CM.[ApplierdAmt]
					,CM.[RefundAmt]
					,CM.[RefundDate]
					,CM.[Notes]
					,CM.[MasterCompanyId]
					,CM.[CreatedBy]
					,CM.[UpdatedBy]
					,CM.[CreatedDate]
					,CM.[UpdatedDate]
					,CM.[IsActive]
					,CM.[IsDeleted]
					,sl.[SerialNumber]
					,sl.[StockLineNumber]
					,im.[partnumber] as 'PN'
					,im.[PartDescription] as 'PNDescription'
					,v.[VendorName] as 'Vendor'
					,sl.ItemMasterId
					,sl.StockLineId
					,sl.UnitCost
					--,([dbo].[fn_ConvertUOM](ISNULL(sl.UnitCost, 0),IM.[StockUnitOfMeasure], IM.[PurchaseUnitOfMeasure],1,IM.[MasterCompanyId])) AS 'UnitCost'
					,'' as 'RMANum'
		  FROM [dbo].[VendorCreditMemoDetail] CM WITH (NOLOCK) 		
			   LEFT JOIN VendorCreditMemo vcm WITH (NOLOCK) ON CM.VendorCreditMemoId = vcm.VendorCreditMemoId
			   LEFT JOIN Stockline sl WITH (NOLOCK) ON CM.StockLineId = sl.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
			   LEFT JOIN ItemMaster IM WITH (NOLOCK) ON sl.ItemMasterId=IM.ItemMasterId
			    AND ISNULL(IM.IsNonStock,0) = 0
			   LEFT JOIN Vendor v WITH (NOLOCK) ON vcm.VendorId = v.VendorId
			  WHERE CM.[VendorCreditMemoId] = @VendorCreditMemoId AND CM.IsDeleted = 0;
			END
  END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetVendorCreditMemoPartsById' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@VendorCreditMemoId, '') AS varchar(100))			   
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