/*************************************************************           
 ** File:   [GetTravelerTaskList]           
 ** Author:   Moin Bloch
 ** Description: Get Search Data for Work Order Traveler Task List    
 ** Purpose:         
 ** Date:   21-01-2025    
 ** PARAMETERS:                    
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    21/01/2025   Moin Bloch		Created
    2    18/02/2025   Devendra Shekh    Added Memo to Filter/Sorting
    3    16/04/2025   Devendra Shekh    Added IsLaborTrackingTurnedOff to select

	EXEC dbo.GetTravelerTaskList 10,1,'CreatedDate',-1,'','','','','',0,1,2
	exec dbo.GetTravelerTaskList @PageSize=15,@PageNumber=1,@SortColumn=default,@SortOrder=-1,@GlobalFilter=N'',@WONumber=default,@EmployeeName=default,@TaskStatusName=default,@TaskName=default,@IsDeleted=0,@MasterCompanyId=1,@EmployeeId=219
**************************************************************/ 

CREATE   PROCEDURE [dbo].[GetTravelerTaskList]
@PageSize INT,
@PageNumber INT,
@SortColumn VARCHAR(50)=NULL,
@SortOrder INT,
@GlobalFilter VARCHAR(50) = NULL,
@WONumber VARCHAR(50)=NULL,
@EmployeeName VARCHAR(50)=NULL,
@TaskStatusName VARCHAR(50)=NULL,
@TaskName VARCHAR(50)=NULL,
@IsDeleted BIT= NULL,	
@MasterCompanyId BIGINT, 
@EmployeeId BIGINT
AS
BEGIN
		SET NOCOUNT ON;
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		DECLARE @RecordFrom INT;
		DECLARE @IsActive BIT=1
		DECLARE @Count INT;
		
		SET @RecordFrom = (@PageNumber-1) * @PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			SET @SortColumn=UPPER(@SortColumn)
		END		
		BEGIN TRY

			;With Result AS(
				SELECT woh.[WorkOrderId],	
				      wfwo.[WorkOrderPartNoId],
					   woh.[WorkFlowWorkOrderId],
				        wo.[WorkOrderNum],
				       wol.[AdjustedHours],
                       wol.[Adjustments],
                       wol.[BillableId],
                       wol.[CreatedBy],
                       wol.[CreatedDate],
                       wol.[EmployeeId],
                       wol.[EndDate],
                       wol.[ExpertiseId],
                       wol.[TaskStatusId],
					   TS.[Description] [TaskStatusName],
                       wol.[StatusChangedDate],					   
                       wol.[IsFromWorkFlow],
                       wol.[Memo],
                       wol.[StartDate],
                       wol.[TaskId],
					   wol.[WorkOrderLaborHeaderId],
                       wol.[WorkOrderLaborId],                    
                       wol.[TotalCostPerHour],
                       wol.[TotalCost],
					   wol.[IsBegin],
					   CASE WHEN (SELECT COUNT([WorkOrderLaborTrackingId]) FROM [dbo].[WorkOrderLaborTracking] wolt WITH(NOLOCK) WHERE wolt.[WorkOrderLaborId] = wol.[WorkOrderLaborId]) > 0 THEN wol.[IsBegin] ELSE NULL END AS [IsBeginTemp],
					  --CASE WHEN wop.[IsTraveler] = 1 THEN (SELECT dbo.FN_GetCurrentLaborHours(wol.WorkOrderLaborId,0)) ELSE wol.[Hours] END AS [Hours],					   
					   emp.[FirstName] + ' '+ emp.[LastName] AS EmployeeName,
					   CASE WHEN WO.[WorkOrderFormTypeId] = 1 THEN WOT.[TaskName] ELSE task.[Description] END AS Task,
					   expr.[Description] AS Expertise,
					   ISNULL(CAST(FLOOR(wol.[Hours]) AS VARCHAR),0) AS LaborHours,  
					   ISNULL(CAST(RIGHT(wol.[Hours], 2) AS VARCHAR),0) AS LaborMinutes,
					   ISNULL(CAST(FLOOR(wol.[Adjustments]) AS VARCHAR),0) AS AdjustmentsHours,  
					   ISNULL(CAST(RIGHT(wol.[Adjustments], 2) AS VARCHAR),0) AS AdjustmentsMinutes,
					   ISNULL(CAST(FLOOR(wol.[AdjustedHours]) AS VARCHAR),0) AS AdjustedHour,  
					   ISNULL(CAST(RIGHT(wol.[AdjustedHours], 2) AS VARCHAR),0) AS AdjustedMinute,
					   wol.[StandardHours],
					   wol.[StandardMinute],
					   wol.[VarianceHours],
					   wol.[VarianceMinute],		
					   woh.[DataEnteredBy],
					   deb.[FirstName] + ' ' + deb.[LastName] AS DataEnteredByName,			
					   ISNULL(wop.[IsTraveler],0) IsTraveler,
					   woh.[HoursorClockorScan],
					   ISNULL(woh.IsLaborTrackingTurnedOff,0) AS IsLaborTrackingTurnedOff
				FROM [dbo].[WorkOrderLabor] wol WITH(NOLOCK)
					LEFT JOIN [dbo].[Task] task  WITH(NOLOCK) ON task.TaskId = wol.TaskId
					LEFT JOIN [dbo].[WorkOrderTask] WOT  WITH(NOLOCK) ON WOT.WorkOrderTaskId = wol.TaskId
					LEFT JOIN [dbo].[EmployeeExpertise] expr WITH(NOLOCK) ON expr.EmployeeExpertiseId = wol.ExpertiseId
					LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON emp.EmployeeId = wol.EmployeeId					
					LEFT JOIN [dbo].[TaskStatus] TS  WITH(NOLOCK) ON TS.TaskStatusId = wol.TaskStatusId
					INNER JOIN [dbo].[WorkOrderLaborHeader] woh WITH(NOLOCK) ON woh.WorkOrderLaborHeaderId = wol.WorkOrderLaborHeaderId
					LEFT JOIN  [dbo].[Employee] deb WITH(NOLOCK) ON deb.EmployeeId = woh.DataEnteredBy
					INNER JOIN [dbo].[WorkOrderWorkFlow] wfwo WITH(NOLOCK) ON wfwo.WorkFlowWorkOrderId = woh.WorkFlowWorkOrderId 
					INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wfwo.WorkOrderPartNoId = wop.ID 	
					INNER JOIN [dbo].[WorkOrder] WO  WITH(NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
				WHERE (wol.[MasterCompanyId] = @MasterCompanyId AND wol.[IsActive] = 1 AND wol.[IsDeleted] = 0)
			), ResultCount AS(SELECT COUNT(WorkOrderLaborId) AS totalItems FROM Result)
			
			SELECT * INTO #TempResult FROM  Result
			WHERE ((@GlobalFilter <>'' AND
					(([WorkOrderNum] LIKE '%' +@GlobalFilter+'%' ) OR 
					([EmployeeName] LIKE '%' +@GlobalFilter+'%') OR					
					([TaskStatusName] LIKE '%' +@GlobalFilter+'%') OR
					([Expertise] LIKE '%' +@GlobalFilter+'%') OR					
					([DataEnteredByName] LIKE '%' +@GlobalFilter+'%') OR					
					([Memo] LIKE '%' +@GlobalFilter+'%') OR					
					([Task] LIKE '%' +@GlobalFilter+'%')))
					OR   
					(@GlobalFilter='' AND (ISNULL(@WONumber,'') ='' OR [WorkOrderNum] LIKE '%' + @WONumber+'%') AND 
					(ISNULL(@EmployeeName,'') ='' OR [EmployeeName] LIKE '%' + @EmployeeName+'%') AND					
					(ISNULL(@TaskStatusName,'') ='' OR [TaskStatusName] LIKE '%' + @TaskStatusName+'%') AND
					(ISNULL(@TaskName,'') ='' OR [Task] LIKE '%' + @TaskName+'%')))

			SELECT @Count = COUNT(WorkOrderLaborId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			
			CASE WHEN (@SortOrder=1 AND @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='EMPLOYEENAME')  THEN EmployeeName END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='TASKSTATUSNAME')  THEN TaskStatusName END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='TASK')  THEN Task END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='Memo')  THEN Memo END ASC,

			CASE WHEN (@SortOrder=-1 AND @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='EMPLOYEENAME')  THEN EmployeeName END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TASKSTATUSNAME')  THEN TaskStatusName END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TASK')  THEN Task END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Memo')  THEN Memo END DESC

			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
					 DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetTravelerTaskList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
			                + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) 
							+ '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(100)) 
							+ '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(100)) 
							+ '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS VARCHAR(100)) 
							+ '@Parameter6 = ''' + CAST(ISNULL(@EmployeeName, '') AS VARCHAR(100)) 
							+ '@Parameter7 = ''' + CAST(ISNULL(@WONumber, '') AS VARCHAR(100)) 
							+ '@Parameter8 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100)) 
							+ '@Parameter9 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) 											
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			=  @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH  	
END