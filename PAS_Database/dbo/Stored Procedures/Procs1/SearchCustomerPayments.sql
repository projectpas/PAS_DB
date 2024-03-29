﻿
/*************************************************************           
 ** File:   [SearchCustomerPayments]           
 ** Author:   Unknown
 ** Description: This stored procedure is used to retrieve Customer Payments Information   
 ** Purpose:         
 ** Date:   12/23/2020        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/23/2022   Unknown        Created
	2    03/06/2024   Moin Bloch     Modified Added PostedDate

--EXEC SearchCustomerPayments
**************************************************************/
-- =============================================    
-- =============================================    
CREATE   PROCEDURE [dbo].[SearchCustomerPayments]    
 @PageNumber int,    
 @PageSize int,    
 @SortColumn varchar(50)=null,    
 @SortOrder int,    
 @StatusID int,    
 @GlobalFilter varchar(50) = null,    
 @ReceiptNo varchar(50)=null,    
 @Status varchar(50)=null,    
 @BankAcct varchar(50)=null,    
 @OpenDate datetime=null,    
 @DepositDate datetime=null,   
 @PostedDate datetime=null,   
 @AcctingPeriod varchar(50)=null,    
 @Reference varchar(50)=null,    
 @Amount varchar(50)=null,    
 @AmtApplied varchar(50)=null,    
 @AmtRemaining varchar(50)=null,    
 @Currency varchar(50)=null,    
 @CntrlNum varchar(50)=null,    
 @LastMSLevel varchar(50)=null,     
 @MasterCompanyId int = null,    
 @EmployeeId bigint,    
 @BackAcctNumber varchar(50) = null    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY    
    
  DECLARE @RecordFrom INT;    
  DECLARE @MSModuleID INT = 59; -- CustomerPayment Management Structure Module ID    
  SET @RecordFrom = (@PageNumber-1)*@PageSize;    
      
    
  If @StatusID=0    
  Begin     
   Set @StatusID=null    
   SET @Status = null    
  End    
  ELSE IF @StatusID=1    
  Begin     
   SET @Status = 'Open'    
  End    
  ELSE IF @StatusID=2    
  Begin     
   SET @Status = 'Posted'    
  End    
  IF @SortColumn is null    
  Begin    
   Set @SortColumn=Upper('ReceiptID')    
  End     
  Else    
  Begin     
   Set @SortColumn=Upper(@SortColumn)    
  End    
  --SET @SortOrder=-1;    
    
  ;WITH Result AS(    
  SELECT DISTINCT     
   CP.ReceiptID,     
   CP.ReceiptNo AS 'ReceiptNo',     
   S.Name AS 'Status',     
   LEB.BankAccountNumber AS 'BankAccountNumber',     
   LEB.BankName AS 'BankAcct',     
   CP.OpenDate,     
   CP.DepositDate,     
   AP.PeriodName AS 'AcctingPeriod',     
   CP.Reference,     
   CP.Amount,     
   CP.AmtApplied,     
   CP.AmtRemaining,    
   --'USD' AS 'Currency',     
   CP.CntrlNum,    
   MSD.LastMSLevel,    
   MSD.AllMSlevels,    
   CP.CreatedDate,  
   CASE WHEN ISNULL(ic.CurrencyId,0) > 0 THEN ic.CurrencyId  
	    WHEN ISNULL(iw.CurrencyId,0) > 0 THEN iw.CurrencyId   
        WHEN ISNULL(icd.CurrencyId,0) > 0 THEN icd.CurrencyId   
  ELSE 0 END 'CurrencyId',  
  CP.PostedDate
  FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)    
   INNER JOIN [dbo].[CustomerManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = CP.ReceiptId    
   INNER JOIN [dbo].[RoleManagementStructure] RMS WITH(NOLOCK) ON CP.ManagementStructureId = RMS.EntityStructureId    
   INNER JOIN [dbo].[EmployeeUserRole] EUR WITH(NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId    
    LEFT JOIN [dbo].[LegalEntityBankingLockBox] LEB WITH(NOLOCK) ON LEB.LegalEntityBankingLockBoxId = CP.BankName    
    LEFT JOIN [dbo].[MasterCustomerPaymentStatus] S WITH(NOLOCK) ON S.Id = CP.StatusId    
    LEFT JOIN [dbo].[AccountingCalendar] AP WITH(NOLOCK) ON AP.AccountingCalendarId = CP.AcctingPeriod  
    LEFT JOIN (  
 SELECT ReceiptId,MAX(CurrencyId) 'CurrencyId' FROM [dbo].[InvoiceCheckPayment] iv WITH(NOLOCK)   
 GROUP BY ReceiptId  
 )ic ON CP.ReceiptId = ic.ReceiptId  
   LEFT JOIN(  
 SELECT ReceiptId,MAX(CurrencyId) 'CurrencyId' FROM [dbo].[InvoiceWireTransferPayment] iv WITH(NOLOCK)   
 GROUP BY ReceiptId  
 )iw ON CP.ReceiptId = iw.ReceiptId  
   LEFT JOIN (  
 SELECT ReceiptId,MAX(CurrencyId) 'CurrencyId' FROM [dbo].[InvoiceCreditDebitCardPayment] iv WITH(NOLOCK)  
 GROUP BY ReceiptId  
 )icd on CP.ReceiptId = icd.ReceiptId  
   ),    
  
  FinalResult AS (    
  SELECT C.Code 'Currency' ,R.* FROM Result R  
  LEFT JOIN [dbo].[Currency] C WITH(NOLOCK) ON R.CurrencyId = C.CurrencyId  
  Where (    
   (@GlobalFilter <>'' AND ((ReceiptNo like '%' + @GlobalFilter +'%') OR    
   (Status like '%' + @GlobalFilter +'%') OR    
   (BankAcct like '%' + @GlobalFilter +'%') OR    
   (AcctingPeriod like '%' +@GlobalFilter+'%') OR    
   (Reference like '%' +@GlobalFilter+'%') OR    
   --(Currency like '%' +@GlobalFilter+'%') OR  
   (C.Code like '%' +@GlobalFilter+'%') OR    
   (CntrlNum like '%' +@GlobalFilter+'%') OR    
   (LastMSLevel like '%' +@GlobalFilter+'%') OR    
   (BankAccountNumber like '%' +@GlobalFilter+'%')OR  
   (CAST(Amount AS varchar(50)) like '%' +@GlobalFilter+'%') OR
   (CAST(AmtApplied AS varchar(50)) like '%' +@GlobalFilter+'%') OR 
   (CAST(AmtRemaining AS varchar(50)) like '%' +@GlobalFilter+'%')  
   ))    
   OR       
   (@GlobalFilter='' AND (IsNull(@ReceiptNo,'') ='' OR ReceiptNo like  '%'+ @ReceiptNo+'%') and     
   (IsNull(@Status,'') ='' OR Status like '%'+ @Status +'%') and    
   (IsNull(@BankAcct,'') ='' OR BankAcct like  '%'+@BankAcct+'%') and    
   (@OpenDate is  null or Cast(OpenDate as date)=Cast(@OpenDate as date)) and    
   (@DepositDate is  null or Cast(DepositDate as date)=Cast(@DepositDate as date)) and  
   (@PostedDate is  null or Cast(PostedDate as date)=Cast(@PostedDate as date)) and    
   (IsNull(@AcctingPeriod,'') ='' OR AcctingPeriod like '%'+ @AcctingPeriod+'%') and    
   (IsNull(@Reference,'') ='' OR Reference like '%'+ @Reference +'%') and    
   (ISNULL(@Amount,'') ='' or CAST(Amount AS varchar(50)) LIKE '%' + @Amount + '%') and    
   (ISNULL(@AmtApplied,'') ='' or CAST(AmtApplied  AS varchar(50)) LIKE '%' + @AmtApplied + '%') and    
   (ISNULL(@AmtRemaining,'') ='' or CAST(AmtRemaining  AS varchar(50)) LIKE '%' + @AmtRemaining + '%') and    
   --(IsNull(@Currency,'') ='' OR Currency like '%'+ @Currency+'%') and  
   (IsNull(@Currency,'') ='' OR C.Code like '%'+ @Currency+'%') and  
   (IsNull(@CntrlNum,'') ='' OR CntrlNum like '%'+@CntrlNum+'%') and    
   (IsNull(@LastMSLevel,'') ='' OR LastMSLevel like '%'+@LastMSLevel+'%') and     
   (IsNull(@BackAcctNumber,'') = '' OR BankAccountNumber like '%'+@BackAcctNumber+'%')))),    
  ResultCount AS (Select COUNT(ReceiptID) AS NumberOfItems FROM FinalResult)    
  SELECT * FROM FinalResult, ResultCount    
  ORDER BY    
  CASE WHEN (@SortOrder=1 and @SortColumn='RECEIPTID') THEN ReceiptId END ASC,    
  CASE WHEN (@SortOrder=1 and @SortColumn='RECEIPTNO') THEN ReceiptNo END ASC,    
  CASE WHEN (@SortOrder=1 and @SortColumn='STATUS') THEN Status END ASC,    
  CASE WHEN (@SortOrder=1 and @SortColumn='BANKACCT') THEN BankAcct END ASC,    
  CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE') THEN OpenDate END ASC,    
  CASE WHEN (@SortOrder=1 and @SortColumn='DEPOSITDATE') THEN DepositDate END ASC,  
  CASE WHEN (@SortOrder=1 and @SortColumn='POSTEDDATE') THEN PostedDate END ASC,   
  CASE WHEN (@SortOrder=1 and @SortColumn='ACCTINGPERIOD') THEN AcctingPeriod END ASC,    
  CASE WHEN (@SortOrder=1 and @SortColumn='REFERENCE') THEN Reference END ASC,    
  CASE WHEN (@SortOrder=1 and @SortColumn='AMOUNT') THEN CAST(Amount AS varchar(50)) END ASC,    
  CASE WHEN (@SortOrder=1 and @SortColumn='AMTAPPLIED') THEN CAST(AmtApplied  AS varchar(50)) END ASC,    
  CASE WHEN (@SortOrder=1 and @SortColumn='AMTREMAINING') THEN CAST(AmtRemaining  AS varchar(50)) END ASC,    
  CASE WHEN (@SortOrder=1 and @SortColumn='CURRENCY') THEN Currency END ASC,    
  CASE WHEN (@SortOrder=1 and @SortColumn='CNTRLNUM') THEN CntrlNum END ASC,    
  CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,    
  CASE WHEN (@SortOrder=1 and @SortColumn='BANKACCOUNTNUMBER')  THEN BankAccountNumber END ASC,    

  CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIPTID') THEN ReceiptId END Desc,    
  CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIPTNO')  THEN ReceiptNo END Desc,    
  CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,    
  CASE WHEN (@SortOrder=-1 and @SortColumn='BANKACCT')  THEN BankAcct END Desc,    
  CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END Desc,    
  CASE WHEN (@SortOrder=-1 and @SortColumn='DEPOSITDATE')  THEN DepositDate END Desc, 
  CASE WHEN (@SortOrder=-1 and @SortColumn='POSTEDDATE') THEN PostedDate END Desc, 
  CASE WHEN (@SortOrder=-1 and @SortColumn='ACCTINGPERIOD')  THEN AcctingPeriod END Desc,    
  CASE WHEN (@SortOrder=-1 and @SortColumn='REFERENCE')  THEN Reference END Desc,    
  CASE WHEN (@SortOrder=-1 and @SortColumn='AMOUNT')  THEN CAST(Amount AS varchar(50)) END Desc,    
  CASE WHEN (@SortOrder=-1 and @SortColumn='AMTAPPLIED')  THEN CAST(AmtApplied  AS varchar(50)) END Desc,    
  CASE WHEN (@SortOrder=-1 and @SortColumn='AMTREMAINING')  THEN CAST(AmtRemaining  AS varchar(50)) END Desc,    
  CASE WHEN (@SortOrder=-1 and @SortColumn='CURRENCY')  THEN Currency END Desc,    
  CASE WHEN (@SortOrder=-1 and @SortColumn='CNTRLNUM')  THEN CntrlNum END Desc,    
  CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END Desc,    
  CASE WHEN (@SortOrder=-1 and @SortColumn='BANKACCOUNTNUMBER')  THEN BankAccountNumber END Desc    
  OFFSET @RecordFrom ROWS     
  FETCH NEXT @PageSize ROWS ONLY    
 END TRY        
 BEGIN CATCH    
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
        , @AdhocComments     VARCHAR(150)    = 'SearchCustomerPayments'     
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReceiptNo, '') + ''',    
            @Parameter2 = ' + ISNULL(CAST(@Reference AS VARCHAR(10)) ,'') +''    
        , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
        exec spLogException     
                @DatabaseName           = @DatabaseName    
                , @AdhocComments          = @AdhocComments    
                , @ProcedureParameters = @ProcedureParameters    
                , @ApplicationName        =  @ApplicationName    
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;    
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
        RETURN(1);    
 END CATCH    
END