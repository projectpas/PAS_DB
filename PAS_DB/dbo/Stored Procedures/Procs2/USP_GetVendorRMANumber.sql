/*************************************************************           
 ** File:   [USP_GetVendorRMANumber]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get VendorRMANumber List
 ** Purpose:         
 ** Date:   06-06-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    06-06-2025    Sahdev Saliya       Created  
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetVendorRMANumber]
    @VendorRMAId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
	     BEGIN TRY

			SELECT
				vrma.VendorRMAId,
				vrmad.VendorRMADetailId,
				vrma.RMANumber AS RMANum,
				vrmad.StockLineId,
				stk.StockLineNumber,
				ISNULL(vrmad.SerialNumber, '') AS SerialNumber,
				vrmad.ItemMasterId,
				vrmad.UnitCost,
				vrmad.ExtendedCost,
				vrma.MasterCompanyId,
				vrma.RMANumber AS Barcode,  
				ISNULL(vrmad.Notes, '') AS Notes,
				vrmad.Qty,
				im.PartNumber,
				im.PartDescription
			FROM [DBO].VendorRMA vrma WITH(NOLOCK)
			LEFT JOIN [dbo].VendorRMADetail vrmad WITH(NOLOCK) ON vrma.VendorRMAId = vrmad.VendorRMAId
			INNER JOIN [dbo].ItemMaster im WITH(NOLOCK) ON vrmad.ItemMasterId = im.ItemMasterId
			INNER JOIN [dbo].StockLine stk WITH(NOLOCK) ON vrmad.StockLineId = stk.StockLineId
			WHERE vrma.VendorRMAId = @VendorRMAId
		 AND ISNULL(im.IsNonStock,0) = 0 AND ISNULL(stk.IsNonStock,0) = 0
			 END TRY    

    BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorRMANumber' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAId, '')
			 
				  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

				  exec spLogException 
						   @DatabaseName			= @DatabaseName
						 , @AdhocComments			= @AdhocComments
						 , @ProcedureParameters		= @ProcedureParameters
						 , @ApplicationName			= @ApplicationName
						 , @ErrorLogID              = @ErrorLogID OUTPUT ;
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
				  RETURN
	END CATCH
END