  
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
 ** S NO   Date         Author   Change Description                
 ** --   --------     -------  --------------------------------     
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
    @IsDownload BIT = NULL   

	DECLARE @Stage varchar(300) = NULL  
    DECLARE @CustomerId varchar(100) = NULL 

	DECLARE @ApprovedQuoteStatusId INT = 0
	SELECT @ApprovedQuoteStatusId = WorkOrderQuoteStatusId FROM DBO.WorkOrderQuoteStatus  WITH (NOLOCK) WHERE Description = 'Approved';

     DECLARE @ModuleID INT = 12; -- MS Module ID    
     SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END    

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

		IF OBJECT_ID('tempdb..#AwaitingPartsData') IS NOT NULL
			DROP TABLE #AwaitingPartsData	
		
		IF OBJECT_ID(N'tempdb..#tmpMultipleWOMStockline') IS NOT NULL
			DROP TABLE #tmpMultipleWOMStockline

		IF OBJECT_ID(N'tempdb..#tmpMultipleWOMStocklineKit') IS NOT NULL
			DROP TABLE #tmpMultipleWOMStocklineKit

		CREATE TABLE #AwaitingPartsData
		(	
			TotalRecordsCount BIGINT NULL, 
			WorkOrderId BIGINT NULL, 
			wonum VARCHAR(50) NULL, 
			customername VARCHAR(500) NULL, 
			woqnum VARCHAR(50) NULL, 
			pn VARCHAR(500) NULL, 
			pnDescription VARCHAR(500) NULL,
			stagecode VARCHAR(100) NULL, 
			approvedamount DECIMAL(18, 2) NULL, 
			openDate DATETIME2 NULL, 
			requestDate DATETIME2 NULL, 
			estimatedShipDate DATETIME2 NULL, 
			quantityRequested INT NULL, 
			quantityAvailable INT NULL, 
			dateQuoteApproved DATETIME2 NULL,
			level1 VARCHAR(500) NULL, 
			level2 VARCHAR(500) NULL, 
			level3 VARCHAR(500) NULL, 
			level4 VARCHAR(500) NULL, 
			level5 VARCHAR(500) NULL, 
			level6 VARCHAR(500) NULL, 
			level7 VARCHAR(500) NULL, 
			level8 VARCHAR(500) NULL,
			level9 VARCHAR(500) NULL, 
			level10 VARCHAR(500) NULL, 
			masterCompanyId INT NULL
		)
		
		CREATE TABLE #tmpMultipleWOMStockline
		(
			[ID] [BIGINT] NOT NULL IDENTITY, 						 
			[WorkOrderMaterialsId] [BIGINT] NULL,
			[WorkOrderId] [BIGINT] NULL,						 
			[ItemMasterId] [BIGINT] NULL,
			[ConditionId] [BIGINT] NOT NULL,
			[Quantity] [INT] NULL,
		)

		CREATE TABLE #tmpMultipleWOMStocklineKit
		(
			[ID] [BIGINT] NOT NULL IDENTITY, 
			[WorkOrderMaterialsId] [BIGINT] NULL,
			[WorkOrderId] [BIGINT] NULL,						 
			[ItemMasterId] [BIGINT] NULL,
			[ConditionId] [BIGINT] NOT NULL,
			[Quantity] [INT] NULL,
		)

		CREATE TABLE #tmpMultipleSubWOMStockline
		(
			[ID] [BIGINT] NOT NULL IDENTITY, 						 
			[SubWorkOrderMaterialsId] [BIGINT] NULL,
			[SubWorkOrderId] [BIGINT] NULL,						 
			[ItemMasterId] [BIGINT] NULL,
			[ConditionId] [BIGINT] NOT NULL,
			[Quantity] [INT] NULL,
		)

		CREATE TABLE #tmpMultipleSubWOMStocklineKit
		(
			[ID] [BIGINT] NOT NULL IDENTITY, 
			[SubWorkOrderMaterialsId] [BIGINT] NULL,
			[SubWorkOrderId] [BIGINT] NULL,						 
			[ItemMasterId] [BIGINT] NULL,
			[ConditionId] [BIGINT] NOT NULL,
			[Quantity] [INT] NULL,
		)

		INSERT INTO #tmpMultipleWOMStockline 
		SELECT DISTINCT	WOM.[WorkOrderMaterialsId], WOM.[WorkOrderId], WOM.[ItemMasterId],WOM.[ConditionCodeId], SUM(ISNULL(WOM.[Quantity], 0))
				FROM [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK) 
		WHERE WOM.[MasterCompanyId] = @MasterCompanyId
		GROUP BY WOM.[WorkOrderMaterialsId], WOM.[WorkOrderId], WOM.[ItemMasterId],WOM.[ConditionCodeId];

		INSERT INTO #tmpMultipleSubWOMStockline 
		SELECT DISTINCT	WOM.[SubWorkOrderMaterialsId], WOM.[SubWorkOrderId], WOM.[ItemMasterId],WOM.[ConditionCodeId], SUM(ISNULL(WOM.[Quantity], 0))
				FROM [dbo].[SubWorkOrderMaterials] WOM WITH (NOLOCK) 
		WHERE WOM.[MasterCompanyId] = @MasterCompanyId
		GROUP BY WOM.[SubWorkOrderMaterialsId], WOM.[SubWorkOrderId], WOM.[ItemMasterId],WOM.[ConditionCodeId];

		INSERT INTO #tmpMultipleWOMStocklineKit
		SELECT DISTINCT WOM.[WorkOrderMaterialsKitId], WOM.[WorkOrderId], WOM.[ItemMasterId],WOM.[ConditionCodeId], SUM(ISNULL(WOM.[Quantity], 0))
				FROM [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK) 
		WHERE WOM.[MasterCompanyId] = @MasterCompanyId
		GROUP BY WOM.[WorkOrderMaterialsKitId], WOM.[WorkOrderId], WOM.[ItemMasterId],WOM.[ConditionCodeId];

		INSERT INTO #tmpMultipleSubWOMStocklineKit
		SELECT DISTINCT WOM.[SubWorkOrderMaterialsKitId], WOM.[SubWorkOrderId], WOM.[ItemMasterId],WOM.[ConditionCodeId], SUM(ISNULL(WOM.[Quantity], 0))
				FROM [dbo].[SubWorkOrderMaterialsKit] WOM WITH (NOLOCK) 
		WHERE WOM.[MasterCompanyId] = @MasterCompanyId
		GROUP BY WOM.[SubWorkOrderMaterialsKitId], WOM.[SubWorkOrderId], WOM.[ItemMasterId],WOM.[ConditionCodeId];
    
	INSERT INTO #AwaitingPartsData
	SELECT DISTINCT 0 AS TotalRecordsCount,    
		WO.WorkOrderId,  
		MAX(UPPER(WO.WorkOrderNum)) 'wonum',
		MAX(UPPER(C.Name)) 'customername',
		MAX(UPPER(WOQ.QuoteNumber)) 'woqnum',
		MAX(UPPER(IM.partnumber)) 'pn',    
		MAX(UPPER(IM.PartDescription)) 'pnDescription',    
		MAX(UPPER(WOS.Stage)) 'stagecode',  
		MAX(WOM.ExtendedCost) 'approvedamount',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST((select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),Max(TZ.Description))) AS DATETIME) ELSE CAST((select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),Max(TZ.Description))) AS DATETIME) END 'opendate',  
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOPN.CustomerRequestDate) AS DATETIME) ELSE CAST(MAX(WOPN.CustomerRequestDate) AS DATETIME) END 'requestdate',    
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOPN.EstimatedShipDate) AS DATETIME) ELSE CAST(MAX(WOPN.EstimatedShipDate) AS DATETIME) END 'estimatedShipDate',  
		ISNULL(tmpWOM.Quantity, 0) 'quantityRequested',
		SUM(ISNULL(STK.QuantityAvailable, 0)) 'quantityAvailable',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOQ.ApprovedDate) AS DATETIME) ELSE CAST(MAX(WOQ.ApprovedDate) AS DATETIME) END 'dateQuoteApproved',
		UPPER(MAX(MSD.Level1Name)) AS level1,      
		UPPER(MAX(MSD.Level2Name)) AS level2,     
		UPPER(MAX(MSD.Level3Name)) AS level3,     
		UPPER(MAX(MSD.Level4Name)) AS level4,     
		UPPER(MAX(MSD.Level5Name)) AS level5,     
		UPPER(MAX(MSD.Level6Name)) AS level6,     
		UPPER(MAX(MSD.Level7Name)) AS level7,     
		UPPER(MAX(MSD.Level8Name)) AS level8,     
		UPPER(MAX(MSD.Level9Name)) AS level9,     
		UPPER(MAX(MSD.Level10Name)) AS level10 ,  
		MAX(WO.MasterCompanyId) MasterCompanyId 
	FROM DBO.WorkOrder WO WITH (NOLOCK)      
		INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId     
		INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID    
		INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID    
		LEFT JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId AND QuoteStatusId = @ApprovedQuoteStatusId
		LEFT JOIN DBO.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WQD.WorkOrderQuoteId  
		LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = WO.CustomerId  
		LEFT JOIN dbo.EntityStructureSetup ES WITH (NOLOCK) ON ES.EntityStructureId=MSD.EntityMSID    
		LEFT JOIN DBO.WorkOrderStage AS WOS WITH (NOLOCK) ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId   
		LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
		LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
		LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId
	    INNER JOIN #tmpMultipleWOMStockline tmpWOM WITH (NOLOCK) ON tmpWOM.[WorkOrderId] = WO.[WorkOrderId]
		INNER JOIN DBO.ItemMaster AS IM WITH (NOLOCK) ON tmpWOM.ItemMasterId = IM.ItemMasterId    
		INNER JOIN DBO.WorkOrderMaterials AS WOM WITH (NOLOCK) ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
		INNER JOIN DBO.Stockline STK WITH (NOLOCK) ON tmpWOM.ItemMasterId = STK.ItemMasterId AND tmpWOM.ConditionId = STK.ConditionId AND STK.IsParent = 1    
	WHERE    
		WO.CustomerId=ISNULL(@CustomerId,WO.CustomerId)
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
     GROUP BY WO.WorkOrderId, tmpWOM.Quantity

	INSERT INTO #AwaitingPartsData
	SELECT DISTINCT 0 AS TotalRecordsCount,    
		WO.WorkOrderId,  
		MAX(UPPER(WO.WorkOrderNum)) 'wonum',
		MAX(UPPER(C.Name)) 'customername',
		MAX(UPPER(WOQ.QuoteNumber)) 'woqnum',
		MAX(UPPER(IM.partnumber)) 'pn',    
		MAX(UPPER(IM.PartDescription)) 'pnDescription',     
		MAX(UPPER(WOS.Stage)) 'stagecode',  
		MAX(WOM.ExtendedCost) 'approvedamount',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST((select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),Max(TZ.Description))) AS DATETIME) ELSE CAST((select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),Max(TZ.Description))) AS DATETIME) END 'opendate',  
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOPN.CustomerRequestDate) AS DATETIME) ELSE CAST(MAX(WOPN.CustomerRequestDate) AS DATETIME) END 'requestdate',    
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOPN.EstimatedShipDate) AS DATETIME) ELSE CAST(MAX(WOPN.EstimatedShipDate) AS DATETIME) END 'estimatedShipDate',
		ISNULL(tmpWOM.Quantity, 0) 'quantityRequested',
		SUM(ISNULL(STK.QuantityAvailable, 0)) 'quantityAvailable',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOQ.ApprovedDate) AS DATETIME) ELSE CAST(MAX(WOQ.ApprovedDate) AS DATETIME) END 'dateQuoteApproved',
		UPPER(MAX(MSD.Level1Name)) AS level1,      
		UPPER(MAX(MSD.Level2Name)) AS level2,     
		UPPER(MAX(MSD.Level3Name)) AS level3,     
		UPPER(MAX(MSD.Level4Name)) AS level4,     
		UPPER(MAX(MSD.Level5Name)) AS level5,     
		UPPER(MAX(MSD.Level6Name)) AS level6,     
		UPPER(MAX(MSD.Level7Name)) AS level7,     
		UPPER(MAX(MSD.Level8Name)) AS level8,     
		UPPER(MAX(MSD.Level9Name)) AS level9,     
		UPPER(MAX(MSD.Level10Name)) AS level10 ,  
		MAX(WO.MasterCompanyId) MasterCompanyId  
	FROM DBO.WorkOrder WO WITH (NOLOCK)      
		INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId     
		INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID    
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
		LEFT JOIN DBO.ItemMaster AS IM WITH (NOLOCK) ON tmpWOM.ItemMasterId = IM.ItemMasterId    
		LEFT JOIN DBO.WorkOrderMaterialsKit AS WOM WITH (NOLOCK) ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId
		LEFT JOIN DBO.Stockline STK WITH (NOLOCK) ON tmpWOM.ItemMasterId = STK.ItemMasterId AND tmpWOM.ConditionId = STK.ConditionId AND STK.IsParent = 1    
	WHERE    
		WO.CustomerId=ISNULL(@CustomerId,WO.CustomerId)
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
     GROUP BY WO.WorkOrderId, tmpWOM.Quantity

 INSERT INTO #AwaitingPartsData
	SELECT DISTINCT 0 AS TotalRecordsCount,    
		SWO.SubWorkOrderId,  
		MAX(UPPER(SWO.SubWorkOrderNo)) 'wonum',
		MAX(UPPER(C.Name)) 'customername',
		MAX(UPPER(WOQ.QuoteNumber)) 'woqnum',
		MAX(UPPER(IM.partnumber)) 'pn',    
		MAX(UPPER(IM.PartDescription)) 'pnDescription',    
		MAX(UPPER(WOS.Stage)) 'stagecode',  
		MAX(WOM.ExtendedCost) 'approvedamount',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST((select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),Max(TZ.Description))) AS DATETIME) ELSE CAST((select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),Max(TZ.Description))) AS DATETIME) END 'opendate',  
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOPN.CustomerRequestDate) AS DATETIME) ELSE CAST(MAX(WOPN.CustomerRequestDate) AS DATETIME) END 'requestdate',    
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOPN.EstimatedShipDate) AS DATETIME) ELSE CAST(MAX(WOPN.EstimatedShipDate) AS DATETIME) END 'estimatedShipDate',
		ISNULL(tmpWOM.Quantity, 0) 'quantityRequested',
		SUM(ISNULL(STK.QuantityAvailable, 0)) 'quantityAvailable',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOQ.ApprovedDate) AS DATETIME) ELSE CAST(MAX(WOQ.ApprovedDate) AS DATETIME) END 'dateQuoteApproved',
		UPPER(MAX(MSD.Level1Name)) AS level1,      
		UPPER(MAX(MSD.Level2Name)) AS level2,     
		UPPER(MAX(MSD.Level3Name)) AS level3,     
		UPPER(MAX(MSD.Level4Name)) AS level4,     
		UPPER(MAX(MSD.Level5Name)) AS level5,     
		UPPER(MAX(MSD.Level6Name)) AS level6,     
		UPPER(MAX(MSD.Level7Name)) AS level7,     
		UPPER(MAX(MSD.Level8Name)) AS level8,     
		UPPER(MAX(MSD.Level9Name)) AS level9,     
		UPPER(MAX(MSD.Level10Name)) AS level10 ,  
		MAX(WO.MasterCompanyId) MasterCompanyId  
	FROM DBO.SubWorkOrder SWO WITH (NOLOCK)    
		INNER JOIN DBO.WorkOrder WO WITH (NOLOCK) ON SWO.WorkOrderId = WO.WorkOrderId 
		INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId     
		INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID    
		INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID    
		INNER JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId AND QuoteStatusId = @ApprovedQuoteStatusId
		LEFT JOIN DBO.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WQD.WorkOrderQuoteId  
		LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = WO.CustomerId  
		LEFT JOIN dbo.EntityStructureSetup ES WITH (NOLOCK) ON ES.EntityStructureId=MSD.EntityMSID    
		LEFT JOIN DBO.WorkOrderStage AS WOS WITH (NOLOCK) ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId   
		LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
		LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
		LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId 
	    INNER JOIN #tmpMultipleSubWOMStockline tmpWOM WITH (NOLOCK) ON tmpWOM.[SubWorkOrderId] = SWO.[SubWorkOrderId]
		INNER JOIN DBO.ItemMaster AS IM WITH (NOLOCK) ON tmpWOM.ItemMasterId = IM.ItemMasterId    
		INNER JOIN DBO.SubWorkOrderMaterials AS WOM WITH (NOLOCK) ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId
		INNER JOIN DBO.Stockline STK WITH (NOLOCK) ON tmpWOM.ItemMasterId = STK.ItemMasterId AND tmpWOM.ConditionId = STK.ConditionId AND STK.IsParent = 1    
	WHERE    
		WO.CustomerId=ISNULL(@CustomerId,WO.CustomerId)
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
     GROUP BY SWO.SubWorkOrderId, tmpWOM.Quantity


	INSERT INTO #AwaitingPartsData
	SELECT DISTINCT 0 AS TotalRecordsCount,    
		SWO.SubWorkOrderId,  
		MAX(UPPER(SWO.SubWorkOrderNo)) 'wonum',
		MAX(UPPER(C.Name)) 'customername',
		MAX(UPPER(WOQ.QuoteNumber)) 'woqnum',
		MAX(UPPER(IM.partnumber)) 'pn',    
		MAX(UPPER(IM.PartDescription)) 'pnDescription',    
		MAX(UPPER(WOS.Stage)) 'stagecode',  
		MAX(WOM.ExtendedCost) 'approvedamount',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST((select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),Max(TZ.Description))) AS DATETIME) ELSE CAST((select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),Max(TZ.Description))) AS DATETIME) END 'opendate',  
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOPN.CustomerRequestDate) AS DATETIME) ELSE CAST(MAX(WOPN.CustomerRequestDate) AS DATETIME) END 'requestdate',    
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOPN.EstimatedShipDate) AS DATETIME) ELSE CAST(MAX(WOPN.EstimatedShipDate) AS DATETIME) END 'estimatedShipDate',  
		ISNULL(tmpWOM.Quantity, 0) 'quantityRequested',
		SUM(ISNULL(STK.QuantityAvailable, 0)) 'quantityAvailable',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN CAST(MAX(WOQ.ApprovedDate) AS DATETIME) ELSE CAST(MAX(WOQ.ApprovedDate) AS DATETIME) END 'dateQuoteApproved',
		UPPER(MAX(MSD.Level1Name)) AS level1,      
		UPPER(MAX(MSD.Level2Name)) AS level2,     
		UPPER(MAX(MSD.Level3Name)) AS level3,     
		UPPER(MAX(MSD.Level4Name)) AS level4,     
		UPPER(MAX(MSD.Level5Name)) AS level5,     
		UPPER(MAX(MSD.Level6Name)) AS level6,     
		UPPER(MAX(MSD.Level7Name)) AS level7,     
		UPPER(MAX(MSD.Level8Name)) AS level8,     
		UPPER(MAX(MSD.Level9Name)) AS level9,     
		UPPER(MAX(MSD.Level10Name)) AS level10 ,  
		MAX(WO.MasterCompanyId) MasterCompanyId  
	FROM DBO.SubWorkOrder SWO WITH (NOLOCK)
		INNER JOIN DBO.WorkOrder WO WITH (NOLOCK) ON SWO.WorkOrderId = WO.WorkOrderId     
		INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId     
		INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID    
		INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID    
		INNER JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId AND QuoteStatusId = @ApprovedQuoteStatusId   
		LEFT JOIN DBO.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WQD.WorkOrderQuoteId  
		LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = WO.CustomerId  
		LEFT JOIN dbo.EntityStructureSetup ES WITH (NOLOCK) ON ES.EntityStructureId=MSD.EntityMSID    
		LEFT JOIN DBO.WorkOrderStage AS WOS WITH (NOLOCK) ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId   
		LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
		LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
		LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId
	    LEFT JOIN #tmpMultipleSubWOMStocklineKit tmpWOM WITH (NOLOCK) ON tmpWOM.[SubWorkOrderId] = SWO.[SubWorkOrderId]
		LEFT JOIN DBO.ItemMaster AS IM WITH (NOLOCK) ON tmpWOM.ItemMasterId = IM.ItemMasterId    
		LEFT JOIN DBO.SubWorkOrderMaterialsKit AS WOM WITH (NOLOCK) ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId
		LEFT JOIN DBO.Stockline STK WITH (NOLOCK) ON tmpWOM.ItemMasterId = STK.ItemMasterId AND tmpWOM.ConditionId = STK.ConditionId AND STK.IsParent = 1   
	WHERE    
		WO.CustomerId=ISNULL(@CustomerId,WO.CustomerId)
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
     GROUP BY SWO.SubWorkOrderId, tmpWOM.Quantity


	IF ISNULL(@PageSize,0)=0    
    BEGIN     
		SELECT @PageSize = COUNT(*)    
		FROM #AwaitingPartsData FC  
		WHERE (quantityRequested - quantityAvailable) > 0
		ORDER BY WorkOrderId DESC    
    END    

	DECLARE @TotalWorkOrder INT = 0, @TotalAwaitingParts INT = 0;

	SELECT @TotalWorkOrder = COUNT(DISTINCT WorkOrderId) FROM #AwaitingPartsData FC
	WHERE (quantityRequested - quantityAvailable) > 0;

	SELECT @TotalAwaitingParts = SUM(quantityRequested - quantityAvailable) FROM #AwaitingPartsData FC
	WHERE (quantityRequested - quantityAvailable) > 0

    SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END    
    SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END    

	IF @IsDownload = 1
	BEGIN
		SELECT COUNT(2) OVER () AS TotalRecordsCount, @TotalWorkOrder AS WorkOrderTotal, @TotalAwaitingParts AS AwaitingPartsTotal, WorkOrderId, wonum, customername, woqnum, pn, pnDescription,stagecode, approvedamount, openDate, requestDate, estimatedShipDate, quantityRequested, quantityAvailable
			, dateQuoteApproved	,level1, level2, level3, level4, level5, level6, level7, level8,level9, level10, (quantityRequested - quantityAvailable) AS missingPieceParts
		FROM #AwaitingPartsData FC  
		WHERE (quantityRequested - quantityAvailable) > 0
		ORDER BY WorkOrderId DESC;
	END
	ELSE
	BEGIN
		SELECT COUNT(2) OVER () AS TotalRecordsCount, @TotalWorkOrder AS WorkOrderTotal, @TotalAwaitingParts AS AwaitingPartsTotal, WorkOrderId, wonum, customername, woqnum, pn, pnDescription,stagecode, approvedamount, openDate, requestDate, estimatedShipDate, quantityRequested, quantityAvailable
			, dateQuoteApproved	,level1, level2, level3, level4, level5, level6, level7, level8,level9, level10, (quantityRequested - quantityAvailable) AS missingPieceParts
		FROM #AwaitingPartsData FC  
		WHERE (quantityRequested - quantityAvailable) > 0
		ORDER BY WorkOrderId DESC  
		OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;
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