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
	15   26/03/2024   Devendra Shekh    added temp table and removed union
	16   27/03/2024   Devendra Shekh    changes for customer credit payment and added vendor for creditmemo
	17   28/03/2024   Devendra Shekh    table changes for creditMemo(changed to same as nonPO)
	18   04/04/2024   Devendra Shekh    discount removed from credit memo and suspense record
	19   08/04/2023   Devendra Shekh	added conditon for amount for SelectedforPayment
	20   08/07/2024   Abhishek Jirawla	Removed Miscellaneous flag from CustomerCreditPaymentDetails select
	21   23/12/2024   AMIT GHEDIYA      Update to get for IsEnable for next vendor payment.
	22   27/12/2024   RAJESH GAMI       Added Vendor Proforma Invoice
	23   31/12/2024   AMIT GHEDIYA      Update for  DiscountDate.
	24   01/JAN/2025  RAJESH GAMI       Remove Discount Percentage from the proforma invoice
	25   11-03-2025   ABHISHEK JIRAWLA  IsVendorOnHold check for payment hold
	26   11-03-2025   AMIT GHEDIYA      Update LegalEntityId condition to get from VendorPaymentDetailst table
	27   27-11-2025   Moin Bloch	    added Manual Journal
	28   03-12-2025   AMIT GHEDIYA	    update Manual Journal code type to (4 to 6)
	29   03-02-2026   AMIT GHEDIYA	    update to get vendor which is not Payment Hold (PN-15337)
	30   12-02-2026   AMIT GHEDIYA	    date filter issue (PN-15442)
	31   16/02/2026   Amit Ghediya		update to get due date from ReceivingReconciliation duedate (PN-15444)
	32   19/02/2026   Amit Ghediya		update for cm is full used or not (PN-15510)
     
