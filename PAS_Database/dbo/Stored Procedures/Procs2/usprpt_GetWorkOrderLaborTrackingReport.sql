/*************************************************************           
 ** File:   [usprpt_GetWorkOrderLaborTrackingReport]           
 ** Author:   
 ** Description: Get Data for Work-Order Labor Tracking Report
 ** Purpose:         
 ** Date:     
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date				Author  			Change Description            
 ** --   --------		-------				--------------------------------          
	1	25-AUG-2023		Ekta Chandegra		Convert text into uppercase
	2	29-MARCH-2024	Ekta Chandegra		IaDeleted and IsActive flag is added
	3	13-SEP-2024		Devendra Shekh		employee select issue resolved
**************************************************************/
CREATE     PROCEDURE [dbo].[usprpt_GetWorkOrderLaborTrackingReport] 
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
		@customername VARCHAR(40) = NULL,
		@Fromdate DATETIME,
		@Todate DATETIME,
		@WorkOrderId BIGINT = NULL,
		@EmployeeId BIGINT = NULL,
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

			@WorkOrderId=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='WO Num' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @WorkOrderId END,

			@EmployeeId=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Employee' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @EmployeeId END,

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
				 FROM dbo.WorkOrderLaborTracking WOT WITH(NOLOCK) 
				    INNER JOIN dbo.Task T WITH(NOLOCK) on WOT.TaskId = T.TaskId 
					INNER JOIN dbo.WorkOrderLabor WOL WITH(NOLOCK) on WOT.WorkOrderLaborId = WOL.WorkOrderLaborId
					INNER JOIN dbo.WorkOrderLaborHeader LH WITH(NOLOCK) on WOL.WorkOrderLaborHeaderId = LH.WorkOrderLaborHeaderId
					INNER JOIN dbo.WorkOrder WO WITH(NOLOCK) on LH.WorkOrderId = WO.WorkOrderId
					INNER JOIN dbo.WorkOrderWorkFlow WOF WITH(NOLOCK) on LH.WorkFlowWorkOrderId = WOF.WorkFlowWorkOrderId
					INNER JOIN dbo.WorkOrderPartNumber WPN WITH(NOLOCK) ON WOF.WorkOrderPartNoId = WPN.ID  
					INNER JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId  
					INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WPN.ID
					LEFT JOIN dbo.TaskStatus TS WITH(NOLOCK) ON WOL.TaskStatusId = TS.TaskStatusId
					LEFT JOIN dbo.Employee EMP WITH(NOLOCK) ON EMP.EmployeeId = WOT.EmployeeId 		
					LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID

				WHERE (CAST(WOT.StartTime AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE) OR CAST(WOT.EndTime AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE))
					AND WO.mastercompanyid = @mastercompanyid
					AND WO.IsActive = 1 AND WO.IsDeleted = 0
					AND (@EmployeeId IS NULL OR WOT.EmployeeId = @EmployeeId)
					AND (@WorkOrderId IS NULL OR WO.WorkOrderId = @WorkOrderId)
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

		--INSERT INTO #tmpLaborTracking
		;WITH Result AS(
			SELECT 
			--COUNT(1) OVER () AS TotalRecordsCount,
			UPPER(WO.WorkOrderNum) 'woNum',
			UPPER(IM.partnumber) 'pn',
			UPPER(IM.PartDescription) 'pnDescription',
			UPPER(IM.ManufacturerName) 'manufacturerName',
			UPPER(T.[Description]) 'task',
			UPPER(TS.[Description]) 'taskStatus',
			

			--CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (WOL.StatusChangedDate,TZ.Description)), 'MM/dd/yyyy hh:mm tt') ELSE CONVERT(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (WOL.StatusChangedDate,TZ.Description)), 100) END 'statusChangeDate', 
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (WOL.StatusChangedDate,TZ.Description)), 'MM/dd/yyyy hh:mm tt') ELSE CONVERT(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (WOL.StatusChangedDate,TZ.Description)), 100) END 'statusChangeDate', 
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (WOT.StartTime,TZ.Description)), 'MM/dd/yyyy hh:mm tt') ELSE CONVERT(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (WOT.StartTime,TZ.Description)), 100) END 'startDate', 
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (WOT.EndTime,TZ.Description)), 'MM/dd/yyyy hh:mm tt') ELSE CONVERT(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (WOT.EndTime,TZ.Description)), 100) END 'endDate', 
			--UPPER(EMP.FirstName + ' ' + EMP.LastName) 'employee',
			format(WOT.TotalHours,'00') 'totalHours', 
		   format(WOT.TotalMinutes,'00') 'totalMinutes',
			UPPER(MSD.Level1Name) AS level1,  
			UPPER(MSD.Level2Name) AS level2, 
			UPPER(MSD.Level3Name) AS level3, 
			UPPER(MSD.Level4Name) AS level4, 
			UPPER(MSD.Level5Name) AS level5, 
			UPPER(MSD.Level6Name) AS level6, 
			UPPER(MSD.Level7Name) AS level7, 
			UPPER(MSD.Level8Name) AS level8, 
			UPPER(MSD.Level9Name) AS level9, 
			UPPER(MSD.Level10Name) AS level10,
			UPPER(EMP.FirstName) + ' ' + UPPER(EMP.LastName) As employeeName
		 FROM dbo.WorkOrderLaborTracking WOT WITH(NOLOCK) 
				    INNER JOIN dbo.Task T WITH(NOLOCK) on WOT.TaskId = T.TaskId 
					INNER JOIN dbo.WorkOrderLabor WOL WITH(NOLOCK) on WOT.WorkOrderLaborId = WOL.WorkOrderLaborId
					INNER JOIN dbo.WorkOrderLaborHeader LH WITH(NOLOCK) on WOL.WorkOrderLaborHeaderId = LH.WorkOrderLaborHeaderId
					INNER JOIN dbo.WorkOrder WO WITH(NOLOCK) on LH.WorkOrderId = WO.WorkOrderId
					INNER JOIN dbo.WorkOrderWorkFlow WOF WITH(NOLOCK) on LH.WorkFlowWorkOrderId = WOF.WorkFlowWorkOrderId
					INNER JOIN dbo.WorkOrderPartNumber WPN WITH(NOLOCK) ON WOF.WorkOrderPartNoId = WPN.ID  
					INNER JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId  
					INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WPN.ID
					LEFT JOIN dbo.TaskStatus TS WITH(NOLOCK) ON WOL.TaskStatusId = TS.TaskStatusId
					LEFT JOIN dbo.Employee EMP WITH(NOLOCK) ON EMP.EmployeeId = WOT.EmployeeId 		
					LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
					LEFT JOIN DBO.ManagementStructureLevel MSL ON MSL.ID = ES.Level1Id
					LEFT JOIN DBO.LegalEntity LE ON LE.LegalEntityId = MSL.LegalEntityId
					LEFT JOIN DBO.TimeZone TZ ON TZ.TimeZoneId = LE.TimeZoneId

			WHERE 
					--(CAST(WOT.StartTime AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE) OR CAST(WOT.EndTime AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)) AND
					(CAST(WOL.StatusChangedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)) AND
					WO.mastercompanyid = @mastercompanyid
					AND WO.IsActive = 1 AND WO.IsDeleted = 0
					AND (@EmployeeId IS NULL OR WOT.EmployeeId = @EmployeeId)
					AND (@WorkOrderId IS NULL OR WO.WorkOrderId = @WorkOrderId)
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
			
			UNION ALL 

			SELECT 
			--COUNT(1) OVER () AS TotalRecordsCount,
			UPPER(WO.WorkOrderNum) 'woNum',
			UPPER(IM.partnumber) 'pn',
			UPPER(IM.PartDescription) 'pnDescription',
			UPPER(IM.ManufacturerName) 'manufacturerName',
			UPPER(T.[Description]) 'task',
			UPPER(TS.[Description]) 'taskStatus',
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (WOL.StatusChangedDate,TZ.Description)), 'MM/dd/yyyy hh:mm tt') ELSE CONVERT(VARCHAR(50),(select [dbo].[ConvertUTCtoLocal] (WOL.StatusChangedDate,TZ.Description)), 100) END 'statusChangeDate', 
			NULL AS 'startDate', 
			NULL AS 'endDate', 
			--UPPER(EMP.FirstName + ' ' + EMP.LastName) 'employee',
			format(FLOOR(WOL.Adjustments),'00') 'totalHours', 
			format(convert(int,(WOL.Adjustments - FLOOR(WOL.Adjustments))* 100),'00') 'totalMinutes',
			--format(WOT.TotalHours,'00') 'totalHours', 
		 --  format(WOT.TotalMinutes,'00') 'totalMinutes',
			UPPER(MSD.Level1Name) AS level1,  
			UPPER(MSD.Level2Name) AS level2, 
			UPPER(MSD.Level3Name) AS level3, 
			UPPER(MSD.Level4Name) AS level4, 
			UPPER(MSD.Level5Name) AS level5, 
			UPPER(MSD.Level6Name) AS level6, 
			UPPER(MSD.Level7Name) AS level7, 
			UPPER(MSD.Level8Name) AS level8, 
			UPPER(MSD.Level9Name) AS level9, 
			UPPER(MSD.Level10Name) AS level10,
			UPPER(EMP.FirstName) + ' ' + UPPER(EMP.LastName) As employeeName
		 FROM dbo.WorkOrderLabor WOL WITH(NOLOCK) 
				    INNER JOIN dbo.Task T WITH(NOLOCK) on WOL.TaskId = T.TaskId 
					--INNER JOIN dbo.WorkOrderLabor WOL WITH(NOLOCK) on WOT.WorkOrderLaborId = WOL.WorkOrderLaborId
					INNER JOIN dbo.WorkOrderLaborHeader LH WITH(NOLOCK) on WOL.WorkOrderLaborHeaderId = LH.WorkOrderLaborHeaderId
					INNER JOIN dbo.WorkOrder WO WITH(NOLOCK) on LH.WorkOrderId = WO.WorkOrderId
					INNER JOIN dbo.WorkOrderWorkFlow WOF WITH(NOLOCK) on LH.WorkFlowWorkOrderId = WOF.WorkFlowWorkOrderId
					INNER JOIN dbo.WorkOrderPartNumber WPN WITH(NOLOCK) ON WOF.WorkOrderPartNoId = WPN.ID  
					INNER JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId  
					INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WPN.ID
					LEFT JOIN dbo.TaskStatus TS WITH(NOLOCK) ON WOL.TaskStatusId = TS.TaskStatusId
					LEFT JOIN dbo.Employee EMP WITH(NOLOCK) ON EMP.EmployeeId = WOL.EmployeeId 		
					LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
					LEFT JOIN DBO.ManagementStructureLevel MSL ON MSL.ID = ES.Level1Id
					LEFT JOIN DBO.LegalEntity LE ON LE.LegalEntityId = MSL.LegalEntityId
					LEFT JOIN DBO.TimeZone TZ ON TZ.TimeZoneId = LE.TimeZoneId
			WHERE  
					--(CAST(WOL.StartDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE) OR CAST(WOL.EndDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)) AND
					(CAST(WOL.StatusChangedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)) AND							
					WO.mastercompanyid = @mastercompanyid
					AND WO.IsActive = 1 AND WO.IsDeleted = 0
					AND (@EmployeeId IS NULL OR WOL.EmployeeId = @EmployeeId)
					AND (@WorkOrderId IS NULL OR WO.WorkOrderId = @WorkOrderId)
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
					AND WOL.Adjustments >0
					AND (SELECT COUNT(1) FROM dbo.WorkOrderLaborTracking WOT WITH(NOLOCK) WHERE WOL.WorkOrderLaborId = WOT.WorkOrderLaborId) > 0

		--ORDER BY IM.partnumber
		--OFFSET((@PageNumber-1) * @PageSize) ROWS FETCH NEXT @PageSize ROWS ONLY
		)
		Select * INTO #tmpLaborTracking from  Result  

	SELECT DISTINCT COUNT(1) OVER () AS TotalRecordsCount, * FROM #tmpLaborTracking
	ORDER BY pn
	OFFSET((@PageNumber-1) * @PageSize) ROWS FETCH NEXT @PageSize ROWS ONLY

    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION

    IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
    BEGIN
      DROP TABLE #managmetnstrcture
    END

    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetWorkOrderBillingReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@customername, '') AS varchar(100)) +
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