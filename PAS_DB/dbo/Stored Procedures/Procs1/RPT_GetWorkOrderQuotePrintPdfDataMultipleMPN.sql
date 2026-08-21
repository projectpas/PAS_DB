/*************************************************************             
 ** File:   [RPT_GetWorkOrderQuotePrintPdfDataMultipleMPN]             
 ** Author:   RAJESH GAMI  
 ** Description: This stored procedure is used to get work order quote pdf details for multiple MPN 
 ** Purpose:           
 ** Date:   12-FEB-2025          
            
 ** PARAMETERS:   
 ** RETURN VALUE:             
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date			 Author			   Change Description              
 ** --   --------		 -------			--------------------------------            
    1    12-FEB-2025	 RAJESH GAMI		Created  
    2    24-FEB-2025	 RAJESH GAMI		Fixed the Total Amount Issue
	3    06-APR-2025	 HEMANT SALIYA		Updated for Get correct PN and Serial Number
	4    09-APR-2025	 Devendra Shekh		Comparing @CorrectiveActionCode instead of @corrective
    5    15-APR-2025	 RAJESH GAMI 	    Added Order By (WO Part Id Ascending)
	6    01-MAY-2025	 HEMANT SALIYA		Updated Hangle Error on Corrective Action
	7    09-MAY-2025	 Devendra Shekh		Added IsPrintCorrectiveAction to select
    8    10-JUL-2025     Moin Bloch         Updated MEMO To PublicationNotes
	9	 23-JUL-2025     Devendra Shekh		Added Case for Memo
	10	 14-OCT-2025     RAJESH GAMI		Return Estimated Ship Date
	11	 02-March-2026   Ayushi Patel		PN-15745 Retuen ItemNo  , Added OrderBY ID
	12   17-March-2026	 Ayushi Patel		PN-15746 Return CustomerReference Partwise
	13   23-March-2026	 BHARGAV SALIYA		PN-15822 Added CustomerReference field in Group By clause
	14    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	15    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	16    21/July/2026			 Bhargav Saliya						[PN-17747] - Added In [Fleet] in temp table
--EXEC [RPT_GetWorkOrderQuotePrintPdfDataMultipleMPN] 2304,'3823,3824,3825',0  
exec RPT_GetWorkOrderQuotePrintPdfDataMultipleMPN @WorkOrderQuoteId=2303,@workOrderPartNoIds=N'3820,3821,3822',@isByPartIds=1
**************************************************************/  
CREATE   PROCEDURE [dbo].[RPT_GetWorkOrderQuotePrintPdfDataMultipleMPN]  
 @WorkOrderQuoteId bigint,  
 @workOrderPartNoIds varchar(max),
 @isByPartIds INT = 0
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
   			IF OBJECT_ID(N'tempdb..#tmpQuoteIds') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpQuoteIds
			END

			IF OBJECT_ID(N'tempdb..#tmpQuotetblMulti') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpQuotetblMulti
			END
			IF OBJECT_ID(N'tempdb..#tblTempQuoteMain') IS NOT NULL    
			BEGIN    
				DROP TABLE #tblTempQuoteMain
			END
			DECLARE @totalCount INT =0,@currentRow INT = 1,@sql NVARCHAR(MAX), @PartId BIGINT = 0;
			DECLARE @TotalFreight DECIMAL(18,2)=0 ,@TotalCharges  DECIMAL(18,2)=0,@SubTotal  DECIMAL(18,2)=0,@WOQGrandTotal  DECIMAL(18,2)=0,@FinalSalesTaxes  DECIMAL(18,2)=0,@FinalOtherTaxes  DECIMAL(18,2) =0
			DECLARE @WOId BIGINT = (SELECT WorkorderId FROM DBO.WorkOrderQuote WITH(NOLOCK) Where WorkOrderQuoteId = @WorkOrderQuoteId);
			DECLARE @corrective VARCHAR(20) = 'corrective action'
			DECLARE @CorrectiveActionCode VARCHAR(100) = 'CRA';

			DECLARE @VendorModuleId INT, @ManufacturerModuleId INT, @OtherModuleId INT;
			SELECT @VendorModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Vendor';
			SELECT @ManufacturerModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Manufacturer';
			SELECT @OtherModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Others';

			DECLARE @TotalQuoteRow INT = 0, @CurrentQuoteRow INT = 0;
			DECLARE @WorkOrderId BIGINT, @workOrderPartNoId BIGINT;
			DECLARE @EmailContent NVARCHAR(MAX);
			DECLARE @ConditionName NVARCHAR(MAX),
					@PublicationId VARCHAR(100),
					@RevisionNum VARCHAR(100),
					@RevisionDate VARCHAR(100),
					@SecondPublicationId VARCHAR(100),
					@SecondRevisionNum VARCHAR(100),
					@SecondRevisionDate VARCHAR(100),
					@WorkOrderNum VARCHAR(50),
					@IsEasaUKLicenseType VARCHAR(50),
					@PublishedById INT,
					@VendorName VARCHAR(100),
					@ManufacturerName VARCHAR(100),
					@PublishedByOthers VARCHAR(100),
					@IsMultiple BIT,
					@EmailBody NVARCHAR(MAX);

			IF OBJECT_ID(N'tempdb..#tmpWorkOrderQuote') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpWorkOrderQuote
			END

			IF OBJECT_ID(N'tempdb..#tmpPartResult') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpPartResult
			END 

			IF OBJECT_ID(N'tempdb..#tmpResult') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpResult
			END

			CREATE TABLE #tmpWorkOrderQuote (      
				[RowId] INT IDENTITY (1, 1) NOT NULL,
				[WorkOrderQuoteId] BIGINT NULL,
				[WorkOrderPartNoId] BIGINT NULL,
			)

			CREATE TABLE #tmpPartResult (        
				[PublicationId] VARCHAR(100) NULL,
				[Fleet] VARCHAR(100) NULL,
				[ConditionName] NVARCHAR(MAX) NULL,
				[RevisionNum] VARCHAR(100) NULL,
				[RevisionDate] VARCHAR(100) NULL,
				[SecondPublicationId] VARCHAR(100) NULL,
				[SecondRevisionNum] VARCHAR(100) NULL,
				[SecondRevisionDate] VARCHAR(100) NULL,
				[WorkOrderNum] VARCHAR(50) NULL,
				[IsEasaUKLicenseType] VARCHAR(50) NULL,
				[PublishedById] INT NULL,
				[VendorName] VARCHAR(100) NULL,
				[ManufacturerName] VARCHAR(100) NULL,
				[PublishedByOthers] VARCHAR(100) NULL,
				[IsMultiple] BIT NULL,
				[EmailBody] NVARCHAR(MAX) NULL
			)

			CREATE TABLE #tmpResult (        
				[WorkOrderQuoteId] BIGINT NULL,
				[WorkOrderPartNoId] BIGINT NULL,
				[Remarks] NVARCHAR(MAX) NULL,
			)

			INSERT INTO #tmpWorkOrderQuote ([WorkOrderQuoteId], [WorkOrderPartNoId])
			SELECT [WorkOrderQuoteId], [WOPartNoId]
			FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK)
			WHERE [WorkOrderQuoteId] = @WorkOrderQuoteId;

			SELECT @TotalQuoteRow = COUNT([RowId]), @CurrentQuoteRow = MIN([RowId]) FROM #tmpWorkOrderQuote;

			WHILE(@CurrentQuoteRow <= @TotalQuoteRow) AND ISNULL(@TotalQuoteRow, 0) > 0
			BEGIN
				
				SELECT @workOrderPartNoId = [WorkOrderPartNoId] FROM #tmpWorkOrderQuote WHERE [RowId] = @CurrentQuoteRow;

				SELECT @WorkOrderId = [WorkOrderId] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @workOrderPartNoId;

				TRUNCATE TABLE #tmpPartResult;

				INSERT INTO #tmpPartResult EXEC [dbo].[GetWorkorderQuoteCurrectiveAction] @WorkOrderId, @workOrderPartNoId;
				
				IF EXISTS(SELECT 1 FROM #tmpPartResult)
				BEGIN
					
					SELECT	@ConditionName = ConditionName, @PublicationId = PublicationId, @RevisionNum = RevisionNum, @RevisionDate = RevisionDate, @SecondPublicationId = SecondPublicationId, @SecondRevisionNum = SecondRevisionNum, @SecondRevisionDate = SecondRevisionDate, 
							@WorkOrderNum = WorkOrderNum, @IsEasaUKLicenseType = IsEasaUKLicenseType, @PublishedById = PublishedById, @VendorName = VendorName, @ManufacturerName = ManufacturerName, @PublishedByOthers = PublishedByOthers, @IsMultiple = IsMultiple, @EmailBody = EmailBody
					FROM #tmpPartResult;

					IF(@IsMultiple IS NULL OR ISNULL(@PublicationId, '0') = '0')
					BEGIN
						SET @EmailContent = '';
					END
					ELSE
					BEGIN
						SET @EmailContent = @EmailBody;

						-- Apply replacements
						SET @EmailContent = REPLACE(@EmailContent, '#Condition', ISNULL(NULLIF(@ConditionName,''), '-'));
						SET @EmailContent = REPLACE(@EmailContent, '#PublicationName', ISNULL(@PublicationId, '-'));
						SET @EmailContent = REPLACE(@EmailContent, '#RevisionNumber', ISNULL(NULLIF(@RevisionNum,''), '-'));
						SET @EmailContent = REPLACE(@EmailContent, '#RevisionDate', ISNULL(NULLIF(@RevisionDate,''), '-'));
						SET @EmailContent = REPLACE(@EmailContent, '#RepairSpecificationName', ISNULL(@SecondPublicationId, '-'));
						SET @EmailContent = REPLACE(@EmailContent, '#RepairRevNum', ISNULL(NULLIF(@SecondRevisionNum,''), '-'));
						SET @EmailContent = REPLACE(@EmailContent, '#RepairRevDate', ISNULL(NULLIF(@SecondRevisionDate,''), '-'));
						SET @EmailContent = REPLACE(@EmailContent, '#WorkOrderNumber', ISNULL(@WorkOrderNum, '-'));
						SET @EmailContent = REPLACE(@EmailContent, '#FAAorEASA', ISNULL(@IsEasaUKLicenseType, '-'));

						-- Handle conditional PublicationByName
						DECLARE @PublicationByName VARCHAR(200);

						IF @PublishedById = @VendorModuleId   -- Vendor
							SET @PublicationByName = @VendorName;
						ELSE IF @PublishedById = @ManufacturerModuleId -- Manufacturer
							SET @PublicationByName = @ManufacturerName;
						ELSE IF @PublishedById = @OtherModuleId -- Others
							SET @PublicationByName = @PublishedByOthers;
						ELSE
							SET @PublicationByName = '-';

						SET @EmailContent = REPLACE(@EmailContent, '#PublicationByName', ISNULL(@PublicationByName, '-'));
					END

					-- Final result
					INSERT INTO #tmpResult ([WorkOrderQuoteId], [WorkOrderPartNoId], [Remarks])
					VALUES (@WorkOrderQuoteId, @workOrderPartNoId, @EmailContent) 
				END
			
				SET @CurrentQuoteRow += 1;
			END

			CREATE TABLE #tblTempQuoteMain (
				ItemNo INT IDENTITY (1, 1) NOT NULL,
				ID INT,
				ItemMasterId INT,
				PartNumber NVARCHAR(255),
				PartDescription NVARCHAR(500),
				RevisedPartNo NVARCHAR(255),
				Revenue DECIMAL(18, 2),
				MaterialCost DECIMAL(18, 2),
				MaterialRevenuePercentage DECIMAL(18, 2),
				LaborCost DECIMAL(18, 2),
				LaborRevenuePercentage DECIMAL(18, 2),
				OverHeadCost DECIMAL(18, 2),
				OverHeadCostRevenuePercentage DECIMAL(18, 2),
				FreightRevenue DECIMAL(18, 2),
				OtherCost DECIMAL(18, 2),
				DirectCost DECIMAL(18, 2),
				Margin DECIMAL(18, 2),
				MarginPercentage DECIMAL(18, 2),
				Scope NVARCHAR(255),
				StockLineNumber NVARCHAR(255),
				SerialNumber NVARCHAR(255),
				MaterialRevenue DECIMAL(18, 2),
				LaborRevenue DECIMAL(18, 2),
				ChargesRevenue DECIMAL(18, 2),
				MaterialFlatBillingAmount DECIMAL(18, 2),
				LaborFlatBillingAmount DECIMAL(18, 2),
				ChargesFlatBillingAmount DECIMAL(18, 2),
				FreightFlatBillingAmount DECIMAL(18, 2),
				LaborFinalAmount DECIMAL(18, 2),
				ChargesFinalAmount DECIMAL(18, 2),
				FreightFinalAmount DECIMAL(18, 2),
				Quantity INT,
				QuoteMethod INT,
				CommonFlatRate DECIMAL(18, 2),
				TATDaysStandard INT,
				EvalFees DECIMAL(18, 2),
				SubtotalForTax DECIMAL(18, 2),
				TAXRates DECIMAL(18, 2),
				OtherTax DECIMAL(18, 2),
				SalesTaxAmount DECIMAL(18, 2),
				OtherTaxAmount DECIMAL(18, 2),
				FinalTotal DECIMAL(18, 2),
				FinalLaborTotal DECIMAL(18, 2),
				RowNumber INT,
				Memo VARCHAR(MAX),
				IsPrintCorrectiveAction BIT,
				EstimatedShipDate DATETIME2(7)NULL,
				CustomerReference NVARCHAR(255),
			);


		IF(@isByPartIds = 1)
		BEGIN
				;WITH WOQPartCte AS (
				SELECT DISTINCT
				wop.ID,
				im.ItemMasterId,
				 CASE WHEN ISNULL(wop.RevisedPartNumber, '') != '' THEN wop.RevisedPartNumber ELSE im.PartNumber END PartNumber,  
				 CASE WHEN ISNULL(wop.RevisedPartDescription, '') != '' THEN wop.RevisedPartDescription ELSE im.PartDescription END PartDescription,
				 --wop.RevisedPartDescription PartDescription,  
				 RevisedPartNo = CASE WHEN im1.ItemMasterId IS null THEN  '' ELSE im1.PartNumber END,  
				 Revenue = SUM(ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0)),  
				 SUM(wqd.MaterialCost) AS 'MaterialCost',  
				 SUM(wqd.MaterialRevenuePercentage) AS 'MaterialRevenuePercentage',  
				 SUM(wqd.LaborCost) AS 'LaborCost',  
				 SUM(wqd.LaborRevenuePercentage) AS 'LaborRevenuePercentage',  
				 SUM(wqd.OverHeadCost) AS 'OverHeadCost',  
				 SUM(wqd.OverHeadCostRevenuePercentage) AS 'OverHeadCostRevenuePercentage',  
				 SUM(wqd.FreightRevenue) AS 'FreightRevenue',  
				 OtherCost = SUM(wqd.ChargesCost),  
				 DirectCost = SUM(wqd.MaterialCost + wqd.LaborCost + wqd.ChargesCost),  
				 Margin = SUM(wqd.MaterialMargin + wqd.LaborMargin + wqd.ChargesMargin),  
				 MarginPercentage = SUM(wqd.MaterialMarginPer + wqd.LaborMarginPer + wqd.ChargesMarginPer),  
				 Scope = UPPER(MAX(s.WorkScopeCode)),
				 UPPER(sl.StockLineNumber) AS StockLineNumber,
				 --UPPER(sl.SerialNumber) AS SerialNumber,
				 CASE WHEN ISNULL(wop.RevisedSerialNumber, '') != '' THEN UPPER(wop.RevisedSerialNumber) ELSE UPPER(wop.CurrentSerialNumber) END AS SerialNumber,
				 SUM(wqd.MaterialRevenue) AS 'MaterialRevenue',  
				 SUM(wqd.LaborRevenue) AS 'LaborRevenue',  
				 SUM(wqd.ChargesRevenue) AS 'ChargesRevenue',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN wqd.CommonFlatRate ELSE SUM(wqd.MaterialFlatBillingAmount) END AS 'MaterialFlatBillingAmount' ,  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.LaborFlatBillingAmount) END AS 'LaborFlatBillingAmount',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.ChargesFlatBillingAmount) END AS 'ChargesFlatBillingAmount',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.FreightFlatBillingAmount) END AS 'FreightFlatBillingAmount',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.LaborFlatBillingAmount) END AS 'LaborFinalAmount',
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN  0.00 ELSE SUM(wqd.ChargesFlatBillingAmount) END AS 'ChargesFinalAmount',
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN  0.00 ELSE SUM(wqd.FreightFlatBillingAmount) END AS 'FreightFinalAmount',
				 wop.Quantity,  
				 ISNULL(wqd.QuoteMethod,0) AS QuoteMethod,  
				 wqd.CommonFlatRate,  
				 wop.TATDaysStandard ,
				 ISNULL(wqd.EvalFees,0) AS EvalFees,
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN wqd.CommonFlatRate 
				 ELSE SUM(ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0) + ISNULL(wqd.FreightFlatBillingAmount,0))
				 END AS subtotalfortax,
				 TAXRates = (SELECT SUM(ISNULL(tr.TaxRate,0)) FROM dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)
							LEFT JOIN dbo.TaxType t WITH(NOLOCK) ON custtax.TaxTypeId = t.TaxTypeId
							LEFT JOIN dbo.TaxRate tr WITH(NOLOCK) ON custtax.TaxRateId = tr.TaxRateId and t.Code ='SALES TAX'
						WHERE custtax.CustomerId = cust.[CustomerId] and custtax.IsActive = 1 and custtax.IsDeleted = 0 ),
				Othertax = (SELECT SUM(ISNULL(tr.TaxRate,0)) FROM dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)
							LEFT JOIN dbo.TaxType t WITH(NOLOCK) ON custtax.TaxTypeId = t.TaxTypeId
							LEFT JOIN dbo.TaxRate tr WITH(NOLOCK) ON custtax.TaxRateId = tr.TaxRateId  and t.Code !='SALES TAX'
						WHERE custtax.CustomerId = cust.[CustomerId] and custtax.IsActive = 1 and custtax.IsDeleted = 0 ),
				--CAST((
				--	SELECT TOP 1
				--		REPLACE(REPLACE(ctd.Memo, '</p><p>', ' '), '<br>', '')
				--	FROM dbo.CommonWorkOrderTearDown ctd WITH (NOLOCK)
				--	LEFT JOIN dbo.CommonTeardownType ctt WITH (NOLOCK) 
				--		ON ctd.CommonTeardownTypeId = ctt.CommonTeardownTypeId 
				--	WHERE ctd.WorkFlowWorkOrderId = wf.WorkFlowWorkOrderId
				--	  AND UPPER(ctt.Code) = UPPER(@CorrectiveActionCode)
				--	FOR XML PATH(''), TYPE
				--).value('.', 'NVARCHAR(MAX)') AS NVARCHAR(MAX)) AS Memo				
				 CASE WHEN ISNULL(wop.PublicationNotes, '') <> '' THEN REPLACE(REPLACE(wop.PublicationNotes, '</p><p>', ' '), '<br>', '') ELSE REPLACE(REPLACE(tmp.[Remarks], '</p><p>', ' '), '<br>', '') END AS Memo
				,ISNULL(woq.IsPrintCorrectiveAction, 0) AS IsPrintCorrectiveAction
				--Memo =
				--(SELECT CAST('<x>' + REPLACE(REPLACE(ctd.Memo, '</p><p>',' '),'<br>','') + '</x>' AS XML).value('.', 'NVARCHAR(MAX)') 
				--	FROM
				--		dbo.CommonWorkOrderTearDown ctd WITH(NOLOCK)
				--		LEFT JOIN dbo.CommonTeardownType ctt WITH(NOLOCK) ON ctd.CommonTeardownTypeId = ctt.CommonTeardownTypeId 
				--	WHERE ctd.WorkFlowWorkOrderId = wf.WorkFlowWorkOrderId AND UPPER(ctt.Code) = UPPER(@CorrectiveActionCode))
					--,ISNULL(FORMAT(wop.EstimatedShipDate, 'MM/dd/yyyy'), '') AS EstimatedShipDate
						,CASE 
						WHEN wop.EstimatedShipDate IS NULL 
							 OR LTRIM(RTRIM(CAST(wop.EstimatedShipDate AS VARCHAR))) = '' 
						THEN '' 
						ELSE FORMAT(wop.EstimatedShipDate, 'MM/dd/yyyy') 
					 END AS EstimatedShipDate,
					 wop.CustomerReference
			FROM dbo.WorkOrder wo WITH(NOLOCK)
				 INNER JOIN dbo.WorkOrderQuote woq WITH(NOLOCK) ON wo.WorkOrderId = woq.WorkOrderId  
				 INNER JOIN dbo.WorkOrderQuoteDetails wqd WITH(NOLOCK) ON woq.WorkOrderQuoteId = wqd.WorkOrderQuoteId  
				 INNER JOIN dbo.WorkOrderPartNumber wop WITH(NOLOCK) ON wqd.WOPartNoId = wop.ID  
				 INNER JOIN dbo.WorkOrderWorkFlow wf WITH(NOLOCK) ON  wop.ID = wf.WorkOrderPartNoId
				 INNER JOIN dbo.ItemMaster im WITH(NOLOCK) ON wop.ItemMasterId = im.ItemMasterId  
				 LEFT JOIN dbo.ItemMaster im1 WITH(NOLOCK) ON im.RevisedPartId = im1.ItemMasterId  
				  AND ISNULL(im1.IsNonStock,0) = 0
				  INNER JOIN dbo.WorkScope s WITH(NOLOCK) ON wop.WorkOrderScopeId = s.WorkScopeId  
				 INNER JOIN dbo.StockLine sl WITH(NOLOCK) ON wop.StockLineId = sl.StockLineId  
				 INNER JOIN dbo.Customer cust WITH(NOLOCK)  ON woq.CustomerId = cust.CustomerId
				 LEFT JOIN #tmpResult tmp ON tmp.WorkOrderQuoteId = woq.WorkOrderQuoteId AND tmp.WorkOrderPartNoId = wop.ID
			WHERE woq.WorkOrderQuoteId = @WorkOrderQuoteId AND wop.ID IN (SELECT value FROM STRING_SPLIT(@workOrderPartNoIds, ','))
				 AND woq.IsActive = 1 AND woq.IsDeleted = 0  
			 AND ISNULL(im.IsNonStock,0) = 0 AND ISNULL(sl.IsNonStock,0) = 0
				  GROUP BY im.PartNumber, wop.ID, wop.RevisedPartNumber, wop.RevisedPartDescription,
				 im.PartDescription, im1.ItemMasterId, im1.PartNumber,im.ItemMasterId, wop.PublicationNotes, tmp.[Remarks],
				 sl.StockLineNumber, wop.RevisedSerialNumber, wop.CurrentSerialNumber, wop.Quantity, wqd.QuoteMethod, wqd.CommonFlatRate, TATDaysStandard,wqd.EvalFees, cust.CustomerId,wf.WorkFlowWorkOrderId,woq.IsPrintCorrectiveAction,wop.EstimatedShipDate,wop.CustomerReference),
			AfterTax AS (SELECT *, CAST(((Ct.subtotalfortax * Ct.TAXRates) / 100) AS DECIMAL(18, 2)) AS SalesTaxAmount, CAST(((Ct.subtotalfortax * Ct.Othertax) / 100) AS DECIMAL(18, 2)) AS OtherTaxAmount FROM WOQPartCte Ct)
	       

			SELECT *, (ISNULL(FinalQuote.SalesTaxAmount, 0) + ISNULL(FinalQuote.OtherTaxAmount, 0) + ISNULL(FinalQuote.subtotalfortax, 0)) FinalTotal, 
			CASE WHEN ISNULL(QuoteMethod,0) > 0  THEN ISNULL(MaterialFlatBillingAmount,0) ELSE ISNULL(MaterialFlatBillingAmount,0) + ISNULL(LaborFlatBillingAmount,0)END as FinalLaborTotal,ROW_NUMBER() OVER (ORDER BY ItemMasterId) AS RowNumber INTO #tmpQuoteIds FROM AfterTax FinalQuote;
			
			INSERT INTO #tblTempQuoteMain(ID, ItemMasterId, PartNumber, PartDescription, RevisedPartNo, Revenue, MaterialCost, 
						MaterialRevenuePercentage, LaborCost, LaborRevenuePercentage, OverHeadCost, 
						OverHeadCostRevenuePercentage, FreightRevenue, OtherCost, DirectCost, Margin, 
						MarginPercentage, Scope, StockLineNumber, SerialNumber, MaterialRevenue, 
						LaborRevenue, ChargesRevenue, MaterialFlatBillingAmount, LaborFlatBillingAmount, 
						ChargesFlatBillingAmount, FreightFlatBillingAmount, LaborFinalAmount, 
						ChargesFinalAmount, FreightFinalAmount, Quantity, QuoteMethod, CommonFlatRate, 
						TATDaysStandard, EvalFees, SubtotalForTax, TAXRates, OtherTax, SalesTaxAmount, 
						OtherTaxAmount, FinalTotal, FinalLaborTotal, RowNumber, Memo, IsPrintCorrectiveAction,EstimatedShipDate,CustomerReference)
			SELECT 
					ID, ItemMasterId, PartNumber, PartDescription, RevisedPartNo, Revenue, MaterialCost, 
					MaterialRevenuePercentage, LaborCost, LaborRevenuePercentage, OverHeadCost, 
					OverHeadCostRevenuePercentage, FreightRevenue, OtherCost, DirectCost, Margin, 
					MarginPercentage, Scope, StockLineNumber, SerialNumber, MaterialRevenue, 
					LaborRevenue, ChargesRevenue, MaterialFlatBillingAmount, LaborFlatBillingAmount, 
					ChargesFlatBillingAmount, FreightFlatBillingAmount, LaborFinalAmount, 
					ChargesFinalAmount, FreightFinalAmount, Quantity, QuoteMethod, CommonFlatRate, 
					TATDaysStandard, EvalFees, SubtotalForTax, TAXRates, OtherTax, SalesTaxAmount, 
					OtherTaxAmount, 
					FinalTotal,
					FinalLaborTotal,
					RowNumber,
					Memo, IsPrintCorrectiveAction,EstimatedShipDate,CustomerReference
				FROM #tmpQuoteIds
				ORDER BY ID;

		END
		ELSE
		BEGIN
				;WITH WOQPartCte AS (
				SELECT DISTINCT  
				wop.ID,
				im.ItemMasterId,
				 --im.PartNumber,  
				 --im.PartDescription,  
				 CASE WHEN ISNULL(wop.RevisedPartNumber, '') != '' THEN wop.RevisedPartNumber ELSE im.PartNumber END PartNumber,  
				 CASE WHEN ISNULL(wop.RevisedPartDescription, '') != '' THEN wop.RevisedPartDescription ELSE im.PartDescription END PartDescription,
				 RevisedPartNo = CASE WHEN im1.ItemMasterId IS null THEN  '' ELSE im1.PartNumber END,  
				 Revenue = SUM(ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0)),  
				 SUM(wqd.MaterialCost) AS 'MaterialCost',  
				 SUM(wqd.MaterialRevenuePercentage) AS 'MaterialRevenuePercentage',  
				 SUM(wqd.LaborCost) AS 'LaborCost',  
				 SUM(wqd.LaborRevenuePercentage) AS 'LaborRevenuePercentage',  
				 SUM(wqd.OverHeadCost) AS 'OverHeadCost',  
				 SUM(wqd.OverHeadCostRevenuePercentage) AS 'OverHeadCostRevenuePercentage',  
				 SUM(wqd.FreightRevenue) AS 'FreightRevenue',  
				 OtherCost = SUM(wqd.ChargesCost),  
				 DirectCost = SUM(wqd.MaterialCost + wqd.LaborCost + wqd.ChargesCost),  
				 Margin = SUM(wqd.MaterialMargin + wqd.LaborMargin + wqd.ChargesMargin),  
				 MarginPercentage = SUM(wqd.MaterialMarginPer + wqd.LaborMarginPer + wqd.ChargesMarginPer),  
				 Scope = UPPER(MAX(s.WorkScopeCode)),
				 UPPER(sl.StockLineNumber) AS StockLineNumber,
				 --UPPER(sl.SerialNumber) AS SerialNumber,
				 CASE WHEN ISNULL(wop.RevisedSerialNumber, '') != '' THEN UPPER(wop.RevisedSerialNumber) ELSE UPPER(wop.CurrentSerialNumber) END AS SerialNumber,
				 SUM(wqd.MaterialRevenue) AS 'MaterialRevenue',  
				 SUM(wqd.LaborRevenue) AS 'LaborRevenue',  
				 SUM(wqd.ChargesRevenue) AS 'ChargesRevenue',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN wqd.CommonFlatRate ELSE SUM(wqd.MaterialFlatBillingAmount) END AS 'MaterialFlatBillingAmount' ,  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.LaborFlatBillingAmount) END AS 'LaborFlatBillingAmount',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.ChargesFlatBillingAmount) END AS 'ChargesFlatBillingAmount',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.FreightFlatBillingAmount) END AS 'FreightFlatBillingAmount',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.LaborFlatBillingAmount) END AS 'LaborFinalAmount',
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN  0.00 ELSE SUM(wqd.ChargesFlatBillingAmount) END AS 'ChargesFinalAmount',
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN  0.00 ELSE SUM(wqd.FreightFlatBillingAmount) END AS 'FreightFinalAmount',
				 wop.Quantity,  
				 ISNULL(wqd.QuoteMethod,0) AS QuoteMethod,  
				 wqd.CommonFlatRate,  
				 wop.TATDaysStandard ,
				 ISNULL(wqd.EvalFees,0) AS EvalFees,
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN wqd.CommonFlatRate 
				 ELSE SUM(ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0) + ISNULL(wqd.FreightFlatBillingAmount,0))
				 END AS subtotalfortax,
				 TAXRates = (SELECT SUM(ISNULL(tr.TaxRate,0)) FROM dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)
							LEFT JOIN dbo.TaxType t WITH(NOLOCK) ON custtax.TaxTypeId = t.TaxTypeId
							LEFT JOIN dbo.TaxRate tr WITH(NOLOCK) ON custtax.TaxRateId = tr.TaxRateId and t.Code ='SALES TAX'
						WHERE custtax.CustomerId = cust.[CustomerId] and custtax.IsActive = 1 and custtax.IsDeleted = 0 ),
				Othertax = (SELECT SUM(ISNULL(tr.TaxRate,0)) FROM dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)
							LEFT JOIN dbo.TaxType t WITH(NOLOCK) ON custtax.TaxTypeId = t.TaxTypeId
							LEFT JOIN dbo.TaxRate tr WITH(NOLOCK) ON custtax.TaxRateId = tr.TaxRateId 
						WHERE custtax.CustomerId = cust.[CustomerId] and custtax.IsActive = 1 and custtax.IsDeleted = 0 ),
				--CAST((
				--	SELECT TOP 1
				--		REPLACE(REPLACE(ctd.Memo, '</p><p>', ' '), '<br>', '')
				--	FROM dbo.CommonWorkOrderTearDown ctd WITH (NOLOCK)
				--	LEFT JOIN dbo.CommonTeardownType ctt WITH (NOLOCK) 
				--		ON ctd.CommonTeardownTypeId = ctt.CommonTeardownTypeId 
				--	WHERE ctd.WorkFlowWorkOrderId = wf.WorkFlowWorkOrderId
				--	  AND UPPER(ctt.Code) = UPPER(@CorrectiveActionCode)
				--	FOR XML PATH(''), TYPE
				--).value('.', 'NVARCHAR(MAX)') AS NVARCHAR(MAX)) AS Memo
				CASE WHEN ISNULL(wop.PublicationNotes, '') <> '' THEN REPLACE(REPLACE(wop.PublicationNotes, '</p><p>', ' '), '<br>', '') ELSE REPLACE(REPLACE(tmp.[Remarks], '</p><p>', ' '), '<br>', '') END AS Memo
				,ISNULL(woq.IsPrintCorrectiveAction, 0) AS IsPrintCorrectiveAction
				--Memo =
				--(SELECT CAST('<x>' + REPLACE(REPLACE(ctd.Memo, '</p><p>',' '),'<br>','') + '</x>' AS XML).value('.', 'NVARCHAR(MAX)') 
				--	FROM
				--		dbo.CommonWorkOrderTearDown ctd WITH(NOLOCK)
				--		LEFT JOIN dbo.CommonTeardownType ctt WITH(NOLOCK) ON ctd.CommonTeardownTypeId = ctt.CommonTeardownTypeId 
				--		WHERE ctd.WorkFlowWorkOrderId = wf.WorkFlowWorkOrderId AND UPPER(ctt.Code) = UPPER(@CorrectiveActionCode) AND ctd.MasterCompanyId = 20 )
				--,ISNULL(FORMAT(wop.EstimatedShipDate, 'MM/dd/yyyy'), '') AS EstimatedShipDate
						,CASE 
						WHEN wop.EstimatedShipDate IS NULL 
							 OR LTRIM(RTRIM(CAST(wop.EstimatedShipDate AS VARCHAR))) = '' 
						THEN '' 
						ELSE FORMAT(wop.EstimatedShipDate, 'MM/dd/yyyy') 
					 END AS EstimatedShipDate,wop.CustomerReference
			FROM dbo.WorkOrder wo WITH(NOLOCK)
				 INNER JOIN dbo.WorkOrderQuote woq WITH(NOLOCK) ON wo.WorkOrderId = woq.WorkOrderId  
				 INNER JOIN dbo.WorkOrderQuoteDetails wqd WITH(NOLOCK) ON woq.WorkOrderQuoteId = wqd.WorkOrderQuoteId  
				 INNER JOIN dbo.WorkOrderPartNumber wop WITH(NOLOCK) ON wqd.WOPartNoId = wop.ID 
				 INNER JOIN dbo.WorkOrderWorkFlow wf WITH(NOLOCK) ON  wop.ID = wf.WorkOrderPartNoId
				 --LEFT JOIN dbo.CommonWorkOrderTearDown ctd WITH(NOLOCK) ON wf.WorkFlowWorkOrderId = ctd.WorkFlowWorkOrderId
				 INNER JOIN dbo.ItemMaster im WITH(NOLOCK) ON wop.ItemMasterId = im.ItemMasterId  
				 LEFT JOIN dbo.ItemMaster im1 WITH(NOLOCK) ON im.RevisedPartId = im1.ItemMasterId  
				  AND ISNULL(im1.IsNonStock,0) = 0
				  INNER JOIN dbo.WorkScope s WITH(NOLOCK) ON wop.WorkOrderScopeId = s.WorkScopeId  
				 INNER JOIN dbo.StockLine sl WITH(NOLOCK) ON wop.StockLineId = sl.StockLineId  
				 INNER JOIN dbo.Customer cust WITH(NOLOCK)  ON woq.CustomerId = cust.CustomerId
				 LEFT JOIN #tmpResult tmp ON tmp.WorkOrderQuoteId = woq.WorkOrderQuoteId AND tmp.WorkOrderPartNoId = wop.ID
			WHERE woq.WorkOrderQuoteId = @WorkOrderQuoteId 
				 AND woq.IsActive = 1 AND woq.IsDeleted = 0  
			 AND ISNULL(im.IsNonStock,0) = 0 AND ISNULL(sl.IsNonStock,0) = 0
				  GROUP BY im.PartNumber,  wop.ID, wop.RevisedPartNumber, wop.RevisedPartDescription,
				 im.PartDescription, im1.ItemMasterId, im1.PartNumber, im.ItemMasterId, wop.PublicationNotes, tmp.[Remarks],
				 sl.StockLineNumber, wop.RevisedSerialNumber, wop.CurrentSerialNumber, wop.Quantity, wqd.QuoteMethod, wqd.CommonFlatRate, TATDaysStandard,wqd.EvalFees, cust.CustomerId,wf.WorkFlowWorkOrderId,woq.IsPrintCorrectiveAction,wop.EstimatedShipDate,wop.CustomerReference),
			AfterTax AS (SELECT *, CAST(((Ct.subtotalfortax * Ct.TAXRates) / 100) AS DECIMAL(18, 2)) AS SalesTaxAmount, CAST(((Ct.subtotalfortax * Ct.Othertax) / 100) AS DECIMAL(18, 2)) AS OtherTaxAmount FROM WOQPartCte Ct)

			SELECT *, (ISNULL(FinalQuote.SalesTaxAmount, 0) + ISNULL(FinalQuote.OtherTaxAmount, 0) + ISNULL(FinalQuote.subtotalfortax, 0)) FinalTotal, 
			CASE WHEN ISNULL(QuoteMethod,0) > 0  THEN ISNULL(MaterialFlatBillingAmount,0) ELSE ISNULL(MaterialFlatBillingAmount,0) + ISNULL(LaborFlatBillingAmount,0)END as FinalLaborTotal,ROW_NUMBER() OVER (ORDER BY ItemMasterId) AS RowNumber INTO #tmpQuotetblMulti FROM AfterTax FinalQuote;
			
			INSERT INTO #tblTempQuoteMain(ID, ItemMasterId, PartNumber, PartDescription, RevisedPartNo, Revenue, MaterialCost, 
						MaterialRevenuePercentage, LaborCost, LaborRevenuePercentage, OverHeadCost, 
						OverHeadCostRevenuePercentage, FreightRevenue, OtherCost, DirectCost, Margin, 
						MarginPercentage, Scope, StockLineNumber, SerialNumber, MaterialRevenue, 
						LaborRevenue, ChargesRevenue, MaterialFlatBillingAmount, LaborFlatBillingAmount, 
						ChargesFlatBillingAmount, FreightFlatBillingAmount, LaborFinalAmount, 
						ChargesFinalAmount, FreightFinalAmount, Quantity, QuoteMethod, CommonFlatRate, 
						TATDaysStandard, EvalFees, SubtotalForTax, TAXRates, OtherTax, SalesTaxAmount, 
						OtherTaxAmount, FinalTotal, FinalLaborTotal, RowNumber, Memo, IsPrintCorrectiveAction,EstimatedShipDate,CustomerReference)
				SELECT 
					ID, ItemMasterId, PartNumber, PartDescription, RevisedPartNo, Revenue, MaterialCost, 
					MaterialRevenuePercentage, LaborCost, LaborRevenuePercentage, OverHeadCost, 
					OverHeadCostRevenuePercentage, FreightRevenue, OtherCost, DirectCost, Margin, 
					MarginPercentage, Scope, StockLineNumber, SerialNumber, MaterialRevenue, 
					LaborRevenue, ChargesRevenue, MaterialFlatBillingAmount, LaborFlatBillingAmount, 
					ChargesFlatBillingAmount, FreightFlatBillingAmount, LaborFinalAmount, 
					ChargesFinalAmount, FreightFinalAmount, Quantity, QuoteMethod, CommonFlatRate, 
					TATDaysStandard, EvalFees, SubtotalForTax, TAXRates, OtherTax, SalesTaxAmount, 
					OtherTaxAmount, 
					FinalTotal,
					FinalLaborTotal,
					RowNumber,
					Memo, IsPrintCorrectiveAction,CASE 
        WHEN LTRIM(RTRIM(CAST(EstimatedShipDate AS VARCHAR))) = '' THEN NULL
        ELSE EstimatedShipDate
    END AS EstimatedShipDate,CustomerReference
				FROM #tmpQuotetblMulti
				ORDER BY ID;

		END

		SET @totalCount = (SELECT  COUNT(*) FROM #tblTempQuoteMain)

		WHILE @currentRow <= @totalCount
		BEGIN
			SET @PartId =  (SELECT  ID FROM #tblTempQuoteMain WHERE RowNumber = @currentRow) 
			print @PartId
			EXEC [dbo].[USP_GetCustomerTax_Information_Repair_WOQ_Output] 
		     @WorkOrderQuoteId,
			 @WOId,
			 @PartId,
		     @TotalFreight = @TotalFreight OUTPUT,
		     @TotalCharges = @TotalCharges OUTPUT,
			 @SubTotal = @SubTotal OUTPUT,
			 @WOQGrandTotal = @WOQGrandTotal OUTPUT,
			 @FinalSalesTaxes = @FinalSalesTaxes OUTPUT,
			 @FinalOtherTaxes = @FinalOtherTaxes OUTPUT
			UPDATE  #tblTempQuoteMain SET SalesTaxAmount = @FinalSalesTaxes,OtherTaxAmount = @FinalOtherTaxes, FinalTotal = ISNULL(@FinalSalesTaxes,0) + ISNULL(@FinalOtherTaxes,0) + ISNULL(SubtotalForTax,0)  WHERE RowNumber = @currentRow
			SET @currentRow = @currentRow + 1;
		END

	SELECT * FROM #tblTempQuoteMain ORDER BY ID 
		
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetWorkOrderQuotePrintPdfDataMultipleMPN'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + ISNULL(CAST(@WorkOrderQuoteId AS VARCHAR(50)), '') + ''''
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters    = @ProcedureParameters  
                     , @ApplicationName        = @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END