-- EXEC VendorReadyToPayList 1,NULL,NULL,1  
--EXEC dbo.VendorReadyToPayList @MasterCompanyId=1,@StartDate=default,@EndDate=default,@LegalEntityId=1
**************************************************************/
CREATE   PROCEDURE [dbo].[VendorReadyToPayList]  
@MasterCompanyId INT = NULL,  
@EmployeeId BIGINT  = NULL ,
@StartDate DATETIME = NULL,  
@EndDate DATETIME = NULL,
@LegalEntityId BIGINT = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  

	DECLARE @CreditCardPaymentMethodId INT,@CreditMemoLoopID AS INT,
			@VendorCreditMemoId BIGINT,
			@VendorId BIGINT,
			@VendorPaymentDetailsId BIGINT,
			@IsVendorPayment BIT,
			@VendorCreditMemoStatusId INT,
			@ManualJRefrenceTypeId INT = 2,
			@ManualJStatusId INT,
			@IsVendorPaymentMJ BIT,
			@CurrntEmpTimeZoneDesc VARCHAR(100) = '';

			SELECT	@CurrntEmpTimeZoneDesc = COALESCE(
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

	SELECT @VendorCreditMemoStatusId = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';

	SELECT @ManualJStatusId = ManualJournalStatusId FROM [dbo].[ManualJournalStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';

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
		[VendorPaymentDetailsId] BIGINT NULL,
		[VendorId] BIGINT NULL,
	)

	IF OBJECT_ID(N'tempdb..#TempVendorReadyToPayList') IS NOT NULL    
	BEGIN    
		DROP TABLE #TempVendorReadyToPayList
	END

	CREATE TABLE #TempVendorReadyToPayList(        
		[ID] BIGINT IDENTITY(1,1),      
		[VendorPaymentDetailsId] BIGINT NOT NULL,
		[ReadyToPayId] BIGINT NOT NULL,
		[DueDate] DATETIME2 NULL,
		[VendorId] BIGINT NULL,
		[VendorName] VARCHAR(100) NULL,
		[PaymentMethodId] BIGINT NULL,
		[PaymentMethodName] VARCHAR(100) NULL,
		[ReceivingReconciliationId] BIGINT NOT NULL,
		[InvoiceNum] VARCHAR(100),
		[CurrencyId] INT NULL,
		[CurrencyName] VARCHAR(50) NULL,
		[FXRate] NUMERIC(9,4) NULL,
		[OriginalAmount] DECIMAL(18, 2) NULL,
		[PaymentMade] DECIMAL(18, 2) NULL,
		[AmountDue] DECIMAL(18, 2) NULL,
		[PaidAmount] DECIMAL(18, 2) NULL,
		[NetDays] INT NULL,
		[Percentage] DECIMAL(18, 2) NULL,
		[DaysPastDue] INT NULL,
		[DiscountDate] DATETIME2 NULL,
		[DiscountAvailable] DECIMAL(18, 2) NULL,
		[DiscountToken] DECIMAL(18, 2) NULL,
		[StatusId] INT NULL,
		[Status] VARCHAR(50),
		[MasterCompanyId] INT NULL,
		[ReadyToPaymentMade] VARCHAR(250) NULL,
		[DefaultPaymentMethod] INT NULL,
		[IsCheckPayment] BIT NULL,
		[IsDomesticWirePayment] BIT NULL,
		[IsInternationlWirePayment] BIT NULL,
		[IsACHTransferPayment] BIT NULL,
		[IsCreditCardPayment] BIT NULL,
		[IsCreditMemo] BIT NULL,
		[SelectedforPayment] INT NULL,
		[IsEnable] BIT NULL,
		[IsCustomerCreditMemo] BIT NULL,
		[CreditMemoHeaderId] BIGINT NOT NULL,
		[VendorReadyToPayDetailsTypeId] INT NULL,
		[NonPOInvoiceId] BIGINT NULL,
		[CustomerCreditPaymentDetailId] BIGINT NULL,
		[CreatedDate] DATETIME2 NULL,
		[VendorProformaInvoiceId] BIGINT NULL,
		[IsVendorOnHold] BIT NULL,
		[ManualJournalHeaderId] BIGINT NULL,
		) 

	INSERT #tmpVendorCreditMemoMapping ([VendorCreditMemoMappingId],[VendorCreditMemoId],[VendorPaymentDetailsId],[VendorId])
		SELECT [VendorCreditMemoMappingId],[VendorCreditMemoId],[VendorPaymentDetailsId],[VendorId]
	FROM [dbo].[VendorCreditMemoMapping] WITH (NOLOCK) WHERE ISNULL(IsPosted,0) = 0;

	SELECT  @CreditMemoLoopID = MAX(ID) FROM #tmpVendorCreditMemoMapping
	WHILE(@CreditMemoLoopID > 0)
	BEGIN
		SELECT @VendorCreditMemoId = [VendorCreditMemoId] , 
			   @VendorPaymentDetailsId = [VendorPaymentDetailsId],
			   @VendorId = [VendorId]
		FROM #tmpVendorCreditMemoMapping WHERE ID  = @CreditMemoLoopID;

		DECLARE @ID BIGINT;
		SELECT @ID = ReadyToPayDetailsId FROM [dbo].[VendorReadyToPayDetails] WITH(NOLOCK) WHERE VendorPaymentDetailsId = @VendorPaymentDetailsId AND CheckNumber IS NULL;
		IF(@ID IS NULL)
		BEGIN
			UPDATE [dbo].[VendorCreditMemo] SET IsVendorPayment = NULL
			WHERE VendorCreditMemoId = @VendorCreditMemoId;

			----Reserve ManualJournalDetails for Used
			UPDATE [dbo].[ManualJournalDetails] SET IsVendorPayment = NULL
			WHERE ManualJournalHeaderId = @VendorCreditMemoId AND ReferenceId = @VendorId;

			DELETE [dbo].[VendorCreditMemoMapping]  WHERE VendorCreditMemoId = @VendorCreditMemoId;
		END

		--SELECT @IsVendorPayment = ISNULL(IsVendorPayment,0) FROM [dbo].[VendorCreditMemo] WITH (NOLOCK) WHERE VendorCreditMemoId = @VendorCreditMemoId;
		
		--SELECT @IsVendorPaymentMJ = ISNULL(IsVendorPayment,0) FROM [dbo].[ManualJournalDetails] WITH (NOLOCK) WHERE ManualJournalHeaderId = @VendorCreditMemoId AND ReferenceId =  @VendorId;

		--IF(@IsVendorPayment = 0)
		--BEGIN
		--	DELETE [dbo].[VendorCreditMemoMapping]  WHERE VendorPaymentDetailsId = @VendorPaymentDetailsId AND VendorCreditMemoId = @VendorCreditMemoId AND ISNULL(IsPosted,0) = 0;
		--END

		--IF(@IsVendorPaymentMJ = 0)
		--BEGIN
		--	DELETE [dbo].[VendorCreditMemoMapping]  WHERE VendorPaymentDetailsId = @VendorPaymentDetailsId AND VendorCreditMemoId = @VendorCreditMemoId AND ISNULL(IsPosted,0) = 0;
		--END

		SET @VendorCreditMemoId = 0;
		SET @VendorPaymentDetailsId = 0;
		SET @VendorId = 0;
		SET @CreditMemoLoopID = @CreditMemoLoopID - 1;
	END
	  
	--Selecting
	--;With CTEData 
	--VendorPayment -ReceivingReconciliation DETAILS
	INSERT INTO #TempVendorReadyToPayList(VendorPaymentDetailsId, ReadyToPayId, DueDate, VendorId, VendorName, PaymentMethodId, PaymentMethodName, ReceivingReconciliationId
					,InvoiceNum, CurrencyId, CurrencyName, FXRate, OriginalAmount, PaymentMade, AmountDue, PaidAmount, NetDays, [Percentage]
					,DaysPastDue, DiscountDate, DiscountAvailable, DiscountToken, StatusId, [Status], MasterCompanyId, ReadyToPaymentMade
					,DefaultPaymentMethod, IsCheckPayment, IsDomesticWirePayment, IsInternationlWirePayment, IsACHTransferPayment, IsCreditCardPayment, IsCreditMemo
					,SelectedforPayment, IsEnable, IsCustomerCreditMemo, CreditMemoHeaderId, VendorReadyToPayDetailsTypeId, NonPOInvoiceId, [CustomerCreditPaymentDetailId], [CreatedDate], [IsVendorOnHold]) --as (

    SELECT DISTINCT VPD.VendorPaymentDetailsId,
			        VPD.ReadyToPayId,  
					--DATEADD(RRC.InvoiceDate, ISNULL(ctm.NetDays,0), VPD.DueDate) AS [DueDate],  
					 --CASE WHEN IIF(TRY_CAST(RRC.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
						--THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(RRC.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
					 --ELSE NULL END	AS 'DueDate',
					 RRC.DueDate AS 'DueDate',
                    --(VPD.DueDate + ISNULL(ctm.NetDays,0)) AS DueDate,  
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
					(ISNULL(VPD.RemainingAmount,0) + (ISNULL(VPD.InvoiceTotal,0) - 0 - ISNULL(VPD.PaymentMade,0) - ISNULL(VPD.RemainingAmount,0))) AS AmountDue,  
                    ISNULL(VPD.PaymentMade,0) AS PaidAmount,  
                    ISNULL(ctm.NetDays,0) AS NetDays,
					ISNULL(p.[PercentValue],0) AS [Percentage],   
                    CASE WHEN DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  
                   
				   CASE WHEN ISNULL(ctm.[Days],0) > 0 THEN
					DATEADD(Day, ISNULL(ctm.[Days],0), RRC.InvoiceDate) 
				   ELSE '' END AS DiscountDate,  

				   (CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((VPD.InvoiceTotal * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END) - 0 AS DiscountAvailable,  
				 --VPD.DiscountToken,  
				   0 'DiscountToken',
				   VPD.StatusId,
				   VPD.[Status],
				   VPD.MasterCompanyId, --, VP.DefaultPaymentMethod
				   0 'ReadyToPaymentMade',
				 --DefaultPaymentMethod = (SELECT TOP 1 CASE WHEN VP.DefaultPaymentMethod = 3 THEN 2 ELSE VP.DefaultPaymentMethod END  FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted=0 ),
				   DefaultPaymentMethod = (SELECT TOP 1 VP.DefaultPaymentMethod FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsCheckPayment = 1,--(SELECT CASE WHEN COUNT(ch.CheckPaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorCheckPayment] VP WITH(NOLOCK) INNER JOIN CheckPayment ch WITH(NOLOCK) on ch.CheckPaymentId=vp.CheckPaymentId  WHERE VP.VendorId = V.VendorId AND ch.IsDeleted = 0),
				   IsDomesticWirePayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsInternationlWirePayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorInternationalWirePaymentId) > 0 THEN 1 ELSE 0 END FROM [dbo].[VendorInternationlWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsACHTransferPayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
	               IsCreditCardPayment = 1,--(SELECT TOP 1 CASE WHEN VP.DefaultPaymentMethod = @CreditCardPaymentMethodId THEN 1 ELSE 0 END FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsCreditMemo = 0,
					SelectedforPayment = 
				   (SELECT 
				   CASE WHEN COUNT(ISNULL(VCM.VendorCreditMemoId,0)) > COUNT(VCMM.VendorCreditMemoId) THEN 1 ELSE 0 END
					FROM 
					[dbo].[VendorCreditMemo] VCM WITH (NOLOCK)
						LEFT JOIN [dbo].[VendorCreditMemoDetail] VCMD WITH (NOLOCK) ON VCM.VendorCreditMemoId = VCMD.VendorCreditMemoId
						LEFT JOIN [dbo].[VendorCreditMemoMapping] VCMM WITH (NOLOCK) ON  VCMD.VendorCreditMemoId = VCMM.VendorCreditMemoId
						LEFT JOIN [dbo].[Vendor] VE WITH(NOLOCK) ON VCM.VendorId = VE.VendorId
					WHERE VCM.VendorCreditMemoStatusId = @VendorCreditMemoStatusId AND VCM.IsVendorPayment IS NULL AND CASE WHEN VCM.VendorId IS NOT NULL THEN VCM.VendorId ELSE VE.VendorId END = V.VendorId
					HAVING SUM(ISNULL(VCMD.ApplierdAmt,0)) > 0),
					IsEnable = (SELECT CASE WHEN COUNT(VRTPD.[ReadyToPayDetailsId]) > 0 THEN 0 ELSE 1 END  FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK)
						WHERE VRTPD.VendorPaymentDetailsId = VPD.VendorPaymentDetailsId AND ISNULL(VRTPD.IsGenerated,0) = 0),
					IsCustomerCreditMemo = 0,
					ISNULL(VPD.CreditMemoHeaderId,0) AS CreditMemoHeaderId,
					VendorReadyToPayDetailsTypeId = 1,
					NonPOInvoiceId = 0,
					[CustomerCreditPaymentDetailId] = 0,
					VPD.CreatedDate,
					V.IsVendorOnHold
			FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK)  
			     INNER JOIN [dbo].[ReceivingReconciliationHeader] RRC WITH(NOLOCK) ON VPD.[ReceivingReconciliationId] = RRC.[ReceivingReconciliationId]	
				 INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON VPD.VendorId = V.VendorId  
				  LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId  
				  LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(ctm.PercentId AS INT) = p.PercentId  
				  --OUTER APPLY (SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken
						--	   FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 
						--	   WHERE ISNULL(VD.VendorPaymentDetailsId,0) = VPD.VendorPaymentDetailsId
				  --               AND IsVoidedCheck = 0 AND CheckNumber IS NULL GROUP BY VD.VendorPaymentDetailsId) AS Tab
		   WHERE [VPD].[MasterCompanyId] = @MasterCompanyId 
		        AND [VPD].[RemainingAmount] > 0
				AND ISNULL(RRC.[IsInvoiceOnHold],0) = 0
				AND ISNULL(VPD.NonPOInvoiceId,0) = 0
				AND ((@StartDate IS NULL AND @EndDate IS NULL) OR (DATEADD(Day, ISNULL(ctm.NetDays,0), VPD.DueDate)) BETWEEN @StartDate AND @EndDate)
				AND VPD.LegalEntityId = @LegalEntityId

				UPDATE  #TempVendorReadyToPayList 
				SET AmountDue = ISNULL(AmountDue,0) - ISNULL(discNewData.DiscountToken,0), DiscountAvailable = ISNULL(DiscountAvailable,0) - ISNULL(discNewData.DiscountToken,0),
					DiscountToken = ISNULL(discNewData.DiscountToken,0), ReadyToPaymentMade = ISNULL(discNewData.ReadyToPaymentMade,0)
				FROM(SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken, VD.InvoiceNum
							   FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK) 
							   LEFT JOIN [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) ON VPD.[ReceivingReconciliationId] = VD.[ReceivingReconciliationId]	
							   WHERE ISNULL(VD.VendorPaymentDetailsId,0) = VPD.VendorPaymentDetailsId
							   AND IsVoidedCheck = 0 AND CheckNumber IS NULL GROUP BY VD.VendorPaymentDetailsId,VD.InvoiceNum
				) discNewData WHERE #TempVendorReadyToPayList.VendorReadyToPayDetailsTypeId = 1 AND #TempVendorReadyToPayList.InvoiceNum = discNewData.InvoiceNum
	
	--UNION ALL
		--CreditMemo DETAILS
		INSERT INTO #TempVendorReadyToPayList(VendorPaymentDetailsId, ReadyToPayId, DueDate, VendorId, VendorName, PaymentMethodId, PaymentMethodName, ReceivingReconciliationId
					,InvoiceNum, CurrencyId, CurrencyName, FXRate, OriginalAmount, PaymentMade, AmountDue, PaidAmount, NetDays, [Percentage]
					,DaysPastDue, DiscountDate, DiscountAvailable, DiscountToken, StatusId, [Status], MasterCompanyId, ReadyToPaymentMade
					,DefaultPaymentMethod, IsCheckPayment, IsDomesticWirePayment, IsInternationlWirePayment, IsACHTransferPayment, IsCreditCardPayment, IsCreditMemo
					,SelectedforPayment, IsEnable, IsCustomerCreditMemo, CreditMemoHeaderId, VendorReadyToPayDetailsTypeId, NonPOInvoiceId, [CustomerCreditPaymentDetailId], [CreatedDate], [IsVendorOnHold])
	    SELECT DISTINCT VPD.VendorPaymentDetailsId,
			        VPD.ReadyToPayId,  
					
					CASE WHEN IIF(TRY_CAST(VPD.DueDate AS DATETIME) IS NULL, 0, 1 ) = 1 
						THEN VPD.DueDate 
					ELSE
						CASE WHEN IIF(TRY_CAST(CM.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
							THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(CM.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
						ELSE NULL END
					END AS 'DueDate',
					--DATEADD(Day, ISNULL(ctm.NetDays,0), VPD.DueDate) AS DueDate,
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
					(ISNULL(VPD.RemainingAmount,0) + (ISNULL(VPD.InvoiceTotal,0) - 0 - ISNULL(VPD.PaymentMade,0) - ISNULL(VPD.RemainingAmount,0))) AS AmountDue,  
                    ISNULL(VPD.PaymentMade,0) AS PaidAmount,  
                    ISNULL(ctm.NetDays,0) AS NetDays,
					ISNULL(p.[PercentValue],0) AS [Percentage],   
                    CASE WHEN DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  
				   
				   CASE WHEN ISNULL(ctm.[Days],0) > 0 THEN
					DATEADD(Day, ISNULL(ctm.[Days],0), CM.InvoiceDate) 
				   ELSE '' END AS DiscountDate,

				   --(CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((VPD.InvoiceTotal * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END) - 0 AS DiscountAvailable,  
				   0 AS DiscountAvailable,
				   0 'DiscountToken',
				   VPD.StatusId,
				   VPD.[Status],
				   VPD.MasterCompanyId,
				   0 'ReadyToPaymentMade',
				   DefaultPaymentMethod = (SELECT TOP 1 VP.DefaultPaymentMethod FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsCheckPayment = 1,--(SELECT CASE WHEN COUNT(ch.CheckPaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorCheckPayment] VP WITH(NOLOCK) INNER JOIN CheckPayment ch WITH(NOLOCK) on ch.CheckPaymentId=vp.CheckPaymentId  WHERE VP.VendorId = V.VendorId AND ch.IsDeleted = 0),
				   IsDomesticWirePayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsInternationlWirePayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorInternationalWirePaymentId) > 0 THEN 1 ELSE 0 END FROM [dbo].[VendorInternationlWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsACHTransferPayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
	               IsCreditCardPayment = 1,--(SELECT TOP 1 CASE WHEN VP.DefaultPaymentMethod = @CreditCardPaymentMethodId THEN 1 ELSE 0 END FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsCreditMemo = 0,
					SelectedforPayment = 
				   (SELECT 
				   CASE WHEN COUNT(ISNULL(VCM.VendorCreditMemoId,0)) > COUNT(VCMM.VendorCreditMemoId) THEN 1 ELSE 0 END
					FROM 
					[dbo].[VendorCreditMemo] VCM WITH (NOLOCK)
						LEFT JOIN [dbo].[VendorCreditMemoDetail] VCMD WITH (NOLOCK) ON VCM.VendorCreditMemoId = VCMD.VendorCreditMemoId
						LEFT JOIN [dbo].[VendorCreditMemoMapping] VCMM WITH (NOLOCK) ON  VCMD.VendorCreditMemoId = VCMM.VendorCreditMemoId
						LEFT JOIN [dbo].[Vendor] VE WITH(NOLOCK) ON VCM.VendorId = VE.VendorId
					WHERE VCM.VendorCreditMemoStatusId = @VendorCreditMemoStatusId AND VCM.IsVendorPayment IS NULL AND CASE WHEN VCM.VendorId IS NOT NULL THEN VCM.VendorId ELSE VE.VendorId END = V.VendorId
					HAVING SUM(ISNULL(VCMD.ApplierdAmt,0)) > 0),
					IsEnable = (SELECT CASE WHEN COUNT(VRTPD.[ReadyToPayDetailsId]) > 0 THEN 0 ELSE 1 END  FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK)
						WHERE VRTPD.VendorPaymentDetailsId = VPD.VendorPaymentDetailsId AND ISNULL(VRTPD.IsGenerated,0) = 0),
					IsCustomerCreditMemo = 1,
					ISNULL(VPD.CreditMemoHeaderId,0) AS CreditMemoHeaderId,
					VendorReadyToPayDetailsTypeId = 2,
					ISNULL(VPD.NonPOInvoiceId,0) AS NonPOInvoiceId,
					[CustomerCreditPaymentDetailId] = 0,
					VPD.CreatedDate,
					V.IsVendorOnHold
			FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK)  
				 INNER JOIN [dbo].[CreditMemo] CM WITH(NOLOCK) ON VPD.CreditMemoHeaderId = CM.CreditMemoHeaderId	
				 JOIN [dbo].[EntityStructureSetup] ES WITH(NOLOCK) ON ES.EntityStructureId = CM.ManagementStructureId
				 JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
				 JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON MSL.LegalEntityId = LE.LegalEntityId  
				 INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON VPD.VendorId = V.VendorId  
				  LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId  
				  LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(ctm.PercentId AS INT) = p.PercentId  
		   WHERE [VPD].[MasterCompanyId] = @MasterCompanyId 
		        AND [VPD].[RemainingAmount] > 0
				AND ISNULL(VPD.NonPOInvoiceId,0) = 0
				AND ISNULL(VPD.CreditMemoHeaderId,0) <> 0
				AND ((@StartDate IS NULL AND @EndDate IS NULL) OR (DATEADD(Day, ISNULL(ctm.NetDays,0), VPD.DueDate)) BETWEEN @StartDate AND @EndDate)
				AND VPD.LegalEntityId = @LegalEntityId

				UPDATE  #TempVendorReadyToPayList 
				SET AmountDue = ISNULL(AmountDue,0) - ISNULL(discNewData.DiscountToken,0), DiscountAvailable = ISNULL(DiscountAvailable,0) - ISNULL(discNewData.DiscountToken,0),
					DiscountToken = ISNULL(discNewData.DiscountToken,0), ReadyToPaymentMade = ISNULL(discNewData.ReadyToPaymentMade,0)
				FROM(SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,0 as DiscountToken, VD.InvoiceNum
							   FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK) 
							    LEFT JOIN [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) ON VPD.CreditMemoHeaderId = VD.CreditMemoHeaderId	
							   WHERE ISNULL(VD.VendorPaymentDetailsId,0) = VPD.VendorPaymentDetailsId
				                 AND IsVoidedCheck = 0 AND CheckNumber IS NULL GROUP BY VD.VendorPaymentDetailsId,VD.InvoiceNum
				) discNewData WHERE #TempVendorReadyToPayList.VendorReadyToPayDetailsTypeId = 2 AND #TempVendorReadyToPayList.InvoiceNum = discNewData.InvoiceNum

		--UNION ALL
		--VendorPayment -NonPOInvoice DETAILS
		INSERT INTO #TempVendorReadyToPayList(VendorPaymentDetailsId, ReadyToPayId, DueDate, VendorId, VendorName, PaymentMethodId, PaymentMethodName, ReceivingReconciliationId
					,InvoiceNum, CurrencyId, CurrencyName, FXRate, OriginalAmount, PaymentMade, AmountDue, PaidAmount, NetDays, [Percentage]
					,DaysPastDue, DiscountDate, DiscountAvailable, DiscountToken, StatusId, [Status], MasterCompanyId, ReadyToPaymentMade
					,DefaultPaymentMethod, IsCheckPayment, IsDomesticWirePayment, IsInternationlWirePayment, IsACHTransferPayment, IsCreditCardPayment, IsCreditMemo
					,SelectedforPayment, IsEnable, IsCustomerCreditMemo, CreditMemoHeaderId, VendorReadyToPayDetailsTypeId, NonPOInvoiceId, [CustomerCreditPaymentDetailId], [CreatedDate], [IsVendorOnHold])
		SELECT DISTINCT VPD.VendorPaymentDetailsId,
			        VPD.ReadyToPayId,  
					--DATEADD(Day, ISNULL(ctm.NetDays,0), VPD.DueDate) AS DueDate,
					--CASE WHEN IIF(TRY_CAST(VPD.DueDate AS DATETIME) IS NULL, 0, 1 ) = 1 
					--	THEN VPD.DueDate 
					-- ELSE
					--	CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
					--		THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
					--	ELSE NULL END
					--END AS 'DueDate',
					NPH.DueDate AS 'DueDate',
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
					(ISNULL(VPD.RemainingAmount,0) + (ISNULL(VPD.InvoiceTotal,0) - 0 - ISNULL(VPD.PaymentMade,0) - ISNULL(VPD.RemainingAmount,0))) AS AmountDue,  
                    ISNULL(VPD.PaymentMade,0) AS PaidAmount,  
                    ISNULL(ctm.NetDays,0) AS NetDays,
					ISNULL(p.[PercentValue],0) AS [Percentage],   
                    CASE WHEN DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  
				   CASE WHEN ISNULL(ctm.[Days],0) > 0 THEN
					DATEADD(Day, ISNULL(ctm.[Days],0), NPH.InvoiceDate) 
				   ELSE '' END AS DiscountDate,
				   (CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((VPD.InvoiceTotal * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END) - 0 AS DiscountAvailable,  
				   0 'DiscountToken',
				   VPD.StatusId,
				   VPD.[Status],
				   VPD.MasterCompanyId,
				   0 'ReadyToPaymentMade',
				   DefaultPaymentMethod = (SELECT TOP 1 VP.DefaultPaymentMethod FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsCheckPayment = 1,--(SELECT CASE WHEN COUNT(ch.CheckPaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorCheckPayment] VP WITH(NOLOCK) INNER JOIN CheckPayment ch WITH(NOLOCK) on ch.CheckPaymentId=vp.CheckPaymentId  WHERE VP.VendorId = V.VendorId AND ch.IsDeleted = 0),
				   IsDomesticWirePayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsInternationlWirePayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorInternationalWirePaymentId) > 0 THEN 1 ELSE 0 END FROM [dbo].[VendorInternationlWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsACHTransferPayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
	               IsCreditCardPayment = 1,--(SELECT TOP 1 CASE WHEN VP.DefaultPaymentMethod = @CreditCardPaymentMethodId THEN 1 ELSE 0 END FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsCreditMemo = 0,
					SelectedforPayment = 
				   (SELECT 
				   CASE WHEN COUNT(ISNULL(VCM.VendorCreditMemoId,0)) > COUNT(VCMM.VendorCreditMemoId) THEN 1 ELSE 0 END
					FROM 
					[dbo].[VendorCreditMemo] VCM WITH (NOLOCK)
						LEFT JOIN [dbo].[VendorCreditMemoDetail] VCMD WITH (NOLOCK) ON VCM.VendorCreditMemoId = VCMD.VendorCreditMemoId
						LEFT JOIN [dbo].[VendorCreditMemoMapping] VCMM WITH (NOLOCK) ON  VCMD.VendorCreditMemoId = VCMM.VendorCreditMemoId
						LEFT JOIN [dbo].[Vendor] VE WITH(NOLOCK) ON VCM.VendorId = VE.VendorId
					WHERE VCM.VendorCreditMemoStatusId = @VendorCreditMemoStatusId AND VCM.IsVendorPayment IS NULL AND CASE WHEN VCM.VendorId IS NOT NULL THEN VCM.VendorId ELSE VE.VendorId END = V.VendorId
					HAVING SUM(ISNULL(VCMD.ApplierdAmt,0)) > 0),
					IsEnable = (SELECT CASE WHEN COUNT(VRTPD.[ReadyToPayDetailsId]) > 0 THEN 0 ELSE 1 END  FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK)
						WHERE VRTPD.VendorPaymentDetailsId = VPD.VendorPaymentDetailsId AND ISNULL(VRTPD.IsGenerated,0) = 0),
					IsCustomerCreditMemo = 0,
					ISNULL(VPD.CreditMemoHeaderId,0) AS CreditMemoHeaderId,
					VendorReadyToPayDetailsTypeId = 3,
					NPH.NonPOInvoiceId,
					[CustomerCreditPaymentDetailId] = 0,
					VPD.CreatedDate,
					V.IsVendorOnHold
			FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK)  
				 INNER JOIN [dbo].[NonPOInvoiceHeader] NPH WITH(NOLOCK) ON VPD.NonPOInvoiceId = NPH.NonPOInvoiceId	
				 JOIN [dbo].[EntityStructureSetup] ES WITH(NOLOCK) ON ES.EntityStructureId = NPH.ManagementStructureId
				 JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
				 JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON MSL.LegalEntityId = LE.LegalEntityId  
				 INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON VPD.VendorId = V.VendorId  
				  LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId  
				  LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(ctm.PercentId AS INT) = p.PercentId  
				  --OUTER APPLY (SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken
				  --	   FROM [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) 							  
			      --	   WHERE ISNULL(VD.VendorPaymentDetailsId,0) = VPD.VendorPaymentDetailsId
				  --	AND IsVoidedCheck = 0 AND CheckNumber IS NULL GROUP BY VD.VendorPaymentDetailsId) AS Tab
		   WHERE [VPD].[MasterCompanyId] = @MasterCompanyId 
		        AND [VPD].[RemainingAmount] > 0
				AND ISNULL(VPD.NonPOInvoiceId,0) <> 0
				AND ((@StartDate IS NULL AND @EndDate IS NULL) OR (DATEADD(Day, ISNULL(ctm.NetDays,0), VPD.DueDate)) BETWEEN @StartDate AND @EndDate)
				AND VPD.LegalEntityId = @LegalEntityId

				UPDATE  #TempVendorReadyToPayList 
				SET AmountDue = ISNULL(AmountDue,0) - ISNULL(discNewData.DiscountToken,0), DiscountAvailable = ISNULL(DiscountAvailable,0) - ISNULL(discNewData.DiscountToken,0),
					DiscountToken = ISNULL(discNewData.DiscountToken,0), ReadyToPaymentMade = ISNULL(discNewData.ReadyToPaymentMade,0)
				FROM(SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken, VD.InvoiceNum
							   FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK) 
							    LEFT JOIN [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) ON VPD.NonPOInvoiceId = VD.NonPOInvoiceId	
							   WHERE ISNULL(VD.VendorPaymentDetailsId,0) = VPD.VendorPaymentDetailsId
				                 AND IsVoidedCheck = 0 AND CheckNumber IS NULL GROUP BY VD.VendorPaymentDetailsId,VD.InvoiceNum
				) discNewData WHERE #TempVendorReadyToPayList.VendorReadyToPayDetailsTypeId = 3 AND #TempVendorReadyToPayList.InvoiceNum = discNewData.InvoiceNum

				
       -- Manual Journal

	   INSERT INTO #TempVendorReadyToPayList([VendorPaymentDetailsId],[ReadyToPayId],[DueDate],[VendorId],[VendorName],[PaymentMethodId],[PaymentMethodName],[ReceivingReconciliationId]
					,[InvoiceNum],[CurrencyId],[CurrencyName],[FXRate],[OriginalAmount],[PaymentMade],[AmountDue],[PaidAmount],[NetDays],[Percentage]
					,[DaysPastDue],[DiscountDate],[DiscountAvailable],[DiscountToken],[StatusId],[Status],[MasterCompanyId],[ReadyToPaymentMade]
					,[DefaultPaymentMethod],[IsCheckPayment],[IsDomesticWirePayment],[IsInternationlWirePayment],[IsACHTransferPayment],[IsCreditCardPayment],[IsCreditMemo]
					,[SelectedforPayment],[IsEnable],[IsCustomerCreditMemo],[CreditMemoHeaderId],[VendorReadyToPayDetailsTypeId],[NonPOInvoiceId], 
					 [CustomerCreditPaymentDetailId],[CreatedDate],[IsVendorOnHold],[ManualJournalHeaderId])
		SELECT DISTINCT VPD.VendorPaymentDetailsId,
		                VPD.ReadyToPayId,
						CASE WHEN IIF(TRY_CAST(VPD.DueDate AS DATETIME) IS NULL, 0, 1 ) = 1 
							THEN VPD.DueDate 
						ELSE
							CASE WHEN IIF(TRY_CAST(MJH.[EntryDate] AS DATETIME) IS NULL, 0, 1 ) = 1
								THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(MJH.[EntryDate],@CurrntEmpTimeZoneDesc)AS DATETIME)))
							ELSE NULL END
						END,  
					    VPD.[VendorId],
					    VPD.[VendorName],
					    VPD.[PaymentMethodId],
					    VPD.[PaymentMethodName],  
                        VPD.[ReceivingReconciliationId],
					    VPD.[InvoiceNum],
					    VPD.[CurrencyId],
					    VPD.[CurrencyName],
					    VPD.[FXRate],  
					    ISNULL(VPD.[InvoiceTotal],0) AS OriginalAmount,
					    0 AS [PaymentMade],  
					    (ISNULL(VPD.[RemainingAmount],0) + (ISNULL(VPD.[InvoiceTotal],0) - 0 - ISNULL(VPD.[PaymentMade],0) - ISNULL(VPD.[RemainingAmount],0))) AS AmountDue,  
                        ISNULL(VPD.[PaymentMade],0),  
                        ISNULL(CTM.[NetDays],0),
					    ISNULL(p.[PercentValue],0) AS [Percentage], 						
						CASE WHEN DATEDIFF(DAY, (CAST(VPD.[DueDate] AS DATETIME) + ISNULL(CTM.[NetDays],0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(VPD.[DueDate] AS DATETIME) + ISNULL(CTM.[NetDays],0)), GETUTCDATE()) END AS [DaysPastDue],  
					    CASE WHEN ISNULL(CTM.[Days],0) > 0 THEN DATEADD(DAY, ISNULL(CTM.[Days],0), MJH.[EntryDate]) ELSE '' END AS DiscountDate,
					    (CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(VPD.[DueDate] AS DATETIME) + ISNULL(CTM.[Days],0)), GETUTCDATE()), 0) <= 0 THEN CAST((VPD.[InvoiceTotal] * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END) - 0 AS [DiscountAvailable],  
					    0 'DiscountToken',
					    VPD.[StatusId],
					    VPD.[Status],
					    VPD.[MasterCompanyId],
					    0 'ReadyToPaymentMade',
						[DefaultPaymentMethod] = (SELECT TOP 1 VP.[DefaultPaymentMethod] FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.[VendorId] = V.[VendorId] AND vp.[IsDeleted] = 0),
				        [IsCheckPayment] = 1,--(SELECT CASE WHEN COUNT(ch.[CheckPaymentId]) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorCheckPayment] VP WITH(NOLOCK) INNER JOIN [dbo].[CheckPayment] ch WITH(NOLOCK) on ch.CheckPaymentId=vp.CheckPaymentId  WHERE VP.VendorId = V.VendorId AND ch.IsDeleted = 0),
				        [IsDomesticWirePayment] = 1,--(SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				        [IsInternationlWirePayment] = 1,--(SELECT CASE WHEN COUNT(VP.VendorInternationalWirePaymentId) > 0 THEN 1 ELSE 0 END FROM [dbo].[VendorInternationlWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				        [IsACHTransferPayment] = 1,--(SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
	                    [IsCreditCardPayment] = 1,--(SELECT TOP 1 CASE WHEN VP.DefaultPaymentMethod = @CreditCardPaymentMethodId THEN 1 ELSE 0 END FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				        [IsCreditMemo] = 0,
						[SelectedforPayment] = 0,
						--[SelectedforPayment] = (SELECT CASE WHEN COUNT(ISNULL(VCMD.VendorCreditMemoId,0)) > 0 THEN 1 ELSE 0 END
						--FROM [dbo].[VendorCreditMemo] VCM 
						--	LEFT JOIN [dbo].[VendorCreditMemoDetail] VCMD WITH (NOLOCK) ON VCM.VendorCreditMemoId = VCMD.VendorCreditMemoId
						--	LEFT JOIN [dbo].[VendorRMA] VR WITH (NOLOCK) ON VR.VendorRMAId = VCM.VendorRMAId
						--	LEFT JOIN [dbo].[Vendor] VD WITH(NOLOCK) ON VCM.VendorId = VD.VendorId
						--	LEFT JOIN [dbo].[Vendor] VE WITH(NOLOCK) ON VR.VendorId = VE.VendorId
						--WHERE VCM.VendorCreditMemoStatusId = @VendorCreditMemoStatusId 
						--AND VCM.IsVendorPayment IS NULL 
						--AND CASE WHEN VCM.VendorId IS NOT NULL THEN VCM.VendorId ELSE VE.VendorId END = V.VendorId
						--HAVING SUM(ISNULL(VCMD.ApplierdAmt,0)) > 0),
						IsEnable = (SELECT CASE WHEN COUNT(VRTPD.[ReadyToPayDetailsId]) > 0 THEN 0 ELSE 1 END  FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK)
									WHERE VRTPD.VendorPaymentDetailsId = VPD.VendorPaymentDetailsId AND ISNULL(VRTPD.IsGenerated,0) = 0),
						IsCustomerCreditMemo = 0,
						ISNULL(VPD.[CreditMemoHeaderId],0),
						[VendorReadyToPayDetailsTypeId] = 6,
						0,
						[CustomerCreditPaymentDetailId] = 0,
						VPD.[CreatedDate],
						V.[IsVendorOnHold],
						VPD.[ManualJournalHeaderId]
			      FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK)  
			INNER JOIN [dbo].[ManualJournalHeader] MJH WITH(NOLOCK) ON VPD.[ManualJournalHeaderId] = MJH.[ManualJournalHeaderId]	
			INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON VPD.[VendorId] = V.[VendorId]  
			 LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.[CreditTermsId] = V.[CreditTermsId]
		     LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(ctm.[PercentId] AS INT) = p.[PercentId]
			     WHERE [VPD].[MasterCompanyId] = @MasterCompanyId 
		           AND [VPD].[RemainingAmount] > 0
				   AND ISNULL(VPD.[ManualJournalHeaderId],0) <> 0
				   AND ((@StartDate IS NULL AND @EndDate IS NULL) OR (DATEADD(Day, ISNULL(ctm.[NetDays],0), VPD.[DueDate])) BETWEEN @StartDate AND @EndDate)
				   AND VPD.[LegalEntityId] = @LegalEntityId

				--UPDATE  #TempVendorReadyToPayList 
				--SET AmountDue = ISNULL(AmountDue,0) - ISNULL(discNewData.DiscountToken,0), DiscountAvailable = ISNULL(DiscountAvailable,0) - ISNULL(discNewData.DiscountToken,0),
				--	DiscountToken = ISNULL(discNewData.DiscountToken,0), ReadyToPaymentMade = ISNULL(discNewData.ReadyToPaymentMade,0)
				--FROM(SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken, VD.InvoiceNum
				--			   FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK) 
				--			    LEFT JOIN [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) ON VPD.ManualJournalHeaderId = VD.ManualJournalHeaderId	
				--			   WHERE ISNULL(VD.VendorPaymentDetailsId,0) = VPD.VendorPaymentDetailsId
				--                 AND IsVoidedCheck = 0 AND CheckNumber IS NULL GROUP BY VD.VendorPaymentDetailsId,VD.InvoiceNum
				--) discNewData WHERE #TempVendorReadyToPayList.VendorReadyToPayDetailsTypeId = 3 AND #TempVendorReadyToPayList.InvoiceNum = discNewData.InvoiceNum
							   
							   
				--CustomerCreditPayment DETAILS
		INSERT INTO #TempVendorReadyToPayList(VendorPaymentDetailsId, ReadyToPayId, DueDate, VendorId, VendorName, PaymentMethodId, PaymentMethodName, ReceivingReconciliationId
					,InvoiceNum, CurrencyId, CurrencyName, FXRate, OriginalAmount, PaymentMade, AmountDue, PaidAmount, NetDays, [Percentage]
					,DaysPastDue, DiscountDate, DiscountAvailable, DiscountToken, StatusId, [Status], MasterCompanyId, ReadyToPaymentMade
					,DefaultPaymentMethod, IsCheckPayment, IsDomesticWirePayment, IsInternationlWirePayment, IsACHTransferPayment, IsCreditCardPayment, IsCreditMemo
					,SelectedforPayment, IsEnable, IsCustomerCreditMemo, CreditMemoHeaderId, VendorReadyToPayDetailsTypeId, NonPOInvoiceId, [CustomerCreditPaymentDetailId], [CreatedDate], [IsVendorOnHold])
		SELECT	DISTINCT CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN 0 ELSE VPD.VendorPaymentDetailsId END AS VendorPaymentDetailsId,
				CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN 0 ELSE VPD.ReadyToPayId END AS ReadyToPayId,  
				DATEADD(Day, ISNULL(ctm.NetDays,0), CCPD.ProcessedDate) AS [DueDate],  
				CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN CCPD.VendorId ELSE VPD.VendorId END AS VendorId,  
				CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN V.VendorName ELSE VPD.VendorName END AS VendorName,  
				CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN 0 ELSE VPD.PaymentMethodId END AS PaymentMethodId,  
				CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN '' ELSE VPD.PaymentMethodName END AS PaymentMethodName,  
				CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN 0 ELSE VPD.ReceivingReconciliationId END AS ReceivingReconciliationId,  
				CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN CCPD.SuspenseUnappliedNumber ELSE VPD.InvoiceNum END AS InvoiceNum,  
				CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN V.CurrencyId ELSE VPD.CurrencyId END AS CurrencyId,  
				CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN CU.Code ELSE VPD.CurrencyName END AS CurrencyName,  
				CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN 0 ELSE VPD.FXRate END AS FXRate,  
				CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN CCPD.RemainingAmount ELSE ISNULL(VPD.InvoiceTotal,0) END AS OriginalAmount,  
				0 AS PaymentMade, 
				(ISNULL(VPD.RemainingAmount,0) + (CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN CCPD.RemainingAmount ELSE ISNULL(VPD.InvoiceTotal,0) END - 0 - ISNULL(VPD.PaymentMade,0) - ISNULL(VPD.RemainingAmount,0))) AS AmountDue,  
				CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN 0 ELSE ISNULL(VPD.PaymentMade,0) END AS PaidAmount,  
				ISNULL(ctm.NetDays,0) AS NetDays,
				ISNULL(p.[PercentValue],0) AS [Percentage],   
				CASE WHEN DATEDIFF(DAY, (CAST(CCPD.ProcessedDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(CCPD.ProcessedDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  
				 CASE WHEN ISNULL(ctm.[Days],0) > 0 THEN
					DATEADD(Day, ISNULL(ctm.[Days],0), CCPD.ProcessedDate) 
				   ELSE '' END AS DiscountDate,
				--(CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(CCPD.ProcessedDate AS DATETIME) + ISNULL(ctm.Days,0)), GETUTCDATE()), 0) <= 0 
					 --THEN CAST((CASE WHEN ISNULL(VPD.VendorPaymentDetailsId, 0) = 0 THEN CCPD.RemainingAmount ELSE ISNULL(VPD.InvoiceTotal,0) END * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END) - 0 AS DiscountAvailable,  
				0 AS DiscountAvailable,  
				0 'DiscountToken',
				CCPD.StatusId,
				'Processed' as [Status],
				CCPD.MasterCompanyId,
				0 'ReadyToPaymentMade',
				DefaultPaymentMethod = (SELECT TOP 1 VP.DefaultPaymentMethod FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				IsCheckPayment = 1,--(SELECT CASE WHEN COUNT(ch.CheckPaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorCheckPayment] VP WITH(NOLOCK) INNER JOIN CheckPayment ch WITH(NOLOCK) on ch.CheckPaymentId=vp.CheckPaymentId  WHERE VP.VendorId = V.VendorId AND ch.IsDeleted = 0),
				IsDomesticWirePayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				IsInternationlWirePayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorInternationalWirePaymentId) > 0 THEN 1 ELSE 0 END FROM [dbo].[VendorInternationlWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				IsACHTransferPayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
	            IsCreditCardPayment = 1,--(SELECT TOP 1 CASE WHEN VP.DefaultPaymentMethod = @CreditCardPaymentMethodId THEN 1 ELSE 0 END FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				IsCreditMemo = 0,
				SelectedforPayment = 
				   (SELECT 
				  CASE WHEN COUNT(ISNULL(VCM.VendorCreditMemoId,0)) > COUNT(VCMM.VendorCreditMemoId) THEN 1 ELSE 0 END
					FROM 
					[dbo].[VendorCreditMemo] VCM WITH (NOLOCK)
						LEFT JOIN [dbo].[VendorCreditMemoDetail] VCMD WITH (NOLOCK) ON VCM.VendorCreditMemoId = VCMD.VendorCreditMemoId
						LEFT JOIN [dbo].[VendorCreditMemoMapping] VCMM WITH (NOLOCK) ON  VCMD.VendorCreditMemoId = VCMM.VendorCreditMemoId
						LEFT JOIN [dbo].[Vendor] VE WITH(NOLOCK) ON VCM.VendorId = VE.VendorId
					WHERE VCM.VendorCreditMemoStatusId = @VendorCreditMemoStatusId AND VCM.IsVendorPayment IS NULL AND CASE WHEN VCM.VendorId IS NOT NULL THEN VCM.VendorId ELSE VE.VendorId END = V.VendorId
					HAVING SUM(ISNULL(VCMD.ApplierdAmt,0)) > 0),
				IsEnable = (SELECT CASE WHEN COUNT(VRTPD.[ReadyToPayDetailsId]) > 0 THEN 0 ELSE 1 END  FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK)
						WHERE VRTPD.VendorPaymentDetailsId = VPD.VendorPaymentDetailsId AND ISNULL(VRTPD.IsGenerated,0) = 0),
				IsCustomerCreditMemo = 0,
				ISNULL(VPD.CreditMemoHeaderId,0) AS CreditMemoHeaderId,
				VendorReadyToPayDetailsTypeId = 4,
				NonPOInvoiceId = 0,
				CCPD.[CustomerCreditPaymentDetailId],
				VPD.CreatedDate,
				V.IsVendorOnHold
			FROM [dbo].[CustomerCreditPaymentDetail] CCPD WITH(NOLOCK)  
					LEFT JOIN [dbo].[VendorReadyToPayDetails] VRPD WITH(NOLOCK) ON CCPD.[CustomerCreditPaymentDetailId] = VRPD.[CustomerCreditPaymentDetailId]  
					INNER JOIN [dbo].[CustomerPayments] CP WITH(NOLOCK) ON CP.ReceiptId = CCPD.ReceiptId	
					INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON CCPD.VendorId = V.VendorId  
					LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId  
					LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(ctm.PercentId AS INT) = p.PercentId  
					LEFT JOIN [dbo].[Currency] CU WITH(NOLOCK) ON V.CurrencyId = CU.CurrencyId  
					LEFT JOIN [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK) ON VPD.[CustomerCreditPaymentDetailId] = CCPD.[CustomerCreditPaymentDetailId]	
		   WHERE CCPD.[MasterCompanyId] = @MasterCompanyId 
		        AND [VPD].[RemainingAmount] > 0
				AND ISNULL(VPD.NonPOInvoiceId,0) = 0
				AND ISNULL(CCPD.IsProcessed,0) = 1
				--AND  CCPD.IsMiscellaneous = 1
				AND ((@StartDate IS NULL AND @EndDate IS NULL) OR (DATEADD(Day, ISNULL(ctm.NetDays,0), VPD.DueDate)) BETWEEN @StartDate AND @EndDate)
				AND VPD.LegalEntityId = @LegalEntityId

/****************************START  Vendor Proforma Invoice*********************************/
			INSERT INTO #TempVendorReadyToPayList(VendorPaymentDetailsId, ReadyToPayId, DueDate, VendorId, VendorName, PaymentMethodId, PaymentMethodName, ReceivingReconciliationId
					,InvoiceNum, CurrencyId, CurrencyName, FXRate, OriginalAmount, PaymentMade, AmountDue, PaidAmount, NetDays, [Percentage]
					,DaysPastDue, DiscountDate, DiscountAvailable, DiscountToken, StatusId, [Status], MasterCompanyId, ReadyToPaymentMade
					,DefaultPaymentMethod, IsCheckPayment, IsDomesticWirePayment, IsInternationlWirePayment, IsACHTransferPayment, IsCreditCardPayment, IsCreditMemo
					,SelectedforPayment, IsEnable, IsCustomerCreditMemo, CreditMemoHeaderId, VendorReadyToPayDetailsTypeId, VendorProformaInvoiceId, [CustomerCreditPaymentDetailId], [CreatedDate], [IsVendorOnHold])
			SELECT DISTINCT VPD.VendorPaymentDetailsId,
			        VPD.ReadyToPayId,  
					--DATEADD(Day, ISNULL(ctm.NetDays,0), VPD.DueDate) AS DueDate,
					CASE WHEN IIF(TRY_CAST(VPD.DueDate AS DATETIME) IS NULL, 0, 1 ) = 1 
							THEN VPD.DueDate 
					ELSE
						CASE WHEN IIF(TRY_CAST(NPH.InvoiceDate AS DATETIME) IS NULL, 0, 1 ) = 1
							THEN DATEADD(DAY,ISNULL(CTM.NetDays,0),(Cast(DBO.ConvertUTCtoLocal(NPH.InvoiceDate,@CurrntEmpTimeZoneDesc)AS DATETIME)))
						ELSE NULL END
					END AS 'DueDate',
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
					(ISNULL(VPD.RemainingAmount,0) + (ISNULL(VPD.InvoiceTotal,0) - 0 - ISNULL(VPD.PaymentMade,0) - ISNULL(VPD.RemainingAmount,0))) AS AmountDue,  
                    ISNULL(VPD.PaymentMade,0) AS PaidAmount,  
                    ISNULL(ctm.NetDays,0) AS NetDays,
					0 AS [Percentage],   
                    CASE WHEN DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) <= 0 THEN 0 ELSE DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.NetDays,0)), GETUTCDATE()) END AS DaysPastDue,  
				 --  CASE WHEN ISNULL(ctm.[Days],0) > 0 THEN
					--DATEADD(Day, ISNULL(ctm.[Days],0), NPH.InvoiceDate) 
				 --  ELSE '' END AS DiscountDate,
					'' DiscountDate,
				   --(CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(VPD.DueDate AS DATETIME) + ISNULL(ctm.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((VPD.InvoiceTotal * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END) - 0 AS DiscountAvailable,  
				   0 AS DiscountAvailable, 
				   0 'DiscountToken',
				   VPD.StatusId,
				   VPD.[Status],
				   VPD.MasterCompanyId,
				   0 'ReadyToPaymentMade',
				   DefaultPaymentMethod = (SELECT TOP 1 VP.DefaultPaymentMethod FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsCheckPayment = 1,--(SELECT CASE WHEN COUNT(ch.CheckPaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorCheckPayment] VP WITH(NOLOCK) INNER JOIN CheckPayment ch WITH(NOLOCK) on ch.CheckPaymentId=vp.CheckPaymentId  WHERE VP.VendorId = V.VendorId AND ch.IsDeleted = 0),
				   IsDomesticWirePayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsInternationlWirePayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorInternationalWirePaymentId) > 0 THEN 1 ELSE 0 END FROM [dbo].[VendorInternationlWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsACHTransferPayment = 1,--(SELECT CASE WHEN COUNT(VP.VendorDomesticWirePaymentId) > 0 THEN 1 ELSE 0 END  FROM [dbo].[VendorDomesticWirePayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
	               IsCreditCardPayment = 1,--(SELECT TOP 1 CASE WHEN VP.DefaultPaymentMethod = @CreditCardPaymentMethodId THEN 1 ELSE 0 END FROM [dbo].[VendorPayment] VP WITH(NOLOCK) WHERE VP.VendorId = V.VendorId AND vp.IsDeleted = 0),
				   IsCreditMemo = 0,
					SelectedforPayment = 
				   (SELECT 
				   CASE WHEN COUNT(ISNULL(VCM.VendorCreditMemoId,0)) > COUNT(VCMM.VendorCreditMemoId) THEN 1 ELSE 0 END
					FROM 
					[dbo].[VendorCreditMemo] VCM WITH (NOLOCK)
						LEFT JOIN [dbo].[VendorCreditMemoDetail] VCMD WITH (NOLOCK) ON VCM.VendorCreditMemoId = VCMD.VendorCreditMemoId
						LEFT JOIN [dbo].[VendorCreditMemoMapping] VCMM WITH (NOLOCK) ON  VCMD.VendorCreditMemoId = VCMM.VendorCreditMemoId
						LEFT JOIN [dbo].[Vendor] VE WITH(NOLOCK) ON VCM.VendorId = VE.VendorId
					WHERE VCM.VendorCreditMemoStatusId = @VendorCreditMemoStatusId AND VCM.IsVendorPayment IS NULL AND CASE WHEN VCM.VendorId IS NOT NULL THEN VCM.VendorId ELSE VE.VendorId END = V.VendorId
					HAVING SUM(ISNULL(VCMD.ApplierdAmt,0)) > 0),
					IsEnable = (SELECT CASE WHEN COUNT(VRTPD.[ReadyToPayDetailsId]) > 0 THEN 0 ELSE 1 END  FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK)
						WHERE VRTPD.VendorPaymentDetailsId = VPD.VendorPaymentDetailsId AND ISNULL(VRTPD.IsGenerated,0) = 0),
					IsCustomerCreditMemo = 0,
					ISNULL(VPD.CreditMemoHeaderId,0) AS CreditMemoHeaderId,
					VendorReadyToPayDetailsTypeId = 5,
					NPH.VendorProformaInvoiceId,
					[CustomerCreditPaymentDetailId] = 0,
					VPD.CreatedDate,
					V.IsVendorOnHold
			FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK)  
				 INNER JOIN [dbo].VendorProformaInvoiceHeader NPH WITH(NOLOCK) ON VPD.VendorProformaInvoiceId = NPH.VendorProformaInvoiceId	
				 JOIN [dbo].[EntityStructureSetup] ES WITH(NOLOCK) ON ES.EntityStructureId = NPH.ManagementStructureId
				 JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
				 JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON MSL.LegalEntityId = LE.LegalEntityId  
				 INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON VPD.VendorId = V.VendorId  
				  LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = V.CreditTermsId  
				  LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(ctm.PercentId AS INT) = p.PercentId  				 
		   WHERE [VPD].[MasterCompanyId] = @MasterCompanyId 
		        AND [VPD].[RemainingAmount] > 0
				AND ISNULL(VPD.VendorProformaInvoiceId,0) <> 0
				AND ((@StartDate IS NULL AND @EndDate IS NULL) OR (DATEADD(Day, ISNULL(ctm.NetDays,0), VPD.DueDate)) BETWEEN @StartDate AND @EndDate)
				AND VPD.LegalEntityId = @LegalEntityId

				UPDATE  #TempVendorReadyToPayList 
				SET AmountDue = ISNULL(AmountDue,0) - ISNULL(discNewData.DiscountToken,0), DiscountAvailable = ISNULL(DiscountAvailable,0) - ISNULL(discNewData.DiscountToken,0),
					DiscountToken = ISNULL(discNewData.DiscountToken,0), ReadyToPaymentMade = ISNULL(discNewData.ReadyToPaymentMade,0)
				FROM(SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,SUM(ISNULL(VD.DiscountToken,0)) DiscountToken, VD.InvoiceNum
							   FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK) 
							    LEFT JOIN [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) ON VPD.VendorProformaInvoiceId = VD.VendorProformaInvoiceId	
							   WHERE ISNULL(VD.VendorPaymentDetailsId,0) = VPD.VendorPaymentDetailsId
				                 AND IsVoidedCheck = 0 AND CheckNumber IS NULL GROUP BY VD.VendorPaymentDetailsId,VD.InvoiceNum
				) discNewData WHERE #TempVendorReadyToPayList.VendorReadyToPayDetailsTypeId = 3 AND #TempVendorReadyToPayList.InvoiceNum = discNewData.InvoiceNum


		/****************************END  Vendor Proforma Invoice*********************************/


				UPDATE  #TempVendorReadyToPayList 
				SET AmountDue = ISNULL(AmountDue,0) - ISNULL(discNewData.DiscountToken,0), DiscountAvailable = ISNULL(DiscountAvailable,0) - ISNULL(discNewData.DiscountToken,0),
					DiscountToken = ISNULL(discNewData.DiscountToken,0), ReadyToPaymentMade = ISNULL(discNewData.ReadyToPaymentMade,0)
				FROM(SELECT VD.VendorPaymentDetailsId,SUM(ISNULL(VD.PaymentMade,0) + ISNULL(VD.CreditMemoAmount,0)) ReadyToPaymentMade,0 AS DiscountToken, VD.InvoiceNum
							   FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK) 
							   LEFT JOIN [dbo].[VendorReadyToPayDetails] VD WITH(NOLOCK) ON VPD.[ReceivingReconciliationId] = VD.[ReceivingReconciliationId]	
							   WHERE ISNULL(VD.VendorPaymentDetailsId,0) = VPD.VendorPaymentDetailsId
							   AND IsVoidedCheck = 0 AND CheckNumber IS NULL GROUP BY VD.VendorPaymentDetailsId,VD.InvoiceNum
				) discNewData WHERE #TempVendorReadyToPayList.VendorReadyToPayDetailsTypeId = 4 AND #TempVendorReadyToPayList.InvoiceNum = discNewData.InvoiceNum

				--Update for MJ is addd for Vendor
				--UPDATE  #TempVendorReadyToPayList 
				--SET SelectedforPayment = mjNewData.SelectedforPayment
				--FROM(SELECT CASE WHEN ReferenceId > 0 THEN 1 ELSE 0 END As SelectedforPayment, ReferenceId AS VendorId
				--			   FROM [dbo].[ManualJournalDetails] MJD WITH(NOLOCK)
				--			JOIN [dbo].[ManualJournalHeader] MJH WITH(NOLOCK) ON MJD.ManualJournalHeaderId = MJH.ManualJournalHeaderId
				--			LEFT JOIN [dbo].[VendorCreditMemoMapping] VCMM WITH(NOLOCK) ON VCMM.VendorCreditMemoId = MJD.ManualJournalHeaderId AND VCMM.VendorId = MJD.ReferenceId --AND ISNULL(VCMM.IsPosted,0) = 0 
				--	 WHERE ReferenceTypeId = @ManualJRefrenceTypeId AND MJH.ManualJournalStatusId = @ManualJStatusId AND VCMM.IsPosted IS NULL AND ISNULL(MJD.IsVendorPayment,0) = 0
				--) mjNewData WHERE #TempVendorReadyToPayList.VendorId = mjNewData.VendorId AND ISNULL(#TempVendorReadyToPayList.SelectedforPayment, 0) = 0 AND #TempVendorReadyToPayList.[ManualJournalHeaderId] IS NULL


		SELECT [ID] ,      
			[VendorPaymentDetailsId] ,
			[ReadyToPayId] ,
			CASE WHEN ISNULL(DueDate, '') = '' THEN GETUTCDATE() ELSE DueDate END AS [DueDate] ,
			[VendorId] ,
			[VendorName] ,
			[PaymentMethodId] ,
			[PaymentMethodName] ,
			[ReceivingReconciliationId] ,
			[InvoiceNum] ,
			[CurrencyId] ,
			[CurrencyName] ,
			[FXRate] ,
			[OriginalAmount] ,
			[PaymentMade] ,
			[AmountDue] ,
			[PaidAmount] ,
			[NetDays] ,
			[Percentage] ,
			[DaysPastDue] ,
			[DiscountDate] ,
			[DiscountAvailable] ,
			[DiscountToken] ,
			[StatusId] ,
			[Status] ,
			[MasterCompanyId] ,
			[ReadyToPaymentMade] ,
			[DefaultPaymentMethod] ,
			[IsCheckPayment] ,
			[IsDomesticWirePayment] ,
			[IsInternationlWirePayment] ,
			[IsACHTransferPayment] ,
			[IsCreditCardPayment] ,
			[IsCreditMemo] ,
			[SelectedforPayment] ,
			[IsEnable] ,
			[IsCustomerCreditMemo] ,
			[CreditMemoHeaderId] ,
			[VendorReadyToPayDetailsTypeId] ,
			[NonPOInvoiceId] ,
			[CustomerCreditPaymentDetailId] ,
			[CreatedDate] ,
			[VendorProformaInvoiceId], 
			[IsVendorOnHold] 
		FROM #TempVendorReadyToPayList 
		WHERE ISNULL(IsVendorOnHold,0) = 0
		ORDER BY CreatedDate DESC;

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