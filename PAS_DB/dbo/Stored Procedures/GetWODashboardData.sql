

/*************************************************************           
 ** File:   [GetWODashboardData]           
 ** Author:   Hemant Saliya
 ** Description: This SP is Used to Get WO list By Stage
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
	2    05/03/2022   Hemant Saliya Remove Duplicate Records

exec GetWODashboardData @PageSize=10,@PageNumber=1,@SortColumn=N'OpenDate',@SortOrder=1,@WOTypeId=N'ALL',@GlobalFilter=N'',
@WorkOrderStageId=18,@WorkOrderNum=NULL,@PartNumber=NULL,@PartDescription=NULL,@Customer=NULL,@SerialNumber=NULL,
@WOType=N'ALL',@WOStage=NULL,@Priority=NULL,@StageDays=NULL,@Techname=NULL,@EstRevenue=0,@EstCost=0,
@EstMargin=0,@OpenDate=NULL,@CustReqDate=NULL,@PONumber=NULL,@RONumber=NULL,@MasterCompanyId=1

**************************************************************/

CREATE   PROCEDURE [dbo].[GetWODashboardData]
	@PageNumber INT,
	@PageSize INT,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT,
	@WOTypeId VARCHAR(50),
	@GlobalFilter VARCHAR(50) = null,
	@WorkOrderStageId BIGINT,
	@WorkOrderNum VARCHAR(50) = NULL,
	@PartNumber VARCHAR(50) = NULL,
	@PartDescription VARCHAR(50) = NULL,
	@Customer VARCHAR(50) = NULL,
	@SerialNumber VARCHAR(50) = NULL,
	@WOType VARCHAR(50) = NULL,
	@WOStage VARCHAR(50) = NULL,
	@Priority VARCHAR(50) = NULL,
	@StageDays INT = NULL,
	@Techname  VARCHAR(50) = NULL,
	@EstRevenue DECIMAL = NULL,
	@EstCost DECIMAL = NULL,
	@EstMargin DECIMAL = NULL,
	@OpenDate DATETIME = NULL,
	@CustReqDate DATETIME = NULL,
	@PONumber VARCHAR(50) = NULL,
	@RONumber VARCHAR(50) = NULL,
	@MasterCompanyId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	DECLARE @WorkOrderStatusId BIGINT;
	DECLARE @CustomerAffiliation VARCHAR(20);

	SELECT @WorkOrderStatusId  = Id FROM dbo.WorkOrderStatus WITH(NOLOCK) WHERE UPPER(StatusCode) = 'CLOSED'
	IF(UPPER(@WOTypeId) = 'INTERNAL')
	BEGIN
		SET @CustomerAffiliation = '1';
	END
	ELSE IF(UPPER(@WOTypeId) = 'EXTERNAL')
	BEGIN
		SET @CustomerAffiliation = '2';
	END
	ELSE IF(UPPER(@WOTypeId) = 'ALL')
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
				DECLARE @RecordFrom int;
				DECLARE @RecStageCode VARCHAR(20);

				IF OBJECT_ID(N'tempdb..#tmpWorkOrderData') IS NOT NULL
				BEGIN
				DROP TABLE #tmpWorkOrderData
				END

				CREATE TABLE #tmpWorkOrderData
				(
					 ID BIGINT NOT NULL IDENTITY, 					 
					 WorkOrderNum VARCHAR(20) NULL,
					 PartNumber VARCHAR(500) NULL,
					 PartDescription VARCHAR(500) NULL,
					 Customer VARCHAR(500) NULL,
					 SerialNumber VARCHAR(100) NULL,
					 WOStage VARCHAR(200) NULL,
					 WOType VARCHAR(200) NULL,
					 [Priority] VARCHAR(200) NULL,
					 Techname VARCHAR(200) NULL,
					 OpenDate VARCHAR(200) NULL,
					 CustReqDate VARCHAR(200) NULL,
					 EstRevenue DECIMAL(18,2) NULL,
					 EstCost DECIMAL(18,2) NULL,
					 EstMargin DECIMAL(18,2) NULL,
					 RONumber VARCHAR(200) NULL,
					 PONumber VARCHAR(200) NULL
				)

				SET @RecordFrom = (@PageNumber-1) * @PageSize;
				
				IF @SortColumn IS NULL
				BEGIN
					SET @SortColumn = Upper('OpenDate')
				END 
				ELSE
				BEGIN 
					SET @SortColumn = Upper(@SortColumn)
				END

				SELECT @RecStageCode = StageCode FROM dbo.WorkOrderStage WOSG WITH (NOLOCK) WHERE WorkOrderStageId = @WorkOrderStageId

				INSERT INTO #tmpWorkOrderData (WorkOrderNum, PartNumber, PartDescription, Customer, SerialNumber, WOStage, WOType,
				[Priority], Techname, OpenDate, CustReqDate, EstRevenue, EstCost, EstMargin, PONumber, RONumber)
				SELECT DISTINCT WO.WorkOrderNum, IM.partnumber AS PartNumber, IM.PartDescription, c.Name AS Customer,
					SL.SerialNumber, WOSG.Stage AS WOStage, 
					CASE WHEN UPPER(@WOTypeId) = 'INTERNAL' THEN 'INTERNAL' ELSE 'EXTERNAL' END AS WOType,
					p.Description AS [Priority], 
					(EMP.FirstName + ' ' + EMP.LastName) AS Techname, WO.OpenDate, WOP.CustomerRequestDate AS CustReqDate,
					ISNULL(WOC.Revenue, 0) AS EstRevenue,
					ISNULL(WOC.TotalCost, 0) AS EstCost, ISNULL(WOC.ActualMargin, 0) AS EstMargin,
					''  AS PONumber, WOP.CustomerReference AS RONumber
				FROM dbo.WorkOrder WO WITH (NOLOCK) 
					JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId				
					JOIN dbo.Customer C ON c.CustomerId = WO.CustomerId
					JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOP.ItemMasterId
					JOIN dbo.Stockline SL WITH (NOLOCK)  ON SL.StockLineId = WOP.StockLineId
					LEFT JOIN dbo.WorkOrderMPNCostDetails WOC WITH (NOLOCK) ON WOP.ID = WOC.WOPartNoId	
					LEFT JOIN dbo.WorkOrderStage WOSG WITH (NOLOCK)  ON WOSG.WorkOrderStageId = WOP.WorkOrderStageId
					LEFT JOIN dbo.Priority P WITH (NOLOCK)  ON P.PriorityId = WOP.WorkOrderPriorityId
					LEFT JOIN dbo.Employee EMP WITH (NOLOCK)  ON EMP.EmployeeId = WOP.TechnicianId
				WHERE WOP.MasterCompanyId = @MasterCompanyId AND WOP.WorkOrderStageId = @WorkOrderStageId AND WO.IsActive = 1 AND WO.IsDeleted = 0
					AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))

				UNION ALL 

				SELECT DISTINCT '' AS WorkOrderNum, IM.partnumber AS PartNumber, IM.PartDescription, c.Name AS Customer,
					SL.SerialNumber, 'RECEIVED' AS WOStage, CASE WHEN UPPER(@WOTypeId) = 'INTERNAL' THEN 'INTERNAL' ELSE 'EXTERNAL' END AS WOType, '' AS [Priority], 
					'' AS Techname, RC.ReceivedDate AS OpenDate, RC.CustReqDate AS CustReqDate,
					0 AS EstRevenue, 
					0 AS EstCost,
					0 AS EstMargin,
					''  AS PONumber, RC.Reference AS RONumber
				FROM dbo.ReceivingCustomerWork RC WITH (NOLOCK) 
					JOIN dbo.Customer C ON C.CustomerId = RC.CustomerId
					JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = RC.ItemMasterId
					JOIN dbo.Stockline SL WITH (NOLOCK)  ON SL.StockLineId = RC.StockLineId
				WHERE ISNULL(RC.WorkOrderId, 0) = 0 AND ISNULL(RC.RepairOrderPartRecordId, 0) = 0 AND RC.MasterCompanyId = @MasterCompanyId AND @RecStageCode = 'RECEIVED' AND
				 RC.IsActive = 1 AND RC.IsDeleted = 0 AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))

				UNION ALL 

				SELECT DISTINCT WO.WorkOrderNum, IM.partnumber AS PartNumber, IM.PartDescription, c.Name AS Customer,
					SL.SerialNumber, WOSG.Stage AS WOStage, CASE WHEN UPPER(@WOTypeId) = 'INTERNAL' THEN 'INTERNAL' ELSE 'EXTERNAL' END AS WOType, p.Description AS [Priority], 
					(EMP.FirstName + ' ' + EMP.LastName) AS Techname, WO.OpenDate, WOP.CustomerRequestDate AS CustReqDate,
					ISNULL(WOC.Revenue, 0) AS EstRevenue,
					--CASE WHEN ISNULL(WOC.ActualRevenue, 0) != 0 THEN ISNULL(WOC.ActualRevenue, 0) ELSE ISNULL(WOC.Revenue, 0) END AS EstRevenue, 
					ISNULL(WOC.TotalCost, 0) AS EstCost, ISNULL(WOC.ActualMargin, 0) AS EstMargin,
					''  AS PONumber, WOP.CustomerReference AS RONumber
				FROM dbo.WorkOrder WO WITH (NOLOCK) 
					JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId				
					JOIN dbo.Customer C ON c.CustomerId = WO.CustomerId
					JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOP.ItemMasterId
					JOIN dbo.Stockline SL WITH (NOLOCK)  ON SL.StockLineId = WOP.StockLineId
					LEFT JOIN dbo.WorkOrderMPNCostDetails WOC WITH (NOLOCK) ON WOP.ID = WOC.WOPartNoId	
					LEFT JOIN dbo.WorkOrderStage WOSG WITH (NOLOCK)  ON WOSG.WorkOrderStageId = WOP.WorkOrderStageId
					LEFT JOIN dbo.Priority P WITH (NOLOCK)  ON P.PriorityId = WOP.WorkOrderPriorityId
					LEFT JOIN dbo.Employee EMP WITH (NOLOCK)  ON EMP.EmployeeId = WOP.TechnicianId
				WHERE WOP.MasterCompanyId = @MasterCompanyId AND ISNULL(WOP.TechnicianId,0) = 0 AND @WorkOrderStageId = 222222 AND WO.IsActive = 1 AND WO.IsDeleted = 0   -- Static Data Bease No Stage Are Present
					AND WOP.IsClosed = 0 AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))

				UNION ALL 

				SELECT DISTINCT '' AS WorkOrderNum, IM.partnumber AS PartNumber, IM.PartDescription, c.Name AS Customer,
					SL.SerialNumber, 'RECEIVED' AS WOStage, CASE WHEN UPPER(@WOTypeId) = 'INTERNAL' THEN 'INTERNAL' ELSE 'EXTERNAL' END AS WOType, '' AS [Priority], 
					'' AS Techname, RC.ReceivedDate AS OpenDate, RC.CustReqDate AS CustReqDate,
					0 AS EstRevenue, 
					0 AS EstCost,
					0 AS EstMargin,
					''  AS PONumber, RC.Reference AS RONumber
				FROM dbo.ReceivingCustomerWork RC WITH (NOLOCK) 
					JOIN dbo.Customer C ON C.CustomerId = RC.CustomerId
					JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = RC.ItemMasterId
					JOIN dbo.Stockline SL WITH (NOLOCK)  ON SL.StockLineId = RC.StockLineId
				WHERE ISNULL(RC.WorkOrderId, 0) = 0 AND ISNULL(RC.RepairOrderPartRecordId, 0) = 0 AND RC.MasterCompanyId = @MasterCompanyId AND @WorkOrderStageId = 111111    -- Static Data Bease No Stage Are Present
				AND RC.IsActive = 1 AND RC.IsDeleted = 0 AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))

				;With Result AS(
					SELECT DISTINCT WorkOrderNum, PartNumber, PartDescription, Customer, SerialNumber, WOStage, WOType,
						[Priority], Techname, OpenDate, CustReqDate, EstRevenue, EstCost, EstMargin, PONumber, RONumber FROM #tmpWorkOrderData
					),
				FinalResult AS (
				SELECT WorkOrderNum, PartNumber, PartDescription, Customer, SerialNumber, WOStage, WOType,
				[Priority], Techname, OpenDate, CustReqDate, EstRevenue, EstCost, EstMargin, PONumber, RONumber FROM Result
				WHERE (
					(@GlobalFilter <> '' AND ((WorkOrderNum like '%' + @GlobalFilter +'%' ) OR 
							(OpenDate like '%' + @GlobalFilter +'%') OR
							(CustReqDate like '%' + @GlobalFilter +'%') OR
							(PartNumber like '%' + @GlobalFilter +'%') OR
							(PartDescription like '%'+ @GlobalFilter +'%') OR
							(Customer like '%' + @GlobalFilter +'%') OR
							(WOType like '%' + @GlobalFilter +'%') OR
							(Techname like '%' + @GlobalFilter +'%') OR
							(SerialNumber like '%' + @GlobalFilter +'%') OR
							([Priority] like '%' + @GlobalFilter +'%') OR
							(WOStage like '%' + @GlobalFilter +'%') OR
							(Techname like '%' + @GlobalFilter +'%') OR
							(CAST(EstRevenue AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
							(CAST(EstCost AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
							(CAST(EstMargin AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
							(PONumber like '%' + @GlobalFilter +'%') OR
							(RONumber like '%' + @GlobalFilter +'%')
							))
							OR   
							(@GlobalFilter = '' AND 
							(IsNull(@WorkOrderNum, '') = '' OR WorkOrderNum like  '%'+ @WorkOrderNum +'%') AND 
							(IsNull(@OpenDate, '') = '' OR Cast(OpenDate as Date) = Cast(@OpenDate as date)) AND
							(IsNull(@PartNumber, '') = '' OR PartNumber like '%'+ @PartNumber +'%') AND
							(IsNull(@PartDescription, '') = '' OR PartDescription like '%'+ @PartDescription +'%') AND
							(IsNull(@Customer, '') = '' OR Customer like '%'+ @Customer +'%') AND
							(IsNull(@Techname, '') = '' OR Techname like '%'+ @Techname +'%') AND
							(IsNull(@SerialNumber, '') = '' OR SerialNumber like '%'+ @SerialNumber +'%') AND
							(ISNULL(@EstRevenue,0) =0 OR EstRevenue = @EstRevenue) AND
						    (ISNULL(@EstCost,0) =0 OR EstCost = @EstCost) AND
							(ISNULL(@EstMargin,0) =0 OR EstMargin = @EstMargin) AND
							(IsNull(@Priority, '') = '' OR [Priority] like '%'+ @Priority +'%') AND
							(IsNull(@PONumber, '') = '' OR PONumber like '%'+ @PONumber +'%') AND
							(IsNull(@RONumber, '') = '' OR RONumber like '%'+ @RONumber +'%') AND
							(IsNull(@CustReqDate, '') = '' OR Cast(CustReqDate as Date) = Cast(@CustReqDate as date)))
							)),
					ResultCount AS (Select COUNT(WorkOrderNum) AS NumberOfItems FROM FinalResult)

					SELECT WorkOrderNum, PartNumber, PartDescription, Customer,SerialNumber, WOStage, [Priority], WOType,
					 Techname, OpenDate, CustReqDate,EstRevenue, EstCost,  EstMargin, PONumber, RONumber, NumberOfItems FROM FinalResult, ResultCount
					ORDER BY  
					CASE WHEN (@SortOrder = 1 AND @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='OPENDATE')  THEN OpenDate END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='CUSTOMER')  THEN Customer END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='WOTYPE')  THEN WOType END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='SERIALNUMBER')  THEN SerialNumber END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='WOSTAGE')  THEN WOStage END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='PRIORITY')  THEN Priority END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='TECHNAME')  THEN Techname END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='CUSTREQDATE')  THEN CustReqDate END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='ESTREVENUE')  THEN EstRevenue END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='ESTCOST')  THEN EstCost END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='ESTMARGINE')  THEN EstMargin END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='PONUMBER')  THEN PONumber END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn='RPONUMBER')  THEN RONumber END ASC,
				
					CASE WHEN (@SortOrder = -1 AND @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='OPENDATE')  THEN OpenDate END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='PARTNUMBER')  THEN PartNumber END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='CUSTOMER')  THEN Customer END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='WOTYPE')  THEN WOType END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='SERIALNUMBER')  THEN SerialNumber END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='WOSTAGE')  THEN WOStage END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='PRIORITY')  THEN Priority END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='TECHNAME')  THEN Techname END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='CUSTREQDATE')  THEN CustReqDate END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='ESTREVENUE')  THEN EstRevenue END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='ESTCOST')  THEN EstCost END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='ESTMARGINE')  THEN EstMargin END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='PONUMBER')  THEN PONumber END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn='RPONUMBER')  THEN RONumber END DESC

				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY

				IF OBJECT_ID(N'tempdb..#tmpWorkOrderData') IS NOT NULL
				BEGIN
				DROP TABLE #tmpWorkOrderData
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
              , @AdhocComments     VARCHAR(150)    = 'GetWODashboardData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + '''
													   @Parameter2 = '''+ ISNULL(@WorkOrderStageId, '') + '''
													   @Parameter3 = ' + ISNULL(@WOTypeId ,'') +''
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