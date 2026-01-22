/****************************           
 ** File:   [VendorPositivePayList]           
 ** Author:   MOIN BLOCH
 ** Description: This stored procedure is used Get Vendor Positive Pay List
 ** Purpose:         
 ** Date:   07/10/2023
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 ****************************           
  ** Change History           
 ****************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/10/2023   MOIN BLOCH    CREATED 
	2    07/21/2023   MOIN BLOCH    Added StartDate And EndDate Filter
	3    06/25/2024   SAHDEV SALIYA Added ReadyToPayDetailsId for Resolve Print Issue
  
exec VendorPositivePayList 
@PageSize=10,@PageNumber=1,@SortColumn=N'invoiceNum',@SortOrder=-1,@GlobalFilter=N'',
@InvoiceNum=N'2',@OriginalTotal=NULL,@RRTotal=NULL,@InvoiceTotal=NULL,@Status=N'PaidinFull',@VendorName=NULL,@InvociedDate=NULL,@EntryDate=NULL,@MasterCompanyId=1,@EmployeeId=2,
@BankName=NULL,@BankAccountNumber=NULL,@PaymentMethod=NULL,@PaymentMethodId=1,@StartDate=NULL,@EndDate=NULL
**********************/
CREATE   PROCEDURE [dbo].[VendorPositivePayList]
@PageSize int,  
@PageNumber int,  
@SortColumn varchar(50) = NULL,  
@SortOrder int,  
@GlobalFilter varchar(50) = NULL,  
@InvoiceNum varchar(50) = NULL,  
@OriginalTotal varchar(50) = NULL,  
@RRTotal varchar(50) = NULL,  
@InvoiceTotal varchar(50) = NULL,  
@Status varchar(50) = NULL,  
@VendorName varchar(50) = NULL,  
@InvociedDate datetime = NULL,  
@EntryDate datetime = NULL,  
@MasterCompanyId int = NULL,  
@EmployeeId bigint,
@BankName varchar(50) = NULL,  
@BankAccountNumber varchar(50) = NULL, 
@PaymentMethod varchar(50) = NULL,
@PaymentMethodId int = NULL,
@StartDate datetime = NULL,  
@EndDate datetime = NULL
AS  
BEGIN 
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY         
    DECLARE @RecordFrom INT;  
    SET @RecordFrom = (@PageNumber-1) * @PageSize;      
    IF @SortColumn IS NULL  
    BEGIN  
		SET @SortColumn = UPPER('CreatedDate')  
    END   
    ELSE  
    BEGIN   
		SET @SortColumn = UPPER(@SortColumn)  
    END
	IF(@StartDate = '')
	BEGIN   
		SET @StartDate = NULL;
    END
	
	DECLARE @Check INT;
    DECLARE @DomesticWire INT;
    DECLARE @InternationalWire INT;
    DECLARE @ACHTransfer INT;
    DECLARE @CreditCard INT;
 
	SELECT @Check = [VendorPaymentMethodId] FROM [VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'Check';
	SELECT @DomesticWire = [VendorPaymentMethodId] FROM [VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'Domestic Wire';
	SELECT @InternationalWire = [VendorPaymentMethodId] FROM [VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'International Wire';
	SELECT @ACHTransfer = [VendorPaymentMethodId] FROM [VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'ACH Transfer';
	SELECT @CreditCard = [VendorPaymentMethodId] FROM [VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'Credit Card';

    IF(@Status = 'PaidinFull')  
    BEGIN 
	    IF(@PaymentMethodId = @Check)
		BEGIN
			SET @SortColumn = UPPER('READYTOPAYID')  
		END
       ;WITH Result AS (  
		SELECT 0 AS ReceivingReconciliationId
			,CASE WHEN VRP.IsVoidedCheck = 1 THEN VRP.CheckNumber + ' (V)' ELSE VRP.CheckNumber END AS InvoiceNum
			,SUM(ISNULL(VRP.PaymentMade,0)) AS InvoiceTotal
			,VRP.VendorId
			,VN.VendorName
			,ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold'
			,VRP.CheckDate AS 'InvociedDate'
			,VRP.CheckDate AS 'EntryDate'			
			,CASE WHEN VRP.IsVoidedCheck =1 THEN VRP.CheckNumber + ' (V)' ELSE VRP.CheckNumber END AS 'PaymentRef'
			,'' AS 'CheckCrashed'						
			,CASE WHEN VRP.PaymentMethodId = @Check THEN lebl.BankName WHEN VRP.PaymentMethodId = @DomesticWire THEN DWPL.BankName WHEN VRP.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBank WHEN VRP.PaymentMethodId = @ACHTransfer THEN DWPL.BankName WHEN VRP.PaymentMethodId = @CreditCard THEN '' END AS BankName
			,CASE WHEN VRP.IsVoidedCheck = 1 AND VRP.PaymentMethodId = @Check THEN lebl.BankAccountNumber + ' (V)' 
			      WHEN VRP.IsVoidedCheck = 1 AND VRP.PaymentMethodId = @DomesticWire THEN DWPL.AccountNumber 
				  WHEN VRP.IsVoidedCheck = 1 AND VRP.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBankAccount 
				  WHEN VRP.IsVoidedCheck = 1 AND VRP.PaymentMethodId = @ACHTransfer THEN DWPL.AccountNumber 
				  WHEN VRP.IsVoidedCheck = 1 AND VRP.PaymentMethodId = @CreditCard THEN '' 
				  WHEN VRP.IsVoidedCheck = 0 AND VRP.PaymentMethodId = @Check THEN lebl.BankAccountNumber 
			      WHEN VRP.IsVoidedCheck = 0 AND VRP.PaymentMethodId = @DomesticWire THEN DWPL.AccountNumber 
				  WHEN VRP.IsVoidedCheck = 0 AND VRP.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBankAccount 
				  WHEN VRP.IsVoidedCheck = 0 AND VRP.PaymentMethodId = @ACHTransfer THEN DWPL.AccountNumber
				  WHEN VRP.IsVoidedCheck = 0 AND VRP.PaymentMethodId = @CreditCard THEN '' END AS 'BankAccountNumber'
			,VRH.ReadyToPayId
			,VRP.IsVoidedCheck
			,PM.[Description] AS 'PaymentMethod'
			,[VRP].[PaymentMethodId]
			,[VRP].ReadyToPayDetailsId
		FROM [dbo].[VendorReadyToPayDetails] VRP  WITH(NOLOCK)
		INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRP.VendorId = VN.VendorId
		 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRH WITH(NOLOCK) ON VRP.ReadyToPayId = VRH.ReadyToPayId
		 LEFT JOIN [dbo].[VendorPaymentMethod] PM WITH(NOLOCK) ON PM.VendorPaymentMethodId = VRP.PaymentMethodId	
		 LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRH.BankId
		 LEFT JOIN [dbo].[VendorDomesticWirePayment] VDWP WITH(NOLOCK) ON VDWP.VendorId = VRP.VendorId
		 LEFT JOIN [dbo].[DomesticWirePayment] DWPL WITH(NOLOCK) ON DWPL.DomesticWirePaymentId = VDWP.DomesticWirePaymentId
		 LEFT JOIN [dbo].[VendorInternationlWirePayment] VIWP WITH(NOLOCK) ON VIWP.VendorId = VRP.VendorId
		 LEFT JOIN [dbo].[InternationalWirePayment] IWPL WITH(NOLOCK) ON IWPL.InternationalWirePaymentId = VIWP.InternationalWirePaymentId

		 WHERE ([VRP].[PaymentMethodId] = @PaymentMethodId) AND (VRP.[MasterCompanyId] = @MasterCompanyId) 
		   AND (@StartDate IS NULL OR CAST(VRP.CheckDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE))
		 GROUP BY VRP.CheckNumber,lebl.BankName,DWPL.BankName,IWPL.BeneficiaryBank,lebl.BankAccountNumber,DWPL.AccountNumber,IWPL.BeneficiaryBankAccount, VRH.ReadyToPayId,VN.IsVendorOnHold,CheckDate,VN.VendorName,IsVoidedCheck,VRP.VendorId,PM.[Description],[VRP].[PaymentMethodId],[VRP].ReadyToPayDetailsId
    ),  
    FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, InvoiceTotal,VendorName, PaymentHold, InvociedDate,EntryDate,  
      PaymentMethod, PaymentRef, CheckCrashed,BankName,BankAccountNumber,ReadyToPayId,IsVoidedCheck,VendorId,PaymentMethodId,ReadyToPayDetailsId FROM Result  
    WHERE 
	   ((@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR          
       (InvociedDate LIKE '%' +@GlobalFilter+'%') OR  
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR        
	   (BankName LIKE '%' +@GlobalFilter+'%') OR  
       (BankAccountNumber LIKE '%'+@GlobalFilter+'%') OR  
       (InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR  
	   (PaymentMethod LIKE '%' +@GlobalFilter+'%') OR  
       (VendorName LIKE '%' +@GlobalFilter+'%')  
       ))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND   
       (ISNULL(@InvociedDate,'') ='' OR CAST(InvociedDate AS DATE) = CAST(@InvociedDate AS DATE)) AND  
       (ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS DATE) = CAST(@EntryDate AS DATE)) AND  
       (ISNULL(@InvoiceTotal,'') ='' OR InvoiceTotal LIKE '%'+ @InvoiceTotal+'%') AND  
	   (ISNULL(@BankName,'') ='' OR BankName LIKE '%'+ @BankName+'%') AND 
	   (ISNULL(@BankAccountNumber,'') ='' OR BankAccountNumber LIKE '%'+ @BankAccountNumber+'%') AND 
	   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND 
       (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%')))
	   ),
	   ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, InvoiceNum, InvoiceTotal,VendorName, PaymentHold, InvociedDate, EntryDate,  
			 PaymentMethod, PaymentRef, CheckCrashed, NumberOfItems,BankName,BankAccountNumber,ReadyToPayId,IsVoidedCheck,VendorId,PaymentMethodId,ReadyToPayDetailsId
		FROM FinalResult, ResultCount    
     ORDER BY CASE WHEN (@SortOrder=1  AND @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
		      CASE WHEN (@SortOrder=1  AND @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
			  CASE WHEN (@SortOrder=1  AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END ASC,   
		      CASE WHEN (@SortOrder=1  AND @SortColumn='VENDORNAME')  THEN VendorName END ASC,   			   
		      CASE WHEN (@SortOrder=-1 AND @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
		      CASE WHEN (@SortOrder=-1 AND @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
			  CASE WHEN (@SortOrder=-1 AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END DESC,  
		      CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORNAME')  THEN VendorName END DESC, 
			  CASE WHEN (@SortOrder=1  AND @SortColumn='CHECKNUMBER')  THEN InvoiceNum END ASC,  
		      CASE WHEN (@SortOrder=-1 AND @SortColumn='CHECKNUMBER')  THEN InvoiceNum END DESC, 
			  CASE WHEN (@SortOrder=1  AND @SortColumn='READYTOPAYID')  THEN ReadyToPayId END ASC,  
		      CASE WHEN (@SortOrder=-1 AND @SortColumn='READYTOPAYID')  THEN ReadyToPayId END DESC 

     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END      
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'VendorPositivePayList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''  
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