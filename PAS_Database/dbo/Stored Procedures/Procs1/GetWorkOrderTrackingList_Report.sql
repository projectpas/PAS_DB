/*************************************************************           
 ** File:   [usprpt_GetWorkOrderBacklogReport]           
 ** Author:   Subhash Saliya  
 ** Description: Get Data for WorkOrderBacklog Report
 ** Purpose:         
 ** Date:   27-April-2022   
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  	Change Description            
 ** --   --------     -------		-------------------------------- 
	1	27-April-2022	 Subhash Saliya 	Move Reports to Angular Side
    2   05/26/2023		HEMANT SALIYA		Updated For WorkOrder Settings
	3   04-SEPT-2023    Ekta Chandegra      Convert text into uppercase
	4   27-AUG-2024     Devendra Shekh      date issue resolved
	5   23-Oct-2024     Sahdev Saliya       Added new failed WO Number in the Work Order Management Report for filter  

EXECUTE   [dbo].[usprpt_GetWorkOrderBacklogReport] 'WO Opened','','','','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60'
**************************************************************/
CREATE     PROCEDURE [dbo].[GetWorkOrderTrackingList_Report] 
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
		@stage VARCHAR(40) = NULL,
		@status VARCHAR(40) = NULL,
		@wotype VARCHAR(40) = NULL,
		@Fromdate DATETIME,
		@Todate DATETIME,
		@Customer VARCHAR(50) = NULL,
		@techNames VARCHAR(50) = NULL,
		@wonum VARCHAR(50) = NULL,
		@partnumber VARCHAR(50) = NULL,
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

      DECLARE @ModuleID INT = 12; -- MS Module ID
	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END

	  SELECT @Fromdate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date' 
			THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Fromdate END,

			@Todate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date' 
			THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Todate END,

			@partnumber=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='PN' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @partnumber END,

			@stage=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Stage' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @stage END,

			@Customer=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Customer END,

			@techNames=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Tech Name' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @techNames END,

			@wonum=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Wo Num' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @wonum END,

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
			SELECT @PageSize=COUNT(*)
			FROM WorkOrder WO WITH(NOLOCK)  
				JOIN dbo.WorkOrderPartNumber WPN WITH(NOLOCK) ON WO.WorkOrderId = WPN.WorkOrderId
				INNER JOIN dbo.WorkOrderTurnArroundTime WTT WITH(NOLOCK) ON WTT.WorkOrderPartNoId = WPN.ID AND WPN.WorkOrderStageId = WTT.CurrentStageId
				left JOIN dbo.WorkOrderQuoteDetails woq WITH(NOLOCK) ON woq.WOPartNoId = WPN.ID  
				JOIN dbo.WorkOrderType WT WITH(NOLOCK) ON WO.WorkOrderTypeId = WT.Id  
				JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WPN.ID = WOWF.WorkOrderPartNoId  
				JOIN dbo.WorkOrderStatus WOS WITH(NOLOCK) ON WOS.Id = WPN.WorkOrderStatusId  
				JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId  
				LEFT JOIN dbo.Stockline STL WITH(NOLOCK) ON WPN.StockLineId = STL.StockLineId
				LEFT JOIN dbo.WorkOrderSettings wost WITH(NOLOCK) ON wost.MasterCompanyId = WO.MasterCompanyId AND WO.WorkOrderTypeId = wost.WorkOrderTypeId
				JOIN dbo.Priority PR WITH(NOLOCK) ON WPN.WorkOrderPriorityId = PR.PriorityId  
				JOIN dbo.WorkOrderStage WOSG WITH(NOLOCK) ON WTT.CurrentStageId = WOSG.WorkOrderStageId and wosg.IncludeInStageReport=1   
				LEFT JOIN dbo.Employee EMP WITH(NOLOCK) ON EMP.EmployeeId = WPN.TechnicianId
				LEFT JOIN dbo.Employee EMPStage WITH(NOLOCK) ON EMPStage.EmployeeId = WOSG.ManagerId
				LEFT JOIN dbo.Employee EMPsales WITH(NOLOCK) ON EMPsales.EmployeeId = WO.SalesPersonId
				LEFT JOIN dbo.Employee EMPcsr WITH(NOLOCK) ON EMPcsr.EmployeeId = WO.CSRId 
				INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WPN.ID
				LEFT JOIN dbo.EmployeeStation EMPS WITH(NOLOCK) ON WPN.TechStationId = EMPS.EmployeeStationId				
			WHERE CAST(WTT.StatusChangedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)
				AND	WO.CustomerId=ISNULL(@Customer,WO.CustomerId) 
				AND (ISNULL(@stage,'')='' OR WTT.CurrentStageId IN(SELECT value FROM String_split(ISNULL(@stage,''), ',')))
				AND (@techNames IS NULL OR WPN.TechnicianId = @techNames)
				AND (@wonum IS NULL OR WO.WorkOrderId = @wonum)
				AND	WPN.ItemMasterId=ISNULL(@partnumber,WPN.ItemMasterId) 
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
				MAX(WO.WorkOrderNum) AS WorkOrderNum,   
				MAX(WO.WorkOrderId) AS WorkOrderId,
				MAX(WPN.ID) AS WorkorderPartId,
				MAX(WO.CustomerId) AS CustomerId, 
				MAX(IM.ItemMasterId) AS ItemMasterId, 
				MAX(IM.partnumber) AS PartNos,  
				MAX(IM.partnumber) AS PartNoType,  
				MAX(IM.PartDescription) AS PNDescription,  
				MAX(IM.PartDescription) AS PNDescriptionType,  
				MAX(WPN.WorkScope) AS WorkScope,  
				MAX(WPN.WorkScope) AS WorkScopeType,  
				MAX(PR.Description) As Priority,    
				MAX(PR.Description) As PriorityType,   
				UPPER(MAX(WO.CustomerName)) AS CustomerName,  
				UPPER(MAX(WO.CustomerType)) AS CustomerType,       
				UPPER(MAX(WOSG.Code + '-' + WOSG.Stage)) AS  Stage,  
				UPPER(MAX(WOSG.Code + '-' + WOSG.Stage)) AS  StageType,  
				UPPER(MAX(WOS.Description)) AS WorkOrderStatus,  
				UPPER(MAX(WOS.Description)) AS WorkOrderStatusType,  
				MAX(WO.OpenDate) AS OpenDate, 
				--CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(MAX(WPN.CustomerRequestDate), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), MAX(WPN.CustomerRequestDate), 107) END 'CustomerRequestDateType', 
				CASE WHEN ISNULL(@IsDownload,0) = 0 THEN MAX(WPN.CustomerRequestDate) ELSE CONVERT(VARCHAR(50), MAX(WPN.CustomerRequestDate), 107) END 'CustomerRequestDateType', 
      			--CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(MAX(WPN.PromisedDate), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), MAX(WPN.PromisedDate), 107) END 'PromisedDateType',  
      			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN MAX(WPN.PromisedDate) ELSE CONVERT(VARCHAR(50), MAX(WPN.PromisedDate), 107) END 'PromisedDateType',  
				--CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(MAX(WPN.EstimatedShipDate), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), MAX(WPN.EstimatedShipDate), 107) END 'EstimatedShipDateType', 
				CASE WHEN ISNULL(@IsDownload,0) = 0 THEN MAX(WPN.EstimatedShipDate) ELSE CONVERT(VARCHAR(50), MAX(WPN.EstimatedShipDate), 107) END 'EstimatedShipDateType', 
				((Select top 1 ShipDate from dbo.WorkOrderShipping wosp  WITH(NOLOCK) where WorkOrderId = WO.WorkOrderId order by WorkOrderShippingId desc))as EstimatedCompletionDate,  
				((Select top 1 ShipDate from dbo.WorkOrderShipping wosp  WITH(NOLOCK) where WorkOrderId = WO.WorkOrderId order by WorkOrderShippingId desc))as EstimatedCompletionDateType,  
				(isnull((sum(WTT.[Days])+ (sum(WTT.[Hours])/24)+ (sum(WTT.[Mins])/1440)),0)) + ISNULL(DATEDIFF(day, Max(WTT.StatusChangedDate), GETDATE()), 0) as TotalDaysinStage,
				UPPER(MAX(EMPStage.FirstName) + ' ' + MAX(EMPStage.LastName)) AS ManagerName,
				MAX(IM.ItemGroup) as ItemGroup,
				UPPER(MAX(EMPsales.FirstName) + ' ' + MAX(EMPsales.LastName)) AS SalespersonName,
				UPPER(MAX(EMPcsr.FirstName) + ' ' + MAX(EMPcsr.LastName)) AS CSRName,
				MAX(dbo.FN_GetTatStandardDays(WPN.Id)) AS TATDaysStandard,
				MAX(dbo.FN_GetTatCurrentDays(WPN.Id)) AS TATDaysCurrent,
				DATEDIFF(day, Max(WPN.ReceivedDate), GETDATE()) AS woage,
				MAX(WPN.WorkOrderStatusId) AS WorkOrderStatusId,  
				UPPER(MAX(WT.Description)) AS WorkOrderType,  
				UPPER(MAX(EMP.FirstName) + ' ' + MAX(EMP.LastName)) AS TechName,  
				UPPER(MAX(EMPS.StationName)) AS TechStation,  
				UPPER(MAX(STL.SerialNumber)) AS SerialNumber,  
				UPPER(MAX(WPN.CustomerReference)) AS CustomerReference,  
				UPPER(MAX(WPN.CustomerReference)) AS CustomerReferenceType,
			   (case when MAX(dbo.FN_GetTatCurrentDays(WPN.Id)) >= MAX(dbo.FN_GetTatStandardDays(WPN.Id)) then UPPER('red') when  MAX(dbo.FN_GetTatCurrentDays(WPN.Id)) >=MAX(dbo.FN_GetTatStandardDays(WPN.Id)) -Max(Isnull(wost.StandardTurntimeDays,0)) then UPPER('yellow') when   MAX(dbo.FN_GetTatCurrentDays(WPN.Id)) < MAX(dbo.FN_GetTatStandardDays(WPN.Id)) -Max(Isnull(wost.StandardTurntimeDays,0)) then UPPER('green') else ''  end) as colourcode , 
				MAX(case when woq.QuoteMethod =1 then isnull(CommonFlatRate,0) else isnull((woq.FreightFlatBillingAmount+woq.ChargesFlatBillingAmount+woq.LaborFlatBillingAmount+woq.MaterialFlatBillingAmount),0) end) as Quoteamount,
				WTT.CurrentStageId as WorkOrderStageId,
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
			INNER JOIN dbo.WorkOrderTurnArroundTime WTT WITH(NOLOCK) ON WTT.WorkOrderPartNoId = WPN.ID AND WPN.WorkOrderStageId = WTT.CurrentStageId
			left JOIN dbo.WorkOrderQuoteDetails woq WITH(NOLOCK) ON woq.WOPartNoId = WPN.ID  
			JOIN dbo.WorkOrderType WT WITH(NOLOCK) ON WO.WorkOrderTypeId = WT.Id  
			JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WPN.ID = WOWF.WorkOrderPartNoId  
			JOIN dbo.WorkOrderStatus WOS WITH(NOLOCK) ON WOS.Id = WPN.WorkOrderStatusId  
			JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId  
			LEFT JOIN dbo.Stockline STL WITH(NOLOCK) ON WPN.StockLineId = STL.StockLineId
			LEFT JOIN dbo.WorkOrderSettings wost WITH(NOLOCK) ON wost.MasterCompanyId = WO.MasterCompanyId AND WO.WorkOrderTypeId = wost.WorkOrderTypeId
			JOIN dbo.Priority PR WITH(NOLOCK) ON WPN.WorkOrderPriorityId = PR.PriorityId  
			INNER JOIN dbo.WorkOrderStage WOSG WITH(NOLOCK) ON WTT.CurrentStageId = WOSG.WorkOrderStageId and wosg.IncludeInStageReport=1   
			LEFT JOIN dbo.Employee EMP WITH(NOLOCK) ON EMP.EmployeeId = WPN.TechnicianId
			LEFT JOIN dbo.Employee EMPStage WITH(NOLOCK) ON EMPStage.EmployeeId = WOSG.ManagerId
			LEFT JOIN dbo.Employee EMPsales WITH(NOLOCK) ON EMPsales.EmployeeId = WO.SalesPersonId
			LEFT JOIN dbo.Employee EMPcsr WITH(NOLOCK) ON EMPcsr.EmployeeId = WO.CSRId 
			LEFT JOIN dbo.EmployeeStation EMPS WITH(NOLOCK) ON WPN.TechStationId = EMPS.EmployeeStationId
       		INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WPN.ID
		WHERE CAST(WTT.StatusChangedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE) and WO.IsDeleted = 0 and WO.IsActive = 1
				AND	WO.CustomerId=ISNULL(@Customer,WO.CustomerId) 
				AND (ISNULL(@stage,'')='' OR WTT.CurrentStageId IN(SELECT value FROM String_split(ISNULL(@stage,''), ','))) 
			    AND (@techNames IS NULL OR WPN.TechnicianId = @techNames)
				AND (@wonum IS NULL OR WO.WorkOrderId = @wonum)
				AND	WPN.ItemMasterId=ISNULL(@partnumber,WPN.ItemMasterId) 
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
			 GROUP BY WPN.ID, WTT.CurrentStageId,WO.WorkOrderId  ORDER BY Max(WOSG.Sequence),WTT.CurrentStageId,WO.WorkOrderId Desc
			OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;

    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
  ROLLBACK TRANSACTION
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usprpt_GetWorkOrderBacklogReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@stage, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
            '@Parameter6 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
            '@Parameter7 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +
            '@Parameter8 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +
            '@Parameter8 = ''' + CAST(ISNULL(@stage, '') AS varchar),
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