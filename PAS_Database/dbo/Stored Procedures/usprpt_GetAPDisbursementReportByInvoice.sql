
CREATE PROCEDURE [dbo].[usprpt_GetAPDisbursementReportByInvoice]
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
@BankAccount        VARCHAR(200) = NULL,
@BaseCurrency       VARCHAR(50) = NULL,
@GlAccountNum       VARCHAR(200) = NULL,
@PaymentMethod      VARCHAR(50) = NULL,
@BaseCurrencyAmount DECIMAL(18,2) = NULL,
@CreditTermsName    VARCHAR(50) = NULL,
@Level1  VARCHAR(MAX) = NULL,
@Level2  VARCHAR(MAX) = NULL,
@Level3  VARCHAR(MAX) = NULL,
@Level4  VARCHAR(MAX) = NULL,
@Level5  VARCHAR(MAX) = NULL,
@Level6  VARCHAR(MAX) = NULL,
@Level7  VARCHAR(MAX) = NULL,
@Level8  VARCHAR(MAX) = NULL,
@Level9  VARCHAR(MAX) = NULL,
@Level10 VARCHAR(MAX) = NULL,

@PageNumber INT = 1,
@PageSize INT = NULL,
@SortColumn VARCHAR(50)=NULL,
@SortOrder INT = NULL,
@ViewType  VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

  BEGIN TRY

    DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	
    SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], -- Prefer Employee's TimeZone description if available 
    LTZ.[Description] )  -- Fallback to LegalEntity's TimeZone description
    FROM [dbo].[Employee] E WITH (NOLOCK) LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
    LEFT JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
    LEFT JOIN [dbo].[TimeZone] LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
    WHERE E.EmployeeId = @EmployeeId;	


    -- Set sort column
    IF @SortColumn IS NULL
    BEGIN
        SET @SortColumn = UPPER('InvoiceNum');
    END
    ELSE
    BEGIN
        SET @SortColumn = UPPER(@SortColumn);
    END

    IF OBJECT_ID(N'tempdb..#tmprAPDisbursementReportInvoice') IS NOT NULL
       BEGIN
			DROP TABLE #tmprAPDisbursementReportInvoice
	   END


 CREATE TABLE #tmprAPDisbursementReportInvoice
