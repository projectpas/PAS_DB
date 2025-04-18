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
	20   03/06/2024   AMIT GHEDIYA    Update for get CheckNumber from condition.
	21   19/06/2024   Abhishek Jirawla Add Legal Entity and returning data in capital. Update Invoiced Date to InvoiceDate instead of Due date
	22   19-07-2024   Shrey Chandegara      Modify For date filter issue(use this function @CurrntEmpTimeZoneDesc )
	23   27-12-2024   RAJESH GAMI     Added Vendor Proforma Invoice Functionality
	24   31-12-2024   AMIT GHEDIYA    update get account name & get creditmemo amount & PAyment method name.
	25   01-01-2025   AMIT GHEDIYA    Update statusid for vendor perfoma in print check.
	26   01-01-2025   RAJESH GAMI     Update logic for the get record for print check.
	27   03-01-2025   RAJESH GAMI     Modified to resolved to not getting paymentmethod for the vendor Proforma.
	28   03-01-2025   RAJESH GAMI     Modified to resolved to merge multiple line payment to single line (Partial Paid with same Vendor Proforma Invoice)
	29   28-01-2025   ABHISHEK JIRAWLA	Modified to resolved to merge multiple line payment method for (Partial Paid)
	30   11-03-2025   ABHISHEK JIRAWLA	IsVendorOnHold check for payment hold
	31   10-04-2025   AMIT GHEDIYA		Get le from perticular module
	32	 11-04-2025	  Ekta Chandegra	Convert date using dbo.ConvertUTCtoLocal

 --EXEC VendorPaymentList 10,1,'ReceivingReconciliationId',1,'','',0,0,0,'ALL','',NULL,NULL,1,73   
