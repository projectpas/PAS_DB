/*************************************************************           
 ** File:   [VendorPaymentList]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used VendorPaymentList
 ** Purpose:         
 ** Date:   19/05/2023        
          
 ** PARAMETERS:  @UserType varchar(60)   
         
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
	7    20/10/2023   Devendra Shekh  added union for creditmemo details
	8    26/10/2023   Moin Bloch      added open Receiving Reconciliation List
	9    27/10/2023   Devendra Shekh  Changes for customer creditmemo details
	10   30/10/2023   Moin Bloch      added status Filter
	11   31/10/2023   Devendra Shekh  Changes for nonpo details
	12   02/11/2023   Devendra Shekh  Changes for nonpo details
	13   15/11/2023   Moin Bloch      added DueDate and Days Past Due
	14   07/03/2024   AMIT GHEDIYA    Update Status Name as per PN-6767 (Filter param added)
	15   26/03/2024   Devendra Shekh  added temp table and removed union
	16   28/03/2024   Devendra Shekh  table changes for creditMemo(changed to same as nonPO)
	17   02/04/2024   AMIT GHEDIYA    filter update
	18   05/04/2024   AMIT GHEDIYA    Update status for Print Check & Paid in full.
	19   08/04/2024   AMIT GHEDIYA    Get Vendor Payment Control Num.

 --EXEC VendorPaymentList 10,1,'ReceivingReconciliationId',1,'','',0,0,0,'ALL','',NULL,NULL,1,73   
**************************************************************/
CREATE   PROCEDURE [dbo].[VendorPaymentList]  
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
@CurrentStatus varchar(50)=null,  
@VendorName varchar(50)=null,  
@InvociedDate datetime=null,  
@EntryDate datetime=null,  
@DueDate datetime=null,  
@DaysPastDue varchar(50)=null,  
@MasterCompanyId int = null,  
@EmployeeId bigint  ,
@BankName varchar(50)=null, 
@BankAccountNumber varchar(50)=null,
@PaymentHold varchar(50) = NULL,
@ReadyToPaymentMade varchar(50)=null,
@DiscountToken varchar(50)=null,
@DifferenceAmount varchar(50)=null,
@PaymentMethod varchar(50)=null,
@PaymentRef varchar(50)=null,
@CheckCrashed varchar(50)=null
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
	DECLARE @NonPOInvoiceHeaderStatusId INT;
	DECLARE @StatusId VARCHAR(50) = '3,6,10';

	SELECT @NonPOInvoiceHeaderStatusId = NonPOInvoiceHeaderStatusId FROM [dbo].[NonPOInvoiceHeaderStatus] WITH(NOLOCK) WHERE [Description] = 'Posted';
	SELECT @Check = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'Check';
	SELECT @DomesticWire = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'Domestic Wire';
	SELECT @InternationalWire = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'International Wire';
	SELECT @ACHTransfer = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'ACH Transfer';
	SELECT @CreditCard = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'Credit Card';
    
    IF @SortColumn IS NULL  
    BEGIN  
		SET @SortColumn = UPPER('CreatedDate')  
    END   
    ELSE  
    BEGIN   
		SET @SortColumn = UPPER(@SortColumn)  
    END  

	IF OBJECT_ID(N'tempdb..#TEMPVendorPaymentListRecords') IS NOT NULL    
		BEGIN    
	DROP TABLE #TEMPVendorPaymentListRecords
	END

	CREATE TABLE #TEMPVendorPaymentListRecords(        
		[ID] BIGINT IDENTITY(1,1),      
		[ReceivingReconciliationId] BIGINT NOT NULL,
		[InvoiceNum] VARCHAR(100),
		[Status] VARCHAR(50),
		[OriginalTotal] DECIMAL(18, 2) NULL,
		[RRTotal] DECIMAL(18, 2) NULL,
		[InvoiceTotal] DECIMAL(18, 2) NULL,
		[DifferenceAmount] DECIMAL(18, 2) NULL,
		[VendorName] VARCHAR(100) NULL,
		[PaymentHold] VARCHAR(100) NULL,
		[InvociedDate] DATETIME2 NULL,
		[EntryDate] DATETIME2 NULL,
		[DueDate] DATETIME2 NULL,
		[DaysPastDue] INT NULL,
		[DiscountToken] DECIMAL(18, 2) NULL,
		[ReadyToPaymentMade] VARCHAR(250) NULL,
		[PaymentMethod] VARCHAR(250) NULL,
		[PaymentRef] VARCHAR(50) NULL,
		[DateProcessed] VARCHAR(20) NULL,
		[CheckCrashed] VARCHAR(20) NULL,
		[BankName] VARCHAR(100) NULL,
		[BankAccountNumber] VARCHAR(50) NULL,
		[ReadyToPayId] BIGINT NULL,
		[ReadyToPayDetailsId] BIGINT NULL,
		[IsVoidedCheck] BIT NULL,
		[VendorId] BIGINT NULL,
		[PaymentMethodId] BIGINT NULL,
		[CreatedDate] DATETIME2 NULL,
		[IsVendorPayment] BIT NULL,
		[IsReceivingReconciliation] BIT NULL,
		[IsCreditMemo] BIT NULL,
		[IsNonPOInvoice] BIT NULL,
		[IsCustomerCreditPayment] BIT NULL,
		[ControlNumber] VARCHAR(100) NULL
		) 
     
    IF(@CurrentStatus = 'PendingPayment')  
    BEGIN  
    --;WITH Result AS (       
	-- VendorPayment -ReceivingReconciliation DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [ReadyToPayId], [BankName],
		[BankAccountNumber], [VendorId], [ControlNumber])
		SELECT RRH.ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   --RRH.[Status],			   
			   CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' 
			        WHEN ISNULL(RRC.IsInvoiceOnHold,0) = 0 AND  RRH.PaymentMade = 0 THEN 'Ready to Pay'
			   ELSE 'Pending Payment' END AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			   --ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
			   CASE WHEN RRC.IsInvoiceOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
			   RRH.DueDate AS 'InvociedDate',
			   RRH.DueDate AS 'EntryDate',			   			  
			   --DATEADD(DAY, ctm.NetDays,RRC.InvoiceDate) AS 'DueDate',   
			   --CASE WHEN DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  			   
			   CASE WHEN IIF(TRY_CAST(RRC.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),RRC.InvoiceDate)
					  ELSE NULL END	AS 'DueDate',
			   CASE WHEN IIF(TRY_CAST(RRC.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
			   --'' AS 'PaymentMethod',
			   --'' AS 'PaymentRef',
			   PaymentMethod = (SELECT MAX(PM.Description) FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsGenerated = 1),
			   --ISNULL(Tab.PaymentRef,'') AS 'PaymentRef',
			   PaymentRef = (SELECT MAX(VD.CheckNumber) FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
								 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId  AND VD.IsGenerated = 1),
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
			   ISNULL(Tab.ReadyToPaymentMade,0) AS 'ReadyToPaymentMade',
			   ISNULL(Tab.ReadyToPayId,0) AS 'ReadyToPayId',
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   RRH.VendorId,
			   --VPControlNum = (SELECT ISNULL(VD.VPControlNum,'') FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
						--		 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsGenerated = 1)
			   ISNULL(TAB.ControlNumber,'') AS 'ControlNumber'
		  FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		       INNER JOIN [dbo].[ReceivingReconciliationHeader] RRC WITH(NOLOCK) ON RRH.[ReceivingReconciliationId] = RRC.[ReceivingReconciliationId]	
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId  --WHERE StatusId=3
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   OUTER APPLY (SELECT VD.VendorPaymentDetailsId,
			                       SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
								   SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
								   MAX(PM.Description) AS PaymentMethod,
								   MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
								   VRTPDH.ReadyToPayId,
								   VD.ControlNumber
							FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							     LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsVoidedCheck = 0
			    GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RemainingAmount > 0 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0

	--UNION ALL
	-- -ReceivingReconciliation DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [ReadyToPayId], [BankName],
		[BankAccountNumber], [VendorId], [ControlNumber])
		SELECT DISTINCT
		       RRH.ReceivingReconciliationId,
			   RRH.InvoiceNum,
			   'Pending Payment' AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   0 AS InvoiceTotal,
			   ISNULL(RRH.InvoiceTotal,0) AS 'DifferenceAmount', 
			   VN.VendorName,
			   --ISNULL(RRH.IsInvoiceOnHold,0) AS 'PaymentHold',
			   CASE WHEN RRH.IsInvoiceOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
			   RRH.InvoiceDate AS 'InvociedDate',
			   RRH.InvoiceDate AS 'EntryDate',
			   --DATEADD(DAY, ctm.NetDays,RRH.InvoiceDate) AS 'DueDate',  
			   --CASE WHEN DATEDIFF(DAY, (CAST(RRH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(RRH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  
			   CASE WHEN IIF(TRY_CAST(RRH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),RRH.InvoiceDate)
					  ELSE NULL END	AS 'DueDate',
			   CASE WHEN IIF(TRY_CAST(RRH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(RRH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(RRH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
			   '' AS 'PaymentMethod',
			   '' AS 'PaymentRef',
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   0 AS 'DiscountToken',
			   0 AS 'ReadyToPaymentMade',
			   0 AS 'ReadyToPayId',
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   RRH.VendorId,
			   '' AS 'ControlNumber' 
		FROM [dbo].[ReceivingReconciliationHeader] RRH  WITH(NOLOCK) 		
			INNER JOIN [dbo].[ReceivingReconciliationDetails] RRD WITH(NOLOCK) ON RRH.[ReceivingReconciliationId] = RRD.[ReceivingReconciliationId]	
			INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.[VendorId] = VN.[VendorId]	
			LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
		WHERE RRH.[MasterCompanyId] = @MasterCompanyId 
		  AND RRH.[StatusId] = 1

	--UNION ALL
	-- VendorPayment -CreditMemo DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [ReadyToPayId], [BankName],
		[BankAccountNumber], [VendorId], [ControlNumber])
		SELECT RRH.ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' 
			        WHEN RRH.PaymentMade = 0 THEN 'Ready to Pay'
			   ELSE 'Pending Payment' END AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			  -- 0 AS 'PaymentHold',
			  'NO' AS 'PaymentHold',
			   RRH.DueDate AS 'InvociedDate',
			   RRH.DueDate AS 'EntryDate',
			   CASE WHEN IIF(TRY_CAST(CM.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),CM.InvoiceDate)
					  ELSE NULL END	AS 'DueDate',
			    CASE WHEN IIF(TRY_CAST(CM.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
			   --'' AS 'PaymentMethod',
			   --'' AS 'PaymentRef',
			  PaymentMethod = (SELECT MAX(PM.Description) FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId  AND VD.IsGenerated = 1),
			   --ISNULL(Tab.PaymentRef,'') AS 'PaymentRef',
			   PaymentRef = (SELECT MAX(VD.CheckNumber) FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
								 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId  AND VD.IsGenerated = 1),
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
			   ISNULL(Tab.ReadyToPaymentMade,0) AS 'ReadyToPaymentMade',
			   ISNULL(Tab.ReadyToPayId,0) AS 'ReadyToPayId',
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   RRH.VendorId,
			   --VPControlNum = (SELECT ISNULL(VD.VPControlNum,'') FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
						--		 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsGenerated = 1)
			   ISNULL(TAB.ControlNumber,'') AS 'ControlNumber'
		  FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		       INNER JOIN [dbo].[CreditMemo] CM WITH(NOLOCK) ON RRH.CreditMemoHeaderId = CM.CreditMemoHeaderId	
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   OUTER APPLY (SELECT VD.VendorPaymentDetailsId,
			                       SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
								   SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
								   MAX(PM.Description) AS PaymentMethod,
								   MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
								   VRTPDH.ReadyToPayId,
								   VD.ControlNumber
							FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							     LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsVoidedCheck = 0
			    GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RRH.RemainingAmount > 0 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0 
		  AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) = 0
		  AND ISNULL(RRH.CreditMemoHeaderId, 0) <> 0

	--UNION ALL
	-- VendorPayment NonPOInvoice DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [ReadyToPayId], [BankName],
		[BankAccountNumber], [VendorId], [ControlNumber])
		SELECT 0 AS ReceivingReconciliationId,
				NPH.NPONumber AS [InvoiceNum],
				NPHS.[Description] AS [Status],
				(ISNULL(part.ExtendedPrice,0)) AS OriginalTotal,
				0 AS RRTotal,
				0 AS InvoiceTotal,
				0 AS 'DifferenceAmount',  
				NPH.VendorName,
				--0 AS 'PaymentHold',
				'NO' AS 'PaymentHold',
				NPH.UpdatedDate AS 'InvociedDate',
				NPH.UpdatedDate AS 'EntryDate',
				--DATEADD(DAY, ctm.NetDays,NPH.InvoiceDate) AS 'DueDate', 
				--CASE WHEN DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  				
				CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),NPH.InvoiceDate)
					  ELSE NULL END	AS 'DueDate',
			    CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
				--'' AS 'PaymentMethod',
				--'' AS 'PaymentRef',
				ISNULL(Tab.PaymentMethod,'') AS 'PaymentMethod',
			    ISNULL(Tab.PaymentRef,'') AS 'PaymentRef',
				'' AS 'DateProcessed',
				'' AS 'CheckCrashed',
				ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
				ISNULL(Tab.ReadyToPaymentMade,0) AS 'ReadyToPaymentMade',
				ISNULL(Tab.ReadyToPayId,0) AS 'ReadyToPayId',
				'' AS BankName,
				'' AS BankAccountNumber,
				NPH.VendorId,
				ISNULL(VPD.ControlNumber,'') AS 'ControlNumber'
		  FROM [dbo].[NonPOInvoiceHeader] NPH  WITH(NOLOCK)
		       LEFT JOIN [dbo].[VendorReadyToPayDetails] VPD WITH(NOLOCK) ON VPD.NonPOInvoiceId = NPH.NonPOInvoiceId	
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON NPH.VendorId = VN.VendorId
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   INNER JOIN [dbo].[NonPOInvoiceHeaderStatus] NPHS WITH(NOLOCK) ON NPHS.[NonPOInvoiceHeaderStatusId] = NPH.[StatusId]
			   --OUTER APPLY (SELECT VD.VendorPaymentDetailsId,
			   --                    SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
						--		   SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
						--		   MAX(PM.Description) AS PaymentMethod,
						--		   --MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
						--		   CASE WHEN VD.IsVoidedCheck =1 THEN MAX(VD.CheckNumber) + ' (V)' ELSE MAX(VD.CheckNumber) END PaymentRef,
						--		   VRTPDH.ReadyToPayId
						--	FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
						--		 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
						--	     LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
						--	WHERE ISNULL(VD.VendorReadyToPayDetailsTypeId, 0) = 3 AND VD.IsVoidedCheck = 0 AND VD.IsGenerated = 1 AND ISNULL(VD.NonPOInvoiceId, 0) = NPH.NonPOInvoiceId
			   -- GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.IsVoidedCheck) AS Tab
			   OUTER APPLY (SELECT VD.VendorPaymentDetailsId,ReadyToPayDetailsId,
								   SUM(ISNULL(VD.PaymentMade,0)) ReadyToPaymentMade,
								   SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
								   MAX(PM.Description) AS PaymentMethod,
								   CASE WHEN VD.IsVoidedCheck =1 THEN MAX(VD.CheckNumber) + ' (V)' ELSE MAX(VD.CheckNumber) END PaymentRef,
								   VRTPDH.ReadyToPayId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate
		                    FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
				OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VD.ReadyToPayId =  SS.ReadyToPayId AND  VD.VendorId = SS.VendorId AND  VD.PaymentMethodId = SS.PaymentMethodId) AS SRT
		  WHERE ISNULL(VD.VendorPaymentDetailsId,0) = VPD.VendorPaymentDetailsId AND VD.CheckNumber IS NOT NULL AND IsVoidedCheck = 0
			GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate) AS Tab
				OUTER APPLY (SELECT VD.NonPOInvoiceId,
								   SUM(ISNULL(VD.ExtendedPrice,0)) ExtendedPrice
							FROM [dbo].[NonPOInvoicePartDetails] VD WITH(NOLOCK) 
							WHERE VD.NonPOInvoiceId = NPH.NonPOInvoiceId
			    GROUP BY VD.NonPOInvoiceId) AS part
	      WHERE NPH.MasterCompanyId = @MasterCompanyId AND part.ExtendedPrice > 0  AND VPD.CheckNumber IS NULL AND NPH.PostedDate IS NULL
				AND NPHS.NonPOInvoiceHeaderStatusId = @NonPOInvoiceHeaderStatusId

		--UNION ALL
		-- VendorPayment -NonPOInvoice DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [ReadyToPayId], [BankName],
		[BankAccountNumber], [VendorId], [ControlNumber])
		SELECT RRH.ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' 
			        WHEN RRH.PaymentMade = 0 THEN 'Ready to Pay'
			   ELSE 'Pending Payment' END AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			   --0 AS 'PaymentHold',
			   'NO' AS 'PaymentHold',
			   RRH.DueDate AS 'InvociedDate',
			   RRH.DueDate AS 'EntryDate',
			  --DATEADD(DAY, ctm.NetDays,NPH.InvoiceDate) AS 'DueDate',  
			  -- CASE WHEN DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  
			   CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),NPH.InvoiceDate)
					  ELSE NULL END	AS 'DueDate',
			    CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
			   --'' AS 'PaymentMethod',
			   --'' AS 'PaymentRef',
			   ISNULL(Tab.PaymentMethod,'') AS 'PaymentMethod',
			   ISNULL(Tab.PaymentRef,'') AS 'PaymentRef',
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
			   ISNULL(Tab.ReadyToPaymentMade,0) AS 'ReadyToPaymentMade',
			   ISNULL(Tab.ReadyToPayId,0) AS 'ReadyToPayId',
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   RRH.VendorId,
			   --VPControlNum = (SELECT ISNULL(VD.VPControlNum,'') FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
						--		 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsGenerated = 1)
			    ISNULL(TAB.ControlNumber,'') AS 'ControlNumber'
		  FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		       INNER JOIN [dbo].[NonPOInvoiceHeader] NPH WITH(NOLOCK) ON RRH.NonPOInvoiceId = NPH.NonPOInvoiceId 	
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId  --WHERE StatusId=3
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   OUTER APPLY (SELECT VD.VendorPaymentDetailsId,ReadyToPayDetailsId,
								   SUM(ISNULL(VD.PaymentMade,0)) ReadyToPaymentMade,
								   SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
								   MAX(PM.Description) AS PaymentMethod,
								   CASE WHEN VD.IsVoidedCheck =1 THEN MAX(VD.CheckNumber) + ' (V)' ELSE MAX(VD.CheckNumber) END PaymentRef,
								   VRTPDH.ReadyToPayId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate,VD.ControlNumber
		                    FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
				OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VD.ReadyToPayId =  SS.ReadyToPayId AND  VD.VendorId = SS.VendorId AND  VD.PaymentMethodId = SS.PaymentMethodId) AS SRT
		  WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.CheckNumber IS NOT NULL AND IsVoidedCheck = 0
			GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate,VD.ControlNumber) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RemainingAmount > 0 AND ISNULL(RRH.NonPOInvoiceId, 0) <> 0
		        AND NPH.StatusId = @NonPOInvoiceHeaderStatusId

	    --CustomerCreditPayment DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [ReadyToPayId], [BankName],
		[BankAccountNumber], [VendorId], [ControlNumber])
		SELECT RRH.ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' 
			        WHEN RRH.PaymentMade = 0 THEN 'Ready to Pay'
			   ELSE 'Pending Payment' END AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			   --0 AS 'PaymentHold',
			   'NO' AS 'PaymentHold',
			   RRH.DueDate AS 'InvociedDate',
			   RRH.DueDate AS 'EntryDate',
			   CASE WHEN IIF(TRY_CAST(CCPD.ProcessedDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),CCPD.ProcessedDate)
					  ELSE NULL END	AS 'DueDate',
			    CASE WHEN IIF(TRY_CAST(CCPD.ProcessedDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(CCPD.ProcessedDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(CCPD.ProcessedDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
			   --'' AS 'PaymentMethod',
			   --'' AS 'PaymentRef',
			   ISNULL(Tab.PaymentMethod,'') AS 'PaymentMethod',
			   ISNULL(Tab.PaymentRef,'') AS 'PaymentRef',
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
			   ISNULL(Tab.ReadyToPaymentMade,0) AS 'ReadyToPaymentMade',
			   ISNULL(Tab.ReadyToPayId,0) AS 'ReadyToPayId',
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   RRH.VendorId,
			   --VPControlNum = (SELECT ISNULL(VD.VPControlNum,'') FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
						--		 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsGenerated = 1)
			   ISNULL(TAB.ControlNumber,'') AS 'ControlNumber'
		  FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		       INNER JOIN [dbo].[CustomerCreditPaymentDetail] CCPD WITH(NOLOCK) ON RRH.CustomerCreditPaymentDetailId = CCPD.CustomerCreditPaymentDetailId	
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   OUTER APPLY (SELECT VD.VendorPaymentDetailsId,
			                       SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
								   SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
								   MAX(PM.Description) AS PaymentMethod,
								   MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
								   VRTPDH.ReadyToPayId,
								   VD.ControlNumber
							FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							     LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsGenerated = 1 AND VD.IsVoidedCheck = 0
			    GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RRH.RemainingAmount > 0 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0 AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) <> 0

    --),  
    ;WITH FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate,DueDate, DaysPastDue, 
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,DiscountToken,ReadyToPaymentMade,BankName,BankAccountNumber,VendorId,ControlNumber FROM #TEMPVendorPaymentListRecords  
    WHERE -- ISNULL(ReadyToPayId,0) = 0 AND 
	   ((@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR   
       ([Status] LIKE '%' +@GlobalFilter+'%') OR  
       (InvociedDate LIKE '%' +@GlobalFilter+'%') OR  
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR  
       (OriginalTotal LIKE '%' +@GlobalFilter+'%') OR  
       (RRTotal LIKE '%'+@GlobalFilter+'%') OR  
	   (DaysPastDue LIKE '%'+@GlobalFilter+'%') OR  
       (InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR  
       (VendorName LIKE '%' +@GlobalFilter+'%')  OR
	   (ReadyToPaymentMade LIKE '%' +@GlobalFilter+'%') OR
	   (DiscountToken LIKE '%' +@GlobalFilter+'%') OR
	   (DifferenceAmount LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentMethod LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentRef LIKE '%' +@GlobalFilter+'%') OR
	   (CheckCrashed LIKE '%' +@GlobalFilter+'%')
       ))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND   
       (ISNULL(@InvociedDate,'') ='' OR CAST([InvociedDate] AS DATE) = CAST(@InvociedDate AS DATE)) AND  
       (ISNULL(@EntryDate,'') ='' OR CAST([EntryDate] AS DATE) = CAST(@EntryDate AS DATE)) AND
	   (ISNULL(@DueDate,'') ='' OR CAST([DueDate] AS DATE) = CAST(@DueDate AS DATE)) AND 
	   (ISNULL(@DaysPastDue,'') ='' OR DaysPastDue LIKE '%'+@DaysPastDue+'%') AND  
       (ISNULL(@OriginalTotal,'') ='' OR [OriginalTotal] LIKE '%'+ @OriginalTotal+'%') AND  
       (ISNULL(@RRTotal,'') ='' OR [RRTotal] LIKE '%'+@RRTotal+'%') AND  	   
       (ISNULL(@InvoiceTotal,'') ='' OR [InvoiceTotal] LIKE '%'+ @InvoiceTotal+'%') AND  
       (ISNULL(@VendorName,'') ='' OR [VendorName] LIKE '%'+ @VendorName +'%') AND
	   (ISNULL(@Status,'') ='' OR [Status] LIKE '%'+ @Status +'%') AND
	   (ISNULL(@PaymentHold,'') ='' OR [PaymentHold] LIKE '%' + @PaymentHold + '%') AND
	   (ISNULL(@ReadyToPaymentMade,'') ='' OR ReadyToPaymentMade LIKE '%'+ @ReadyToPaymentMade+'%') AND
	   (ISNULL(@DiscountToken,'') ='' OR DiscountToken LIKE '%'+ @DiscountToken+'%') AND
	   (ISNULL(@DifferenceAmount,'') ='' OR DifferenceAmount LIKE '%'+ @DifferenceAmount+'%') AND
	   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND
	   (ISNULL(@PaymentRef,'') ='' OR PaymentRef LIKE '%'+ @PaymentRef+'%') AND
	   (ISNULL(@CheckCrashed,'') ='' OR CheckCrashed LIKE '%'+ @CheckCrashed+'%'))  
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate, EntryDate, DueDate, DaysPastDue,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems,DiscountToken,ReadyToPaymentMade,BankName,BankAccountNumber,VendorId,ControlNumber FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC, 
	 CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,

     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC, 
	 CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END DESC 

     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END  
    ELSE IF(@CurrentStatus = 'ReadyforSelection')
    BEGIN  
    --;WITH Result AS (  
	-- VendorPayment -ReceivingReconciliation DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [BankName], [BankAccountNumber], 
		[ReadyToPayId], [VendorId], [CreatedDate], [ControlNumber])
		 SELECT DISTINCT 
		        RRH.ReceivingReconciliationId,
				RRH.InvoiceNum,
				--RRH.[Status],
				CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' ELSE 'Ready to Pay' END AS [Status],
				ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
				ISNULL(RRH.RRTotal,0) AS RRTotal,
				ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
				RRH.RemainingAmount AS 'DifferenceAmount',  
				VN.VendorName,
				--ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
				--ISNULL(RRC.IsInvoiceOnHold,0) AS 'PaymentHold',
				CASE WHEN RRC.IsInvoiceOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
				RRH.DueDate AS 'InvociedDate',
				RRH.DueDate AS 'EntryDate',
				--DATEADD(DAY, ctm.NetDays,RRC.InvoiceDate) AS 'DueDate',  
			    --CASE WHEN DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  				
				CASE WHEN IIF(TRY_CAST(RRC.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),RRC.InvoiceDate)
					  ELSE NULL END	AS 'DueDate',
			    CASE WHEN IIF(TRY_CAST(RRC.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
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
				RRH.CreatedDate,
				ISNULL(TAB.ControlNumber,'') AS 'ControlNumber'
		   FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		        INNER JOIN [dbo].[ReceivingReconciliationHeader] RRC WITH(NOLOCK) ON RRH.[ReceivingReconciliationId] = RRC.[ReceivingReconciliationId]	
				INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId  --WHERE StatusId=3
				LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
				OUTER APPLY (SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
							 SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) AS PaymentMethod,
							 MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
							 VRTPDH.ReadyToPayId,
							 VD.ControlNumber
							 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsVoidedCheck = 0
							 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber) AS Tab
		 WHERE RRH.MasterCompanyId = @MasterCompanyId 
		 AND RemainingAmount > 0 
		 --AND RRH.PaymentMade = 0
		 AND ISNULL(RRC.IsInvoiceOnHold,0) = 0 --WHERE StatusId=3 
		 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0
		
		 --UNION ALL
		 -- VendorPayment -CreditMemo DETAILS
		 INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		 [InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [BankName], [BankAccountNumber], 
		 [ReadyToPayId], [VendorId], [CreatedDate],[ControlNumber])
		 SELECT DISTINCT 
		        RRH.ReceivingReconciliationId,
				RRH.InvoiceNum,
				CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' ELSE 'Ready to Pay' END AS [Status],
				ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
				ISNULL(RRH.RRTotal,0) AS RRTotal,
				ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
				RRH.RemainingAmount AS 'DifferenceAmount',  
				VN.VendorName,
				--0 AS 'PaymentHold',
				'NO' AS 'PaymentHold',
				RRH.DueDate AS 'InvociedDate',
				RRH.DueDate AS 'EntryDate',
				CASE WHEN IIF(TRY_CAST(CM.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),CM.InvoiceDate)
					  ELSE NULL END	AS 'DueDate',
			    CASE WHEN IIF(TRY_CAST(CM.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
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
				RRH.CreatedDate,
				ISNULL(TAB.ControlNumber,'') AS 'ControlNumber'
		   FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		        INNER JOIN [dbo].[CreditMemo] CM WITH(NOLOCK) ON RRH.CreditMemoHeaderId = CM.CreditMemoHeaderId
				INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId
				LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
				OUTER APPLY (SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
							 SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) AS PaymentMethod,
							 MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
							 VRTPDH.ReadyToPayId,
							 VD.ControlNumber
							 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsVoidedCheck = 0
							 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber) AS Tab
		 WHERE RRH.MasterCompanyId = @MasterCompanyId 
		 AND RemainingAmount > 0 
		 --AND RRH.PaymentMade = 0
		 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0
		 AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) = 0
		 AND ISNULL(RRH.CreditMemoHeaderId, 0) <> 0

	--UNION ALL
	-- VendorPayment -NonPOInvoice DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [BankName], [BankAccountNumber], 
		[ReadyToPayId], [VendorId], [CreatedDate], [ControlNumber])
		SELECT DISTINCT 
		        RRH.ReceivingReconciliationId,
				RRH.InvoiceNum,
				CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' ELSE 'Ready to Pay' END AS [Status],
				ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
				ISNULL(RRH.RRTotal,0) AS RRTotal,
				ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
				RRH.RemainingAmount AS 'DifferenceAmount',  
				VN.VendorName,
				--0 AS 'PaymentHold',
				'NO' AS 'PaymentHold',
				RRH.DueDate AS 'InvociedDate',
				RRH.DueDate AS 'EntryDate',
				--DATEADD(DAY, ctm.NetDays,NPH.InvoiceDate) AS 'DueDate',  
			    --CASE WHEN DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  
				CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),NPH.InvoiceDate)
					  ELSE NULL END	AS 'DueDate',
			    CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
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
				RRH.CreatedDate,
				ISNULL(TAB.ControlNumber,'') AS 'ControlNumber'
		   FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		        INNER JOIN [dbo].[NonPOInvoiceHeader] NPH WITH(NOLOCK) ON RRH.NonPOInvoiceId = NPH.NonPOInvoiceId
				INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId
				LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
				OUTER APPLY (SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
							 SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) AS PaymentMethod,
							 MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
							 VRTPDH.ReadyToPayId,
							 VD.ControlNumber
							 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsVoidedCheck = 0
							 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber) AS Tab
		 WHERE RRH.MasterCompanyId = @MasterCompanyId 
		 AND RemainingAmount > 0 
		 --AND RRH.PaymentMade = 0
		 AND ISNULL(RRH.NonPOInvoiceId, 0) <> 0
		 AND NPH.StatusId = @NonPOInvoiceHeaderStatusId

		 -- CustomerCreditPayment DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [BankName], [BankAccountNumber], 
		[ReadyToPayId], [VendorId], [CreatedDate], [ControlNumber])
		  SELECT 0 AS ReceivingReconciliationId,
				CCPD.SuspenseUnappliedNumber AS [InvoiceNum],
				'Ready to Pay' [Status],
				ISNULL(CCPD.RemainingAmount,0) AS OriginalTotal,
				0 AS RRTotal,
				0 AS InvoiceTotal,
				0 AS 'DifferenceAmount',  
				V.VendorName as [VendorName],
				--0 AS 'PaymentHold',
				'NO' AS 'PaymentHold',
				CCPD.ProcessedDate AS 'InvociedDate',
				CCPD.ProcessedDate AS 'EntryDate',				
				CASE WHEN IIF(TRY_CAST(CCPD.ProcessedDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),CCPD.ProcessedDate)
					  ELSE NULL END	AS 'DueDate',
				CASE WHEN IIF(TRY_CAST(CCPD.ProcessedDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(CCPD.ProcessedDate AS DATETIME) + ISNULL(CTM.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(CCPD.ProcessedDate AS DATETIME) + ISNULL(CTM.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',				
				'' AS 'PaymentMethod',
				'' AS 'PaymentRef',
				'' AS 'DateProcessed',
				'' AS 'CheckCrashed',
				ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
			    ISNULL(Tab.ReadyToPaymentMade,0) AS 'ReadyToPaymentMade',
				'' AS BankName,
				'' AS BankAccountNumber,
				ISNULL(Tab.ReadyToPayId,0) AS 'ReadyToPayId',
				CCPD.[VendorId] AS [VendorId],
				CCPD.CreatedDate,
				ISNULL(TAB.ControlNumber,'') AS 'ControlNumber'
			FROM [dbo].[CustomerCreditPaymentDetail] CCPD WITH(NOLOCK)  
				LEFT JOIN [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK) ON VPD.[CustomerCreditPaymentDetailId] = CCPD.[CustomerCreditPaymentDetailId]	  
				LEFT JOIN [dbo].[Vendor] V WITH(NOLOCK) ON CCPD.VendorId = V.VendorId  
				LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = V.CreditTermsId  
				LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(CTM.PercentId AS INT) = p.PercentId  
				LEFT JOIN [dbo].[Currency] CU WITH(NOLOCK) ON V.CurrencyId = CU.CurrencyId  
				OUTER APPLY (SELECT VD.VendorPaymentDetailsId,
			                       SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
								   SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
								   MAX(PM.Description) AS PaymentMethod,
								   MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
								   VRTPDH.ReadyToPayId,
								   VD.ControlNumber
							FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							     LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							WHERE ISNULL(VD.[CustomerCreditPaymentDetailId],0) = CCPD.[CustomerCreditPaymentDetailId] AND VD.IsVoidedCheck = 0
			    GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber) AS Tab
	      WHERE CCPD.MasterCompanyId = @MasterCompanyId 
				AND CCPD.IsProcessed = 1 AND CCPD.IsMiscellaneous = 1 AND VPD.RemainingAmount > 0 
    --),  
    ;WITH FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate, DueDate, DaysPastDue,
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,DiscountToken,ReadyToPaymentMade,BankName,BankAccountNumber,ReadyToPayId,VendorId,CreatedDate,ControlNumber FROM #TEMPVendorPaymentListRecords  
    WHERE -- ISNULL(ReadyToPayId,0) = 0 AND 
	   ((@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR   
       ([Status] LIKE '%' +@GlobalFilter+'%') OR  
       (InvociedDate LIKE '%' +@GlobalFilter+'%') OR  
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR
	   (DaysPastDue LIKE '%' +@GlobalFilter+'%') OR  
       (OriginalTotal LIKE '%' +@GlobalFilter+'%') OR  
       (RRTotal LIKE '%'+@GlobalFilter+'%') OR  
       (InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR  
       (VendorName LIKE '%' +@GlobalFilter+'%')  OR
	   (ReadyToPaymentMade LIKE '%' +@GlobalFilter+'%') OR
	   (DiscountToken LIKE '%' +@GlobalFilter+'%') OR
	   (DifferenceAmount LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentMethod LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentRef LIKE '%' +@GlobalFilter+'%') OR
	   (CheckCrashed LIKE '%' +@GlobalFilter+'%')
       ))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND   
       (ISNULL(@InvociedDate,'') ='' OR CAST(InvociedDate AS DATE) = CAST(@InvociedDate AS DATE)) AND  
       (ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS DATE) = CAST(@EntryDate AS DATE)) AND 
	   (ISNULL(@DueDate,'') ='' OR CAST([DueDate] AS DATE) = CAST(@DueDate AS DATE)) AND 
       (ISNULL(@DaysPastDue,'') ='' OR DaysPastDue LIKE '%'+@DaysPastDue+'%') AND
       (ISNULL(@OriginalTotal,'') ='' OR OriginalTotal LIKE '%'+ @OriginalTotal+'%') AND  
       (ISNULL(@RRTotal,'') ='' OR RRTotal LIKE '%'+@RRTotal+'%') AND  
       (ISNULL(@InvoiceTotal,'') ='' OR InvoiceTotal LIKE '%'+ @InvoiceTotal+'%') AND  
       (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%') AND
	   (ISNULL(@Status,'') ='' OR [Status] LIKE '%'+ @Status +'%') AND
	   (ISNULL(@PaymentHold,'') ='' OR PaymentHold LIKE '%' + @PaymentHold + '%') AND
	   (ISNULL(@ReadyToPaymentMade,'') ='' OR ReadyToPaymentMade LIKE '%'+ @ReadyToPaymentMade+'%') AND
	   (ISNULL(@DiscountToken,'') ='' OR DiscountToken LIKE '%'+ @DiscountToken+'%') ANd
	   (ISNULL(@DifferenceAmount,'') ='' OR DifferenceAmount LIKE '%'+ @DifferenceAmount+'%') AND
	   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND
	   (ISNULL(@PaymentRef,'') ='' OR PaymentRef LIKE '%'+ @PaymentRef+'%') AND
	   (ISNULL(@CheckCrashed,'') ='' OR CheckCrashed LIKE '%'+ @CheckCrashed+'%')) 
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate, EntryDate,DueDate, DaysPastDue ,
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems,DiscountToken,ReadyToPaymentMade,BankName,BankAccountNumber,ReadyToPayId,VendorId,ControlNumber  FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC,  
	 CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC,
	 CASE WHEN (@SortOrder= -1 and @SortColumn='STATUS')  THEN Status END DESC
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END  
	ELSE IF(@CurrentStatus = 'CheckRegister')  
    BEGIN  
    --;WITH Result AS (       
	-- VendorPayment DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [BankName], [BankAccountNumber], 
		[ReadyToPayId], [ReadyToPayDetailsId], [VendorId], [CreatedDate])
		SELECT ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   --RRH.[Status],
			   'Selected to be Paid' AS [Status],
			   ISNULL(InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRTotal,0) AS RRTotal,
			   ISNULL(PaymentMade,0) AS InvoiceTotal,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			   --ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
			   CASE WHEN VN.IsVendorOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
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
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RemainingAmount > 0 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0--WHERE StatusId=3  

		-- UNION ALL
		 --VendorPayment -CreditMemo DETAILS
		 INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		 [InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [BankName], [BankAccountNumber], 
		 [ReadyToPayId], [ReadyToPayDetailsId], [VendorId], [CreatedDate])
		 SELECT ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   'Selected to be Paid' AS [Status],
			   ISNULL(InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRTotal,0) AS RRTotal,
			   ISNULL(PaymentMade,0) AS InvoiceTotal,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			   --ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
			   CASE WHEN VN.IsVendorOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
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
               INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId
	           OUTER APPLY (SELECT VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) as PaymentMethod,MAX(VD.CheckNumber) AS PaymentRef,VRTPDH.ReadyToPayId
							 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.CheckNumber IS NULL
							 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RemainingAmount > 0 
		  AND ISNULL(RRH.NonPOInvoiceId, 0) = 0
		  AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) = 0
		  AND ISNULL(RRH.CreditMemoHeaderId, 0) <> 0

	--UNION ALL
	--VendorPayment -NonPOInvoice DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [BankName], [BankAccountNumber], 
		[ReadyToPayId], [ReadyToPayDetailsId], [VendorId], [CreatedDate])
		SELECT ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   'Selected to be Paid' AS [Status],
			   ISNULL(InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRTotal,0) AS RRTotal,
			   ISNULL(PaymentMade,0) AS InvoiceTotal,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			  -- ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
			   CASE WHEN VN.IsVendorOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
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
               INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId
	           OUTER APPLY (SELECT VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) as PaymentMethod,MAX(VD.CheckNumber) AS PaymentRef,VRTPDH.ReadyToPayId
							 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.CheckNumber IS NULL
							 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RemainingAmount > 0 AND ISNULL(RRH.NonPOInvoiceId, 0) <> 0 
    --),  
    ;WITH FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,DiscountToken,ReadyToPaymentMade,BankName,BankAccountNumber,ReadyToPayId,ReadyToPayDetailsId,VendorId,CreatedDate  FROM #TEMPVendorPaymentListRecords  
    WHERE  ISNULL(ReadyToPayId,0) > 0 AND (  
       (@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR   
       ([Status] LIKE '%' +@GlobalFilter+'%') OR  
       (InvociedDate LIKE '%' +@GlobalFilter+'%') OR  
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR
	   
       (OriginalTotal LIKE '%' +@GlobalFilter+'%') OR  
       (RRTotal LIKE '%'+@GlobalFilter+'%') OR  
       (InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR  
       (VendorName LIKE '%' +@GlobalFilter+'%') OR
	   (ReadyToPaymentMade LIKE '%' +@GlobalFilter+'%') OR
	   (DiscountToken LIKE '%' +@GlobalFilter+'%') OR
	   (DifferenceAmount LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentMethod LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentRef LIKE '%' +@GlobalFilter+'%')
       ))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND   
       (ISNULL(@InvociedDate,'') ='' OR CAST(InvociedDate AS DATE) = Cast(@InvociedDate AS DATE)) AND  
       (ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS DATE) = Cast(@EntryDate AS DATE)) AND  
       (ISNULL(@OriginalTotal,'') ='' OR OriginalTotal LIKE '%'+ @OriginalTotal+'%') AND  
       (ISNULL(@RRTotal,'') ='' OR RRTotal LIKE '%'+@RRTotal+'%') AND  
       (ISNULL(@InvoiceTotal,'') ='' OR InvoiceTotal LIKE '%'+ @InvoiceTotal+'%') AND  
       (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%') AND
	   (ISNULL(@Status,'') ='' OR [Status] LIKE '%'+ @Status +'%') AND
	   (ISNULL(@PaymentHold,'') ='' OR PaymentHold LIKE '%' + @PaymentHold + '%') AND
	   (ISNULL(@ReadyToPaymentMade,'') ='' OR ReadyToPaymentMade LIKE '%'+ @ReadyToPaymentMade+'%') AND
	   (ISNULL(@DiscountToken,'') ='' OR DiscountToken LIKE '%'+ @DiscountToken+'%') ANd
	   (ISNULL(@DifferenceAmount,'') ='' OR DifferenceAmount LIKE '%'+ @DifferenceAmount+'%') AND
	   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND
	   (ISNULL(@PaymentRef,'') ='' OR PaymentRef LIKE '%'+ @PaymentRef+'%'))   
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate, EntryDate,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems,DiscountToken,ReadyToPaymentMade,BankName,BankAccountNumber,ReadyToPayId,ReadyToPayDetailsId,VendorId  FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID') THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC, 
	 CASE WHEN (@SortOrder=1 and @SortColumn='STATUS') THEN Status END ASC,
  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS') THEN Status END DESC

     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END  
    ELSE IF(@CurrentStatus = 'PartiallyPaid')  
    BEGIN  
    --;WITH Result AS (  
	--VendorPayment -ReceivingReconciliation DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPaymentMade],
		[ReadyToPayId], [ReadyToPayDetailsId], [IsVoidedCheck], [VendorId], [PaymentMethodId], [CreatedDate], [ControlNumber])
		SELECT RRH.ReceivingReconciliationId,
			   RRH.InvoiceNum,
			   --RRH.[Status],
			   'Partially Paid' AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
			   ISNULL(RemainingAmount,0) AS 'DifferenceAmount',  
			   VN.VendorName,
			   --ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
			   --ISNULL(RRC.IsInvoiceOnHold,0) AS 'PaymentHold',
			   CASE WHEN RRC.IsInvoiceOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
			   RRH.DueDate AS 'InvociedDate',
			   RRH.DueDate AS 'EntryDate',
			   CASE WHEN IIF(TRY_CAST(RRC.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),RRC.InvoiceDate)
					  ELSE NULL END	AS 'DueDate',
			   CASE WHEN IIF(TRY_CAST(RRC.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
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
			   tab.CreatedDate,
			   ISNULL(TAB.ControlNumber,'') AS 'ControlNumber'
		  FROM [dbo].[VendorPaymentDetails] RRH WITH(NOLOCK) 
			   INNER JOIN [dbo].[ReceivingReconciliationHeader] RRC WITH(NOLOCK) ON RRH.[ReceivingReconciliationId] = RRC.[ReceivingReconciliationId]	
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId 
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   OUTER APPLY (SELECT VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0)) ReadyToPaymentMade,
							SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
							MAX(PM.Description) AS PaymentMethod,CASE WHEN VD.IsVoidedCheck =1 THEN MAX(VD.CheckNumber) + ' (V)' ELSE MAX(VD.CheckNumber) END PaymentRef,VRTPDH.ReadyToPayId,VD.IsVoidedCheck,
							VD.PaymentMethodId,
							SRT.CreatedDate,
							VD.ControlNumber
		                    FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
				OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VD.ReadyToPayId =  SS.ReadyToPayId AND  VD.VendorId = SS.VendorId AND  VD.PaymentMethodId = SS.PaymentMethodId) AS SRT
		  WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.CheckNumber IS NOT NULL AND IsVoidedCheck = 0
			GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate,VD.ControlNumber) AS Tab
		  WHERE RRH.MasterCompanyId = @MasterCompanyId 
		  AND RRH.PaymentMade > 0 
		  AND RRH.RemainingAmount > 0 
		  AND ISNULL(RRH.NonPOInvoiceId, 0) = 0--WHERE StatusId=3  

	--UNION ALL
	--VendorPayment -NonPOInvoice DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPaymentMade],
		[ReadyToPayId], [ReadyToPayDetailsId], [IsVoidedCheck], [VendorId], [PaymentMethodId], [CreatedDate],[ControlNumber])
		SELECT RRH.ReceivingReconciliationId,
			   RRH.InvoiceNum,
			   'Partially Paid' AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
			   ISNULL(RemainingAmount,0) AS 'DifferenceAmount',  
			   VN.VendorName,
			   --0 AS 'PaymentHold',
			   'NO' AS 'PaymentHold',
			   RRH.DueDate AS 'InvociedDate',
			   RRH.DueDate AS 'EntryDate',
			   CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),NPH.InvoiceDate)
					  ELSE NULL END	AS 'DueDate',
			    CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
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
			   tab.CreatedDate,
			   ISNULL(TAB.ControlNumber,'') AS 'ControlNumber'
		  FROM [dbo].[VendorPaymentDetails] RRH WITH(NOLOCK) 
			   INNER JOIN [dbo].[NonPOInvoiceHeader] NPH WITH(NOLOCK) ON RRH.NonPOInvoiceId = NPH.NonPOInvoiceId		
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId 
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   OUTER APPLY (SELECT VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0)) ReadyToPaymentMade,
							SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
							MAX(PM.Description) AS PaymentMethod,CASE WHEN VD.IsVoidedCheck =1 THEN MAX(VD.CheckNumber) + ' (V)' ELSE MAX(VD.CheckNumber) END PaymentRef,
							VRTPDH.ReadyToPayId,VD.IsVoidedCheck,
							VD.PaymentMethodId,
							SRT.CreatedDate,
							VD.ControlNumber
		                    FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
				OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VD.ReadyToPayId =  SS.ReadyToPayId AND  VD.VendorId = SS.VendorId AND  VD.PaymentMethodId = SS.PaymentMethodId) AS SRT
		  WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.CheckNumber IS NOT NULL AND IsVoidedCheck = 0
			GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate,VD.ControlNumber) AS Tab
		  WHERE RRH.MasterCompanyId = @MasterCompanyId 
		  AND RRH.PaymentMade > 0 
		  AND RRH.RemainingAmount > 0 
		  AND ISNULL(RRH.NonPOInvoiceId, 0) <> 0
		  AND NPH.StatusId = @NonPOInvoiceHeaderStatusId

		--VendorPayment -CustomerCreditPayment DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPaymentMade],
		[ReadyToPayId], [ReadyToPayDetailsId], [IsVoidedCheck], [VendorId], [PaymentMethodId], [CreatedDate], [ControlNumber])
		SELECT VPD.ReceivingReconciliationId,
			   VPD.InvoiceNum,
			   'Partially Paid' AS [Status],
			   ISNULL(VPD.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(VPD.RRTotal,0) AS RRTotal,
			   ISNULL(VPD.PaymentMade,0) AS InvoiceTotal,
			   ISNULL(VPD.RemainingAmount,0) AS 'DifferenceAmount',  
			   VN.VendorName,
			   --0 AS 'PaymentHold',
			   'NO' AS 'PaymentHold',
			   VPD.DueDate AS 'InvociedDate',
			   VPD.DueDate AS 'EntryDate',
			   CASE WHEN IIF(TRY_CAST(CCPD.ProcessedDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),CCPD.ProcessedDate)
					  ELSE NULL END	AS 'DueDate',
			    CASE WHEN IIF(TRY_CAST(CCPD.ProcessedDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(CCPD.ProcessedDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(CCPD.ProcessedDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
			   ISNULL(Tab.PaymentMethod,'') AS 'PaymentMethod',
			   ISNULL(Tab.PaymentRef,'') AS 'PaymentRef',
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   ISNULL(VPD.DiscountToken,0) AS 'DiscountToken',  
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   ISNULL(Tab.ReadyToPaymentMade,0) AS 'ReadyToPaymentMade',
			   Tab.ReadyToPayId,
			   Tab.ReadyToPayDetailsId,
			   Tab.IsVoidedCheck,
			   VPD.VendorId,
			   tab.PaymentMethodId,
			   tab.CreatedDate,
			   ISNULL(TAB.ControlNumber,'') AS 'ControlNumber'
		  FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK) 
			   INNER JOIN [dbo].[CustomerCreditPaymentDetail] CCPD WITH(NOLOCK) ON VPD.CustomerCreditPaymentDetailId = CCPD.CustomerCreditPaymentDetailId		
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VPD.VendorId = VN.VendorId 
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   OUTER APPLY (SELECT VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0)) ReadyToPaymentMade,
							SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
							MAX(PM.Description) AS PaymentMethod,CASE WHEN VD.IsVoidedCheck =1 THEN MAX(VD.CheckNumber) + ' (V)' ELSE MAX(VD.CheckNumber) END PaymentRef,
							VRTPDH.ReadyToPayId,
							VD.IsVoidedCheck,VD.PaymentMethodId,
							SRT.CreatedDate,
							VD.ControlNumber
		                    FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
				OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VD.ReadyToPayId =  SS.ReadyToPayId AND  VD.VendorId = SS.VendorId AND  VD.PaymentMethodId = SS.PaymentMethodId) AS SRT
		  WHERE ISNULL(VD.VendorPaymentDetailsId,0) = VPD.VendorPaymentDetailsId AND VD.CheckNumber IS NOT NULL AND IsVoidedCheck = 0
			GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate,VD.ControlNumber) AS Tab
		  WHERE VPD.MasterCompanyId = @MasterCompanyId 
		  AND VPD.PaymentMade > 0 
		  AND VPD.RemainingAmount > 0 
		  AND ISNULL(VPD.NonPOInvoiceId, 0) = 0
		  AND ISNULL(VPD.CustomerCreditPaymentDetailId, 0) <> 0

    --),  
    ;WITH FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate,ReadyToPaymentMade,DueDate,DaysPastDue,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,DiscountToken,BankName,BankAccountNumber,ReadyToPayId,ReadyToPayDetailsId,IsVoidedCheck,VendorId,PaymentMethodId,CreatedDate,ControlNumber FROM #TEMPVendorPaymentListRecords  
    WHERE (  
	   (@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR   
       ([Status] LIKE '%' +@GlobalFilter+'%') OR  
       (InvociedDate LIKE '%' +@GlobalFilter+'%') OR  
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR  
	   (DaysPastDue LIKE '%' +@GlobalFilter+'%') OR  
       (OriginalTotal LIKE '%' +@GlobalFilter+'%') OR  
       (RRTotal LIKE '%'+@GlobalFilter+'%') OR  
       (InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR	
       (VendorName LIKE '%' +@GlobalFilter+'%') OR
	   (ReadyToPaymentMade LIKE '%' +@GlobalFilter+'%') OR
	   (DiscountToken LIKE '%' +@GlobalFilter+'%') OR
	   (DifferenceAmount LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentMethod LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentRef LIKE '%' +@GlobalFilter+'%')
       ))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND   
       (ISNULL(@InvociedDate,'') ='' OR CAST(InvociedDate AS DATE) = CAST(@InvociedDate AS DATE)) AND  
       (ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS DATE) = CAST(@EntryDate AS DATE)) AND 
	   (ISNULL(@DueDate,'') ='' OR CAST([DueDate] AS DATE) = CAST(@DueDate AS DATE)) AND 
       (ISNULL(@DaysPastDue,'') ='' OR DaysPastDue LIKE '%'+@DaysPastDue+'%') AND  
       (ISNULL(@OriginalTotal,'') ='' OR OriginalTotal LIKE '%'+ @OriginalTotal+'%') AND  
       (ISNULL(@RRTotal,'') ='' OR RRTotal LIKE '%'+@RRTotal+'%') AND  
       (ISNULL(@InvoiceTotal,'') ='' OR InvoiceTotal LIKE '%'+ @InvoiceTotal+'%') AND  
       (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%') AND
	   (ISNULL(@Status,'') ='' OR [Status] LIKE '%'+ @Status +'%') AND
	   (ISNULL(@PaymentHold,'') ='' OR PaymentHold LIKE '%' + @PaymentHold + '%') AND
	   (ISNULL(@ReadyToPaymentMade,'') ='' OR ReadyToPaymentMade LIKE '%'+ @ReadyToPaymentMade+'%') AND
	   (ISNULL(@DiscountToken,'') ='' OR DiscountToken LIKE '%'+ @DiscountToken+'%') AND
	   (ISNULL(@DifferenceAmount,'') ='' OR DifferenceAmount LIKE '%'+ @DifferenceAmount+'%') AND
	   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND
	   (ISNULL(@PaymentRef,'') ='' OR PaymentRef LIKE '%'+ @PaymentRef+'%'))   
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate, EntryDate,ReadyToPaymentMade,DueDate,DaysPastDue, 
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems,DiscountToken,BankName,BankAccountNumber,ReadyToPayId,ReadyToPayDetailsId,IsVoidedCheck,VendorId,PaymentMethodId,CreatedDate,ControlNumber FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC,  
	 CASE WHEN (@SortOrder=1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC,  
	 CASE WHEN (@SortOrder=1 and @SortColumn='STATUS') THEN Status END ASC,
  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
	CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS') THEN Status END DESC
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END 
	ELSE IF(@CurrentStatus = 'PrintCheck')  
    BEGIN  
    --;With Result AS (  
	--VendorPayment -ReceivingReconciliation DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorId], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPayId], [IsVoidedCheck], [PaymentMethodId], [CreatedDate], [ReadyToPayDetailsId],[ControlNumber])
		SELECT 0 AS ReceivingReconciliationId,
		CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS InvoiceNum,
		--RRH.[Status],
		CASE WHEN ISNULL(VRTPD.AmountDue,0) > 0 THEN 'Partially Paid' 
			   ELSE 'Full Payment' END AS [Status],
		0 AS OriginalTotal,
		0 AS RRTotal,
		SUM(ISNULL(VRTPD.PaymentMade,0)) AS InvoiceTotal,
		0 AS 'DifferenceAmount',  
		VRTPD.VendorId,
		VN.VendorName,
		--ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
		CASE WHEN VN.IsVendorOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
		CheckDate AS 'InvociedDate',
		CheckDate AS 'EntryDate',		
		'' AS 'PaymentMethod',
		CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS 'PaymentRef',
		'' AS 'DateProcessed',
		'' AS 'CheckCrashed',
		0 AS 'DiscountToken',
		lebl.BankName, 		
		CASE WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber + ' (V)' 			  
			  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber 
		      ELSE ''  
		END AS 'BankAccountNumber'
		,VRTPDH.ReadyToPayId
		,VRTPD.IsVoidedCheck
		,VRTPD.PaymentMethodId
		,SRT.CreatedDate
		,VRTPD.ReadyToPayDetailsId
		,VRTPD.ControlNumber
		FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
		INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
		 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.ReceivingReconciliationId = RRH.ReceivingReconciliationId
		 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		 LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRTPDH.BankId		
		 LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId
		 OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VRTPD.ReadyToPayId =  SS.ReadyToPayId AND  VRTPD.VendorId = SS.VendorId AND  VRTPD.PaymentMethodId = SS.PaymentMethodId) AS SRT
	  WHERE RRH.MasterCompanyId = @MasterCompanyId 
	     AND VRTPD.PaymentMethodId = @Check
		 AND ISNULL(VRTPD.IsCheckPrinted,0) = 0
		 AND ISNULL(VRTPD.IsGenerated,0) = 1
		 AND RRH.StatusId IN(SELECT Item FROM dbo.SplitString(@StatusId, ','))
	     --AND (RemainingAmount <= 0  OR IsVoidedCheck = 1) 
		 AND ISNULL(VRTPD.CreditMemoHeaderId, 0) = 0 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0	AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) = 0	
		GROUP BY VRTPD.CheckNumber,lebl.BankName,lebl.BankAccountNumber,VRTPDH.ReadyToPayId,
				 RRH.[Status],VN.IsVendorOnHold,CheckDate,VN.VendorName,IsVoidedCheck,
				 VRTPD.VendorId,VRTPD.PaymentMethodId,SRT.CreatedDate,VRTPD.ReadyToPayDetailsId,VRTPD.AmountDue,VRTPD.ControlNumber
				
		-- UNION ALL
		--VendorPayment -CreditMemo DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorId], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPayId], [IsVoidedCheck], [PaymentMethodId], [CreatedDate], [ReadyToPayDetailsId], [ControlNumber])
		SELECT 0 AS ReceivingReconciliationId,
		CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS InvoiceNum,
		CASE WHEN ISNULL(VRTPD.AmountDue,0) > 0 THEN 'Partially Paid' 
			   ELSE 'Full Payment' END AS [Status],
		0 AS OriginalTotal,
		0 AS RRTotal,
		SUM(ISNULL(VRTPD.PaymentMade,0)) AS InvoiceTotal,
		0 AS 'DifferenceAmount',  
		VRTPD.VendorId,
		VN.VendorName,
		--ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',	
		CASE WHEN VN.IsVendorOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
		CheckDate AS 'InvociedDate',
		CheckDate AS 'EntryDate',		
		'' AS 'PaymentMethod',
		CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS 'PaymentRef',
		'' AS 'DateProcessed',
		'' AS 'CheckCrashed',
		0 AS 'DiscountToken',
		lebl.BankName, 		
		CASE WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber + ' (V)' 			  
			  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber 
		      ELSE ''  
		END AS 'BankAccountNumber'
		,VRTPDH.ReadyToPayId
		,VRTPD.IsVoidedCheck
		,VRTPD.PaymentMethodId
		,SRT.CreatedDate
		,VRTPD.ReadyToPayDetailsId
		,VRTPD.ControlNumber
		FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
		INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
		 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.CreditMemoHeaderId = RRH.CreditMemoHeaderId
		 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		 LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRTPDH.BankId		
		 LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId
		 OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VRTPD.ReadyToPayId =  SS.ReadyToPayId AND  VRTPD.VendorId = SS.VendorId AND  VRTPD.PaymentMethodId = SS.PaymentMethodId) AS SRT
	  WHERE RRH.MasterCompanyId = @MasterCompanyId 
	     AND VRTPD.PaymentMethodId = @Check
		 AND ISNULL(VRTPD.IsCheckPrinted,0) = 0
		 AND ISNULL(VRTPD.IsGenerated,0) = 1
		  AND RRH.StatusId IN(SELECT Item FROM dbo.SplitString(@StatusId, ','))
	     --AND (RemainingAmount <= 0  OR IsVoidedCheck = 1) 
		 AND ISNULL(VRTPD.CreditMemoHeaderId, 0) <> 0 AND ISNULL(RRH.CreditMemoHeaderId, 0) <> 0 
		 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0 AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) = 0		
		GROUP BY VRTPD.CheckNumber,lebl.BankName,lebl.BankAccountNumber,VRTPDH.ReadyToPayId,
				 RRH.[Status],VN.IsVendorOnHold,CheckDate,VN.VendorName,IsVoidedCheck,
				 VRTPD.VendorId,VRTPD.PaymentMethodId,SRT.CreatedDate,VRTPD.ReadyToPayDetailsId,VRTPD.AmountDue,VRTPD.ControlNumber

	 --UNION ALL
	 --VendorPayment -NonPO DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorId], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPayId], [IsVoidedCheck], [PaymentMethodId], [CreatedDate], [ReadyToPayDetailsId], [ControlNumber])
		SELECT 0 AS ReceivingReconciliationId,
		CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS InvoiceNum,
		CASE WHEN ISNULL(VRTPD.AmountDue,0) > 0 THEN 'Partially Paid' 
			   ELSE 'Full Payment' END AS [Status],
		0 AS OriginalTotal,
		0 AS RRTotal,
		SUM(ISNULL(VRTPD.PaymentMade,0)) AS InvoiceTotal,
		0 AS 'DifferenceAmount',  
		VRTPD.VendorId,
		VN.VendorName,
		--ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',	
		CASE WHEN VN.IsVendorOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
		CheckDate AS 'InvociedDate',
		CheckDate AS 'EntryDate',		
		'' AS 'PaymentMethod',
		CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS 'PaymentRef',
		'' AS 'DateProcessed',
		'' AS 'CheckCrashed',
		0 AS 'DiscountToken',
		lebl.BankName, 		
		CASE WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber + ' (V)' 			  
			  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber 
		      ELSE ''  
		END AS 'BankAccountNumber'
		,VRTPDH.ReadyToPayId
		,VRTPD.IsVoidedCheck
		,VRTPD.PaymentMethodId
		,SRT.CreatedDate
		,VRTPD.ReadyToPayDetailsId
		,VRTPD.ControlNumber
		FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
		INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
		 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.NonPOInvoiceId = RRH.NonPOInvoiceId
		 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		 LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRTPDH.BankId		
		 LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId
		 OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VRTPD.ReadyToPayId =  SS.ReadyToPayId AND  VRTPD.VendorId = SS.VendorId AND  VRTPD.PaymentMethodId = SS.PaymentMethodId) AS SRT
	  WHERE RRH.MasterCompanyId = @MasterCompanyId 
	     AND VRTPD.PaymentMethodId = @Check
		 AND ISNULL(VRTPD.IsCheckPrinted,0) = 0
		 AND ISNULL(VRTPD.IsGenerated,0) = 1
		AND RRH.StatusId IN(SELECT Item FROM dbo.SplitString(@StatusId, ','))
	     --AND (RemainingAmount <= 0  OR IsVoidedCheck = 1) 
		 AND ISNULL(VRTPD.CreditMemoHeaderId, 0) = 0 AND ISNULL(RRH.NonPOInvoiceId, 0) <> 0 AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) = 0		
		GROUP BY VRTPD.CheckNumber,lebl.BankName,lebl.BankAccountNumber,VRTPDH.ReadyToPayId,
				 RRH.[Status],VN.IsVendorOnHold,CheckDate,VN.VendorName,IsVoidedCheck,
				 VRTPD.VendorId,VRTPD.PaymentMethodId,SRT.CreatedDate,VRTPD.ReadyToPayDetailsId,VRTPD.AmountDue,VRTPD.ControlNumber

		--VendorPayment -CustomerCreditPayment DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorId], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPayId], [IsVoidedCheck], [PaymentMethodId], [CreatedDate], [ReadyToPayDetailsId], [ControlNumber])
		SELECT 0 AS ReceivingReconciliationId,
		CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS InvoiceNum,
		CASE WHEN ISNULL(VRTPD.AmountDue,0) > 0 THEN 'Partially Paid' 
			   ELSE 'Full Payment' END AS [Status],
		0 AS OriginalTotal,
		0 AS RRTotal,
		SUM(ISNULL(VRTPD.PaymentMade,0)) AS InvoiceTotal,
		0 AS 'DifferenceAmount',  
		VRTPD.VendorId,
		VN.VendorName,
		--ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',		
		CASE WHEN VN.IsVendorOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
		CheckDate AS 'InvociedDate',
		CheckDate AS 'EntryDate',		
		'' AS 'PaymentMethod',
		CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS 'PaymentRef',
		'' AS 'DateProcessed',
		'' AS 'CheckCrashed',
		0 AS 'DiscountToken',
		lebl.BankName, 		
		CASE WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber + ' (V)' 			  
			  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber 
		      ELSE ''  
		END AS 'BankAccountNumber'
		,VRTPDH.ReadyToPayId
		,VRTPD.IsVoidedCheck
		,VRTPD.PaymentMethodId
		,SRT.CreatedDate
		,VRTPD.ReadyToPayDetailsId
		,VRTPD.ControlNumber
		FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
		INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
		 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.CustomerCreditPaymentDetailId = RRH.CustomerCreditPaymentDetailId
		 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		 LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRTPDH.BankId		
		 LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId
		 OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VRTPD.ReadyToPayId =  SS.ReadyToPayId AND  VRTPD.VendorId = SS.VendorId AND  VRTPD.PaymentMethodId = SS.PaymentMethodId) AS SRT
	  WHERE RRH.MasterCompanyId = @MasterCompanyId 
	     AND VRTPD.PaymentMethodId = @Check
		 AND ISNULL(VRTPD.IsCheckPrinted,0) = 0
		 AND ISNULL(VRTPD.IsGenerated,0) = 1
		 AND RRH.StatusId IN(SELECT Item FROM dbo.SplitString(@StatusId, ','))
	     --AND (RemainingAmount <= 0  OR IsVoidedCheck = 1) 
		 AND ISNULL(VRTPD.CreditMemoHeaderId, 0) = 0 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0 AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) <> 0			
		GROUP BY VRTPD.CheckNumber,lebl.BankName,lebl.BankAccountNumber,VRTPDH.ReadyToPayId,
				 RRH.[Status],VN.IsVendorOnHold,CheckDate,VN.VendorName,IsVoidedCheck,
				 VRTPD.VendorId,VRTPD.PaymentMethodId,SRT.CreatedDate,VRTPD.ReadyToPayDetailsId,VRTPD.AmountDue,VRTPD.ControlNumber
	--),  
    ;WITH FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate,DiscountToken,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,BankName,BankAccountNumber,ReadyToPayId,IsVoidedCheck,VendorId,PaymentMethodId,CreatedDate,ReadyToPayDetailsId,ControlNumber FROM #TEMPVendorPaymentListRecords  
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
       (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%') AND
	   (ISNULL(@Status,'') ='' OR [Status] LIKE '%'+ @Status +'%') AND
	   (ISNULL(@PaymentHold,'') ='' OR PaymentHold LIKE '%' + @PaymentHold + '%'))     
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate, EntryDate,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems,DiscountToken,BankName,BankAccountNumber,ReadyToPayId,IsVoidedCheck,VendorId,PaymentMethodId,CreatedDate,ReadyToPayDetailsId,ControlNumber FROM FinalResult, ResultCount  
  
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
    ELSE IF(@CurrentStatus = 'PaidinFull')  
    BEGIN  
    --;With Result AS (  
	--VendorPayment DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorId], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPayId], [IsVoidedCheck], [PaymentMethodId], [CreatedDate], [ReadyToPayDetailsId],[ControlNumber])
		SELECT 0 AS ReceivingReconciliationId,
		CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS InvoiceNum,
		CASE WHEN ISNULL(VRTPD.AmountDue,0) > 0 THEN 'Partially Paid' 
			   ELSE 'Full Payment' END AS [Status],
		0 AS OriginalTotal,
		0 AS RRTotal,
		SUM(ISNULL(VRTPD.PaymentMade,0)) AS InvoiceTotal,
		0 AS 'DifferenceAmount',  
		VRTPD.VendorId,
		VN.VendorName,
		--ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',		
		CASE WHEN VN.IsVendorOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
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
		,VRTPD.PaymentMethodId
		,SRT.CreatedDate
		,VRTPD.ReadyToPayDetailsId
		,VRTPD.ControlNumber
		FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
		INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
		LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.VendorPaymentDetailsId = RRH.VendorPaymentDetailsId
		-- LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.ReceivingReconciliationId = RRH.ReceivingReconciliationId
		 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		 LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRTPDH.BankId
		 LEFT JOIN [dbo].[VendorDomesticWirePayment] VDWP WITH(NOLOCK) ON VDWP.VendorId = VRTPD.VendorId
		 LEFT JOIN [dbo].[DomesticWirePayment] DWPL WITH(NOLOCK) ON DWPL.DomesticWirePaymentId = VDWP.DomesticWirePaymentId
		 LEFT JOIN [dbo].[VendorInternationlWirePayment] VIWP WITH(NOLOCK) ON VIWP.VendorId = VRTPD.VendorId
		 LEFT JOIN [dbo].[InternationalWirePayment] IWPL WITH(NOLOCK) ON IWPL.InternationalWirePaymentId = VIWP.InternationalWirePaymentId
		 LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId
		 OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VRTPD.ReadyToPayId =  SS.ReadyToPayId AND VRTPD.VendorPaymentDetailsId = SS.VendorPaymentDetailsId AND  VRTPD.VendorId = SS.VendorId AND  VRTPD.PaymentMethodId = SS.PaymentMethodId) AS SRT
	  WHERE RRH.MasterCompanyId = @MasterCompanyId 
	     --AND (RemainingAmount <= 0  OR IsVoidedCheck = 1) 
		-- AND (RemainingAmount <= 0  OR IsVoidedCheck = 1) 
		AND (RRH.PaymentMade > 0  OR IsVoidedCheck = 1)
		 --AND ISNULL(VRTPD.CreditMemoHeaderId, 0) = 0	
		 AND ISNULL(VRTPD.IsGenerated,0) = 1
		-- AND ISNULL(RRH.NonPOInvoiceId, 0) = 0	
		 -- AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) = 0
		 AND (CASE WHEN VRTPD.PaymentMethodId = @Check THEN CASE WHEN VRTPD.IsCheckPrinted = 1 THEN VRTPD.IsCheckPrinted END END = 1 OR  VRTPD.PaymentMethodId <> @Check )

		 GROUP BY VRTPD.CheckNumber,lebl.BankName,lebl.BankAccountNumber,DWPL.AccountNumber,
		          IWPL.BeneficiaryBankAccount, VRTPDH.ReadyToPayId,VRTPD.AmountDue,VN.IsVendorOnHold,
		          CheckDate,VN.VendorName,IsVoidedCheck,VRTPD.VendorId,VRTPD.PaymentMethodId,SRT.CreatedDate,
				  DWPL.BankName,IWPL.BeneficiaryBank,VRTPD.ReadyToPayDetailsId,VRTPD.ControlNumber	 

		-- UNION ALL
		--VendorPayment -CreditMemo DETAILS
		--INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorId], [VendorName], [PaymentHold],
		--[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPayId], [IsVoidedCheck], [PaymentMethodId], [CreatedDate], [ReadyToPayDetailsId])
		--SELECT 0 AS ReceivingReconciliationId,
		--CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS InvoiceNum,
		--RRH.[Status],
		--0 AS OriginalTotal,
		--0 AS RRTotal,
		--SUM(ISNULL(VRTPD.PaymentMade,0)) AS InvoiceTotal,
		--0 AS 'DifferenceAmount',  
		--VRTPD.VendorId,
		--VN.VendorName,
		----ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',	
		--CASE WHEN VN.IsVendorOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
		--CheckDate AS 'InvociedDate',
		--CheckDate AS 'EntryDate',		
		--'' AS 'PaymentMethod',
		--CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS 'PaymentRef',
		--'' AS 'DateProcessed',
		--'' AS 'CheckCrashed',
		--0 AS 'DiscountToken'
		--,CASE WHEN VRTPD.PaymentMethodId = @Check THEN lebl.BankName 
		--      WHEN VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.BankName 
		--	  WHEN VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBank 
		--	  WHEN VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.BankName 
		--	  WHEN VRTPD.PaymentMethodId = @CreditCard THEN '' END AS BankName
		--,CASE WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber + ' (V)' 
		--	  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.AccountNumber + ' (V)' 
		--	  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBankAccount + ' (V)' 
		--	  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.AccountNumber + ' (V)' 
		--	  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @CreditCard THEN '' 
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber 
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.AccountNumber 
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBankAccount 
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.AccountNumber
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @CreditCard THEN '' END AS 'BankAccountNumber'
		--,VRTPDH.ReadyToPayId
		--,VRTPD.IsVoidedCheck
		--,VRTPD.PaymentMethodId
		--,SRT.CreatedDate
		--,VRTPD.ReadyToPayDetailsId
		--FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
		--INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
		-- LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.CreditMemoHeaderId = RRH.CreditMemoHeaderId
		-- LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		-- LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRTPDH.BankId
		-- LEFT JOIN [dbo].[VendorDomesticWirePayment] VDWP WITH(NOLOCK) ON VDWP.VendorId = VRTPD.VendorId
		-- LEFT JOIN [dbo].[DomesticWirePayment] DWPL WITH(NOLOCK) ON DWPL.DomesticWirePaymentId = VDWP.DomesticWirePaymentId
		-- LEFT JOIN [dbo].[VendorInternationlWirePayment] VIWP WITH(NOLOCK) ON VIWP.VendorId = VRTPD.VendorId
		-- LEFT JOIN [dbo].[InternationalWirePayment] IWPL WITH(NOLOCK) ON IWPL.InternationalWirePaymentId = VIWP.InternationalWirePaymentId
		-- LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId
		-- OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VRTPD.ReadyToPayId =  SS.ReadyToPayId AND  VRTPD.VendorId = SS.VendorId AND  VRTPD.PaymentMethodId = SS.PaymentMethodId) AS SRT
	 -- WHERE RRH.MasterCompanyId = @MasterCompanyId 
	 --    AND (RemainingAmount <= 0  OR IsVoidedCheck = 1) 
		-- AND ISNULL(VRTPD.CreditMemoHeaderId, 0) <> 0	
		-- AND ISNULL(RRH.NonPOInvoiceId, 0) = 0	
		-- AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) = 0
		-- AND ISNULL(RRH.CreditMemoHeaderId, 0) <> 0
		-- AND (CASE WHEN VRTPD.PaymentMethodId = @Check THEN CASE WHEN VRTPD.IsCheckPrinted = 1 THEN VRTPD.IsCheckPrinted END END = 1 OR  VRTPD.PaymentMethodId <> @Check )

		-- GROUP BY VRTPD.CheckNumber,lebl.BankName,lebl.BankAccountNumber,DWPL.AccountNumber,
		--          IWPL.BeneficiaryBankAccount, VRTPDH.ReadyToPayId,RRH.[Status],VN.IsVendorOnHold,
		--          CheckDate,VN.VendorName,IsVoidedCheck,VRTPD.VendorId,VRTPD.PaymentMethodId,SRT.CreatedDate,
		--		  DWPL.BankName,IWPL.BeneficiaryBank,ReadyToPayDetailsId 	 		 

	--UNION ALL
		--VendorPayment -NonPO DETAILS
		--INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorId], [VendorName], [PaymentHold],
		--[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPayId], [IsVoidedCheck], [PaymentMethodId], [CreatedDate], [ReadyToPayDetailsId])
		--SELECT 0 AS ReceivingReconciliationId,
		--CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS InvoiceNum,
		--RRH.[Status],
		--0 AS OriginalTotal,
		--0 AS RRTotal,
		--SUM(ISNULL(VRTPD.PaymentMade,0)) AS InvoiceTotal,
		--0 AS 'DifferenceAmount',  
		--VRTPD.VendorId,
		--VN.VendorName,
		----ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',		
		--CASE WHEN VN.IsVendorOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
		--CheckDate AS 'InvociedDate',
		--CheckDate AS 'EntryDate',		
		--'' AS 'PaymentMethod',
		--CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS 'PaymentRef',
		--'' AS 'DateProcessed',
		--'' AS 'CheckCrashed',
		--0 AS 'DiscountToken'
		--,CASE WHEN VRTPD.PaymentMethodId = @Check THEN lebl.BankName 
		--      WHEN VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.BankName 
		--	  WHEN VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBank 
		--	  WHEN VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.BankName 
		--	  WHEN VRTPD.PaymentMethodId = @CreditCard THEN '' END AS BankName
		--,CASE WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber + ' (V)' 
		--	  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.AccountNumber + ' (V)' 
		--	  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBankAccount + ' (V)' 
		--	  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.AccountNumber + ' (V)' 
		--	  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @CreditCard THEN '' 
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber 
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.AccountNumber 
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBankAccount 
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.AccountNumber
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @CreditCard THEN '' END AS 'BankAccountNumber'
		--,VRTPDH.ReadyToPayId
		--,VRTPD.IsVoidedCheck
		--,VRTPD.PaymentMethodId
		--,SRT.CreatedDate
		--,VRTPD.ReadyToPayDetailsId
		--FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
		--INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
		-- LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.NonPOInvoiceId = RRH.NonPOInvoiceId
		-- LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		-- LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRTPDH.BankId
		-- LEFT JOIN [dbo].[VendorDomesticWirePayment] VDWP WITH(NOLOCK) ON VDWP.VendorId = VRTPD.VendorId
		-- LEFT JOIN [dbo].[DomesticWirePayment] DWPL WITH(NOLOCK) ON DWPL.DomesticWirePaymentId = VDWP.DomesticWirePaymentId
		-- LEFT JOIN [dbo].[VendorInternationlWirePayment] VIWP WITH(NOLOCK) ON VIWP.VendorId = VRTPD.VendorId
		-- LEFT JOIN [dbo].[InternationalWirePayment] IWPL WITH(NOLOCK) ON IWPL.InternationalWirePaymentId = VIWP.InternationalWirePaymentId
		-- LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId
		-- OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VRTPD.ReadyToPayId =  SS.ReadyToPayId AND  VRTPD.VendorId = SS.VendorId AND  VRTPD.PaymentMethodId = SS.PaymentMethodId) AS SRT
	 -- WHERE RRH.MasterCompanyId = @MasterCompanyId 
	 --    AND (RemainingAmount <= 0  OR IsVoidedCheck = 1) 
		-- AND ISNULL(VRTPD.CreditMemoHeaderId, 0) = 0	
		-- AND ISNULL(RRH.NonPOInvoiceId, 0) <> 0	
		-- AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) = 0
		-- AND (CASE WHEN VRTPD.PaymentMethodId = @Check THEN CASE WHEN VRTPD.IsCheckPrinted = 1 THEN VRTPD.IsCheckPrinted END END = 1 OR  VRTPD.PaymentMethodId <> @Check )

		-- GROUP BY VRTPD.CheckNumber,lebl.BankName,lebl.BankAccountNumber,DWPL.AccountNumber,
		--          IWPL.BeneficiaryBankAccount, VRTPDH.ReadyToPayId,RRH.[Status],VN.IsVendorOnHold,
		--          CheckDate,VN.VendorName,IsVoidedCheck,VRTPD.VendorId,VRTPD.PaymentMethodId,SRT.CreatedDate,
		--		  DWPL.BankName,IWPL.BeneficiaryBank,VRTPD.ReadyToPayDetailsId	 

		--VendorPayment -CustomerCreditPayment DETAILS
		--INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorId], [VendorName], [PaymentHold],
		--[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPayId], [IsVoidedCheck], [PaymentMethodId], [CreatedDate], [ReadyToPayDetailsId])
		--SELECT 0 AS ReceivingReconciliationId,
		--CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS InvoiceNum,
		--RRH.[Status],
		--0 AS OriginalTotal,
		--0 AS RRTotal,
		--SUM(ISNULL(VRTPD.PaymentMade,0)) AS InvoiceTotal,
		--0 AS 'DifferenceAmount',  
		--VRTPD.VendorId,
		--VN.VendorName,
		----ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',		
		--CASE WHEN VN.IsVendorOnHold = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
		--CheckDate AS 'InvociedDate',
		--CheckDate AS 'EntryDate',		
		--'' AS 'PaymentMethod',
		--CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS 'PaymentRef',
		--'' AS 'DateProcessed',
		--'' AS 'CheckCrashed',
		--0 AS 'DiscountToken'
		--,CASE WHEN VRTPD.PaymentMethodId = @Check THEN lebl.BankName 
		--      WHEN VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.BankName 
		--	  WHEN VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBank 
		--	  WHEN VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.BankName 
		--	  WHEN VRTPD.PaymentMethodId = @CreditCard THEN '' END AS BankName
		--,CASE WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber + ' (V)' 
		--	  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.AccountNumber + ' (V)' 
		--	  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBankAccount + ' (V)' 
		--	  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.AccountNumber + ' (V)' 
		--	  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @CreditCard THEN '' 
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber 
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.AccountNumber 
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBankAccount 
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.AccountNumber
		--	  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @CreditCard THEN '' END AS 'BankAccountNumber'
		--,VRTPDH.ReadyToPayId
		--,VRTPD.IsVoidedCheck
		--,VRTPD.PaymentMethodId
		--,SRT.CreatedDate
		--,VRTPD.ReadyToPayDetailsId
		--FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
		--INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
		-- LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.CustomerCreditPaymentDetailId = RRH.CustomerCreditPaymentDetailId
		-- LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		-- LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRTPDH.BankId
		-- LEFT JOIN [dbo].[VendorDomesticWirePayment] VDWP WITH(NOLOCK) ON VDWP.VendorId = VRTPD.VendorId
		-- LEFT JOIN [dbo].[DomesticWirePayment] DWPL WITH(NOLOCK) ON DWPL.DomesticWirePaymentId = VDWP.DomesticWirePaymentId
		-- LEFT JOIN [dbo].[VendorInternationlWirePayment] VIWP WITH(NOLOCK) ON VIWP.VendorId = VRTPD.VendorId
		-- LEFT JOIN [dbo].[InternationalWirePayment] IWPL WITH(NOLOCK) ON IWPL.InternationalWirePaymentId = VIWP.InternationalWirePaymentId
		-- LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId
		-- OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VRTPD.ReadyToPayId =  SS.ReadyToPayId AND  VRTPD.VendorId = SS.VendorId AND  VRTPD.PaymentMethodId = SS.PaymentMethodId) AS SRT
	 -- WHERE RRH.MasterCompanyId = @MasterCompanyId 
	 --    AND (RemainingAmount <= 0  OR IsVoidedCheck = 1) 
		-- AND ISNULL(VRTPD.CreditMemoHeaderId, 0) = 0	
		-- AND ISNULL(RRH.NonPOInvoiceId, 0) = 0	
		-- AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) <> 0	
		-- AND (CASE WHEN VRTPD.PaymentMethodId = @Check THEN CASE WHEN VRTPD.IsCheckPrinted = 1 THEN VRTPD.IsCheckPrinted END END = 1 OR  VRTPD.PaymentMethodId <> @Check )

		-- GROUP BY VRTPD.CheckNumber,lebl.BankName,lebl.BankAccountNumber,DWPL.AccountNumber,
		--          IWPL.BeneficiaryBankAccount, VRTPDH.ReadyToPayId,RRH.[Status],VN.IsVendorOnHold,
		--          CheckDate,VN.VendorName,IsVoidedCheck,VRTPD.VendorId,VRTPD.PaymentMethodId,SRT.CreatedDate,
		--		  DWPL.BankName,IWPL.BeneficiaryBank,VRTPD.ReadyToPayDetailsId

	--),  
    ;WITH FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate,DiscountToken,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,BankName,BankAccountNumber,ReadyToPayId,IsVoidedCheck,VendorId,PaymentMethodId,CreatedDate,ReadyToPayDetailsId FROM #TEMPVendorPaymentListRecords  
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
       (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%')AND
	   (ISNULL(@Status,'') ='' OR [Status] LIKE '%'+ @Status +'%') AND
	   (ISNULL(@PaymentHold,'') ='' OR PaymentHold LIKE '%' + @PaymentHold + '%'))   
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate, EntryDate,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems,DiscountToken,BankName,BankAccountNumber,ReadyToPayId,IsVoidedCheck,VendorId,PaymentMethodId,CreatedDate,ReadyToPayDetailsId FROM FinalResult, ResultCount  
  
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
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    --ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'VendorPaymentList'                 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))  
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