(   VendorId INT NULL,
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
    BankAccount NVARCHAR(200),
    GLAccountNum NVARCHAR(200),
    CreditTermsName NVARCHAR(30) NULL,
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


  INSERT INTO #tmprAPDisbursementReportInvoice
    (
        VendorId,Payee, VendorCode,
        InvoiceNum, InvoiceDate, PaymentMethod, PaymentReference,
        PaymentDate, InvoiceDueDate, TotalBaseCurrencyAmount,
        BaseCurrency, BaseCurrencyAmount,
        BankAccount, GLAccountNum,
        CreditTermsName,
        Level1Id, Level2Id, Level3Id, Level4Id, Level5Id,
        Level6Id, Level7Id, Level8Id, Level9Id, Level10Id
    )

    SELECT   MAX(rtp.VendorId)  AS 'VendorId',
    MAX(VND.VendorName)  AS 'Payee',MAX(VND.VendorCode)  AS 'VendorCode',
         CASE 
            	WHEN ISNULL(VPD.ReceivingReconciliationId,0) > 0 THEN RRC.InvoiceNum
            	WHEN ISNULL(VPD.CreditMemoHeaderId,0) > 0 THEN CM.InvoiceNumber
            	WHEN ISNULL(VPD.NonPOInvoiceId,0) > 0  THEN NPH.InvoiceNumber
            	WHEN ISNULL(VPD.CustomerCreditPaymentDetailId,0) > 0 THEN CCPD.ReferenceNumber
            	WHEN ISNULL(VPD.VendorProformaInvoiceId,0) > 0 THEN VNPH.InvoiceNumber
				WHEN ISNULL(VPD.ManualJournalHeaderId,0) > 0 THEN VPD.[InvoiceNum]
            END AS 'InvoiceNum',
            CASE 
            	WHEN ISNULL(VPD.ReceivingReconciliationId,0) > 0 THEN CAST(RRC.InvoiceDate AS DATE)
            	WHEN ISNULL(VPD.CreditMemoHeaderId,0) > 0 THEN CAST(CM.InvoiceDate AS DATE)
            	WHEN ISNULL(VPD.NonPOInvoiceId,0) > 0  THEN CAST(NPH.InvoiceDate AS DATE)
            	WHEN ISNULL(VPD.CustomerCreditPaymentDetailId,0) > 0 THEN CAST(CCPD.ProcessedDate AS DATE)
            	WHEN ISNULL(VPD.VendorProformaInvoiceId,0) > 0 THEN CAST(VNPH.InvoiceDate AS DATE)
				WHEN ISNULL(VPD.ManualJournalHeaderId,0) > 0 THEN CAST(MJH.PostedDate AS DATE)
            END AS 'InvoiceDate',
            MAX(vpym.Description)                                AS 'PaymentMethod',
            MAX(rtp.CheckNumber)                                AS 'PaymentReference',
            MAX( (Cast(DBO.ConvertUTCtoLocal(rtp.CheckDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))  AS 'PaymentDate',
            --MAX((Cast(DBO.ConvertUTCtoLocal(rtp.DueDate,@CurrntEmpTimeZoneDesc)AS DATETIME))) AS 'InvoiceDueDate',
			MAX(rtp.DueDate) AS 'InvoiceDueDate',
          --  NULL AS 'InvoiceDueDate',
            NULL AS 'TotalBaseCurrencyAmount',
            MAX(rtp.CurrencyName)                             AS 'BaseCurrency',
            SUM(rtp.PaymentMade)                     AS 'BaseCurrencyAmount',
             
            MAX(CONCAT(lebl.BankName, ' - ', lebl.BankAccountNumber))  AS 'BankAccount',
            MAX( g.AccountCode)      AS 'GLAccountNum',
            MAX(CT.Name) AS 'CreditTermsName',
            MAX(L1.Code)  AS [Level1Id],
            MAX(L2.Code)  AS [Level2Id],
            MAX(L3.Code)  AS [Level3Id],
            MAX(L4.Code)  AS [Level4Id],
            MAX(L5.Code)  AS [Level5Id],
            MAX(L6.Code)  AS [Level6Id],
            MAX(L7.Code)  AS [Level7Id],
            MAX(L8.Code)  AS [Level8Id],
            MAX(L9.Code)  AS [Level9Id],
            MAX(L10.Code) AS [Level10Id]

            FROM [dbo].[VendorReadyToPayDetails] rtp WITH(NOLOCK)
            INNER JOIN [dbo].[VendorPaymentDetails] vpd WITH(NOLOCK)  ON vpd.VendorPaymentDetailsId = rtp.VendorPaymentDetailsId
            INNER JOIN [dbo].[Vendor] VND WITH(NOLOCK) ON VND.VendorId = rtp.VendorId 
            LEFT JOIN [dbo].[ReceivingReconciliationHeader] RRC WITH(NOLOCK) ON VPD.[ReceivingReconciliationId] = RRC.[ReceivingReconciliationId]	
			LEFT JOIN [dbo].[CreditMemo] CM WITH(NOLOCK) ON VPD.CreditMemoHeaderId = CM.CreditMemoHeaderId
			LEFT JOIN [dbo].[NonPOInvoiceHeader] NPH  WITH(NOLOCK) ON VPD.NonPOInvoiceId = NPH.NonPOInvoiceId
			LEFT JOIN [dbo].[CustomerCreditPaymentDetail] CCPD WITH(NOLOCK) ON VPD.CustomerCreditPaymentDetailId = CCPD.CustomerCreditPaymentDetailId	
			LEFT JOIN [dbo].[VendorProformaInvoiceHeader] VNPH WITH(NOLOCK) ON VPD.VendorProformaInvoiceId = VNPH.VendorProformaInvoiceId 
			LEFT JOIN [dbo].[ManualJournalHeader] MJH WITH(NOLOCK) ON VPD.[ManualJournalHeaderId] = MJH.[ManualJournalHeaderId]	
            
            LEFT JOIN [dbo].[VendorPaymentMethod] vpym WITH(NOLOCK) ON vpym.VendorPaymentMethodId = rtp.PaymentMethodId
            LEFT JOIN [dbo].[VendorReadyToPayHeader] vrtph WITH(NOLOCK) ON vrtph.ReadyToPayId = rtp.ReadyToPayId AND vrtph.MasterCompanyId = rtp.MasterCompanyId
            LEFT JOIN [dbo].[EntityStructureSetup] ess WITH(NOLOCK) ON ess.EntityStructureId = vrtph.ManagementStructureId AND ess.MasterCompanyId = rtp.MasterCompanyId
            LEFT JOIN [dbo].[LegalEntityBankingLockBox] lebl WITH(NOLOCK) ON lebl.LegalEntityId = vpd.LegalEntityId AND lebl.AccountTypeId = 2 AND lebl.IsPrimay = 1  AND lebl.IsActive = 1 AND lebl.IsDeleted = 0
            LEFT JOIN [dbo].[GLAccount] g WITH(NOLOCK) ON g.GLAccountId = lebl.GLAccountId
             LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CT.CreditTermsId = VND.CreditTermsId AND CT.IsActive = 1

           -- Management Structure Levels
            LEFT JOIN [dbo].[ManagementStructureLevel] L1 WITH(NOLOCK) ON L1.ID = ess.Level1Id AND L1.IsActive = 1 AND L1.IsDeleted = 0
            LEFT JOIN [dbo].[ManagementStructureLevel] L2 WITH(NOLOCK) ON L2.ID = ess.Level2Id AND L2.IsActive = 1 AND L2.IsDeleted = 0
            LEFT JOIN [dbo].[ManagementStructureLevel] L3 WITH(NOLOCK) ON L3.ID = ess.Level3Id AND L3.IsActive = 1 AND L3.IsDeleted = 0
            LEFT JOIN [dbo].[ManagementStructureLevel] L4 WITH(NOLOCK) ON L4.ID = ess.Level4Id AND L4.IsActive = 1 AND L4.IsDeleted = 0
            LEFT JOIN [dbo].[ManagementStructureLevel] L5 WITH(NOLOCK) ON L5.ID = ess.Level5Id AND L5.IsActive = 1 AND L5.IsDeleted = 0
            LEFT JOIN [dbo].[ManagementStructureLevel] L6 WITH(NOLOCK) ON L6.ID = ess.Level6Id AND L6.IsActive = 1 AND L6.IsDeleted = 0
            LEFT JOIN [dbo].[ManagementStructureLevel] L7 WITH(NOLOCK) ON L7.ID = ess.Level7Id AND L7.IsActive = 1 AND L7.IsDeleted = 0
            LEFT JOIN [dbo].[ManagementStructureLevel] L8 WITH(NOLOCK) ON L8.ID = ess.Level8Id AND L8.IsActive = 1 AND L8.IsDeleted = 0
            LEFT JOIN [dbo].[ManagementStructureLevel] L9 WITH(NOLOCK) ON L9.ID = ess.Level9Id AND L9.IsActive = 1 AND L9.IsDeleted = 0
            LEFT JOIN [dbo].[ManagementStructureLevel] L10 WITH(NOLOCK) ON L10.ID = ess.Level10Id AND L10.IsActive = 1 AND L10.IsDeleted = 0

      WHERE rtp.IsVoidedCheck = 0
            AND rtp.IsGenerated   = 1
            AND rtp.IsActive      = 1
            AND rtp.IsDeleted     = 0
            AND rtp.MasterCompanyId = @MasterCompanyId
            AND (@FromPaymentDate IS NULL OR CAST(rtp.CheckDate AS DATE) >= CAST(@FromPaymentDate AS DATE))
            AND (@ToPaymentDate IS NULL OR CAST(rtp.CheckDate AS DATE) <= CAST(@ToPaymentDate AS DATE))
            AND (@Payee       IS NULL OR rtp.VendorName LIKE '%' + @Payee + '%')
            AND (@InvoiceNum IS NULL  OR (
                        (ISNULL(VPD.ReceivingReconciliationId,0) > 0 AND RRC.InvoiceNum LIKE '%' + @InvoiceNum + '%')
                        OR (ISNULL(VPD.CreditMemoHeaderId,0) > 0 AND CM.InvoiceNumber LIKE '%' + @InvoiceNum + '%')
                        OR (ISNULL(VPD.NonPOInvoiceId,0) > 0 AND NPH.InvoiceNumber LIKE '%' + @InvoiceNum + '%')
                        OR (ISNULL(VPD.CustomerCreditPaymentDetailId,0) > 0 AND CCPD.ReferenceNumber LIKE '%' + @InvoiceNum + '%')
                        OR (ISNULL(VPD.VendorProformaInvoiceId,0) > 0 AND VNPH.InvoiceNumber LIKE '%' + @InvoiceNum + '%')
						OR (ISNULL(VPD.ManualJournalHeaderId,0) > 0 AND  VPD.[InvoiceNum] LIKE '%' + @InvoiceNum + '%')
            )
            )
            AND (@PaymentRef IS NULL OR rtp.CheckNumber LIKE '%' + @PaymentRef + '%')
            AND (@BankAccount IS NULL OR CONCAT(lebl.BankName,' - ',lebl.BankAccountNumber) LIKE '%' + @BankAccount + '%')
            AND (@BaseCurrency IS NULL OR rtp.CurrencyName LIKE '%' + @BaseCurrency + '%')
            AND (@GlAccountNum IS NULL OR CONCAT(g.AccountCode,' - ',g.AccountName) LIKE '%' + @GlAccountNum + '%')
            AND (@PaymentMethod IS NULL OR vpym.Description LIKE '%' + @PaymentMethod + '%')
            AND (@BaseCurrencyAmount IS NULL OR rtp.OriginalAmount = @BaseCurrencyAmount)
            -- Column date filters
            AND (@InvoiceDate IS NULL OR(
                     (ISNULL(VPD.ReceivingReconciliationId,0) > 0 AND CAST(RRC.InvoiceDate AS DATE) = CAST(@InvoiceDate AS DATE))
                    OR (ISNULL(VPD.CreditMemoHeaderId,0) > 0 AND CAST(CM.InvoiceDate AS DATE) = CAST(@InvoiceDate AS DATE))
                    OR (ISNULL(VPD.NonPOInvoiceId,0) > 0 AND CAST(NPH.InvoiceDate AS DATE) = CAST(@InvoiceDate AS DATE))
                    OR (ISNULL(VPD.CustomerCreditPaymentDetailId,0) > 0 AND CAST(CCPD.ProcessedDate AS DATE) = CAST(@InvoiceDate AS DATE))
                    OR (ISNULL(VPD.VendorProformaInvoiceId,0) > 0 AND CAST(VNPH.InvoiceDate AS DATE) = CAST(@InvoiceDate AS DATE))
					OR (ISNULL(VPD.ManualJournalHeaderId,0) > 0 AND CAST(MJH.PostedDate AS DATE) = CAST(@InvoiceDate AS DATE) )
                )
            )
            AND (@InvoiceDueDate IS NULL OR CAST(rtp.DueDate AS DATE) = CAST(@InvoiceDueDate AS DATE))
            AND (@PaymentDate IS NULL OR CAST(rtp.CheckDate AS DATE) = CAST(@PaymentDate AS DATE))
            AND (@CreditTermsName IS NULL OR CT.Name LIKE '%' + @CreditTermsName + '%')
            AND ( @Level1 IS NULL  OR ess.Level1Id IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@Level1, ',')))
            AND ( @Level2 IS NULL OR ess.Level2Id IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@Level2, ',')))
            AND ( @Level3 IS NULL  OR ess.Level3Id IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@Level3, ',')))
            AND ( @Level4 IS NULL OR ess.Level4Id IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@Level4, ',')))
            AND ( @Level5 IS NULL  OR ess.Level5Id IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@Level5, ',')))
            AND ( @Level6 IS NULL  OR ess.Level6Id IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@Level6, ',')))
            AND ( @Level7 IS NULL OR ess.Level7Id IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@Level7, ',')))
            AND ( @Level8 IS NULL OR ess.Level8Id IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@Level8, ',')))
            AND ( @Level9 IS NULL OR ess.Level9Id IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@Level9, ',')))
            AND ( @Level10 IS NULL OR ess.Level10Id IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@Level10, ',')))

            GROUP BY
            CASE
                WHEN ISNULL(VPD.ReceivingReconciliationId,0) > 0 THEN RRC.InvoiceNum
                WHEN ISNULL(VPD.CreditMemoHeaderId,0) > 0 THEN CM.InvoiceNumber
                WHEN ISNULL(VPD.NonPOInvoiceId,0) > 0 THEN NPH.InvoiceNumber
                WHEN ISNULL(VPD.CustomerCreditPaymentDetailId,0) > 0 THEN CCPD.ReferenceNumber
                WHEN ISNULL(VPD.VendorProformaInvoiceId,0) > 0 THEN VNPH.InvoiceNumber
				WHEN ISNULL(VPD.ManualJournalHeaderId,0) > 0 THEN VPD.[InvoiceNum]
            END,
            CASE
                WHEN ISNULL(VPD.ReceivingReconciliationId,0) > 0 THEN CAST(RRC.InvoiceDate AS DATE)
                WHEN ISNULL(VPD.CreditMemoHeaderId,0) > 0 THEN CAST(CM.InvoiceDate AS DATE)
                WHEN ISNULL(VPD.NonPOInvoiceId,0) > 0 THEN CAST(NPH.InvoiceDate AS DATE)
                WHEN ISNULL(VPD.CustomerCreditPaymentDetailId,0) > 0 THEN CAST(CCPD.ProcessedDate AS DATE)
                WHEN ISNULL(VPD.VendorProformaInvoiceId,0) > 0 THEN CAST(VNPH.InvoiceDate AS DATE)
				WHEN ISNULL(VPD.ManualJournalHeaderId,0) > 0 THEN CAST(MJH.PostedDate AS DATE)
            END
            ,rtp.CheckNumber

    -- Pagination 
    Print @SortColumn
     SELECT *
        FROM #tmprAPDisbursementReportInvoice
        WHERE InvoiceNum is not null
        --ORDER BY InvoiceNum
          ORDER BY
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'payee')              THEN Payee END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'payee')              THEN Payee END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'vendorCode')         THEN VendorCode END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'vendorCode')         THEN VendorCode END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'invoiceNum')         THEN InvoiceNum END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'invoiceNum')         THEN InvoiceNum END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'invoiceDate')        THEN InvoiceDate END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'invoiceDate')        THEN InvoiceDate END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'paymentMethod')      THEN PaymentMethod END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'paymentMethod')      THEN PaymentMethod END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'paymentReference')   THEN PaymentReference END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'paymentReference')   THEN PaymentReference END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'paymentDate')        THEN PaymentDate END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'paymentDate')        THEN PaymentDate END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'baseCurrencyAmount') THEN BaseCurrencyAmount END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'baseCurrencyAmount') THEN BaseCurrencyAmount END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'baseCurrency')       THEN BaseCurrency END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'baseCurrency')       THEN BaseCurrency END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'invoiceDueDate')     THEN InvoiceDueDate END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'invoiceDueDate')     THEN InvoiceDueDate END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'bankAccount')        THEN BankAccount END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'bankAccount')        THEN BankAccount END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'glAccountNum')       THEN GLAccountNum END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'glAccountNum')       THEN GLAccountNum END DESC,
            CASE WHEN (@SortOrder = 1  AND @SortColumn = 'creditTermsName')    THEN CreditTermsName END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'creditTermsName')    THEN CreditTermsName END DESC

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
        FROM #tmprAPDisbursementReportInvoice
        WHERE InvoiceNum is not null;

END TRY
BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------

                @AdhocComments VARCHAR(150) = '[usprpt_GetAPDisbursementReportByInvoice]',
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