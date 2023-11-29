/*************************************************************           
 ** File:   [VendorPositivePayExportList]           
 ** Author:   MOIN BLOCH
 ** Description: This stored procedure is used Get Vendor Positive Pay Export List
 ** Purpose:         
 ** Date:   07/11/2023
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/11/2023   MOIN BLOCH    CREATED 
	2    07/19/2023   Satish Gohil  Modify(Credit card Payment detail added)
	3    07/21/2023   MOIN BLOCH    Added StartDate And EndDate Filter
	4    08/01/2023   MOIN BLOCH    International Wire Payment CHANGES
	5    08/03/2023   MOIN BLOCH    Domestic wire Payment Bug
	6    22/08/2023   MOIN BLOCH    Set Order by Check date and Resolved Dublicate entry issue
	7    31/08/2023   MOIN BLOCH    Set Order by Check Number 

--EXEC VendorPositivePayExportList 
**************************************************************/
CREATE   PROCEDURE [dbo].[VendorPositivePayExportList]
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
@ReadyToPayIds varchar(250) = NULL,
@VendorIds varchar(250) = NULL,
@StartDate datetime = NULL,  
@EndDate datetime = NULL
AS  
BEGIN 
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY         
    DECLARE @RecordFrom INT;  
	DECLARE @CheckPaymentMethodId INT;
	DECLARE @DomesticWirePaymentMethodId INT;
	DECLARE @InternationalWirePaymentMethodId INT;
	DECLARE @CreditCardPaymentMethodId INT;
	DECLARE @ACHTransferPaymentMethodId INT;
		
    SET @RecordFrom = (@PageNumber-1) * @PageSize;      
    IF @SortColumn IS NULL  
    BEGIN  
		SET @SortColumn = UPPER('ReadyToPayId')  
    END   
    ELSE  
    BEGIN   
		SET @SortColumn = UPPER('ReadyToPayId')  
    End  
	IF(@ReadyToPayIds = '')
	BEGIN
		SET @ReadyToPayIds = NULL;
	END
	IF(@VendorIds = '')
	BEGIN
		SET @VendorIds = NULL;
	END	
	IF(@StartDate = '')
	BEGIN   
		SET @StartDate = NULL;
    END

	SELECT @CheckPaymentMethodId = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod]  WITH(NOLOCK) WHERE [Description] ='Check';
	SELECT @DomesticWirePaymentMethodId = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod]  WITH(NOLOCK) WHERE [Description] ='Domestic Wire';
	SELECT @InternationalWirePaymentMethodId = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod]  WITH(NOLOCK) WHERE [Description] ='International Wire';
	SELECT @CreditCardPaymentMethodId = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod]  WITH(NOLOCK) WHERE [Description] ='Credit Card';
	SELECT @ACHTransferPaymentMethodId = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod]  WITH(NOLOCK)  WHERE [Description] ='ACH Transfer';

	IF(@PaymentMethodId = @CheckPaymentMethodId)
    BEGIN
		 SET @SortColumn = UPPER('CHECKNUMBER')  

		;WITH Result AS (  
		 SELECT 0 AS ReceivingReconciliationId	 
			   ,VRP.IsVoidedCheck
			   ,CASE WHEN VRP.IsVoidedCheck = 1 THEN 'V' ELSE ' ' END AS VoidedCheck
			   ,CASE WHEN VRP.IsVoidedCheck = 1 THEN lebl.BankAccountNumber ELSE lebl.BankAccountNumber END AS VendorBankAccountNumber
			   ,CASE WHEN LEN(UPPER(lebl.BankName)) > 35 then LEFT(UPPER(lebl.BankName), 35) ELSE  UPPER(lebl.BankName) END AS VendorBankName
			   ,CASE WHEN  LEN(VRP.CheckNumber) = 1 THEN '000000000'+ VRP.CheckNumber
			         WHEN  LEN(VRP.CheckNumber) = 2 THEN '00000000'+ VRP.CheckNumber
					 WHEN  LEN(VRP.CheckNumber) = 3 THEN '0000000'+ VRP.CheckNumber
					 WHEN  LEN(VRP.CheckNumber) = 4 THEN '000000'+ VRP.CheckNumber
					 WHEN  LEN(VRP.CheckNumber) = 5 THEN '00000'+ VRP.CheckNumber
					 WHEN  LEN(VRP.CheckNumber) = 6 THEN '0000'+ VRP.CheckNumber
					 WHEN  LEN(VRP.CheckNumber) = 7 THEN '000'+ VRP.CheckNumber
					 WHEN  LEN(VRP.CheckNumber) = 8 THEN '00'+ VRP.CheckNumber
					 WHEN  LEN(VRP.CheckNumber) = 9 THEN '0'+ VRP.CheckNumber
					 WHEN  LEN(VRP.CheckNumber) = 10 THEN VRP.CheckNumber
					 ELSE  VRP.CheckNumber			   
			    END AS InvoiceNum
	 		   ,SUM(ISNULL(VRP.PaymentMade,0)) AS PaymentAmount	
			   ,CAST(ISNULL(VRP.CheckDate, NULL) AS DATE) AS 'Date'
			   ,VN.VendorName
			   ,VRP.ReadyToPayId
		FROM [dbo].[VendorReadyToPayDetails] VRP  WITH(NOLOCK)
				INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRP.VendorId = VN.VendorId
				LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRP.[ReceivingReconciliationId] = RRH.[ReceivingReconciliationId]
				LEFT JOIN [dbo].[VendorReadyToPayHeader] VRH WITH(NOLOCK) ON VRP.ReadyToPayId = VRH.ReadyToPayId
				LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRH.BankId			 
		WHERE (VRP.[MasterCompanyId] = @MasterCompanyId) AND (VRP.[PaymentMethodId] = @CheckPaymentMethodId) AND		      
			  (@StartDate IS NULL OR CAST(VRP.CheckDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)) AND
			  (@ReadyToPayIds IS NULL OR VRP.ReadyToPayId IN (SELECT Item FROM dbo.SplitString(@ReadyToPayIds,','))) AND
		      (@VendorIds IS NULL OR VRP.VendorId IN (SELECT Item FROM dbo.SplitString(@VendorIds,','))) 		       
			 GROUP BY VRP.IsVoidedCheck,lebl.BankAccountNumber,lebl.BankName,VRP.CheckNumber,
			 VN.VendorName,VRP.CheckDate,VRP.ReadyToPayId
		),  
		FinalResult AS (  
		SELECT ReceivingReconciliationId,IsVoidedCheck,VoidedCheck,VendorBankAccountNumber,VendorBankName,InvoiceNum,PaymentAmount,[Date],VendorName,ReadyToPayId
		FROM Result  
		WHERE ( 
		   (@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR             
		   (VendorName LIKE '%' +@GlobalFilter+'%') OR
		   (VendorBankName LIKE '%' +@GlobalFilter+'%') OR  
		   (PaymentAmount LIKE '%' +@GlobalFilter+'%') OR  
		   (VendorBankAccountNumber LIKE '%' +@GlobalFilter+'%')))  
		   OR     
		   (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND         
		   (ISNULL(@EntryDate,'') ='' OR CAST([Date] AS DATE) = CAST(@EntryDate AS DATE)) AND  
		   (ISNULL(@InvoiceTotal,'') ='' OR PaymentAmount LIKE '%'+ @InvoiceTotal+'%') AND  
		   (ISNULL(@BankName,'') ='' OR VendorBankName LIKE '%'+ @BankName+'%') AND 
		   (ISNULL(@BankAccountNumber,'') ='' OR VendorBankAccountNumber LIKE '%'+ @BankAccountNumber+'%') AND 
		   (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%')))
		   ),
		   ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
				SELECT ReceivingReconciliationId,IsVoidedCheck,VoidedCheck,VendorBankAccountNumber,VendorBankName,InvoiceNum,NumberOfItems,PaymentAmount,[Date],VendorName
			FROM FinalResult, ResultCount    
		 ORDER BY CASE WHEN (@SortOrder=1  AND @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='VENDORNAME')  THEN VendorName END ASC,  				  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORNAME')  THEN VendorName END DESC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='READYTOPAYID')  THEN ReadyToPayId END ASC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='READYTOPAYID')  THEN ReadyToPayId END DESC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='CHECKNUMBER')  THEN InvoiceNum END ASC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='CHECKNUMBER')  THEN InvoiceNum END DESC  

		 OFFSET @RecordFrom ROWS   
		 FETCH NEXT @PageSize ROWS ONLY  

    END
	IF(@PaymentMethodId = @DomesticWirePaymentMethodId)
    BEGIN
		;WITH Result AS (  
		 SELECT 0 AS ReceivingReconciliationId
			   ,CASE WHEN VRP.IsVoidedCheck = 1 THEN VRP.CheckNumber ELSE VRP.CheckNumber END AS InvoiceNum
			   ,CASE WHEN LEN(UPPER(DWP.BankName)) > 35 then LEFT(UPPER(DWP.BankName), 35) ELSE  UPPER(DWP.BankName) END AS VendorBankName
	 		   ,CASE WHEN VRP.IsVoidedCheck = 1 THEN DWP.AccountNumber ELSE DWP.AccountNumber END AS VendorBankAccountNumber
			   ,VBA.[VendorBankAccountType] AS 'VendorBankAccountType'
			   ,CASE WHEN LEN(UPPER(VAD.Line1)) > 33 THEN LEFT(UPPER(VAD.Line1), 33) ELSE  UPPER(VAD.Line1) END AS VendorAddressLine1
			   ,CASE WHEN LEN(UPPER(VAD.Line2)) > 33 THEN LEFT(UPPER(VAD.Line2), 33) ELSE  UPPER(VAD.Line2) END AS VendorAddressLine2
			   ,CASE WHEN LEN(UPPER(PAD.Line1)) > 35 THEN LEFT(UPPER(PAD.Line1), 35) ELSE  UPPER(PAD.Line1) END AS VendorBankAddressLine1
			   ,CASE WHEN LEN(UPPER(PAD.Line2)) > 35 THEN LEFT(UPPER(PAD.Line2), 35) ELSE  UPPER(PAD.Line2) END AS VendorBankAddressLine2
			   ,CASE WHEN LEN(UPPER(PAD.City)) > 35 THEN LEFT(UPPER(PAD.City), 35) ELSE  UPPER(PAD.City) END AS VendorBankCity
			   ,CASE WHEN LEN(UPPER(PCO.countries_iso_code)) > 2 then LEFT(UPPER(PCO.countries_iso_code), 2) ELSE  UPPER(PCO.countries_iso_code) END AS VendorBankCountry		   		   
			   ,CASE WHEN LEN(UPPER(DWP.ABA)) > 11 THEN LEFT(UPPER(DWP.ABA), 11) ELSE  UPPER(DWP.ABA) END AS VendorABANumber
			   ,'ABA' AS VendorBankIDType
			   ,CASE WHEN LEN(UPPER(VAD.City)) > 27 THEN LEFT(UPPER(VAD.City), 27) ELSE  UPPER(VAD.City) END AS VendorCity
			   ,CASE WHEN LEN(UPPER(VCO.countries_iso_code)) > 2 THEN LEFT(UPPER(VCO.countries_iso_code), 2) ELSE  UPPER(VCO.countries_iso_code) END AS VendorCountry		   
			   ,CASE WHEN LEN(UPPER(VN.VendorName)) > 33 THEN LEFT(UPPER(VN.VendorName), 33) ELSE  UPPER(VN.VendorName) END AS VendorName
			   ,CASE WHEN LEN(UPPER(VAD.PostalCode)) > 10 THEN LEFT(UPPER(VAD.PostalCode), 10) ELSE  UPPER(VAD.PostalCode) END AS VendorZipCode
			   ,CASE WHEN LEN(UPPER(VAD.StateOrProvince)) > 2 THEN LEFT(UPPER(VAD.StateOrProvince), 2) ELSE  UPPER(VAD.StateOrProvince) END AS VendorState
			   ,'' AS Comments
			   ,CASE WHEN VRP.IsVoidedCheck = 1 THEN VRP.CheckNumber + ' (V)' ELSE VRP.CheckNumber END AS VendorReference
			   ,lebl.BankAccountNumber AS OriginatorBankAccount -- 
			   ,SUM(ISNULL(VRP.PaymentMade,0)) AS PaymentAmount			   
			   ,'' AS PaymentDetailsLine1
			   ,'' AS PaymentDetailsLine2
			   ,'' AS PaymentDetailsLine3
			   ,'' AS PaymentDetailsLine4			 
			   ,CAST(ISNULL(VRP.CheckDate, NULL) AS DATE) AS 'Date'
			   ,PM.[Description] AS 'PaymentMethod'
			   ,VRP.[ReadyToPayId]
			   ,VRP.[VendorId]
			   ,VRP.[PaymentMethodId]
			FROM [dbo].[VendorReadyToPayDetails] VRP  WITH(NOLOCK)
			INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRP.VendorId = VN.VendorId
			 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRP.[ReceivingReconciliationId] = RRH.[ReceivingReconciliationId]
			 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRH WITH(NOLOCK) ON VRP.ReadyToPayId = VRH.ReadyToPayId
			 LEFT JOIN [dbo].[VendorDomesticWirePayment] VVP WITH(NOLOCK) ON VVP.VendorId = VN.VendorId
			 LEFT JOIN [dbo].[DomesticWirePayment] DWP WITH(NOLOCK) ON DWP.DomesticWirePaymentId = VVP.DomesticWirePaymentId
			 LEFT JOIN [dbo].[VendorBankAccountType] VBA WITH(NOLOCK) ON VBA.VendorBankAccountTypeId = DWP.VendorBankAccountTypeId
			 LEFT JOIN [dbo].[Address] VAD WITH(NOLOCK) ON VAD.AddressId = VN.AddressId	
			 LEFT JOIN [dbo].[Address] PAD WITH(NOLOCK) ON PAD.AddressId = DWP.BankAddressId
			 LEFT JOIN [dbo].[Countries] PCO WITH(NOLOCK) ON PCO.countries_id = PAD.CountryId
			 LEFT JOIN [dbo].[Countries] VCO WITH(NOLOCK) ON VCO.countries_id = VAD.CountryId		
			 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VRP.PaymentMethodId
			 LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH(NOLOCK) ON  ESS.[EntityStructureId] = VRH.[ManagementStructureId]
			 --LEFT JOIN [dbo].[ManagementStructureLevel] MSL ON MSL.ID = ESS.Level1Id			 
			 --LEFT JOIN [dbo].[LegalEntityBankingLockBox] LLB ON LLB.LegalEntityId =  MSL.LegalEntityId AND IsPrimay = 1
			 LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRH.BankId	AND IsPrimay = 1
		     LEFT JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON lebl.LegalEntityId = LE.LegalEntityId
		     LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON LE.FunctionalCurrencyId = CR.CurrencyId
			 			 			 
		WHERE (VRP.[MasterCompanyId] = @MasterCompanyId) AND (VRP.[PaymentMethodId] = @DomesticWirePaymentMethodId) AND		      
			  (@StartDate IS NULL OR CAST(VRP.CheckDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)) AND
			  (@ReadyToPayIds IS NULL OR VRP.ReadyToPayId IN (SELECT Item FROM dbo.SplitString(@ReadyToPayIds,','))) AND
		      (@VendorIds IS NULL OR VRP.VendorId IN (SELECT Item FROM dbo.SplitString(@VendorIds,','))) 		       
			 GROUP BY VRP.CheckNumber,DWP.BankName,DWP.AccountNumber,VAD.Line1,VAD.Line2,PAD.Line1,PAD.Line2,PAD.City,
			 PCO.countries_iso_code,DWP.ABA,VAD.City,VCO.countries_iso_code, VRP.IsVoidedCheck,VN.VendorName,VAD.PostalCode,lebl.BankAccountNumber,
			 VAD.StateOrProvince,VRP.CheckDate,PM.[Description],VRP.ReadyToPayId,VRP.VendorId,VRP.[PaymentMethodId],VBA.[VendorBankAccountType]
		),  
		FinalResult AS (  
		SELECT ReceivingReconciliationId,InvoiceNum,VendorBankName,VendorBankAccountNumber,VendorBankAccountType,VendorAddressLine1,VendorAddressLine2,
			   VendorBankAddressLine1,VendorBankAddressLine2,VendorBankCity,VendorBankCountry,VendorABANumber,VendorBankIDType,
			   VendorCity,VendorCountry,VendorName,VendorZipCode,VendorState,Comments,VendorReference,OriginatorBankAccount,PaymentAmount,
			   PaymentDetailsLine1,PaymentDetailsLine2,PaymentDetailsLine3,PaymentDetailsLine4,[Date],PaymentMethod,ReadyToPayId,VendorId,[PaymentMethodId]	
		FROM Result  
		WHERE ( 
		   (@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR             
		   (VendorName LIKE '%' +@GlobalFilter+'%') OR
		   (VendorBankName LIKE '%' +@GlobalFilter+'%') OR  
		   (PaymentAmount LIKE '%' +@GlobalFilter+'%') OR  
		   (VendorBankAccountNumber LIKE '%' +@GlobalFilter+'%')))  
		   OR     
		   (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND         
		   (ISNULL(@EntryDate,'') ='' OR CAST([Date] AS DATE) = CAST(@EntryDate AS DATE)) AND  
		   (ISNULL(@InvoiceTotal,'') ='' OR PaymentAmount LIKE '%'+ @InvoiceTotal+'%') AND  
		   (ISNULL(@BankName,'') ='' OR VendorBankName LIKE '%'+ @BankName+'%') AND 
		   (ISNULL(@BankAccountNumber,'') ='' OR VendorBankAccountNumber LIKE '%'+ @BankAccountNumber+'%') AND 
		   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND 
		   (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%')))
		   ),
		   ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
		  SELECT ReceivingReconciliationId,InvoiceNum,VendorBankName,VendorBankAccountNumber,VendorBankAccountType,VendorAddressLine1,VendorAddressLine2,
			   VendorBankAddressLine1,VendorBankAddressLine2,VendorBankCity,VendorBankCountry,VendorABANumber,VendorBankIDType,
			   VendorCity,VendorCountry,VendorName,VendorZipCode,VendorState,Comments,VendorReference,OriginatorBankAccount,PaymentAmount,
			   PaymentDetailsLine1,PaymentDetailsLine2,PaymentDetailsLine3,PaymentDetailsLine4,[Date],NumberOfItems,PaymentMethod,ReadyToPayId,VendorId,[PaymentMethodId]
			FROM FinalResult, ResultCount    
		 ORDER BY CASE WHEN (@SortOrder=1  AND @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END ASC,   
				  CASE WHEN (@SortOrder=1  AND @SortColumn='VENDORNAME')  THEN VendorName END ASC,   
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORNAME')  THEN VendorName END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='ReadyToPayId')  THEN ReadyToPayId END ASC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='ReadyToPayId')  THEN ReadyToPayId END DESC  

		 OFFSET @RecordFrom ROWS   
		 FETCH NEXT @PageSize ROWS ONLY  
    END 
	IF(@PaymentMethodId = @InternationalWirePaymentMethodId)
    BEGIN
		;WITH Result AS (  
		 SELECT 0 AS ReceivingReconciliationId
			   ,CASE WHEN VRP.IsVoidedCheck = 1 THEN VRP.CheckNumber ELSE VRP.CheckNumber END AS InvoiceNum
			   ,CASE WHEN LEN(UPPER(IWPL.BeneficiaryBank)) > 33 then LEFT(UPPER(IWPL.BeneficiaryBank), 33) ELSE  UPPER(IWPL.BeneficiaryBank) END AS VendorBankName
	 		   ,CASE WHEN VRP.IsVoidedCheck = 1 THEN IWPL.BeneficiaryBankAccount ELSE IWPL.BeneficiaryBankAccount END AS VendorBankAccountNumber			
			   ,VBA.[VendorBankAccountType] AS 'VendorBankAccountType'
			   ,CASE WHEN LEN(UPPER(VAD.Line1)) > 33 THEN LEFT(UPPER(VAD.Line1), 33) ELSE  UPPER(VAD.Line1) END AS VendorAddressLine1
			   ,CASE WHEN LEN(UPPER(VAD.Line2)) > 33 THEN LEFT(UPPER(VAD.Line2), 33) ELSE  UPPER(VAD.Line2) END AS VendorAddressLine2
			   ,CASE WHEN LEN(UPPER(PAD.Line1)) > 35 THEN LEFT(UPPER(PAD.Line1), 35) ELSE  UPPER(PAD.Line1) END AS VendorBankAddressLine1
			   ,CASE WHEN LEN(UPPER(PAD.Line2)) > 35 THEN LEFT(UPPER(PAD.Line2), 35) ELSE  UPPER(PAD.Line2) END AS VendorBankAddressLine2
			   ,CASE WHEN LEN(UPPER(PAD.City)) > 35 THEN LEFT(UPPER(PAD.City), 35) ELSE  UPPER(PAD.City) END AS VendorBankCity
			   ,CASE WHEN LEN(UPPER(PCO.countries_iso_code)) > 2 then LEFT(UPPER(PCO.countries_iso_code), 2) ELSE  UPPER(PCO.countries_iso_code) END AS VendorBankCountry	
			   ,CASE WHEN LEN(UPPER(IWPL.SwiftCode)) > 11 THEN LEFT(UPPER(IWPL.SwiftCode), 11) ELSE  UPPER(IWPL.SwiftCode) END AS VendorBankIDNumber ---- 
			   ,'SWIFT' AS vendorBankIDType
			   ,CASE WHEN LEN(UPPER(VAD.City)) > 27 THEN LEFT(UPPER(VAD.City), 27) ELSE  UPPER(VAD.City) END AS VendorCity
			   ,CASE WHEN LEN(UPPER(VCO.countries_iso_code)) > 2 THEN LEFT(UPPER(VCO.countries_iso_code), 2) ELSE  UPPER(VCO.countries_iso_code) END AS VendorCountry		   
			   ,CASE WHEN LEN(UPPER(VN.VendorName)) > 33 THEN LEFT(UPPER(VN.VendorName), 33) ELSE  UPPER(VN.VendorName) END AS VendorName
			   ,CASE WHEN LEN(UPPER(VAD.PostalCode)) > 10 THEN LEFT(UPPER(VAD.PostalCode), 10) ELSE  UPPER(VAD.PostalCode) END AS VendorZipCode
			   ,CASE WHEN LEN(UPPER(VAD.StateOrProvince)) > 2 THEN LEFT(UPPER(VAD.StateOrProvince), 2) ELSE  UPPER(VAD.StateOrProvince) END AS VendorState
			   ,'' AS Comments
			   ,CASE WHEN VRP.IsVoidedCheck = 1 THEN VRP.CheckNumber + ' (V)' ELSE VRP.CheckNumber END AS VendorReference
			   ,lebl.BankAccountNumber AS OriginatorBankAccount -- 
			   ,SUM(ISNULL(VRP.PaymentMade,0)) AS PaymentAmount
			   ,CR.Code AS PaymentCurrency  
			   ,'' AS PaymentDetailsLine1
			   ,'' AS PaymentDetailsLine2
			   ,'' AS PaymentDetailsLine3
			   ,'' AS PaymentDetailsLine4			   
			   ,CAST(ISNULL(VRP.CheckDate, NULL) AS DATE) AS 'Date'
			   ,PM.[Description] AS 'PaymentMethod'
			   ,VRP.[ReadyToPayId]
			   ,VRP.[VendorId]
			   ,VRP.[PaymentMethodId]
			FROM [dbo].[VendorReadyToPayDetails] VRP  WITH(NOLOCK)
			INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRP.VendorId = VN.VendorId
			 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRP.[ReceivingReconciliationId] = RRH.[ReceivingReconciliationId]
			 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRH WITH(NOLOCK) ON VRP.ReadyToPayId = VRH.ReadyToPayId
			 LEFT JOIN [dbo].[VendorInternationlWirePayment] VVP WITH(NOLOCK) ON VVP.VendorId = VRP.VendorId
		     LEFT JOIN [dbo].[InternationalWirePayment] IWPL WITH(NOLOCK) ON IWPL.InternationalWirePaymentId = VVP.InternationalWirePaymentId
			 LEFT JOIN [dbo].[VendorBankAccountType] VBA WITH(NOLOCK) ON VBA.VendorBankAccountTypeId = IWPL.VendorBankAccountTypeId
			 LEFT JOIN [dbo].[Address] VAD WITH(NOLOCK) ON VAD.AddressId = VN.AddressId	
			 LEFT JOIN [dbo].[Address] PAD WITH(NOLOCK) ON PAD.AddressId = IWPL.BankAddressId
			 LEFT JOIN [dbo].[Countries] PCO WITH(NOLOCK) ON PCO.countries_id = PAD.CountryId
			 LEFT JOIN [dbo].[Countries] VCO WITH(NOLOCK) ON VCO.countries_id = VAD.CountryId		
			 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VRP.PaymentMethodId			
		     LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityBankingLockBoxId = VRH.BankId	AND IsPrimay = 1
		     LEFT JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON lebl.LegalEntityId = LE.LegalEntityId
		     LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON LE.FunctionalCurrencyId = CR.CurrencyId
			 --LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH(NOLOCK) ON  ESS.[EntityStructureId] = VRH.[ManagementStructureId]
			 --LEFT JOIN [dbo].[ManagementStructureLevel] MSL ON MSL.ID = ESS.Level1Id			 
			 --LEFT JOIN [dbo].[LegalEntityBankingLockBox] LLB ON LLB.LegalEntityId =  MSL.LegalEntityId AND IsPrimay = 1
			 --LEFT JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON LLB.LegalEntityId = LE.LegalEntityId
			 --LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON LE.FunctionalCurrencyId = CR.CurrencyId

		WHERE (VRP.[MasterCompanyId] = @MasterCompanyId) AND (VRP.[PaymentMethodId] = @InternationalWirePaymentMethodId) AND		      
			  (@StartDate IS NULL OR CAST(VRP.CheckDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)) AND
			  (@ReadyToPayIds IS NULL OR VRP.ReadyToPayId IN (SELECT Item FROM dbo.SplitString(@ReadyToPayIds,','))) AND
		      (@VendorIds IS NULL OR VRP.VendorId IN (SELECT Item FROM dbo.SplitString(@VendorIds,','))) 		       
	    GROUP BY VRP.CheckNumber,IWPL.BeneficiaryBank,IWPL.BeneficiaryBankAccount,VAD.Line1,VAD.Line2,PAD.Line1,PAD.Line2,PAD.City,
			 PCO.countries_iso_code,IWPL.SwiftCode,VAD.City,VCO.countries_iso_code, VRP.IsVoidedCheck,VN.VendorName,VAD.PostalCode,lebl.BankAccountNumber,
			 VAD.StateOrProvince,VRP.CheckDate,PM.[Description],VRP.ReadyToPayId,VRP.VendorId,VRP.[PaymentMethodId],CR.Code,VBA.[VendorBankAccountType]
		),  
		FinalResult AS (  
		SELECT ReceivingReconciliationId,InvoiceNum,VendorBankName,VendorBankAccountNumber,VendorBankAccountType,VendorAddressLine1,VendorAddressLine2,
			   VendorBankAddressLine1,VendorBankAddressLine2,VendorBankCity,VendorBankCountry,VendorBankIDNumber,VendorBankIDType,
			   VendorCity,VendorCountry,VendorName,VendorZipCode,VendorState,Comments,VendorReference,OriginatorBankAccount,PaymentAmount,
			   PaymentCurrency,PaymentDetailsLine1,PaymentDetailsLine2,PaymentDetailsLine3,PaymentDetailsLine4,[Date],PaymentMethod,ReadyToPayId,VendorId,[PaymentMethodId]	
		FROM Result  
		WHERE ( 
		   (@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR             
		   (VendorName LIKE '%' +@GlobalFilter+'%') OR
		   (VendorBankName LIKE '%' +@GlobalFilter+'%') OR  
		   (PaymentAmount LIKE '%' +@GlobalFilter+'%') OR  
		   (VendorBankAccountNumber LIKE '%' +@GlobalFilter+'%')))  
		   OR     
		   (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND         
		   (ISNULL(@EntryDate,'') ='' OR CAST([Date] AS DATE) = CAST(@EntryDate AS DATE)) AND  
		   (ISNULL(@InvoiceTotal,'') ='' OR PaymentAmount LIKE '%'+ @InvoiceTotal+'%') AND  
		   (ISNULL(@BankName,'') ='' OR VendorBankName LIKE '%'+ @BankName+'%') AND 
		   (ISNULL(@BankAccountNumber,'') ='' OR VendorBankAccountNumber LIKE '%'+ @BankAccountNumber+'%') AND 
		   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND 
		   (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%')))
		   ),
		   ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
		  SELECT ReceivingReconciliationId,InvoiceNum,VendorBankName,VendorBankAccountNumber,VendorBankAccountType,VendorAddressLine1,VendorAddressLine2,
			   VendorBankAddressLine1,VendorBankAddressLine2,VendorBankCity,VendorBankCountry,VendorBankIDNumber,VendorBankIDType,
			   VendorCity,VendorCountry,VendorName,VendorZipCode,VendorState,Comments,VendorReference,OriginatorBankAccount,PaymentAmount,
			   PaymentCurrency,PaymentDetailsLine1,PaymentDetailsLine2,PaymentDetailsLine3,PaymentDetailsLine4,[Date],NumberOfItems,PaymentMethod,ReadyToPayId,VendorId,[PaymentMethodId]
			FROM FinalResult, ResultCount    
		 ORDER BY CASE WHEN (@SortOrder=1  AND @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END ASC,   
				  CASE WHEN (@SortOrder=1  AND @SortColumn='VENDORNAME')  THEN VendorName END ASC,   
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORNAME')  THEN VendorName END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='ReadyToPayId')  THEN ReadyToPayId END ASC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='ReadyToPayId')  THEN ReadyToPayId END DESC  
		 OFFSET @RecordFrom ROWS   
		 FETCH NEXT @PageSize ROWS ONLY  

    END 
	IF(@PaymentMethodId = @CreditCardPaymentMethodId)
    BEGIN
		;WITH Result AS (  
		 SELECT 
				0 AS ReceivingReconciliationId
				,CASE WHEN VRP.IsVoidedCheck = 1 THEN VRP.CheckNumber ELSE VRP.CheckNumber END AS InvoiceNum			   
			    ,CAST(ISNULL(VRP.CheckDate, NULL) AS DATE) AS 'Date'
			    ,CASE WHEN LEN(UPPER(VN.VendorName)) > 33 THEN LEFT(UPPER(VN.VendorName), 33) ELSE  UPPER(VN.VendorName) END AS VendorName
			    ,CASE WHEN LEN(UPPER(VAD.Line1)) > 33 THEN LEFT(UPPER(VAD.Line1), 33) ELSE  UPPER(VAD.Line1) END AS VendorAddressLine1
			    ,CASE WHEN LEN(UPPER(VAD.Line2)) > 33 THEN LEFT(UPPER(VAD.Line2), 33) ELSE  UPPER(VAD.Line2) END AS VendorAddressLine2
			    ,CASE WHEN LEN(UPPER(VAD.City)) > 27 THEN LEFT(UPPER(VAD.City), 27) ELSE  UPPER(VAD.City) END AS VendorCity
			    ,CASE WHEN LEN(UPPER(VAD.StateOrProvince)) > 2 THEN LEFT(UPPER(VAD.StateOrProvince), 2) ELSE  UPPER(VAD.StateOrProvince) END AS VendorState
			    ,CASE WHEN LEN(UPPER(VAD.PostalCode)) > 10 THEN LEFT(UPPER(VAD.PostalCode), 10) ELSE  UPPER(VAD.PostalCode) END AS VendorZipCode
			    ,CASE WHEN VRP.IsVoidedCheck = 1 THEN VRP.CheckNumber ELSE VRP.CheckNumber END AS VendorReference
			    ,SUM(ISNULL(VRP.PaymentMade,0)) AS PaymentAmount
			    ,'' AS PaymentDetailsLine1
			    ,'' AS PaymentDetailsLine2
			    ,'' AS PaymentDetailsLine3
			    ,'' AS PaymentDetailsLine4
			    ,VRP.[ReadyToPayId]
			    ,VRP.[VendorId]
			    ,VRP.[PaymentMethodId]
			    ,PM.[Description] AS 'PaymentMethod'
			FROM [dbo].[VendorReadyToPayDetails] VRP  WITH(NOLOCK)
			INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRP.VendorId = VN.VendorId
			 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRP.[ReceivingReconciliationId] = RRH.[ReceivingReconciliationId]
			 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRH WITH(NOLOCK) ON VRP.ReadyToPayId = VRH.ReadyToPayId
			 LEFT JOIN [dbo].[Address] VAD WITH(NOLOCK) ON VAD.AddressId = VN.AddressId	
			 LEFT JOIN [dbo].[Countries] VCO WITH(NOLOCK) ON VCO.countries_id = VAD.CountryId		
			 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VRP.PaymentMethodId			 
		WHERE (VRP.[MasterCompanyId] = @MasterCompanyId) AND (VRP.[PaymentMethodId] = @CreditCardPaymentMethodId) AND		      
			  (@StartDate IS NULL OR CAST(VRP.CheckDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)) AND
			  (@ReadyToPayIds IS NULL OR VRP.ReadyToPayId IN (SELECT Item FROM dbo.SplitString(@ReadyToPayIds,','))) AND
		      (@VendorIds IS NULL OR VRP.VendorId IN (SELECT Item FROM dbo.SplitString(@VendorIds,','))) 		       
			 GROUP BY VRP.CheckNumber,VAD.Line1,VAD.Line2
			,VAD.City,VCO.countries_iso_code, VRP.IsVoidedCheck,VN.VendorName,VAD.PostalCode,
			 VAD.StateOrProvince,VRP.CheckDate,PM.[Description],VRP.ReadyToPayId,VRP.VendorId,VRP.[PaymentMethodId]
		),  
		FinalResult AS (  
		SELECT ReceivingReconciliationId,InvoiceNum,VendorAddressLine1,VendorAddressLine2,
			   VendorCity,VendorName,VendorZipCode,VendorState,VendorReference,PaymentAmount,PaymentMethod,
			   PaymentDetailsLine1,PaymentDetailsLine2,PaymentDetailsLine3,PaymentDetailsLine4,[Date],ReadyToPayId,VendorId,[PaymentMethodId]	
		FROM Result  
		WHERE ( 
		   (@GlobalFilter <>'' AND ((InvoiceNum LIKE '%' +@GlobalFilter+'%' ) OR             
		   (VendorName LIKE '%' +@GlobalFilter+'%') OR
		   (PaymentAmount LIKE '%' +@GlobalFilter+'%')))  
		   OR     
		   (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE  '%'+ @InvoiceNum+'%') AND         
		   (ISNULL(@EntryDate,'') ='' OR CAST([Date] AS DATE) = CAST(@EntryDate AS DATE)) AND  
		   (ISNULL(@InvoiceTotal,'') ='' OR PaymentAmount LIKE '%'+ @InvoiceTotal+'%') AND  
		   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND 
		   (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%')))
		   ),
		   ResultCount AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM FinalResult)  
		  SELECT ReceivingReconciliationId,InvoiceNum,VendorAddressLine1,VendorAddressLine2,
			   VendorCity,VendorName,VendorZipCode,VendorState,VendorReference,PaymentAmount,
			   PaymentMethod,
			   PaymentDetailsLine1,PaymentDetailsLine2,PaymentDetailsLine3,PaymentDetailsLine4,[Date],NumberOfItems,ReadyToPayId,VendorId,[PaymentMethodId]
			FROM FinalResult, ResultCount    
		 ORDER BY CASE WHEN (@SortOrder=1  AND @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END ASC,   
				  CASE WHEN (@SortOrder=1  AND @SortColumn='VENDORNAME')  THEN VendorName END ASC,   
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORNAME')  THEN VendorName END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='ReadyToPayId')  THEN ReadyToPayId END ASC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='ReadyToPayId')  THEN ReadyToPayId END DESC  
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
              , @AdhocComments     VARCHAR(150)    = 'VendorPositivePayExportList'   
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