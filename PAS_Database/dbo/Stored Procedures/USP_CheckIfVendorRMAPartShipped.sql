/*************************************************************           
 ** File:   [USP_CheckIfVendorRMAPartShipped]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to CheckIfVendorRMA PartShipped List
 ** Purpose:         
 ** Date:   11-06-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    11-06-2025    Sahdev Saliya       Created  

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_CheckIfVendorRMAPartShipped]
    @VendorRMAId BIGINT,
    @VendorRMADetailId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

		BEGIN TRY
			SELECT
				vr.VendorRMAId,
				ISNULL(vrma.VendorRMADetailId, 0) AS VendorRMADetailId,
				ISNULL(rm.RMAShippingId, 0) AS RMAShippingId,
				ISNULL(rmi.RMAShippingItemId, 0) AS RMAShippingItemId,
				ISNULL(rmi.QtyShipped, 0) AS QtyShipped
			FROM [dbo].VendorRMA vr WITH(NOLOCK)
			LEFT JOIN [dbo].VendorRMADetail vrma WITH(NOLOCK) ON vr.VendorRMAId = vrma.VendorRMAId
			LEFT JOIN [dbo].RMAShippingItem rmi WITH(NOLOCK) ON vrma.VendorRMADetailId = rmi.VendorRMADetailId
			LEFT JOIN [dbo].RMAShipping rm WITH(NOLOCK) ON rmi.RMAShippingId = rm.RMAShippingId
			WHERE vr.VendorRMAId = @VendorRMAId;
		END TRY

 BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_CheckIfVendorRMAPartShipped' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAId, '') + ''',
				    @Parameter2 = ' + ISNULL(@VendorRMADetailId ,'') 

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