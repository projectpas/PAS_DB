/*************************************************************             
 ** File:   [USP_CustomerCCPayment_GetViewById]             
 ** Author:  Devendra Shekh 
 ** Description: This stored procedure is used to get [CustomerCCPayments] view details by id
 ** Purpose:           
 ** Date:   09/11/2023      
            
 ** PARAMETERS: @CustomerCCPaymentsId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    09/11/2023		Devendra Shekh			Created  
       
-- exec USP_CustomerCCPayment_GetViewById 1
************************************************************************/   

CREATE   PROCEDURE [dbo].[USP_CustomerCCPayment_GetViewById]
@CustomerCCPaymentsId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT 
					t.CustomerCCPaymentsId,
					t.LegalEntityId,
					l.Name AS [LegalEntity],
					t.CustomerName,
					t.MerchantID,
					t.CompanyBankAccount,
					lb.BankName + '-' +  lb.BankAccountNumber AS [BankAccount],
					STUFF(
						(SELECT ', ' + convert(varchar(20), i.Code, 120)
						FROM dbo.[Currency] i WITH (NOLOCK)
						where i.CurrencyId in (SELECT Item FROM DBO.SPLITSTRING(t.CurrencyId,','))
						FOR XML PATH (''))
						, 1, 1, '')  AS [Currency],
					STUFF(
						(SELECT ', ' + convert(varchar(20), i.PaymentMethodName, 120)
						FROM dbo.[SupportedPaymentMethods] i WITH (NOLOCK)
						where i.Id in (SELECT Item FROM DBO.SPLITSTRING(t.SupportedPaymentMethods,','))
						FOR XML PATH (''))
						, 1, 1, '')  AS [SupportedPaymentMethods],
					STUFF(
						(SELECT ', ' + convert(varchar(20), i.GatewayRequestTypesName, 120)
						FROM dbo.[GatewayRequestTypeslist] i WITH (NOLOCK)
						where i.Id in (SELECT Item FROM DBO.SPLITSTRING(t.GatewayRequestTypes,','))
						FOR XML PATH (''))
						, 1, 1, '')  AS [GatewayRequestTypes],
					t.TestMode,
					t.PayerAuthentication,
					t.IgnoreAVSResponse,
					t.IgnoreCSCResponse,
					t.DisableSendingRecurringRequests,
					t.InActive,
					(SELECT StatusName FROM [CustomerCCPaymentsStatus] WHERE Id = t.PartialAVSMatch) AS PartialAVSMatch,
					(SELECT StatusName FROM [CustomerCCPaymentsStatus] WHERE Id = t.NoAVSMatch) AS NoAVSMatch,
					(SELECT StatusName FROM [CustomerCCPaymentsStatus] WHERE Id = t.AVSServiceNotAvailable) AS AVSServiceNotAvailable,
					(SELECT StatusName FROM [CustomerCCPaymentsStatus] WHERE Id = t.NoCSCMatch) AS NoCSCMatch,
					(SELECT StatusName FROM [CustomerCCPaymentsStatus] WHERE Id = t.CSCNotSubmitted) AS CSCNotSubmitted,
					(SELECT StatusName FROM [CustomerCCPaymentsStatus] WHERE Id = t.CSCServiceNotAvailable) AS CSCServiceNotAvailable,
					(SELECT StatusName FROM [CustomerCCPaymentsStatus] WHERE Id = t.CSCNotSupportedbyCardholderBank) AS CSCNotSupportedbyCardholderBank,
					t.MasterCompanyId,
					t.CreatedBy,
					t.UpdatedBy,
					t.CreatedDate,
					t.UpdatedDate,
					t.IsActive,
					t.IsDeleted
				FROM [DBO].[CustomerCCPayments] t WITH (NOLOCK) 
				LEFT JOIN [DBO].[LegalEntity] l WITH (NOLOCK) ON t.LegalEntityId = l.LegalEntityId
				LEFT JOIN [DBO].[LegalEntityBankingLockBox] lb WITH (NOLOCK) ON t.CompanyBankAccount = lb.LegalEntityBankingLockBoxId
				--LEFT JOIN [DBO].[IntegrationPortal] i WITH (NOLOCK) ON t.IntegrationIds = i.IntegrationPortalId
				WHERE t.CustomerCCPaymentsId = @CustomerCCPaymentsId
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CustomerCCPayment_GetViewById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CustomerCCPaymentsId, '') + ''
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