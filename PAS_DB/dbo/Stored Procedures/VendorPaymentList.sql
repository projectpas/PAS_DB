/*************************************************************           
 ** File:   [VendorPaymentList]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used VendorPaymentList
 ** Purpose:         
 ** Date:   19/05/2023        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    19/05/2023   Subhash Saliya  changes 
    2    07/04/2023   Satish Gohil    changes(Display data changes)
	3    05/07/2023   Satish Gohil    Voided check condition added
	4    18/07/2023   Moin Bloch      Payment Method Wise Bank Accout And Bank Name
	5    13/09/2023   Moin Bloch      commented RemainingAmount in PaidinFull to show voided entry 
	6    05/10/2023   AMIT GHEDIYA    updated paymentmade sum with creditmemo amount.

--exec VendorPaymentList @PageSize=20,@PageNumber=1,@SortColumn=N'ReceivingReconciliationId',@SortOrder=-1,@GlobalFilter=N'',@InvoiceNum=NULL,@OriginalTotal=0,@RRTotal=0,@InvoiceTotal=0,@Status=N'PaidinFull',@VendorName=NULL,@InvociedDate=NULL,@EntryDate=NULL,@MasterCompanyId=1,@EmployeeId=2

--EXEC VendorPaymentList 10,1,'ReceivingReconciliationId',1,'','',0,0,0,'ALL','',NULL,NULL,1,73   
**************************************************************/

CREATE     PROCEDURE [dbo].[VendorPaymentList]  
 -- Add the parameters for the stored procedure here  
