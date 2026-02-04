



/*************************************************************                   
 ** File:  [usprpt_GetAPDisbursementReportByPayeeSSRS]                   
 ** Author: Priyansh Patel     
 ** Description: Get Data for AP Disbursement Report        
 ** Purpose:                 
 ** Date:   28-Jan-2026              
                  
 ** PARAMETERS:                   
                 
 ** RETURN VALUE:                   
          

 **************************************************************                   
  ** Change History                   
 *************************************************************************************************                   
 ** S NO   Date            Author          Change Description                    
 ** --   --------         -------          --------------------------------                  
    1    28-Jan-2026    Priyansh Patel		   Created    
    
 EXEC dbo.usprpt_GetAPDisbursementReportByPayeeSSRS
    @MasterCompanyId = 1 , @PageNumber =1 , @PageSize = 10, @EmployeeId = 2

***************************************************************************************************/   

CREATE              PROCEDURE [dbo].[usprpt_GetAPDisbursementReportByPayeeSSRS]
@FromPaymentDate DATE = NULL,
@ToPaymentDate DATE = NULL,
@Payee VARCHAR(200) = NULL,
@PaymentRef VARCHAR(100) = NULL,
@InvoiceNum VARCHAR(100) = NULL,
@MasterCompanyId INT,
@EmployeeId bigint,

@InvoiceDate        DATE = NULL,
@InvoiceDueDate     DATE = NULL,
@PaymentDate        DATE = NULL,
@PaymentReference   VARCHAR(100) = NULL,
@BankAccount        VARCHAR(200) = NULL,
@BaseCurrency       VARCHAR(50) = NULL,
@GlAccountNum       VARCHAR(200) = NULL,
@PaymentMethod      VARCHAR(50) = NULL,
@BaseCurrencyAmount DECIMAL(18,2) = NULL,

@StrFilter VARCHAR(MAX) = NULL , 


@PageNumber INT = 1,
@PageSize INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    DECLARE @IsMultiCurrency BIT = 0;

  BEGIN TRY

   DECLARE	@level1Ids VARCHAR(MAX) = NULL,    
			@level2Ids VARCHAR(MAX) = NULL,    
			@level3Ids VARCHAR(MAX) = NULL,    
			@level4Ids VARCHAR(MAX) = NULL,    
			@level5Ids VARCHAR(MAX) = NULL,    
			@level6Ids VARCHAR(MAX) = NULL,    
			@level7Ids VARCHAR(MAX) = NULL,    
			@level8Ids VARCHAR(MAX) = NULL,    
			@level9Ids VARCHAR(MAX) = NULL,    
			@level10Ids VARCHAR(MAX) = NULL 

     IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPMSFilter
	END

	CREATE TABLE #TEMPMSFilter([ID] BIGINT  IDENTITY(1,1),[LevelIds] VARCHAR(MAX)); 

	INSERT INTO #TEMPMSFilter(LevelIds)	SELECT Item FROM DBO.SPLITSTRING(@strFilter,'!');

	SELECT @level1Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 1 
	SELECT @level2Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 2 
	SELECT @level3Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 3 
	SELECT @level4Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 4 
	SELECT @level5Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 5 
	SELECT @level6Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 6 
	SELECT @level7Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 7 
	SELECT @level8Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 8 
	SELECT @level9Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 9 
	SELECT @level10Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 10	 

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


                    
       IF OBJECT_ID(N'tempdb..#tmprAPDisbursementReport') IS NOT NULL
       BEGIN
			DROP TABLE #tmprAPDisbursementReport
	   END


