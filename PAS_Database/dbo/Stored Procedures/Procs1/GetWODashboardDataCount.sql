/*************************************************************           
 ** File:   [GetWODashboardDataCount]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used get work order count based on stage  
 ** Purpose:         
 ** Date:   07/22/2022      
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/22/2022   Hemant Saliya Created
	2    03/08/2024   Bhargav Saliya  In WokOrder DashBoard  Count Issue Resolved
     
-- EXEC [GetWODashboardDataCount] 1,2,'internal'
**************************************************************/
CREATE PROCEDURE [dbo].[GetWODashboardDataCount]
	@MasterCompanyId BIGINT,
	@EmployeeId BIGINT,
	@Type VARCHAR(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	DECLARE @WorkOrderStatusId BIGINT;
	DECLARE @CustomerAffiliation VARCHAR(20);

	SELECT @WorkOrderStatusId  = Id FROM dbo.WorkOrderStatus WITH(NOLOCK) WHERE UPPER(StatusCode) = 'CLOSED'
	IF(@Type = 'internal')
	BEGIN
		SET @CustomerAffiliation = '1';
	END
	ELSE IF(@Type = 'external')
	BEGIN
		SET @CustomerAffiliation = '2';
	END
	ELSE IF(@Type = 'all')
	BEGIN
		SET @CustomerAffiliation = '1,2,3';
	END
	ELSE
	BEGIN
		SET @CustomerAffiliation = '1,2,3';
	END

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF OBJECT_ID(N'tempdb..#tmpWorkOrderStage') IS NOT NULL
				BEGIN
				DROP TABLE #tmpWorkOrderStage
				END

				CREATE TABLE #tmpWorkOrderStage
				(
					 ID BIGINT NOT NULL IDENTITY, 					 
					 WorkOrderStageId BIGINT NULL,
					 StatusId BIGINT NULL,
					 Stage VARCHAR(100) NULL,
					 Code VARCHAR(100) NULL,
					 StageCode VARCHAR(100) NULL,
					 CodeDescription VARCHAR(200) NULL,
					 Counts INT NULL,
					 Cost DECIMAL(18,2) NULL,
					 GroupNo INT NULL
				)

				--INSERT Static Data Bease No Stage are Present
				--INSERT INTO #tmpWorkOrderStage(WorkOrderStageId, StatusId, Stage, Code, StageCode, CodeDescription)
				--SELECT 111111, 0, 'WO NOT CREATED', '00', null, 'WO NOT CREATED' 

				--INSERT Static Data Bease No Stage are Present
				--INSERT INTO #tmpWorkOrderStage(WorkOrderStageId, StatusId, Stage, Code, StageCode, CodeDescription)
				--SELECT 222222, 0, 'TO BE ASSIGNED', '00', null, 'TO BE ASSIGNED'

				INSERT INTO #tmpWorkOrderStage(WorkOrderStageId, StatusId, Stage, Code, StageCode, CodeDescription)				
				SELECT WorkOrderStageId, StatusId, 
				UPPER(Stage) AS Stage, 
				UPPER(Code) AS Code, 
				UPPER(ISNULL(StageCode, '')), 
				UPPER(CodeDescription)
				FROM dbo.WorkOrderStage WITH (NOLOCK) 
				WHERE MasterCompanyId = @MasterCompanyId AND ISNULL(IncludeInDashboard, 0) = 1 AND IsActive = 1 AND IsDeleted = 0
				order by [Sequence] ASC

				UPDATE #tmpWorkOrderStage 
					SET Counts = ISNULL(T2.StageCount, 0)
				FROM #tmpWorkOrderStage AS WOS INNER JOIN (
				SELECT DISTINCT ISNULL(COUNT(DISTINCT WOP.ID), 0) AS StageCount, WorkOrderStageId  
				FROM dbo.WorkOrder WO WITH (NOLOCK) 
				JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId				
				JOIN dbo.Customer C ON c.CustomerId = WO.CustomerId
				WHERE WOP.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted = 0 AND WO.IsActive = 1
				AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				GROUP BY WOP.WorkOrderStageId) AS T2 ON WOS.WorkOrderStageId = T2.WorkOrderStageId

				UPDATE #tmpWorkOrderStage 
						SET Counts = ISNULL(Counts, 0) + (SELECT ISNULL(COUNT(DISTINCT ReceivingCustomerWorkId), 0) 
						FROM dbo.ReceivingCustomerWork RC WITH(NOLOCK) JOIN dbo.Customer C ON c.CustomerId = RC.CustomerId
						WHERE ISNULL(RC.WorkOrderId, 0) = 0 AND ISNULL(RC.RepairOrderPartRecordId, 0) = 0 
						AND RC.MasterCompanyId = @MasterCompanyId 
						AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ',')))
				FROM #tmpWorkOrderStage AS WOS 
				WHERE WOS.StageCode = 'RECEIVED'

				UPDATE #tmpWorkOrderStage 
					SET Counts = (SELECT ISNULL(COUNT(DISTINCT ReceivingCustomerWorkId), 0) 
					FROM dbo.ReceivingCustomerWork RC WITH(NOLOCK) 
					JOIN dbo.Customer C ON c.CustomerId = RC.CustomerId
					WHERE ISNULL(RC.WorkOrderId, 0) = 0 AND ISNULL(RC.RepairOrderPartRecordId, 0) = 0 AND RC.MasterCompanyId = @MasterCompanyId
					AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ',')))
				FROM #tmpWorkOrderStage AS WOS 
				WHERE WOS.WorkOrderStageId = 111111 --INSERT B'CoZ No Stage Are Present

				UPDATE #tmpWorkOrderStage 
					SET Counts = (SELECT DISTINCT ISNULL(COUNT(DISTINCT WO.WorkOrderId), 0) AS StageCount  
						FROM dbo.WorkOrder WO WITH (NOLOCK) 
						JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId				
						JOIN dbo.Customer C ON c.CustomerId = WO.CustomerId
						LEFT JOIN dbo.Employee EMP WITH (NOLOCK)  ON EMP.EmployeeId = WOP.TechnicianId
						WHERE WOP.MasterCompanyId = @MasterCompanyId AND ISNULL(WOP.TechnicianId,0) = 0 AND WO.IsDeleted = 0 AND WO.IsActive = 1
						AND WOP.IsClosed = 0 --AND WOP.IsDeleted = 0 AND WOP.IsActive = 1
						AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ',')))
				FROM #tmpWorkOrderStage AS WOS 
				WHERE WOS.WorkOrderStageId = 222222 --INSERT B'CoZ No Stage Are Present
				
				UPDATE #tmpWorkOrderStage 
					SET Cost = ISNULL(T2.TotalCost, 0)
				FROM #tmpWorkOrderStage AS WOS INNER JOIN (
				SELECT DISTINCT ISNULL(SUM(WOC.Revenue), 0) AS TotalCost, WorkOrderStageId  
				FROM dbo.WorkOrder WO WITH (NOLOCK) 
				JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId	
				JOIN dbo.WorkOrderMPNCostDetails WOC WITH (NOLOCK) ON WOP.ID = WOC.WOPartNoId	
				JOIN dbo.Customer C ON c.CustomerId = WO.CustomerId
				WHERE WOP.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted = 0 AND WO.IsActive = 1--AND WO.WorkOrderStatusId  != @WorkOrderStatusId
				AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				GROUP BY WOP.WorkOrderStageId) AS T2 ON WOS.WorkOrderStageId = T2.WorkOrderStageId

				UPDATE #tmpWorkOrderStage 
					SET Cost = ISNULL(T2.TotalCost, 0)
				FROM #tmpWorkOrderStage AS WOS INNER JOIN (
				SELECT DISTINCT ISNULL(SUM(WOC.Revenue), 0) AS TotalCost  
				FROM dbo.WorkOrder WO WITH (NOLOCK) 
				JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId	
				JOIN dbo.WorkOrderMPNCostDetails WOC WITH (NOLOCK) ON WOP.ID = WOC.WOPartNoId	
				JOIN dbo.Customer C ON c.CustomerId = WO.CustomerId
				WHERE WOP.MasterCompanyId = @MasterCompanyId AND ISNULL(WOP.TechnicianId,0) = 0 AND WO.IsDeleted = 0 AND WO.IsActive = 1--AND WO.WorkOrderStatusId  != @WorkOrderStatusId
				AND WOP.IsClosed = 0 AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				) AS T2 ON WOS.WorkOrderStageId = 222222

				SELECT *, 
				RowNumber = CASE WHEN((ROW_NUMBER() OVER (ORDER BY (SELECT NULL)))  % 4) = 0 THEN 4 ELSE (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)))  % 4 END
				FROM #tmpWorkOrderStage Order by ID ASC

				IF OBJECT_ID(N'tempdb..#tmpWorkOrderStage') IS NOT NULL
				BEGIN
				DROP TABLE #tmpWorkOrderStage
				END

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWODashboardDataCount' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + '''
													   @Parameter2 = '''+ ISNULL(@EmployeeId, '') + '''
													   @Parameter3 = ' + ISNULL(@Type ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END