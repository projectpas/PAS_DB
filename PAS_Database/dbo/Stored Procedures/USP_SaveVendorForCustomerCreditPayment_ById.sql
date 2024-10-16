﻿/*****************************************************************************     
** Author:  <Devendra Shekh>    
** Create date: <03/04/2024>    
** Description: <used to Save Vendor For Customer CreditPayment ById>    
    
EXEC [USP_SaveVendorForCustomerCreditPayment_ById]   
**********************   
** Change History   
**********************     

	  (mm/dd/yyyy)
** PR   Date			Author				Change Description    
** --   --------		-------				--------------------------------  
** 1    03/08/2024		Devendra Shekh		created
** 2    03/26/2024		Devendra Shekh		aded new sp call AddVendorPaymentDetails
** 3    03/26/2024		Devendra Shekh		aded CASE for vendorId update
** 4    04/01/2024		Devendra Shekh		aded INERTING accouting entry while updating flage to IsProcessed
** 5    04/22/2024		Devendra Shekh		updating vendorId

*****************************************************************************/  
CREATE   PROCEDURE [dbo].[USP_SaveVendorForCustomerCreditPayment_ById]
@CustomerCreditPaymentDetailId BIGINT,
@VendorId BIGINT,
@MasterCompanyId INT,
@UserName VARCHAR(50),
@IsProcessed BIT = 0
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		/**
		StatusId
		1 - Open
		2 - Closed
		3 - Processed
		**/

		UPDATE CCPD
		SET CCPD.[StatusId] = CASE WHEN @IsProcessed = 1 THEN 3 ELSE CCPD.[StatusId] END, 
			CCPD.IsProcessed = @IsProcessed, 
			CCPD.[ProcessedDate] = CASE WHEN @IsProcessed = 1 THEN GETUTCDATE() ELSE CCPD.[ProcessedDate] END,
			CCPD.UpdatedDate = GETUTCDATE(),
			CCPD.VendorId = @VendorId, --CASE WHEN ISNULL(CCPD.VendorId, 0) = 0 THEN @VendorId ELSE CCPD.VendorId END,
			CCPD.UpdatedBy = @UserName
		FROM [dbo].[CustomerCreditPaymentDetail] CCPD WITH(NOLOCK)
		WHERE CCPD.[CustomerCreditPaymentDetailId] = @CustomerCreditPaymentDetailId AND CCPD.MasterCompanyId = @MasterCompanyId;

		IF(ISNULL(@IsProcessed, 0) = 1)
		BEGIN
			EXEC [USP_AddVendorPaymentDetails_ForCustomerCreditPaymentDetailById] @CustomerCreditPaymentDetailId, @VendorId, @MasterCompanyId, @UserName
			EXEC [USP_BatchTriggerBasedonSupenseId] @CustomerCreditPaymentDetailId;
		END

	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_SaveVendorForCustomerCreditPayment_ById'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerCreditPaymentDetailId, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@CustomerCreditPaymentDetailId, '') AS varchar(100)) 
			   		                                           
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END