CREATE TABLE #tmprAPDisbursementReport
(
    Payee NVARCHAR(200),
    VendorCode NVARCHAR(50),
    InvoiceNum NVARCHAR(100) NULL,
    InvoiceDate DATE NULL,
    PaymentMethod NVARCHAR(100) NULL,
    PaymentReference NVARCHAR(100) NULL,
    PaymentDate DATE NULL,
    InvoiceDueDate DATE NULL,
    TotalBaseCurrencyAmount DECIMAL(18,2) NULL,
    BaseCurrency NVARCHAR(50),
    BaseCurrencyAmount DECIMAL(18,2),
    BaseCurrencyAmounts1 NVARCHAR(MAX),
    BankAccount NVARCHAR(200),
    GLAccountNum NVARCHAR(200),
    Level1Id NVARCHAR(200),
    Level2Id NVARCHAR(200),
    Level3Id NVARCHAR(200),
    Level4Id NVARCHAR(200),
    Level5Id NVARCHAR(200),
    Level6Id NVARCHAR(200),
    Level7Id NVARCHAR(200),
    Level8Id NVARCHAR(200),
    Level9Id NVARCHAR(200),
    Level10Id NVARCHAR(200)
);

    INSERT INTO #tmprAPDisbursementReport
    (
         Payee, VendorCode,
        InvoiceNum, InvoiceDate, PaymentMethod, PaymentReference,
        PaymentDate, InvoiceDueDate, TotalBaseCurrencyAmount,
        BaseCurrency, BaseCurrencyAmount,
        BankAccount, GLAccountNum,
        Level1Id, Level2Id, Level3Id, Level4Id, Level5Id,
        Level6Id, Level7Id, Level8Id, Level9Id, Level10Id
    )
  SELECT
            MAX(rtp.VendorName)  AS 'Payee',
            MAX(VND.VendorCode)  AS 'VendorCode',
            NULL AS 'InvoiceNum',
            NULL AS 'InvoiceDate',
            NULL AS 'PaymentMethod',
            NULL AS 'PaymentReference',
            NULL AS 'PaymentDate',
            NULL AS 'InvoiceDueDate',
            NULL AS 'TotalBaseCurrencyAmount',

            MAX(rtp.CurrencyName) AS 'BaseCurrency',
            SUM(rtp.PaymentMade) AS 'BaseCurrencyAmount',
            --vpym.Description                                AS 'PaymentMethod',
            --rtp.CheckNumber                                 AS 'PaymentReference',
                                          
            --(Cast(DBO.ConvertUTCtoLocal(rtp.CheckDate,@CurrntEmpTimeZoneDesc)AS DATETIME))  AS 'PaymentDate',
            -- (Cast(DBO.ConvertUTCtoLocal(rtp.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS 'InvoiceDueDate',
            MAX(CONCAT(lebl.BankName, ' - ', lebl.BankAccountNumber)) 
                                                    AS 'BankAccount',
            MAX( CONCAT(g.AccountCode, ' - ', g.AccountName))      AS 'GLAccountNum',

             MAX(CONCAT(L1.Code, ' - ', L1.Description))  AS [Level1Id],
              MAX(CONCAT(L2.Code, ' - ', L2.Description))  AS [Level2Id],
              MAX(CONCAT(L3.Code, ' - ', L3.Description))  AS [Level3Id],
              MAX(CONCAT(L4.Code, ' - ', L4.Description))  AS [Level4Id],
              MAX(CONCAT(L5.Code, ' - ', L5.Description))  AS [Level5Id],
              MAX(CONCAT(L6.Code, ' - ', L6.Description))  AS [Level6Id],
              MAX(CONCAT(L7.Code, ' - ', L7.Description))  AS [Level7Id],
              MAX(CONCAT(L8.Code, ' - ', L8.Description))  AS [Level8Id],
              MAX(CONCAT(L9.Code, ' - ', L9.Description))  AS [Level9Id],
              MAX(CONCAT(L10.Code, ' - ', L10.Description))  AS [Level10Id]

            FROM [dbo].[VendorReadyToPayDetails] rtp WITH(NOLOCK)

            INNER JOIN [dbo].[VendorPaymentDetails] vpd WITH(NOLOCK)
            ON vpd.VendorPaymentDetailsId = rtp.VendorPaymentDetailsId

            LEFT JOIN [dbo].[ReceivingReconciliationHeader] RRC WITH(NOLOCK) ON VPD.[ReceivingReconciliationId] = RRC.[ReceivingReconciliationId]	
			LEFT JOIN [dbo].[CreditMemo] CM WITH(NOLOCK) ON VPD.CreditMemoHeaderId = CM.CreditMemoHeaderId
			LEFT JOIN [dbo].[NonPOInvoiceHeader] NPH  WITH(NOLOCK) ON VPD.NonPOInvoiceId = NPH.NonPOInvoiceId
			LEFT JOIN [dbo].[CustomerCreditPaymentDetail] CCPD WITH(NOLOCK) ON VPD.CustomerCreditPaymentDetailId = CCPD.CustomerCreditPaymentDetailId	
			LEFT JOIN [dbo].[VendorProformaInvoiceHeader] VNPH WITH(NOLOCK) ON VPD.VendorProformaInvoiceId = VNPH.VendorProformaInvoiceId 
            LEFT JOIN [dbo].[Vendor] VND WITH(NOLOCK) ON VND.VendorId = rtp.VendorId 

    LEFT JOIN [dbo].[VendorPaymentMethod] vpym WITH(NOLOCK)
        ON vpym.VendorPaymentMethodId = rtp.PaymentMethodId

    LEFT JOIN [dbo].[VendorReadyToPayHeader] vrtph WITH(NOLOCK)
        ON vrtph.ReadyToPayId = rtp.ReadyToPayId
       AND vrtph.MasterCompanyId = rtp.MasterCompanyId

    LEFT JOIN [dbo].[EntityStructureSetup] ess WITH(NOLOCK)
        ON ess.EntityStructureId = vrtph.ManagementStructureId
       AND ess.MasterCompanyId = rtp.MasterCompanyId

    LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK)
        ON lebl.LegalEntityId = vpd.LegalEntityId
       AND lebl.AccountTypeId = 2
       AND lebl.IsPrimay = 1
       AND lebl.IsActive = 1
       AND lebl.IsDeleted = 0

    LEFT JOIN [dbo].[GLAccount] g WITH(NOLOCK)
        ON g.GLAccountId = lebl.GLAccountId

    -- Management Structure Levels
    LEFT JOIN [dbo].[ManagementStructureLevel] L1 WITH(NOLOCK) 
        ON L1.ID = ess.Level1Id AND L1.IsActive = 1 AND L1.IsDeleted = 0
    LEFT JOIN [dbo].[ManagementStructureLevel] L2 WITH(NOLOCK) 
        ON L2.ID = ess.Level2Id AND L2.IsActive = 1 AND L2.IsDeleted = 0
    LEFT JOIN [dbo].[ManagementStructureLevel] L3 WITH(NOLOCK) 
        ON L3.ID = ess.Level3Id AND L3.IsActive = 1 AND L3.IsDeleted = 0
    LEFT JOIN [dbo].[ManagementStructureLevel] L4 WITH(NOLOCK) 
        ON L4.ID = ess.Level4Id AND L4.IsActive = 1 AND L4.IsDeleted = 0
    LEFT JOIN [dbo].[ManagementStructureLevel] L5 WITH(NOLOCK) 
        ON L5.ID = ess.Level5Id AND L5.IsActive = 1 AND L5.IsDeleted = 0
    LEFT JOIN [dbo].[ManagementStructureLevel] L6 WITH(NOLOCK) 
        ON L6.ID = ess.Level6Id AND L6.IsActive = 1 AND L6.IsDeleted = 0
    LEFT JOIN [dbo].[ManagementStructureLevel] L7 WITH(NOLOCK) 
        ON L7.ID = ess.Level7Id AND L7.IsActive = 1 AND L7.IsDeleted = 0
    LEFT JOIN [dbo].[ManagementStructureLevel] L8 WITH(NOLOCK) 
        ON L8.ID = ess.Level8Id AND L8.IsActive = 1 AND L8.IsDeleted = 0
    LEFT JOIN [dbo].[ManagementStructureLevel] L9 WITH(NOLOCK) 
        ON L9.ID = ess.Level9Id AND L9.IsActive = 1 AND L9.IsDeleted = 0
    LEFT JOIN [dbo].[ManagementStructureLevel] L10 WITH(NOLOCK) 
        ON L10.ID = ess.Level10Id AND L10.IsActive = 1 AND L10.IsDeleted = 0

      WHERE rtp.IsVoidedCheck = 0
            AND rtp.IsGenerated   = 1
            AND rtp.IsActive      = 1
            AND rtp.IsDeleted     = 0
            AND rtp.MasterCompanyId = @MasterCompanyId

            AND (@FromPaymentDate IS NULL OR CAST(rtp.CheckDate AS DATE) >= CAST(@FromPaymentDate AS DATE))
            AND (@ToPaymentDate IS NULL OR CAST(rtp.CheckDate AS DATE) <= CAST(@ToPaymentDate AS DATE))
            AND (@Payee       IS NULL OR rtp.VendorName LIKE '%' + @Payee + '%')

            AND (@InvoiceNum IS NULL OR 
                    ((ISNULL(VPD.ReceivingReconciliationId,0) > 0 AND RRC.InvoiceNum LIKE '%' + @InvoiceNum + '%')
                        OR (ISNULL(VPD.CreditMemoHeaderId,0) > 0 AND CM.InvoiceNumber LIKE '%' + @InvoiceNum + '%')
                        OR (ISNULL(VPD.NonPOInvoiceId,0) > 0 AND NPH.InvoiceNumber LIKE '%' + @InvoiceNum + '%')
                        OR (ISNULL(VPD.CustomerCreditPaymentDetailId,0) > 0 AND CCPD.ReferenceNumber LIKE '%' + @InvoiceNum + '%')
                        OR (ISNULL(VPD.VendorProformaInvoiceId,0) > 0 AND VNPH.InvoiceNumber LIKE '%' + @InvoiceNum + '%')
                    ))
            AND (@PaymentRef IS NULL OR rtp.CheckNumber LIKE '%' + @PaymentRef + '%')
            AND (@PaymentReference IS NULL OR rtp.CheckNumber LIKE '%' + @PaymentReference + '%')

            AND (@BankAccount IS NULL OR CONCAT(lebl.BankName,' - ',lebl.BankAccountNumber) LIKE '%' + @BankAccount + '%')
            AND (@BaseCurrency IS NULL OR rtp.CurrencyName LIKE '%' + @BaseCurrency + '%')
            AND (@GlAccountNum IS NULL OR CONCAT(g.AccountCode,' - ',g.AccountName) LIKE '%' + @GlAccountNum + '%')
            AND (@PaymentMethod IS NULL OR vpym.Description LIKE '%' + @PaymentMethod + '%')

            AND (@BaseCurrencyAmount IS NULL OR rtp.OriginalAmount = @BaseCurrencyAmount)
            -- Column date filters
            AND (
                @InvoiceDate IS NULL OR
                (
                    (ISNULL(VPD.ReceivingReconciliationId,0) > 0 AND CAST(RRC.InvoiceDate AS DATE) = CAST(@InvoiceDate AS DATE))
                    OR (ISNULL(VPD.CreditMemoHeaderId,0) > 0 AND CAST(CM.InvoiceDate AS DATE) = CAST(@InvoiceDate AS DATE) )
                    OR (ISNULL(VPD.NonPOInvoiceId,0) > 0 AND CAST(NPH.InvoiceDate AS DATE) = CAST(@InvoiceDate AS DATE) )
                    OR (ISNULL(VPD.CustomerCreditPaymentDetailId,0) > 0 AND CAST(CCPD.ProcessedDate AS DATE) = CAST(@InvoiceDate AS DATE) )
                    OR (ISNULL(VPD.VendorProformaInvoiceId,0) > 0 AND CAST(VNPH.InvoiceDate AS DATE) = CAST(@InvoiceDate AS DATE) )
                )
            )

            AND (@InvoiceDueDate IS NULL OR CAST(rtp.DueDate AS DATE) = CAST( @InvoiceDueDate AS DATE))
            AND (@PaymentDate IS NULL OR CAST(rtp.CheckDate AS DATE) = CAST( @PaymentDate AS DATE) )
        

            AND (ISNULL(@level1Ids,'') =''  OR ess.Level1Id  IN (SELECT Item FROM DBO.SPLITSTRING(@level1Ids,',')))    
	        AND (ISNULL(@level2Ids,'') =''  OR ess.Level2Id  IN (SELECT Item FROM DBO.SPLITSTRING(@level2Ids,',')))    
	        AND (ISNULL(@level3Ids,'') =''  OR ess.Level3Id  IN (SELECT Item FROM DBO.SPLITSTRING(@level3Ids,',')))    
	        AND (ISNULL(@level4Ids,'') =''  OR ess.Level4Id  IN (SELECT Item FROM DBO.SPLITSTRING(@level4Ids,',')))    
	        AND (ISNULL(@level5Ids,'') =''  OR ess.Level5Id  IN (SELECT Item FROM DBO.SPLITSTRING(@level5Ids,',')))    
	        AND (ISNULL(@level6Ids,'') =''  OR ess.Level6Id  IN (SELECT Item FROM DBO.SPLITSTRING(@level6Ids,',')))    
	        AND (ISNULL(@level7Ids,'') =''  OR ess.Level7Id  IN (SELECT Item FROM DBO.SPLITSTRING(@level7Ids,',')))    
	        AND (ISNULL(@level8Ids,'') =''  OR ess.Level8Id  IN (SELECT Item FROM DBO.SPLITSTRING(@level8Ids,',')))    
	        AND (ISNULL(@level9Ids,'') =''  OR ess.Level9Id  IN (SELECT Item FROM DBO.SPLITSTRING(@level9Ids,',')))    
	        AND (ISNULL(@level10Ids,'') ='' OR ess.Level10Id IN (SELECT Item FROM DBO.SPLITSTRING(@level10Ids,',')))


            GROUP BY rtp.VendorId
            
    -- Pagination
        SELECT *
        FROM #tmprAPDisbursementReport
        ORDER BY Payee
        OFFSET 
            CASE 
                WHEN @PageSize IS NULL THEN 0
                ELSE (@PageNumber - 1) * @PageSize
            END ROWS
        FETCH NEXT 
            CASE 
                WHEN @PageSize IS NULL THEN NULL
                ELSE @PageSize
            END ROWS ONLY;

        -- Total Records Count
        SELECT COUNT(*) AS TotalRecords
        FROM #tmprAPDisbursementReport;


END TRY
BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------

                @AdhocComments VARCHAR(150) = '[usprpt_GetAPDisbursementReportByPayeeSSRS]',
                @ProcedureParameters VARCHAR(3000) =
                    '@PageNumber = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100)) +
                    '@PageSize = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) +
                    '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)),
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC SplogexceptiON
             @DatabaseName = @DatabaseName,
             @AdhocComments = @AdhocComments,
             @ProcedureParameters = @ProcedureParameters,
             @ApplicationName = @ApplicationName,
             @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16, 1, @ErrorLogID
        );

        RETURN (1);
END CATCH
END