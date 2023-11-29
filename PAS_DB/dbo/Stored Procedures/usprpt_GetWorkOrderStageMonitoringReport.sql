/*************************************************************
 ** File:   [usprpt_GetWorkOrderStageMonitoringReport]
 ** Author:  
 ** Description: Get Data for Work-Order Stage Monitoring Report
 ** Purpose:
 ** Date:  

 ** PARAMETERS:
         
 ** RETURN VALUE:
  
 **************************************************************
  ** Change History           
 **************************************************************
 ** SN  Date			Author  			Change Description
 ** --  --------		-------				--------------------------------
	1	25-AUG-2023 	Ekta Chandegra		Convert text into uppercase
	2   25-Aug-2023     Bhargav Saliya      Conver Dates UTC to Legal Entity Time Zone
**************************************************************/
CREATE   PROCEDURE [dbo].[usprpt_GetWorkOrderStageMonitoringReport]
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
		@Fromdate DATETIME,
		@Todate DATETIME,
		@FromStage VARCHAR(50) = NULL,
		@ToStage VARCHAR(50) = NULL,
		@IgnoreDuplicate VARCHAR(200) = NULL,
		@Employee VARCHAR(50) = NULL,
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
		@ApprovedQuoteStatusId BIGINT = 0

		SELECT @ApprovedQuoteStatusId = WorkOrderQuoteStatusId FROM WorkOrderQuoteStatus WHERE [Description] = 'Approved';

		DECLARE @ModuleID INT = 12; -- MS Module ID
		SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END

		SELECT @Fromdate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date' 
			THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Fromdate END,

			@Todate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date' 
			THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Todate END,

			@FromStage=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Stage' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @FromStage END,

			@ToStage=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Stage' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @ToStage END,

			@IgnoreDuplicate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(200)')='Ignore Duplicate Work Order' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(200)') ELSE @IgnoreDuplicate END,

			@Employee=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Employee' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Employee END,

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
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10 end

		FROM @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)
	 
		IF ISNULL(@PageSize,0)=0
		BEGIN 
			SELECT @PageSize = COUNT(*)
			FROM WorkOrder WO WITH(NOLOCK)  
			INNER JOIN dbo.WorkOrderPartNumber WPN WITH(NOLOCK) ON WO.WorkOrderId = WPN.WorkOrderId
			LEFT JOIN dbo.WorkOrderTurnArroundTime WTT WITH(NOLOCK) ON WTT.WorkOrderPartNoId = WPN.ID --AND WPN.WorkOrderStageId = WTT.CurrentStageId
			left JOIN dbo.WorkOrderQuote workOrderQ WITH(NOLOCK) ON workOrderQ.WorkOrderId = WO.WorkOrderId
			left JOIN dbo.WorkOrderQuoteDetails woq WITH(NOLOCK) ON woq.WOPartNoId = WPN.ID  
			JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId  
			LEFT JOIN dbo.Stockline STL WITH(NOLOCK) ON WPN.StockLineId = STL.StockLineId
			LEFT JOIN dbo.WorkOrderStage WOSG_Old WITH(NOLOCK) ON WTT.OldStageId = WOSG_Old.WorkOrderStageId-- and WOSG_Old.IncludeInStageReport = 1   
			LEFT JOIN dbo.WorkOrderStage WOSG WITH(NOLOCK) ON WTT.CurrentStageId = WOSG.WorkOrderStageId-- and wosg.IncludeInStageReport = 1
			LEFT JOIN dbo.WorkOrderStage WOSG_Curr WITH(NOLOCK) ON WPN.WorkOrderStageId = WOSG_Curr.WorkOrderStageId-- and WOSG_Curr.IncludeInStageReport = 1
       		INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WPN.ID
			WHERE CAST(WTT.StatusChangedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE) 
				AND WO.IsDeleted = 0 AND WO.IsActive = 1
				AND	(WTT.ChangedBy) = ISNULL(@Employee, WTT.ChangedBy) 
				AND ((ISNULL(@FromStage, '') = '' OR WOSG_Old.WorkOrderStageId = @FromStage) AND (ISNULL(@ToStage, '') = '' OR WOSG.WorkOrderStageId = @ToStage))
				AND WO.mastercompanyid = @MasterCompanyId AND MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))
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
			END

			SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
			SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END

			SELECT COUNT(1) OVER () AS TotalRecordsCount,
				MAX(WPN.ID) AS workorderPartId,  
				UPPER(MAX(WO.CustomerName)) AS customername,  
				UPPER(MAX(IM.partnumber)) AS pn, 
				UPPER(MAX(IM.partnumber)) AS partNos, 
				UPPER(MAX(IM.PartDescription)) AS pndescription, 
				UPPER(MAX(STL.SerialNumber)) AS serialnum,  
				UPPER(MAX(WPN.WorkScope)) AS workscope,
				MAX(WO.WorkOrderId) AS workOrderId,   
				UPPER(MAX(WO.WorkOrderNum)) AS wonum,   
				UPPER(MAX(WO.WorkOrderNum)) AS workOrderNum,   
				(SELECT UPPER(WOS_From.Code + '-' + WOS_From.Stage) FROM DBO.WorkOrderStage WOS_From WITH (NOLOCK) WHERE WOS_From.WorkOrderStageId = WTT.OldStageId) AS fromstage,
				(SELECT UPPER(WOS_To.Code + '-' + WOS_To.Stage) FROM DBO.WorkOrderStage WOS_To WITH (NOLOCK) WHERE WOS_To.WorkOrderStageId = WTT.CurrentStageId) AS tostage,
				UPPER(MAX(WTT.ChangedBy)) AS employee, 
				UPPER(MAX(WOSG_Curr.Code + '-' + WOSG_Curr.Stage)) AS currentstage,
				CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(MAX(WPN.ReceivedDate), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), MAX(WPN.ReceivedDate), 107) END 'recdate', 
				CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),MAX(TZ.Description))), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),MAX(TZ.Description))), 107) END 'opendate', 
				CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(MAX(workOrderQ.OpenDate), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), MAX(workOrderQ.OpenDate), 107) END 'quotedate', 
				MAX(workOrderQ.QuoteNumber) AS quotenum, 
				MAX(case when woq.QuoteMethod =1 then isnull(CommonFlatRate,0) else isnull((woq.FreightFlatBillingAmount+woq.ChargesFlatBillingAmount+woq.LaborFlatBillingAmount+woq.MaterialFlatBillingAmount),0) end) as quoteamount,
				MAX(CASE WHEN workOrderQ.QuoteStatusId = @ApprovedQuoteStatusId THEN (case when woq.QuoteMethod =1 then isnull(CommonFlatRate,0) else isnull((woq.FreightFlatBillingAmount+woq.ChargesFlatBillingAmount+woq.LaborFlatBillingAmount+woq.MaterialFlatBillingAmount),0) end) ELSE 0 END) as quoteapprovalamount,
				UPPER(MAX(MSD.Level1Name)) AS level1,  
				UPPER(MAX(MSD.Level2Name)) AS level2, 
				UPPER(MAX(MSD.Level3Name)) AS level3, 
				UPPER(MAX(MSD.Level4Name)) AS level4, 
				UPPER(MAX(MSD.Level5Name)) AS level5, 
				UPPER(MAX(MSD.Level6Name)) AS level6, 
				UPPER(MAX(MSD.Level7Name)) AS level7, 
				UPPER(MAX(MSD.Level8Name)) AS level8, 
				UPPER(MAX(MSD.Level9Name)) AS level9, 
				UPPER(MAX(MSD.Level10Name)) AS level10
			FROM WorkOrder WO WITH(NOLOCK)  
			INNER JOIN dbo.WorkOrderPartNumber WPN WITH(NOLOCK) ON WO.WorkOrderId = WPN.WorkOrderId
			LEFT JOIN dbo.WorkOrderTurnArroundTime WTT WITH(NOLOCK) ON WTT.WorkOrderPartNoId = WPN.ID --AND WPN.WorkOrderStageId = WTT.CurrentStageId
			left JOIN dbo.WorkOrderQuote workOrderQ WITH(NOLOCK) ON workOrderQ.WorkOrderId = WO.WorkOrderId
			left JOIN dbo.WorkOrderQuoteDetails woq WITH(NOLOCK) ON woq.WOPartNoId = WPN.ID  
			JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId  
			LEFT JOIN dbo.Stockline STL WITH(NOLOCK) ON WPN.StockLineId = STL.StockLineId
			LEFT JOIN dbo.WorkOrderStage WOSG_Old WITH(NOLOCK) ON WTT.OldStageId = WOSG_Old.WorkOrderStageId-- and WOSG_Old.IncludeInStageReport = 1   
			LEFT JOIN dbo.WorkOrderStage WOSG WITH(NOLOCK) ON WTT.CurrentStageId = WOSG.WorkOrderStageId-- and wosg.IncludeInStageReport = 1
			LEFT JOIN dbo.WorkOrderStage WOSG_Curr WITH(NOLOCK) ON WPN.WorkOrderStageId = WOSG_Curr.WorkOrderStageId-- and WOSG_Curr.IncludeInStageReport = 1
       		INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WPN.ID

			LEFT JOIN [dbo].EntityStructureSetup ESS WITH(NOLOCK) ON WPN.ManagementStructureId = ESS.EntityStructureId
			LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ESS.Level1Id = MSL.ID
			LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
			LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId
			WHERE CAST(WTT.StatusChangedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE) 
				AND WO.IsDeleted = 0 AND WO.IsActive = 1
				AND	(WTT.ChangedBy) = ISNULL(@Employee, WTT.ChangedBy) 
				AND ((ISNULL(@FromStage, '') = '' OR WOSG_Old.WorkOrderStageId = @FromStage) AND (ISNULL(@ToStage, '') = '' OR WOSG.WorkOrderStageId = @ToStage))
				AND WO.mastercompanyid = @MasterCompanyId AND MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))
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
			GROUP BY WPN.ID,
			CASE WHEN (ISNULL(@IgnoreDuplicate, '') = 'true' OR ISNULL(@IgnoreDuplicate, '') = '1') THEN WTT.WOTATId ELSE '' END,  WTT.OldStageId, WTT.CurrentStageId
			ORDER BY Max(WOSG.Sequence), WTT.CurrentStageId Desc
			OFFSET((@PageNumber - 1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;
    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION

    IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
    BEGIN
      DROP TABLE #managmetnstrcture
    END

    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[usprpt_GetWorkOrderStageMonitoringReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@Employee, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
            '@Parameter6 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
            '@Parameter7 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +
            '@Parameter8 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),
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
    DROP TABLE #ManagmetnStrcture
  END
END