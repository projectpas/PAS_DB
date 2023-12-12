/*************************************************************           
 ** File:   [USP_UpdateCreditMemoHeader_ById]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used VendorReadyToPayList 
 ** Purpose:         
 ** Date:   19/05/2023      
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    27/10/2023   Devendra Shekh	Changes for customer creditmemo details
    2    31/10/2023   Devendra Shekh	modified for different vendorreadytopay 


	exec [USP_UpdateCreditMemoHeader_ById] 1,1,1,1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateCreditMemoHeader_ById]  
@ReferenceId BIGINT = NULL,  
@UpdatedBy VARCHAR(100) = NULL,
@Type INT = NULL,
@VendorRTPTypeId INT = NULL
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
	BEGIN TRY  

	IF(@VendorRTPTypeId = 2)
	BEGIN
		IF(@Type = 1)
		BEGIN
			UPDATE [CreditMemo]
			SET [IsUsedInVendorPayment] = 1, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [CreditMemoHeaderId] = @ReferenceId
		END
		ELSE
		BEGIN
			UPDATE [CreditMemo]
			SET [StatusId] = (SELECT ID FROM [dbo].[CreditMemoStatus] WITHH(NOLOCK) WHERE [Name] = 'Refunded'), [Status] = (SELECT [Name] FROM [dbo].[CreditMemoStatus] WITHH(NOLOCK) WHERE [Name] = 'Refunded')
			,[UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [CreditMemoHeaderId] = @ReferenceId
		END
	END
	ELSE IF(@VendorRTPTypeId = 3)
	BEGIN
		IF(@Type = 1)
		BEGIN
			UPDATE [NonPOInvoiceHeader]
			SET [IsUsedInVendorPayment] = 1, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [NonPOInvoiceId] = @ReferenceId
		END
	END
	

	END TRY      
	BEGIN CATCH        
	IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateCreditMemoHeader_ById'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReferenceId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END