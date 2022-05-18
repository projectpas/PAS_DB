/*************************************************************           
 ** File:   [USP_GetAllWOAssignmentOpenItem]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve WorkOrder Assignment Details    
 ** Purpose:         
 ** Date:   02/22/2021       
        
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/12/2021   Hemant Saliya Created
     
 EXECUTE USP_GetAllWOAssignmentOpenItem 1,20,'', -1,'',1

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetAllWOAssignmentOpenItem]    
( 
@PageNumber int,
@PageSize int,
@SortColumn varchar(50) = '',
@SortOrder int,
@GlobalFilter varchar(50) = '',
@MasterCompanyId bigint = 0,
@WorkOrderNum varchar(20) = NULL,
@PartNumber varchar(20) = null,
@PartDescription varchar(20) = null,
@Customer varchar(20) = null,
@Stage varchar(20) = null,
@Status varchar(20) = null,
@Expertise varchar(20) = null,
@Assignedto varchar(20) = null,
@StationName varchar(20) = null,
@Memo varchar(20) = null,
@AssignedDate Datetime = NULL, 
@nte varchar(20) = null,
@workOrderNumber varchar(20) = NULL,
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
		DECLARE @CloseWOStatusId INT;
		DECLARE @CloseTaskStatusId INT;
		DECLARE @ExpertiseType VARCHAR(50);

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
			SELECT @ExpertiseType = EmpExpCode from dbo.EmployeeExpertise WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND EmpExpCode = 'TECHNICIAN'
			SELECT @CloseTaskStatusId = TaskStatusId from dbo.TaskStatus WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND StatusCode = 'COMPLETED'
			SELECT @CloseWOStatusId = Id from dbo.WorkOrderStatus WITH(NOLOCK) WHERE StatusCode = 'CLOSED'

				;WITH CTE AS(
						SELECT	
							SUM(ISNULL(wl.Hours,0)) AS [Hours],
							SUM(ISNULL(wl.Adjustments,0)) AS [Adjustments],
							SUM(ISNULL(wl.AdjustedHours,0)) AS [AdjustedHours],
							SUM(ISNULL(wl.BurdenRateAmount,0)) AS BurdenRateAmount,
							wowf.WorkOrderPartNoId  AS WorkOrderPartNoId
						FROM dbo.WorkOrder wo WITH (NOLOCK)
							INNER JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wo.WorkOrderId = wowf.WorkOrderId
							INNER JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WOP.ID = wowf.WorkFlowWorkOrderId							
							LEFT JOIN dbo.WorkOrderLaborHeader wlh WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1
							LEFT JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId AND wl.IsDeleted = 0 AND wl.IsActive = 1 AND ISNULL(wl.TaskStatusId, 0) != @CloseTaskStatusId
						WHERE wo.MasterCompanyId= @MasterCompanyId AND ISNULL(WOP.IsClosed, 0) = 0
				        GROUP BY wowf.WorkFlowWorkOrderId, wowf.WorkOrderPartNoId
						),

					Result AS(
							   SELECT 
									ISNULL(CTE.Hours,0) AS [Hours],
									ISNULL(CTE.Adjustments,0) AS [Adjustments],
									ISNULL(CTE.AdjustedHours,0) AS [AdjustedHours],
									ISNULL(CTE.BurdenRateAmount,0) AS BurdenRateAmount,
									im.partnumber AS PartNumber,
									im.PartDescription,
									wo.CustomerName AS Customer,
									wo.WorkOrderNum,
									ws.Stage,
									wst.[Status] As [mpnStatus],
									empexp.Description AS Expertise,
									empTech.FirstName + ' ' + empTech.LastName AS Assignedto,
									emps.StationName,
									wop.NTE as nte,
									wo.Memo,
									wo.WorkOrderId,
									WOP.ID AS workOrderPartNoId,
									wo.CustomerId,
									im.ItemMasterId,
									WOP.AssignDate As AssignedDate,
									wop.ExpertiseId as EmployeeExpertiseId,
									wop.TechnicianId as EmployeeId
								FROM dbo.WorkOrder wo 
									INNER JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WOP.WorkOrderId = wo.WorkOrderId AND ISNULL(WOP.IsClosed, 0) = 0 
									INNER JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.WorkOrderStageId
									INNER JOIN dbo.WorkOrderStatus wst WITH (NOLOCK) ON wst.Id = wop.WorkOrderStatusId
									INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId
									LEFT JOIN CTE as CTE WITH (NOLOCK) ON CTE.WorkOrderPartNoId = WOP.ID
									LEFT JOIN dbo.Employee empTech WITH (NOLOCK) ON empTech.EmployeeId = wop.TechnicianId
								    LEFT JOIN dbo.EmployeeExpertise empexp WITH (NOLOCK) ON empexp.EmployeeExpertiseId = wop.ExpertiseId
									LEFT JOIN dbo.EmployeeStation emps WITH (NOLOCK) ON emps.EmployeeStationId = wop.TechStationId
								WHERE wo.MasterCompanyId= @MasterCompanyId AND wst.Id != @CloseWOStatusId  
					), ResultCount AS(SELECT COUNT(WorkOrderId) AS totalItems FROM Result)
					SELECT * INTO #TempResult2 from  Result
					WHERE (
								(@GlobalFilter <>'' AND (
								(PartNumber like '%' +@GlobalFilter+'%') OR
								(PartDescription like '%' +@GlobalFilter+'%') OR
								(Customer like '%' +@GlobalFilter+'%') OR		
								(WorkOrderNum like '%' +@GlobalFilter+'%' ) OR 
								(Stage like '%' +@GlobalFilter+'%') OR
								(mpnStatus like '%' +@GlobalFilter+'%') OR
								(Expertise like '%'+@GlobalFilter+'%') OR
								(Assignedto like '%'+@GlobalFilter+'%') OR
								(StationName like '%' +@GlobalFilter+'%') OR
								(Memo like '%' +@GlobalFilter+'%') OR
								(nte like '%' +@GlobalFilter+'%')
								))
								OR   
								(@GlobalFilter='' AND (IsNull(@WorkOrderNum,'') ='' OR WorkOrderNum like '%' + @WorkOrderNum+'%') AND
								(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND
								(IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND
								(IsNull(@Customer,'') ='' OR Customer like '%' + @Customer+'%') AND
								(IsNull(@Stage,'') ='' OR Stage like '%' + @Stage+'%') AND
								(IsNull(@Status,'') ='' OR mpnStatus like '%' + @Status+'%') AND
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
					CASE WHEN (@SortOrder=1 and @SortColumn='Customer')  THEN Customer END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Stage')  THEN Stage END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN mpnStatus END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Expertise')  THEN Expertise END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Assignedto')  THEN Assignedto END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='StationName')  THEN StationName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Memo')  THEN Memo END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='AssignedDate')  THEN AssignedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='nte')  THEN nte END ASC,

					CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumber')  THEN PartNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PartDescription END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Customer')  THEN Customer END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Stage')  THEN Stage END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Status')  THEN mpnStatus END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Expertise')  THEN Expertise END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Assignedto')  THEN Assignedto END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='StationName')  THEN StationName END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Memo')  THEN Memo END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='AssignedDate')  THEN AssignedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='nte')  THEN nte END DESC

					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY	
			END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetAllWOAssignmentOpenItem' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''', 
													   @Parameter2 = ' + ISNULL(@PageSize ,'') +'''
													   @Parameter3 = ' + ISNULL(@SortColumn ,'') +'''
													   @Parameter4 = ' + ISNULL(@SortOrder ,'') +'''
													   @Parameter5 = ' + ISNULL(@GlobalFilter ,'') +'''
													   @Parameter8 = ' + ISNULL(@MasterCompanyId ,'') +'''
													   @Parameter9 = ' + ISNULL(@WorkOrderNum ,'') +'''
													   @Parameter10 = ' + ISNULL(@PartNumber ,'') +'''
													   @Parameter15 = ' + ISNULL(@Customer ,'') +'''
													   @Parameter16 = ' + ISNULL(@Stage ,'') +'''
													   @Parameter17 = ' + ISNULL(@Status ,'') +'''
													   @Parameter19 = ' + ISNULL(@Expertise ,'') +'''
													   @Parameter20 = ' + ISNULL(@Assignedto ,'') +'''
													   @Parameter21 = ' + ISNULL(@StationName ,'') +'''
													   @Parameter22 = ' + ISNULL(@Memo ,'') +'''
													   @Parameter23 = ' + ISNULL(@AssignedDate ,'') +'''
													   @Parameter24 = ' + ISNULL(@nte ,'') +'''
													   @Parameter25 = ' + ISNULL(@workOrderNumber ,'') +'''
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