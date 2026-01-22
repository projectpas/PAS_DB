/********************************************************************  
 ** File:   [USP_Customer aymentList]             
 ** Author:  Devendra Shekh  
 ** Description: This stored procedure is used get the data Customer ayment by Id  
 ** Purpose:           
 ** Date:   09/01/2023    
            
 ** PARAMETERS:    
       
 ***********************************************************************      
 ** Change History             
 ***********************************************************************   
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			------------------------------------  
    1    09/01/2023   Devendra Shekh      Created  
    1    09/07/2023   Devendra Shekh      COLUMN name changed to [PartialAVSMatch] for authorization  
  
 EXEC USP_GetCustomerCCPaymentById 1  
**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetCustomerCCPaymentById]   
@CustomerCCPaymentsId BIGINT  
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  BEGIN TRY  
  BEGIN TRANSACTION  
 BEGIN  
    SELECT   
      CustomerCCPaymentsId  
    , LegalEntityId  
    ,ISNULL(CustomerName,'') AS CustomerName  
    , CompanyBankAccount  
    ,ISNULL(MerchantID,'') AS MerchantID  
    ,CurrencyId  
    ,SupportedPaymentMethods  
    ,GatewayRequestTypes  
    ,ISNULL(TestMode,0) AS TestMode  
    ,ISNULL(PayerAuthentication,0) AS PayerAuthentication  
    ,ISNULL(IgnoreAVSResponse,0) AS IgnoreAVSResponse  
    ,ISNULL(IgnoreCSCResponse,0) AS IgnoreCSCResponse  
    ,ISNULL(DisableSendingRecurringRequests,0) AS DisableSendingRecurringRequests  
    ,ISNULL(InActive,0) AS InActive  
    ,ISNULL([PartialAVSMatch],0) AS [PartialAVSMatch]  
    ,ISNULL(NoAVSMatch,'') AS NoAVSMatch  
    ,ISNULL(AVSServiceNotAvailable,0) AS AVSServiceNotAvailable  
    ,ISNULL(NoCSCMatch,0) AS NoCSCMatch  
    ,ISNULL(CSCNotSubmitted,0) AS CSCNotSubmitted  
    ,ISNULL(CSCServiceNotAvailable,0) AS CSCServiceNotAvailable  
    ,ISNULL(CSCNotSupportedbyCardholderBank,0) AS CSCNotSupportedbyCardholderBank  
    ,[MasterCompanyId]  
    ,[CreatedBy]  
    ,[UpdatedBy]  
    ,[CreatedDate]  
    ,[UpdatedDate]  
    ,[IsActive]  
    ,[IsDeleted]  
    FROM [dbo].[CustomerCCPayments] WITH(NOLOCK) WHERE CustomerCCPaymentsId = @CustomerCCPaymentsId  
 END  
 COMMIT  TRANSACTION  
  END TRY  
  BEGIN CATCH  
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
  DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,@AdhocComments varchar(150) = 'USP_GetCustomer aymentsId',  
            @ProcedureParameters varchar(3000) = '@Customer aymentsId = ''' + CAST(ISNULL(@CustomerCCPaymentsId, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'  
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC spLogException @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
    RETURN (1);  
  END CATCH  
END