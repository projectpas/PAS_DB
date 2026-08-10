/*************************************************************           
 ** File:   [usprpt_GetGoodsReceiptNotInvoicedReport]
 ** Author:   Devendra Shekh
 ** Description: Get Goods Receipt which are not Invoiced
 ** Date:    11-Feb-2025
 **************************************************************           
  ** Change History           
 **************************************************************           
  ** S NO   Date            Author				Change Description              
 ** --   --------         -------			--------------------------------            
    1    11-Feb-2025     Devendra Shekh				Created
    2    20-Feb-2025     Rajesh Gami				Modify as per requirement
	3    23-Feb-2025     Rajesh Gami				Resolved Getting records issue
	4    20-Mar-2026     Vishal Suthar				Fixed total mismatch issue by adding qtyRemaining > 0 condition in "WithTotal" cte
	5    01-May-2026     Rajesh Gami				Added NonStock and ASSET Inventory [PN-16267]
	6    04-May-2026     Rajesh Gami				Return PN and PN Desc for Asset and NonStock [PN-16267]
	7    27-Jul-2026     Bhargav					Convert reconciled qty (Stock UOM) back to Purchase UOM so partially-received PO rows are not hidden [PN-17360]
	8	 30/July/2026	Kishor Makwana				[PN-17492]  PERFORMANCE ONLY. No change to any returned row, column, value or column order.
**************************************************************/
CREATE        PROCEDURE [dbo].[usprpt_GetGoodsReceiptNotInvoicedReport]     
@PageNumber INT = 1,    
@PageSize INT = NULL,    
@mastercompanyid INT,    
@xmlFilter XML  
AS    
BEGIN    
	SET NOCOUNT ON;    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	BEGIN TRY
    	 DECLARE @postedStatusId INT = (select ID FROM BatchStatus WHERE [Name] = 'Posted')
		DECLARE @Fromdate DATETIME2,    
				@Todate  DATETIME2,    
				@level1 VARCHAR(MAX) = NULL,    
				@level2 VARCHAR(MAX) = NULL,    
				@level3 VARCHAR(MAX) = NULL,    
				@level4 VARCHAR(MAX) = NULL,    
				@Level5 VARCHAR(MAX) = NULL,    
				@Level6 VARCHAR(MAX) = NULL,    
				@Level7 VARCHAR(MAX) = NULL,    
				@Level8 VARCHAR(MAX) = NULL,    
				@Level9 VARCHAR(MAX) = NULL,    
				@Level10 VARCHAR(MAX) = NULL, 
				@UserEmployeeId BIGINT = 0;
	
		SELECT @Fromdate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Received Date'     
		THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Fromdate END,    
    
		@Todate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Received Date'     
		THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Todate END,    
    
		@level1=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level1'     
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level1 END,    
    
		@level2=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level2'     
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level2 END,    
    
		@level3=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level3'     
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level3 END,    
    
		@level4=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level4'     
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level4 END,    
    
		@level5=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level5'     
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level5 END,    
    
		@level6=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level6'     
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level6 END,    
    
		@level7=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level7'     
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level7 END,    
    
		@level8=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level8'     
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level8 END,    
    
		@level9=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level9'     
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level9 END,    
    
		@level10=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level10'     
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10 end, 
		
		@UserEmployeeId=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='EmployeeId'     
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @UserEmployeeId end 
    
		FROM @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)     
  
		DECLARE @POModuleID INT = 4; 
		DECLARE @ROModuleID INT = 25;
		SELECT @POModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'POHeader';
		SELECT @ROModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'ROHeader';

		/* --------------START: Get the timzone and UTC offset -------------- */
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '', @BaseUtcOffsetSec BIGINT = 0;
		SELECT 	@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description] )
		FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @UserEmployeeId;		
				
		SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec FROM dbo.TimeZone WITH(NOLOCK) WHERE [Description] = @CurrntEmpTimeZoneDesc
		/* -------------- END: Get the timzone and UTC offset -------------- */
  
		SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END    
		SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END
        DECLARE @FromDateOnly DATE = CONVERT(DATE,@Fromdate);
        DECLARE @ToDateExclusive DATETIME2 = DATEADD(DAY,1,CONVERT(DATE,@Todate));

        IF OBJECT_ID(N'tempdb..#LevelFilter') IS NOT NULL DROP TABLE #LevelFilter;
        CREATE TABLE #LevelFilter(LevelNo TINYINT NOT NULL, Item BIGINT NOT NULL,
            PRIMARY KEY CLUSTERED(LevelNo,Item));
        IF ISNULL(@level1,'')<>'' INSERT #LevelFilter SELECT 1,CONVERT(BIGINT,Item) FROM dbo.SPLITSTRING(@level1,',');
        IF ISNULL(@level2,'')<>'' INSERT #LevelFilter SELECT 2,CONVERT(BIGINT,Item) FROM dbo.SPLITSTRING(@level2,',');
        IF ISNULL(@level3,'')<>'' INSERT #LevelFilter SELECT 3,CONVERT(BIGINT,Item) FROM dbo.SPLITSTRING(@level3,',');
        IF ISNULL(@level4,'')<>'' INSERT #LevelFilter SELECT 4,CONVERT(BIGINT,Item) FROM dbo.SPLITSTRING(@level4,',');
        IF ISNULL(@level5,'')<>'' INSERT #LevelFilter SELECT 5,CONVERT(BIGINT,Item) FROM dbo.SPLITSTRING(@level5,',');
        IF ISNULL(@level6,'')<>'' INSERT #LevelFilter SELECT 6,CONVERT(BIGINT,Item) FROM dbo.SPLITSTRING(@level6,',');
        IF ISNULL(@level7,'')<>'' INSERT #LevelFilter SELECT 7,CONVERT(BIGINT,Item) FROM dbo.SPLITSTRING(@level7,',');
        IF ISNULL(@level8,'')<>'' INSERT #LevelFilter SELECT 8,CONVERT(BIGINT,Item) FROM dbo.SPLITSTRING(@level8,',');
        IF ISNULL(@level9,'')<>'' INSERT #LevelFilter SELECT 9,CONVERT(BIGINT,Item) FROM dbo.SPLITSTRING(@level9,',');
        IF ISNULL(@level10,'')<>'' INSERT #LevelFilter SELECT 10,CONVERT(BIGINT,Item) FROM dbo.SPLITSTRING(@level10,',');


		;WITH rptCTE ([vendor],[vendorCode],[poRoNum],[poStatus],
		[pn],[pnDescription],[stockType],
		--[cond],
			[qtyOrdered],[qtyReceived],[qtyReconciled],[qtyRemaining],[receivingReconNum],
			[unitCost],
			[extCost],[baseCurrency],[receivedBy],
			[level1], [level2], [level3], [level4], [level5], [level6], [level7], [level8], [level9], [level10], [masterCompanyId],CreatedDate,Id,IsPO,PartID,ReceivingReconciliationDetailId) 
		AS (
			SELECT
			PO.VendorName AS 'vendor',
			PO.VendorCode AS 'vendorCode',
			PO.PurchaseOrderNumber AS 'poRoNum',
			PO.[Status] AS 'poStatus',
			COALESCE(STK.PartNumber, NSTK.PartNumber, AI.[Name]) AS 'pn',
			COALESCE(STK.PNDescription, NSTK.PartDescription, AI.[Description]) AS 'pnDescription',
			POP.StockType AS 'stockType',
			--STK.Condition AS 'cond',
			ISNULL(POP.QuantityOrdered,0) AS 'qtyOrdered',
			ISNULL(POP.QuantityReceived,0) AS 'qtyReceived',
			ISNULL(CASE WHEN NULLIF(IM.StockUnitOfMeasure,'') IS NOT NULL AND NULLIF(IM.PurchaseUnitOfMeasure,'') IS NOT NULL AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure
						THEN dbo.fn_ConvertUOM(RRCD.InvoicedQty, IM.StockUnitOfMeasure, IM.PurchaseUnitOfMeasure, 0, PO.MasterCompanyId)
						ELSE RRCD.InvoicedQty END, 0) AS 'qtyReconciled',
			 0 AS 'qtyRemaining',
			RRCH.ReceivingReconciliationNumber AS 'receivingReconNum',
			ISNULL(POP.UnitCost,0) AS 'unitCost',
			ISNULL(ISNULL(POP.UnitCost,0),0) AS 'extCost',
			POP.FunctionalCurrency AS 'baseCurrency',
			COALESCE(STK.CreatedBy, NSTK.CreatedBy, AI.CreatedBy)  AS 'receivedBy',
			UPPER(MSL1.Code)  AS 'level1',      
			UPPER(MSL2.Code)  AS 'level2',     
			UPPER(MSL3.Code)  AS 'level3',     
			UPPER(MSL4.Code)  AS 'level4',     
			UPPER(MSL5.Code)  AS 'level5',     
			UPPER(MSL6.Code)  AS 'level6',     
			UPPER(MSL7.Code)  AS 'level7',     
			UPPER(MSL8.Code)  AS 'level8',     
			UPPER(MSL9.Code)  AS 'level9',     
			UPPER(MSL10.Code) AS 'level10',  
			PO.MasterCompanyId,
			COALESCE(STK.[CreatedDate], NSTK.[CreatedDate], AI.[CreatedDate])AS  CreatedDate,
			PO.PurchaseOrderId as Id,
			1 as IsPO,
			POP.PurchaseOrderPartRecordId PartID
			,RRCD.ReceivingReconciliationDetailId
		FROM [dbo].[PurchaseOrder] PO WITH(NOLOCK)
		INNER JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId
		LEFT JOIN DBO.Stockline STK WITH(NOLOCK) ON POP.PurchaseOrderPartRecordId = STK.PurchaseOrderPartRecordId
		LEFT JOIN DBO.NonStockInventory NSTK WITH(NOLOCK) ON POP.PurchaseOrderPartRecordId = NSTK.PurchaseOrderPartRecordId
		LEFT JOIN DBO.AssetInventory AI WITH(NOLOCK) ON POP.PurchaseOrderPartRecordId = AI.PurchaseOrderPartRecordId
		LEFT JOIN DBO.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = POP.ItemMasterId 
		--INNER JOIN DBO.StocklineDraft STD WITH(NOLOCK) ON STK.StockLineId = STD.StockLineId AND POP.PurchaseOrderPartRecordId = STD.RepairOrderPartRecordId
		INNER JOIN [dbo].[PurchaseOrderManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.[ModuleID] = @POModuleID AND MSD.[ReferenceID] = PO.PurchaseOrderId  
		LEFT JOIN [dbo].[ReceivingReconciliationHeader] RRCH WITH(NOLOCK) ON PO.VendorId = RRCH.VendorId AND RRCH.StatusId =  @postedStatusId
		LEFT JOIN [dbo].[ReceivingReconciliationDetails] RRCD WITH(NOLOCK) ON RRCH.ReceivingReconciliationId = RRCD.ReceivingReconciliationId AND RRCD.PurchaseOrderId = POP.PurchaseOrderId AND RRCD.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId AND RRCD.[Type] = 1 --AND ((ISNULL(POP.QuantityReceived,0) - ISNULL(RRCD.InvoicedQty,0)) > 0 )
		LEFT JOIN [dbo].ManagementStructureLevel MSL1 WITH(NOLOCK)   ON MSD.[Level1Id] = MSL1.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL2 WITH(NOLOCK)  ON MSD.[Level2Id] = MSL2.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL3 WITH(NOLOCK)  ON MSD.[Level3Id] = MSL3.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL4 WITH(NOLOCK)  ON MSD.[Level4Id] = MSL4.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL5 WITH(NOLOCK)  ON MSD.[Level5Id] = MSL5.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL6 WITH(NOLOCK)  ON MSD.[Level6Id] = MSL6.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL7 WITH(NOLOCK)  ON MSD.[Level7Id] = MSL7.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL8 WITH(NOLOCK)  ON MSD.[Level8Id] = MSL8.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL9 WITH(NOLOCK)  ON MSD.[Level9Id] = MSL9.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL10 WITH(NOLOCK) ON MSD.[Level10Id] = MSL10.ID
		WHERE PO.[MasterCompanyId] = @mastercompanyid 
			AND PO.[IsDeleted] = 0 
			--AND ISNULL(POP.QuantityReceived,0) > 0
			--AND (RRCH.ReceivingReconciliationId IS NULL OR (ISNULL(POP.QuantityReceived,0) - ISNULL(RRCD.InvoicedQty,0)) > 0 )
			AND ( (STK.CreatedDate >= @FromDateOnly AND STK.CreatedDate < @ToDateExclusive)
 OR (NSTK.CreatedDate >= @FromDateOnly AND NSTK.CreatedDate < @ToDateExclusive)
 OR (AI.CreatedDate >= @FromDateOnly AND AI.CreatedDate < @ToDateExclusive) )  
			AND (ISNULL(@level1,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=1 AND LF.Item=MSD.[Level1Id]))    
			AND (ISNULL(@level2,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=2 AND LF.Item=MSD.[Level2Id]))    
			AND (ISNULL(@level3,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=3 AND LF.Item=MSD.[Level3Id]))    
			AND (ISNULL(@level4,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=4 AND LF.Item=MSD.[Level4Id]))    
			AND (ISNULL(@level5,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=5 AND LF.Item=MSD.[Level5Id]))    
			AND (ISNULL(@level6,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=6 AND LF.Item=MSD.[Level6Id]))    
			AND (ISNULL(@level7,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=7 AND LF.Item=MSD.[Level7Id]))    
			AND (ISNULL(@level8,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=8 AND LF.Item=MSD.[Level8Id]))    
			AND (ISNULL(@level9,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=9 AND LF.Item=MSD.[Level9Id]))    
			AND (ISNULL(@level10,'') ='' OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=10 AND LF.Item=MSD.[Level10Id]))

			UNION

			SELECT
			RO.VendorName AS 'vendor',
			RO.VendorCode AS 'vendorCode',
			RO.RepairOrderNumber AS 'poRoNum',
			RO.[Status] AS 'poStatus',
		    COALESCE(STK.PartNumber,AI.[Name])  AS 'pn',
			COALESCE(STK.PNDescription,AI.[Description]) AS 'pnDescription',
			ROP.StockType AS 'stockType',
			--STK.Condition AS 'cond',
			ISNULL(ROP.QuantityOrdered,0) AS 'qtyOrdered',
			ISNULL(ROP.QuantityReceived,0) AS 'qtyReceived',
			ISNULL(RRCD.InvoicedQty,0) AS 'qtyReconciled',
			 0 AS 'qtyRemaining',
			RRCH.ReceivingReconciliationNumber AS 'receivingReconNum',
			(COALESCE(ISNULL(STK.RepairOrderUnitCost,0),ISNULL(AI.UnitCost,0))  * ISNULL(ROP.QuantityReceived,0))  AS 'unitCost',
			ISNULL(ROP.UnitCost,0) AS 'extCost',
			--0 AS 'extCost',
			ROP.FunctionalCurrency AS 'baseCurrency',
			COALESCE(STK.CreatedBy,AI.CreatedBy)AS 'receivedBy',
			UPPER(MSL1.Code)  AS 'level1',      
			UPPER(MSL2.Code)  AS 'level2',     
			UPPER(MSL3.Code)  AS 'level3',     
			UPPER(MSL4.Code)  AS 'level4',     
			UPPER(MSL5.Code)  AS 'level5',     
			UPPER(MSL6.Code)  AS 'level6',     
			UPPER(MSL7.Code)  AS 'level7',     
			UPPER(MSL8.Code)  AS 'level8',     
			UPPER(MSL9.Code)  AS 'level9',     
			UPPER(MSL10.Code) AS 'level10',  
			RO.MasterCompanyId,
			COALESCE(STK.CreatedDate,AI.CreatedDate)CreatedDate,
			RO.RepairOrderId as Id,
			0 as IsPO,
			ROP.RepairOrderPartRecordId PartID
			,RRCD.ReceivingReconciliationDetailId
		FROM [dbo].[RepairOrder] RO WITH(NOLOCK)
		INNER JOIN [dbo].[RepairOrderPart] ROP WITH(NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
		LEFT JOIN DBO.Stockline STK WITH(NOLOCK) ON ROP.RepairOrderPartRecordId = STK.RepairOrderPartRecordId
		LEFT JOIN DBO.AssetInventory AI WITH(NOLOCK) ON ROP.RepairOrderPartRecordId = AI.RepairOrderPartRecordId

		INNER JOIN [dbo].[RepairOrderManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.[ModuleID] = @ROModuleID AND MSD.[ReferenceID] = RO.RepairOrderId 
		LEFT JOIN [dbo].[ReceivingReconciliationHeader] RRCH WITH(NOLOCK) ON RO.VendorId = RRCH.VendorId AND RRCH.StatusId =  @postedStatusId
		LEFT JOIN [dbo].[ReceivingReconciliationDetails] RRCD WITH(NOLOCK) ON RRCH.ReceivingReconciliationId = RRCD.ReceivingReconciliationId AND  RRCD.PurchaseOrderId = ROP.RepairOrderId AND RRCD.PurchaseOrderPartRecordId = ROP.RepairOrderPartRecordId AND RRCD.[Type] = 2 --AND ((ISNULL(ROP.QuantityReceived,0) - ISNULL(RRCD.InvoicedQty,0)) > 0 )

		LEFT JOIN [dbo].ManagementStructureLevel MSL1 WITH(NOLOCK)   ON MSD.[Level1Id] = MSL1.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL2 WITH(NOLOCK)  ON MSD.[Level2Id] = MSL2.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL3 WITH(NOLOCK)  ON MSD.[Level3Id] = MSL3.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL4 WITH(NOLOCK)  ON MSD.[Level4Id] = MSL4.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL5 WITH(NOLOCK)  ON MSD.[Level5Id] = MSL5.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL6 WITH(NOLOCK)  ON MSD.[Level6Id] = MSL6.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL7 WITH(NOLOCK)  ON MSD.[Level7Id] = MSL7.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL8 WITH(NOLOCK)  ON MSD.[Level8Id] = MSL8.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL9 WITH(NOLOCK)  ON MSD.[Level9Id] = MSL9.ID
		LEFT JOIN [dbo].ManagementStructureLevel MSL10 WITH(NOLOCK) ON MSD.[Level10Id] = MSL10.ID
		WHERE RO.[MasterCompanyId] = @mastercompanyid 
			AND RO.[IsDeleted] = 0 
			--AND ISNULL(ROP.QuantityReceived,0) > 0
			--AND (RRCH.ReceivingReconciliationId IS NULL OR (ISNULL(ROP.QuantityReceived,0) - ISNULL(RRCD.InvoicedQty,0)) > 0 )
			AND ( (STK.CreatedDate >= @FromDateOnly AND STK.CreatedDate < @ToDateExclusive)
 OR (AI.CreatedDate >= @FromDateOnly AND AI.CreatedDate < @ToDateExclusive) )  
			AND (ISNULL(@level1,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=1 AND LF.Item=MSD.[Level1Id]))    
			AND (ISNULL(@level2,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=2 AND LF.Item=MSD.[Level2Id]))    
			AND (ISNULL(@level3,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=3 AND LF.Item=MSD.[Level3Id]))    
			AND (ISNULL(@level4,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=4 AND LF.Item=MSD.[Level4Id]))    
			AND (ISNULL(@level5,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=5 AND LF.Item=MSD.[Level5Id]))    
			AND (ISNULL(@level6,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=6 AND LF.Item=MSD.[Level6Id]))    
			AND (ISNULL(@level7,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=7 AND LF.Item=MSD.[Level7Id]))    
			AND (ISNULL(@level8,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=8 AND LF.Item=MSD.[Level8Id]))    
			AND (ISNULL(@level9,'') =''  OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=9 AND LF.Item=MSD.[Level9Id]))    
			AND (ISNULL(@level10,'') ='' OR EXISTS (SELECT 1 FROM #LevelFilter LF WHERE LF.LevelNo=10 AND LF.Item=MSD.[Level10Id]))
		)
		,GroupData AS
				(
					SELECT
						vendor, vendorCode, poRoNum, poStatus,
						pn, pnDescription, stockType, 
						--cond,
						Id, IsPO, PartID,

						MAX(qtyOrdered)     AS qtyOrdered,
						MAX(qtyReceived)    AS qtyReceived,
						qtyReconciled  AS qtyReconciled,
						SUM(qtyRemaining)   AS qtyRemaining,

						MAX(unitCost)       AS unitCost,
						SUM(extCost)        AS extCost,

						MAX(baseCurrency)   AS baseCurrency,
						MAX(receivedBy)     AS receivedBy,

						MAX(level1) level1, MAX(level2) level2, MAX(level3) level3,
						MAX(level4) level4, MAX(level5) level5, MAX(level6) level6,
						MAX(level7) level7, MAX(level8) level8, MAX(level9) level9,
						MAX(level10) level10,

						 MAX(masterCompanyId)masterCompanyId,
						 MAX(CreatedDate)CreatedDate,
						 CASE 
							WHEN COUNT(DISTINCT receivingReconNum) > 1 
								THEN 'MULTIPLE'
							ELSE MAX(receivingReconNum)
						END AS receivingReconNum
					FROM rptCTE
					GROUP BY
						vendor, vendorCode, poRoNum, poStatus,
						pn, pnDescription, stockType, 
						--cond,
						Id, IsPO, PartID,qtyReconciled,ReceivingReconciliationDetailId
				)
		,PartLevel AS
				(
					SELECT
						vendor, vendorCode, poRoNum, poStatus,
						pn, pnDescription, stockType, 
						--cond,
						Id, IsPO, PartID,

						MAX(qtyOrdered)     AS qtyOrdered,
						MAX(qtyReceived)    AS qtyReceived,
						SUM(qtyReconciled)  AS qtyReconciled,
						SUM(qtyRemaining)   AS qtyRemaining,

						MAX(unitCost)       AS unitCost,
						SUM(extCost)        AS extCost,

						MAX(baseCurrency)   AS baseCurrency,
						MAX(receivedBy)     AS receivedBy,

						MAX(level1) level1, MAX(level2) level2, MAX(level3) level3,
						MAX(level4) level4, MAX(level5) level5, MAX(level6) level6,
						MAX(level7) level7, MAX(level8) level8, MAX(level9) level9,
						MAX(level10) level10,

						 MAX(masterCompanyId)masterCompanyId,
						 MAX(CreatedDate)CreatedDate,
						 CASE 
							WHEN COUNT(DISTINCT receivingReconNum) > 1 
								THEN 'MULTIPLE'
							ELSE MAX(receivingReconNum)
						END AS receivingReconNum
					FROM GroupData
					GROUP BY
						vendor, vendorCode, poRoNum, poStatus,
						pn, pnDescription, stockType, 
						--cond,
						Id, IsPO, PartID
				),

				OrderLevel AS
				(
					SELECT
						vendor, vendorCode, poRoNum, poStatus,
						pn, pnDescription, stockType, 
						--cond,

						SUM(qtyOrdered)     AS qtyOrdered,
						SUM(qtyReceived)    AS qtyReceived,
						SUM(qtyReconciled)  AS qtyReconciled,
						(SUM(ISNULL(qtyReceived,0)) - SUM(ISNULL(qtyReconciled,0)))    AS qtyRemaining,
						--MAX(UNITCost) as UNITCost,
						(CASE WHEN MAX(isPO) =  1 THEN ((SUM(ISNULL(qtyReceived,0)) - SUM(ISNULL(qtyReconciled,0))) * MAX(UNITCost)) ELSE  SUM(UNITCost) END)AS   extCost,
						MAX(baseCurrency)   AS baseCurrency,
						MAX(receivedBy)     AS receivedBy,

						MAX(level1) level1, MAX(level2) level2, MAX(level3) level3,
						MAX(level4) level4, MAX(level5) level5, MAX(level6) level6,
						MAX(level7) level7, MAX(level8) level8, MAX(level9) level9,
						MAX(level10) level10,

						MAX(masterCompanyId) masterCompanyId,
						MAX(CreatedDate) CreatedDate,
						MAX(Id) Id,
						MAX(IsPO) IsPO,
						--MAX(UPPER(receivingReconNum)) receivingReconNum
						CASE 
							WHEN COUNT(DISTINCT receivingReconNum) > 1 
								THEN 'MULTIPLE'
							ELSE MAX(receivingReconNum)
						END AS receivingReconNum
					FROM PartLevel
					GROUP BY
						vendor, vendorCode, poRoNum, poStatus,
						pn, pnDescription, stockType
						--, cond
				),
				WithTotal ([masterCompanyId], [TotalExtCost]) 
						AS (SELECT [masterCompanyId], 				
						FORMAT(SUM([extCost]), 'N', 'en-us') [TotalExtCost]				
						FROM OrderLevel 
						WHERE qtyRemaining > 0
						GROUP BY [masterCompanyId])
				SELECT
					COUNT(*) OVER() totalRecordsCount,
					FC.*
					,WC.TotalExtCost
				FROM OrderLevel FC
				INNER JOIN WithTotal WC ON FC.masterCompanyId = WC.masterCompanyId
				WHERE qtyRemaining > 0
				ORDER BY CreatedDate DESC
		OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY
        OPTION (RECOMPILE); 
    
	END TRY
	BEGIN CATCH    
	DECLARE @ErrorLogID int,    
            @DatabaseName varchar(100) = DB_NAME()    
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            ,    
            @AdhocComments varchar(150) = '[usprpt_GetGoodsReceiptNotInvoicedReport]',    
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100)) +      
            '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) +      
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS VARCHAR(100)) +      
            '@Parameter4 = ''' + CAST(ISNULL(@xmlFilter, '') AS VARCHAR(MAX)),    
            @ApplicationName VARCHAR(100) = 'PAS'     
    
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
    EXEC Splogexception @DatabaseName = @DatabaseName,    
                        @AdhocComments = @AdhocComments,    
                        @ProcedureParameters = @ProcedureParameters,    
                        @ApplicationName = @ApplicationName,    
                        @ErrorLogID = @ErrorLogID OUTPUT;    
    
	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
	RETURN (1);    
	END CATCH
END