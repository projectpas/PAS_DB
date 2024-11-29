  
/*************************************************************
 ** File:   [usprpt_GetWorkOrderAwaitingPartsReport]
 ** Author:   Abhishek Jirawla 
 ** Description: Get Data for WorkOrder Awaiting Parts report
 ** Purpose:   
 ** Date:   22-10-2024  

 ** PARAMETERS:
   
 ** RETURN VALUE:
 
 **************************************************************
  ** Change History
 **************************************************************
 ** S NO   DateAuthor   Change Description 
 ** --   ---------------  --------------------------------
	1	22-10-2024		Abhishek Jirawla	CREATED  
**************************************************************/
CREATE   PROCEDURE [dbo].[usprpt_GetWorkOrderAwaitingPartsReport]
 @PageNumber INT = 1,
 @PageSize INT = NULL,
 @mastercompanyid INT,
 @xmlFilter XML
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
BEGIN TRANSACTION   
	DECLARE
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
	@IsDownload BIT = NULL,
	@ReplaceProvisionId BIGINT = 0,
	@POOpenStatus INT = 0,
	@POPendingStatus INT = 0,
	@POFulFillingStatus INT = 0

	DECLARE @Stage varchar(100) = NULL  
	DECLARE @CustomerId varchar(30) = NULL 

	DECLARE @ApprovedQuoteStatusId INT = 0
	SELECT @ApprovedQuoteStatusId = WorkOrderQuoteStatusId FROM DBO.WorkOrderQuoteStatus  WITH (NOLOCK) WHERE Description = 'Approved';

	SELECT @POOpenStatus = POStatusId FROM DBO.POStatus WITH (NOLOCK) WHERE Description = 'Open';

	SELECT @POPendingStatus = POStatusId FROM DBO.POStatus WITH (NOLOCK) WHERE Description = 'Pending';

	SELECT @POFulFillingStatus = POStatusId FROM DBO.POStatus WITH (NOLOCK) WHERE Description = 'Fulfilling';

	DECLARE @ModuleID INT = 12; -- MS Module ID
	SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END

	SELECT @ReplaceProvisionId = ProvisionId FROM DBO.Provision WITH (NOLOCK) WHERE UPPER(StatusCode) = 'REPLACE'

	SELECT @Stage = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(500)')='Stage'
	THEN filterby.value('(FieldValue/text())[1]','VARCHAR(500)') ELSE @Stage END,

	@CustomerId=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer'
	THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @CustomerId END,

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
	THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10 END,

	 @IsDownload = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='IsDownload'
	THEN convert(bit, filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @IsDownload END


	FROM @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby) 

		IF OBJECT_ID(N'tempdb..#AwaitingPartsData') IS NOT NULL
			DROP TABLE #AwaitingPartsData	
		
		IF OBJECT_ID(N'tempdb..#tmpMultipleWOMStockline') IS NOT NULL
			DROP TABLE #tmpMultipleWOMStockline

		IF OBJECT_ID(N'tempdb..#tmpMultipleWOMStocklineKit') IS NOT NULL
			DROP TABLE #tmpMultipleWOMStocklineKit

		CREATE TABLE #AwaitingPartsData
		(	
			TotalRecordsCount BIGINT NULL, 
			WorkOrderId BIGINT NULL, 
			wonum VARCHAR(30) NULL, 
			customername VARCHAR(100) NULL, 
			woqnum VARCHAR(100) NULL, 
			mpn VARCHAR(50) NULL, 
			mpnDescription NVARCHAR(MAX) NULL,
			itemMasterId BIGINT NULL,
			pn VARCHAR(50) NULL, 
			pnDescription NVARCHAR(MAX) NULL,
			stagecode VARCHAR(100) NULL, 
			conditionId BIGINT NULL,
			condition VARCHAR(256) NULL,
			manufacturer VARCHAR(250) NULL,
			uom VARCHAR(100) NULL,
			approvedamount DECIMAL(18, 2) NULL, 
			openDate DATETIME2 NULL, 
			requestDate DATETIME2 NULL, 
			estimatedShipDate DATETIME2 NULL, 
			workOrderMaterialsId BIGINT NULL,
			quantityRequested INT NULL, 
			quantityReserved INT NULL, 
			quantityIssued INT NULL, 
			quantityAvailable INT NULL,
			backlog INT NULL,
			customerStock INT NULL,
			customerApprovedDate DATETIME2 NULL,
			level1 VARCHAR(MAX) NULL, 
			level2 VARCHAR(MAX) NULL, 
			level3 VARCHAR(MAX) NULL, 
			level4 VARCHAR(MAX) NULL, 
			level5 VARCHAR(MAX) NULL, 
			level6 VARCHAR(MAX) NULL, 
			level7 VARCHAR(MAX) NULL, 
			level8 VARCHAR(MAX) NULL,
			level9 VARCHAR(MAX) NULL, 
			level10 VARCHAR(MAX) NULL, 
			masterCompanyId INT NULL,
			isKitType BIT NULL
		)
		
		CREATE TABLE #tmpMultipleWOMStockline
		(
			[ID] [BIGINT] NOT NULL IDENTITY, 						 
			[WorkOrderMaterialsId] [BIGINT] NULL,
			[WorkOrderId] [BIGINT] NULL,						 
			[ItemMasterId] [BIGINT] NULL,
			[ConditionId] [BIGINT] NOT NULL,
			[Quantity] [INT] NULL, 
			[QuantityReserved] [INT] NULL,
			[QuantityIssued] [INT] NULL
		)

		CREATE TABLE #tmpMultipleWOMStocklineKit
		(
			[ID] [BIGINT] NOT NULL IDENTITY, 
			[WorkOrderMaterialsId] [BIGINT] NULL,
			[WorkOrderId] [BIGINT] NULL,						 
			[ItemMasterId] [BIGINT] NULL,
			[ConditionId] [BIGINT] NOT NULL,
			[Quantity] [INT] NULL, 
			[QuantityReserved] [INT] NULL,
			[QuantityIssued] [INT] NULL
		)

		INSERT INTO #tmpMultipleWOMStockline 
		SELECT DISTINCT	WOM.[WorkOrderMaterialsId], WOM.[WorkOrderId], WOM.[ItemMasterId],WOM.[ConditionCodeId], SUM(ISNULL(WOM.[Quantity], 0)), ISNULL(WOM.[TotalReserved], 0), ISNULL(WOM.[TotalIssued], 0)
				FROM [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK) 
		WHERE WOM.[MasterCompanyId] = @MasterCompanyId AND WOM.ProvisionId = @ReplaceProvisionId
		GROUP BY WOM.[WorkOrderMaterialsId], WOM.[WorkOrderId], WOM.[ItemMasterId],WOM.[ConditionCodeId], WOM.[TotalReserved], WOM.[TotalIssued];

		INSERT INTO #tmpMultipleWOMStocklineKit
		SELECT DISTINCT WOM.[WorkOrderMaterialsKitId], WOM.[WorkOrderId], WOM.[ItemMasterId],WOM.[ConditionCodeId], SUM(ISNULL(WOM.[Quantity], 0)), ISNULL(WOM.[TotalReserved], 0), ISNULL(WOM.[TotalIssued], 0)
				FROM [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK) 
		WHERE WOM.[MasterCompanyId] = @MasterCompanyId AND WOM.ProvisionId = @ReplaceProvisionId
		GROUP BY WOM.[WorkOrderMaterialsKitId], WOM.[WorkOrderId], WOM.[ItemMasterId],WOM.[ConditionCodeId], WOM.[TotalReserved], WOM.[TotalIssued];

	INSERT INTO #AwaitingPartsData
	SELECT DISTINCT 0 AS TotalRecordsCount,
		WO.WorkOrderId,  
		UPPER(WO.WorkOrderNum) 'wonum',
		UPPER(C.Name) 'customername',
		UPPER(WOQ.QuoteNumber) 'woqnum',
        MPNData.mpn 'mpn',
        MPNData.mpnDescription 'mpnDescription',
		IMWOM.ItemMasterId 'itemMasterId',
		UPPER(IMWOM.partnumber) 'pn',
		UPPER(IMWOM.PartDescription) 'pnDescription',
		MAX(UPPER(WOS_From.Code + '-' + WOS_From.Stage)) AS 'stagecode',
		MPNData.conditionId 'conditionId',
		MPNData.condition 'condition',
		UPPER(IMWOM.ManufacturerName) 'manufacturer',
		UPPER(UOM.ShortName) 'uom',
		ApprovedAmount.approvedamount,
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST((select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),Max(TZ.Description))) AS DATETIME) ELSE CAST((select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),Max(TZ.Description))) AS DATETIME) END 'opendate',  
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOPN.CustomerRequestDate) AS DATETIME) ELSE CAST(MAX(WOPN.CustomerRequestDate) AS DATETIME) END 'requestdate',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOPN.EstimatedShipDate) AS DATETIME) ELSE CAST(MAX(WOPN.EstimatedShipDate) AS DATETIME) END 'estimatedShipDate',  
		tmpWOM.WorkOrderMaterialsId 'workOrderMaterialsId',
		ISNULL(tmpWOM.Quantity, 0) 'quantityRequested',
		ISNULL(tmpWOM.QuantityReserved, 0) 'quantityReserved',
		ISNULL(tmpWOM.QuantityIssued, 0) 'quantityIssued',
		ISNULL(STK.QuantityAvailable, 0) 'quantityAvailable',
		--ISNULL(POPData.Backlog, 0) 'backlog',
		0 'backlog',
		ISNULL(STKCS.QuantityAvailable, 0) 'customerStock',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOQ.ApprovedDate) AS DATETIME) ELSE CAST(MAX(WOQ.ApprovedDate) AS DATETIME) END 'customerApprovedDate',
		UPPER(MSD.Level1Name) AS level1, 
		UPPER(MSD.Level2Name) AS level2,
		UPPER(MSD.Level3Name) AS level3,
		UPPER(MSD.Level4Name) AS level4,
		UPPER(MSD.Level5Name) AS level5,
		UPPER(MSD.Level6Name) AS level6,
		UPPER(MSD.Level7Name) AS level7,
		UPPER(MSD.Level8Name) AS level8,
		UPPER(MSD.Level9Name) AS level9,
		UPPER(MSD.Level10Name) AS level10 ,  
		MAX(WO.MasterCompanyId) MasterCompanyId,
		0 'isKitType'
	FROM DBO.WorkOrder WO WITH (NOLOCK) 
		INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId
		INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID
		INNER JOIN DBO.ItemMaster AS IMWOPN WITH (NOLOCK) ON WOPN.ItemMasterId = IMWOPN.ItemMasterId
		INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID
		INNER JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId AND QuoteStatusId = @ApprovedQuoteStatusId
		INNER JOIN DBO.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WQD.WorkOrderQuoteId  
		LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = WO.CustomerId  
		LEFT JOIN dbo.EntityStructureSetup ES WITH (NOLOCK) ON ES.EntityStructureId=MSD.EntityMSID
		LEFT JOIN DBO.WorkOrderStage AS WOS WITH (NOLOCK) ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId   
		LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
		LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
		LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId
		LEFT JOIN #tmpMultipleWOMStockline tmpWOM WITH (NOLOCK) ON tmpWOM.[WorkOrderId] = WO.[WorkOrderId]
		LEFT JOIN DBO.ItemMaster AS IMWOM WITH (NOLOCK) ON tmpWOM.ItemMasterId = IMWOM.ItemMasterId
		LEFT JOIN DBO.WorkOrderMaterials AS WOM WITH (NOLOCK) ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
		LEFT JOIN DBO.UnitOfMeasure AS UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
		LEFT JOIN (
			SELECT 
				ItemMasterId, 
				ConditionId, 
				SUM(ISNULL(QuantityAvailable, 0)) AS QuantityAvailable
			FROM 
				DBO.Stockline WITH(NOLOCK)
			WHERE 
				ISNULL(IsCustomerStock, 0) = 0 AND ISNULL(IsParent, 0) = 1
			GROUP BY 
				ItemMasterId, ConditionId
		) AS STK ON tmpWOM.ItemMasterId = STK.ItemMasterId AND tmpWOM.ConditionId = STK.ConditionId
		LEFT JOIN (
			SELECT 
				ItemMasterId, 
				ConditionId, 
				SUM(ISNULL(QuantityAvailable, 0)) AS QuantityAvailable
			FROM 
				DBO.Stockline WITH(NOLOCK)
			WHERE 
				ISNULL(IsCustomerStock, 0) = 1 AND ISNULL(IsParent, 0) = 1
			GROUP BY 
				ItemMasterId, ConditionId
		) AS STKCS ON tmpWOM.ItemMasterId = STKCS.ItemMasterId AND tmpWOM.ConditionId = STKCS.ConditionId
		LEFT JOIN DBO.Condition CDTN WITH (NOLOCK) ON tmpWOM.ConditionId = CDTN.ConditionId
		OUTER APPLY (
			SELECT 
				UPPER(IMWOPN.partnumber) AS mpn,
				UPPER(IMWOPN.PartDescription) AS mpnDescription,
				UPPER(CDTN.ConditionId) AS conditionId,
				UPPER(CDTN.Description) AS condition
			FROM DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
			INNER JOIN DBO.ItemMaster IMWOPN WITH (NOLOCK) ON WOPN.ItemMasterId = IMWOPN.ItemMasterId
			INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOPN.ID = WOWF.WorkOrderPartNoId
			LEFT JOIN DBO.Condition CDTN WITH (NOLOCK) ON tmpWOM.ConditionId = CDTN.ConditionId
			WHERE WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
		) AS MPNData
		OUTER APPLY (
			SELECT 
				MAX(
					CASE  
						WHEN WQD.QuoteMethod = 1 THEN ISNULL(WQD.CommonFlatRate, 0) 
						ELSE ISNULL(WQD.MaterialFlatBillingAmount, 0) 
						   + ISNULL(WQD.LaborFlatBillingAmount, 0) 
						   + ISNULL(WQD.ChargesFlatBillingAmount, 0) 
						   + ISNULL(WQD.FreightFlatBillingAmount, 0)
					END
				) AS approvedamount
			FROM DBO.WorkOrderQuoteDetails WQD WITH (NOLOCK) 
			WHERE WQD.WorkOrderQuoteId = WOQ.WorkOrderQuoteId
		) AS ApprovedAmount
		OUTER APPLY (
			SELECT 
				WOS_From.Code,
				WOS_From.Stage
			FROM 
				DBO.WorkOrderStage WOS_From WITH (NOLOCK) 
			WHERE 
				WOS_From.WorkOrderStageId = WOS.WorkOrderStageId
		) AS WOS_From
	WHERE
		(@CustomerId IS NULL OR WO.CustomerId = @CustomerId)
		AND ISNULL(WO.IsDeleted, 0) = 0  		 
		AND ISNULL(WO.IsActive, 1) = 1 
		AND  ISNULL(WO.WorkOrderStatusId, 0) != 2 -----WO Not Closed  
		AND (ISNULL(@Stage,'') ='' OR WOS.WorkOrderStageId IN (SELECT value FROM String_split(ISNULL(@Stage,WOS.WorkOrderStageId), ',')))
		AND  ISNULL(WOPN.WorkOrderStatusId, 0) != 2 AND  ISNULL(WOPN.IsClosed, 0) != 1 -----MPN Not Closed  
		AND WO.mastercompanyid = @MasterCompanyId 
		AND MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))
		AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
		AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
		AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
		AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
		AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
		AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
		AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
		AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
		AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
		AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))  
	GROUP BY WO.WorkOrderId, WQD.QuoteMethod, tmpWOM.Quantity, tmpWOM.[QuantityReserved], tmpWOM.[QuantityIssued],
		STK.QuantityAvailable,
		STKCS.QuantityAvailable,
		UPPER(WO.WorkOrderNum),
		UPPER(C.Name),
		UPPER(WOQ.QuoteNumber),
		IMWOM.ItemMasterId,
		UPPER(IMWOM.partnumber),
		UPPER(IMWOM.PartDescription),
		MPNData.mpn,
		MPNData.mpnDescription,
		MPNData.conditionId,
		MPNData.condition,
		tmpWOM.WorkOrderMaterialsId,
		UPPER(IMWOM.ManufacturerName),
		UPPER(UOM.ShortName),
		ApprovedAmount.approvedamount,
		MSD.Level1Name,
		MSD.Level2Name,
		MSD.Level3Name,
		MSD.Level4Name,
		MSD.Level5Name,
		MSD.Level6Name,
		MSD.Level7Name,
		MSD.Level8Name,
		MSD.Level9Name,
		MSD.Level10Name

	UPDATE #AwaitingPartsData SET [backlog] = ISNULL(POPDATA.[Backlog], 0)
	FROM(
	SELECT 
		APD.WorkOrderId, 
		APD.ItemMasterId,
		APD.ConditionId,
		SUM(ISNULL(POP.QuantityBackOrdered, 0)) AS Backlog 
	FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
		INNER JOIN DBO.PurchaseOrder PO WITH(NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId AND PO.StatusId IN (@POOpenStatus, @POPendingStatus, @POFulFillingStatus) AND PO.IsDeleted = 0
		INNER JOIN #AwaitingPartsData APD WITH(NOLOCK) ON APD.WorkOrderId = POP.WorkOrderId
	WHERE POP.WorkOrderId IS NOT NULL AND APD.WorkOrderId = POP.WorkOrderId AND APD.ItemMasterId = POP.ItemMasterId AND APD.ConditionId = POP.ConditionId
	GROUP BY 
		APD.WorkOrderId, 
		APD.ItemMasterId,
		APD.ConditionId
	) POPDATA WHERE POPDATA.WorkOrderId = #AwaitingPartsData.WorkOrderId AND POPDATA.ItemMasterId = #AwaitingPartsData.ItemMasterId AND POPDATA.ConditionId = #AwaitingPartsData.ConditionId

	INSERT INTO #AwaitingPartsData
	SELECT DISTINCT 0 AS TotalRecordsCount,
		WO.WorkOrderId,  
		UPPER(WO.WorkOrderNum) 'wonum',
		UPPER(C.Name) 'customername',
		UPPER(WOQ.QuoteNumber) 'woqnum',
		MPNData.mpn 'mpn',
        MPNData.mpnDescription 'mpnDescription',
		IMWOM.ItemMasterId 'itemMasterId',
		UPPER(IMWOM.partnumber) 'pn',
		UPPER(IMWOM.PartDescription) 'pnDescription',
		MAX(UPPER(WOS_From.Code + '-' + WOS_From.Stage)) AS 'stagecode',
		MPNData.conditionId 'conditionId',
		MPNData.condition 'condition',
		UPPER(IMWOM.ManufacturerName) 'manufacturer',
		UPPER(UOM.ShortName) 'uom',
		ApprovedAmount.approvedamount,
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST((select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),Max(TZ.Description))) AS DATETIME) ELSE CAST((select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),Max(TZ.Description))) AS DATETIME) END 'opendate',  
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOPN.CustomerRequestDate) AS DATETIME) ELSE CAST(MAX(WOPN.CustomerRequestDate) AS DATETIME) END 'requestdate',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOPN.EstimatedShipDate) AS DATETIME) ELSE CAST(MAX(WOPN.EstimatedShipDate) AS DATETIME) END 'estimatedShipDate',
		tmpWOM.WorkOrderMaterialsId 'workOrderMaterialsId',
		ISNULL(tmpWOM.Quantity, 0) 'quantityRequested',
		ISNULL(tmpWOM.QuantityReserved, 0) 'quantityReserved',
		ISNULL(tmpWOM.QuantityIssued, 0) 'quantityIssued',
		ISNULL(STK.QuantityAvailable, 0) 'quantityAvailable',
		--ISNULL(POPData.Backlog, 0) 'backlog',
		0 'backlog',
		ISNULL(STKCS.QuantityAvailable, 0) 'customerStock',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOQ.ApprovedDate) AS DATETIME) ELSE CAST(MAX(WOQ.ApprovedDate) AS DATETIME) END 'customerApprovedDate',
		UPPER(MSD.Level1Name) AS level1, 
		UPPER(MSD.Level2Name) AS level2,
		UPPER(MSD.Level3Name) AS level3,
		UPPER(MSD.Level4Name) AS level4,
		UPPER(MSD.Level5Name) AS level5,
		UPPER(MSD.Level6Name) AS level6,
		UPPER(MSD.Level7Name) AS level7,
		UPPER(MSD.Level8Name) AS level8,
		UPPER(MSD.Level9Name) AS level9,
		UPPER(MSD.Level10Name) AS level10 ,  
		MAX(WO.MasterCompanyId) MasterCompanyId,
		1 'isKitType'
	FROM DBO.WorkOrder WO WITH (NOLOCK) 
		INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId
		INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID
		INNER JOIN DBO.ItemMaster AS IMWOPN WITH (NOLOCK) ON WOPN.ItemMasterId = IMWOPN.ItemMasterId
		INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID
		INNER JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId AND QuoteStatusId = @ApprovedQuoteStatusId
		LEFT JOIN DBO.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WQD.WorkOrderQuoteId  
		LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = WO.CustomerId  
		LEFT JOIN dbo.EntityStructureSetup ES WITH (NOLOCK) ON ES.EntityStructureId=MSD.EntityMSID
		LEFT JOIN DBO.WorkOrderStage AS WOS WITH (NOLOCK) ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId   
		LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
		LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
		LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId
		LEFT JOIN #tmpMultipleWOMStocklineKit tmpWOM WITH (NOLOCK) ON tmpWOM.[WorkOrderId] = WO.[WorkOrderId]
		LEFT JOIN DBO.ItemMaster AS IMWOM WITH (NOLOCK) ON tmpWOM.ItemMasterId = IMWOM.ItemMasterId
		LEFT JOIN DBO.WorkOrderMaterialsKit AS WOM WITH (NOLOCK) ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId
		LEFT JOIN DBO.UnitOfMeasure AS UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
		LEFT JOIN (
			SELECT 
				ItemMasterId, 
				ConditionId, 
				SUM(ISNULL(QuantityAvailable, 0)) AS QuantityAvailable
			FROM 
				DBO.Stockline WITH (NOLOCK)
			WHERE 
				ISNULL(IsCustomerStock, 0) = 0 AND ISNULL(IsParent, 0) = 1
			GROUP BY 
				ItemMasterId, ConditionId
		) AS STK ON tmpWOM.ItemMasterId = STK.ItemMasterId AND tmpWOM.ConditionId = STK.ConditionId
		LEFT JOIN (
			SELECT 
				ItemMasterId, 
				ConditionId, 
				SUM(ISNULL(QuantityAvailable, 0)) AS QuantityAvailable
			FROM 
				DBO.Stockline WITH (NOLOCK)
			WHERE 
				ISNULL(IsCustomerStock, 0) = 1 AND ISNULL(IsParent, 0) = 1
			GROUP BY 
				ItemMasterId, ConditionId
		) AS STKCS ON tmpWOM.ItemMasterId = STKCS.ItemMasterId AND tmpWOM.ConditionId = STKCS.ConditionId
		LEFT JOIN DBO.Condition CDTN WITH (NOLOCK) ON tmpWOM.ConditionId = CDTN.ConditionId
		OUTER APPLY (
			SELECT 
				UPPER(IMWOPN.partnumber) AS mpn,
				UPPER(IMWOPN.PartDescription) AS mpnDescription,
				UPPER(CDTN.ConditionId) AS conditionId,
				UPPER(CDTN.Description) AS condition
			FROM DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
			INNER JOIN DBO.ItemMaster IMWOPN WITH (NOLOCK) ON WOPN.ItemMasterId = IMWOPN.ItemMasterId
			INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOPN.ID = WOWF.WorkOrderPartNoId
			LEFT JOIN DBO.Condition CDTN WITH (NOLOCK) ON tmpWOM.ConditionId = CDTN.ConditionId
			WHERE WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
		) AS MPNData
		OUTER APPLY (
			SELECT 
				MAX(
					CASE  
						WHEN WQD.QuoteMethod = 1 THEN ISNULL(WQD.CommonFlatRate, 0) 
						ELSE ISNULL(WQD.MaterialFlatBillingAmount, 0) 
						   + ISNULL(WQD.LaborFlatBillingAmount, 0) 
						   + ISNULL(WQD.ChargesFlatBillingAmount, 0) 
						   + ISNULL(WQD.FreightFlatBillingAmount, 0)
					END
				) AS approvedamount
			FROM DBO.WorkOrderQuoteDetails WQD WITH (NOLOCK) 
			WHERE WQD.WorkOrderQuoteId = WOQ.WorkOrderQuoteId
		) AS ApprovedAmount
		OUTER APPLY (
			SELECT 
				WOS_From.Code,
				WOS_From.Stage
			FROM 
				DBO.WorkOrderStage WOS_From WITH (NOLOCK) 
			WHERE 
				WOS_From.WorkOrderStageId = WOS.WorkOrderStageId
		) AS WOS_From
	WHERE
		(@CustomerId IS NULL OR WO.CustomerId = @CustomerId)
		AND ISNULL(WO.IsDeleted, 0) = 0
		AND ISNULL(WO.IsActive, 1) = 1 
		AND  ISNULL(WO.WorkOrderStatusId, 0) != 2 -----WO Not Closed  
		AND (ISNULL(@Stage,'') ='' OR WOS.WorkOrderStageId IN (SELECT value FROM String_split(ISNULL(@Stage,WOS.WorkOrderStageId), ',')))
		AND  ISNULL(WOPN.WorkOrderStatusId, 0) != 2 AND  ISNULL(WOPN.IsClosed, 0) != 1 -----MPN Not Closed 
		AND WO.mastercompanyid = @MasterCompanyId 
		AND MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))
		AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
		AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
		AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
		AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
		AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
		AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
		AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
		AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
		AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
		AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))  
	GROUP BY WO.WorkOrderId, WQD.QuoteMethod, tmpWOM.Quantity, tmpWOM.[QuantityReserved], tmpWOM.[QuantityIssued],
		STK.QuantityAvailable,
		STKCS.QuantityAvailable,
		UPPER(WO.WorkOrderNum),
		UPPER(C.Name),
		UPPER(WOQ.QuoteNumber),
		IMWOM.ItemMasterId,
		UPPER(IMWOM.partnumber),
		UPPER(IMWOM.PartDescription),
		MPNData.mpn,
		MPNData.mpnDescription,
		MPNData.conditionId,
		MPNData.condition,
		tmpWOM.WorkOrderMaterialsId,
		UPPER(IMWOM.ManufacturerName),
		UPPER(UOM.ShortName),
		ApprovedAmount.approvedamount,
		MSD.Level1Name,
		MSD.Level2Name,
		MSD.Level3Name,
		MSD.Level4Name,
		MSD.Level5Name,
		MSD.Level6Name,
		MSD.Level7Name,
		MSD.Level8Name,
		MSD.Level9Name,
		MSD.Level10Name

	UPDATE #AwaitingPartsData SET [backlog] = ISNULL(POPDATA.[Backlog], 0)
	FROM(
	SELECT 
		APD.WorkOrderId, 
		APD.ItemMasterId,
		APD.ConditionId,
		SUM(ISNULL(POP.QuantityBackOrdered, 0)) AS Backlog 
	FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
		INNER JOIN DBO.PurchaseOrder PO WITH(NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId AND PO.StatusId IN (@POOpenStatus, @POPendingStatus, @POFulFillingStatus) AND PO.IsDeleted = 0
		INNER JOIN #AwaitingPartsData APD WITH(NOLOCK) ON APD.WorkOrderId = POP.WorkOrderId
	WHERE POP.WorkOrderId IS NOT NULL AND APD.WorkOrderId = POP.WorkOrderId AND APD.ItemMasterId = POP.ItemMasterId AND APD.ConditionId = POP.ConditionId AND APD.isKitType = 1
	GROUP BY 
		APD.WorkOrderId, 
		APD.ItemMasterId,
		APD.ConditionId
	) POPDATA WHERE POPDATA.WorkOrderId = #AwaitingPartsData.WorkOrderId AND POPDATA.ItemMasterId = #AwaitingPartsData.ItemMasterId AND POPDATA.ConditionId = #AwaitingPartsData.ConditionId


	IF ISNULL(@PageSize,0)=0
	BEGIN
		SELECT @PageSize = COUNT(*)
		FROM #AwaitingPartsData FC   WITH (NOLOCK)
		WHERE (quantityRequested - quantityReserved - quantityIssued - quantityAvailable - backlog - customerStock) > 0 OR (backlog > 0 and quantityRequested - quantityReserved - quantityIssued - quantityAvailable - customerStock > 0)
		ORDER BY WorkOrderId DESC
	END

	DECLARE @TotalWorkOrder INT = 0, @TotalAwaitingParts INT = 0;

	SELECT @TotalWorkOrder = COUNT(DISTINCT WorkOrderId) FROM #AwaitingPartsData FC WITH (NOLOCK)
	WHERE  (ISNULL(quantityRequested, 0) - ISNULL(quantityReserved, 0) - ISNULL(quantityIssued, 0) - ISNULL(quantityAvailable, 0) - ISNULL(backlog, 0) - ISNULL(customerStock, 0)) > 0 OR 
		(ISNULL(backlog, 0) > 0 and ISNULL(quantityRequested, 0) - ISNULL(quantityReserved, 0) - ISNULL(quantityIssued, 0) - ISNULL(quantityAvailable, 0) - ISNULL(customerStock, 0) > 0)

	SELECT @TotalAwaitingParts = SUM(ISNULL(quantityRequested, 0) - ISNULL(quantityReserved, 0) - ISNULL(quantityIssued, 0) - ISNULL(quantityAvailable, 0) - ISNULL(backlog, 0) - ISNULL(customerStock, 0)) FROM #AwaitingPartsData FC WITH (NOLOCK)
	WHERE  (ISNULL(quantityRequested, 0) - ISNULL(quantityReserved, 0) - ISNULL(quantityIssued, 0) - ISNULL(quantityAvailable, 0) - ISNULL(backlog, 0) - ISNULL(customerStock, 0)) > 0 OR 
		(ISNULL(backlog, 0) > 0 and ISNULL(quantityRequested, 0) - ISNULL(quantityReserved, 0) - ISNULL(quantityIssued, 0) - ISNULL(quantityAvailable, 0) - ISNULL(customerStock, 0) > 0)

	SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END

	IF @IsDownload = 1
	BEGIN
		SELECT DISTINCT COUNT(2) OVER () AS TotalRecordsCount, @TotalWorkOrder AS WorkOrderTotal, @TotalAwaitingParts AS AwaitingPartsTotal, WorkOrderId, wonum, customername, woqnum, mpn, mpnDescription, pn, pnDescription,stagecode, condition, manufacturer, uom, approvedamount, openDate, requestDate, estimatedShipDate 
			, quantityRequested, quantityReserved, quantityIssued, (quantityRequested - quantityReserved - quantityIssued) AS quantityRemaining, quantityAvailable, backlog, customerStock, customerApprovedDate
			, level1, level2, level3, level4, level5, level6, level7, level8,level9, level10
			, CASE 
				WHEN (quantityRequested - quantityReserved - quantityIssued - quantityAvailable - backlog - customerStock) >= 0 THEN (quantityRequested - quantityReserved - quantityIssued - quantityAvailable - backlog - customerStock)
				ELSE 0
				END AS toBeOrdered
		FROM #AwaitingPartsData FC   WITH (NOLOCK)
		WHERE (ISNULL(quantityRequested, 0) - ISNULL(quantityReserved, 0) - ISNULL(quantityIssued, 0) - ISNULL(quantityAvailable, 0) - ISNULL(backlog, 0) - ISNULL(customerStock, 0)) > 0 OR 
			(ISNULL(backlog, 0) > 0 and ISNULL(quantityRequested, 0) - ISNULL(quantityReserved, 0) - ISNULL(quantityIssued, 0) - ISNULL(quantityAvailable, 0) - ISNULL(customerStock, 0) > 0)
		ORDER BY WorkOrderId DESC;
	END
	ELSE
	BEGIN
		SELECT DISTINCT COUNT(2) OVER () AS TotalRecordsCount, @TotalWorkOrder AS WorkOrderTotal, @TotalAwaitingParts AS AwaitingPartsTotal, WorkOrderId, wonum, customername, woqnum, mpn, mpnDescription, pn, pnDescription,stagecode, condition, manufacturer, uom, approvedamount, openDate, requestDate, estimatedShipDate
			, quantityRequested, quantityReserved, quantityIssued, (quantityRequested - quantityReserved - quantityIssued) AS quantityRemaining, quantityAvailable, backlog, customerStock, customerApprovedDate
			, level1, level2, level3, level4, level5, level6, level7, level8,level9, level10
			, CASE 
				WHEN (quantityRequested - quantityReserved - quantityIssued - quantityAvailable - backlog - customerStock) >= 0 THEN (quantityRequested - quantityReserved - quantityIssued - quantityAvailable - backlog - customerStock)
				ELSE 0
				END AS toBeOrdered
		FROM #AwaitingPartsData FC   WITH (NOLOCK)
		WHERE (ISNULL(quantityRequested, 0) - ISNULL(quantityReserved, 0) - ISNULL(quantityIssued, 0) - ISNULL(quantityAvailable, 0) - ISNULL(backlog, 0) - ISNULL(customerStock, 0)) > 0 OR 
			(ISNULL(backlog, 0) > 0 and ISNULL(quantityRequested, 0) - ISNULL(quantityReserved, 0) - ISNULL(quantityIssued, 0) - ISNULL(quantityAvailable, 0) - ISNULL(customerStock, 0) > 0)
		ORDER BY WorkOrderId DESC  
		OFFSET((ISNULL(@PageNumber, 0)-1) * ISNULL(@pageSize, 0)) ROWS FETCH NEXT ISNULL(@pageSize, 0) ROWS ONLY;
	END


	COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
	ROLLBACK TRANSACTION
DECLARE @ErrorLogID int,
	@DatabaseName varchar(100) = DB_NAME()
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	,
	@AdhocComments varchar(150) = '[usprpt_GetWorkOrderAwaitingPartsReport]',
	@ProcedureParameters varchar(3000) = 
	'@Parameter3 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
	'@Parameter4 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
	'@Parameter5 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
	'@Parameter6 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +
	'@Parameter7 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),   
  
	@ApplicationName varchar(100) = 'PAS'

	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	EXEC Splogexception @DatabaseName = @DatabaseName,
		@AdhocComments = @AdhocComments,
		@ProcedureParameters = @ProcedureParameters,
		@ApplicationName = @ApplicationName,
		@ErrorLogID = @ErrorLogID OUTPUT;

	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

	RETURN (1);
	END CATCH

	IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
	BEGIN
		DROP TABLE #managmetnstrcture
	END
END