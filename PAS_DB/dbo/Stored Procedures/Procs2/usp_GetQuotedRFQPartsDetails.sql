/*************************************************************             
 ** File:   [usp_GetQuotedRFQPartsDetails]             
 ** Author:   Devendra Shekh    
 ** Description: Get Data of quoted RFQ for Speed Quote
 ** Date:   31-July-2025 
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO	Date			Author				Change Description              
 ** --		--------		-------				--------------------------------            
 **	1		31-July-2025	Devendra Shekh		Created
 
EXECUTE [dbo].[usp_GetQuotedRFQPartsDetails] 9, 95633, 1   
	1    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
**************************************************************/  
CREATE   PROCEDURE [dbo].[usp_GetQuotedRFQPartsDetails]
@CustomerRfqId BIGINT = NULL,
@ItemMasterId BIGINT = NULL,
@MasterCompanyId INT = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
	BEGIN TRY
		BEGIN

		DECLARE @OHCondition INT=NULL, @REPCondition INT=NULL,@BCCondition INT =NULL;
		DECLARE @BENCH INT = 1, @OVERHAUL INT = 2, @REPAIR INT = 3, @EXCHANGEUNITAVAILABLE INT = 4, @OUTRIGHTUNITAVAILABLE INT = 5;

		IF(@MasterCompanyId = 11)
		BEGIN
			SELECT @OHCondition = ConditionId FROM DBO.Condition WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND Code = 'OVERHAULED';
			SELECT @REPCondition = ConditionId FROM DBO.Condition WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND Code = 'REPAIRED';
			SELECT @BCCondition = ConditionId FROM DBO.Condition WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND Code = 'BC';	
		END
		ELSE
		BEGIN
			SELECT @OHCondition = ConditionId FROM DBO.Condition WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND Code = 'OVERHAUL';
			SELECT @REPCondition = ConditionId FROM DBO.Condition WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND Code = 'REPAIR';
			SELECT @BCCondition = ConditionId FROM DBO.Condition WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND Code = 'BC';	
		END

		IF OBJECT_ID('tempdb..#tmpQuotedRFQResult') IS NOT NULL
			DROP TABLE #tmpQuotedRFQResult

		CREATE TABLE #tmpQuotedRFQResult
		(
			[RecordId] BIGINT IDENTITY(1,1),
			PartNumber VARCHAR(50) NULL,
			PartId BIGINT NULL,
			ItemMasterId BIGINT NULL,
			Description NVARCHAR(MAX) NULL,
			UnitOfMeasureId BIGINT NULL,
			UnitOfMeasure VARCHAR(250) NULL,
			QtyAvailable INT NULL,
			QtyOnHand INT NULL,
			ItemGroup VARCHAR(256) NULL,
			Manufacturer VARCHAR(100) NULL,
			ManufacturerId BIGINT NULL,
			ItemClassificationCode VARCHAR(30) NULL,
			ItemClassification VARCHAR(100) NULL,
			ItemClassificationId BIGINT NULL,
			ConditionId BIGINT NULL,
			ConditionDescription VARCHAR(256) NULL,
			Code VARCHAR(100) NULL,
			AlternateFor NVARCHAR(MAX) NULL,
			Oempmader VARCHAR(100) NULL,
			OemPN VARCHAR(100) NULL,
			IsPma BIT NULL,
			UnitCost DECIMAL(18, 2) NULL,
			UnitSalePrice DECIMAL(18, 2) NULL,
			TAT NUMERIC(18, 2) NULL,
		)

		INSERT INTO #tmpQuotedRFQResult ([PartNumber], [PartId], [ItemMasterId], [Description], [unitOfMeasureId], [unitOfMeasure], [QtyAvailable], [QtyOnHand], [ItemGroup], [Manufacturer], [ManufacturerId],
					[ItemClassificationCode], [ItemClassification], [ItemClassificationId], [ConditionId], [ConditionDescription], [Code], [AlternateFor], [Oempmader], [OemPN], [IsPma],
					[UnitCost], [UnitSalePrice], [TAT])
		SELECT	im.PartNumber
				,im.ItemMasterId As PartId
				,im.ItemMasterId As ItemMasterId
				,im.PartDescription AS Description
				,im.PurchaseUnitOfMeasureId  AS unitOfMeasureId
				,im.PurchaseUnitOfMeasure AS unitOfMeasure
				,SUM(ISNULL(sl.QuantityAvailable, 0)) AS QtyAvailable
				,SUM(ISNULL(sl.QuantityOnHand, 0)) AS QtyOnHand
				,ig.Description AS ItemGroup
				,mf.Name Manufacturer
				,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
				,ic.ItemClassificationCode
				,ic.Description AS ItemClassification
				,ic.ItemClassificationId
				,c.ConditionId ConditionId
				,c.Description ConditionDescription
				,c.Code
				,ISNULL(STUFF((
				SELECT DISTINCT ', '+ I.partnumber FROM DBO.Nha_Tla_Alt_Equ_ItemMapping M WITH (NOLOCK) INNER JOIN ItemMaster I WITH (NOLOCK) ON I.ItemMasterId = M.ItemMasterId Where M.MappingItemMasterId = im.ItemMasterId AND M.MappingType = 1
				FOR XML PATH('')
				 AND ISNULL(I.IsNonStock,0) = 0 )
				,1,1,''), '') AlternateFor
				,CASE 
					WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER' --'PMA&DER'
					WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA' --'PMA'
					WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
					ELSE 'OEM'
					END AS Oempmader
				,CASE 
					WHEN im.IsPma = 1 and im.IsDER = 1 THEN OEMPMA.partnumber 
					WHEN im.IsPma = 1 and im.IsDER = 0 THEN OEMPMA.partnumber 
					ELSE ''
					END AS OemPN
				,im.IsPma
				,ISNULL(imps.PP_UnitPurchasePrice,0) AS UnitCost
				,ISNULL(imps.SP_CalSPByPP_UnitSalePrice,0) AS UnitSalePrice
				,CASE WHEN c.ConditionId = @BCCondition THEN im.turnTimeBenchTest
				WHEN c.ConditionId = @OHCondition THEN im.TurnTimeOverhaulHours
				WHEN c.ConditionId = @REPCondition THEN im.TurnTimeRepairHours
				ELSE 0 END AS TAT
			FROM DBO.ItemMaster im WITH (NOLOCK)
			LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId IN (SELECT ConditionId FROM DBO.Condition WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId)
			LEFT JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.ConditionId = c.ConditionId AND sl.IsDeleted = 0  AND sl.isActive = 1
			LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
			LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
			LEFT JOIN DBO.ItemClassification ic WITH (NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
			LEFT JOIN (SELECT partnumber, ItemMasterId FROM DBO.ItemMaster WITH (NOLOCK)) OEMPMA ON OEMPMA.ItemMasterId = im.IsOemPNId
			LEFT JOIN DBO.ItemMasterPurchaseSale imps WITH (NOLOCK) on imps.ItemMasterId = im.ItemMasterId AND imps.ConditionId = c.ConditionId
			WHERE	im.ItemMasterId = @ItemMasterId
					AND c.ConditionId IN (@OHCondition, @REPCondition, @BCCondition)
			 AND ISNULL(im.IsNonStock,0) = 0 GROUP BY	im.PartNumber, im.PurchaseUnitOfMeasureId, im.PurchaseUnitOfMeasure, im.ItemMasterId, im.PartDescription, ig.Description, mf.Name, im.ManufacturerId
						,ic.ItemClassificationCode, ic.Description, ic.ItemClassificationId, c.Description, c.ConditionId, im.IsPma, im.IsDER, OEMPMA.partnumber, sl.ItemMasterId
						,imps.PP_UnitPurchasePrice, imps.SP_CalSPByPP_UnitSalePrice, im.TurnTimeOverhaulHours, im.TurnTimeRepairHours, im.turnTimeBenchTest, c.Code
			ORDER	BY CASE WHEN c.ConditionId = @OHCondition THEN 1
						    WHEN c.ConditionId = @REPCondition THEN 2
						    WHEN c.ConditionId = @BCCondition THEN 3
						    ELSE NULL END 
			
			IF(ISNULL(@CustomerRfqId, 0) > 0)
			BEGIN
				-- OverHaul Condition Data Update
				UPDATE TMP
				SET	
					TMP.UnitSalePrice= ISNULL(CRQD.QuotePrice, 0),
					TMP.UnitCost= ISNULL(CRQD.QuotePrice, 0),
					TMP.TAT = ISNULL(CRQD.QuoteTat, 0)
				FROM #tmpQuotedRFQResult TMP
				LEFT JOIN [dbo].[CustomerRfqQuote] CRQ WITH(NOLOCK) ON CRQ.MasterCompanyId = @MasterCompanyId AND CRQ.CustomerRfqId = @CustomerRfqId
				LEFT JOIN [dbo].[CustomerRfqQuoteDetails] CRQD WITH(NOLOCK) ON CRQD.CustomerRfqQuoteId = CRQ.CustomerRfqQuoteId AND CRQD.ServiceType = @OVERHAUL 
				WHERE TMP.ConditionId = @OHCondition

				-- Repair Condition Data Update
				UPDATE TMP
				SET	
					TMP.UnitSalePrice= ISNULL(CRQD.QuotePrice, 0),
					TMP.UnitCost= ISNULL(CRQD.QuotePrice, 0),
					TMP.TAT = ISNULL(CRQD.QuoteTat, 0)
				FROM #tmpQuotedRFQResult TMP
				LEFT JOIN [dbo].[CustomerRfqQuote] CRQ WITH(NOLOCK) ON CRQ.MasterCompanyId = @MasterCompanyId AND CRQ.CustomerRfqId = @CustomerRfqId
				LEFT JOIN [dbo].[CustomerRfqQuoteDetails] CRQD WITH(NOLOCK) ON CRQD.CustomerRfqQuoteId = CRQ.CustomerRfqQuoteId AND CRQD.ServiceType = @REPAIR 
				WHERE TMP.ConditionId = @REPCondition

				-- BC Condition Data Update
				UPDATE TMP
				SET	
					TMP.UnitSalePrice= ISNULL(CRQD.QuotePrice, 0),
					TMP.UnitCost= ISNULL(CRQD.QuotePrice, 0),
					TMP.TAT = ISNULL(CRQD.QuoteTat, 0)
				FROM #tmpQuotedRFQResult TMP
				LEFT JOIN [dbo].[CustomerRfqQuote] CRQ WITH(NOLOCK) ON CRQ.MasterCompanyId = @MasterCompanyId AND CRQ.CustomerRfqId = @CustomerRfqId
				LEFT JOIN [dbo].[CustomerRfqQuoteDetails] CRQD WITH(NOLOCK) ON CRQD.CustomerRfqQuoteId = CRQ.CustomerRfqQuoteId AND CRQD.ServiceType = @BENCH 
				WHERE TMP.ConditionId = @BCCondition
			END

			SELECT	[PartNumber], [PartId], [ItemMasterId], [Description], [unitOfMeasureId], [unitOfMeasure], [QtyAvailable], [QtyOnHand], [ItemGroup], [Manufacturer], [ManufacturerId],
					[ItemClassificationCode], [ItemClassification], [ItemClassificationId], [ConditionId], [ConditionDescription], [Code], [AlternateFor], [Oempmader], [OemPN], [IsPma],
					[UnitCost], [UnitSalePrice], [TAT]
			FROM #tmpQuotedRFQResult;
			
			END
		END TRY    
		BEGIN CATCH      
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'usp_GetQuotedRFQPartsDetails' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CustomerRfqId, '')+''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END