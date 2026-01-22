/*************************************************************           
 ** File:   [USP_GetDetailForVendorCreditMemo_ById]           
 ** Author:   Hemant  
 ** Description: Get Data to create vendor credit memo from vendorRMA data
 ** Purpose:         
 ** Date:   21-June-2023       
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date				 Author  			Change Description            
 ** --   --------			-------			--------------------------------          
	1	21-June-2023		Devendra		Get Data to create vendor credit memo from vendorRMA data
     
EXECUTE   [dbo].[USP_GetDetailForVendorCreditMemo_ById] 23
**************************************************************/
Create   PROCEDURE [dbo].[USP_GetDetailForVendorCreditMemo_ById]
@VRMAId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT 
					vra.VendorRMAId,
					vr.VendorName,
					vra.RMANumber as 'RMANum',
					im.partnumber,
					im.PartDescription,
					vrs.VendorRMAStatus,
					vra.VendorRMAStatusId,
					rmad.ExtendedCost
					
				FROM [DBO].[VendorRMA] vra WITH (NOLOCK)	
				LEFT JOIN [dbo].[VendorRMADetail] rmad WITH(NOLOCK) ON vra.VendorRMAId = rmad.VendorRMAId
				LEFT JOIN [dbo].[VendorRMAStatus] vrs WITH(NOLOCK) ON vra.VendorRMAStatusId = vrs.VendorRMAStatusId
				LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON rmad.ItemMasterId = im.ItemMasterId
				LEFT JOIN [dbo].[Vendor] vr WITH(NOLOCK) ON vra.VendorId = vr.VendorId
				LEFT JOIN [dbo].[VendorPayment] vrp WITH(NOLOCK) ON vr.VendorId = vrp.VendorId
				LEFT JOIN [dbo].[VendorPaymentDetails] vrpd WITH(NOLOCK) ON vrp.VendorPaymentId = vrpd.VendorPaymentDetailsId
				WHERE vra.VendorRMAId = @VRMAId
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetDetailForVendorCreditMemo_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VRMAId, '') + ''
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