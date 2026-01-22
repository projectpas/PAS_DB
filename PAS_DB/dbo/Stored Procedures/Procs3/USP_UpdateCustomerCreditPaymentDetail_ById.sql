/*************************************************************           
 ** File:   [USP_UpdateCustomerCreditPaymentDetail_ById]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Update Customer Credit PaymentDetail 
 ** Purpose:         
 ** Date:   03/29/2024 (mm/dd/yyyy)
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
		(mm/dd/yyyy)
 ** --   --------     -------			--------------------------------          
    1    03/29/2024   Devendra Shekh	created

	exec [USP_UpdateCustomerCreditPaymentDetail_ById] 158,'ADMIN user'
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateCustomerCreditPaymentDetail_ById]  
@ReferenceId BIGINT = NULL,  
@IsCreditMemo BIT = NULL
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
	BEGIN TRY  

		IF(ISNULL(@IsCreditMemo, 0) = 1)
		BEGIN
			DECLARE @CustomerCreditDetailsIds VARCHAR(30) = '';
			SET @CustomerCreditDetailsIds =  (SELECT STUFF((SELECT ',' + CAST(STC.CustomerCreditPaymentDetailId AS VARCHAR) 
												FROM [dbo].[StandAloneCreditMemoDetails] STC 
												WHERE STC.CreditMemoHeaderId = @ReferenceId 
												FOR XML PATH ('')), 1, 1, ''))

			IF(ISNULL(@CustomerCreditDetailsIds, '') != '')
			BEGIN
				UPDATE [CustomerCreditPaymentDetail]
				SET [StatusId] = 2, [UpdatedDate] = GETUTCDATE()
				WHERE [CustomerCreditPaymentDetailId] IN (SELECT VALUE FROM STRING_SPLIT(@CustomerCreditDetailsIds, ','))
			END
		END
		ELSE
		BEGIN
			UPDATE [CustomerCreditPaymentDetail]
			SET [StatusId] = 2, [UpdatedDate] = GETUTCDATE()
			WHERE [CustomerCreditPaymentDetailId] = @ReferenceId;
		END
			
	END TRY      
	BEGIN CATCH        
	IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateCustomerCreditPaymentDetail_ById'   
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