@PageSize int,  
@PageNumber int,  
@SortColumn varchar(50)=null,  
@SortOrder int,   
@GlobalFilter varchar(50) = null,  
@InvoiceNum varchar(50)=null,  
@OriginalTotal varchar(50)=null,  
@RRTotal varchar(50)=null,  
@InvoiceTotal varchar(50)=null,  
@Status varchar(50)=null,  
@VendorName varchar(50)=null,  
@InvociedDate datetime=null,  
@EntryDate datetime=null,  
@MasterCompanyId int = null,  
@EmployeeId bigint  ,
@BankName varchar(50)=null, 
@BankAccountNumber varchar(50)=null 
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  --BEGIN TRANSACTION  
  -- BEGIN  
    DECLARE @RecordFrom int;  
    SET @RecordFrom = (@PageNumber-1) * @PageSize; 
	
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
    
    IF @SortColumn IS NULL  
    BEGIN  
     SET @SortColumn = UPPER('CreatedDate')  
    END   
    ELSE  
    BEGIN   
     SET @SortColumn = UPPER(@SortColumn)  
    END  
     
    IF(@Status = 'PendingPayment')  
    BEGIN  
    ;WITH Result AS (        
		SELECT ReceivingReconciliationId,
		       RRH.InvoiceNum,RRH.[Status],
			   ISNULL(InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRTotal,0) AS RRTotal,
			   ISNULL(PaymentMade,0) AS InvoiceTotal,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			   ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
			   RRH.DueDate AS 'InvociedDate',
			   RRH.DueDate AS 'EntryDate',
			   '' AS 'PaymentMethod',
			   '' AS 'PaymentRef',
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
			   ISNULL(Tab.ReadyToPaymentMade,0) AS 'ReadyToPaymentMade',
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   RRH.VendorId
		  FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId  --WHERE StatusId=3
			   OUTER APPLY (SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,max(PM.Description) as PaymentMethod,Max(VRTPDH.PrintCheck_Wire_Num) as PaymentRef
							FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							     LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsVoidedCheck = 0
			    GROUP BY VD.VendorPaymentDetailsId) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RemainingAmount > 0
    ),  
    FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,DiscountToken,ReadyToPaymentMade,BankName,BankAccountNumber,VendorId FROM Result  
    WHERE (  
       (@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR   
       ([Status] LIKE '%' +@GlobalFilter+'%') OR  
       (InvociedDate LIKE '%' +@GlobalFilter+'%') OR  
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR  
       (OriginalTotal LIKE '%' +@GlobalFilter+'%') OR  
       (RRTotal LIKE '%'+@GlobalFilter+'%') OR  
       (InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR  
       (VendorName LIKE '%' +@GlobalFilter+'%')  
       ))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND   
       (ISNULL(@InvociedDate,'') ='' OR CAST(InvociedDate AS DATE) = CAST(@InvociedDate AS DATE)) AND  
       (ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS DATE) = CAST(@EntryDate AS DATE)) AND  
       (ISNULL(@OriginalTotal,'') ='' OR OriginalTotal LIKE '%'+ @OriginalTotal+'%') AND  
       (ISNULL(@RRTotal,'') ='' OR RRTotal LIKE '%'+@RRTotal+'%') AND  
       (ISNULL(@InvoiceTotal,'') ='' OR InvoiceTotal LIKE '%'+ @InvoiceTotal+'%') AND  
       (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%'))  
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate, EntryDate,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems,DiscountToken,ReadyToPaymentMade,BankName,BankAccountNumber,VendorId FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC,  
  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC  
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END  
    ELSE IF(@Status = 'ReadytoPay' )
    BEGIN  
    ;WITH Result AS (
     SELECT ReceivingReconciliationId,
			RRH.InvoiceNum,RRH.[Status],
			ISNULL(InvoiceTotal,0) AS OriginalTotal,
			ISNULL(RRTotal,0) AS RRTotal,
			ISNULL(PaymentMade,0) AS InvoiceTotal,
	        RRH.RemainingAmount AS 'DifferenceAmount',  
            VN.VendorName,
			ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
			RRH.DueDate AS 'InvociedDate',
			RRH.DueDate AS 'EntryDate',
			''AS 'PaymentMethod',
			'' AS 'PaymentRef',
			'' AS 'DateProcessed',
			'' AS 'CheckCrashed',
			ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
			ISNULL(Tab.ReadyToPaymentMade,0) AS 'ReadyToPaymentMade',
			'' AS BankName,
			'' AS BankAccountNumber,
			Tab.ReadyToPayId,
			RRH.VendorId,
			RRH.CreatedDate
	   FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
			INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId  --WHERE StatusId=3
			OUTER APPLY (SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) AS PaymentMethod,MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,VRTPDH.ReadyToPayId
						 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
						 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
						 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
						 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsVoidedCheck = 0
						 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId) AS Tab
	   WHERE RRH.MasterCompanyId = @MasterCompanyId AND RemainingAmount > 0 --WHERE StatusId=3  
    ),  
    FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,DiscountToken,ReadyToPaymentMade,BankName,BankAccountNumber,ReadyToPayId,VendorId,CreatedDate  FROM Result  
    WHERE (  
	   (@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR   
       ([Status] LIKE '%' +@GlobalFilter+'%') OR  
       (InvociedDate LIKE '%' +@GlobalFilter+'%') OR  
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR  
       (OriginalTotal LIKE '%' +@GlobalFilter+'%') OR  
       (RRTotal LIKE '%'+@GlobalFilter+'%') OR  
       (InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR  
       (VendorName LIKE '%' +@GlobalFilter+'%')  
       ))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND   
       (ISNULL(@InvociedDate,'') ='' OR CAST(InvociedDate AS DATE) = CAST(@InvociedDate AS DATE)) AND  
       (ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS DATE) = CAST(@EntryDate AS DATE)) AND  
       (ISNULL(@OriginalTotal,'') ='' OR OriginalTotal LIKE '%'+ @OriginalTotal+'%') AND  
       (ISNULL(@RRTotal,'') ='' OR RRTotal LIKE '%'+@RRTotal+'%') AND  
       (ISNULL(@InvoiceTotal,'') ='' OR InvoiceTotal LIKE '%'+ @InvoiceTotal+'%') AND  
       (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%'))  
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate, EntryDate,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems,DiscountToken,ReadyToPaymentMade,BankName,BankAccountNumber,ReadyToPayId,VendorId  FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC,  
  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC  
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END  
	ELSE IF(@Status = 'SelectedtobePaid')  
    BEGIN  
    ;WITH Result AS (        
		SELECT ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   RRH.[Status],
			   ISNULL(InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRTotal,0) AS RRTotal,
			   ISNULL(PaymentMade,0) AS InvoiceTotal,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			   ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
			   RRH.DueDate AS 'InvociedDate',
			   RRH.DueDate AS 'EntryDate',
			   ISNULL(Tab.PaymentMethod,'') AS 'PaymentMethod',
			   ISNULL(Tab.PaymentRef,'') AS 'PaymentRef',
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
			   ISNULL(Tab.ReadyToPaymentMade,0) 'ReadyToPaymentMade',
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   Tab.ReadyToPayId,
			   Tab.ReadyToPayDetailsId,
			   RRH.VendorId,
			   RRH.CreatedDate
		  FROM [dbo].[VendorPaymentDetails] RRH WITH(NOLOCK)
               INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId  --WHERE StatusId=3
	           OUTER APPLY (SELECT VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) as PaymentMethod,MAX(VD.CheckNumber) AS PaymentRef,VRTPDH.ReadyToPayId
							 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.CheckNumber IS NULL
							 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RemainingAmount > 0 --WHERE StatusId=3  
    ),  
    FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,DiscountToken,ReadyToPaymentMade,BankName,BankAccountNumber,ReadyToPayId,ReadyToPayDetailsId,VendorId,CreatedDate  FROM Result  
    WHERE  ISNULL(ReadyToPayId,0) > 0 AND (  
       (@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR   
       ([Status] LIKE '%' +@GlobalFilter+'%') OR  
       (InvociedDate LIKE '%' +@GlobalFilter+'%') OR  
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR  
       (OriginalTotal LIKE '%' +@GlobalFilter+'%') OR  
       (RRTotal LIKE '%'+@GlobalFilter+'%') OR  
       (InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR  
       (VendorName LIKE '%' +@GlobalFilter+'%')  
       ))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND   
       (ISNULL(@InvociedDate,'') ='' OR CAST(InvociedDate AS DATE) = Cast(@InvociedDate AS DATE)) AND  
       (ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS DATE) = Cast(@EntryDate AS DATE)) AND  
       (ISNULL(@OriginalTotal,'') ='' OR OriginalTotal LIKE '%'+ @OriginalTotal+'%') AND  
       (ISNULL(@RRTotal,'') ='' OR RRTotal LIKE '%'+@RRTotal+'%') AND  
       (ISNULL(@InvoiceTotal,'') ='' OR InvoiceTotal LIKE '%'+ @InvoiceTotal+'%') AND  
       (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%'))  
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate, EntryDate,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems,DiscountToken,ReadyToPaymentMade,BankName,BankAccountNumber,ReadyToPayId,ReadyToPayDetailsId,VendorId  FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID') THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC,  
  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC  
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END  
    ELSE IF(@Status = 'PartiallyPaid')  
    BEGIN  
    ;WITH Result AS (  
		SELECT ReceivingReconciliationId,
			   RRH.InvoiceNum,
			   RRH.[Status],
			   ISNULL(InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRTotal,0) AS RRTotal,
			   ISNULL(PaymentMade,0) AS InvoiceTotal,
			   ISNULL(RemainingAmount,0) AS 'DifferenceAmount',  
			   VN.VendorName,
			   ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
			   RRH.DueDate AS 'InvociedDate',
			   RRH.DueDate AS 'EntryDate',
			   ISNULL(Tab.PaymentMethod,'') AS 'PaymentMethod',
			   ISNULL(Tab.PaymentRef,'') AS 'PaymentRef',
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   ISNULL(RRH.DiscountToken,0) AS 'DiscountToken',  
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   ISNULL(Tab.ReadyToPaymentMade,0) AS 'ReadyToPaymentMade',
			   Tab.ReadyToPayId,
			   Tab.ReadyToPayDetailsId,
			   Tab.IsVoidedCheck,
			   RRH.VendorId,
			   tab.PaymentMethodId,
			   tab.CreatedDate
		  FROM [dbo].[VendorPaymentDetails] RRH WITH(NOLOCK) 
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId 
			   OUTER APPLY (SELECT VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) AS PaymentMethod,CASE WHEN VD.IsVoidedCheck =1 THEN MAX(VD.CheckNumber) + ' (V)' ELSE MAX(VD.CheckNumber) END PaymentRef,VRTPDH.ReadyToPayId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate
		                    FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
				OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VD.ReadyToPayId =  SS.ReadyToPayId AND  VD.VendorId = SS.VendorId AND  VD.PaymentMethodId = SS.PaymentMethodId) AS SRT
		  WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.CheckNumber IS NOT NULL AND IsVoidedCheck = 0
			GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate) AS Tab
		  WHERE RRH.MasterCompanyId = @MasterCompanyId AND PaymentMade > 0 AND RemainingAmount > 0--WHERE StatusId=3  
    ),  
    FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate,ReadyToPaymentMade,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,DiscountToken,BankName,BankAccountNumber,ReadyToPayId,ReadyToPayDetailsId,IsVoidedCheck,VendorId,PaymentMethodId,CreatedDate FROM Result  
    WHERE (  
	   (@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR   
       ([Status] LIKE '%' +@GlobalFilter+'%') OR  
       (InvociedDate LIKE '%' +@GlobalFilter+'%') OR  
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR  
       (OriginalTotal LIKE '%' +@GlobalFilter+'%') OR  
       (RRTotal LIKE '%'+@GlobalFilter+'%') OR  
       (InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR	
       (VendorName LIKE '%' +@GlobalFilter+'%')  
       ))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND   
       (ISNULL(@InvociedDate,'') ='' OR CAST(InvociedDate AS DATE) = CAST(@InvociedDate AS DATE)) AND  
       (ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS DATE) = CAST(@EntryDate AS DATE)) AND  
       (ISNULL(@OriginalTotal,'') ='' OR OriginalTotal LIKE '%'+ @OriginalTotal+'%') AND  
       (ISNULL(@RRTotal,'') ='' OR RRTotal LIKE '%'+@RRTotal+'%') AND  
       (ISNULL(@InvoiceTotal,'') ='' OR InvoiceTotal LIKE '%'+ @InvoiceTotal+'%') AND  
       (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%'))  
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate, EntryDate,ReadyToPaymentMade,
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems,DiscountToken,BankName,BankAccountNumber,ReadyToPayId,ReadyToPayDetailsId,IsVoidedCheck,VendorId,PaymentMethodId,CreatedDate FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC,  
	 CASE WHEN (@SortOrder=1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC,  
  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedDate')  THEN CreatedDate END DESC
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END  
    ELSE IF(@Status = 'PaidinFull')  
    BEGIN  
    ;With Result AS (  
		SELECT 0 AS ReceivingReconciliationId,
		CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS InvoiceNum,
		RRH.[Status],
		0 AS OriginalTotal,
		0 AS RRTotal,
		SUM(ISNULL(VRTPD.PaymentMade,0)) AS InvoiceTotal,
		0 AS 'DifferenceAmount',  
		VRTPD.VendorId,
		VN.VendorName,
		ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',		
		CheckDate AS 'InvociedDate',
		CheckDate AS 'EntryDate',		
		'' AS 'PaymentMethod',
		CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS 'PaymentRef',
		'' AS 'DateProcessed',
		'' AS 'CheckCrashed',
		0 AS 'DiscountToken'
		,CASE WHEN VRTPD.PaymentMethodId = @Check THEN lebl.BankName 
		      WHEN VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.BankName 
			  WHEN VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBank 
			  WHEN VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.BankName 
			  WHEN VRTPD.PaymentMethodId = @CreditCard THEN '' END AS BankName
		,CASE WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber + ' (V)' 
			  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.AccountNumber + ' (V)' 
			  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBankAccount + ' (V)' 
			  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.AccountNumber + ' (V)' 
			  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @CreditCard THEN '' 
			  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber 
			  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.AccountNumber 
			  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBankAccount 
			  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.AccountNumber
			  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @CreditCard THEN '' END AS 'BankAccountNumber'
		,VRTPDH.ReadyToPayId
		,VRTPD.IsVoidedCheck
		--,VRTPD.CreatedDate
		,VRTPD.PaymentMethodId
		,SRT.CreatedDate
		FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
		INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
		 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.ReceivingReconciliationId = RRH.ReceivingReconciliationId
		 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		 LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRTPDH.BankId
		 LEFT JOIN [dbo].[VendorDomesticWirePayment] VDWP WITH(NOLOCK) ON VDWP.VendorId = VRTPD.VendorId
		 LEFT JOIN [dbo].[DomesticWirePayment] DWPL WITH(NOLOCK) ON DWPL.DomesticWirePaymentId = VDWP.DomesticWirePaymentId
		 LEFT JOIN [dbo].[VendorInternationlWirePayment] VIWP WITH(NOLOCK) ON VIWP.VendorId = VRTPD.VendorId
		 LEFT JOIN [dbo].[InternationalWirePayment] IWPL WITH(NOLOCK) ON IWPL.InternationalWirePaymentId = VIWP.InternationalWirePaymentId
		 LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId
		 OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VRTPD.ReadyToPayId =  SS.ReadyToPayId AND  VRTPD.VendorId = SS.VendorId AND  VRTPD.PaymentMethodId = SS.PaymentMethodId) AS SRT
	  WHERE RRH.MasterCompanyId = @MasterCompanyId 
	     AND (RemainingAmount <= 0  OR IsVoidedCheck = 1) 
		 GROUP BY VRTPD.CheckNumber,lebl.BankName,lebl.BankAccountNumber,DWPL.AccountNumber,IWPL.BeneficiaryBankAccount, VRTPDH.ReadyToPayId,RRH.[Status],VN.IsVendorOnHold
		 ,CheckDate,VN.VendorName,IsVoidedCheck,VRTPD.VendorId,VRTPD.PaymentMethodId,SRT.CreatedDate,DWPL.BankName,IWPL.BeneficiaryBank 		 
	),  
    FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate,DiscountToken,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,BankName,BankAccountNumber,ReadyToPayId,IsVoidedCheck,VendorId,PaymentMethodId,CreatedDate FROM Result  
    WHERE (  
     (@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR   
       ([Status] LIKE '%' +@GlobalFilter+'%') OR  
       (InvociedDate LIKE '%' +@GlobalFilter+'%') OR  
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR  
       (OriginalTotal LIKE '%' +@GlobalFilter+'%') OR  
       (RRTotal LIKE '%'+@GlobalFilter+'%') OR  
	   (BankName LIKE '%' +@GlobalFilter+'%') OR  
       (BankAccountNumber LIKE '%'+@GlobalFilter+'%') OR  
       (InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR  
       (VendorName LIKE '%' +@GlobalFilter+'%')  
       ))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND   
       (ISNULL(@InvociedDate,'') ='' OR CAST(InvociedDate AS DATE) = CAST(@InvociedDate AS DATE)) AND  
       (ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS DATE) = CAST(@EntryDate AS DATE)) AND  
       (ISNULL(@OriginalTotal,'') ='' OR OriginalTotal LIKE '%'+ @OriginalTotal+'%') AND  
       (ISNULL(@RRTotal,'') ='' OR RRTotal LIKE '%'+@RRTotal+'%') AND  
       (ISNULL(@InvoiceTotal,'') ='' OR InvoiceTotal LIKE '%'+ @InvoiceTotal+'%') AND  
	   (ISNULL(@InvoiceTotal,'') ='' OR InvoiceTotal LIKE '%'+ @InvoiceTotal+'%') AND 
	   (ISNULL(@BankName,'') ='' OR BankName LIKE '%'+ @BankName+'%') AND 
	   (ISNULL(@BankAccountNumber,'') ='' OR BankAccountNumber LIKE '%'+ @BankAccountNumber+'%') AND 
       (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%'))  
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate, EntryDate,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems,DiscountToken,BankName,BankAccountNumber,ReadyToPayId,IsVoidedCheck,VendorId,PaymentMethodId,CreatedDate FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC,  
	 CASE WHEN (@SortOrder=1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC,  
	  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC,  	 
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedDate')  THEN CreatedDate END DESC

     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END  
   --END  
   --COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    --ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'VendorPaymentList'   
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