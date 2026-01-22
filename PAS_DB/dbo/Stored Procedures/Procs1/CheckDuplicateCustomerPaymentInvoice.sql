/*************************************************************             
 ** File:   [CheckDuplicateCustomerPaymentInvoice]
 ** Author:   
 ** Description: This stored procedure is used to check Customer Invoices for same customer
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date          Author			Change Description              
 ** --   --------      -------			-------------------------------            
	1                  Moin Bloch			Created	
	
	EXEC [dbo].[CheckDuplicateCustomerPaymentInvoice]  
**************************************************************/  

CREATE   PROCEDURE [dbo].[CheckDuplicateCustomerPaymentInvoice]    
@CheckDuplicateCustomerPaymentInvoiceType CheckDuplicateCustomerPaymentInvoiceType READONLY
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON    
 BEGIN TRY    

	IF OBJECT_ID(N'tempdb..#CheckDuplicateCustomerPaymentInvoiceType') IS NOT NULL  
    BEGIN  
		DROP TABLE #CheckDuplicateCustomerPaymentInvoiceType
    END 
	
    CREATE TABLE #CheckDuplicateCustomerPaymentInvoiceType
    (  		
		 [CustomerId] [bigint] NULL,
		 [CustomerName] [varchar](100) NULL,  
		 [SOBillingInvoicingId] [bigint] NULL,
		 [DocNum] [varchar](100) NULL, 
		 [InvoiceType] [bigint] NULL		  
    )

	INSERT INTO #CheckDuplicateCustomerPaymentInvoiceType ([CustomerId],[CustomerName],[SOBillingInvoicingId],[DocNum],[InvoiceType]) 
	   SELECT TY.[CustomerId],CS.[Name],TY.[SOBillingInvoicingId],TY.[DocNum],TY.[InvoiceType] 
		  FROM @CheckDuplicateCustomerPaymentInvoiceType  TY
		  INNER JOIN [dbo].[Customer] CS WITH(NOLOCK) ON TY.[CustomerId] = CS.[CustomerId]
		
    SELECT [CustomerId],[CustomerName],[SOBillingInvoicingId],[InvoiceType],[DocNum],COUNT(*) FROM #CheckDuplicateCustomerPaymentInvoiceType  		
	 GROUP BY [CustomerId],[CustomerName],[SOBillingInvoicingId],[InvoiceType],[DocNum] HAVING COUNT(*) > 1;
	  
 END TRY        
  BEGIN CATCH    
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
              , @AdhocComments     VARCHAR(150)    = 'CheckDuplicateCustomerPaymentInvoice'                  
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(1, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
              exec spLogException     
                       @DatabaseName           = @DatabaseName    
                     , @AdhocComments          = @AdhocComments    
                     , @ProcedureParameters = @ProcedureParameters    
                     , @ApplicationName        =  @ApplicationName    
                     , @ErrorLogID             = @ErrorLogID OUTPUT;    
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
              RETURN(1);    
 END CATCH    
END