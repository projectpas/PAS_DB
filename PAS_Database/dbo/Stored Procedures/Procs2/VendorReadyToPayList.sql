/*************************************************************           
 ** File:   [VendorReadyToPayList]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used VendorReadyToPayList 
 ** Purpose:         
 ** Date:   19/05/2023      
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    19/05/2023   Subhash Saliya	Created
	2    07/04/2023   Satish Gohil		Modify(Change Conditon)
	3    13/07/2023   Moin Bloch		Added All Vendor Payment Methods
	4    21/09/2023   AMIT GHEDIYA		Added for is vendorcreditmemo or not
	5    28/09/2023   AMIT GHEDIYA		Added new parm startdate & enddate filter.
	6    06/10/2023   AMIT GHEDIYA		Modify logic for AmountDue, due to discount amount time expired..
	7    19/10/2023   Devendra Shekh	added union all for credit memo
	8    26/10/2023   Moin Bloch	    added InvoiceOnHold flag.
	9    27/10/2023   Devendra Shekh	Changes for customer creditmemo details
	10   31/10/2023   Devendra Shekh	added union al for nonpo details
	11   02/11/2023   Devendra Shekh	changed union for nonpo details
	12   06/11/2023   AMIT GHEDIYA      Update Status Approved To Posted for VendorCreditMemo.
	13   05/01/2024   Moin Bloch        Replaced PercentId at CreditTermsId
	14   15/03/2023   AMIT GHEDIYA      Add LegalEntityId wise filter.
     
-- EXEC VendorReadyToPayList 1,NULL,NULL  
**************************************************************/
CREATE     PROCEDURE [dbo].[VendorReadyToPayList]  
@MasterCompanyId INT = NULL,  
@StartDate DATETIME = NULL,  
@EndDate DATETIME = NULL,
@LegalEntityId BIGINT = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  

	DECLARE @CreditCardPaymentMethodId INT,@CreditMemoLoopID AS INT,
			@VendorCreditMemoId BIGINT,@VendorPaymentDetailsId BIGINT,
			@IsVendorPayment BIT,
			@VendorCreditMemoStatusId INT;;

	SELECT @VendorCreditMemoStatusId = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';

	SELECT @CreditCardPaymentMethodId = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod] WITH(NOLOCK) WHERE [Description] ='Credit Card';

	--Added for checking is reserved or not then delete from list.
	IF OBJECT_ID(N'tempdb..#tmpVendorCreditMemoMapping') IS NOT NULL
	BEGIN
		DROP TABLE #tmpVendorCreditMemoMapping
	END
				
	CREATE TABLE #tmpVendorCreditMemoMapping
	(
		[ID] INT IDENTITY,
		[VendorCreditMemoMappingId] INT,
		[VendorCreditMemoId] BIGINT NULL,
		[VendorPaymentDetailsId] BIGINT NULL
	)

	INSERT #tmpVendorCreditMemoMapping ([VendorCreditMemoMappingId],[VendorCreditMemoId],[VendorPaymentDetailsId])
		SELECT [VendorCreditMemoMappingId],[VendorCreditMemoId],[VendorPaymentDetailsId]
	FROM [dbo].[VendorCreditMemoMapping] WITH (NOLOCK);

	SELECT  @CreditMemoLoopID = MAX(ID) FROM #tmpVendorCreditMemoMapping
	WHILE(@CreditMemoLoopID > 0)
	BEGIN
		SELECT @VendorCreditMemoId = [VendorCreditMemoId] , @VendorPaymentDetailsId = [VendorPaymentDetailsId]
		FROM #tmpVendorCreditMemoMapping WHERE ID  = @CreditMemoLoopID;

		SELECT @IsVendorPayment = ISNULL(IsVendorPayment,0) FROM [dbo].[VendorCreditMemo] WITH (NOLOCK) WHERE VendorCreditMemoId = @VendorCreditMemoId 

		IF(@IsVendorPayment = 0)
		BEGIN
			DELETE [dbo].[VendorCreditMemoMapping]  WHERE VendorPaymentDetailsId = @VendorPaymentDetailsId AND VendorCreditMemoId = @VendorCreditMemoId;
		END

		SET @VendorCreditMemoId = 0;
		SET @CreditMemoLoopID = @CreditMemoLoopID - 1;
	END
	  
	--Selecting
    SELECT DISTINCT VPD.VendorPaymentDetailsId,
			        VPD.ReadyToPayId,  
                    (VPD.DueDate + ISNULL(ctm.NetDays,0)) AS DueDate,  
					VPD.VendorId,
					VPD.VendorName,
					VPD.PaymentMethodId,
					VPD.PaymentMethodName,  
                    VPD.ReceivingReconciliationId,
					VPD.InvoiceNum,
					VPD.CurrencyId,
					VPD.CurrencyName,
					VPD.FXRate,  
					ISNULL(VPD.InvoiceTotal,0) AS OriginalAmount,
					0 AS PaymentMade,  
                    --ISNULL(VPD.RemainingAmount,0) AS AmountDue,  
					(ISNULL(VPD.RemainingAmount,0) + (ISNULL(VPD.InvoiceTotal,0) - ISNULL(Tab.DiscountToken,0) - ISNULL(VPD.PaymentMade,0) - ISNULL(VPD.RemainingAmount,0))) AS AmountDue,  
                    ISNULL(VPD.PaymentMade,0) AS PaidAmount,  
                    ISNULL(ctm.NetDays,0) AS NetDays,
					ISNULL(p.[PercentValue],0) AS [Percentage],   
                    CASE WHEN DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  
                   (VPD.DueDate + ISNULL(ctm.Days,0)) AS DiscountDate,  
				   (CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((VPD.InvoiceTotal * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END) -(ISNULL(Tab.DiscountToken,0)) AS DiscountAvailable,  
				 --VPD.DiscountToken,  
				   ISNULL(Tab.DiscountToken,0) 'DiscountToken',
				   VPD.StatusId,
				   VPD.[Status],
				   VPD.MasterCompanyId, --, VP.DefaultPaymentMethod
				   ISNULL(tab.ReadyToPaymentMade,0) 'ReadyToPaymentMade',
				 --DefaultPaymentMethod = (SELECT TOP 1 CASE WHEN VP.DefaultPaymentMethod = 3 THEN 2 ELSE VP.DefaultPaymentMethod END  FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted=0 ),
				   DefaultPaymentMethod = (SELECT TOP 1 VP.DefaultPaymentMethod FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsCheckPayment = (SELECT CASE WHEN COUNT(ch.CheckPaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorCheckPayment] VP WITH(NOLOCK) INNER JOIN CheckPayment ch WITH(NOLOCK) on ch.CheckPaymentId=vp.CheckPaymentId  WHERE VP.VendorId = V.VendorId AND ch.IsDeleted = 0),
				   IsDomesticWirePayment = (SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsInternationlWirePayment = (SELECT CASE WHEN COUNT(VP.VendorInternationalWirePaymentId) > 0 THEN 1 ELSE 0 END FROM [dbo].[VendorInternationlWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsACHTransferPayment = (SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
	               IsCreditCardPayment = (SELECT TOP 1 CASE WHEN VP.DefaultPaymentMethod = @CreditCardPaymentMethodId THEN 1 ELSE 0 END FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsCreditMemo = 0,
				   SelectedforPayment = 
				   (SELECT CASE WHEN COUNT(ISNULL(VCMD.VendorCreditMemoId,0)) > 0 THEN 1 ELSE 0 END
					FROM [dbo].[VendorCreditMemo] VCM 
						LEFT JOIN [dbo].[VendorCreditMemoDetail] VCMD WITH (NOLOCK) ON VCM.VendorCreditMemoId = VCMD.VendorCreditMemoId
						LEFT JOIN [dbo].[VendorRMA] VR WITH (NOLOCK) ON VR.VendorRMAId = VCM.VendorRMAId
						LEFT JOIN [dbo].[Vendor] VD WITH(NOLOCK) ON VCM.VendorId = VD.VendorId
						LEFT JOIN [dbo].[Vendor] VE WITH(NOLOCK) ON VR.VendorId = VE.VendorId
					WHERE VCM.VendorCreditMemoStatusId = @VendorCreditMemoStatusId AND VCM.IsVendorPayment IS NULL AND CASE WHEN VCM.VendorId IS NOT NULL THEN VCM.VendorId ELSE VE.VendorId END = V.VendorId),
					IsCustomerCreditMemo = 0,
					CreditMemoHeaderId = 0,
					VendorReadyToPayDetailsTypeId = 1,
					NonPOInvoiceId = 0
			FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK)  
			     INNER JOIN [dbo].[ReceivingReconciliationHeader] RRC WITH(NOLOCK) ON VPD.[ReceivingReconciliationId] = RRC.[ReceivingReconciliationId]	
				 INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON VPD.VendorId = V.VendorId  
				  LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId  
				  LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(ctm.PercentId AS INT) = p.PercentId  
				  OUTER APPLY (SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken
							   FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							   WHERE ISNULL(VD.VendorPaymentDetailsId,0) = VPD.VendorPaymentDetailsId
				                 AND IsVoidedCheck = 0 AND CheckNumber IS NULL GROUP BY VD.VendorPaymentDetailsId) AS Tab
		   WHERE [VPD].[MasterCompanyId] = @MasterCompanyId 
		        AND [VPD].[RemainingAmount] > 0
				AND ISNULL(RRC.[IsInvoiceOnHold],0) = 0
				AND ISNULL(VPD.NonPOInvoiceId,0) = 0
				AND ((@StartDate IS NULL AND @EndDate IS NULL) OR (VPD.DueDate + ISNULL(ctm.NetDays,0)) BETWEEN @StartDate AND @EndDate)
				AND RRC.LegalEntityId = @LegalEntityId
	
	UNION ALL

	    SELECT DISTINCT 0 AS VendorPaymentDetailsId,
					0 AS ReadyToPayId,  
					DATEADD(Day, ISNULL(ctm.NetDays,0), CMD.InvoiceDate) AS [DueDate],  
					CMD.CustomerId AS [VendorId],
					CMD.CustomerName AS [VendorName],
					0 AS PaymentMethodId,
					'' AS PaymentMethodName,  
                    0 AS ReceivingReconciliationId,
					CMD.CreditMemoNumber AS [InvoiceNum],
					CU.CurrencyId,
					CU.Code AS [CurrencyName],
					0 AS [FXRate],  
					ABS(ISNULL(CMD.Amount,0)) AS OriginalAmount,
					0 AS PaymentMade,  
					ABS(ISNULL(CMD.Amount,0)) AS AmountDue,  
                    0 AS PaidAmount,  
                    ISNULL(ctm.NetDays,0) AS NetDays,
					ISNULL(p.[PercentValue],0) AS [Percentage],   
					CASE WHEN DATEDIFF(DAY, DATEADD(Day, ISNULL(ctm.NetDays,0), CMD.InvoiceDate), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, DATEADD(Day, ISNULL(ctm.NetDays,0), CMD.InvoiceDate), GETUTCDATE()) END AS DaysPastDue,   
					0 AS DiscountDate,  
					0 AS DiscountAvailable,  
					0 AS 'DiscountToken',
					CMD.StatusId,
					CMD.[Status],
					CMD.MasterCompanyId,
					0 AS 'ReadyToPaymentMade',
					DefaultPaymentMethod = 1,
					IsCheckPayment = 1,
					IsDomesticWirePayment = 0,
					IsInternationlWirePayment = 0,
					IsACHTransferPayment = 0,
					IsCreditCardPayment = 0,
					IsCreditMemo = 1,
					SelectedforPayment = 1,
					IsCustomerCreditMemo = 1,
					CMD.CreditMemoHeaderId,
					VendorReadyToPayDetailsTypeId = 2,
					NonPOInvoiceId = 0
				FROM [dbo].[CreditMemo] CMD WITH(NOLOCK)  
				JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = CMD.ManagementStructureId
				JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
				JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
				INNER JOIN [dbo].[CustomerRefund] CRF WITH(NOLOCK) ON CMD.CustomerRefundId = CRF.CustomerRefundId  
				INNER JOIN [dbo].[RefundCreditMemoMapping] RFCM WITH(NOLOCK) ON CMD.CreditMemoHeaderId = RFCM.CreditMemoHeaderId  
				--INNER JOIN [dbo].[CreditMemoPaymentBatchDetails] CMBD WITH(NOLOCK) ON CMBD.ReferenceId = CRF.CustomerRefundId AND CMBD.ModuleId = (SELECT ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'CustomerRefund')
				--INNER JOIN [dbo].[CommonBatchDetails] CBD WITH(NOLOCK) ON CBD.CommonJournalBatchDetailId = CMBD.CommonJournalBatchDetailId  
				--INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON BD.JournalBatchDetailId = CBD.JournalBatchDetailId  
				--INNER JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BS.Id = BD.StatusId  
				INNER JOIN [dbo].[Customer] C WITH(NOLOCK) ON CMD.CustomerId = C.CustomerId  
				INNER JOIN [dbo].[CustomerFinancial] CF WITH(NOLOCK) ON CF.CustomerId = C.CustomerId  
				INNER JOIN [dbo].[Currency] CU WITH(NOLOCK) ON CF.CurrencyId = CU.CurrencyId  
				 LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = CF.CreditTermsId  
				 LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(ctm.PercentId AS INT) = p.PercentId  
				WHERE CMD.[MasterCompanyId] = @MasterCompanyId AND CMD.[CustomerRefundId] IS NOT NULL AND ISNULL(CMD.IsUsedInVendorPayment,0) <> 1
				AND ((@StartDate IS NULL AND @EndDate IS NULL) OR DATEADD(Day, ISNULL(ctm.NetDays,0), CMD.InvoiceDate) BETWEEN @StartDate AND @EndDate)
				AND LE.LegalEntityId = @LegalEntityId

		UNION ALL

		SELECT DISTINCT VPD.VendorPaymentDetailsId,
			        VPD.ReadyToPayId,  
                    (VPD.DueDate + ISNULL(ctm.NetDays,0)) AS DueDate,  
					VPD.VendorId,
					VPD.VendorName,
					VPD.PaymentMethodId,
					VPD.PaymentMethodName,  
                    VPD.ReceivingReconciliationId,
					VPD.InvoiceNum,
					VPD.CurrencyId,
					VPD.CurrencyName,
					VPD.FXRate,  
					ISNULL(VPD.InvoiceTotal,0) AS OriginalAmount,
					0 AS PaymentMade,  
					(ISNULL(VPD.RemainingAmount,0) + (ISNULL(VPD.InvoiceTotal,0) - ISNULL(Tab.DiscountToken,0) - ISNULL(VPD.PaymentMade,0) - ISNULL(VPD.RemainingAmount,0))) AS AmountDue,  
                    ISNULL(VPD.PaymentMade,0) AS PaidAmount,  
                    ISNULL(ctm.NetDays,0) AS NetDays,
					ISNULL(p.[PercentValue],0) AS [Percentage],   
                    CASE WHEN DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  
                   (VPD.DueDate + ISNULL(ctm.Days,0)) AS DiscountDate,  
				   (CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((VPD.InvoiceTotal * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END) -(ISNULL(Tab.DiscountToken,0)) AS DiscountAvailable,  
				   ISNULL(Tab.DiscountToken,0) 'DiscountToken',
				   VPD.StatusId,
				   VPD.[Status],
				   VPD.MasterCompanyId,
				   ISNULL(tab.ReadyToPaymentMade,0) 'ReadyToPaymentMade',
				   DefaultPaymentMethod = (SELECT TOP 1 VP.DefaultPaymentMethod FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsCheckPayment = (SELECT CASE WHEN COUNT(ch.CheckPaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorCheckPayment] VP WITH(NOLOCK) INNER JOIN CheckPayment ch WITH(NOLOCK) on ch.CheckPaymentId=vp.CheckPaymentId  WHERE VP.VendorId = V.VendorId AND ch.IsDeleted = 0),
				   IsDomesticWirePayment = (SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsInternationlWirePayment = (SELECT CASE WHEN COUNT(VP.VendorInternationalWirePaymentId) > 0 THEN 1 ELSE 0 END FROM [dbo].[VendorInternationlWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsACHTransferPayment = (SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
	               IsCreditCardPayment = (SELECT TOP 1 CASE WHEN VP.DefaultPaymentMethod = @CreditCardPaymentMethodId THEN 1 ELSE 0 END FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsCreditMemo = 0,
				   SelectedforPayment = 
				   (SELECT CASE WHEN COUNT(ISNULL(VCMD.VendorCreditMemoId,0)) > 0 THEN 1 ELSE 0 END
					FROM [dbo].[VendorCreditMemo] VCM 
						LEFT JOIN [dbo].[VendorCreditMemoDetail] VCMD WITH (NOLOCK) ON VCM.VendorCreditMemoId = VCMD.VendorCreditMemoId
						LEFT JOIN [dbo].[VendorRMA] VR WITH (NOLOCK) ON VR.VendorRMAId = VCM.VendorRMAId
						LEFT JOIN [dbo].[Vendor] VD WITH(NOLOCK) ON VCM.VendorId = VD.VendorId
						LEFT JOIN [dbo].[Vendor] VE WITH(NOLOCK) ON VR.VendorId = VE.VendorId
					WHERE VCM.VendorCreditMemoStatusId = @VendorCreditMemoStatusId AND VCM.IsVendorPayment IS NULL AND CASE WHEN VCM.VendorId IS NOT NULL THEN VCM.VendorId ELSE VE.VendorId END = V.VendorId),
					IsCustomerCreditMemo = 0,
					CreditMemoHeaderId = 0,
					VendorReadyToPayDetailsTypeId = 3,
					NPH.NonPOInvoiceId
			FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK)  
				 INNER JOIN [dbo].[NonPOInvoiceHeader] NPH WITH(NOLOCK) ON VPD.NonPOInvoiceId = NPH.NonPOInvoiceId	
				 JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = NPH.ManagementStructureId
				 JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
				 JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
				 INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON VPD.VendorId = V.VendorId  
				  LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId  
				  LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(ctm.PercentId AS INT) = p.PercentId  
				  OUTER APPLY (SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken
							   FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
							   WHERE ISNULL(VD.VendorPaymentDetailsId,0) = VPD.VendorPaymentDetailsId
				                 AND IsVoidedCheck = 0 AND CheckNumber IS NULL GROUP BY VD.VendorPaymentDetailsId) AS Tab
		   WHERE [VPD].[MasterCompanyId] = @MasterCompanyId 
		        AND [VPD].[RemainingAmount] > 0
				AND ISNULL(VPD.NonPOInvoiceId,0) <> 0
				AND ((@StartDate IS NULL AND @EndDate IS NULL) OR (VPD.DueDate + ISNULL(ctm.NetDays,0)) BETWEEN @StartDate AND @EndDate)
				AND LE.LegalEntityId = @LegalEntityId

  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'VendorReadyToPayList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''  
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