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
    1    07/22/2022   Hemant Saliya   Created
	2    03/08/2024   Bhargav Saliya  In WokOrder DashBoard  Count Issue Resolved
	3	 12 NOV 2024  HEMANT SALIYA	  Verify the count and removed un used code 
	4	 31/12/2024	  Bhargav saliya  In WO DashBoards Resolved [RECEIVED] Count Issue (PN-10677)
     
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

				INSERT INTO #tmpWorkOrderStage(WorkOrderStageId, StatusId, Stage, Code, StageCode, CodeDescription)				
				SELECT WorkOrderStageId, StatusId, 
					UPPER(Stage) AS Stage, 
					UPPER(Code) AS Code, 
					UPPER(ISNULL(StageCode, '')), 
					UPPER(CodeDescription)
				FROM dbo.WorkOrderStage WITH (NOLOCK) 
				WHERE MasterCompanyId = @MasterCompanyId AND ISNULL(IncludeInDashboard, 0) = 1 AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0
				order by [Sequence] ASC

				UPDATE #tmpWorkOrderStage 
					SET Counts = ISNULL(T2.StageCount, 0)
				FROM #tmpWorkOrderStage AS WOS INNER JOIN (
				SELECT DISTINCT ISNULL(COUNT(DISTINCT WOP.ID), 0) AS StageCount, WorkOrderStageId  
				FROM dbo.WorkOrder WO WITH (NOLOCK) 
					JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId				
					JOIN dbo.Customer C WITH (NOLOCK) ON c.CustomerId = WO.CustomerId
				WHERE WOP.MasterCompanyId = @MasterCompanyId AND ISNULL(WO.IsDeleted, 0) = 0 AND ISNULL(WO.IsActive, 0) = 1
				AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				GROUP BY WOP.WorkOrderStageId) AS T2 ON WOS.WorkOrderStageId = T2.WorkOrderStageId

				UPDATE #tmpWorkOrderStage 
						SET Counts = ISNULL(Counts, 0) + (SELECT ISNULL(COUNT(DISTINCT ReceivingCustomerWorkId), 0) 
						FROM dbo.ReceivingCustomerWork RC WITH(NOLOCK) JOIN dbo.Customer C WITH (NOLOCK) ON c.CustomerId = RC.CustomerId
						WHERE ISNULL(RC.WorkOrderId, 0) = 0 AND ISNULL(RC.RepairOrderPartRecordId, 0) = 0 
						AND RC.MasterCompanyId = @MasterCompanyId	AND  RC.IsActive = 1 AND RC.IsDeleted = 0
						AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ',')))
				FROM #tmpWorkOrderStage AS WOS 
				WHERE WOS.StageCode = 'RECEIVED'
				
				UPDATE #tmpWorkOrderStage 
					SET Cost = ISNULL(T2.TotalCost, 0)
				FROM #tmpWorkOrderStage AS WOS INNER JOIN (
				SELECT DISTINCT ISNULL(SUM(WOC.Revenue), 0) AS TotalCost, WorkOrderStageId  
				FROM dbo.WorkOrder WO WITH (NOLOCK) 
					JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId	
					JOIN dbo.WorkOrderMPNCostDetails WOC WITH (NOLOCK) ON WOP.ID = WOC.WOPartNoId	
					JOIN dbo.Customer C WITH (NOLOCK) ON c.CustomerId = WO.CustomerId
				WHERE WOP.MasterCompanyId = @MasterCompanyId AND ISNULL(WO.IsDeleted, 0) = 0 AND ISNULL(WO.IsActive, 0) = 1--AND WO.WorkOrderStatusId  != @WorkOrderStatusId
					AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				GROUP BY WOP.WorkOrderStageId) AS T2 ON WOS.WorkOrderStageId = T2.WorkOrderStageId

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