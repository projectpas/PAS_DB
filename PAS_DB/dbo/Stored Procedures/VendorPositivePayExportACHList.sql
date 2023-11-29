/*************************************************************           
 ** File:   [VendorPositivePayExportACHList]           
 ** Author:   MOIN BLOCH
 ** Description: This stored procedure is used Get Vendor Positive Pay Export ACH List
 ** Purpose:         
 ** Date:   07/19/2023
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/19/2023   MOIN BLOCH    CREATED 
	2    09/07/2023   MOIN BLOCH    Modefied (Added missing Fields) 
	3    09/20/2023   MOIN BLOCH    Modefied (Added missing Fields)
	4    09/26/2023   MOIN BLOCH    Modefied (Added 0 ADDAND IN ACCOUNT NUMBER)
	5    09/29/2023   MOIN BLOCH    Modefied (Removed 10 digit length from Entry Hash)
	
--EXEC VendorPositivePayExportACHList 
**************************************************************/
CREATE   PROCEDURE [dbo].[VendorPositivePayExportACHList]
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
@EmployeeId bigint = NULL,
@BankName varchar(50) = NULL,  
@BankAccountNumber varchar(50) = NULL,
@PaymentMethod varchar(50) = NULL,
@PaymentMethodId int = NULL,
@ReadyToPayIds varchar(250) = NULL,
@VendorIds varchar(250) = NULL,
@LegalEntityId bigint = NULL,
@CreatedBy varchar(250) = NULL,
@Opr INT = NULL
AS  
BEGIN 
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY         
    DECLARE @RecordFrom INT;  
	DECLARE @ACHTransferPaymentMethodId INT;
	DECLARE @CheckingAccountTypeId INT;
	DECLARE @SavingAccountTypeId INT;
	DECLARE @Fileid varchar(10)=''
		
    SET @RecordFrom = (@PageNumber-1) * @PageSize;      
    IF @SortColumn IS NULL  
    BEGIN  
		SET @SortColumn = UPPER('CreatedDate')  
    END   
    ELSE  
    BEGIN   
		SET @SortColumn = UPPER(@SortColumn)  
    End  
	IF(@ReadyToPayIds = '')
	BEGIN
		SET @ReadyToPayIds = NULL;
	END
	IF(@VendorIds = '')
	BEGIN
		SET @VendorIds = NULL;
	END	

	DECLARE @CurrentDate DATE = GETUTCDATE();

	SELECT @ACHTransferPaymentMethodId = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod] WHERE [Description] ='ACH Transfer';

	SELECT @CheckingAccountTypeId = VendorBankAccountTypeId FROM [VendorBankAccountType] where VendorBankAccountType = 'Checking';
	SELECT @SavingAccountTypeId = VendorBankAccountTypeId FROM [VendorBankAccountType] where VendorBankAccountType = 'Saving';

	IF(@PaymentMethodId = @ACHTransferPaymentMethodId AND @Opr = 1)  -- File Header
    BEGIN	   
		 EXEC [dbo].[GenerateNachaFileID] @LegalEntityId,@CurrentDate,@MasterCompanyId,@CreatedBy,@Fileid OUTPUT
		;WITH Result AS (  
		 SELECT TOP 1 '1' AS RecordTypeCode
		       ,'01' AS PriorityCode			
			   ,SPACE(1) + CASE WHEN LEN(UPPER(ACH.ABA)) = 1 THEN UPPER(ACH.ABA) + SPACE(8)
			                    WHEN LEN(UPPER(ACH.ABA)) = 2 THEN UPPER(ACH.ABA) + SPACE(7)
					            WHEN LEN(UPPER(ACH.ABA)) = 3 THEN UPPER(ACH.ABA) + SPACE(6)
					            WHEN LEN(UPPER(ACH.ABA)) = 4 THEN UPPER(ACH.ABA) + SPACE(5)
					            WHEN LEN(UPPER(ACH.ABA)) = 5 THEN UPPER(ACH.ABA) + SPACE(4)
					            WHEN LEN(UPPER(ACH.ABA)) = 6 THEN UPPER(ACH.ABA) + SPACE(3)
					            WHEN LEN(UPPER(ACH.ABA)) = 7 THEN UPPER(ACH.ABA) + SPACE(2)
					            WHEN LEN(UPPER(ACH.ABA)) = 8 THEN UPPER(ACH.ABA) + SPACE(1)
					            WHEN LEN(UPPER(ACH.ABA)) = 9 THEN UPPER(ACH.ABA)    
					            WHEN LEN(UPPER(ACH.ABA)) > 9 THEN LEFT(UPPER(ACH.ABA), 9)   
					            ELSE SPACE(9)  
				END AS ImmediateDestination	
			    ,'1'+ CASE WHEN LEN(UPPER(LEE.taxId)) = 1 THEN UPPER(LEE.taxId) + SPACE(8)
						   WHEN LEN(UPPER(LEE.taxId)) = 2 THEN UPPER(LEE.taxId) + SPACE(7)
						   WHEN LEN(UPPER(LEE.taxId)) = 3 THEN UPPER(LEE.taxId) + SPACE(6)
						   WHEN LEN(UPPER(LEE.taxId)) = 4 THEN UPPER(LEE.taxId) + SPACE(5)
						   WHEN LEN(UPPER(LEE.taxId)) = 5 THEN UPPER(LEE.taxId) + SPACE(4)
						   WHEN LEN(UPPER(LEE.taxId)) = 6 THEN UPPER(LEE.taxId) + SPACE(3)
						   WHEN LEN(UPPER(LEE.taxId)) = 7 THEN UPPER(LEE.taxId) + SPACE(2)
						   WHEN LEN(UPPER(LEE.taxId)) = 8 THEN UPPER(LEE.taxId) + SPACE(1)
						   WHEN LEN(UPPER(LEE.taxId)) = 9 THEN UPPER(LEE.taxId)
						   WHEN LEN(UPPER(LEE.taxId)) > 9 THEN LEFT(UPPER(LEE.taxId), 9)
					  ELSE SPACE(9) END AS ImmediateOrigin 
				,CONVERT(VARCHAR,GETUTCDATE(), 12) AS FileCreationDate		
				,REPLACE(CONVERT(VARCHAR(5),GETUTCDATE(),108), ':', '') AS FileCreationTime 
				,@Fileid AS FileIDModifier     
				,'094' AS RecordSize
				,'10' AS BlockingFactor
				,'1' AS FormatCode
				,CASE WHEN LEN(UPPER(ACH.BeneficiaryBankName)) <= 23 THEN UPPER(ACH.BeneficiaryBankName) + SPACE(dbo.GetSpace(23,LEN(ACH.BeneficiaryBankName)))			          
					  WHEN LEN(UPPER(ACH.BeneficiaryBankName)) > 23  THEN LEFT(UPPER(ACH.BeneficiaryBankName), 23) 
					  ELSE SPACE(23)		
				 END AS ImmediateDestinationName				 
				,CASE WHEN LEN(UPPER(LEE.[Name])) <= 23 THEN UPPER(LEE.[Name]) + SPACE(dbo.GetSpace(23,LEN(LEE.[Name])))			          
					  WHEN LEN(UPPER(LEE.[Name])) > 23  THEN LEFT(UPPER(LEE.[Name]), 23) 
					  ELSE SPACE(23)		
				 END AS ImmediateOriginName                
                ,SPACE(8) AS ReferenceCode 		
				,VRP.CheckNumber 
				,VRP.CheckDate AS 'Date'
				,VN.VendorName
				,SUM(ISNULL(VRP.PaymentMade,0)) AS PaymentAmount
				,ACH.BankName
	 		    ,ACH.AccountNumber
				,PM.[Description] AS 'PaymentMethod'			  
			FROM [dbo].[VendorReadyToPayDetails] VRP  WITH(NOLOCK)
			INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRP.VendorId = VN.VendorId
			 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRP.[ReceivingReconciliationId] = RRH.[ReceivingReconciliationId]
			 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRH WITH(NOLOCK) ON VRP.ReadyToPayId = VRH.ReadyToPayId
			 --LEFT JOIN [dbo].[VendorDomesticWirePayment] VVP WITH(NOLOCK) ON VVP.VendorId = VN.VendorId
			 --LEFT JOIN [dbo].[DomesticWirePayment] DWP WITH(NOLOCK) ON DWP.DomesticWirePaymentId = VVP.DomesticWirePaymentId
			 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VRP.PaymentMethodId			 
			 INNER JOIN [dbo].[EntityStructureSetup] ESS WITH(NOLOCK) ON ESS.EntityStructureId = VRH.ManagementStructureId
			 INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON MSL.ID = ESS.Level1Id
             INNER JOIN [dbo].[LegalEntity] LEE WITH(NOLOCK) ON LEE.LegalEntityId = MSL.LegalEntityId
			  LEFT JOIN [dbo].[ACH] ACH WITH(NOLOCK) ON ACH.LegalENtityId = MSL.LegalEntityId AND IsPrimay = 1			 	 
		WHERE (VRP.[MasterCompanyId] = @MasterCompanyId) AND (MSL.LegalEntityId = @LegalEntityId) AND (VRP.[PaymentMethodId] = @ACHTransferPaymentMethodId) AND
			  (@ReadyToPayIds IS NULL OR VRP.ReadyToPayId IN (SELECT Item FROM dbo.SplitString(@ReadyToPayIds,','))) AND
		      (@VendorIds IS NULL OR VRP.VendorId IN (SELECT Item FROM dbo.SplitString(@VendorIds,','))) 		       
			 GROUP BY ACH.ABA,LEE.[Name],VRP.CheckNumber,VRP.CheckDate,VN.VendorName,ACH.BankName,ACH.BeneficiaryBankName,ACH.AccountNumber,VRP.CheckDate
			         ,VRP.ReadyToPayId,VRP.VendorId,VRP.[PaymentMethodId],PM.[Description],LEE.[taxId]
		),  
		FinalResult AS (  
		SELECT RecordTypeCode,PriorityCode,ImmediateDestination,ImmediateOrigin,FileCreationDate,FileCreationTime,FileIDModifier,
			   RecordSize,BlockingFactor,FormatCode,ImmediateDestinationName,ImmediateOriginName,ReferenceCode,CheckNumber,Date,
			   VendorName,PaymentAmount,BankName,AccountNumber,PaymentMethod
		FROM Result  
		WHERE ( 
		   (@GlobalFilter <>'' AND ((CheckNumber LIKE '%' +@GlobalFilter+'%' ) OR             
		   (VendorName LIKE '%' +@GlobalFilter+'%') OR
		   (BankName LIKE '%' +@GlobalFilter+'%') OR
		   (PaymentAmount LIKE '%' +@GlobalFilter+'%') OR 
		   (PaymentMethod LIKE '%' +@GlobalFilter+'%') OR  
		   (AccountNumber LIKE '%' +@GlobalFilter+'%')))  
		   OR     
		   (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR CheckNumber LIKE  '%'+ @InvoiceNum+'%') AND         
		   (ISNULL(@EntryDate,'') ='' OR CAST([Date] AS DATE) = CAST(@EntryDate AS DATE)) AND  
		   (ISNULL(@InvoiceTotal,'') ='' OR PaymentAmount LIKE '%'+ @InvoiceTotal+'%') AND  
		   (ISNULL(@BankName,'') ='' OR BankName LIKE '%'+ @BankName+'%') AND 
		   (ISNULL(@BankAccountNumber,'') ='' OR AccountNumber LIKE '%'+ @BankAccountNumber+'%') AND 
		   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND 
		   (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%')))
		   ),
		   ResultCount AS (SELECT COUNT(RecordTypeCode) AS NumberOfItems FROM FinalResult)  
		  SELECT RecordTypeCode,PriorityCode,ImmediateDestination,ImmediateOrigin,FileCreationDate,FileCreationTime,FileIDModifier,
			   RecordSize,BlockingFactor,FormatCode,ImmediateDestinationName,ImmediateOriginName,ReferenceCode,CheckNumber,Date,
			   VendorName,PaymentAmount,BankName,AccountNumber,PaymentMethod,NumberOfItems
			FROM FinalResult, ResultCount    
		 ORDER BY CASE WHEN (@SortOrder=1  AND @SortColumn='CheckNumber')  THEN CheckNumber END ASC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END ASC,   
				  CASE WHEN (@SortOrder=1  AND @SortColumn='VENDORNAME')  THEN VendorName END ASC,   
				  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='CheckNumber')  THEN CheckNumber END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORNAME')  THEN VendorName END DESC  
		 OFFSET @RecordFrom ROWS   
		 FETCH NEXT @PageSize ROWS ONLY  
    END 
	IF(@PaymentMethodId = @ACHTransferPaymentMethodId AND @Opr = 2)  -- Batch Header
    BEGIN
		;WITH Result AS (  
		 SELECT TOP 1 '5' AS RecordTypeCode
		       ,'220' AS ServiceClassCode
			   ,CASE WHEN LEN(UPPER(LEE.[Name])) <= 16 THEN UPPER(LEE.[Name]) + SPACE(dbo.GetSpace(16,LEN(LEE.[Name])))			          
					  WHEN LEN(UPPER(LEE.[Name])) > 16  THEN LEFT(UPPER(LEE.[Name]), 16) 
					  ELSE SPACE(16) END AS CompanyName
			   ,SPACE(20) AS CompanyDiscretionaryData
		       ,'1'+  CASE WHEN LEN(UPPER(LEE.taxId)) = 1 THEN UPPER(LEE.taxId) + SPACE(8)
						   WHEN LEN(UPPER(LEE.taxId)) = 2 THEN UPPER(LEE.taxId) + SPACE(7)
						   WHEN LEN(UPPER(LEE.taxId)) = 3 THEN UPPER(LEE.taxId) + SPACE(6)
						   WHEN LEN(UPPER(LEE.taxId)) = 4 THEN UPPER(LEE.taxId) + SPACE(5)
						   WHEN LEN(UPPER(LEE.taxId)) = 5 THEN UPPER(LEE.taxId) + SPACE(4)
						   WHEN LEN(UPPER(LEE.taxId)) = 6 THEN UPPER(LEE.taxId) + SPACE(3)
						   WHEN LEN(UPPER(LEE.taxId)) = 7 THEN UPPER(LEE.taxId) + SPACE(2)
						   WHEN LEN(UPPER(LEE.taxId)) = 8 THEN UPPER(LEE.taxId) + SPACE(1)
						   WHEN LEN(UPPER(LEE.taxId)) = 9 THEN UPPER(LEE.taxId)
						   WHEN LEN(UPPER(LEE.taxId)) > 9 THEN LEFT(UPPER(LEE.taxId), 9)
					  ELSE SPACE(9) END AS CompanyIdentification
			   ,'CCD' AS StandardEntryClassCode
			   ,'ACH Transf' AS CompanyEntryDescription -----------  Need To Confirm With Client		
			   ,CONVERT(VARCHAR,GETUTCDATE(), 12) AS CompanyDescriptiveDate	--VRP.CheckDate	 -----------  Need To Confirm With Client
			   ,CONVERT(VARCHAR,GETUTCDATE(), 12) AS EffectiveEntryDate		--VRP.CheckDate  -----------  Need To Confirm With Client
			   ,SPACE(3) AS Reserved 
			   ,'1' AS OriginatorStatusCode			
			   ,CASE WHEN LEN(UPPER(ACH.ABA)) = 1 THEN UPPER(ACH.ABA) + SPACE(7)
			         WHEN LEN(UPPER(ACH.ABA)) = 2 THEN UPPER(ACH.ABA) + SPACE(6)
					 WHEN LEN(UPPER(ACH.ABA)) = 3 THEN UPPER(ACH.ABA) + SPACE(5)
					 WHEN LEN(UPPER(ACH.ABA)) = 4 THEN UPPER(ACH.ABA) + SPACE(4)
					 WHEN LEN(UPPER(ACH.ABA)) = 5 THEN UPPER(ACH.ABA) + SPACE(3)
					 WHEN LEN(UPPER(ACH.ABA)) = 6 THEN UPPER(ACH.ABA) + SPACE(2)
					 WHEN LEN(UPPER(ACH.ABA)) = 7 THEN UPPER(ACH.ABA) + SPACE(1)
					 WHEN LEN(UPPER(ACH.ABA)) = 8 THEN UPPER(ACH.ABA) 
					 WHEN LEN(UPPER(ACH.ABA)) > 8 THEN LEFT(UPPER(ACH.ABA), 8)   
					 ELSE SPACE(8)
				END AS OriginatingDFIID	
			   ,'0000001' AS BatchNumber
			   ,VRP.CheckNumber 
			   ,VRP.CheckDate AS 'Date'
			   ,VN.VendorName
			   ,SUM(ISNULL(VRP.PaymentMade,0)) AS PaymentAmount
			   ,ACH.BankName
	 		   ,ACH.AccountNumber
			   ,PM.[Description] AS 'PaymentMethod'			  
			FROM [dbo].[VendorReadyToPayDetails] VRP  WITH(NOLOCK)
			 INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRP.VendorId = VN.VendorId
			 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRP.[ReceivingReconciliationId] = RRH.[ReceivingReconciliationId]
			 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRH WITH(NOLOCK) ON VRP.ReadyToPayId = VRH.ReadyToPayId
			 --LEFT JOIN [dbo].[VendorDomesticWirePayment] VVP WITH(NOLOCK) ON VVP.VendorId = VN.VendorId
			 --LEFT JOIN [dbo].[DomesticWirePayment] DWP WITH(NOLOCK) ON DWP.DomesticWirePaymentId = VVP.DomesticWirePaymentId
			  LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VRP.PaymentMethodId			 
			 INNER JOIN [dbo].[EntityStructureSetup] ESS WITH(NOLOCK) ON ESS.EntityStructureId = VRH.ManagementStructureId
			 INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON MSL.ID = ESS.Level1Id
             INNER JOIN [dbo].[LegalEntity] LEE WITH(NOLOCK) ON LEE.LegalEntityId = MSL.LegalEntityId
			  LEFT JOIN [dbo].[ACH] ACH WITH(NOLOCK) ON ACH.LegalENtityId = MSL.LegalEntityId AND IsPrimay = 1	
		WHERE (VRP.[MasterCompanyId] = @MasterCompanyId) AND (MSL.LegalEntityId = @LegalEntityId) AND (VRP.[PaymentMethodId] = @ACHTransferPaymentMethodId) AND
			  (@ReadyToPayIds IS NULL OR VRP.ReadyToPayId IN (SELECT Item FROM dbo.SplitString(@ReadyToPayIds,','))) AND
		      (@VendorIds IS NULL OR VRP.VendorId IN (SELECT Item FROM dbo.SplitString(@VendorIds,','))) 		       
			 GROUP BY ACH.ABA,LEE.[Name],VRP.CheckNumber,VRP.CheckDate,VN.VendorName,ACH.BankName,ACH.AccountNumber,VRP.CheckDate
			         ,VRP.ReadyToPayId,VRP.VendorId,VRP.[PaymentMethodId],PM.[Description],LEE.taxId
		),  
		FinalResult AS (  
		SELECT RecordTypeCode,ServiceClassCode,CompanyName,CompanyDiscretionaryData,CompanyIdentification,StandardEntryClassCode,CompanyEntryDescription,
			   CompanyDescriptiveDate,EffectiveEntryDate,Reserved,OriginatorStatusCode,OriginatingDFIID,BatchNumber,CheckNumber,Date,
			   VendorName,PaymentAmount,BankName,AccountNumber,PaymentMethod
		FROM Result  
		WHERE ( 
		   (@GlobalFilter <>'' AND ((CheckNumber LIKE '%' +@GlobalFilter+'%' ) OR             
		   (VendorName LIKE '%' +@GlobalFilter+'%') OR
		   (BankName LIKE '%' +@GlobalFilter+'%') OR
		   (PaymentAmount LIKE '%' +@GlobalFilter+'%') OR 
		   (PaymentMethod LIKE '%' +@GlobalFilter+'%') OR  
		   (AccountNumber LIKE '%' +@GlobalFilter+'%')))  
		   OR     
		   (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR CheckNumber LIKE  '%'+ @InvoiceNum+'%') AND         
		   (ISNULL(@EntryDate,'') ='' OR CAST([Date] AS DATE) = CAST(@EntryDate AS DATE)) AND  
		   (ISNULL(@InvoiceTotal,'') ='' OR PaymentAmount LIKE '%'+ @InvoiceTotal+'%') AND  
		   (ISNULL(@BankName,'') ='' OR BankName LIKE '%'+ @BankName+'%') AND 
		   (ISNULL(@BankAccountNumber,'') ='' OR AccountNumber LIKE '%'+ @BankAccountNumber+'%') AND 
		   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND 
		   (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%')))
		   ),
		   ResultCount AS (SELECT COUNT(RecordTypeCode) AS NumberOfItems FROM FinalResult)  
		  SELECT RecordTypeCode,ServiceClassCode,CompanyName,CompanyDiscretionaryData,CompanyIdentification,StandardEntryClassCode,
		         CompanyEntryDescription,CompanyDescriptiveDate,EffectiveEntryDate,Reserved,OriginatorStatusCode,OriginatingDFIID,BatchNumber,
				 CheckNumber,Date,VendorName,PaymentAmount,BankName,AccountNumber,PaymentMethod,NumberOfItems
			FROM FinalResult, ResultCount    
		 ORDER BY CASE WHEN (@SortOrder=1  AND @SortColumn='CheckNumber')  THEN CheckNumber END ASC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END ASC,   
				  CASE WHEN (@SortOrder=1  AND @SortColumn='VENDORNAME')  THEN VendorName END ASC,   
				  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='CheckNumber')  THEN CheckNumber END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORNAME')  THEN VendorName END DESC  
		 OFFSET @RecordFrom ROWS   
		 FETCH NEXT @PageSize ROWS ONLY  
    END
	IF(@PaymentMethodId = @ACHTransferPaymentMethodId AND @Opr = 3) -- Transactions (Vendor Payments)
    BEGIN
		;WITH Result AS (  
		 SELECT '6' AS RecordTypeCode
			    ,CASE WHEN DWP.VendorBankAccountTypeId = @CheckingAccountTypeId THEN '22'
			          WHEN DWP.VendorBankAccountTypeId = @SavingAccountTypeId THEN '32'
					  ELSE '22' 
					END AS TransactionCode
			   ,CASE WHEN LEN(UPPER(DWP.ABA)) = 1 THEN UPPER(DWP.ABA) + SPACE(7)
			         WHEN LEN(UPPER(DWP.ABA)) = 2 THEN UPPER(DWP.ABA) + SPACE(6)
					 WHEN LEN(UPPER(DWP.ABA)) = 3 THEN UPPER(DWP.ABA) + SPACE(5)
					 WHEN LEN(UPPER(DWP.ABA)) = 4 THEN UPPER(DWP.ABA) + SPACE(4)
					 WHEN LEN(UPPER(DWP.ABA)) = 5 THEN UPPER(DWP.ABA) + SPACE(3)
					 WHEN LEN(UPPER(DWP.ABA)) = 6 THEN UPPER(DWP.ABA) + SPACE(2)
					 WHEN LEN(UPPER(DWP.ABA)) = 7 THEN UPPER(DWP.ABA) + SPACE(1)
					 WHEN LEN(UPPER(DWP.ABA)) = 8 THEN UPPER(DWP.ABA)
					 WHEN LEN(UPPER(DWP.ABA)) > 8 THEN LEFT(UPPER(DWP.ABA), 8) 
					 ELSE SPACE(8)   
				END AS ReceivingDFIID
				,CASE WHEN LEN(UPPER(DWP.ABA)) > 1 THEN RIGHT(UPPER(DWP.ABA), 1) 			       
					 ELSE SPACE(1)   
				END AS CheckDigit				
				,CASE WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 1 THEN dbo.GetNumOfZero(16) + DWP.[AccountNumber] 
				      WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 2 THEN dbo.GetNumOfZero(15) + DWP.[AccountNumber] 
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 3 THEN dbo.GetNumOfZero(14) + DWP.[AccountNumber] 
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 4 THEN dbo.GetNumOfZero(13) + DWP.[AccountNumber] 
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 5 THEN dbo.GetNumOfZero(12) + DWP.[AccountNumber] 
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 6 THEN dbo.GetNumOfZero(11) + DWP.[AccountNumber] 
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 7 THEN dbo.GetNumOfZero(10) + DWP.[AccountNumber]
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 8 THEN dbo.GetNumOfZero(9)  + DWP.[AccountNumber]
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 9 THEN dbo.GetNumOfZero(8)  + DWP.[AccountNumber]
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 10 THEN dbo.GetNumOfZero(7) + DWP.[AccountNumber]
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 11 THEN dbo.GetNumOfZero(6) + DWP.[AccountNumber]
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 12 THEN dbo.GetNumOfZero(5) + DWP.[AccountNumber]
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 13 THEN dbo.GetNumOfZero(4) + DWP.[AccountNumber]
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 14 THEN dbo.GetNumOfZero(3) + DWP.[AccountNumber]
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 15 THEN dbo.GetNumOfZero(2) + DWP.[AccountNumber]
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 16 THEN dbo.GetNumOfZero(1) + DWP.[AccountNumber]
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) = 17 THEN UPPER(DWP.[AccountNumber])
					  WHEN LEN(UPPER(ISNULL(DWP.[AccountNumber],''))) > 17 THEN LEFT(UPPER(DWP.[AccountNumber]), 17) 
					  ELSE dbo.GetNumOfZero(17)
				END AS DFIAccountNumber
			   ,CASE WHEN LEN(SUM(ISNULL(VRP.PaymentMade,0))) = 1 THEN '000000000' + CAST(ROUND(SUM(VRP.PaymentMade),0) AS INT) 
				      WHEN LEN(SUM(ISNULL(VRP.PaymentMade,0))) = 2 THEN '00000000' + CAST(ROUND(SUM(VRP.PaymentMade),0) AS INT) 
					  WHEN LEN(SUM(ISNULL(VRP.PaymentMade,0))) = 3 THEN '0000000' + CAST(ROUND(SUM(VRP.PaymentMade),0) AS INT) 
					  WHEN LEN(SUM(ISNULL(VRP.PaymentMade,0))) = 4 THEN '000000' + CAST(ROUND(SUM(VRP.PaymentMade),0) AS INT) 
					  WHEN LEN(SUM(ISNULL(VRP.PaymentMade,0))) = 5 THEN '00000' + CAST(ROUND(SUM(VRP.PaymentMade),0) AS INT) 
					  WHEN LEN(SUM(ISNULL(VRP.PaymentMade,0))) = 6 THEN '0000' + CAST(ROUND(SUM(VRP.PaymentMade),0) AS INT) 
					  WHEN LEN(SUM(ISNULL(VRP.PaymentMade,0))) = 7 THEN '000' + CAST(ROUND(SUM(VRP.PaymentMade),0) AS INT)
					  WHEN LEN(SUM(ISNULL(VRP.PaymentMade,0))) = 8 THEN '00' + CAST(ROUND(SUM(VRP.PaymentMade),0) AS INT)
					  WHEN LEN(SUM(ISNULL(VRP.PaymentMade,0))) = 9 THEN '0' + CAST(ROUND(SUM(VRP.PaymentMade),0) AS INT)
					  WHEN LEN(SUM(ISNULL(VRP.PaymentMade,0))) = 10 THEN CAST(ROUND(SUM(VRP.PaymentMade),0) AS INT)
					  WHEN LEN(SUM(ISNULL(VRP.PaymentMade,0))) > 10 THEN LEFT(CAST(ROUND(SUM(VRP.PaymentMade),0) AS INT),10)
					  ELSE  '0000000000'
				END AS Amount
				,CASE WHEN LEN(UPPER(DWP.[AccountNumber])) <= 15 THEN UPPER(DWP.[AccountNumber]) + SPACE(dbo.GetSpace(15,LEN(DWP.[AccountNumber])))			          
					  WHEN LEN(UPPER(DWP.[AccountNumber])) > 15  THEN LEFT(UPPER(DWP.[AccountNumber]), 15) 
					  ELSE SPACE(15) END AS IdentificationNumber
				,CASE WHEN LEN(UPPER(VN.[VendorName])) <= 22 THEN UPPER(VN.[VendorName]) + SPACE(dbo.GetSpace(22,LEN(VN.[VendorName])))			          
					  WHEN LEN(UPPER(VN.[VendorName])) > 22  THEN LEFT(UPPER(VN.[VendorName]), 22) 
					  ELSE SPACE(22) END AS ReceivingCompanyName
				,' ' AS DiscretionaryData
				,'0'  AS AddendaRecordIndicator
				,'202881060000101' AS TraceNumber  ----   Need to discuss currenty static value	
			   ,VRP.CheckNumber 
			   ,VRP.CheckDate AS 'Date'
			   ,VN.VendorName
			   ,SUM(ISNULL(VRP.PaymentMade,0)) AS PaymentAmount
			   ,DWP.BankName
	 		   ,DWP.AccountNumber
			   ,PM.[Description] AS 'PaymentMethod'			  
			FROM [dbo].[VendorReadyToPayDetails] VRP  WITH(NOLOCK)
			INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRP.VendorId = VN.VendorId
			 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRP.[ReceivingReconciliationId] = RRH.[ReceivingReconciliationId]
			 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRH WITH(NOLOCK) ON VRP.ReadyToPayId = VRH.ReadyToPayId
			 LEFT JOIN [dbo].[VendorDomesticWirePayment] VVP WITH(NOLOCK) ON VVP.VendorId = VN.VendorId
			 LEFT JOIN [dbo].[DomesticWirePayment] DWP WITH(NOLOCK) ON DWP.DomesticWirePaymentId = VVP.DomesticWirePaymentId
			 LEFT JOIN [dbo].[VendorBankAccountType] BAT WITH(NOLOCK) ON DWP.VendorBankAccountTypeId = BAT.VendorBankAccountTypeId			 
			 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VRP.PaymentMethodId			 
			 INNER JOIN [dbo].[EntityStructureSetup] ESS WITH(NOLOCK) ON ESS.EntityStructureId = VRH.ManagementStructureId
			 INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON MSL.ID = ESS.Level1Id
             INNER JOIN [dbo].[LegalEntity] LEE WITH(NOLOCK) ON LEE.LegalEntityId = MSL.LegalEntityId
			 	 
		WHERE (VRP.[MasterCompanyId] = @MasterCompanyId) AND (MSL.LegalEntityId = @LegalEntityId) AND (VRP.[PaymentMethodId] = @ACHTransferPaymentMethodId) AND
			  (@ReadyToPayIds IS NULL OR VRP.ReadyToPayId IN (SELECT Item FROM dbo.SplitString(@ReadyToPayIds,','))) AND
		      (@VendorIds IS NULL OR VRP.VendorId IN (SELECT Item FROM dbo.SplitString(@VendorIds,','))) 		       
			 GROUP BY DWP.ABA,VN.[VendorName],VRP.CheckNumber,VRP.CheckDate,VN.VendorName,DWP.BankName,DWP.AccountNumber,VRP.CheckDate
			         ,VRP.ReadyToPayId,VRP.VendorId,VRP.[PaymentMethodId],PM.[Description],DWP.VendorBankAccountTypeId
		),  
		FinalResult AS (  
		SELECT RecordTypeCode,TransactionCode,ReceivingDFIID,CheckDigit,DFIAccountNumber,Amount,IdentificationNumber,
			   ReceivingCompanyName,DiscretionaryData,AddendaRecordIndicator,TraceNumber,CheckNumber,Date,
			   VendorName,PaymentAmount,BankName,AccountNumber,PaymentMethod
		FROM Result  
		WHERE ( 
		   (@GlobalFilter <>'' AND ((CheckNumber LIKE '%' +@GlobalFilter+'%' ) OR             
		   (VendorName LIKE '%' +@GlobalFilter+'%') OR
		   (BankName LIKE '%' +@GlobalFilter+'%') OR
		   (PaymentAmount LIKE '%' +@GlobalFilter+'%') OR 
		   (PaymentMethod LIKE '%' +@GlobalFilter+'%') OR  
		   (AccountNumber LIKE '%' +@GlobalFilter+'%')))  
		   OR     
		   (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR CheckNumber LIKE  '%'+ @InvoiceNum+'%') AND         
		   (ISNULL(@EntryDate,'') ='' OR CAST([Date] AS DATE) = CAST(@EntryDate AS DATE)) AND  
		   (ISNULL(@InvoiceTotal,'') ='' OR PaymentAmount LIKE '%'+ @InvoiceTotal+'%') AND  
		   (ISNULL(@BankName,'') ='' OR BankName LIKE '%'+ @BankName+'%') AND 
		   (ISNULL(@BankAccountNumber,'') ='' OR AccountNumber LIKE '%'+ @BankAccountNumber+'%') AND 
		   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND 
		   (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%')))
		   ),
		   ResultCount AS (SELECT COUNT(RecordTypeCode) AS NumberOfItems FROM FinalResult)  
		  SELECT RecordTypeCode,TransactionCode,ReceivingDFIID,CheckDigit,DFIAccountNumber,Amount,IdentificationNumber,
		         ReceivingCompanyName,DiscretionaryData,AddendaRecordIndicator,TraceNumber,
				 CheckNumber,Date,VendorName,PaymentAmount,BankName,AccountNumber,PaymentMethod,NumberOfItems
			FROM FinalResult, ResultCount    
		 ORDER BY CASE WHEN (@SortOrder=1  AND @SortColumn='CheckNumber')  THEN CheckNumber END ASC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END ASC,   
				  CASE WHEN (@SortOrder=1  AND @SortColumn='VENDORNAME')  THEN VendorName END ASC,   
				  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='CheckNumber')  THEN CheckNumber END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORNAME')  THEN VendorName END DESC  
		 OFFSET @RecordFrom ROWS   
		 FETCH NEXT @PageSize ROWS ONLY  
    END
	IF(@PaymentMethodId = @ACHTransferPaymentMethodId AND @Opr = 4) -- Batch Footer
    BEGIN
		;WITH Result AS (  
		 SELECT TOP 1 '8' AS RecordTypeCode
		       ,'220' AS ServiceClassCode
			   ,'000002' AS EntryAddendaCount			   
			   ,CASE WHEN LEN(UPPER(ACH.ABA)) = 1 THEN UPPER(ACH.ABA) + SPACE(7)
			         WHEN LEN(UPPER(ACH.ABA)) = 2 THEN UPPER(ACH.ABA) + SPACE(6)
					 WHEN LEN(UPPER(ACH.ABA)) = 3 THEN UPPER(ACH.ABA) + SPACE(5)
					 WHEN LEN(UPPER(ACH.ABA)) = 4 THEN UPPER(ACH.ABA) + SPACE(4)
					 WHEN LEN(UPPER(ACH.ABA)) = 5 THEN UPPER(ACH.ABA) + SPACE(3)
					 WHEN LEN(UPPER(ACH.ABA)) = 6 THEN UPPER(ACH.ABA) + SPACE(2)
					 WHEN LEN(UPPER(ACH.ABA)) = 7 THEN UPPER(ACH.ABA) + SPACE(1)
					 WHEN LEN(UPPER(ACH.ABA)) = 8 THEN UPPER(ACH.ABA) 
					 WHEN LEN(UPPER(ACH.ABA)) > 8 THEN RIGHT(UPPER(ACH.ABA), 8)   					
					 ELSE SPACE(8)
				END AS EntryHash	
			   ,'000000000000' AS TotalDebitEntry ----   Need to discuss currenty static value	
			   ,'000000000000' AS TotalCreditEntry
			   ,'1'+ CASE WHEN LEN(UPPER(LEE.taxId)) = 1 THEN UPPER(LEE.taxId) + SPACE(8)
						   WHEN LEN(UPPER(LEE.taxId)) = 2 THEN UPPER(LEE.taxId) + SPACE(7)
						   WHEN LEN(UPPER(LEE.taxId)) = 3 THEN UPPER(LEE.taxId) + SPACE(6)
						   WHEN LEN(UPPER(LEE.taxId)) = 4 THEN UPPER(LEE.taxId) + SPACE(5)
						   WHEN LEN(UPPER(LEE.taxId)) = 5 THEN UPPER(LEE.taxId) + SPACE(4)
						   WHEN LEN(UPPER(LEE.taxId)) = 6 THEN UPPER(LEE.taxId) + SPACE(3)
						   WHEN LEN(UPPER(LEE.taxId)) = 7 THEN UPPER(LEE.taxId) + SPACE(2)
						   WHEN LEN(UPPER(LEE.taxId)) = 8 THEN UPPER(LEE.taxId) + SPACE(1)
						   WHEN LEN(UPPER(LEE.taxId)) = 9 THEN UPPER(LEE.taxId) + SPACE(0)     
						   WHEN LEN(UPPER(LEE.taxId)) > 9 THEN LEFT(UPPER(LEE.taxId), 9)
					  ELSE SPACE(9) END AS CompanyIdentification
				,SPACE(19) AS MessageAuthenticationCode  
				,SPACE(6) AS Reserved 
				,CASE WHEN LEN(UPPER(ACH.ABA)) = 1 THEN UPPER(ACH.ABA) + SPACE(7)
			         WHEN LEN(UPPER(ACH.ABA)) = 2 THEN UPPER(ACH.ABA) + SPACE(6)
					 WHEN LEN(UPPER(ACH.ABA)) = 3 THEN UPPER(ACH.ABA) + SPACE(5)
					 WHEN LEN(UPPER(ACH.ABA)) = 4 THEN UPPER(ACH.ABA) + SPACE(4)
					 WHEN LEN(UPPER(ACH.ABA)) = 5 THEN UPPER(ACH.ABA) + SPACE(3)
					 WHEN LEN(UPPER(ACH.ABA)) = 6 THEN UPPER(ACH.ABA) + SPACE(2)
					 WHEN LEN(UPPER(ACH.ABA)) = 7 THEN UPPER(ACH.ABA) + SPACE(1)
					 WHEN LEN(UPPER(ACH.ABA)) = 8 THEN UPPER(ACH.ABA) 
					 WHEN LEN(UPPER(ACH.ABA)) > 8 THEN LEFT(UPPER(ACH.ABA), 8)   
					 ELSE SPACE(8)
				END AS OriginatingDFIID	
				,'0000001' AS BatchNumber
			   ,VRP.CheckNumber 
			   ,VRP.CheckDate AS 'Date'
			   ,VN.VendorName
			   ,SUM(ISNULL(VRP.PaymentMade,0)) AS PaymentAmount
			   ,DWP.BankName
	 		   ,DWP.AccountNumber
			   ,PM.[Description] AS 'PaymentMethod'
			  
			FROM [dbo].[VendorReadyToPayDetails] VRP  WITH(NOLOCK)
			INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRP.VendorId = VN.VendorId
			 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRP.[ReceivingReconciliationId] = RRH.[ReceivingReconciliationId]
			 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRH WITH(NOLOCK) ON VRP.ReadyToPayId = VRH.ReadyToPayId
			 LEFT JOIN [dbo].[VendorDomesticWirePayment] VVP WITH(NOLOCK) ON VVP.VendorId = VN.VendorId
			 LEFT JOIN [dbo].[DomesticWirePayment] DWP WITH(NOLOCK) ON DWP.DomesticWirePaymentId = VVP.DomesticWirePaymentId
			 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VRP.PaymentMethodId			 
			 INNER JOIN [dbo].[EntityStructureSetup] ESS WITH(NOLOCK) ON ESS.EntityStructureId = VRH.ManagementStructureId
			 INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON MSL.ID = ESS.Level1Id
             INNER JOIN [dbo].[LegalEntity] LEE WITH(NOLOCK) ON LEE.LegalEntityId = MSL.LegalEntityId
			  LEFT JOIN [dbo].[ACH] ACH WITH(NOLOCK) ON ACH.LegalENtityId = MSL.LegalEntityId AND IsPrimay = 1	
			 	 
		WHERE (VRP.[MasterCompanyId] = @MasterCompanyId) AND (MSL.LegalEntityId = @LegalEntityId) AND (VRP.[PaymentMethodId] = @ACHTransferPaymentMethodId) AND
			  (@ReadyToPayIds IS NULL OR VRP.ReadyToPayId IN (SELECT Item FROM dbo.SplitString(@ReadyToPayIds,','))) AND
		      (@VendorIds IS NULL OR VRP.VendorId IN (SELECT Item FROM dbo.SplitString(@VendorIds,','))) 		       
			 GROUP BY DWP.ABA,VN.[VendorName],VRP.CheckNumber,VRP.CheckDate,VN.VendorName,DWP.BankName,DWP.AccountNumber,VRP.CheckDate
			         ,VRP.ReadyToPayId,VRP.VendorId,VRP.[PaymentMethodId],PM.[Description],LEE.[taxId],ACH.ABA
		),  
		FinalResult AS (  
		SELECT RecordTypeCode,ServiceClassCode,EntryAddendaCount,EntryHash,TotalDebitEntry,TotalCreditEntry,CompanyIdentification,MessageAuthenticationCode,
			   Reserved,OriginatingDFIID,BatchNumber,CheckNumber,Date,
			   VendorName,PaymentAmount,BankName,AccountNumber,PaymentMethod
		FROM Result  
		WHERE ( 
		   (@GlobalFilter <>'' AND ((CheckNumber LIKE '%' +@GlobalFilter+'%' ) OR             
		   (VendorName LIKE '%' +@GlobalFilter+'%') OR
		   (BankName LIKE '%' +@GlobalFilter+'%') OR
		   (PaymentAmount LIKE '%' +@GlobalFilter+'%') OR 
		   (PaymentMethod LIKE '%' +@GlobalFilter+'%') OR  
		   (AccountNumber LIKE '%' +@GlobalFilter+'%')))  
		   OR     
		   (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR CheckNumber LIKE  '%'+ @InvoiceNum+'%') AND         
		   (ISNULL(@EntryDate,'') ='' OR CAST([Date] AS DATE) = CAST(@EntryDate AS DATE)) AND  
		   (ISNULL(@InvoiceTotal,'') ='' OR PaymentAmount LIKE '%'+ @InvoiceTotal+'%') AND  
		   (ISNULL(@BankName,'') ='' OR BankName LIKE '%'+ @BankName+'%') AND 
		   (ISNULL(@BankAccountNumber,'') ='' OR AccountNumber LIKE '%'+ @BankAccountNumber+'%') AND 
		   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND 
		   (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%')))
		   ),
		   ResultCount AS (SELECT COUNT(RecordTypeCode) AS NumberOfItems FROM FinalResult)  
			 SELECT RecordTypeCode,ServiceClassCode,EntryAddendaCount,EntryHash,TotalDebitEntry,TotalCreditEntry,
			       CompanyIdentification,MessageAuthenticationCode,
				   Reserved,OriginatingDFIID,BatchNumber,CheckNumber,Date,
				   VendorName,PaymentAmount,BankName,AccountNumber,PaymentMethod,NumberOfItems
			FROM FinalResult, ResultCount    
		 ORDER BY CASE WHEN (@SortOrder=1  AND @SortColumn='CheckNumber')  THEN CheckNumber END ASC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END ASC,   
				  CASE WHEN (@SortOrder=1  AND @SortColumn='VENDORNAME')  THEN VendorName END ASC,   
				  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='CheckNumber')  THEN CheckNumber END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORNAME')  THEN VendorName END DESC  
		 OFFSET @RecordFrom ROWS   
		 FETCH NEXT @PageSize ROWS ONLY  
    END
	IF(@PaymentMethodId = @ACHTransferPaymentMethodId AND @Opr = 5) -- File Footer
    BEGIN
		;WITH Result AS (  
		 SELECT TOP 1 '9' AS RecordTypeCode
		        ,'000001' AS BatchCount
				,'000001' AS BlockCount
				,'00000001' AS EntryAddendaCount								
			    ,CASE WHEN LEN(UPPER(ACH.ABA)) = 1 THEN UPPER(ACH.ABA) + SPACE(7)
			         WHEN LEN(UPPER(ACH.ABA)) = 2 THEN UPPER(ACH.ABA) + SPACE(6)
					 WHEN LEN(UPPER(ACH.ABA)) = 3 THEN UPPER(ACH.ABA) + SPACE(5)
					 WHEN LEN(UPPER(ACH.ABA)) = 4 THEN UPPER(ACH.ABA) + SPACE(4)
					 WHEN LEN(UPPER(ACH.ABA)) = 5 THEN UPPER(ACH.ABA) + SPACE(3)
					 WHEN LEN(UPPER(ACH.ABA)) = 6 THEN UPPER(ACH.ABA) + SPACE(2)
					 WHEN LEN(UPPER(ACH.ABA)) = 7 THEN UPPER(ACH.ABA) + SPACE(1)
					 WHEN LEN(UPPER(ACH.ABA)) = 8 THEN UPPER(ACH.ABA) 
					 WHEN LEN(UPPER(ACH.ABA)) > 8 THEN RIGHT(UPPER(ACH.ABA), 8)   					
					 ELSE SPACE(8)
				END AS EntryHash
				,'000000000000' AS TotalDebitEntry
				,'000000000000' AS TotalCreditEntry
				,SPACE(39) AS Reserved  
			   ,VRP.CheckNumber 
			   ,VRP.CheckDate AS 'Date'
			   ,VN.VendorName
			   ,SUM(ISNULL(VRP.PaymentMade,0)) AS PaymentAmount
			   ,DWP.BankName
	 		   ,DWP.AccountNumber
			   ,PM.[Description] AS 'PaymentMethod'
			  
			FROM [dbo].[VendorReadyToPayDetails] VRP  WITH(NOLOCK)
			INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRP.VendorId = VN.VendorId
			 LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRP.[ReceivingReconciliationId] = RRH.[ReceivingReconciliationId]
			 LEFT JOIN [dbo].[VendorReadyToPayHeader] VRH WITH(NOLOCK) ON VRP.ReadyToPayId = VRH.ReadyToPayId
			 LEFT JOIN [dbo].[VendorDomesticWirePayment] VVP WITH(NOLOCK) ON VVP.VendorId = VN.VendorId
			 LEFT JOIN [dbo].[DomesticWirePayment] DWP WITH(NOLOCK) ON DWP.DomesticWirePaymentId = VVP.DomesticWirePaymentId
			 LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VRP.PaymentMethodId			 
			 INNER JOIN [dbo].[EntityStructureSetup] ESS WITH(NOLOCK) ON ESS.EntityStructureId = VRH.ManagementStructureId
			 INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON MSL.ID = ESS.Level1Id
             INNER JOIN [dbo].[LegalEntity] LEE WITH(NOLOCK) ON LEE.LegalEntityId = MSL.LegalEntityId
			  LEFT JOIN [dbo].[ACH] ACH WITH(NOLOCK) ON ACH.LegalENtityId = MSL.LegalEntityId AND IsPrimay = 1	
			 	 
		WHERE (VRP.[MasterCompanyId] = @MasterCompanyId) AND (MSL.LegalEntityId = @LegalEntityId) AND (VRP.[PaymentMethodId] = @ACHTransferPaymentMethodId) AND
			  (@ReadyToPayIds IS NULL OR VRP.ReadyToPayId IN (SELECT Item FROM dbo.SplitString(@ReadyToPayIds,','))) AND
		      (@VendorIds IS NULL OR VRP.VendorId IN (SELECT Item FROM dbo.SplitString(@VendorIds,','))) 		       
			 GROUP BY DWP.ABA,VN.[VendorName],VRP.CheckNumber,VRP.CheckDate,VN.VendorName,DWP.BankName,DWP.AccountNumber,VRP.CheckDate
			         ,VRP.ReadyToPayId,VRP.VendorId,VRP.[PaymentMethodId],PM.[Description],ACH.ABA
		),  
		FinalResult AS (  
		SELECT RecordTypeCode,BatchCount,BlockCount,EntryHash,EntryAddendaCount,TotalDebitEntry,
			   Reserved,TotalCreditEntry,CheckNumber,Date,VendorName,PaymentAmount,BankName,AccountNumber,PaymentMethod
		FROM Result  
		WHERE ( 
		   (@GlobalFilter <>'' AND ((CheckNumber LIKE '%' +@GlobalFilter+'%' ) OR             
		   (VendorName LIKE '%' +@GlobalFilter+'%') OR
		   (BankName LIKE '%' +@GlobalFilter+'%') OR
		   (PaymentAmount LIKE '%' +@GlobalFilter+'%') OR 
		   (PaymentMethod LIKE '%' +@GlobalFilter+'%') OR  
		   (AccountNumber LIKE '%' +@GlobalFilter+'%')))  
		   OR     
		   (@GlobalFilter='' AND (ISNULL(@InvoiceNum,'') ='' OR CheckNumber LIKE  '%'+ @InvoiceNum+'%') AND         
		   (ISNULL(@EntryDate,'') ='' OR CAST([Date] AS DATE) = CAST(@EntryDate AS DATE)) AND  
		   (ISNULL(@InvoiceTotal,'') ='' OR PaymentAmount LIKE '%'+ @InvoiceTotal+'%') AND  
		   (ISNULL(@BankName,'') ='' OR BankName LIKE '%'+ @BankName+'%') AND 
		   (ISNULL(@BankAccountNumber,'') ='' OR AccountNumber LIKE '%'+ @BankAccountNumber+'%') AND 
		   (ISNULL(@PaymentMethod,'') ='' OR PaymentMethod LIKE '%'+ @PaymentMethod+'%') AND 
		   (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName +'%')))
		   ),
		   ResultCount AS (SELECT COUNT(RecordTypeCode) AS NumberOfItems FROM FinalResult)  
			 SELECT RecordTypeCode,BatchCount,BlockCount,EntryHash,EntryAddendaCount,EntryHash,TotalDebitEntry,
			   Reserved,TotalCreditEntry,CheckNumber,Date,
			   VendorName,PaymentAmount,BankName,AccountNumber,PaymentMethod,NumberOfItems
			FROM FinalResult, ResultCount    
		 ORDER BY CASE WHEN (@SortOrder=1  AND @SortColumn='CheckNumber')  THEN CheckNumber END ASC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END ASC,   
				  CASE WHEN (@SortOrder=1  AND @SortColumn='VENDORNAME')  THEN VendorName END ASC,   
				  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='CheckNumber')  THEN CheckNumber END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='PAYMENTMETHOD')  THEN PaymentMethod END DESC,  
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORNAME')  THEN VendorName END DESC  
		 OFFSET @RecordFrom ROWS   
		 FETCH NEXT @PageSize ROWS ONLY  
    END	
	
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'      
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'VendorPositivePayExportACHList'   
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