**************************************************************/
CREATE    PROCEDURE [dbo].[VendorPaymentList]  
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
@CreditMemoUsed varchar(50)=null,
@Status varchar(50)=null,  
@CurrentStatus varchar(50)=null,  
@VendorName varchar(50)=null,
@LegalEntity varchar(50)=null,
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
@CheckCrashed varchar(50)=null,
@ControlNumber varchar(150)=null
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
	DECLARE @NonPOInvoiceHeaderStatusId INT,@ProformaInvoicePostedStatusId INT;
	DECLARE @StatusId VARCHAR(50) = '3,6';
	DECLARE @PrintFullStatusId VARCHAR(50) = '3,10';
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	
	SELECT 
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM 
					dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN 
					dbo.TimeZone ETZ WITH (NOLOCK) 
					ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN 
					dbo.LegalEntity LE WITH (NOLOCK) 
					ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN 
					dbo.TimeZone LTZ WITH (NOLOCK) 
					ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE 
					E.EmployeeId = @EmployeeId;	
	
	SELECT @NonPOInvoiceHeaderStatusId = NonPOInvoiceHeaderStatusId FROM [dbo].[NonPOInvoiceHeaderStatus] WITH(NOLOCK) WHERE [Description] = 'Posted';
	SELECT @ProformaInvoicePostedStatusId = VendorProformaInvoiceHeaderStatusId FROM [dbo].[VendorProformaInvoiceHeaderStatus] WITH(NOLOCK) WHERE [Description] = 'Posted';
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
		[CreditMemoUsed] DECIMAL(18, 2) NULL,
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
		[ControlNumber] VARCHAR(100) NULL,
		[LegalEntity] VARCHAR(256) NULL,
		[NonPOInvoiceId] BIGINT NULL,
		[CustomerCreditPaymentDetailId] BIGINT NULL,
		[VendorProformaInvoiceId] BIGINT NULL,
		) 
     
    IF(@CurrentStatus = 'PendingPayment')  
    BEGIN  
    --;WITH Result AS (       
	-- VendorPayment -ReceivingReconciliation DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [ReadyToPayId], [BankName],
		[BankAccountNumber], [VendorId], [ControlNumber], [LegalEntity])
		SELECT RRH.ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   --RRH.[Status],			   
			   CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' 
			        WHEN ISNULL(RRC.IsInvoiceOnHold,0) = 0 AND  RRH.PaymentMade = 0 THEN 'Ready to Pay'
			   ELSE 'Pending Payment' END AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
			   ISNULL(Tab.CreditMemoAmount,0) AS CreditMemoUsed,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			   --ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
			   CASE WHEN ISNULL(RRC.IsInvoiceOnHold, 0) = 1 OR ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
			   (Cast(DBO.ConvertUTCtoLocal(RRC.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',			   			  
			   --DATEADD(DAY, ctm.NetDays,RRC.InvoiceDate) AS 'DueDate',   
			   --CASE WHEN DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  			   
			   CASE WHEN IIF(TRY_CAST(RRC.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(RRC.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
					  ELSE NULL END	AS 'DueDate',
			   CASE WHEN IIF(TRY_CAST(RRC.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
			   --'' AS 'PaymentMethod',
			   --'' AS 'PaymentRef',
			   --PaymentMethod = (SELECT MAX(PM.Description) FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
						--		 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
						--		 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsGenerated = 1),
			   PaymentMethod = ISNULL(Tab.PaymentMethod,''),
			   ISNULL(Tab.PayRef,'') AS 'PaymentRef',
			   --PaymentRef = (SELECT MAX(VD.CheckNumber) FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
						--		 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
						--		 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
						--		 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId  AND VD.IsGenerated = 1),
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
			   ISNULL(Tab.ReadyToPaymentMade,0) AS 'ReadyToPaymentMade',
			   ISNULL(Tab.ReadyToPayId,0) AS 'ReadyToPayId',
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   RRH.VendorId,
			   ISNULL(TAB.ControlNumber,'') AS 'ControlNumber',
			   CASE WHEN ISNULL(RRH.[LastMSLevel],'') = '' THEN  ISNULL(le.Name, '') ELSE ISNULL(RRH.[LastMSLevel], '') END AS 'LegalEntity'
		  FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		       INNER JOIN [dbo].[ReceivingReconciliationHeader] RRC WITH(NOLOCK) ON RRH.[ReceivingReconciliationId] = RRC.[ReceivingReconciliationId]	
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId  --WHERE StatusId=3
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = RRC.LegalEntityId
			   OUTER APPLY (SELECT TOP 1 VD.VendorPaymentDetailsId,
			                       SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
								   SUM(ISNULL(VD.CreditMemoAmount,0)) AS CreditMemoAmount,
								   SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
								   MAX(PM.Description) AS PaymentMethod,
								   MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
								   VRTPDH.ReadyToPayId,
								   VD.ControlNumber,
								   MAX(VD.CheckNumber) AS PayRef
							FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								INNER JOIN [dbo].[ReceivingReconciliationHeader] RRC2 WITH(NOLOCK) ON VD.[ReceivingReconciliationId] = RRC2.[ReceivingReconciliationId]	
								 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							     LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsVoidedCheck = 0 AND VD.IsGenerated = 1 --AND VD.CheckNumber IS NULL
			    GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber, VD.ReadyToPayDetailsId
				ORDER BY VD.ReadyToPayDetailsId DESC) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RemainingAmount > 0 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0

	--UNION ALL
	-- -ReceivingReconciliation DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [ReadyToPayId], [BankName],
		[BankAccountNumber], [VendorId], [ControlNumber], [LegalEntity])
		SELECT DISTINCT
		       RRH.ReceivingReconciliationId,
			   RRH.InvoiceNum,
			   'Pending Payment' AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   0 AS InvoiceTotal,
			   0 AS CreditMemoUsed,
			   ISNULL(RRH.InvoiceTotal,0) AS 'DifferenceAmount', 
			   VN.VendorName,
			   --ISNULL(RRH.IsInvoiceOnHold,0) AS 'PaymentHold',
			   CASE WHEN ISNULL(RRH.IsInvoiceOnHold, 0) = 1 OR ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
			   --DATEADD(DAY, ctm.NetDays,RRH.InvoiceDate) AS 'DueDate',  
			   --CASE WHEN DATEDIFF(DAY, (CAST(RRH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(RRH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  
			   CASE WHEN IIF(TRY_CAST(RRH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(RRH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
					  ELSE NULL END	AS 'DueDate',
			   CASE WHEN IIF(TRY_CAST(RRH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(RRH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(RRH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
			   ISNULL(Tab.PaymentMethod,'') AS 'PaymentMethod',
			   ISNULL(Tab.PaymentRef,'') AS 'PaymentRef',
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   0 AS 'DiscountToken',
			   0 AS 'ReadyToPaymentMade',
			   0 AS 'ReadyToPayId',
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   RRH.VendorId,
			   '' AS 'ControlNumber',
			   ISNULL(le.[Name], '') AS 'LegalEntity'
		FROM [dbo].[ReceivingReconciliationHeader] RRH  WITH(NOLOCK) 		
			INNER JOIN [dbo].[ReceivingReconciliationDetails] RRD WITH(NOLOCK) ON RRH.[ReceivingReconciliationId] = RRD.[ReceivingReconciliationId]	
			INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.[VendorId] = VN.[VendorId]	
			LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = RRH.LegalEntityId
			OUTER APPLY (SELECT TOP 1 VD.VendorPaymentDetailsId,
			                    SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
								SUM(ISNULL(VD.CreditMemoAmount,0)) AS CreditMemoAmount,
								SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
								MAX(PM.Description) AS PaymentMethod,
								MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
								VRTPDH.ReadyToPayId,
								VD.ControlNumber,
								MAX(VD.CheckNumber) AS PayRef
						FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							    LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
						WHERE ISNULL(VD.[ReceivingReconciliationId],0) = RRH.[ReceivingReconciliationId] AND VD.IsVoidedCheck = 0  AND VD.IsGenerated = 1 AND VD.CheckNumber IS NULL
			GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber, VD.ReadyToPayDetailsId 
			ORDER BY VD.ReadyToPayDetailsId DESC) AS Tab
		WHERE RRH.[MasterCompanyId] = @MasterCompanyId 
		  AND RRH.[StatusId] = 1

	--UNION ALL
	-- VendorPayment -CreditMemo DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [ReadyToPayId], [BankName],
		[BankAccountNumber], [VendorId], [ControlNumber], [LegalEntity])
		SELECT RRH.ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' 
			        WHEN RRH.PaymentMade = 0 THEN 'Ready to Pay'
			   ELSE 'Pending Payment' END AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
			   ISNULL(Tab.CreditMemoAmount,0) AS CreditMemoUsed,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			  -- 0 AS 'PaymentHold',
			  CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
			   (Cast(DBO.ConvertUTCtoLocal(CM.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
			   CASE WHEN IIF(TRY_CAST(CM.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(CM.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
					  ELSE NULL END	AS 'DueDate',
			    CASE WHEN IIF(TRY_CAST(CM.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
			   --'' AS 'PaymentMethod',
			   --'' AS 'PaymentRef',
			  --PaymentMethod = (SELECT MAX(PM.Description) FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
					--			 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
					--			 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId  AND VD.IsGenerated = 1),
			   PaymentMethod = ISNULL(Tab.PaymentMethod,''),
			   ISNULL(Tab.PayRef,'') AS 'PaymentRef',
			   --PaymentRef = (SELECT MAX(VD.CheckNumber) FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
						--		 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
						--		 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
						--		 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId  AND VD.IsGenerated = 1),
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
			   ISNULL(Tab.ReadyToPaymentMade,0) AS 'ReadyToPaymentMade',
			   ISNULL(Tab.ReadyToPayId,0) AS 'ReadyToPayId',
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   RRH.VendorId,
			   ISNULL(TAB.ControlNumber,'') AS 'ControlNumber',
			   ISNULL(le.[Name], '') AS 'LegalEntity'
		  FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		       INNER JOIN [dbo].[CreditMemo] CM WITH(NOLOCK) ON RRH.CreditMemoHeaderId = CM.CreditMemoHeaderId	
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON CM.ManagementStructureId = ESS.[EntityStructureId]
			   LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			   LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = MSL1.ID
			   OUTER APPLY (SELECT TOP 1 VD.VendorPaymentDetailsId,
			                       SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
								   SUM(ISNULL(VD.CreditMemoAmount,0)) AS CreditMemoAmount,
								   SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
								   MAX(PM.Description) AS PaymentMethod,
								   MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
								   VRTPDH.ReadyToPayId,
								   VD.ControlNumber,
								   MAX(VD.CheckNumber) AS PayRef
							FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							     LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsVoidedCheck = 0 AND VD.IsGenerated = 1 AND VD.CheckNumber IS NULL
			    GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber, VD.ReadyToPayDetailsId 
			ORDER BY VD.ReadyToPayDetailsId DESC) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RRH.RemainingAmount > 0 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0 
		  AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) = 0
		  AND ISNULL(RRH.CreditMemoHeaderId, 0) <> 0

	--UNION ALL
	-- VendorPayment NonPOInvoice DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [ReadyToPayId], [BankName],
		[BankAccountNumber], [VendorId], [ControlNumber], [LegalEntity], [NonPOInvoiceId])
		SELECT 0 AS ReceivingReconciliationId,
				NPH.NPONumber AS [InvoiceNum],
				NPHS.[Description] AS [Status],
				(ISNULL(part.ExtendedPrice,0)) AS OriginalTotal,
				0 AS RRTotal,
				0 AS InvoiceTotal,
				0 AS CreditMemoUsed,
				0 AS 'DifferenceAmount',  
				NPH.VendorName,
				--0 AS 'PaymentHold',
				CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
				(Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
				(Cast(DBO.ConvertUTCtoLocal(NPH.UpdatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
				--DATEADD(DAY, ctm.NetDays,NPH.InvoiceDate) AS 'DueDate', 
				--CASE WHEN DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  				
				CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
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
				ISNULL(VPD.ControlNumber,'') AS 'ControlNumber',
				ISNULL(le.[Name], '') AS 'LegalEntity',
				NPH.NonPOInvoiceId
		  FROM [dbo].[NonPOInvoiceHeader] NPH  WITH(NOLOCK)
		       LEFT JOIN [dbo].[VendorReadyToPayDetails] VPD WITH(NOLOCK) ON VPD.NonPOInvoiceId = NPH.NonPOInvoiceId	
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON NPH.VendorId = VN.VendorId
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON NPH.ManagementStructureId = ESS.[EntityStructureId]
			   LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			   LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = MSL1.ID
			   INNER JOIN [dbo].[NonPOInvoiceHeaderStatus] NPHS WITH(NOLOCK) ON NPHS.[NonPOInvoiceHeaderStatusId] = NPH.[StatusId]
			   OUTER APPLY (SELECT TOP 1 VD.VendorPaymentDetailsId,ReadyToPayDetailsId,
								   SUM(ISNULL(VD.PaymentMade,0)) ReadyToPaymentMade,
								   SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
								   MAX(PM.Description) AS PaymentMethod,
								   CASE WHEN VD.IsVoidedCheck =1 THEN MAX(VD.CheckNumber) + ' (V)' ELSE MAX(VD.CheckNumber) END PaymentRef,
								   VRTPDH.ReadyToPayId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate
		                    FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
				OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VD.ReadyToPayId =  SS.ReadyToPayId AND  VD.VendorId = SS.VendorId AND  VD.PaymentMethodId = SS.PaymentMethodId) AS SRT
		  WHERE ISNULL(VD.VendorPaymentDetailsId,0) = VPD.VendorPaymentDetailsId AND VD.CheckNumber IS NULL AND IsVoidedCheck = 0 AND VD.IsGenerated = 1
			GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate 
			ORDER BY VD.ReadyToPayDetailsId DESC) AS Tab
				OUTER APPLY (SELECT VD.NonPOInvoiceId,
								   SUM(ISNULL(VD.ExtendedPrice,0)) ExtendedPrice
							FROM [dbo].[NonPOInvoicePartDetails] VD WITH(NOLOCK) 
							WHERE VD.NonPOInvoiceId = NPH.NonPOInvoiceId
			    GROUP BY VD.NonPOInvoiceId) AS part
	      WHERE NPH.MasterCompanyId = @MasterCompanyId AND part.ExtendedPrice > 0  AND VPD.CheckNumber IS NULL AND NPH.PostedDate IS NULL
				AND NPHS.NonPOInvoiceHeaderStatusId = @NonPOInvoiceHeaderStatusId

		--UNION ALL
		-- VendorPayment -NonPOInvoice DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [ReadyToPayId], [BankName],
		[BankAccountNumber], [VendorId], [ControlNumber], [LegalEntity], [NonPOInvoiceId])
		SELECT RRH.ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' 
			        WHEN RRH.PaymentMade = 0 THEN 'Ready to Pay'
			   ELSE 'Pending Payment' END AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
			   ISNULL(Tab.CreditMemoAmount,0) AS CreditMemoUsed,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			   --0 AS 'PaymentHold',
				CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
			   (Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
			  --DATEADD(DAY, ctm.NetDays,NPH.InvoiceDate) AS 'DueDate',  
			  -- CASE WHEN DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  
			   CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
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
			    ISNULL(TAB.ControlNumber,'') AS 'ControlNumber',
				ISNULL(le.[Name], '') AS 'LegalEntity',
				NPH.NonPOInvoiceId
		  FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		       INNER JOIN [dbo].[NonPOInvoiceHeader] NPH WITH(NOLOCK) ON RRH.NonPOInvoiceId = NPH.NonPOInvoiceId 	
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId  --WHERE StatusId=3
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON NPH.ManagementStructureId = ESS.[EntityStructureId]
			   LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			   LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = MSL1.ID
			   OUTER APPLY (SELECT TOP 1 VD.VendorPaymentDetailsId,ReadyToPayDetailsId,
								   SUM(ISNULL(VD.PaymentMade,0)) ReadyToPaymentMade,
								   SUM(ISNULL(VD.CreditMemoAmount,0)) AS CreditMemoAmount,
								   SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
								   MAX(PM.Description) AS PaymentMethod,
								   CASE WHEN VD.IsVoidedCheck =1 THEN MAX(VD.CheckNumber) + ' (V)' ELSE MAX(VD.CheckNumber) END PaymentRef,
								   VRTPDH.ReadyToPayId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate,VD.ControlNumber
		                    FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
				OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VD.ReadyToPayId =  SS.ReadyToPayId AND  VD.VendorId = SS.VendorId AND  VD.PaymentMethodId = SS.PaymentMethodId) AS SRT
		  WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId --AND VD.CheckNumber IS NULL 
				AND IsVoidedCheck = 0 AND VD.IsGenerated = 1
			GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate,VD.ControlNumber
			ORDER BY VD.ReadyToPayDetailsId DESC) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RemainingAmount > 0 AND ISNULL(RRH.NonPOInvoiceId, 0) <> 0
		        AND NPH.StatusId = @NonPOInvoiceHeaderStatusId

	    --CustomerCreditPayment DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [ReadyToPayId], [BankName],
		[BankAccountNumber], [VendorId], [ControlNumber], [LegalEntity], [CustomerCreditPaymentDetailId] )
		SELECT RRH.ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' 
			        WHEN RRH.PaymentMade = 0 THEN 'Ready to Pay'
			   ELSE 'Pending Payment' END AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
			   ISNULL(Tab.CreditMemoAmount,0) AS CreditMemoUsed,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			   --0 AS 'PaymentHold',
				CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
			   (Cast(DBO.ConvertUTCtoLocal(CCPD.ProcessedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
			   CASE WHEN IIF(TRY_CAST(CCPD.ProcessedDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(CCPD.ProcessedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
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
			   ISNULL(TAB.ControlNumber,'') AS 'ControlNumber',
			   ISNULL(le.[Name], '') AS 'LegalEntity',
			   CCPD.CustomerCreditPaymentDetailId
		  FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		       INNER JOIN [dbo].[CustomerCreditPaymentDetail] CCPD WITH(NOLOCK) ON RRH.CustomerCreditPaymentDetailId = CCPD.CustomerCreditPaymentDetailId	
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON CCPD.ManagementStructureId = ESS.[EntityStructureId]
			   LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			   LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = MSL1.ID
			   OUTER APPLY (SELECT TOP 1 VD.VendorPaymentDetailsId,
			                       SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
								   SUM(ISNULL(VD.CreditMemoAmount,0)) AS CreditMemoAmount,
								   SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
								   MAX(PM.Description) AS PaymentMethod,
								   MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
								   VRTPDH.ReadyToPayId,
								   VD.ControlNumber
							FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							     LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsGenerated = 1 AND VD.IsVoidedCheck = 0 AND VD.IsGenerated = 1 --AND VD.CheckNumber IS NULL
			    GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber, VD.ReadyToPayDetailsId 
			ORDER BY VD.ReadyToPayDetailsId DESC) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RRH.RemainingAmount > 0 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0 AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) <> 0

	/***********************START: Vendor Proforma Invoice Details **************************/
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [ReadyToPayId], [BankName],
		[BankAccountNumber], [VendorId], [ControlNumber], [LegalEntity], [VendorProformaInvoiceId])
		SELECT 0 AS ReceivingReconciliationId,
				NPH.VendorProformaInvoiceNo AS [InvoiceNum],
				NPHS.[Description] AS [Status],
				(ISNULL(part.ExtendedPrice,0)) AS OriginalTotal,
				0 AS RRTotal,
				0 AS InvoiceTotal,
				0 AS CreditMemoUsed,
				0 AS 'DifferenceAmount',  
				NPH.VendorName,
				CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
				(Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
				(Cast(DBO.ConvertUTCtoLocal(NPH.UpdatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
				CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
					  ELSE NULL END	AS 'DueDate',
			    CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
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
				NPH.VendorId,
				'' AS 'ControlNumber',
				ISNULL(le.[Name], '') AS 'LegalEntity',
				NPH.VendorProformaInvoiceId AS VendorProformaInvoiceId
		  FROM [dbo].[VendorProformaInvoiceHeader] NPH  WITH(NOLOCK)
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON NPH.VendorId = VN.VendorId
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON NPH.ManagementStructureId = ESS.[EntityStructureId]
			   LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			   LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = MSL1.ID
			   INNER JOIN [dbo].[VendorProformaInvoiceHeaderStatus] NPHS WITH(NOLOCK) ON NPHS.[VendorProformaInvoiceHeaderStatusId] = NPH.[StatusId]
			   OUTER APPLY (SELECT VD.VendorProformaInvoiceId,
								   SUM(ISNULL(VD.ExtendedPrice,0)) ExtendedPrice
							FROM [dbo].[VendorProformaInvoicePartDetails] VD WITH(NOLOCK) 
							WHERE VD.VendorProformaInvoiceId = NPH.VendorProformaInvoiceId
			    GROUP BY VD.VendorProformaInvoiceId) AS part
	      WHERE NPH.MasterCompanyId = @MasterCompanyId AND part.ExtendedPrice > 0  AND NPH.PostedDate IS NULL
				AND NPHS.VendorProformaInvoiceHeaderStatusId = @ProformaInvoicePostedStatusId

	
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [ReadyToPayId], [BankName],
		[BankAccountNumber], [VendorId], [ControlNumber], [LegalEntity], VendorProformaInvoiceId)
		SELECT RRH.ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' 
			        WHEN RRH.PaymentMade = 0 THEN 'Ready to Pay'
			   ELSE 'Pending Payment' END AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
			   ISNULL(Tab.CreditMemoAmount,0) AS CreditMemoUsed,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
				CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
			   (Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
			   CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
					  ELSE NULL END	AS 'DueDate',
			    CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN CASE WHEN DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END
					 ELSE NULL END	AS 'DaysPastDue',
			   ISNULL(Tab.PaymentMethod,'') AS 'PaymentMethod',
			   ISNULL(Tab.PaymentRef,'') AS 'PaymentRef',
			   '' AS 'DateProcessed',
			   '' AS 'CheckCrashed',
			   ISNULL(Tab.DiscountToken,0) AS 'DiscountToken',
				CASE WHEN tab.IsGenerated = 1 THEN 0 ELSE ISNULL(Tab.ReadyToPaymentMade,0) END AS 'ReadyToPaymentMade',
			   ISNULL(Tab.ReadyToPayId,0) AS 'ReadyToPayId',
			   '' AS BankName,
			   '' AS BankAccountNumber,
			   RRH.VendorId,
			    ISNULL(TAB.ControlNumber,'') AS 'ControlNumber',
				ISNULL(le.[Name], '') AS 'LegalEntity',
					NPH.VendorProformaInvoiceId AS VendorProformaInvoiceId
		  FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		       INNER JOIN [dbo].[VendorProformaInvoiceHeader] NPH WITH(NOLOCK) ON RRH.VendorProformaInvoiceId = NPH.VendorProformaInvoiceId 	
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId 
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON NPH.ManagementStructureId = ESS.[EntityStructureId]
			   LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			   LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = MSL1.ID
			   OUTER APPLY (SELECT TOP 1 VD.VendorPaymentDetailsId,ReadyToPayDetailsId,ISNULL(VD.PaymentMade,0) ReadyToPaymentMade,
							0 DiscountToken,
							ISNULL(VD.CreditMemoAmount,0) AS CreditMemoAmount,
							PM.Description AS PaymentMethod,
							CASE WHEN VD.IsVoidedCheck =1 THEN VD.CheckNumber + ' (V)' ELSE VD.CheckNumber END PaymentRef,
							VRTPDH.ReadyToPayId,
							VD.IsVoidedCheck,
							VD.PaymentMethodId,
							SRT.CreatedDate,
							VD.ControlNumber,
							ISNULL(VD.IsGenerated,0) IsGenerated
		                    FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
				OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VD.ReadyToPayId =  SS.ReadyToPayId AND  VD.VendorId = SS.VendorId AND  VD.PaymentMethodId = SS.PaymentMethodId) AS SRT
				WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId   AND IsVoidedCheck = 0 AND  RRH.VendorProformaInvoiceId = VD.VendorProformaInvoiceId 
				ORDER BY VD.ReadyToPayDetailsId DESC) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RemainingAmount > 0 AND ISNULL(RRH.VendorProformaInvoiceId, 0) <> 0
		        AND NPH.StatusId = @ProformaInvoicePostedStatusId
	/***********************END: Vendor Proforma Invoice Details **************************/
    --),  
    ;WITH FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,CreditMemoUsed,DifferenceAmount, VendorName, PaymentHold, 
		InvociedDate,EntryDate,DueDate, DaysPastDue, PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, DiscountToken, ReadyToPaymentMade, 
		BankName, BankAccountNumber, VendorId, ControlNumber, LegalEntity, NonPOInvoiceId, CustomerCreditPaymentDetailId,VendorProformaInvoiceId FROM #TEMPVendorPaymentListRecords  
    WHERE -- ISNULL(ReadyToPayId,0) = 0 AND 
	   ((@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR   
       ([Status] LIKE '%' +@GlobalFilter+'%') OR  
       (InvociedDate LIKE '%' +@GlobalFilter+'%') OR  
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR  
       (OriginalTotal LIKE '%' +@GlobalFilter+'%') OR  
       (RRTotal LIKE '%'+@GlobalFilter+'%') OR  
	   (DaysPastDue LIKE '%'+@GlobalFilter+'%') OR  
       (InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR  
	   (CreditMemoUsed LIKE '%' +@GlobalFilter+'%') OR
       (VendorName LIKE '%' +@GlobalFilter+'%') OR  
       (LegalEntity LIKE '%' +@GlobalFilter+'%') OR
	   (ReadyToPaymentMade LIKE '%' +@GlobalFilter+'%') OR
	   (DiscountToken LIKE '%' +@GlobalFilter+'%') OR
	   (DifferenceAmount LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentMethod LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentRef LIKE '%' +@GlobalFilter+'%') OR
	   (CheckCrashed LIKE '%' +@GlobalFilter+'%') OR
	   (ControlNumber LIKE '%' +@GlobalFilter+'%')
       ))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND   
       (ISNULL(@InvociedDate,'') ='' OR CAST([InvociedDate] AS DATE) = CAST(@InvociedDate AS DATE)) AND  
       (ISNULL(@EntryDate,'') ='' OR CAST([EntryDate] AS DATE) = CAST(@EntryDate AS DATE)) AND
	   (ISNULL(@DueDate,'') ='' OR CAST([DueDate] AS DATE) = CAST(@DueDate AS DATE)) AND
	   --(ISNULL(@DueDate,'') ='' OR CAST([DueDate] AS DATE) = CAST(@DueDate AS DATE)) AND 
	   (ISNULL(@DaysPastDue,'') ='' OR DaysPastDue LIKE '%'+@DaysPastDue+'%') AND  
       (ISNULL(@OriginalTotal,'') ='' OR [OriginalTotal] LIKE '%'+ @OriginalTotal+'%') AND  
       (ISNULL(@RRTotal,'') ='' OR [RRTotal] LIKE '%'+@RRTotal+'%') AND  	   
       (ISNULL(@InvoiceTotal,'') ='' OR [InvoiceTotal] LIKE '%'+ @InvoiceTotal+'%') AND 
	   (ISNULL(@CreditMemoUsed,'') ='' OR [CreditMemoUsed] LIKE '%'+ @CreditMemoUsed+'%') AND 
       (ISNULL(@VendorName,'') ='' OR [VendorName] LIKE '%'+ @VendorName +'%') AND 
       (ISNULL(@LegalEntity,'') ='' OR [LegalEntity] LIKE '%'+ @LegalEntity +'%') AND
	   (ISNULL(@Status,'') ='' OR [Status] LIKE '%'+ @Status +'%') AND
	   (ISNULL(@PaymentHold,'') ='' OR [PaymentHold] LIKE '%' + @PaymentHold + '%') AND
	   (ISNULL(@ReadyToPaymentMade,'') ='' OR ReadyToPaymentMade LIKE '%'+ @ReadyToPaymentMade+'%') AND
	   (ISNULL(@DiscountToken,'') ='' OR DiscountToken LIKE '%'+ @DiscountToken+'%') AND
	   (ISNULL(@DifferenceAmount,'') ='' OR DifferenceAmount LIKE '%'+ @DifferenceAmount+'%') AND
	   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND
	   (ISNULL(@PaymentRef,'') ='' OR PaymentRef LIKE '%'+ @PaymentRef+'%') AND
	   (ISNULL(@CheckCrashed,'') ='' OR CheckCrashed LIKE '%'+ @CheckCrashed+'%') AND
	   (ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%'+ @ControlNumber+'%')) 
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, UPPER(InvoiceNum) AS InvoiceNum, UPPER([Status]) AS Status, OriginalTotal, RRTotal, InvoiceTotal,CreditMemoUsed,DifferenceAmount, UPPER(VendorName) AS VendorName, 
	  PaymentHold, InvociedDate, EntryDate, DueDate, DaysPastDue, UPPER(PaymentMethod) AS PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems, DiscountToken,
	  ReadyToPaymentMade, UPPER(BankName) AS BankName, UPPER(BankAccountNumber) AS BankAccountNumber, VendorId, UPPER(ControlNumber) AS ControlNumber, UPPER(LegalEntity) AS LegalEntity,NonPOInvoiceId, CustomerCreditPaymentDetailId,VendorProformaInvoiceId FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DaysPastDue')  THEN DaysPastDue END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentHold')  THEN PaymentHold END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='OriginalTotal')  THEN OriginalTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='RRTotal')  THEN RRTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceTotal')  THEN InvoiceTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='CREDITMEMOUSED')  THEN CreditMemoUsed END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DifferenceAmount')  THEN DifferenceAmount END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DiscountToken')  THEN DiscountToken END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='ReadyToPaymentMade')  THEN ReadyToPaymentMade END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentRef')  THEN PaymentRef END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DateProcessed')  THEN DateProcessed END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='EntryDate')  THEN EntryDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='InvociedDate')  THEN InvociedDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='BankName')  THEN BankName END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='BankAccountNumber')  THEN BankAccountNumber END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='LegalEntity')  THEN LegalEntity END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DueDate')  THEN DueDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='NumberOfItems')  THEN NumberOfItems END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='CheckCrashed')  THEN CheckCrashed END ASC,

     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC, 
	 CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DaysPastDue')  THEN DaysPastDue END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentHold')  THEN PaymentHold END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='OriginalTotal')  THEN OriginalTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='RRTotal')  THEN RRTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceTotal')  THEN InvoiceTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CREDITMEMOUSED')  THEN CreditMemoUsed END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DifferenceAmount')  THEN DifferenceAmount END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DiscountToken')  THEN DiscountToken END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='ReadyToPaymentMade')  THEN ReadyToPaymentMade END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentRef')  THEN PaymentRef END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DateProcessed')  THEN DateProcessed END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='EntryDate')  THEN EntryDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='InvociedDate')  THEN InvociedDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='BankName')  THEN BankName END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='BankAccountNumber')  THEN BankAccountNumber END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='LegalEntity')  THEN LegalEntity END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DueDate')  THEN DueDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='NumberOfItems')  THEN NumberOfItems END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CheckCrashed')  THEN CheckCrashed END DESC

     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END  
    ELSE IF(@CurrentStatus = 'ReadyforSelection')
    BEGIN  
    --;WITH Result AS (  
	-- VendorPayment -ReceivingReconciliation DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [BankName], [BankAccountNumber], 
		[ReadyToPayId], [VendorId], [CreatedDate], [ControlNumber], [LegalEntity])
		 SELECT DISTINCT 
		        RRH.ReceivingReconciliationId,
				RRH.InvoiceNum,
				--RRH.[Status],
				CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' ELSE 'Ready to Pay' END AS [Status],
				ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
				ISNULL(RRH.RRTotal,0) AS RRTotal,
				ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
				ISNULL(Tab.CreditMemoAmount,0) AS CreditMemoUsed,
				RRH.RemainingAmount AS 'DifferenceAmount',  
				VN.VendorName,
				--ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
				--ISNULL(RRC.IsInvoiceOnHold,0) AS 'PaymentHold',
				CASE WHEN ISNULL(RRC.IsInvoiceOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
				(Cast(DBO.ConvertUTCtoLocal(RRC.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
				(Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
				--DATEADD(DAY, ctm.NetDays,RRC.InvoiceDate) AS 'DueDate',  
			    --CASE WHEN DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(RRC.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  				
				CASE WHEN IIF(TRY_CAST(RRC.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(RRC.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
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
				(Cast(DBO.ConvertUTCtoLocal(RRH.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
				ISNULL(TAB.ControlNumber,'') AS 'ControlNumber',
				CASE WHEN ISNULL(RRH.[LastMSLevel],'') = '' THEN  ISNULL(le.Name, '') ELSE ISNULL(RRH.[LastMSLevel], '') END AS 'LegalEntity'
		   FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		        INNER JOIN [dbo].[ReceivingReconciliationHeader] RRC WITH(NOLOCK) ON RRH.[ReceivingReconciliationId] = RRC.[ReceivingReconciliationId]	
				INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId  --WHERE StatusId=3
				LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
				LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = RRC.LegalEntityId
				OUTER APPLY (SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
							 SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) AS PaymentMethod,
							 SUM(ISNULL(VD.CreditMemoAmount,0)) AS CreditMemoAmount,
							 MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
							 VRTPDH.ReadyToPayId,
							 VD.ControlNumber
							 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsVoidedCheck = 0 AND VD.CheckNumber IS NULL
							 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber) AS Tab
		 WHERE RRH.MasterCompanyId = @MasterCompanyId 
		 AND RemainingAmount > 0 
		 --AND RRH.PaymentMade = 0
		 AND ISNULL(RRC.IsInvoiceOnHold,0) = 0 --WHERE StatusId=3 
		 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0
		
		 --UNION ALL
		 -- VendorPayment -CreditMemo DETAILS
		 INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		 [InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [BankName], [BankAccountNumber], 
		 [ReadyToPayId], [VendorId], [CreatedDate],[ControlNumber], [LegalEntity])
		 SELECT DISTINCT 
		        RRH.ReceivingReconciliationId,
				RRH.InvoiceNum,
				CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' ELSE 'Ready to Pay' END AS [Status],
				ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
				ISNULL(RRH.RRTotal,0) AS RRTotal,
				ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
				ISNULL(Tab.CreditMemoAmount,0) AS CreditMemoUsed,
				RRH.RemainingAmount AS 'DifferenceAmount',  
				VN.VendorName,
				--0 AS 'PaymentHold',
				'NO' AS 'PaymentHold',
				(Cast(DBO.ConvertUTCtoLocal(CM.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
				(Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
				CASE WHEN IIF(TRY_CAST(CM.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(CM.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
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
				(Cast(DBO.ConvertUTCtoLocal(RRH.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
				ISNULL(TAB.ControlNumber,'') AS 'ControlNumber',
				ISNULL(le.[Name], '') AS 'LegalEntity'
		   FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		        INNER JOIN [dbo].[CreditMemo] CM WITH(NOLOCK) ON RRH.CreditMemoHeaderId = CM.CreditMemoHeaderId
				INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId
				LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
				LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON CM.ManagementStructureId = ESS.[EntityStructureId]
			    LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			    LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = MSL1.ID
				OUTER APPLY (SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
							 SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) AS PaymentMethod,
							 SUM(ISNULL(VD.CreditMemoAmount,0)) AS CreditMemoAmount,
							 MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
							 VRTPDH.ReadyToPayId,
							 VD.ControlNumber
							 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsVoidedCheck = 0 AND VD.CheckNumber IS NULL
							 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber) AS Tab
		 WHERE RRH.MasterCompanyId = @MasterCompanyId 
		 AND RemainingAmount > 0 
		 --AND RRH.PaymentMade = 0
		 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0
		 AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) = 0
		 AND ISNULL(RRH.CreditMemoHeaderId, 0) <> 0

	--UNION ALL
	-- VendorPayment -NonPOInvoice DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [BankName], [BankAccountNumber], 
		[ReadyToPayId], [VendorId], [CreatedDate], [ControlNumber], [LegalEntity], [NonPOInvoiceId])
		SELECT DISTINCT 
		        RRH.ReceivingReconciliationId,
				RRH.InvoiceNum,
				CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' ELSE 'Ready to Pay' END AS [Status],
				ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
				ISNULL(RRH.RRTotal,0) AS RRTotal,
				ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
				ISNULL(Tab.CreditMemoAmount,0) AS CreditMemoUsed,
				RRH.RemainingAmount AS 'DifferenceAmount',  
				VN.VendorName,
				--0 AS 'PaymentHold',
				'NO' AS 'PaymentHold',
				(Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
				(Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
				--DATEADD(DAY, ctm.NetDays,NPH.InvoiceDate) AS 'DueDate',  
			    --CASE WHEN DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(NPH.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  
				CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
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
				(Cast(DBO.ConvertUTCtoLocal(RRH.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
				ISNULL(TAB.ControlNumber,'') AS 'ControlNumber',
				ISNULL(le.[Name], '') AS 'LegalEntity',
				NPH.NonPOInvoiceId
		   FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		        INNER JOIN [dbo].[NonPOInvoiceHeader] NPH WITH(NOLOCK) ON RRH.NonPOInvoiceId = NPH.NonPOInvoiceId
				INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId
				LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
				LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON NPH.ManagementStructureId = ESS.[EntityStructureId]
			    LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			    LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = MSL1.ID
				OUTER APPLY (SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
							 SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) AS PaymentMethod,
							 SUM(ISNULL(VD.CreditMemoAmount,0)) AS CreditMemoAmount,
							 MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
							 VRTPDH.ReadyToPayId,
							 VD.ControlNumber
							 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsVoidedCheck = 0 AND VD.CheckNumber IS NULL
							 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber) AS Tab
		 WHERE RRH.MasterCompanyId = @MasterCompanyId 
		 AND RemainingAmount > 0 
		 --AND RRH.PaymentMade = 0
		 AND ISNULL(RRH.NonPOInvoiceId, 0) <> 0
		 AND NPH.StatusId = @NonPOInvoiceHeaderStatusId
	
	/********************START: Vendor Proforma Invoice *************************/
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [BankName], [BankAccountNumber], 
		[ReadyToPayId], [VendorId], [CreatedDate], [ControlNumber], [LegalEntity], VendorProformaInvoiceId)
		SELECT DISTINCT 
		        RRH.ReceivingReconciliationId,
				RRH.InvoiceNum,
				CASE WHEN RRH.PaymentMade > 0 THEN 'Partially Paid' ELSE 'Ready to Pay' END AS [Status],
				ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
				ISNULL(RRH.RRTotal,0) AS RRTotal,
				ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
				ISNULL(Tab.CreditMemoAmount,0) AS CreditMemoUsed,
				RRH.RemainingAmount AS 'DifferenceAmount',  
				VN.VendorName,
				'NO' AS 'PaymentHold',
				(Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
				(Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
				CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
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
				(Cast(DBO.ConvertUTCtoLocal(RRH.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
				ISNULL(TAB.ControlNumber,'') AS 'ControlNumber',
				ISNULL(le.[Name], '') AS 'LegalEntity',
				NPH.VendorProformaInvoiceId VendorProformaInvoiceId
		   FROM [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK)
		        INNER JOIN [dbo].[VendorProformaInvoiceHeader] NPH WITH(NOLOCK) ON RRH.VendorProformaInvoiceId = NPH.VendorProformaInvoiceId
				INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId
				LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
				LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON NPH.ManagementStructureId = ESS.[EntityStructureId]
			    LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			    LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = MSL1.ID
				OUTER APPLY (SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
							 SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) AS PaymentMethod,
							 SUM(ISNULL(VD.CreditMemoAmount,0)) AS CreditMemoAmount,
							 MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
							 VRTPDH.ReadyToPayId,
							 VD.ControlNumber
							 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.IsVoidedCheck = 0 AND VD.CheckNumber IS NULL
							 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber) AS Tab
		 WHERE RRH.MasterCompanyId = @MasterCompanyId 
		 AND RemainingAmount > 0 
		 AND ISNULL(RRH.VendorProformaInvoiceId, 0) <> 0
		 AND NPH.StatusId = @ProformaInvoicePostedStatusId
		 /********************END: Vendor Proforma Invoice *************************/
		 -- CustomerCreditPayment DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [BankName], [BankAccountNumber], 
		[ReadyToPayId], [VendorId], [CreatedDate], [ControlNumber], [LegalEntity], [CustomerCreditPaymentDetailId])
		  SELECT 0 AS ReceivingReconciliationId,
				CCPD.SuspenseUnappliedNumber AS [InvoiceNum],
				'Ready to Pay' [Status],
				ISNULL(CCPD.RemainingAmount,0) AS OriginalTotal,
				0 AS RRTotal,
				0 AS InvoiceTotal,
				ISNULL(Tab.CreditMemoAmount,0) AS CreditMemoUsed,
				0 AS 'DifferenceAmount',  
				V.VendorName as [VendorName],
				--0 AS 'PaymentHold',
				'NO' AS 'PaymentHold',
				(Cast(DBO.ConvertUTCtoLocal(CCPD.ProcessedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
				(Cast(DBO.ConvertUTCtoLocal(CCPD.ProcessedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',				
				CASE WHEN IIF(TRY_CAST(CCPD.ProcessedDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(CCPD.ProcessedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
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
				(Cast(DBO.ConvertUTCtoLocal(CCPD.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
				ISNULL(TAB.ControlNumber,'') AS 'ControlNumber',
				ISNULL(le.[Name], '') AS 'LegalEntity',
				CCPD.CustomerCreditPaymentDetailId
			FROM [dbo].[CustomerCreditPaymentDetail] CCPD WITH(NOLOCK)  
				LEFT JOIN [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK) ON VPD.[CustomerCreditPaymentDetailId] = CCPD.[CustomerCreditPaymentDetailId]	  
				LEFT JOIN [dbo].[Vendor] V WITH(NOLOCK) ON CCPD.VendorId = V.VendorId  
				LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = V.CreditTermsId  
				LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(CTM.PercentId AS INT) = p.PercentId  
				LEFT JOIN [dbo].[Currency] CU WITH(NOLOCK) ON V.CurrencyId = CU.CurrencyId  
				LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON CCPD.ManagementStructureId = ESS.[EntityStructureId]
			    LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			    LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = MSL1.ID
				OUTER APPLY (SELECT VD.VendorPaymentDetailsId,
			                       SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,
								   SUM(ISNULL(VD.CreditMemoAmount,0)) AS CreditMemoAmount,
								   SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
								   MAX(PM.Description) AS PaymentMethod,
								   MAX(VRTPDH.PrintCheck_Wire_Num) AS PaymentRef,
								   VRTPDH.ReadyToPayId,
								   VD.ControlNumber
							FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							     LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							WHERE ISNULL(VD.[CustomerCreditPaymentDetailId],0) = CCPD.[CustomerCreditPaymentDetailId] AND VD.IsVoidedCheck = 0 AND VD.CheckNumber IS NULL
			    GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,VD.ControlNumber) AS Tab
	      WHERE CCPD.MasterCompanyId = @MasterCompanyId 
				AND CCPD.IsProcessed = 1 AND CCPD.IsMiscellaneous = 1 AND VPD.RemainingAmount > 0 
    --),  
    ;WITH FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,CreditMemoUsed,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate, DueDate, DaysPastDue,
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,DiscountToken,ReadyToPaymentMade,BankName,BankAccountNumber,ReadyToPayId,VendorId,CreatedDate,ControlNumber,LegalEntity, NonPOInvoiceId, CustomerCreditPaymentDetailId,VendorProformaInvoiceId FROM #TEMPVendorPaymentListRecords  
    WHERE -- ISNULL(ReadyToPayId,0) = 0 AND 
	   ((@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR   
       ([Status] LIKE '%' +@GlobalFilter+'%') OR  
       (InvociedDate LIKE '%' +@GlobalFilter+'%') OR  
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR
	   (DaysPastDue LIKE '%' +@GlobalFilter+'%') OR  
       (OriginalTotal LIKE '%' +@GlobalFilter+'%') OR  
       (RRTotal LIKE '%'+@GlobalFilter+'%') OR  
       (InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR  
	   (CreditMemoUsed LIKE '%' +@GlobalFilter+'%') OR 
       (VendorName LIKE '%' +@GlobalFilter+'%')  OR 
       (LegalEntity LIKE '%' +@GlobalFilter+'%') OR
	   (ReadyToPaymentMade LIKE '%' +@GlobalFilter+'%') OR
	   (DiscountToken LIKE '%' +@GlobalFilter+'%') OR
	   (DifferenceAmount LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentMethod LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentRef LIKE '%' +@GlobalFilter+'%') OR
	   (CheckCrashed LIKE '%' +@GlobalFilter+'%') OR
	   (ControlNumber LIKE '%' +@GlobalFilter+'%')
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
	   (ISNULL(@CreditMemoUsed,'') ='' OR CreditMemoUsed LIKE '%'+ @CreditMemoUsed+'%') AND 
       (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%') AND
	   (ISNULL(@LegalEntity,'') ='' OR [LegalEntity] LIKE '%'+ @LegalEntity +'%') AND
	   (ISNULL(@Status,'') ='' OR [Status] LIKE '%'+ @Status +'%') AND
	   (ISNULL(@PaymentHold,'') ='' OR PaymentHold LIKE '%' + @PaymentHold + '%') AND
	   (ISNULL(@ReadyToPaymentMade,'') ='' OR ReadyToPaymentMade LIKE '%'+ @ReadyToPaymentMade+'%') AND
	   (ISNULL(@DiscountToken,'') ='' OR DiscountToken LIKE '%'+ @DiscountToken+'%') ANd
	   (ISNULL(@DifferenceAmount,'') ='' OR DifferenceAmount LIKE '%'+ @DifferenceAmount+'%') AND
	   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND
	   (ISNULL(@PaymentRef,'') ='' OR PaymentRef LIKE '%'+ @PaymentRef+'%') AND
	   (ISNULL(@CheckCrashed,'') ='' OR CheckCrashed LIKE '%'+ @CheckCrashed+'%') AND
	   (ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%'+ @ControlNumber+'%')) 
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, UPPER(InvoiceNum) AS InvoiceNum, UPPER([Status]) AS Status, OriginalTotal, RRTotal, InvoiceTotal,CreditMemoUsed, DifferenceAmount, UPPER(VendorName) AS VendorName, 
	  PaymentHold, InvociedDate, EntryDate,DueDate, DaysPastDue, UPPER(PaymentMethod) AS PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems,
	  DiscountToken, ReadyToPaymentMade, UPPER(BankName) AS BankName, UPPER(BankAccountNumber) AS BankAccountNumber, ReadyToPayId, VendorId, UPPER(ControlNumber) AS ControlNumber, UPPER(LegalEntity) AS LegalEntity
	  ,NonPOInvoiceId, CustomerCreditPaymentDetailId,VendorProformaInvoiceId FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC,  
	 CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DaysPastDue')  THEN DaysPastDue END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentHold')  THEN PaymentHold END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='OriginalTotal')  THEN OriginalTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='RRTotal')  THEN RRTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceTotal')  THEN InvoiceTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='CREDITMEMOUSED')  THEN CreditMemoUsed END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DifferenceAmount')  THEN DifferenceAmount END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DiscountToken')  THEN DiscountToken END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='ReadyToPaymentMade')  THEN ReadyToPaymentMade END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentRef')  THEN PaymentRef END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DateProcessed')  THEN DateProcessed END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='EntryDate')  THEN EntryDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='InvociedDate')  THEN InvociedDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='BankName')  THEN BankName END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='BankAccountNumber')  THEN BankAccountNumber END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='LegalEntity')  THEN LegalEntity END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DueDate')  THEN DueDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='NumberOfItems')  THEN NumberOfItems END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='CheckCrashed')  THEN CheckCrashed END ASC,
  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DaysPastDue')  THEN DaysPastDue END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentHold')  THEN PaymentHold END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='OriginalTotal')  THEN OriginalTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='RRTotal')  THEN RRTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceTotal')  THEN InvoiceTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CREDITMEMOUSED')  THEN CreditMemoUsed END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DifferenceAmount')  THEN DifferenceAmount END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DiscountToken')  THEN DiscountToken END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='ReadyToPaymentMade')  THEN ReadyToPaymentMade END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentRef')  THEN PaymentRef END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DateProcessed')  THEN DateProcessed END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='EntryDate')  THEN EntryDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='InvociedDate')  THEN InvociedDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='BankName')  THEN BankName END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='BankAccountNumber')  THEN BankAccountNumber END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='LegalEntity')  THEN LegalEntity END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DueDate')  THEN DueDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='NumberOfItems')  THEN NumberOfItems END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CheckCrashed')  THEN CheckCrashed END DESC
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
			   CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
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
			   (Cast(DBO.ConvertUTCtoLocal(RRH.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME))AS CreatedDate
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
			   CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
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
			   (Cast(DBO.ConvertUTCtoLocal(RRH.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate
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
		[ReadyToPayId], [ReadyToPayDetailsId], [VendorId], [CreatedDate], [NonPOInvoiceId])
		SELECT ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   'Selected to be Paid' AS [Status],
			   ISNULL(InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRTotal,0) AS RRTotal,
			   ISNULL(PaymentMade,0) AS InvoiceTotal,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			  -- ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
			   CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
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
			   (Cast(DBO.ConvertUTCtoLocal(RRH.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
			   RRH.NonPOInvoiceId
		  FROM [dbo].[VendorPaymentDetails] RRH WITH(NOLOCK)
               INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId
	           OUTER APPLY (SELECT VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) as PaymentMethod,MAX(VD.CheckNumber) AS PaymentRef,VRTPDH.ReadyToPayId
							 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.CheckNumber IS NULL
							 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RemainingAmount > 0 AND ISNULL(RRH.NonPOInvoiceId, 0) <> 0 

	/********************START: Vendor Proforma Invoice *************************/
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [ReadyToPaymentMade], [BankName], [BankAccountNumber], 
		[ReadyToPayId], [ReadyToPayDetailsId], [VendorId], [CreatedDate], VendorProformaInvoiceId)
		SELECT ReceivingReconciliationId,
		       RRH.InvoiceNum,
			   'Selected to be Paid' AS [Status],
			   ISNULL(InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRTotal,0) AS RRTotal,
			   ISNULL(PaymentMade,0) AS InvoiceTotal,
			   RRH.RemainingAmount AS 'DifferenceAmount',  
			   VN.VendorName,
			   CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
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
			   (Cast(DBO.ConvertUTCtoLocal(RRH.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME))AS CreatedDate,
			   RRH.VendorProformaInvoiceId VendorProformaInvoiceId
		  FROM [dbo].[VendorPaymentDetails] RRH WITH(NOLOCK)
               INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId
	           OUTER APPLY (SELECT VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,MAX(PM.Description) as PaymentMethod,MAX(VD.CheckNumber) AS PaymentRef,VRTPDH.ReadyToPayId
							 FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
							 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							 WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND VD.CheckNumber IS NULL
							 GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId) AS Tab
	      WHERE RRH.MasterCompanyId = @MasterCompanyId AND RemainingAmount > 0 AND ISNULL(RRH.VendorProformaInvoiceId, 0) <> 0 
	
	/******************** END: Vendor Proforma Invoice *************************/
    --),  
    ;WITH FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,DiscountToken,ReadyToPaymentMade,BankName,BankAccountNumber,ReadyToPayId,ReadyToPayDetailsId,VendorId,CreatedDate, NonPOInvoiceId, CustomerCreditPaymentDetailId,VendorProformaInvoiceId FROM #TEMPVendorPaymentListRecords  
    WHERE  ISNULL(ReadyToPayId,0) > 0 AND (  
       (@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR   
       ([Status] LIKE '%' +@GlobalFilter+'%') OR  
       (InvociedDate LIKE '%' +@GlobalFilter+'%') OR  
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR
	   
       (OriginalTotal LIKE '%' +@GlobalFilter+'%') OR  
       (RRTotal LIKE '%'+@GlobalFilter+'%') OR  
       (InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR  
       (VendorName LIKE '%' +@GlobalFilter+'%') OR
	   (LegalEntity LIKE '%' +@GlobalFilter+'%') OR
	   (ReadyToPaymentMade LIKE '%' +@GlobalFilter+'%') OR
	   (DiscountToken LIKE '%' +@GlobalFilter+'%') OR
	   (DifferenceAmount LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentMethod LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentRef LIKE '%' +@GlobalFilter+'%') OR
	   (ControlNumber LIKE '%' +@GlobalFilter+'%')
       ))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND   
       (ISNULL(@InvociedDate,'') ='' OR CAST(InvociedDate AS DATE) = Cast(@InvociedDate AS DATE)) AND  
       (ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS DATE) = Cast(@EntryDate AS DATE)) AND  
       (ISNULL(@OriginalTotal,'') ='' OR OriginalTotal LIKE '%'+ @OriginalTotal+'%') AND  
       (ISNULL(@RRTotal,'') ='' OR RRTotal LIKE '%'+@RRTotal+'%') AND  
       (ISNULL(@InvoiceTotal,'') ='' OR InvoiceTotal LIKE '%'+ @InvoiceTotal+'%') AND  
       (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%') AND
	   (ISNULL(@LegalEntity,'') ='' OR [LegalEntity] LIKE '%'+ @LegalEntity +'%') AND
	   (ISNULL(@Status,'') ='' OR [Status] LIKE '%'+ @Status +'%') AND
	   (ISNULL(@PaymentHold,'') ='' OR PaymentHold LIKE '%' + @PaymentHold + '%') AND
	   (ISNULL(@ReadyToPaymentMade,'') ='' OR ReadyToPaymentMade LIKE '%'+ @ReadyToPaymentMade+'%') AND
	   (ISNULL(@DiscountToken,'') ='' OR DiscountToken LIKE '%'+ @DiscountToken+'%') ANd
	   (ISNULL(@DifferenceAmount,'') ='' OR DifferenceAmount LIKE '%'+ @DifferenceAmount+'%') AND
	   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND
	   (ISNULL(@PaymentRef,'') ='' OR PaymentRef LIKE '%'+ @PaymentRef+'%') AND
	   (ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%'+ @ControlNumber+'%')) 
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, UPPER(InvoiceNum) AS InvoiceNum, UPPER([Status]) AS Status, OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, UPPER(VendorName) AS VendorName, 
	  PaymentHold, InvociedDate, EntryDate, UPPER(PaymentMethod) AS PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems, DiscountToken,
	  ReadyToPaymentMade, UPPER(BankName) AS BankName, UPPER(BankAccountNumber) AS BankAccountNumber, ReadyToPayId, ReadyToPayDetailsId, VendorId,NonPOInvoiceId, CustomerCreditPaymentDetailId,VendorProformaInvoiceId  FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID') THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC, 
	 CASE WHEN (@SortOrder=1 and @SortColumn='STATUS') THEN Status END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentHold')  THEN PaymentHold END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='OriginalTotal')  THEN OriginalTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='RRTotal')  THEN RRTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceTotal')  THEN InvoiceTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DifferenceAmount')  THEN DifferenceAmount END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DiscountToken')  THEN DiscountToken END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentRef')  THEN PaymentRef END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DateProcessed')  THEN DateProcessed END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='EntryDate')  THEN EntryDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='InvociedDate')  THEN InvociedDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='BankName')  THEN BankName END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='BankAccountNumber')  THEN BankAccountNumber END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='NumberOfItems')  THEN NumberOfItems END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='CheckCrashed')  THEN CheckCrashed END ASC,
  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS') THEN Status END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentHold')  THEN PaymentHold END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='OriginalTotal')  THEN OriginalTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='RRTotal')  THEN RRTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceTotal')  THEN InvoiceTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DifferenceAmount')  THEN DifferenceAmount END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DiscountToken')  THEN DiscountToken END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentRef')  THEN PaymentRef END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DateProcessed')  THEN DateProcessed END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='EntryDate')  THEN EntryDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='InvociedDate')  THEN InvociedDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='BankName')  THEN BankName END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='BankAccountNumber')  THEN BankAccountNumber END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='NumberOfItems')  THEN NumberOfItems END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CheckCrashed')  THEN CheckCrashed END DESC

     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END  
    ELSE IF(@CurrentStatus = 'PartiallyPaid')  
    BEGIN  
    --;WITH Result AS (  
	--VendorPayment -ReceivingReconciliation DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal],[CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPaymentMade],
		[ReadyToPayId], [ReadyToPayDetailsId], [IsVoidedCheck], [VendorId], [PaymentMethodId], [CreatedDate], [ControlNumber], [LegalEntity])
		SELECT RRH.ReceivingReconciliationId,
			   RRH.InvoiceNum,
			   --RRH.[Status],
			   'Partially Paid' AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
			   ISNULL(Tab.CreditMemoAmount,0) AS CreditMemoUsed,
			   ISNULL(RemainingAmount,0) AS 'DifferenceAmount',  
			   VN.VendorName,
			   --ISNULL(VN.IsVendorOnHold,0) AS 'PaymentHold',
			   --ISNULL(RRC.IsInvoiceOnHold,0) AS 'PaymentHold',
			   CASE WHEN ISNULL(RRC.IsInvoiceOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
			   (Cast(DBO.ConvertUTCtoLocal(RRC.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
			   CASE WHEN IIF(TRY_CAST(RRC.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(RRC.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
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
			   (Cast(DBO.ConvertUTCtoLocal(tab.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME))AS CreatedDate,
			   ISNULL(TAB.ControlNumber,'') AS 'ControlNumber',
			   CASE WHEN ISNULL(RRH.[LastMSLevel],'') = '' THEN  ISNULL(le.Name, '') ELSE ISNULL(RRH.[LastMSLevel], '') END AS 'LegalEntity'
		  FROM [dbo].[VendorPaymentDetails] RRH WITH(NOLOCK) 
			   INNER JOIN [dbo].[ReceivingReconciliationHeader] RRC WITH(NOLOCK) ON RRH.[ReceivingReconciliationId] = RRC.[ReceivingReconciliationId]	
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId 
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
			   LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = RRC.LegalEntityId
			   OUTER APPLY (SELECT TOP 1 VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0)) ReadyToPaymentMade,
								SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
								SUM(ISNULL(VD.CreditMemoAmount,0)) AS CreditMemoAmount,
								MAX(PM.Description) AS PaymentMethod,CASE WHEN VD.IsVoidedCheck =1 THEN MAX(VD.CheckNumber) + ' (V)' ELSE MAX(VD.CheckNumber) END PaymentRef,VRTPDH.ReadyToPayId,VD.IsVoidedCheck,
								VD.PaymentMethodId,
								SRT.CreatedDate,
								VD.ControlNumber
		                    FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 	
								INNER JOIN [dbo].[ReceivingReconciliationHeader] RRC WITH(NOLOCK) ON VD.[ReceivingReconciliationId] = RRC.[ReceivingReconciliationId]	
								LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
							OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [dbo].[VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VD.ReadyToPayId =  SS.ReadyToPayId AND  VD.VendorId = SS.VendorId AND  VD.PaymentMethodId = SS.PaymentMethodId) AS SRT
								WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND IsVoidedCheck = 0 AND VD.IsGenerated = 1
								GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate,VD.ControlNumber
								ORDER BY VD.ReadyToPayDetailsId DESC
							) AS Tab
		  WHERE RRH.MasterCompanyId = @MasterCompanyId 
		  AND RRH.PaymentMade > 0 
		  AND RRH.RemainingAmount > 0 
		  AND ISNULL(RRH.NonPOInvoiceId, 0) = 0--WHERE StatusId=3  

	--UNION ALL
	--VendorPayment -NonPOInvoice DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal],[CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPaymentMade],
		[ReadyToPayId], [ReadyToPayDetailsId], [IsVoidedCheck], [VendorId], [PaymentMethodId], [CreatedDate],[ControlNumber], [LegalEntity], [NonPOInvoiceId])
		SELECT RRH.ReceivingReconciliationId,
			   RRH.InvoiceNum,
			   'Partially Paid' AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
			   ISNULL(Tab.CreditMemoAmount,0) AS CreditMemoUsed,
			   ISNULL(RemainingAmount,0) AS 'DifferenceAmount',  
			   VN.VendorName,
			   --0 AS 'PaymentHold',
			   'NO' AS 'PaymentHold',
			   (Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
			   CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
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
			   (Cast(DBO.ConvertUTCtoLocal(tab.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
			   ISNULL(TAB.ControlNumber,'') AS 'ControlNumber',
			   ISNULL(le.[Name], '') AS 'LegalEntity',
			   NPH.NonPOInvoiceId
		  FROM [dbo].[VendorPaymentDetails] RRH WITH(NOLOCK) 
			   INNER JOIN [dbo].[NonPOInvoiceHeader] NPH WITH(NOLOCK) ON RRH.NonPOInvoiceId = NPH.NonPOInvoiceId		
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId 
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
				LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON NPH.ManagementStructureId = ESS.[EntityStructureId]
			    LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			    LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = MSL1.ID
			   OUTER APPLY (SELECT TOP 1 VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0)) ReadyToPaymentMade,
							SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
							SUM(ISNULL(VD.CreditMemoAmount,0)) AS CreditMemoAmount,
							MAX(PM.Description) AS PaymentMethod,CASE WHEN VD.IsVoidedCheck =1 THEN MAX(VD.CheckNumber) + ' (V)' ELSE MAX(VD.CheckNumber) END PaymentRef,
							VRTPDH.ReadyToPayId,VD.IsVoidedCheck,
							VD.PaymentMethodId,
							SRT.CreatedDate,
							VD.ControlNumber
		                    FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
						OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [dbo].[VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VD.ReadyToPayId =  SS.ReadyToPayId AND  VD.VendorId = SS.VendorId AND  VD.PaymentMethodId = SS.PaymentMethodId) AS SRT
						WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId AND IsVoidedCheck = 0 AND VD.IsGenerated = 1
						GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate,VD.ControlNumber
						ORDER BY VD.ReadyToPayDetailsId DESC) AS Tab
		  WHERE RRH.MasterCompanyId = @MasterCompanyId 
		  AND RRH.PaymentMade > 0 
		  AND RRH.RemainingAmount > 0 
		  AND ISNULL(RRH.NonPOInvoiceId, 0) <> 0
		  AND NPH.StatusId = @NonPOInvoiceHeaderStatusId

	/********************START: Vendor Proforma Invoice *************************/
		  INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPaymentMade],
		[ReadyToPayId], [ReadyToPayDetailsId], [IsVoidedCheck], [VendorId], [PaymentMethodId], [CreatedDate],[ControlNumber], [LegalEntity], VendorProformaInvoiceId)
		SELECT RRH.ReceivingReconciliationId,
			   RRH.InvoiceNum,
			   'Partially Paid' AS [Status],
			   ISNULL(RRH.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(RRH.RRTotal,0) AS RRTotal,
			   ISNULL(RRH.PaymentMade,0) AS InvoiceTotal,
			   ISNULL(Tab.CreditMemoAmount,0) AS CreditMemoUsed,
			   ISNULL(RemainingAmount,0) AS 'DifferenceAmount',  
			   VN.VendorName,
			   --0 AS 'PaymentHold',
			   'NO' AS 'PaymentHold',
			   (Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
			   (Cast(DBO.ConvertUTCtoLocal(RRH.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
			   CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
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
			   CASE WHEN tab.IsGenerated = 1 THEN 0 ELSE ISNULL(Tab.ReadyToPaymentMade,0) END AS 'ReadyToPaymentMade',
			   Tab.ReadyToPayId,
			   Tab.ReadyToPayDetailsId,
			   Tab.IsVoidedCheck,
			   RRH.VendorId,
			   tab.PaymentMethodId,
			   (Cast(DBO.ConvertUTCtoLocal(tab.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
			   ISNULL(TAB.ControlNumber,'') AS 'ControlNumber',
			   ISNULL(le.[Name], '') AS 'LegalEntity',
			   NPH.VendorProformaInvoiceId VendorProformaInvoiceId
		  FROM [dbo].[VendorPaymentDetails] RRH WITH(NOLOCK) 
			   INNER JOIN [dbo].[VendorProformaInvoiceHeader] NPH WITH(NOLOCK) ON RRH.VendorProformaInvoiceId = NPH.VendorProformaInvoiceId		
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RRH.VendorId = VN.VendorId 
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
				LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON NPH.ManagementStructureId = ESS.[EntityStructureId]
			    LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			    LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = MSL1.ID
			   OUTER APPLY (SELECT TOP 1 VD.VendorPaymentDetailsId,ReadyToPayDetailsId,ISNULL(VD.PaymentMade,0) ReadyToPaymentMade,
							0 DiscountToken,
							ISNULL(VD.CreditMemoAmount,0) AS CreditMemoAmount,
							PM.Description AS PaymentMethod,
							CASE WHEN VD.IsVoidedCheck =1 THEN VD.CheckNumber + ' (V)' ELSE VD.CheckNumber END PaymentRef,
							VRTPDH.ReadyToPayId,
							VD.IsVoidedCheck,
							VD.PaymentMethodId,
							SRT.CreatedDate,
							VD.ControlNumber,
							ISNULL(VD.IsGenerated,0) IsGenerated
		                    FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
				OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [dbo].[VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VD.ReadyToPayId =  SS.ReadyToPayId AND  VD.VendorId = SS.VendorId AND  VD.PaymentMethodId = SS.PaymentMethodId) AS SRT
				WHERE ISNULL(VD.VendorPaymentDetailsId,0) = RRH.VendorPaymentDetailsId   AND IsVoidedCheck = 0 AND  RRH.VendorProformaInvoiceId = VD.VendorProformaInvoiceId  AND VD.IsGenerated = 1
				ORDER BY VD.ReadyToPayDetailsId DESC) AS Tab
		 
		 WHERE RRH.MasterCompanyId = @MasterCompanyId 
		  AND RRH.PaymentMade > 0 
		  AND RRH.RemainingAmount > 0 
		  AND ISNULL(RRH.VendorProformaInvoiceId, 0) <> 0
		  AND NPH.StatusId = @ProformaInvoicePostedStatusId
		/********************END: Vendor Proforma Invoice *************************/

		--VendorPayment -CustomerCreditPayment DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal],[CreditMemoUsed], [DifferenceAmount], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [DueDate], [DaysPastDue], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPaymentMade],
		[ReadyToPayId], [ReadyToPayDetailsId], [IsVoidedCheck], [VendorId], [PaymentMethodId], [CreatedDate], [ControlNumber], [LegalEntity], [CustomerCreditPaymentDetailId])
		SELECT VPD.ReceivingReconciliationId,
			   VPD.InvoiceNum,
			   'Partially Paid' AS [Status],
			   ISNULL(VPD.InvoiceTotal,0) AS OriginalTotal,
			   ISNULL(VPD.RRTotal,0) AS RRTotal,
			   ISNULL(VPD.PaymentMade,0) AS InvoiceTotal,
			   ISNULL(Tab.CreditMemoAmount,0) AS CreditMemoUsed,
			   ISNULL(VPD.RemainingAmount,0) AS 'DifferenceAmount',  
			   VN.VendorName,
			   --0 AS 'PaymentHold',
			   'NO' AS 'PaymentHold',
			   (Cast(DBO.ConvertUTCtoLocal(CCPD.ProcessedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
			   (Cast(DBO.ConvertUTCtoLocal(VPD.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',
			   CASE WHEN IIF(TRY_CAST(CCPD.ProcessedDate AS DATETIME) IS NULL, 0, 1 ) = 1
				     THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(CCPD.ProcessedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
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
			   (Cast(DBO.ConvertUTCtoLocal(tab.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
			   ISNULL(TAB.ControlNumber,'') AS 'ControlNumber',
			   ISNULL(le.[Name], '') AS 'LegalEntity',			   
			   CCPD.CustomerCreditPaymentDetailId
		  FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK) 
			   INNER JOIN [dbo].[CustomerCreditPaymentDetail] CCPD WITH(NOLOCK) ON VPD.CustomerCreditPaymentDetailId = CCPD.CustomerCreditPaymentDetailId		
			   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VPD.VendorId = VN.VendorId 
			   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = VN.CreditTermsId
				LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON CCPD.ManagementStructureId = ESS.[EntityStructureId]
			    LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			    LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = MSL1.ID
			   OUTER APPLY (SELECT TOP 1 VD.VendorPaymentDetailsId,ReadyToPayDetailsId,SUM(ISNULL(VD.PaymentMade,0)) ReadyToPaymentMade,
							SUM(ISNULL(VD.DiscountToken,0)) DiscountToken,
							SUM(ISNULL(VD.CreditMemoAmount,0)) AS CreditMemoAmount,
							MAX(PM.Description) AS PaymentMethod,CASE WHEN VD.IsVoidedCheck =1 THEN MAX(VD.CheckNumber) + ' (V)' ELSE MAX(VD.CheckNumber) END PaymentRef,
							VRTPDH.ReadyToPayId,
							VD.IsVoidedCheck,VD.PaymentMethodId,
							SRT.CreatedDate,
							VD.ControlNumber
		                    FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
								LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VD.PaymentMethodId
								LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VD.ReadyToPayId = VRTPDH.ReadyToPayId
								OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VD.ReadyToPayId =  SS.ReadyToPayId AND  VD.VendorId = SS.VendorId AND  VD.PaymentMethodId = SS.PaymentMethodId) AS SRT
				WHERE ISNULL(VD.VendorPaymentDetailsId,0) = VPD.VendorPaymentDetailsId AND VD.CheckNumber IS NULL AND IsVoidedCheck = 0 AND VD.IsGenerated = 1
				GROUP BY VD.VendorPaymentDetailsId,VRTPDH.ReadyToPayId,ReadyToPayDetailsId,VD.IsVoidedCheck,VD.PaymentMethodId,SRT.CreatedDate,VD.ControlNumber
				ORDER BY VD.ReadyToPayDetailsId DESC) AS Tab
		  WHERE VPD.MasterCompanyId = @MasterCompanyId 
		  AND VPD.PaymentMade > 0 
		  AND VPD.RemainingAmount > 0 
		  AND ISNULL(VPD.NonPOInvoiceId, 0) = 0
		  AND ISNULL(VPD.CustomerCreditPaymentDetailId, 0) <> 0

    --),  
    ;WITH FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,CreditMemoUsed,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate,ReadyToPaymentMade,DueDate,DaysPastDue,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,DiscountToken,BankName,BankAccountNumber,ReadyToPayId,ReadyToPayDetailsId,IsVoidedCheck,VendorId,PaymentMethodId,CreatedDate,ControlNumber,LegalEntity,NonPOInvoiceId, CustomerCreditPaymentDetailId,VendorProformaInvoiceId FROM #TEMPVendorPaymentListRecords  
    WHERE (  
	   (@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR   
       ([Status] LIKE '%' +@GlobalFilter+'%') OR  
       (InvociedDate LIKE '%' +@GlobalFilter+'%') OR  
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR  
	   (DaysPastDue LIKE '%' +@GlobalFilter+'%') OR  
       (OriginalTotal LIKE '%' +@GlobalFilter+'%') OR  
       (RRTotal LIKE '%'+@GlobalFilter+'%') OR  
       (InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR	
	   (CreditMemoUsed LIKE '%' +@GlobalFilter+'%') OR	
       (VendorName LIKE '%' +@GlobalFilter+'%') OR
	   (LegalEntity LIKE '%' +@GlobalFilter+'%') OR
	   (ReadyToPaymentMade LIKE '%' +@GlobalFilter+'%') OR
	   (DiscountToken LIKE '%' +@GlobalFilter+'%') OR
	   (DifferenceAmount LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentMethod LIKE '%' +@GlobalFilter+'%') OR
	   (PaymentRef LIKE '%' +@GlobalFilter+'%') OR
	   (ControlNumber LIKE '%' +@GlobalFilter+'%')
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
	   (ISNULL(@CreditMemoUsed,'') ='' OR CreditMemoUsed LIKE '%'+ @CreditMemoUsed+'%') AND  
       (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%') AND
	   (ISNULL(@LegalEntity,'') ='' OR [LegalEntity] LIKE '%'+ @LegalEntity +'%') AND
	   (ISNULL(@Status,'') ='' OR [Status] LIKE '%'+ @Status +'%') AND
	   (ISNULL(@PaymentHold,'') ='' OR PaymentHold LIKE '%' + @PaymentHold + '%') AND
	   (ISNULL(@ReadyToPaymentMade,'') ='' OR ReadyToPaymentMade LIKE '%'+ @ReadyToPaymentMade+'%') AND
	   (ISNULL(@DiscountToken,'') ='' OR DiscountToken LIKE '%'+ @DiscountToken+'%') AND
	   (ISNULL(@DifferenceAmount,'') ='' OR DifferenceAmount LIKE '%'+ @DifferenceAmount+'%') AND
	   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND
	   (ISNULL(@PaymentRef,'') ='' OR PaymentRef LIKE '%'+ @PaymentRef+'%') AND
	   (ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%'+ @ControlNumber+'%'))    
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, UPPER(InvoiceNum) AS InvoiceNum, UPPER([Status]) AS Status, OriginalTotal, RRTotal, InvoiceTotal,CreditMemoUsed, DifferenceAmount, UPPER(VendorName) AS VendorName, 
	  PaymentHold, InvociedDate, EntryDate, ReadyToPaymentMade, DueDate, DaysPastDue, UPPER(PaymentMethod) AS PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, 
	  NumberOfItems, DiscountToken, UPPER(BankName) AS BankName, UPPER(BankAccountNumber) AS BankAccountNumber,ReadyToPayId,ReadyToPayDetailsId,IsVoidedCheck,VendorId,PaymentMethodId,CreatedDate,
	  UPPER(ControlNumber) AS ControlNumber, UPPER(LegalEntity) AS LegalEntity,NonPOInvoiceId, CustomerCreditPaymentDetailId,VendorProformaInvoiceId FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC,  
	 CASE WHEN (@SortOrder=1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC,  
	 CASE WHEN (@SortOrder=1 and @SortColumn='STATUS') THEN Status END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DaysPastDue')  THEN DaysPastDue END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentHold')  THEN PaymentHold END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='OriginalTotal')  THEN OriginalTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='RRTotal')  THEN RRTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceTotal')  THEN InvoiceTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='CREDITMEMOUSED')  THEN CreditMemoUsed END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DifferenceAmount')  THEN DifferenceAmount END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DiscountToken')  THEN DiscountToken END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='ReadyToPaymentMade')  THEN ReadyToPaymentMade END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentRef')  THEN PaymentRef END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DateProcessed')  THEN DateProcessed END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='EntryDate')  THEN EntryDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='InvociedDate')  THEN InvociedDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='BankName')  THEN BankName END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='BankAccountNumber')  THEN BankAccountNumber END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='LegalEntity')  THEN LegalEntity END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DueDate')  THEN DueDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='NumberOfItems')  THEN NumberOfItems END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='CheckCrashed')  THEN CheckCrashed END ASC,
  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS') THEN Status END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DaysPastDue')  THEN DaysPastDue END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentHold')  THEN PaymentHold END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='OriginalTotal')  THEN OriginalTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='RRTotal')  THEN RRTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceTotal')  THEN InvoiceTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CREDITMEMOUSED')  THEN CreditMemoUsed END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DifferenceAmount')  THEN DifferenceAmount END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DiscountToken')  THEN DiscountToken END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='ReadyToPaymentMade')  THEN ReadyToPaymentMade END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentRef')  THEN PaymentRef END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DateProcessed')  THEN DateProcessed END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='EntryDate')  THEN EntryDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='InvociedDate')  THEN InvociedDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='BankName')  THEN BankName END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='BankAccountNumber')  THEN BankAccountNumber END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='LegalEntity')  THEN LegalEntity END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DueDate')  THEN DueDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='NumberOfItems')  THEN NumberOfItems END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CheckCrashed')  THEN CheckCrashed END DESC
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END 
	ELSE IF(@CurrentStatus = 'PrintCheck')  
    BEGIN  
    --;With Result AS (  
	--VendorPayment -ReceivingReconciliation DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorId], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPayId], [IsVoidedCheck], [PaymentMethodId], [CreatedDate], [ReadyToPayDetailsId],[ControlNumber], [LegalEntity])
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
		CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
		(Cast(DBO.ConvertUTCtoLocal(CheckDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
		(Cast(DBO.ConvertUTCtoLocal(CheckDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',		
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
		,(Cast(DBO.ConvertUTCtoLocal(SRT.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate
		,VRTPD.ReadyToPayDetailsId
		,VRTPD.ControlNumber
		,CASE WHEN ISNULL(RRH.[LastMSLevel],'') = '' THEN  ISNULL(le.Name, '') ELSE ISNULL(RRH.[LastMSLevel], '') END AS 'LegalEntity'
		FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
		INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
		 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.ReceivingReconciliationId = RRH.ReceivingReconciliationId
		 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		 LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRTPDH.BankId		
		 LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId
		 LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = VRTPDH.LegalEntityId
		 OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VRTPD.ReadyToPayId =  SS.ReadyToPayId AND  VRTPD.VendorId = SS.VendorId AND  VRTPD.PaymentMethodId = SS.PaymentMethodId) AS SRT
	  WHERE RRH.MasterCompanyId = @MasterCompanyId 
	     AND VRTPD.PaymentMethodId = @Check
		 AND ISNULL(VRTPD.IsCheckPrinted,0) = 0
		 AND ISNULL(VRTPD.IsGenerated,0) = 1
		 AND ISNULL(VRTPD.ReceivingReconciliationId,0) >0 
		 AND RRH.StatusId IN(SELECT Item FROM dbo.SplitString(@PrintFullStatusId, ','))
	     --AND (RemainingAmount <= 0  OR IsVoidedCheck = 1) 
		 AND ISNULL(VRTPD.CreditMemoHeaderId, 0) = 0 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0	AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) = 0	
		GROUP BY VRTPD.CheckNumber,lebl.BankName,lebl.BankAccountNumber,VRTPDH.ReadyToPayId,
				 RRH.[Status],VN.IsVendorOnHold,CheckDate,VN.VendorName,IsVoidedCheck,
				 VRTPD.VendorId,VRTPD.PaymentMethodId,SRT.CreatedDate,VRTPD.ReadyToPayDetailsId,VRTPD.AmountDue,VRTPD.ControlNumber,le.[Name],RRH.[LastMSLevel]
				
		-- UNION ALL
		--VendorPayment -CreditMemo DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorId], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPayId], [IsVoidedCheck], [PaymentMethodId], [CreatedDate], [ReadyToPayDetailsId], [ControlNumber], [LegalEntity])
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
		CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
		(Cast(DBO.ConvertUTCtoLocal(CheckDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
		(Cast(DBO.ConvertUTCtoLocal(CheckDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',		
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
		,(Cast(DBO.ConvertUTCtoLocal(SRT.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate
		,VRTPD.ReadyToPayDetailsId
		,VRTPD.ControlNumber
		,ISNULL(le.[Name], '') AS 'LegalEntity'
		FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
		INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
		 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.CreditMemoHeaderId = RRH.CreditMemoHeaderId
		 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		 LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRTPDH.BankId		
		 LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId
		 LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = VRTPDH.LegalEntityId
		 OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VRTPD.ReadyToPayId =  SS.ReadyToPayId AND  VRTPD.VendorId = SS.VendorId AND  VRTPD.PaymentMethodId = SS.PaymentMethodId) AS SRT
	  WHERE RRH.MasterCompanyId = @MasterCompanyId 
	     AND VRTPD.PaymentMethodId = @Check
		 AND ISNULL(VRTPD.IsCheckPrinted,0) = 0
		 AND ISNULL(VRTPD.IsGenerated,0) = 1
		  AND RRH.StatusId IN(SELECT Item FROM dbo.SplitString(@PrintFullStatusId, ','))
	     --AND (RemainingAmount <= 0  OR IsVoidedCheck = 1) 
		 AND ISNULL(VRTPD.CreditMemoHeaderId, 0) <> 0 AND ISNULL(RRH.CreditMemoHeaderId, 0) <> 0 
		 AND ISNULL(RRH.NonPOInvoiceId, 0) = 0 AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) = 0		
		GROUP BY VRTPD.CheckNumber,lebl.BankName,lebl.BankAccountNumber,VRTPDH.ReadyToPayId,
				 RRH.[Status],VN.IsVendorOnHold,CheckDate,VN.VendorName,IsVoidedCheck,
				 VRTPD.VendorId,VRTPD.PaymentMethodId,SRT.CreatedDate,VRTPD.ReadyToPayDetailsId,VRTPD.AmountDue,VRTPD.ControlNumber,le.[Name]

	 --UNION ALL
	 --VendorPayment -NonPO DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorId], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPayId], [IsVoidedCheck], [PaymentMethodId], [CreatedDate], [ReadyToPayDetailsId], [ControlNumber], [LegalEntity],[NonPOInvoiceId])
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
		CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
		(Cast(DBO.ConvertUTCtoLocal(CheckDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
		(Cast(DBO.ConvertUTCtoLocal(CheckDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',		
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
		,(Cast(DBO.ConvertUTCtoLocal(SRT.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate
		,VRTPD.ReadyToPayDetailsId
		,VRTPD.ControlNumber
		,ISNULL(le.[Name], '') AS 'LegalEntity'
		,RRH.NonPOInvoiceId
		FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
		INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
		 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.NonPOInvoiceId = RRH.NonPOInvoiceId
		 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		 LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRTPDH.BankId		
		 LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId	
		 LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = VRTPDH.LegalEntityId
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
				 VRTPD.VendorId,VRTPD.PaymentMethodId,SRT.CreatedDate,VRTPD.ReadyToPayDetailsId,VRTPD.AmountDue,VRTPD.ControlNumber,le.[Name],RRH.NonPOInvoiceId

		--VendorPayment -CustomerCreditPayment DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorId], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPayId], [IsVoidedCheck], [PaymentMethodId], [CreatedDate], [ReadyToPayDetailsId], [ControlNumber], [LegalEntity],[CustomerCreditPaymentDetailId])
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
		CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
		(Cast(DBO.ConvertUTCtoLocal(CheckDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
		(Cast(DBO.ConvertUTCtoLocal(CheckDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',		
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
		,(Cast(DBO.ConvertUTCtoLocal(SRT.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate
		,VRTPD.ReadyToPayDetailsId
		,VRTPD.ControlNumber
		,ISNULL(le.[Name], '') AS 'LegalEntity'
		,RRH.CustomerCreditPaymentDetailId
		FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
		INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
		 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.CustomerCreditPaymentDetailId = RRH.CustomerCreditPaymentDetailId
		 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		 LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRTPDH.BankId		
		 LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId
		 LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = VRTPDH.LegalEntityId
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
				 VRTPD.VendorId,VRTPD.PaymentMethodId,SRT.CreatedDate,VRTPD.ReadyToPayDetailsId,VRTPD.AmountDue,VRTPD.ControlNumber,le.[Name],RRH.CustomerCreditPaymentDetailId

	/********************START: Vendor Proforma Invoice *************************/
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorId], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPayId], [IsVoidedCheck], [PaymentMethodId], [CreatedDate], [ReadyToPayDetailsId], [ControlNumber], [LegalEntity],VendorProformaInvoiceId)
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
		CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
		(Cast(DBO.ConvertUTCtoLocal(CheckDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
		(Cast(DBO.ConvertUTCtoLocal(CheckDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',		
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
		,(Cast(DBO.ConvertUTCtoLocal(SRT.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate 
		,VRTPD.ReadyToPayDetailsId
		,VRTPD.ControlNumber
		,ISNULL(le.[Name], '') AS 'LegalEntity'
		,RRH.VendorProformaInvoiceId
		FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
		INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
		 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRTPD.VendorProformaInvoiceId = RRH.VendorProformaInvoiceId
		 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
		 LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRTPDH.BankId		
		 LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId	
		 LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = VRTPDH.LegalEntityId
		 OUTER APPLY (SELECT TOP 1 SS.CreatedDate FROM [VendorReadyToPayDetails] SS WITH(NOLOCK) WHERE VRTPD.ReadyToPayId =  SS.ReadyToPayId AND  VRTPD.VendorId = SS.VendorId AND  VRTPD.PaymentMethodId = SS.PaymentMethodId) AS SRT
	  WHERE RRH.MasterCompanyId = @MasterCompanyId 
	     AND VRTPD.PaymentMethodId = @Check
		 AND ISNULL(VRTPD.IsCheckPrinted,0) = 0
		 AND ISNULL(VRTPD.IsGenerated,0) = 1
		AND RRH.StatusId IN(SELECT Item FROM dbo.SplitString(@StatusId, ','))
		 AND ISNULL(VRTPD.CreditMemoHeaderId, 0) = 0 AND ISNULL(RRH.VendorProformaInvoiceId, 0) <> 0 AND ISNULL(RRH.CustomerCreditPaymentDetailId, 0) = 0		
		GROUP BY VRTPD.CheckNumber,lebl.BankName,lebl.BankAccountNumber,VRTPDH.ReadyToPayId,
				 RRH.[Status],VN.IsVendorOnHold,CheckDate,VN.VendorName,IsVoidedCheck,
				 VRTPD.VendorId,VRTPD.PaymentMethodId,SRT.CreatedDate,VRTPD.ReadyToPayDetailsId,VRTPD.AmountDue,VRTPD.ControlNumber,le.[Name],RRH.VendorProformaInvoiceId

	 /********************END: Vendor Proforma Invoice *************************/
	--),  
    ;WITH FinalResult AS (  
    SELECT ReceivingReconciliationId, InvoiceNum, [Status], OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, VendorName, PaymentHold, InvociedDate,EntryDate,DiscountToken,  
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,BankName,BankAccountNumber,ReadyToPayId,IsVoidedCheck,VendorId,PaymentMethodId,CreatedDate,ReadyToPayDetailsId,ControlNumber,LegalEntity,NonPOInvoiceId, CustomerCreditPaymentDetailId,VendorProformaInvoiceId FROM #TEMPVendorPaymentListRecords  
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
       (VendorName LIKE '%' +@GlobalFilter+'%')   OR 
	   (LegalEntity LIKE '%' +@GlobalFilter+'%') OR
       (ControlNumber LIKE '%' +@GlobalFilter+'%')  
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
	   (ISNULL(@LegalEntity,'') ='' OR [LegalEntity] LIKE '%'+ @LegalEntity +'%') AND
	   (ISNULL(@Status,'') ='' OR [Status] LIKE '%'+ @Status +'%') AND
	   (ISNULL(@PaymentHold,'') ='' OR PaymentHold LIKE '%' + @PaymentHold + '%') AND
	   (ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%'+ @ControlNumber+'%'))     
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, UPPER(InvoiceNum) AS InvoiceNum, UPPER([Status]) AS Status, OriginalTotal, RRTotal, InvoiceTotal,DifferenceAmount, UPPER(VendorName) AS VendorName, 
	  PaymentHold, InvociedDate, EntryDate, UPPER(PaymentMethod) AS PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems,DiscountToken,
	  UPPER(BankName) AS BankName, UPPER(BankAccountNumber) AS BankAccountNumber, ReadyToPayId, IsVoidedCheck, VendorId, PaymentMethodId, CreatedDate, ReadyToPayDetailsId,
	  UPPER(ControlNumber) AS ControlNumber, UPPER(LegalEntity) AS LegalEntity,NonPOInvoiceId, CustomerCreditPaymentDetailId,VendorProformaInvoiceId FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC,  
	 CASE WHEN (@SortOrder=1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC, 
	 CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN Status END ASC, 
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentHold')  THEN PaymentHold END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='OriginalTotal')  THEN OriginalTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='RRTotal')  THEN RRTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceTotal')  THEN InvoiceTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DifferenceAmount')  THEN DifferenceAmount END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DiscountToken')  THEN DiscountToken END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentRef')  THEN PaymentRef END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DateProcessed')  THEN DateProcessed END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='EntryDate')  THEN EntryDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='InvociedDate')  THEN InvociedDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='BankName')  THEN BankName END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='BankAccountNumber')  THEN BankAccountNumber END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='LegalEntity')  THEN LegalEntity END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='NumberOfItems')  THEN NumberOfItems END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='CheckCrashed')  THEN CheckCrashed END ASC,
	  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC,  	 
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedDate')  THEN CreatedDate END DESC ,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='Status')  THEN Status END ASC, 
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentHold')  THEN PaymentHold END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='OriginalTotal')  THEN OriginalTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='RRTotal')  THEN RRTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceTotal')  THEN InvoiceTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DifferenceAmount')  THEN DifferenceAmount END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DiscountToken')  THEN DiscountToken END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentRef')  THEN PaymentRef END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DateProcessed')  THEN DateProcessed END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='EntryDate')  THEN EntryDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='InvociedDate')  THEN InvociedDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='BankName')  THEN BankName END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='BankAccountNumber')  THEN BankAccountNumber END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='LegalEntity')  THEN LegalEntity END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='NumberOfItems')  THEN NumberOfItems END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CheckCrashed')  THEN CheckCrashed END DESC

		OFFSET @RecordFrom ROWS   
		FETCH NEXT @PageSize ROWS ONLY  
    END 
    ELSE IF(@CurrentStatus = 'PaidinFull')  
    BEGIN  
    --;With Result AS (  
	--VendorPayment DETAILS
		INSERT INTO #TEMPVendorPaymentListRecords([ReceivingReconciliationId], [InvoiceNum], [Status], [OriginalTotal], [RRTotal], [InvoiceTotal], [DifferenceAmount], [VendorId], [VendorName], [PaymentHold],
		[InvociedDate], [EntryDate], [PaymentMethod], [PaymentRef], [DateProcessed], [CheckCrashed], [DiscountToken], [BankName], [BankAccountNumber], [ReadyToPayId], [IsVoidedCheck], [PaymentMethodId], [CreatedDate], [ReadyToPayDetailsId],[ControlNumber], [LegalEntity])
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
		CASE WHEN ISNULL(VN.IsVendorOnHold, 0) = 1 THEN 'YES' ELSE 'NO' END AS 'PaymentHold',
		(Cast(DBO.ConvertUTCtoLocal(CheckDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvociedDate',
		(Cast(DBO.ConvertUTCtoLocal(CheckDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'EntryDate',		
		'' AS 'PaymentMethod',
		CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS 'PaymentRef',
		'' AS 'DateProcessed',
		'' AS 'CheckCrashed',
		0 AS 'DiscountToken'
		,CASE WHEN VRTPD.PaymentMethodId = @Check THEN lebl.BankName 
		      WHEN VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.BankName 
			  WHEN VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBank 
			  WHEN VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.BankName 
			  WHEN VRTPD.PaymentMethodId = @CreditCard THEN lebl.BankName END AS BankName
		,CASE WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber + ' (V)' 
			  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.AccountNumber + ' (V)' 
			  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBankAccount + ' (V)' 
			  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.AccountNumber + ' (V)' 
			  WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @CreditCard THEN lebl.BankAccountNumber + ' (V)' 
			  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber 
			  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @DomesticWire THEN DWPL.AccountNumber 
			  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @InternationalWire THEN IWPL.BeneficiaryBankAccount 
			  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @ACHTransfer THEN DWPL.AccountNumber
			  WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @CreditCard THEN lebl.BankAccountNumber END AS 'BankAccountNumber'
		,VRTPDH.ReadyToPayId
		,VRTPD.IsVoidedCheck
		,VRTPD.PaymentMethodId
		,(Cast(DBO.ConvertUTCtoLocal(SRT.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate
		,VRTPD.ReadyToPayDetailsId
		,VRTPD.ControlNumber
		,CASE WHEN ISNULL(RRH.[LastMSLevel],'') = '' THEN  ISNULL(le.Name, '') ELSE ISNULL(RRH.[LastMSLevel], '') END AS 'LegalEntity'
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
		 LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON le.LegalEntityId = VRTPDH.LegalEntityId
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
				  DWPL.BankName,IWPL.BeneficiaryBank,VRTPD.ReadyToPayDetailsId,VRTPD.ControlNumber, le.[Name],RRH.[LastMSLevel]

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
      PaymentMethod, PaymentRef, DateProcessed, CheckCrashed,BankName,BankAccountNumber,ReadyToPayId,IsVoidedCheck,VendorId,PaymentMethodId,CreatedDate,ReadyToPayDetailsId,ControlNumber,LegalEntity FROM #TEMPVendorPaymentListRecords  
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
       (VendorName LIKE '%' +@GlobalFilter+'%')  OR 
	   (LegalEntity LIKE '%' +@GlobalFilter+'%') OR 
       (ControlNumber LIKE '%' +@GlobalFilter+'%') 
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
	   (ISNULL(@LegalEntity,'') ='' OR [LegalEntity] LIKE '%'+ @LegalEntity +'%') AND
	   (ISNULL(@Status,'') ='' OR [Status] LIKE '%'+ @Status +'%') AND
	   (ISNULL(@PaymentHold,'') ='' OR PaymentHold LIKE '%' + @PaymentHold + '%') AND
	   (ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%'+ @ControlNumber+'%'))   
       )),  
      ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
      SELECT ReceivingReconciliationId, UPPER(InvoiceNum) AS InvoiceNum, UPPER([Status]) AS Status, OriginalTotal, RRTotal, InvoiceTotal, DifferenceAmount, UPPER(VendorName) AS VendorName, 
	  PaymentHold, InvociedDate, EntryDate,  UPPER(PaymentMethod) AS PaymentMethod, PaymentRef, DateProcessed, CheckCrashed, NumberOfItems,DiscountToken,
	  UPPER(BankName) AS BankName, UPPER(BankAccountNumber) AS BankAccountNumber, ReadyToPayId, IsVoidedCheck, VendorId, PaymentMethodId, CreatedDate, ReadyToPayDetailsId,
	  UPPER(ControlNumber) AS ControlNumber, UPPER(LegalEntity) AS LegalEntity FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC,  
	 CASE WHEN (@SortOrder=1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC,  
	 CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN Status END ASC, 
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentHold')  THEN PaymentHold END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='OriginalTotal')  THEN OriginalTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='RRTotal')  THEN RRTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceTotal')  THEN InvoiceTotal END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DifferenceAmount')  THEN DifferenceAmount END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DiscountToken')  THEN DiscountToken END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentRef')  THEN PaymentRef END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DateProcessed')  THEN DateProcessed END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='EntryDate')  THEN EntryDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='InvociedDate')  THEN InvociedDate END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='BankName')  THEN BankName END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='BankAccountNumber')  THEN BankAccountNumber END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='LegalEntity')  THEN LegalEntity END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='NumberOfItems')  THEN NumberOfItems END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='CheckCrashed')  THEN CheckCrashed END ASC,
	  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END DESC,  	 
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='Status')  THEN Status END DESC, 
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentHold')  THEN PaymentHold END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='OriginalTotal')  THEN OriginalTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='RRTotal')  THEN RRTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceTotal')  THEN InvoiceTotal END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DifferenceAmount')  THEN DifferenceAmount END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DiscountToken')  THEN DiscountToken END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentRef')  THEN PaymentRef END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DateProcessed')  THEN DateProcessed END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='EntryDate')  THEN EntryDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='InvociedDate')  THEN InvociedDate END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='BankName')  THEN BankName END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='BankAccountNumber')  THEN BankAccountNumber END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='LegalEntity')  THEN LegalEntity END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='NumberOfItems')  THEN NumberOfItems END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CheckCrashed')  THEN CheckCrashed END DESC

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