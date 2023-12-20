
/*************************************************************           
 ** File:   [USP_GetWOAssignment]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used retrieve WorkOrder Assignment Details    
 ** Purpose:         
 ** Date:   02/22/2021        
          
 ** PARAMETERS:           
 @FromRecieveddate Datetime   
 @ToRecieveddate Datetime  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/12/2021   Subhash Saliya Created
     
 EXECUTE USP_GetWOAssignment 1,20,'', -1,'', '2021-07-25 18:30:00.000', '2021-09-25 18:30:00.000',5,NULL
 EXECUTE USP_GetWOAssignment 250, 0

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetWOAssignment]    
( 
@PageNumber int,
@PageSize int,
@SortColumn varchar(50) = '',
@SortOrder int,
@GlobalFilter varchar(50) = '',
@FromRecieveddate Datetime = NULL,   
@ToRecieveddate Datetime = NULL,
@MasterCompanyId bigint = 0,
@WorkOrderNum varchar(20) = NULL,
@PartNumber varchar(20) = null,
@PartDescription varchar(20) = null,
@RevisedPN varchar(20) = null,
@Hours varchar(20) = null,
@Adjustments varchar(20) = null,
@AdjustedHours varchar(20) = null,
@Customer varchar(20) = null,
@Stage varchar(20) = null,
@Status varchar(20) = null,
@Task varchar(20) = null,
@Expertise varchar(20) = null,
@Assignedto varchar(20) = null,
@StationName varchar(20) = null,
@Memo varchar(20) = null,
@AssignedDate Datetime = NULL, 
@nte varchar(20) = null,
@workOrderNumber varchar(20) = NULL,
@ismpnView bit = 0,
@workOrderPartNoId bigint = 0,
@ManagementStructureId bigint = 0
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

        DECLARE @RecordFrom INT;
		DECLARE @IsActive BIT = 1
		DECLARE @Count INT;

		SET @RecordFrom = (@PageNumber - 1) * @PageSize;
		
		IF @SortColumn is null
		BEGIN
			SET @SortColumn = Upper('WorkOrderNum')
		END 
		ELSE
		BEGIN 
			SET @SortColumn = Upper(@SortColumn)
		END

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
			
			     IF(@ismpnView =1)
			     BEGIN
					;WITH CTE AS(
						SELECT	SUM(ISNULL(wl.Hours,0)) AS [Hours],
							SUM(ISNULL(wl.Adjustments,0)) AS [Adjustments],
							SUM(ISNULL(wl.AdjustedHours,0)) AS [AdjustedHours],
							SUM(ISNULL(wl.BurdenRateAmount,0)) AS BurdenRateAmount,
							wlh.WorkOrderLaborHeaderId,
							wl.WorkOrderLaborId
                        FROM dbo.WorkOrder wo 
							INNER JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WOP.WorkOrderId = wo.WorkOrderId
							LEFT Join dbo.WorkOrderLaborHeader wlh WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1
							LEFT JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId AND wl.IsDeleted = 0 AND wl.IsActive = 1
							LEFT JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
						WHERE wo.MasterCompanyId= @MasterCompanyId  and WOP.ID= @workOrderPartNoId 
				        GROUP BY wlh.WorkOrderLaborHeaderId,wl.WorkOrderLaborId
						),

					   Result AS(
							   SELECT 
									im.partnumber AS PartNumber,
									im.PartDescription,
									ISNULL(CTE.Hours,0) AS [Hours],
									ISNULL(CTE.Adjustments,0) AS [Adjustments],
									ISNULL(CTE.AdjustedHours,0) AS [AdjustedHours],
									ISNULL(CTE.BurdenRateAmount,0) AS BurdenRateAmount,
									c.Name AS Customer,
									wo.WorkOrderNum,
									ws.Stage,
									st.[Description] As [Status],
									t.[Description] As [Task],
									ex.[Description] AS Expertise,
									CASE WHEN ISNULL(emp.FirstName, '') != '' THEN emp.FirstName + ' ' + emp.LastName ELSE  empTech.FirstName + ' ' + empTech.LastName END AS Assignedto,									 
									wl.EmployeeId,
									emps.StationName,
									wl.Memo,
									wl.StatusChangedDate as AssignedDate,
									wlh.WorkOrderLaborHeaderId,
									ISNULL(wl.WorkOrderLaborId,0) as WorkOrderLaborId,
									wo.WorkOrderId,
									c.CustomerId,
									im.ItemMasterId,
									t.TaskId,
									ex.EmployeeExpertiseId,
									wlh.WorkFlowWorkOrderId,
									wop.NTE as nte,
									wl.TaskStatusId,
									ISNULL(wo.ReceivingCustomerWorkId,0) as ReceivingCustomerWorkId,
									st.StatusCode as labourStatusCode,
									wst.StatusCode as mpnStatusCode,
									wst.Description as mpnStatus
								FROM dbo.WorkOrder wo 
									INNER JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WOP.WorkOrderId = wo.WorkOrderId
									INNER JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.WorkOrderStageId
									INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.CustomerId = wo.CustomerId
									INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId
									LEFT Join dbo.WorkOrderLaborHeader wlh WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1
									LEFT JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId AND wl.IsDeleted = 0 AND wl.IsActive = 1
									LEFT JOIN CTE as CTE WITH (NOLOCK) ON CTE.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId and wl.WorkOrderLaborId=CTE.WorkOrderLaborId
									LEFT JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
									LEFT JOIN dbo.WorkOrderStatus wst WITH (NOLOCK) ON wst.Id = wop.WorkOrderStatusId
									LEFT JOIN dbo.TaskStatus st WITH (NOLOCK) ON st.TaskStatusId = wl.TaskStatusId
									LEFT JOIN dbo.Task t WITH (NOLOCK) ON t.TaskId = wl.TaskId
									LEFT JOIN dbo.EmployeeExpertise ex WITH (NOLOCK) ON wl.ExpertiseId = ex.EmployeeExpertiseId	
									LEFT JOIN dbo.Employee emp WITH (NOLOCK) ON emp.EmployeeId = wl.EmployeeId
									LEFT JOIN dbo.Employee empTech WITH (NOLOCK) ON empTech.EmployeeId = wop.TechnicianId
									LEFT JOIN dbo.EmployeeStation emps WITH (NOLOCK) ON emps.EmployeeStationId = wop.TechStationId
								WHERE wo.MasterCompanyId= @MasterCompanyId and WOP.ID= @workOrderPartNoId 
					), ResultCount AS(SELECT COUNT(WorkOrderId) AS totalItems FROM Result)
					SELECT * INTO #TempResult2 from  Result
					WHERE (
								(@GlobalFilter <>'' AND (
								(PartNumber like '%' +@GlobalFilter+'%') OR
								(PartDescription like '%' +@GlobalFilter+'%') OR
								(Hours like '%' +@GlobalFilter+'%') OR
								(Adjustments like '%' +@GlobalFilter+'%') OR
								(AdjustedHours like '%' +@GlobalFilter+'%') OR
								(Customer like '%' +@GlobalFilter+'%') OR		
								(WorkOrderNum like '%' +@GlobalFilter+'%' ) OR 
								(Stage like '%' +@GlobalFilter+'%') OR
								(Status like '%' +@GlobalFilter+'%') OR
								([Task] like '%' +@GlobalFilter+'%') OR
								(Expertise like '%'+@GlobalFilter+'%') OR
								(Assignedto like '%'+@GlobalFilter+'%') OR
								(StationName like '%' +@GlobalFilter+'%') OR
								(Memo like '%' +@GlobalFilter+'%') OR
								(AssignedDate like '%' +@GlobalFilter+'%') OR
								(nte like '%' +@GlobalFilter+'%')
								))
								OR   
								(@GlobalFilter='' AND (IsNull(@WorkOrderNum,'') ='' OR WorkOrderNum like '%' + @WorkOrderNum+'%') AND
								(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND
								(IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND
								(IsNull(@Hours,0) =0 OR Hours like '%' + @Hours+'%') AND
								(IsNull(@Adjustments,0) =0 OR Adjustments like '%' + @Adjustments+'%') AND
								(IsNull(@AdjustedHours,0) =0 OR AdjustedHours like '%' + @AdjustedHours+'%') AND
								(IsNull(@Customer,'') ='' OR Customer like '%' + @Customer+'%') AND
								(IsNull(@Stage,'') ='' OR Stage like '%' + @Stage+'%') AND
								(IsNull(@Status,'') ='' OR Status like '%' + @Status+'%') AND
								(IsNull(@Task,'') ='' OR Task like '%' + @Task+'%') AND
								(IsNull(@Expertise,'') ='' OR Expertise like '%' + @Expertise+'%') AND
								(IsNull(@Assignedto,'') ='' OR Assignedto like '%' + @Assignedto+'%') AND
								(IsNull(@StationName,'') ='' OR StationName like '%' + @StationName+'%') AND
								(IsNull(@Memo,'') ='' OR Memo like '%' + @Memo+'%') AND
								(IsNull(@nte,'') ='' OR nte like '%' + @nte+'%') AND
								(IsNull(@AssignedDate,'') ='' OR Cast(AssignedDate as Date)=Cast(@AssignedDate as date))
								))
			Select @Count = COUNT(WorkOrderId) from #TempResult2			

			SELECT *, @Count As NumberOfItems FROM #TempResult2
			ORDER BY  			
			CASE WHEN (@SortOrder=1 and @SortColumn='PartNumber')  THEN PartNumber END ASC,
		    CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='Hours')  THEN Hours END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='Adjustments')  THEN Adjustments END ASC,
		    CASE WHEN (@SortOrder=1 and @SortColumn='AdjustedHours')  THEN AdjustedHours END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='BurdenRateAmount')  THEN BurdenRateAmount END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='Customer')  THEN Customer END ASC,
		    CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='Stage')  THEN Stage END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN Status END ASC,
		    CASE WHEN (@SortOrder=1 and @SortColumn='Task')  THEN Task END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='Expertise')  THEN Expertise END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='Assignedto')  THEN Assignedto END ASC,
		    CASE WHEN (@SortOrder=1 and @SortColumn='StationName')  THEN StationName END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='Memo')  THEN Memo END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='AssignedDate')  THEN AssignedDate END ASC,
		    CASE WHEN (@SortOrder=1 and @SortColumn='nte')  THEN nte END ASC,

			CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumber')  THEN PartNumber END DESC,
		    CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='Hours')  THEN Hours END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='Adjustments')  THEN Adjustments END DESC,
		    CASE WHEN (@SortOrder=-1 and @SortColumn='AdjustedHours')  THEN AdjustedHours END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='BurdenRateAmount')  THEN BurdenRateAmount END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='Customer')  THEN Customer END DESC,
		    CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='Stage')  THEN Stage END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='Status')  THEN Status END DESC,
		    CASE WHEN (@SortOrder=-1 and @SortColumn='Task')  THEN Task END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='Expertise')  THEN Expertise END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='Assignedto')  THEN Assignedto END DESC,
		    CASE WHEN (@SortOrder=-1 and @SortColumn='StationName')  THEN StationName END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='Memo')  THEN Memo END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='AssignedDate')  THEN AssignedDate END DESC,
		    CASE WHEN (@SortOrder=-1 and @SortColumn='nte')  THEN nte END DESC

			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY	
			END
			     ELSE
			     BEGIN			     
			       IF (ISNULL(@workOrderNumber,'') ='')
			       BEGIN
					;WITH CTE AS(
							SELECT	
								SUM(ISNULL(wl.Hours,0)) AS [Hours],
								SUM(ISNULL(wl.Adjustments,0)) AS [Adjustments],
								SUM(ISNULL(wl.AdjustedHours,0)) AS [AdjustedHours],
								SUM(ISNULL(wl.BurdenRateAmount,0)) AS BurdenRateAmount,
								wlh.WorkOrderLaborHeaderId,
								wl.WorkOrderLaborId,
								wo.WorkOrderId
							FROM dbo.WorkOrder wo 
								INNER JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WOP.WorkOrderId = wo.WorkOrderId
								LEFT Join dbo.WorkOrderLaborHeader wlh WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1
								LEFT JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId AND wl.IsDeleted = 0 AND wl.IsActive = 1
								LEFT JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
							WHERE wo.MasterCompanyId= @MasterCompanyId  and Cast(wop.ReceivedDate as date)   >= Cast(@FromRecieveddate as date)    and Cast(wop.ReceivedDate as date)  <= Cast(@ToRecieveddate as date)
							GROUP BY wlh.WorkOrderLaborHeaderId,wl.WorkOrderLaborId,wo.WorkOrderId
					),
				   Result AS(
						   SELECT 
								im.partnumber AS PartNumber,
								im.PartDescription,
								ISNULL(CTE.Hours,0) AS [Hours],
								ISNULL(CTE.Adjustments,0) AS [Adjustments],
								ISNULL(CTE.AdjustedHours,0) AS [AdjustedHours],
								ISNULL(CTE.BurdenRateAmount,0) AS BurdenRateAmount,
								c.Name AS Customer,
								wo.WorkOrderNum,
								ws.Stage,
								st.[Description] As [Status],
								t.[Description] As [Task],
								ex.[Description] AS Expertise,
								CASE WHEN ISNULL(emp.FirstName, '') != '' THEN emp.FirstName + ' ' + emp.LastName ELSE  empTech.FirstName + ' ' + empTech.LastName END AS Assignedto,
								--emp.FirstName + ' ' + emp.LastName AS Assignedto,
								wl.EmployeeId,
								emps.StationName,
								wl.Memo,
								wl.StatusChangedDate as AssignedDate,
								wlh.WorkOrderLaborHeaderId,
								ISNULL(wl.WorkOrderLaborId,0) as WorkOrderLaborId,
								wo.WorkOrderId,
								c.CustomerId,
								im.ItemMasterId,
								t.TaskId,
								ex.EmployeeExpertiseId,
								wlh.WorkFlowWorkOrderId,
								wop.NTE as nte,
								wl.TaskStatusId,
								ISNULL(wo.ReceivingCustomerWorkId,0) as ReceivingCustomerWorkId,
								st.StatusCode as labourStatusCode,
								wst.StatusCode as mpnStatusCode,
								wst.Description as mpnStatus
							FROM dbo.WorkOrder wo 
								INNER JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WOP.WorkOrderId = wo.WorkOrderId
								INNER JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.WorkOrderStageId
								INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.CustomerId = wo.CustomerId
								INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId

								LEFT Join dbo.WorkOrderLaborHeader wlh WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1
								LEFT JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId AND wl.IsDeleted = 0 AND wl.IsActive = 1
								LEFT JOIN CTE as CTE WITH (NOLOCK) ON CTE.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId and wl.WorkOrderLaborId=CTE.WorkOrderLaborId
								LEFT JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
								LEFT JOIN dbo.WorkOrderStatus wst WITH (NOLOCK) ON wst.Id = wop.WorkOrderStatusId
								LEFT JOIN dbo.TaskStatus st WITH (NOLOCK) ON st.TaskStatusId = wl.TaskStatusId
								LEFT JOIN dbo.Task t WITH (NOLOCK) ON t.TaskId = wl.TaskId
								LEFT JOIN dbo.EmployeeExpertise ex WITH (NOLOCK) ON wl.ExpertiseId = ex.EmployeeExpertiseId	
								LEFT JOIN dbo.Employee emp WITH (NOLOCK) ON emp.EmployeeId = wl.EmployeeId
								LEFT JOIN dbo.Employee empTech WITH (NOLOCK) ON empTech.EmployeeId = wop.TechnicianId
								LEFT JOIN dbo.EmployeeStation emps WITH (NOLOCK) ON emps.EmployeeStationId = wop.TechStationId
								LEFT JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.EmployeeId = emp.EmployeeId  and EMS.ManagementStructureId =@ManagementStructureId	
							WHERE wo.MasterCompanyId= @MasterCompanyId  and Cast(wop.ReceivedDate as date)   >= Cast(@FromRecieveddate as date)    and Cast(wop.ReceivedDate as date)  <= Cast(@ToRecieveddate as date)  
				), ResultCount AS(SELECT COUNT(WorkOrderId) AS totalItems FROM Result)
				SELECT * INTO #TempResult from  Result
				WHERE (
									(@GlobalFilter <>'' AND (
									(PartNumber like '%' +@GlobalFilter+'%') OR
									(PartDescription like '%' +@GlobalFilter+'%') OR
									(Hours like '%' +@GlobalFilter+'%') OR
									(Adjustments like '%' +@GlobalFilter+'%') OR
									(AdjustedHours like '%' +@GlobalFilter+'%') OR
									(Customer like '%' +@GlobalFilter+'%') OR		
									(WorkOrderNum like '%' +@GlobalFilter+'%' ) OR 
									(Stage like '%' +@GlobalFilter+'%') OR
									(Status like '%' +@GlobalFilter+'%') OR
									([Task] like '%' +@GlobalFilter+'%') OR
									(Expertise like '%'+@GlobalFilter+'%') OR
									(Assignedto like '%'+@GlobalFilter+'%') OR
									(StationName like '%' +@GlobalFilter+'%') OR
									(Memo like '%' +@GlobalFilter+'%') OR
									(AssignedDate like '%' +@GlobalFilter+'%') OR
									(nte like '%' +@GlobalFilter+'%')
									))
									OR   
									(@GlobalFilter='' AND 
									(IsNull(@WorkOrderNum,'') ='' OR WorkOrderNum like '%' + @WorkOrderNum+'%') AND
									(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND
									(IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND
									(IsNull(@Hours,0) =0 OR Hours like '%' + @Hours+'%') AND
									(IsNull(@Adjustments,0) =0 OR Adjustments like '%' + @Adjustments+'%') AND
									(IsNull(@AdjustedHours,0) =0 OR AdjustedHours like '%' + @AdjustedHours+'%') AND
									(IsNull(@Customer,'') ='' OR Customer like '%' + @Customer+'%') AND
									(IsNull(@Stage,'') ='' OR Stage like '%' + @Stage+'%') AND
									(IsNull(@Status,'') ='' OR Status like '%' + @Status+'%') AND
									(IsNull(@Task,'') ='' OR Task like '%' + @Task+'%') AND
									(IsNull(@Expertise,'') ='' OR Expertise like '%' + @Expertise+'%') AND
									(IsNull(@Assignedto,'') ='' OR Assignedto like '%' + @Assignedto+'%') AND
									(IsNull(@StationName,'') ='' OR StationName like '%' + @StationName+'%') AND
									(IsNull(@Memo,'') ='' OR Memo like '%' + @Memo+'%') AND
									(IsNull(@nte,'') ='' OR nte like '%' + @nte+'%') AND
									(IsNull(@AssignedDate,'') ='' OR Cast(AssignedDate as Date)=Cast(@AssignedDate as date))
									))
					SELECT @Count = COUNT(WorkOrderId) from #TempResult			

					SELECT *, @Count As NumberOfItems FROM #TempResult
					ORDER BY  			
					CASE WHEN (@SortOrder=1 and @SortColumn='PartNumber')  THEN PartNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN PartDescription END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Hours')  THEN Hours END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Adjustments')  THEN Adjustments END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='AdjustedHours')  THEN AdjustedHours END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='BurdenRateAmount')  THEN BurdenRateAmount END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Customer')  THEN Customer END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Stage')  THEN Stage END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN Status END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Task')  THEN Task END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Expertise')  THEN Expertise END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Assignedto')  THEN Assignedto END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='StationName')  THEN StationName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Memo')  THEN Memo END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='AssignedDate')  THEN AssignedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='nte')  THEN nte END ASC,

					CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumber')  THEN PartNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PartDescription END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Hours')  THEN Hours END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Adjustments')  THEN Adjustments END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='AdjustedHours')  THEN AdjustedHours END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='BurdenRateAmount')  THEN BurdenRateAmount END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Customer')  THEN Customer END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Stage')  THEN Stage END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Status')  THEN Status END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Task')  THEN Task END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Expertise')  THEN Expertise END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Assignedto')  THEN Assignedto END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='StationName')  THEN StationName END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Memo')  THEN Memo END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='AssignedDate')  THEN AssignedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='nte')  THEN nte END DESC

			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY					  
				 END 
			     ELSE
			     BEGIN 
					;WITH CTE AS(
							SELECT	
								SUM(ISNULL(wl.Hours,0)) AS [Hours],
								SUM(ISNULL(wl.Adjustments,0)) AS [Adjustments],
								SUM(ISNULL(wl.AdjustedHours,0)) AS [AdjustedHours],
								SUM(ISNULL(wl.BurdenRateAmount,0)) AS BurdenRateAmount,
								wlh.WorkOrderLaborHeaderId,
								wl.WorkOrderLaborId
							FROM dbo.WorkOrder wo 
								INNER JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WOP.WorkOrderId = wo.WorkOrderId
								LEFT Join dbo.WorkOrderLaborHeader wlh WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1
								LEFT JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId AND wl.IsDeleted = 0 AND wl.IsActive = 1
								LEFT JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
							WHERE wo.MasterCompanyId= @MasterCompanyId  and wo.WorkOrderNum =@workOrderNumber and Cast(wop.ReceivedDate as date)   >= Cast(@FromRecieveddate as date)    and Cast(wop.ReceivedDate as date)  <= Cast(@ToRecieveddate as date) 
							GROUP BY wlh.WorkOrderLaborHeaderId,wl.WorkOrderLaborId
					),

				   Result AS(
						   SELECT 
								im.partnumber AS PartNumber,
								im.PartDescription,
								ISNULL(CTE.Hours,0) AS [Hours],
								ISNULL(CTE.Adjustments,0) AS [Adjustments],
								ISNULL(CTE.AdjustedHours,0) AS [AdjustedHours],
								ISNULL(CTE.BurdenRateAmount,0) AS BurdenRateAmount,
								c.Name AS Customer,
								wo.WorkOrderNum,
								ws.Stage,
								st.[Description] As [Status],
								t.[Description] As [Task],
								ex.[Description] AS Expertise,
								CASE WHEN ISNULL(emp.FirstName, '') != '' THEN emp.FirstName + ' ' + emp.LastName ELSE  empTech.FirstName + ' ' + empTech.LastName END AS Assignedto,	
								--emp.FirstName + ' ' + emp.LastName AS Assignedto,
								wl.EmployeeId,
								emps.StationName,
								wl.Memo,
								wl.StatusChangedDate as AssignedDate,
								wlh.WorkOrderLaborHeaderId,
								ISNULL(wl.WorkOrderLaborId,0) as WorkOrderLaborId,
								wo.WorkOrderId,
								c.CustomerId,
								im.ItemMasterId,
								t.TaskId,
								ex.EmployeeExpertiseId,
								wlh.WorkFlowWorkOrderId,
								wop.NTE as nte,
								wl.TaskStatusId,
								ISNULL(wo.ReceivingCustomerWorkId,0) as ReceivingCustomerWorkId,
								st.StatusCode as labourStatusCode,
								wst.StatusCode as mpnStatusCode,
								wst.Description as mpnStatus
							FROM dbo.WorkOrder wo 
								INNER JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WOP.WorkOrderId = wo.WorkOrderId
								INNER JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.WorkOrderStageId
								INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.CustomerId = wo.CustomerId
								INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId
								LEFT Join dbo.WorkOrderLaborHeader wlh WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1
								LEFT JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId AND wl.IsDeleted = 0 AND wl.IsActive = 1
								LEFT JOIN CTE as CTE WITH (NOLOCK) ON CTE.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId and wl.WorkOrderLaborId=CTE.WorkOrderLaborId
								LEFT JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
								LEFT JOIN dbo.WorkOrderStatus wst WITH (NOLOCK) ON wst.Id = wop.WorkOrderStatusId
								LEFT JOIN dbo.TaskStatus st WITH (NOLOCK) ON st.TaskStatusId = wl.TaskStatusId
								LEFT JOIN dbo.Task t WITH (NOLOCK) ON t.TaskId = wl.TaskId
								LEFT JOIN dbo.EmployeeExpertise ex WITH (NOLOCK) ON wl.ExpertiseId = ex.EmployeeExpertiseId	
								LEFT JOIN dbo.Employee emp WITH (NOLOCK) ON emp.EmployeeId = wl.EmployeeId
								LEFT JOIN dbo.Employee empTech WITH (NOLOCK) ON empTech.EmployeeId = wop.TechnicianId
								LEFT JOIN dbo.EmployeeStation emps WITH (NOLOCK) ON emps.EmployeeStationId = wop.TechStationId
								LEFT JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.EmployeeId = emp.EmployeeId	and EMS.ManagementStructureId =@ManagementStructureId
							WHERE wo.MasterCompanyId= @MasterCompanyId    and wo.WorkOrderNum =@workOrderNumber and Cast(wop.ReceivedDate as date)   >= Cast(@FromRecieveddate as date)    and Cast(wop.ReceivedDate as date)  <= Cast(@ToRecieveddate as date) 
				), ResultCount AS(SELECT COUNT(WorkOrderId) AS totalItems FROM Result)
				SELECT * INTO #TempResult1 from  Result
				WHERE (
									(@GlobalFilter <>'' AND (
									(PartNumber like '%' +@GlobalFilter+'%') OR
									(PartDescription like '%' +@GlobalFilter+'%') OR
									(Hours like '%' +@GlobalFilter+'%') OR
									(Adjustments like '%' +@GlobalFilter+'%') OR
									(AdjustedHours like '%' +@GlobalFilter+'%') OR
									(Customer like '%' +@GlobalFilter+'%') OR		
									(WorkOrderNum like '%' +@GlobalFilter+'%' ) OR 
									(Stage like '%' +@GlobalFilter+'%') OR
									(Status like '%' +@GlobalFilter+'%') OR
									([Task] like '%' +@GlobalFilter+'%') OR
									(Expertise like '%'+@GlobalFilter+'%') OR
									(Assignedto like '%'+@GlobalFilter+'%') OR
									(StationName like '%' +@GlobalFilter+'%') OR
									(Memo like '%' +@GlobalFilter+'%') OR
									(AssignedDate like '%' +@GlobalFilter+'%') OR
									(nte like '%' +@GlobalFilter+'%') 								 
									))
									OR   
									(@GlobalFilter='' AND (IsNull(@WorkOrderNum,'') ='' OR WorkOrderNum like '%' + @WorkOrderNum+'%') AND
									(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND
									(IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND
									(IsNull(@Hours,0) =0 OR Hours like '%' + @Hours+'%') AND
									(IsNull(@Adjustments,0) =0 OR Adjustments like '%' + @Adjustments+'%') AND
									(IsNull(@AdjustedHours,0) =0 OR AdjustedHours like '%' + @AdjustedHours+'%') AND
									(IsNull(@Customer,'') ='' OR Customer like '%' + @Customer+'%') AND
									(IsNull(@Stage,'') ='' OR Stage like '%' + @Stage+'%') AND
									(IsNull(@Status,'') ='' OR Status like '%' + @Status+'%') AND
									(IsNull(@Task,'') ='' OR Task like '%' + @Task+'%') AND
									(IsNull(@Expertise,'') ='' OR Expertise like '%' + @Expertise+'%') AND
									(IsNull(@Assignedto,'') ='' OR Assignedto like '%' + @Assignedto+'%') AND
									(IsNull(@StationName,'') ='' OR StationName like '%' + @StationName+'%') AND
									(IsNull(@Memo,'') ='' OR Memo like '%' + @Memo+'%') AND
									(IsNull(@nte,'') ='' OR nte like '%' + @nte+'%') AND
									(IsNull(@AssignedDate,'') ='' OR Cast(AssignedDate as Date)=Cast(@AssignedDate as date))
									))
					SELECT @Count = COUNT(WorkOrderId) from #TempResult1			

					SELECT *, @Count As NumberOfItems FROM #TempResult1
					ORDER BY  			
					CASE WHEN (@SortOrder=1 and @SortColumn='PartNumber')  THEN PartNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN PartDescription END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Hours')  THEN Hours END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Adjustments')  THEN Adjustments END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='AdjustedHours')  THEN AdjustedHours END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='BurdenRateAmount')  THEN BurdenRateAmount END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Customer')  THEN Customer END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Stage')  THEN Stage END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN Status END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Task')  THEN Task END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Expertise')  THEN Expertise END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Assignedto')  THEN Assignedto END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='StationName')  THEN StationName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Memo')  THEN Memo END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='AssignedDate')  THEN AssignedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='nte')  THEN nte END ASC,

					CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumber')  THEN PartNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PartDescription END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Hours')  THEN Hours END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Adjustments')  THEN Adjustments END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='AdjustedHours')  THEN AdjustedHours END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='BurdenRateAmount')  THEN BurdenRateAmount END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Customer')  THEN Customer END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Stage')  THEN Stage END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Status')  THEN Status END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Task')  THEN Task END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Expertise')  THEN Expertise END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Assignedto')  THEN Assignedto END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='StationName')  THEN StationName END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Memo')  THEN Memo END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='AssignedDate')  THEN AssignedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='nte')  THEN nte END DESC

					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY

					END
			     END				
			END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWOAssignment' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''', 
													   @Parameter2 = ' + ISNULL(@PageSize ,'') +'''
													   @Parameter3 = ' + ISNULL(@SortColumn ,'') +'''
													   @Parameter4 = ' + ISNULL(@SortOrder ,'') +'''
													   @Parameter5 = ' + ISNULL(@GlobalFilter ,'') +'''
													   @Parameter6 = ' + ISNULL(@FromRecieveddate ,'') +'''
													   @Parameter7 = ' + ISNULL(@ToRecieveddate ,'') +'''
													   @Parameter8 = ' + ISNULL(@MasterCompanyId ,'') +'''
													   @Parameter9 = ' + ISNULL(@WorkOrderNum ,'') +'''
													   @Parameter10 = ' + ISNULL(@PartNumber ,'') +'''
													   @Parameter11 = ' + ISNULL(@RevisedPN ,'') +'''
													   @Parameter12 = ' + ISNULL(@Hours ,'') +'''
													   @Parameter13 = ' + ISNULL(@Adjustments ,'') +'''
													   @Parameter14 = ' + ISNULL(@AdjustedHours ,'') +'''
													   @Parameter15 = ' + ISNULL(@Customer ,'') +'''
													   @Parameter16 = ' + ISNULL(@Stage ,'') +'''
													   @Parameter17 = ' + ISNULL(@Status ,'') +'''
													   @Parameter18 = ' + ISNULL(@Task ,'') +'''
													   @Parameter19 = ' + ISNULL(@Expertise ,'') +'''
													   @Parameter20 = ' + ISNULL(@Assignedto ,'') +'''
													   @Parameter21 = ' + ISNULL(@StationName ,'') +'''
													   @Parameter22 = ' + ISNULL(@Memo ,'') +'''
													   @Parameter23 = ' + ISNULL(@AssignedDate ,'') +'''
													   @Parameter24 = ' + ISNULL(@nte ,'') +'''
													   @Parameter25 = ' + ISNULL(@workOrderNumber ,'') +'''
													   @Parameter26 = ' + ISNULL(@ismpnView ,'') +'''
													   @Parameter27 = ' + ISNULL(@workOrderPartNoId ,'') +''
													   
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