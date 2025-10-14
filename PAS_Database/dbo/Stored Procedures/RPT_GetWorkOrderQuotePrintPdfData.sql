/*************************************************************             
 ** File:   [RPT_GetWorkOrderQuotePrintPdfData]             
 ** Author:   AMIT GHEDIYA  
 ** Description: This stored procedure is used to get work order quote pdf details  
 ** Purpose:           
 ** Date:   01/05/2024          
            
 ** PARAMETERS:   
 ** RETURN VALUE:             
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date			Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    01/05/2024		AMIT GHEDIYA		Created  
	2    01/05/2024		HEMANT SALIYA		Updated For Handle Flat Rate values 
	3    02/07/2024		VISHAL SUTHAR		Updated to handle Flat Rate and calculate tax in SP level itself
	4    21/JAN/2025	RAJESH GAMI			Updated to WorkScopeCode Instead of their Description
	5    07-APR-2025	RAJESH GAMI			Updated for Get correct PN and Serial Number
	6    28-APR-2025	Abhishek Jirawla    Added Corrective Action Data
	7    01-MAY-2025    Hemant Saliya		Created for Marerials, labor, flat rate changes
	8    09-MAY-2025	Devendra Shekh		Added IsPrintCorrectiveAction to select
	9    10-JUL-2025    Moin Bloch          Updated MEMO To PublicationNotes
	10	 23-JUL-2025    Devendra Shekh      Added Case for Memo     
	11	 14-OCT-2025     RAJESH GAMI		Return Estimated Ship Date
--EXEC [RPT_GetWorkOrderQuotePrintPdfData] 2358,4357  
**************************************************************/  
CREATE PROCEDURE [dbo].[RPT_GetWorkOrderQuotePrintPdfData]  
 @WorkOrderQuoteId bigint,  
 @workOrderPartNoId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN   
		DECLARE @CorrectiveActionCode VARCHAR(100) = 'CRA';

		DECLARE @VendorModuleId INT, @ManufacturerModuleId INT, @OtherModuleId INT;
		SELECT @VendorModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Vendor';
		SELECT @ManufacturerModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Manufacturer';
		SELECT @OtherModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Others';

		DECLARE @WorkOrderId BIGINT;
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

		SELECT @WorkOrderId = [WorkOrderId] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @workOrderPartNoId;

		IF OBJECT_ID(N'tempdb..#tmpPartResult') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpPartResult
		END 

		IF OBJECT_ID(N'tempdb..#tmpResult') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpResult
		END

		CREATE TABLE #tmpPartResult (        
			[PublicationId] VARCHAR(100) NULL,
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
			END

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
			DECLARE @PublicationByName NVARCHAR(200);

			IF @PublishedById = @VendorModuleId   -- Vendor
				SET @PublicationByName = @VendorName;
			ELSE IF @PublishedById = @ManufacturerModuleId -- Manufacturer
				SET @PublicationByName = @ManufacturerName;
			ELSE IF @PublishedById = @OtherModuleId -- Others
				SET @PublicationByName = @PublishedByOthers;
			ELSE
				SET @PublicationByName = '-';
			
			SET @EmailContent = REPLACE(@EmailContent, '#PublicationByName', ISNULL(@PublicationByName, '-'));

			-- Final result
			INSERT INTO #tmpResult ([WorkOrderQuoteId], [WorkOrderPartNoId], [Remarks])
			VALUES (@WorkOrderQuoteId, @workOrderPartNoId, @EmailContent) 
		END

		;WITH WOQPartCte AS (
		SELECT DISTINCT   
		 CASE WHEN ISNULL(wop.RevisedPartNumber, '') != '' THEN wop.RevisedPartNumber ELSE im.PartNumber END PartNumber,    
		 CASE WHEN ISNULL(wop.RevisedPartDescription, '') != '' THEN wop.RevisedPartDescription ELSE im.PartDescription END PartDescription,  
		 RevisedPartNo = CASE WHEN im1.ItemMasterId IS null THEN  '' ELSE im1.PartNumber END,  
		 --Revenue = SUM(ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0)),  
		 Revenue =
		 CASE WHEN MAX(ISNULL(wqd.MaterialBuildMethod,0)) = 3 THEN SUM(wqd.MaterialFlatBillingAmount) ELSE 
						SUM(wqd.MaterialRevenue) END 
		 + CASE WHEN MAX(ISNULL(wqd.LaborBuildMethod,0)) = 3 THEN SUM(wqd.LaborFlatBillingAmount) ELSE 
						SUM(wqd.LaborRevenue) END
		 + CASE WHEN MAX(ISNULL(wqd.ChargesBuildMethod,0)) = 3 THEN SUM(wqd.ChargesFlatBillingAmount) ELSE 
						SUM(wqd.ChargesRevenue) END,

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
		 --CASE WHEN ISNULL(wqd.MaterialBuildMethod,0) > 0 THEN wqd.CommonFlatRate ELSE SUM(wqd.MaterialFlatBillingAmount) END AS 'MaterialFlatBillingAmount' ,  
		 --CASE WHEN ISNULL(wqd.LaborBuildMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.LaborFlatBillingAmount) END AS 'LaborFlatBillingAmount',  
		 --CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.ChargesFlatBillingAmount) END AS 'ChargesFlatBillingAmount',  
		 --CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.FreightFlatBillingAmount) END AS 'FreightFlatBillingAmount',  
		 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN wqd.CommonFlatRate ELSE 
					CASE WHEN MAX(ISNULL(wqd.MaterialBuildMethod,0)) = 3 THEN SUM(wqd.MaterialFlatBillingAmount) ELSE 
						SUM(wqd.MaterialRevenue) END END AS 'MaterialFlatBillingAmount' , 
						
		CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE 
					CASE WHEN MAX(ISNULL(wqd.LaborBuildMethod,0)) = 3 THEN SUM(wqd.LaborFlatBillingAmount) ELSE 
						SUM(wqd.LaborRevenue) END END AS 'LaborFlatBillingAmount' , 

		CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE 
					CASE WHEN MAX(ISNULL(wqd.ChargesBuildMethod,0)) = 3 THEN SUM(wqd.ChargesFlatBillingAmount) ELSE 
						SUM(wqd.ChargesRevenue) END END AS 'ChargesFlatBillingAmount' ,

		CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE 
					CASE WHEN MAX(ISNULL(wqd.FreightBuildMethod,0)) = 3 THEN SUM(wqd.FreightFlatBillingAmount) ELSE 
						SUM(wqd.FreightRevenue) END END AS 'FreightFlatBillingAmount' ,

		 wop.Quantity,  
		 ISNULL(wqd.QuoteMethod,0) AS QuoteMethod,  
		 wqd.CommonFlatRate,  
		 wop.TATDaysStandard ,
		 ISNULL(wqd.EvalFees,0) AS EvalFees,
		 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN wqd.CommonFlatRate 
		 ELSE (CASE WHEN MAX(ISNULL(wqd.MaterialBuildMethod,0)) = 3 THEN SUM(wqd.MaterialFlatBillingAmount) ELSE 
						SUM(wqd.MaterialRevenue) END 
		 + CASE WHEN MAX(ISNULL(wqd.LaborBuildMethod,0)) = 3 THEN SUM(wqd.LaborFlatBillingAmount) ELSE 
						SUM(wqd.LaborRevenue) END
		 + CASE WHEN MAX(ISNULL(wqd.ChargesBuildMethod,0)) = 3 THEN SUM(wqd.ChargesFlatBillingAmount) ELSE 
						SUM(wqd.ChargesRevenue) END
		 + CASE WHEN MAX(ISNULL(wqd.FreightBuildMethod,0)) = 3 THEN SUM(wqd.FreightFlatBillingAmount) ELSE 
						SUM(wqd.FreightRevenue) END)
		 END AS subtotalfortax,
		 TAXRates = (SELECT SUM(ISNULL(tr.TaxRate,0)) FROM dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)
					LEFT JOIN dbo.TaxType t WITH(NOLOCK) ON custtax.TaxTypeId = t.TaxTypeId
					LEFT JOIN dbo.TaxRate tr WITH(NOLOCK) ON custtax.TaxRateId = tr.TaxRateId and t.Code ='SALES TAX'
				WHERE custtax.CustomerId = cust.[CustomerId] and custtax.IsActive = 1 and custtax.IsDeleted = 0 ),
		Othertax = (SELECT SUM(ISNULL(tr.TaxRate,0)) FROM dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)
					LEFT JOIN dbo.TaxType t WITH(NOLOCK) ON custtax.TaxTypeId = t.TaxTypeId
					LEFT JOIN dbo.TaxRate tr WITH(NOLOCK) ON custtax.TaxRateId = tr.TaxRateId 
				WHERE custtax.CustomerId = cust.[CustomerId] and custtax.IsActive = 1 and custtax.IsDeleted = 0 )
		--,Memo =
		--		(SELECT CAST('<x>' + 
		--			REPLACE(
		--				REPLACE(
		--					REPLACE(
		--						REPLACE(
		--							REPLACE(
		--								REPLACE(ctd.Memo, '&', '&amp;'),
		--							'<', '&lt;'),
		--						'>', '&gt;'),
		--					'"', '&quot;'),
		--				'''', '&apos;'),
		--			'</p><p>', ' ') + '</x>' AS XML).value('.', 'NVARCHAR(MAX)')
		--			FROM
		--				dbo.CommonWorkOrderTearDown ctd WITH(NOLOCK)
		--				LEFT JOIN dbo.CommonTeardownType ctt WITH(NOLOCK) ON ctd.CommonTeardownTypeId = ctt.CommonTeardownTypeId 
		--			WHERE ctd.WorkFlowWorkOrderId = wf.WorkFlowWorkOrderId AND UPPER(ctt.Code) = UPPER(@CorrectiveActionCode))

		,Memo = CASE WHEN ISNULL(wop.PublicationNotes, '') <> '' THEN
				(SELECT CAST('<x>' + 
					REPLACE(
						REPLACE(
							REPLACE(
								REPLACE(
									REPLACE(
										REPLACE(wop.PublicationNotes, '&', '&amp;'),
									'<', '&lt;'),
								'>', '&gt;'),
							'"', '&quot;'),
						'''', '&apos;'),
					'</p><p>', ' ') + '</x>' AS XML).value('.', 'NVARCHAR(MAX)'))
					ELSE 
					(SELECT CAST('<x>' + 
					REPLACE(
						REPLACE(
							REPLACE(
								REPLACE(
									REPLACE(
										REPLACE(ISNULL(tmp.Remarks, ''), '&', '&amp;'),
									'<', '&lt;'),
								'>', '&gt;'),
							'"', '&quot;'),
						'''', '&apos;'),
					'</p><p>', ' ') + '</x>' AS XML).value('.', 'NVARCHAR(MAX)'))
					END
		,ISNULL(woq.IsPrintCorrectiveAction, 0) AS IsPrintCorrectiveAction
		,ISNULL(FORMAT(wop.EstimatedShipDate, 'MM/dd/yyyy'), '') AS EstimatedShipDate
	FROM dbo.WorkOrder wo WITH(NOLOCK)        
		 INNER JOIN Dbo.WorkOrderWorkFlow wf WITH(NOLOCK) on wf.WorkOrderId = wo.WorkOrderId and wf.WorkOrderPartNoId=@workOrderPartNoId    
		 INNER JOIN dbo.WorkOrderQuote woq WITH(NOLOCK) ON wo.WorkOrderId = woq.WorkOrderId  
		 INNER JOIN dbo.WorkOrderQuoteDetails wqd WITH(NOLOCK) ON woq.WorkOrderQuoteId = wqd.WorkOrderQuoteId  
		 INNER JOIN dbo.WorkOrderPartNumber wop WITH(NOLOCK) ON wqd.WOPartNoId = wop.ID  
		 INNER JOIN dbo.ItemMaster im WITH(NOLOCK) ON wop.ItemMasterId = im.ItemMasterId  
		 LEFT JOIN dbo.ItemMaster im1 WITH(NOLOCK) ON im.RevisedPartId = im1.ItemMasterId  
		 INNER JOIN dbo.WorkScope s WITH(NOLOCK) ON wop.WorkOrderScopeId = s.WorkScopeId  
		 INNER JOIN dbo.StockLine sl WITH(NOLOCK) ON wop.StockLineId = sl.StockLineId  
		 INNER JOIN dbo.Customer cust WITH(NOLOCK)  ON woq.CustomerId = cust.CustomerId
		 LEFT JOIN #tmpResult tmp ON tmp.WorkOrderQuoteId = woq.WorkOrderQuoteId AND tmp.WorkOrderPartNoId = @workOrderPartNoId
	WHERE woq.WorkOrderQuoteId = @WorkOrderQuoteId AND wop.ID = @workOrderPartNoId  
		 AND woq.IsActive = 1 AND woq.IsDeleted = 0  
	GROUP BY im.PartNumber,  
		 im.PartDescription, im1.ItemMasterId, im1.PartNumber,wop.PublicationNotes,  tmp.Remarks,
		 sl.StockLineNumber, sl.SerialNumber, wop.Quantity, wqd.QuoteMethod, wqd.CommonFlatRate, TATDaysStandard,wqd.EvalFees, cust.CustomerId,wop.RevisedPartNumber, wop.RevisedPartDescription
		 ,wop.RevisedSerialNumber,wop.CurrentSerialNumber, wf.WorkFlowWorkOrderId,woq.IsPrintCorrectiveAction,wop.EstimatedShipDate),
	AfterTax AS (SELECT *, CAST(((Ct.subtotalfortax * Ct.TAXRates) / 100) AS DECIMAL(18, 2)) AS SalesTaxAmount, CAST(((Ct.subtotalfortax * Ct.Othertax) / 100) AS DECIMAL(18, 2)) AS OtherTaxAmount FROM WOQPartCte Ct)
	
	SELECT *, (ISNULL(FinalQuote.SalesTaxAmount, 0) + ISNULL(FinalQuote.OtherTaxAmount, 0) + ISNULL(FinalQuote.subtotalfortax, 0)) FinalTotal FROM AfterTax FinalQuote;

   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetWorkOrderQuotePrintPdfData'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderQuoteId, '') + ''  
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