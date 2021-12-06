
/*************************************************************           
 ** File:   [USP_GetViewWorkLoad]           
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
     
 EXECUTE USP_GetViewWorkLoad 1,20,'', -1,'', '2021-07-25 18:30:00.000', '2021-09-25 18:30:00.000',5,'CWO100010-2020'

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetViewWorkLoad]    
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
@mpnstatus varchar(20) = null,
@workOrderNumber varchar(20) = NULL,
@ManagementStructureId bigint = 0,
@ismpnView bit = 0,
@workOrderPartNoId bigint = 0

)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

        DECLARE @RecordFrom int;
		Declare @IsActive bit = 1
		Declare @Count Int;
		--Declare @SortColumn varchar(50) = null
		--Declare @GlobalFilter varchar(50) = ''
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;
		
		IF @SortColumn is null
		Begin
			Set @SortColumn = Upper('WorkOrderNum')
		End 
		Else
		Begin 
			Set @SortColumn = Upper(@SortColumn)
		End

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

				if(@ismpnView =1)
				begin

				Declare @technicalid bigint =0

				 select @technicalid =wopn.TechnicianId from dbo.WorkOrderPartNumber wopn where wopn.id =@workOrderPartNoId

							;WITH CTE AS(
									SELECT	SUM(isnull(wl.Hours,0)) AS [Hours],
									SUM(isnull(wl.Adjustments,0)) AS [Adjustments],
									SUM(isnull(wl.AdjustedHours,0)) AS [AdjustedHours],
									SUM(isnull(wl.BurdenRateAmount,0)) AS BurdenRateAmount,
									wlh.WorkOrderLaborHeaderId,
									wl.WorkOrderLaborId
									FROM dbo.WorkOrderLaborHeader wlh WITH (NOLOCK)
									INNER JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId
									INNER JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
									INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wowf.WorkOrderPartNoId = wop.ID
									INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId
									WHERE wo.MasterCompanyId= @MasterCompanyId and wl.EmployeeId=@technicalid  and WOP.ID= @workOrderPartNoId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1
									GROUP BY wlh.WorkOrderLaborHeaderId,wl.WorkOrderLaborId
							),

						   Result AS(
								   SELECT 
									im.partnumber AS PartNumber,
									im.PartDescription,
									CTE.Hours AS [Hours],
									CTE.Adjustments AS [Adjustments],
									CTE.AdjustedHours AS [AdjustedHours],
									CTE.BurdenRateAmount AS BurdenRateAmount,
									c.Name AS Customer,
									wo.WorkOrderNum,
									ws.Stage,
									st.[Description] As [Status],
									t.[Description] As [Task],
									ex.[Description] AS Expertise,
									emp.FirstName + ' ' + emp.LastName AS Assignedto,
									wl.EmployeeId,
									emps.StationName,
									wl.Memo,
									wl.StatusChangedDate as AssignedDate,
									wlh.WorkOrderLaborHeaderId,
									wl.WorkOrderLaborId,
									wo.WorkOrderId,
									c.CustomerId,
									im.ItemMasterId,
									t.TaskId,
									ex.EmployeeExpertiseId,
									wlh.WorkFlowWorkOrderId,
									wop.NTE as nte,
									wss.Description as mpnstatus

									FROM dbo.WorkOrderLaborHeader wlh WITH (NOLOCK)
									INNER JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId
									INNER JOIN CTE as CTE WITH (NOLOCK) ON CTE.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId and wl.WorkOrderLaborId=CTE.WorkOrderLaborId
									INNER JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
									INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wowf.WorkOrderPartNoId = wop.ID
									INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId
									LEFT JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.WorkOrderStageId
									LEFT JOIN dbo.WorkOrderStatus wss WITH (NOLOCK) ON wss.Id = wop.WorkOrderStatusId
									INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.CustomerId = wo.CustomerId
									INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId
									LEFT JOIN dbo.TaskStatus st WITH (NOLOCK) ON st.TaskStatusId = wl.TaskStatusId
									INNER JOIN dbo.Task t WITH (NOLOCK) ON t.TaskId = wl.TaskId
									INNER JOIN dbo.EmployeeExpertise ex WITH (NOLOCK) ON wl.ExpertiseId = ex.EmployeeExpertiseId	
									LEFT JOIN dbo.Employee emp WITH (NOLOCK) ON emp.EmployeeId = wl.EmployeeId
									LEFT JOIN dbo.EmployeeStation emps WITH (NOLOCK) ON emps.EmployeeStationId = wop.TechStationId
									WHERE wo.MasterCompanyId= @MasterCompanyId   and wl.EmployeeId=@technicalid  and WOP.ID= @workOrderPartNoId  AND isnull(wlh.IsDeleted,0) = 0 AND isnull(wlh.IsActive,1) = 1
						), ResultCount AS(SELECT COUNT(WorkOrderLaborId) AS totalItems FROM Result)
			
						SELECT * INTO #TempResult3 from  Result
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
											(nte like '%' +@GlobalFilter+'%') OR
											(mpnstatus like '%' +@GlobalFilter+'%') 
											))
											OR   
											(@GlobalFilter='' AND (IsNull(@WorkOrderNum,'') ='' OR WorkOrderNum like '%' + @WorkOrderNum+'%') AND
											(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND
											(IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND
											(IsNull(@Hours,'') ='' OR Hours like '%' + @Hours+'%') AND
											(IsNull(@Adjustments,'') ='' OR Adjustments like '%' + @Adjustments+'%') AND
											(IsNull(@AdjustedHours,'') ='' OR AdjustedHours like '%' + @AdjustedHours+'%') AND
											(IsNull(@Customer,'') ='' OR Customer like '%' + @Customer+'%') AND
											(IsNull(@Stage,'') ='' OR Stage like '%' + @Stage+'%') AND
											(IsNull(@Status,'') ='' OR Status like '%' + @Status+'%') AND
											(IsNull(@Task,'') ='' OR Task like '%' + @Task+'%') AND
											(IsNull(@Expertise,'') ='' OR Expertise like '%' + @Expertise+'%') AND
											(IsNull(@Assignedto,'') ='' OR Assignedto like '%' + @Assignedto+'%') AND
											(IsNull(@StationName,'') ='' OR StationName like '%' + @StationName+'%') AND
											(IsNull(@Memo,'') ='' OR Memo like '%' + @Memo+'%') AND
											(IsNull(@mpnstatus,'') ='' OR mpnstatus like '%' + @mpnstatus+'%') AND
											(IsNull(@nte,'') ='' OR nte like '%' + @nte+'%') AND
											(IsNull(@AssignedDate,'') ='' OR Cast(AssignedDate as Date)=Cast(@AssignedDate as date))
											))
						Select @Count = COUNT(WorkOrderLaborId) from #TempResult3			

						SELECT *, @Count As NumberOfItems FROM #TempResult3
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
				end 
				else
				begin

					IF (isnull(@workOrderNumber,'') ='')
					Begin

					print '1'
						;WITH CTE AS(
								SELECT	SUM(isnull(wl.Hours,0)) AS [Hours],
								SUM(isnull(wl.Adjustments,0)) AS [Adjustments],
								SUM(isnull(wl.AdjustedHours,0)) AS [AdjustedHours],
								SUM(isnull(wl.BurdenRateAmount,0)) AS BurdenRateAmount,
								wlh.WorkOrderLaborHeaderId,
								wl.WorkOrderLaborId
								FROM dbo.WorkOrderLaborHeader wlh WITH (NOLOCK)
								INNER JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId
								INNER JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
								INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wowf.WorkOrderPartNoId = wop.ID
								INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId
								WHERE wo.MasterCompanyId= @MasterCompanyId  and Cast(wop.ReceivedDate as date)   >= Cast(@FromRecieveddate as date)    and Cast(wop.ReceivedDate as date)  <= Cast(@ToRecieveddate as date)  AND wlh.IsDeleted = 0 AND wlh.IsActive = 1
								GROUP BY wlh.WorkOrderLaborHeaderId,wl.WorkOrderLaborId
						),

					   Result AS(
							   SELECT 
								im.partnumber AS PartNumber,
								im.PartDescription,
								CTE.Hours AS [Hours],
								CTE.Adjustments AS [Adjustments],
								CTE.AdjustedHours AS [AdjustedHours],
								CTE.BurdenRateAmount AS BurdenRateAmount,
								c.Name AS Customer,
								wo.WorkOrderNum,
								ws.Stage,
								st.[Description] As [Status],
								t.[Description] As [Task],
								ex.[Description] AS Expertise,
								emp.FirstName + ' ' + emp.LastName AS Assignedto,
								wl.EmployeeId,
								emps.StationName,
								wl.Memo,
								wl.StatusChangedDate as AssignedDate,
								wlh.WorkOrderLaborHeaderId,
								wl.WorkOrderLaborId,
								wo.WorkOrderId,
								c.CustomerId,
								im.ItemMasterId,
								t.TaskId,
								ex.EmployeeExpertiseId,
								wlh.WorkFlowWorkOrderId,
								wop.NTE as nte,
								wss.Description as mpnstatus

								FROM dbo.WorkOrderLaborHeader wlh WITH (NOLOCK)
								INNER JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId
								INNER JOIN CTE as CTE WITH (NOLOCK) ON CTE.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId and wl.WorkOrderLaborId=CTE.WorkOrderLaborId
								INNER JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
								INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wowf.WorkOrderPartNoId = wop.ID
								INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId
								LEFT JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.WorkOrderStageId
								LEFT JOIN dbo.WorkOrderStatus wss WITH (NOLOCK) ON wss.Id = wop.WorkOrderStatusId
								INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.CustomerId = wo.CustomerId
								INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId
								LEFT JOIN dbo.TaskStatus st WITH (NOLOCK) ON st.TaskStatusId = wl.TaskStatusId
								INNER JOIN dbo.Task t WITH (NOLOCK) ON t.TaskId = wl.TaskId
								INNER JOIN dbo.EmployeeExpertise ex WITH (NOLOCK) ON wl.ExpertiseId = ex.EmployeeExpertiseId	
								LEFT JOIN dbo.Employee emp WITH (NOLOCK) ON emp.EmployeeId = wl.EmployeeId
								LEFT JOIN dbo.EmployeeStation emps WITH (NOLOCK) ON emps.EmployeeStationId = wop.TechStationId
								LEFT JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.EmployeeId = emp.EmployeeId	
								WHERE wo.MasterCompanyId= @MasterCompanyId  and EMS.ManagementStructureId =@ManagementStructureId and Cast(wop.ReceivedDate as date)   >= Cast(@FromRecieveddate as date)    and Cast(wop.ReceivedDate as date)  <= Cast(@ToRecieveddate as date)  AND isnull(wlh.IsDeleted,0) = 0 AND isnull(wlh.IsActive,1) = 1
					), ResultCount AS(SELECT COUNT(WorkOrderLaborId) AS totalItems FROM Result)
			
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
										(nte like '%' +@GlobalFilter+'%') OR
										(mpnstatus like '%' +@GlobalFilter+'%') 
										))
										OR   
										(@GlobalFilter='' AND (IsNull(@WorkOrderNum,'') ='' OR WorkOrderNum like '%' + @WorkOrderNum+'%') AND
										(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND
										(IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND
										(IsNull(@Hours,'') ='' OR Hours like '%' + @Hours+'%') AND
										(IsNull(@Adjustments,'') ='' OR Adjustments like '%' + @Adjustments+'%') AND
										(IsNull(@AdjustedHours,'') ='' OR AdjustedHours like '%' + @AdjustedHours+'%') AND
										(IsNull(@Customer,'') ='' OR Customer like '%' + @Customer+'%') AND
										(IsNull(@Stage,'') ='' OR Stage like '%' + @Stage+'%') AND
										(IsNull(@Status,'') ='' OR Status like '%' + @Status+'%') AND
										(IsNull(@Task,'') ='' OR Task like '%' + @Task+'%') AND
										(IsNull(@Expertise,'') ='' OR Expertise like '%' + @Expertise+'%') AND
										(IsNull(@Assignedto,'') ='' OR Assignedto like '%' + @Assignedto+'%') AND
										(IsNull(@StationName,'') ='' OR StationName like '%' + @StationName+'%') AND
										(IsNull(@Memo,'') ='' OR Memo like '%' + @Memo+'%') AND
										(IsNull(@mpnstatus,'') ='' OR mpnstatus like '%' + @mpnstatus+'%') AND
										(IsNull(@nte,'') ='' OR nte like '%' + @nte+'%') AND
										(IsNull(@AssignedDate,'') ='' OR Cast(AssignedDate as Date)=Cast(@AssignedDate as date))
										))
					Select @Count = COUNT(WorkOrderLaborId) from #TempResult			

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
				  
					End 
					Else
					Begin 
						;WITH CTE AS(
								SELECT	SUM(isnull(wl.Hours,0)) AS [Hours],
								SUM(isnull(wl.Adjustments,0)) AS [Adjustments],
								SUM(isnull(wl.AdjustedHours,0)) AS [AdjustedHours],
								SUM(isnull(wl.BurdenRateAmount,0)) AS BurdenRateAmount,
								wlh.WorkOrderLaborHeaderId,
								wl.WorkOrderLaborId
								FROM dbo.WorkOrderLaborHeader wlh WITH (NOLOCK)
								INNER JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId
								INNER JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
								INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wowf.WorkOrderPartNoId = wop.ID
								INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId
								WHERE wo.MasterCompanyId= @MasterCompanyId  and wo.WorkOrderNum =@workOrderNumber and Cast(wop.ReceivedDate as date)   >= Cast(@FromRecieveddate as date)    and Cast(wop.ReceivedDate as date)  <= Cast(@ToRecieveddate as date)  AND wlh.IsDeleted = 0 AND wlh.IsActive = 1
								GROUP BY wlh.WorkOrderLaborHeaderId,wl.WorkOrderLaborId
						),

					   Result AS(
							   SELECT 
								im.partnumber AS PartNumber,
								im.PartDescription,
								CTE.Hours AS [Hours],
								CTE.Adjustments AS [Adjustments],
								CTE.AdjustedHours AS [AdjustedHours],
								CTE.BurdenRateAmount AS BurdenRateAmount,
								c.Name AS Customer,
								wo.WorkOrderNum,
								ws.Stage,
								st.[Description] As [Status],
								t.[Description] As [Task],
								ex.[Description] AS Expertise,
								emp.FirstName + ' ' + emp.LastName AS Assignedto,
								wl.EmployeeId,
								emps.StationName,
								wl.Memo,
								wl.StatusChangedDate as AssignedDate,
								wlh.WorkOrderLaborHeaderId,
								wl.WorkOrderLaborId,
								wo.WorkOrderId,
								c.CustomerId,
								im.ItemMasterId,
								t.TaskId,
								ex.EmployeeExpertiseId,
								wlh.WorkFlowWorkOrderId,
								wop.NTE as nte,
								wss.Description as mpnstatus


								FROM dbo.WorkOrderLaborHeader wlh WITH (NOLOCK)
								INNER JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId
								INNER JOIN CTE as CTE WITH (NOLOCK) ON CTE.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId and wl.WorkOrderLaborId=CTE.WorkOrderLaborId
								INNER JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
								INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wowf.WorkOrderPartNoId = wop.ID
								INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId
								INNER JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.WorkOrderStageId
								 LEFT JOIN dbo.WorkOrderStatus wss WITH (NOLOCK) ON wss.Id = wop.WorkOrderStatusId
								INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.CustomerId = wo.CustomerId
								INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId
								LEFT JOIN dbo.TaskStatus st WITH (NOLOCK) ON st.TaskStatusId = wl.TaskStatusId
								INNER JOIN dbo.Task t WITH (NOLOCK) ON t.TaskId = wl.TaskId
								INNER JOIN dbo.EmployeeExpertise ex WITH (NOLOCK) ON wl.ExpertiseId = ex.EmployeeExpertiseId	
								LEFT JOIN dbo.Employee emp WITH (NOLOCK) ON emp.EmployeeId = wl.EmployeeId
								LEFT JOIN dbo.EmployeeStation emps WITH (NOLOCK) ON emps.EmployeeStationId = wop.TechStationId
								LEFT JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.EmployeeId = emp.EmployeeId	
								WHERE wo.MasterCompanyId= @MasterCompanyId and EMS.ManagementStructureId =@ManagementStructureId and wo.WorkOrderNum =@workOrderNumber and Cast(wop.ReceivedDate as date)   >= Cast(@FromRecieveddate as date)    and Cast(wop.ReceivedDate as date)  <= Cast(@ToRecieveddate as date)  AND isnull(wlh.IsDeleted,0) = 0 AND isnull(wlh.IsActive,1) = 1
					), ResultCount AS(SELECT COUNT(WorkOrderLaborId) AS totalItems FROM Result)
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
										(nte like '%' +@GlobalFilter+'%') OR
										(mpnstatus like '%' +@GlobalFilter+'%') 
										))
										OR   
										(@GlobalFilter='' AND (IsNull(@WorkOrderNum,'') ='' OR WorkOrderNum like '%' + @WorkOrderNum+'%') AND
										(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND
										(IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND
										(IsNull(@Hours,'') ='' OR Hours like '%' + @Hours+'%') AND
										(IsNull(@Adjustments,'') ='' OR Adjustments like '%' + @Adjustments+'%') AND
										(IsNull(@AdjustedHours,'') ='' OR AdjustedHours like '%' + @AdjustedHours+'%') AND
										(IsNull(@Customer,'') ='' OR Customer like '%' + @Customer+'%') AND
										(IsNull(@Stage,'') ='' OR Stage like '%' + @Stage+'%') AND
										(IsNull(@Status,'') ='' OR Status like '%' + @Status+'%') AND
										(IsNull(@Task,'') ='' OR Task like '%' + @Task+'%') AND
										(IsNull(@Expertise,'') ='' OR Expertise like '%' + @Expertise+'%') AND
										(IsNull(@Assignedto,'') ='' OR Assignedto like '%' + @Assignedto+'%') AND
										(IsNull(@StationName,'') ='' OR StationName like '%' + @StationName+'%') AND
										(IsNull(@Memo,'') ='' OR Memo like '%' + @Memo+'%') AND
										(IsNull(@mpnstatus,'') ='' OR mpnstatus like '%' + @mpnstatus+'%') AND
										(IsNull(@nte,'') ='' OR nte like '%' + @nte+'%') AND
										(IsNull(@AssignedDate,'') ='' OR Cast(AssignedDate as Date)=Cast(@AssignedDate as date))
										))
					Select @Count = COUNT(WorkOrderLaborId) from #TempResult1			

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
					End

			   end
				
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderLaborAnalysisDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''',
													   @Parameter2 = ' + ISNULL(@PageSize,'') + ', 
													   @Parameter3 = ' + ISNULL(@SortColumn,'') + ', 
													   @Parameter4 = ' + ISNULL(@SortOrder,'') + ', 
													   @Parameter5 = ' + ISNULL(@GlobalFilter,'') + ', 
													   @Parameter6 = ' + ISNULL(@FromRecieveddate,'') + ',  
													   @Parameter7 = ' + ISNULL(@ToRecieveddate,'') + ', 
													   @Parameter8 = ' + ISNULL(@MasterCompanyId,'') + ', 
													   @Parameter9 = ' + ISNULL(@WorkOrderNum,'') + ', 
													   @Parameter10 = ' + ISNULL(@PartNumber,'') + ', 
													   @Parameter11 = ' + ISNULL(@PartDescription,'') + ', 
													   @Parameter12 = ' + ISNULL(@RevisedPN,'') + ', 
													   @Parameter13 = ' + ISNULL(@Stage,'') + ', 
													   @Parameter14 = ' + ISNULL(@Hours,'') + ', 
													   @Parameter15 = ' + ISNULL(@Adjustments ,'') + ', 
													   @Parameter16 = ' + ISNULL(@AdjustedHours ,'') + ', 
													   @Parameter17 = ' + ISNULL(@Customer ,'') + ', 
													   @Parameter18 = ' + ISNULL(@Stage ,'') + ', 
													   @Parameter19 = ' + ISNULL(@Status ,'') + ', 
													   @Parameter20 = ' + ISNULL(@Task ,'') + ', 
													   @Parameter21 = ' + ISNULL(@Expertise ,'') + ', 
													   @Parameter22 = ' + ISNULL(@Assignedto,'') + ', 
													   @Parameter23 = ' + ISNULL(@StationName,'') + ', 
													   @Parameter24 = ' + ISNULL(@Memo ,'') + ', 
													   @Parameter25 = ' + ISNULL(@AssignedDate,'') + ', 
													   @Parameter26 = ' + ISNULL(@nte,'') + ', 
													   @Parameter27 = ' + ISNULL(@mpnstatus,'') +''
													
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