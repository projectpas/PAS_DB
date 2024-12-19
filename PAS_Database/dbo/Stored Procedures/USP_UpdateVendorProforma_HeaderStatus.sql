/*************************************************************             
 ** File:   [USP_UpdateVendorProforma_HeaderStatus]            
 ** Author:   RAJESH GAMI    
 ** Description: to update the vendor proforma invoice header status
 ** Purpose:           
 ** Date:   19-Dec-2024         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 **	 S NO   Date		  Author			 Change Description              
 **	 --   --------		  -------		--------------------------------            
	  1	 19-Dec-2024	 RAJESH GAMI		CREATED  
       
EXECUTE   [dbo].[USP_UpdateVendorProforma_HeaderStatus] 37,'admin'  
*************************************************************/      
CREATE     PROCEDURE [dbo].[USP_UpdateVendorProforma_HeaderStatus]
@VendorProformaInvoiceId bigint,
@UpdatedBy VARCHAR(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF(@VendorProformaInvoiceId > 0)
				BEGIN
					DECLARE @IsEnforceApproval BIT = 0
					SELECT @IsEnforceApproval = IsEnforcePoRoApproval FROM [dbo].[VendorProformaInvoiceHeader] WITH(NOLOCK) WHERE VendorProformaInvoiceId = @VendorProformaInvoiceId;

					IF(@IsEnforceApproval = 1)
					BEGIN
						UPDATE [dbo].[VendorProformaInvoiceHeader]
						SET StatusId = (SELECT [VendorProformaInvoiceHeaderStatusId] FROM [dbo].VendorProformaInvoiceHeaderStatus WITH(NOLOCK) WHERE [Description] = 'Open')
						, [UpdatedBy] = @UpdatedBy 
						, [UpdatedDate] = GETUTCDATE()
						WHERE VendorProformaInvoiceId = @VendorProformaInvoiceId
					END
					ELSE
					BEGIN
						UPDATE [dbo].[VendorProformaInvoiceHeader]
						SET StatusId = (SELECT VendorProformaInvoiceHeaderStatusId FROM [dbo].VendorProformaInvoiceHeaderStatus WITH(NOLOCK) WHERE [Description] = 'Approved')
						, [UpdatedBy] = @UpdatedBy 
						, [UpdatedDate] = GETUTCDATE()
						WHERE VendorProformaInvoiceId = @VendorProformaInvoiceId
					END
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
              , @AdhocComments     VARCHAR(150)    = '[USP_UpdateVendorProforma_HeaderStatus]'               
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@VendorProformaInvoiceId, '') AS VARCHAR(100))
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