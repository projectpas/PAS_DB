 /*************************************************************           
 ** File:   [GetWorkOrderList]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used to get work order List for both MPN and WO View
 ** Purpose:         
 ** Date:   
          
 ** PARAMETERS:          

 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/28/2023   Vishal Suthar			Added history
    2    08/01/2023   Vishal Suthar			Converting all the data in Upper case which was creating an issue in download
	3    23 Jul2023   Rajesh Gami			Improve Performance
	4    05/08/2024   HEMANT SALIYA			Serial Number Changes Updated
	5    09/20/2024   Devendra Shekh		List WO View Resolved
	6    10/18/2024   Devendra Shekh		Using @WorkOrderStatus for WorkOrderStatusId comparison
	7    10/21/2024   Devendra Shekh		Modified (Optimization Changes)
	8    11/18/2024   Sahdev Saliya         Added New Field IsSubWorkOrder
	9    11/20/2024   Sahdev Saliya         SubWorkOrder Issue Resolved And Multipal WO Issue Resolved
	10   12/31/2024   Devendra Shekh        added new Fields :- mpnQuoteStatus, approvedAmount
	11   02/04/2025   Bhargav Saliya        UTC Date Changes
	12   25/06/2025   Vishal Suthar			Performance Improvement
	13   25/06/2025   HEMANT SALIYA			Optimize SP to reduce wating time
	14   18/07/2025   Vishal Suthar			Added DISTINCT in the final resultset which was populating duplicate entry
	15   24/07/2025   Devendra Shekh		added WOPartId for MPN View
	16   26/08/2025   Moin Bloch		    added RevisedSerialNumber 

	exec dbo.GetWorkOrderList @PageNumber=1,@PageSize=100,@SortColumn=default,@SortOrder=-1,@StatusID=1,@GlobalFilter=default,@ViewType=N'mpn',
	@WorkOrderNum=default,@PartNumber=default,@PartDescription=default,@WorkScope=default,@Priority=default,@CustomerName=default,@CustomerAffiliation=default,@Stage=default,
	@WorkOrderStatus=1,@OpenDate=default,@CustReqDate=default,@PromiseDate=default,@EstShipDate=default,@ShipDate=default,@CreatedDate=default,@UpdatedDate=default,@CreatedBy=default,
	@UpdatedBy=default,@IsDeleted=0,@MasterCompanyId=11,@EmployeeId=98,@WorkOrderStatusType=default,@TechName=default,@TechStation=default,@SerialNumber=default,@CustRef=default,
	@MSModuleID=12,@ManufacturerName=default,@WorkOrderType=default,@IsSubWorkOrder=default,@MPNQuoteStatus=default,@ApprovedAmount=default
     
**************************************************************/
CREATE   PROCEDURE [dbo].[GetWorkOrderList]
 -- Add the parameters for the stored procedure here  
	 @PageNumber INT,  
	 @PageSize INT,  
	 @SortColumn VARCHAR(50)=NULL,  
	 @SortOrder INT,  
	 @StatusID INT,  
	 @GlobalFilter VARCHAR(50) = '',  
	 @ViewType VARCHAR(50) = NULL,  
	 @WorkOrderNum VARCHAR(50)=NULL,  
	 @PartNumber VARCHAR(50)=NULL,  
	 @PartDescription VARCHAR(50)=NULL,  
	 @WorkScope VARCHAR(50)=NULL,  
	 @Priority VARCHAR(50)=NULL,  
	 @CustomerName VARCHAR(50)=NULL,  
	 @CustomerAffiliation VARCHAR(50)=NULL,  
	 @Stage VARCHAR(200)=NULL,  
	 @WorkOrderStatus BIGINT=NULL,      
	 @OpenDate DATETIME=NULL,  
	 @CustReqDate DATETIME=NULL,  
	 @PromiseDate DATETIME=NULL,  
	 @EstShipDate DATETIME=NULL,  
	 @ShipDate DATETIME=NULL,  
	 @CreatedDate DATETIME=NULL,  
	 @UpdatedDate  DATETIME=NULL,  
	 @CreatedBy  VARCHAR(50)=NULL,  
	 @UpdatedBy  VARCHAR(50)=NULL,  
	 @IsDeleted BIT= NULL,  
	 @MasterCompanyId VARCHAR(200)=NULL,  
	 @EmployeeId VARCHAR(200)=NULL,   
	 @WorkOrderStatusType VARCHAR(200)=NULL,  
	 @WorkOrderType VARCHAR(50)=NULL,  
	 @TechName  VARCHAR(50)=NULL,  
	 @TechStation  VARCHAR(50)=NULL, 
	 @SerialNumber  VARCHAR(50)=NULL,  
	 @RevisedSerialNumber VARCHAR(50)=NULL,  
	 @CustRef VARCHAR(50)=NULL,
	 @MSModuleID INT=12,
	 @ManufacturerName VARCHAR(50)=NULL,
	 @IsSubWorkOrder VARCHAR(50) = NULL,
	 @MPNQuoteStatus VARCHAR(50) = NULL,
	 @ApprovedAmount VARCHAR(50) = NULL

AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  --BEGIN TRANSACTION  
  -- BEGIN   
    DECLARE @RecordFrom INT;  
    DECLARE @IsActive BIT=1  
    DECLARE @Count INT;  
    DECLARE @WorkOrderStatusId INT;    
  
    IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL  
    BEGIN  
		DROP TABLE #TempResult   
    END  
  
    IF OBJECT_ID(N'tempdb..#TempResult1') IS NOT NULL  
    BEGIN  
		DROP TABLE #TempResult1  
    END  
  
    SET @RecordFrom = (@PageNumber-1)*@PageSize;  
    IF @IsDeleted IS NULL  
    BEGIN  
		SET @IsDeleted = 0;
    END    
  
    IF (@ViewType IS NULL OR @ViewType = '')  
    BEGIN  
		SET @ViewType= 'mpn';
    END   
  
    IF (@GlobalFilter IS NULL OR @GlobalFilter = '')  
    BEGIN  
		SET @GlobalFilter= '';
    END   
  
    IF @SortColumn IS NULL
    BEGIN  
		SET @SortColumn = UPPER('CreatedDate')
    END
    ELSE
    BEGIN   
		SET @SortColumn=UPPER(@SortColumn)  
    END  
  
    IF @StatusID = 0  
    BEGIN   
		SET @IsActive = 0  
    END   
    ELSE IF @StatusID = 1  
    BEGIN   
		SET @IsActive = 1  
    END   
    ELSE IF @StatusID = 2  
    BEGIN   
		SET @IsActive = NULL  
    END

	DECLARE @WOApprovalDesc VARCHAR(200);  
	SELECT @WOApprovalDesc = [Description] FROM [dbo].[ApprovalStatus] WITH(NOLOCK) WHERE UPPER([Description]) = 'APPROVED';

	DECLARE @BaseUtcOffsetSec INT    
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId; 

	-- Fetch the UTC offset in seconds
	SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec  
	FROM dbo.TimeZone WITH(NOLOCK)  
	WHERE [Description] = @CurrntEmpTimeZoneDesc

	--IF OBJECT_ID('tempdb..#SubWOResult') IS NOT NULL
	--	DROP TABLE #SubWOResult

	--CREATE TABLE #SubWOResult
	--(
	--	[Id] BIGINT IDENTITY(1,1),
	--	[WorkOrderId] BIGINT NULL,
	--	[IsSubWorkOrder] varchar(50) NULL,
	--	[WorkOrderPartNumberId] BIGINT NULL
	--)

	--INSERT INTO #SubWOResult([WorkOrderId], [IsSubWorkOrder], [WorkOrderPartNumberId])
	--SELECT WO.WorkOrderId, 'Yes', SWO.WorkOrderPartNumberId FROM
	--[dbo].[SubWorkOrder] SWO WITH(NOLOCK)
	--JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON SWO.WorkOrderId = WO.WorkOrderId
	--WHERE ISNULL(SWO.IsDeleted,0) = 0
	--GROUP BY WO.WorkOrderId,SWO.WorkOrderPartNumberId

    IF LOWER(@ViewType) = 'mpn'  
     BEGIN  
		CREATE TABLE #TempResult (
			[WorkOrderNum] NVARCHAR(100),
			[WorkOrderId] NVARCHAR(100),
			[CustomerId] NVARCHAR(100),
			[PartNos] NVARCHAR(100),
			[PartNoType] NVARCHAR(100),
			[PNDescription] NVARCHAR(500),
			[PNDescriptionType] NVARCHAR(500),
			[ManufacturerName] NVARCHAR(200),
			[ManufacturerNameType] NVARCHAR(200),
			[WorkScope] NVARCHAR(200),
			[WorkScopeType] NVARCHAR(200),
			[Priority] NVARCHAR(50),
			[PriorityType] NVARCHAR(50),
			[CustomerName] NVARCHAR(200),
			[CustomerType] NVARCHAR(100),
			[Stage] NVARCHAR(100),
			[StageType] NVARCHAR(100),
			[WorkOrderStatus] NVARCHAR(100),
			[WorkOrderStatusType] NVARCHAR(100),
			[OpenDate] DATE,
			[CustomerRequestDate] DATE,
			[CustomerRequestDateType] DATE,
			[PromisedDate] DATE,
			[PromisedDateType] DATE,
			[EstimatedShipDate] DATE,
			[EstimatedShipDateType] DATE,
			[EstimatedCompletionDateType] NVARCHAR(50),
			[EstimatedCompletionDate] DATE,
			[CreatedDate] DATETIME,
			[UpdatedDate] DATETIME,
			[CreatedBy] NVARCHAR(100),
			[UpdatedBy] NVARCHAR(100),
			[IsActive] BIT,
			[IsDeleted] BIT,
			[WorkOrderStatusId] INT,
			[WorkOrderType] NVARCHAR(100),
			[TechName] NVARCHAR(100),
			[TechStation] NVARCHAR(100),
			[SerialNumber] NVARCHAR(100),
			[RevisedSerialNumber] NVARCHAR(100),
			[CustomerReference] NVARCHAR(100),
			[CustomerReferenceType] NVARCHAR(100),
			[IsSubWorkOrder] NVARCHAR(10),
			[MPNQuoteStatus] NVARCHAR(100),
			[ApprovedAmount] NVARCHAR(100),
			[WOPartId] NVARCHAR(100)
		);

		-- 2. Create the index for faster filtering/sorting
		CREATE NONCLUSTERED INDEX IX_TempResult_WorkOrderId ON #TempResult (WorkOrderId);

      ;WITH 
	 --   LatestShipping AS (
		--SELECT	WorkOrderId,
		--		FORMAT(MAX(ShipDate), 'yyyy-MM-ddTHH:mm:ss') AS EstimatedCompletionDate
		--		FROM [dbo].[WorkOrderShipping] WITH (NOLOCK)
		--		GROUP BY WorkOrderId
	 --  )
	 --  ,
	   Result AS(  
       SELECT   
			UPPER(WO.[WorkOrderNum]) AS [WorkOrderNum],
			UPPER(WO.[WorkOrderId]) AS [WorkOrderId],
			UPPER(WO.[CustomerId]) AS [CustomerId],
			--CASE WHEN ISNULL(WPN.RevisedPartNumber, '') != '' THEN UPPER(WPN.RevisedPartNumber) ELSE UPPER(WPN.PartNumber) END AS PartNos,
			UPPER(ISNULL(NULLIF(WPN.[RevisedPartNumber], ''), WPN.[PartNumber])) AS [PartNos],
			--CASE WHEN ISNULL(WPN.RevisedPartNumber, '') != '' THEN UPPER(WPN.RevisedPartNumber) ELSE UPPER(WPN.PartNumber) END AS PartNoType,
			UPPER(ISNULL(NULLIF(WPN.[RevisedPartNumber], ''), WPN.[PartNumber])) AS [PartNoType],
			--CASE WHEN ISNULL(WPN.RevisedPartDescription, '') != '' THEN UPPER(WPN.RevisedPartDescription) ELSE UPPER(WPN.PartDescription) END AS PNDescription,
			UPPER(ISNULL(NULLIF(WPN.[RevisedPartDescription], ''), WPN.[PartDescription])) AS [PNDescription],
			--CASE WHEN ISNULL(WPN.RevisedPartDescription, '') != '' THEN UPPER(WPN.RevisedPartDescription) ELSE UPPER(WPN.PartDescription) END AS PNDescriptionType,
			UPPER(ISNULL(NULLIF(WPN.[RevisedPartDescription], ''), WPN.[PartDescription])) AS [PNDescriptionType],
			UPPER(WPN.[ManufacturerName]) AS [ManufacturerName],  
			UPPER(WPN.[ManufacturerName]) AS [ManufacturerNameType],  
			UPPER(WPN.[WorkScope]) AS [WorkScope],
			UPPER(WPN.[WorkScope]) AS [WorkScopeType],
			UPPER(WPN.[Priority]) AS [Priority],
			UPPER(WPN.[Priority]) As [PriorityType],
			UPPER(WO.[CustomerName]) AS [CustomerName],
			UPPER(WO.[CustomerType]) AS [CustomerType],
			UPPER(WPN.[WorkOrderStage]) AS [Stage],  
			UPPER(WPN.[WorkOrderStage]) AS [StageType],  
			UPPER(WPN.[WorkOrderStatus]) AS [WorkOrderStatus],  
			UPPER(WPN.[WorkOrderStatus]) AS [WorkOrderStatusType],  
			CASE WHEN CAST(WO.[OpenDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE CAST(DATEADD(SECOND, @BaseUtcOffsetSec, WO.[OpenDate]) AS DATE) END [OpenDate], 
			--CASE WHEN CAST(WO.OpenDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(WO.OpenDate, @CurrntEmpTimeZoneDesc) AS DATE)) END OpenDate, 
			WPN.[CustomerRequestDate],  
			WPN.[CustomerRequestDate] AS [CustomerRequestDateType],  
			WPN.[PromisedDate],  
			WPN.[PromisedDate] AS [PromisedDateType],  
			WPN.[EstimatedShipDate],  
			WPN.[EstimatedShipDate] AS [EstimatedShipDateType],  
			LWS.[EstimatedCompletionDate] AS [EstimatedCompletionDateType],
			LWS.[EstimatedCompletionDate] AS [EstimatedCompletionDate],
			--((SELECT top 1 ShipDate FROM dbo.WorkOrderShipping wosp WITH(NOLOCK) WHERE WorkOrderId = WO.WorkOrderId ORDER BY WorkOrderShippingId desc))as EstimatedCompletionDate,  
			--((SELECT top 1 ShipDate FROM dbo.WorkOrderShipping wosp WITH(NOLOCK) WHERE WorkOrderId = WO.WorkOrderId ORDER BY WorkOrderShippingId desc))as EstimatedCompletionDateType,  
			WO.[CreatedDate],
			CASE WHEN CAST(WO.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE CAST(DATEADD(SECOND, @BaseUtcOffsetSec, WO.[UpdatedDate]) AS DATE) END [UpdatedDate],
			--CASE WHEN CAST(WO.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(WO.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATE))END UpdatedDate,
			UPPER(WO.[CreatedBy]) AS [CreatedBy],
			UPPER(WO.[UpdatedBy]) AS [UpdatedBy],
			WO.[IsActive],  
			WO.[IsDeleted],  
			WPN.[WorkOrderStatusId],  
			UPPER(WO.[WorkOrderType]) AS [WorkOrderType],
			UPPER(WPN.[TechName]) AS [TechName],
			UPPER(WPN.[EmployeeStation]) AS [TechStation],			
			UPPER(WPN.[CurrentSerialNumber]) AS [SerialNumber],		
			CASE WHEN ISNULL(WPN.[RevisedSerialNumber], '') != '' THEN UPPER(WPN.[RevisedSerialNumber]) ELSE UPPER(WPN.[CurrentSerialNumber]) END AS [RevisedSerialNumber],
			UPPER(WPN.[CustomerReference]) AS [CustomerReference],
			UPPER(WPN.[CustomerReference]) AS [CustomerReferenceType]
			,ISNULL(SWO.[IsSubWorkOrder], 'No') AS [IsSubWorkOrder],
			UPPER(wqs.[Description]) AS [MPNQuoteStatus],
			CAST(CASE WHEN ISNULL(WOQD.[QuoteMethod], 0) = 1 THEN ISNULL( WOQD.[CommonFlatRate] , 0) ELSE  
			ISNULL(ISNULL(ISNULL(WOQD.[MaterialFlatBillingAmount], 0) + ISNULL(WOQD.[LaborFlatBillingAmount], 0) + ISNULL(WOQD.[ChargesFlatBillingAmount], 0),0) ,0) END AS VARCHAR) 'ApprovedAmount',
			WPN.[ID] AS [WOPartId]
			FROM [dbo].[WorkOrder] WO WITH(NOLOCK)  
			JOIN [dbo].[WorkOrderPartNumber] WPN WITH(NOLOCK) ON WO.[WorkOrderId] = WPN.[WorkOrderId]  
			OUTER APPLY (
				SELECT TOP 1 FORMAT([ShipDate], 'yyyy-MM-ddTHH:mm:ss') AS [EstimatedCompletionDate]
				FROM [dbo].[WorkOrderShipping] WITH (NOLOCK)
				WHERE [WorkOrderId] = WO.[WorkOrderId]
				ORDER BY [ShipDate] DESC
			) AS LWS
			--LEFT JOIN #SubWOResult SWO ON WO.WorkOrderId = SWO.WorkOrderId AND WPN.ID = SWO.WorkOrderPartNumberId
			OUTER APPLY (
				SELECT TOP 1 'Yes' AS [IsSubWorkOrder]
				FROM [dbo].[SubWorkOrder] SWO WITH(NOLOCK)
				WHERE 
					SWO.[WorkOrderId] = WO.[WorkOrderId]
					AND SWO.[WorkOrderPartNumberId] = WPN.[ID]
					AND ISNULL(SWO.[IsDeleted], 0) = 0
			) AS SWO
			--JOIN dbo.WorkOrderType WT WITH(NOLOCK) ON WO.WorkOrderTypeId = WT.Id  
			--JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WPN.ID = WOWF.WorkOrderPartNoId  
			--JOIN dbo.WorkOrderStatus WOS WITH(NOLOCK) ON WOS.Id = WPN.WorkOrderStatusId  
			--JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId         
			--JOIN dbo.Priority PR WITH(NOLOCK) ON WPN.WorkOrderPriorityId = PR.PriorityId  
			--JOIN dbo.WorkOrderStage WOSG WITH(NOLOCK) ON WPN.WorkOrderStageId = WOSG.WorkOrderStageId  
			--LEFT JOIN dbo.Stockline STL WITH(NOLOCK) ON WPN.StockLineId = STL.StockLineId  
			--LEFT JOIN dbo.Employee EMP WITH(NOLOCK) ON EMP.EmployeeId = WPN.TechnicianId  
			--LEFT JOIN dbo.EmployeeStation EMPS WITH(NOLOCK) ON WPN.TechStationId = EMPS.EmployeeStationId
			--LEFT JOIN dbo.WorkOrderShipping wosp  WITH(NOLOCK) on WO.WorkOrderId = wosp.WorkOrderId  
			--LEFT JOIN dbo.WorkOrderQuote woq WITH (NOLOCK) on woq.WorkOrderId = WPN.WorkOrderId
			LEFT JOIN [dbo].[WorkOrderQuoteDetails] WOQD WITH (NOLOCK) ON WPN.[ID] = WOQD.[WOPartNoId] AND WOQD.[IsActive] = 1 AND WOQD.[IsVersionIncrease] = 0 
			LEFT JOIN [dbo].[WorkOrderQuote] woq WITH (NOLOCK) ON woq.[workorderquoteid] = WOQD.[workorderquoteid]
			LEFT JOIN [dbo].[WorkOrderQuoteStatus] wqs WITH (NOLOCK) ON woq.[QuoteStatusId] = wqs.[WorkOrderQuoteStatusId] 
		WHERE ((WO.[MasterCompanyId] = @MasterCompanyId) AND (WO.[IsDeleted] = @IsDeleted) AND (@IsActive IS NULL OR WO.[IsActive] = @IsActive) AND (@WorkOrderStatus = 0 OR WPN.[WorkOrderStatusId] = @WorkOrderStatus))  
        ),
		QuoteResult AS (
			SELECT [WorkOrderNum], [WorkOrderId], [CustomerId], [PartNos], [PartNoType], [PNDescription], [PNDescriptionType], [ManufacturerName], [ManufacturerNameType], [WorkScope], [WorkScopeType], [Priority], [PriorityType], [CustomerName], [CustomerType], [Stage], [StageType], [WorkOrderStatus], [WorkOrderStatusType], [OpenDate], [CustomerRequestDate], [CustomerRequestDateType],
				[PromisedDate], [PromisedDateType], [EstimatedShipDate], [EstimatedShipDateType], [EstimatedCompletionDateType], [EstimatedCompletionDate], [CreatedDate], [UpdatedDate], [CreatedBy], [UpdatedBy], [IsActive], [IsDeleted], [WorkOrderStatusId], [WorkOrderType], [TechName], [TechStation], [SerialNumber],[RevisedSerialNumber],
				[CustomerReference], [CustomerReferenceType], [IsSubWorkOrder], [MPNQuoteStatus],
				CASE WHEN [MPNQuoteStatus] = @WOApprovalDesc THEN [ApprovedAmount] ELSE '' END AS [ApprovedAmount], [WOPartId]
			FROM Result
		),
		ResultCount AS(SELECT COUNT(WorkOrderId) AS totalItems FROM QuoteResult)  
        --SELECT * INTO #TempResult from  QuoteResult
		INSERT INTO #TempResult
		SELECT DISTINCT [WorkOrderNum], [WorkOrderId], [CustomerId], [PartNos], [PartNoType], [PNDescription], [PNDescriptionType],
			   [ManufacturerName], [ManufacturerNameType], [WorkScope], [WorkScopeType], [Priority], [PriorityType], [CustomerName],
			   [CustomerType], [Stage], [StageType], [WorkOrderStatus], [WorkOrderStatusType], [OpenDate], [CustomerRequestDate],
			   [CustomerRequestDateType], [PromisedDate], [PromisedDateType], [EstimatedShipDate], [EstimatedShipDateType],
			   [EstimatedCompletionDateType], [EstimatedCompletionDate], [CreatedDate], [UpdatedDate], [CreatedBy], [UpdatedBy],
			   [IsActive], [IsDeleted], [WorkOrderStatusId], [WorkOrderType], [TechName], [TechStation], [SerialNumber],[RevisedSerialNumber],
			   [CustomerReference], [CustomerReferenceType], [IsSubWorkOrder], [MPNQuoteStatus], [ApprovedAmount], [WOPartId]
		FROM QuoteResult
        WHERE (  
        (@GlobalFilter <>'' AND 
			(  
			([WorkOrderNum] LIKE '%' +@GlobalFilter+'%') OR  
			([WorkOrderType] LIKE '%' +@GlobalFilter+'%') OR  
			([PartNos] LIKE '%' +@GlobalFilter+'%') OR  
			([PNDescription] LIKE '%' +@GlobalFilter+'%') OR
			([ManufacturerName] LIKE '%' +@GlobalFilter+'%') OR  
			([WorkScope] LIKE '%' +@GlobalFilter+'%') OR  
			([Priority] LIKE '%' +@GlobalFilter+'%') OR    
			([CustomerName] LIKE '%' +@GlobalFilter+'%' ) OR   
			([CustomerType] LIKE '%' +@GlobalFilter+'%') OR  
			([Stage] LIKE '%' +@GlobalFilter+'%') OR  
			([TechName] LIKE '%' +@GlobalFilter+'%') OR  
			([TechStation] LIKE '%' +@GlobalFilter+'%') OR  
			([WorkOrderStatus] LIKE '%'+@GlobalFilter+'%') OR  
			([WorkOrderStatusType] LIKE '%'+@GlobalFilter+'%') OR  
			([CreatedBy] LIKE '%' +@GlobalFilter+'%') OR  
			([UpdatedBy] LIKE '%' +@GlobalFilter+'%') OR  
			([SerialNumber] LIKE '%' +@GlobalFilter+'%') OR  
			([RevisedSerialNumber] LIKE '%' +@GlobalFilter+'%') OR  			
			([CustomerReference] LIKE '%' +@GlobalFilter+'%') OR
			([MPNQuoteStatus] LIKE '%' +@GlobalFilter+'%') OR
			([ApprovedAmount] LIKE '%' +@GlobalFilter+'%') OR
			([IsSubWorkOrder] LIKE '%' + @GlobalFilter +'%')
			)
		)  
        OR     
        (@GlobalFilter='' AND (ISNULL(@WorkOrderNum,'') ='' OR [WorkOrderNum] LIKE '%' + @WorkOrderNum+'%') AND  
        (ISNULL(@PartNumber,'') ='' OR [PartNos] LIKE '%' + @PartNumber+'%') AND  
        (ISNULL(@PartDescription,'') ='' OR [PNDescription] LIKE '%' + @PartDescription+'%') AND 
		(ISNULL(@ManufacturerName,'') ='' OR [ManufacturerName] LIKE '%' + @ManufacturerName+'%') AND  
        (ISNULL(@WorkScope,'') ='' OR [WorkScope] LIKE '%' + @WorkScope+'%') AND  
        (ISNULL(@WorkOrderType,'') ='' OR [WorkOrderType] LIKE '%' + @WorkOrderType+'%') AND  
        (ISNULL(@Priority,'') ='' OR [Priority] LIKE '%' + @Priority+'%') AND  
        (ISNULL(@CustomerName,'') ='' OR [CustomerName] LIKE '%' + @CustomerName+'%') AND  
        (ISNULL(@CustomerAffiliation,'') ='' OR [CustomerType] LIKE '%' + @CustomerAffiliation+'%') AND  
        (ISNULL(@Stage,'') ='' OR [Stage] LIKE '%' + @Stage+'%') AND  
        (ISNULL(@TechName,'') ='' OR [TechName] LIKE '%' + @TechName+'%') AND  
        (ISNULL(@TechStation,'') ='' OR [TechStation] LIKE '%' + @TechStation+'%') AND  
        (ISNULL(@WorkOrderStatusType,'') ='' OR [WorkOrderStatusType] LIKE '%' + @WorkOrderStatusType+'%') AND  
        (ISNULL(@CreatedBy,'') ='' OR [CreatedBy] LIKE '%' + @CreatedBy+'%') AND  
        (ISNULL(@UpdatedBy,'') ='' OR [UpdatedBy] LIKE '%' + @UpdatedBy+'%') AND  
		(ISNULL(@OpenDate,'') ='' OR CAST([OpenDate] AS DATE)=CAST(@OpenDate AS DATE)) AND 
        (ISNULL(@CustReqDate,'') ='' OR CAST([CustomerRequestDate] AS DATE)=Cast(@CustReqDate AS DATE)) AND  
        (ISNULL(@PromiseDate,'') ='' OR CAST([PromisedDate] AS DATE)=Cast(@PromiseDate AS DATE)) AND  
        (ISNULL(@EstShipDate,'') ='' OR CAST([EstimatedShipDate] AS DATE)=CAST(@EstShipDate AS DATE)) AND  
        (ISNULL(@ShipDate,'') ='' OR CAST([EstimatedCompletionDate] AS DATE)=CAST(@ShipDate AS DATE)) AND       
        (ISNULL(@CreatedDate,'') ='' OR CAST([CreatedDate] AS DATE)=CAST(@CreatedDate AS DATE)) AND  
        (ISNULL(@UpdatedDate,'') ='' OR CAST([UpdatedDate] AS DATE)=CAST(@UpdatedDate AS DATE)) AND  
        (ISNULL(@SerialNumber,'') ='' OR [SerialNumber] LIKE '%' + @SerialNumber+'%') AND  
		(ISNULL(@RevisedSerialNumber,'') ='' OR [RevisedSerialNumber] LIKE '%' + @RevisedSerialNumber+'%') AND  		
        (ISNULL(@CustRef,'') ='' OR [CustomerReference] LIKE '%' + @CustRef+'%') AND
        (ISNULL(@MPNQuoteStatus,'') ='' OR [MPNQuoteStatus] LIKE '%' + @MPNQuoteStatus+'%') AND
        (ISNULL(@ApprovedAmount,'') ='' OR [ApprovedAmount] LIKE '%' + @ApprovedAmount+'%') AND
		(ISNULL(@IsSubWorkOrder,'') ='' OR [IsSubWorkOrder] LIKE '%' + @IsSubWorkOrder + '%') 

        ))  
  
        SELECT @Count = COUNT(CustomerId) from #TempResult     
  
        SELECT *, @Count AS NumberOfItems FROM #TempResult  
        ORDER BY    
        CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN [CreatedDate] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='PARTNUMBER')  THEN [PartNos] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='partNoType')  THEN [partNoType] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='pnDescriptionType')  THEN [pnDescriptionType] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='workScopeType')  THEN [workScopeType] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='customerRequestDateType')  THEN [customerRequestDateType] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='promisedDateType')  THEN [promisedDateType] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='estimatedShipDateType')  THEN [estimatedShipDateType] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='estimatedCompletionDateType')  THEN [estimatedCompletionDateType] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='stageType')  THEN [stageType] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='workOrderStatusType')  THEN [workOrderStatusType] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='PriorityType')  THEN [PriorityType] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='CustomerType')  THEN [CustomerType] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='WorkOrderType')  THEN [WorkOrderType] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='PARTDESCRIPTION')  THEN [PNDescription] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='ManufacturerName')  THEN [ManufacturerName] END ASC, 
        CASE WHEN (@SortOrder=1 AND @SortColumn='WORKORDERNUM')  THEN [WorkOrderNum] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='WORKSCOPE')  THEN [WorkScope] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='PRIORITY')  THEN [Priority] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERNAME')  THEN [CustomerName] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERAFFILICATION')  THEN [CustomerType] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='STAGE')  THEN [Stage] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='TECHNAME')  THEN [TechName] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='TECHSTATION')  THEN [TechStation] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='WORKORDERSTATUS')  THEN [WorkOrderStatus] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='OPENDATE')  THEN [OpenDate] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTREQDATE')  THEN [CustomerRequestDate] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='PROMISEDATE')  THEN [PromisedDate] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='ESTSHIPDATE')  THEN [EstimatedShipDate] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='SHIPDDATE')  THEN [EstimatedCompletionDate] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN [UpdatedDate] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN [CreatedBy] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN [UpdatedBy] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='SERIALNUMBER') THEN [SerialNumber] END ASC, 
		CASE WHEN (@SortOrder=1 AND @SortColumn='REVISEDSERIALNUMBER') THEN [RevisedSerialNumber] END ASC, 		
        CASE WHEN (@SortOrder=1 AND @SortColumn='MPNQUOTESTATUS') THEN [MPNQuoteStatus] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='APPROVEDAMOUNT') THEN [ApprovedAmount] END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERREFERENCE') THEN [CustomerReference] END ASC,  
  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN [CreatedDate] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTNUMBER')  THEN [PartNos] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='partNoType')  THEN [partNoType] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='pnDescriptionType')  THEN [pnDescriptionType] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='workScopeType')  THEN [workScopeType] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='customerRequestDateType')  THEN [customerRequestDateType] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='promisedDateType')  THEN [promisedDateType] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='estimatedShipDateType')  THEN [estimatedShipDateType] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='estimatedCompletionDateType')  THEN [estimatedCompletionDateType] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='stageType')  THEN [stageType] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='PriorityType')  THEN [PriorityType] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerType')  THEN [CustomerType] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='workOrderStatusType')  THEN [workOrderStatusType] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkOrderType')  THEN [WorkOrderType] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTDESCRIPTION')  THEN [PNDescription] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerName')  THEN [ManufacturerName] END DESC, 
        CASE WHEN (@SortOrder=-1 AND @SortColumn='WORKORDERNUM')  THEN [WorkOrderNum] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='WORKSCOPE')  THEN [WorkScope] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='PRIORITY')  THEN [Priority] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERNAME')  THEN [CustomerName] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERAFFILICATION')  THEN [CustomerType] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='STAGE')  THEN [Stage] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='TECHNAME')  THEN [TechName] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='TECHSTATION')  THEN [TechStation] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='WORKORDERSTATUS')  THEN [WorkOrderStatus] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='OPENDATE')  THEN [OpenDate] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTREQDATE')  THEN [CustomerRequestDate] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='PROMISEDATE')  THEN [PromisedDate] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='ESTSHIPDATE')  THEN [EstimatedShipDate] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='SHIPDDATE')  THEN [EstimatedCompletionDate] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN [UpdatedDate] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN [CreatedBy] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN [UpdatedBy] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='SERIALNUMBER')  THEN [SerialNumber] END DESC, 
		CASE WHEN (@SortOrder=-1 AND @SortColumn='REVISEDSERIALNUMBER') THEN [RevisedSerialNumber] END DESC, 		
        CASE WHEN (@SortOrder=-1 AND @SortColumn='MPNQUOTESTATUS')  THEN [MPNQuoteStatus] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='APPROVEDAMOUNT')  THEN [ApprovedAmount] END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERREFERENCE')  THEN [CustomerReference] END DESC  
  
        OFFSET @RecordFrom ROWS   
        FETCH NEXT @PageSize ROWS ONLY  
       END  
      ELSE  
       BEGIN            
	     ;WITH LatestWorkOrderShipping AS (
				SELECT	[WorkOrderId],
						FORMAT(MAX([ShipDate]), 'yyyy-MM-ddTHH:mm:ss') AS [EstimatedCompletionDate]
				FROM [dbo].[WorkOrderShipping] WITH (NOLOCK)
				GROUP BY [WorkOrderId]
		 ),
		 Main AS(  
         SELECT DISTINCT   
				UPPER(WO.[WorkOrderNum]) AS [WorkOrderNum],
				WO.[WorkOrderId],
				WO.[MasterCompanyId],
				WO.[CustomerId],  
				UPPER(WO.[CustomerName]) AS [CustomerName],
				UPPER(WO.[CustomerType]) AS [CustomerType],
				CASE WHEN CAST(WO.[OpenDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE  CAST(DATEADD(SECOND, @BaseUtcOffsetSec, WO.[OpenDate]) AS DATE) END [OpenDate],
				--CASE WHEN CAST(WO.OpenDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(WO.OpenDate, @CurrntEmpTimeZoneDesc) AS DATE))END OpenDate,

				WO.[CreatedDate],
				CASE WHEN CAST(WO.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE  CAST(DATEADD(SECOND, @BaseUtcOffsetSec, WO.[UpdatedDate]) AS DATE) END [UpdatedDate],
				UPPER(WO.[CreatedBy]) AS [CreatedBy],
				UPPER(WO.[UpdatedBy]) AS [UpdatedBy],
				WO.[IsActive],
				WO.[IsDeleted],
				WO.[WorkOrderType] AS 'WorkOrderType',
				LWS.[EstimatedCompletionDate] AS [EstimatedCompletionDateType],
				LWS.[EstimatedCompletionDate] AS [EstimatedCompletionDate]
				,ISNULL(SWO.[IsSubWorkOrder], 'No') AS [IsSubWorkOrder]
				--(FORMAT((SELECT top 1 ShipDate from dbo.WorkOrderShipping wosp  WITH(NOLOCK) WHERE WorkOrderId = WO.WorkOrderId order by WorkOrderShippingId desc), 'yyyy-MM-ddTHH:mm:ss'))  as 'EstimatedCompletionDateType',
				--(FORMAT((SELECT top 1 ShipDate from dbo.WorkOrderShipping wosp  WITH(NOLOCK) WHERE WorkOrderId = WO.WorkOrderId order by WorkOrderShippingId desc), 'yyyy-MM-ddTHH:mm:ss'))  as 'EstimatedCompletionDate'
			FROM [dbo].[WorkOrder] WO WITH (NOLOCK)   
			--JOIN dbo.WorkOrderType WT WITH (NOLOCK) ON WO.WorkOrderTypeId = WT.Id  
			LEFT JOIN LatestWorkOrderShipping LWS WITH (NOLOCK) ON WO.[WorkOrderId] = LWS.[WorkOrderId]
			--LEFT JOIN #SubWOResult SWO ON WO.WorkOrderId = SWO.WorkOrderId
			OUTER APPLY (
				SELECT TOP 1 'Yes' AS [IsSubWorkOrder]
				FROM [dbo].[SubWorkOrder] SWO WITH(NOLOCK)
				WHERE 
					SWO.[WorkOrderId] = WO.[WorkOrderId]
					--AND SWO.WorkOrderPartNumberId = WPN.ID
					AND ISNULL(SWO.[IsDeleted], 0) = 0
			) AS SWO
			WHERE ((WO.[MasterCompanyId] = @MasterCompanyId) AND (WO.[IsDeleted]=@IsDeleted) AND (@IsActive IS NULL OR WO.[IsActive]=@IsActive)   
			))
			, WorkOrderPartCount AS (
			SELECT [WorkOrderId], COUNT([WorkOrderId]) AS PartCount
			FROM [dbo].[WorkOrderPartNumber] WITH (NOLOCK)
			GROUP BY [WorkOrderId]
			)

			SELECT DISTINCT   
			  [WorkOrderNum], WO.[WorkOrderId], WO.[CustomerId], WO.[CustomerName], [CustomerType], WO.[OpenDate], WO.[CreatedDate], WO.[UpdatedDate], WO.[CreatedBy], WO.[UpdatedBy], WO.[IsActive], WO.[IsDeleted], [WorkOrderType],
			  --(CASE WHEN ((SELECT COUNT(WOPN.WorkOrderId) FROM dbo.WorkOrderPartNumber WOPN WHERE WOPN.WorkOrderId = WO.WorkOrderId) > 1 ) Then 'Multiple' ELse  'Single' End) AS 'RowStatus',
			  CASE WHEN WOPC.[PartCount] > 1 THEN 'Multiple' ELSE 'Single' END AS 'RowStatus',
			  MAX(WPN.[PartNumber])  AS 'PartNumberType',
			  MAX(WPN.[PartNumber])  AS 'PartNumber',
			  MAX(WPN.[PartDescription])  AS 'PartDescriptionType',
			  MAX(WPN.[PartDescription])  AS 'PartDescription',
			  MAX(WPN.[ManufacturerName])  AS 'ManufacturerNameType',
			  MAX(WPN.[ManufacturerName])  AS 'ManufacturerName',
			  MAX(WPN.[WorkScope])  AS 'WorkScopeType',
			  MAX(WPN.[WorkScope])  AS 'WorkScopeDescription',
			  MAX(WPN.[Priority])  AS 'PriorityType',
			  MAX(WPN.[Priority])  AS 'PriorityDescription',
			  MAX(WPN.[WorkOrderStage])  AS 'StageType',
			  MAX(WPN.[WorkOrderStage])  AS 'WOStageDescription',
			  MAX(WPN.[WorkOrderStatus])  AS 'WorkOrderStatusType',
			  MAX(WPN.[WorkOrderStatus])  AS 'WorkOrderStatus',
			  MAX(FORMAT(WPN.[CustomerRequestDate], 'yyyy-MM-ddTHH:mm:ss'))  AS 'CustomerRequestDateType',
			  MAX(FORMAT(WPN.[CustomerRequestDate], 'yyyy-MM-ddTHH:mm:ss') )  AS 'CustomerRequestDate',
			  MAX(FORMAT(WPN.[PromisedDate], 'yyyy-MM-ddTHH:mm:ss'))  AS 'PromisedDateType',
			  MAX(FORMAT(WPN.[PromisedDate], 'yyyy-MM-ddTHH:mm:ss'))  AS 'PromisedDate',
			  MAX(FORMAT(WPN.[EstimatedShipDate], 'yyyy-MM-ddTHH:mm:ss'))  AS 'EstimatedShipDateType',
			  MAX(FORMAT(WPN.[EstimatedShipDate], 'yyyy-MM-ddTHH:mm:ss'))  AS 'EstimatedShipDate',
			  WO.[EstimatedCompletionDateType],
			  WO.[EstimatedCompletionDate],
			  WO.[IsSubWorkOrder],
			  MAX(WPN.[TechName])  AS 'TechNameType',
			  MAX(WPN.[TechName])  AS 'TechName',
			  MAX(WPN.[EmployeeStation])  AS 'TechStationType',
			  MAX(WPN.[EmployeeStation])  AS 'TechStation',
			  MAX(WPN.[CustomerReference])  AS 'CustomerReferenceType',
			  MAX(WPN.[CustomerReference])  AS 'CustomerReference',
			  MAX(UPPER(WPN.[CurrentSerialNumber])) AS [SerialNumber],
			  MAX(CASE WHEN ISNULL(WPN.[RevisedSerialNumber], '') != '' THEN UPPER(WPN.[RevisedSerialNumber]) ELSE UPPER(WPN.[CurrentSerialNumber]) END) AS [RevisedSerialNumber],			  
			  MAX(UPPER(wqs.[Description])) AS [MPNQuoteStatus],
			  MAX(CAST(CASE WHEN ISNULL(WOQD.[QuoteMethod], 0) = 1 THEN ISNULL( WOQD.[CommonFlatRate], 0) ELSE  
					ISNULL(ISNULL(ISNULL(WOQD.[MaterialFlatBillingAmount], 0) + ISNULL(WOQD.[LaborFlatBillingAmount], 0) + ISNULL(WOQD.[ChargesFlatBillingAmount], 0),0) ,0) END AS VARCHAR) ) 'ApprovedAmount'
					--ISNULL(ISNULL(WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount,0) ,0) END AS VARCHAR)) 'ApprovedAmount'
		  INTO #TempWOPartResult
          FROM Main WO WITH (NOLOCK)   
			  JOIN [dbo].[WorkOrderPartNumber] WPN WITH (NOLOCK) ON WO.[WorkOrderId] = WPN.[WorkOrderId]
			  JOIN WorkOrderPartCount WOPC WITH (NOLOCK) ON WO.[WorkOrderId] = WOPC.[WorkOrderId]
			  --LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On WPN.ItemMasterId=I.ItemMasterId  
			  --LEFT JOIN dbo.WorkScope SC WITH(NOLOCK) On WPN.WorkOrderScopeId  = SC.WorkScopeId
			  --LEFT JOIN dbo.Priority P WITH(NOLOCK) On WPN.WorkOrderPriorityId  = P.PriorityId
			  --LEFT JOIN dbo.WorkOrderStage WOS WITH(NOLOCK) On WPN.WorkOrderStageId  = WOS.WorkOrderStageId
			  --LEFT JOIN dbo.WorkOrderStatus WOST WITH(NOLOCK) On WPN.WorkOrderStatusId  = WOST.Id
			  --LEFT JOIN dbo.Employee emp WITH(NOLOCK) On WPN.TechnicianId  = emp.EmployeeId  
			  --LEFT JOIN dbo.EmployeeStation emps WITH(NOLOCK) On WPN.TechStationId  = emps.EmployeeStationId  
				LEFT JOIN [dbo].[WorkOrderQuoteDetails] WOQD WITH (NOLOCK) ON WPN.[ID] = WOQD.[WOPartNoId] AND WOQD.[IsActive] = 1 AND WOQD.[IsVersionIncrease] = 0 
				LEFT JOIN [dbo].[WorkOrderQuote] woq WITH (NOLOCK) ON woq.[workorderquoteid] = WOQD.[workorderquoteid]
				LEFT JOIN [dbo].[WorkOrderQuoteStatus] wqs WITH (NOLOCK) ON woq.[QuoteStatusId] = wqs.[WorkOrderQuoteStatusId] 
          WHERE ((WO.[MasterCompanyId] = @MasterCompanyId) AND (WO.[IsDeleted] = @IsDeleted) AND (@IsActive IS NULL OR WO.[IsActive] = @IsActive)   
				AND (@WorkOrderStatus = 0 OR WPN.[WorkOrderStatusId] = @WorkOrderStatus))
		  GROUP BY	WO.[WorkOrderNum],WO.[WorkOrderId],WO.[CustomerId],WO.[CustomerName],WO.[CustomerType], WO.[OpenDate], WO.[CreatedDate], WO.[UpdatedDate],WO.[CreatedBy], WO.[UpdatedBy],
					WO.[IsActive],WO.[IsDeleted],WO.[WorkOrderType], WO.[EstimatedCompletionDateType],  WO.[EstimatedCompletionDate], WO.[IsSubWorkOrder],WOPC.[PartCount]

         SELECT DISTINCT [WorkOrderNum], [WorkOrderId], [CustomerId], [CustomerName], [CustomerType], [OpenDate], [CreatedDate], [UpdatedDate], [CreatedBy], [UpdatedBy], [IsActive], [IsDeleted], [WorkOrderType],
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([PartNumberType]) END)  AS 'PartNumberType',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([PartNumber]) END)  AS 'PartNumber',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([PartDescriptionType]) END)  AS 'PartDescriptionType',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([PartDescription]) END)  AS 'PartDescription',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([ManufacturerNameType]) END)  AS 'ManufacturerNameType',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([ManufacturerName]) END)  AS 'ManufacturerName',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([WorkScopeType]) END)  AS 'WorkScopeType',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([WorkScopeDescription]) END)  AS 'WorkScopeDescription',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([PriorityType]) END)  AS 'PriorityType',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([PriorityDescription]) END)  AS 'PriorityDescription',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([StageType]) END)  AS 'StageType',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([WOStageDescription]) END)  AS 'WOStageDescription',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([WorkOrderStatusType]) END)  AS 'WorkOrderStatusType',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([WorkOrderStatus]) END)  AS 'WorkOrderStatus',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([CustomerRequestDateType]) END)  AS 'CustomerRequestDateType',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([CustomerRequestDate])  END)  AS 'CustomerRequestDate',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([PromisedDateType]) END)  AS 'PromisedDateType',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([PromisedDate]) END)  AS 'PromisedDate',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([EstimatedShipDateType]) END)  AS 'EstimatedShipDateType',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([EstimatedShipDate]) END)  AS 'EstimatedShipDate',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([EstimatedCompletionDateType]) END)  AS 'EstimatedCompletionDateType',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([EstimatedCompletionDate]) END)  AS 'EstimatedCompletionDate',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([IsSubWorkOrder]) END)  AS 'IsSubWorkOrder',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([TechNameType]) END)  AS 'TechNameType',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([TechName]) END)  AS 'TechName',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([TechStationType]) END)  AS 'TechStationType',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([TechStation]) END)  AS 'TechStation',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([CustomerReferenceType]) END)  AS 'CustomerReferenceType',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([CustomerReference]) END)  AS 'CustomerReference',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([SerialNumber]) END)  AS 'SerialNumber',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([RevisedSerialNumber]) END)  AS 'RevisedSerialNumber',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([MPNQuoteStatus]) END)  AS 'MPNQuoteStatus',
			  (CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX([ApprovedAmount]) END)  AS 'ApprovedAmount'
		  INTO #finalTemp FROM #TempWOPartResult 
		  GROUP BY	 [WorkOrderNum], [WorkOrderId], [CustomerId], [CustomerName], [CustomerType], [OpenDate], [CreatedDate], [UpdatedDate], [CreatedBy], [UpdatedBy],[IsActive], [IsDeleted]
					,[WorkOrderType], [WorkOrderType], [EstimatedCompletionDateType],  [EstimatedCompletionDate], [IsSubWorkOrder], [RowStatus]
  																																			  
          ;WITH Result AS( SELECT DISTINCT M.[WorkOrderId], UPPER([WorkOrderNum]) AS [WorkOrderNum], UPPER([WorkOrderType]) AS [WorkOrderType], UPPER([PartNumber]) AS [PartNos], UPPER([PartNumberType]) AS [PartNoType], UPPER([PartNumberType]) AS [PartNumberType], UPPER([PartDescription]) AS [PNDescription], UPPER([PartDescriptionType]) AS [PNDescriptionType], UPPER([ManufacturerName]) AS [ManufacturerName], UPPER([ManufacturerNameType]) AS [ManufacturerNameType],
              [CustomerId], UPPER([CustomerName]) AS [CustomerName], UPPER([CustomerType]) AS [CustomerType], UPPER([WorkScopeDescription]) AS [WorkScope], UPPER([WorkScopeType]) AS [WorkScopeType],
              UPPER([PriorityDescription]) AS [Priority], UPPER([PriorityType]) [PriorityType], UPPER([WOStageDescription]) AS [Stage], UPPER([StageType]) [StageType], UPPER([WorkOrderStatus]) [WorkOrderStatus],
              UPPER([WorkOrderStatusType]) [WorkOrderStatusType], [OpenDate], UPPER([CreatedBy]) [CreatedBy], UPPER([UpdatedBy]) [UpdatedBy], [CreatedDate], [UpdatedDate], [CustomerRequestDate],   
              CustomerRequestDateType, PromisedDate, PromisedDateType, EstimatedShipDate, EstimatedShipDateType,   
              [EstimatedCompletionDate], [EstimatedCompletionDateType], [IsSubWorkOrder], UPPER([TechName]) [TechName], UPPER([TechNameType]) [TechNameType], UPPER([TechStation]) [TechStation], UPPER([TechStationType]) [TechStationType], 
			  UPPER([CustomerReference]) [CustomerReference], UPPER([CustomerReferenceType]) [CustomerReferenceType], [SerialNumber],[RevisedSerialNumber], [MPNQuoteStatus], 
			  CASE WHEN [MPNQuoteStatus] = 'Multiple' THEN [ApprovedAmount] WHEN [MPNQuoteStatus] = @WOApprovalDesc THEN [ApprovedAmount] ELSE '' END AS [ApprovedAmount]
          FROM #finalTemp M   
          ),  
         ResultCount AS(SELECT COUNT([WorkOrderId]) AS totalItems FROM Result)  
          SELECT * INTO #TempResult1 FROM  Result  
          WHERE (  
           (@GlobalFilter <>'' AND (  
           ([WorkOrderNum] LIKE '%' +@GlobalFilter+'%') OR  
           ([WorkOrderType] LIKE '%' +@GlobalFilter+'%') OR  
           ([PartNos] LIKE '%' +@GlobalFilter+'%') OR  
           ([PNDescription] LIKE '%' +@GlobalFilter+'%') OR
		   ([ManufacturerName] LIKE '%' +@GlobalFilter+'%') OR 
           ([WorkScope] LIKE '%' +@GlobalFilter+'%') OR  
           ([Priority] LIKE '%' +@GlobalFilter+'%') OR    
           ([CustomerName] LIKE '%' +@GlobalFilter+'%' ) OR   
           ([CustomerType] LIKE '%' +@GlobalFilter+'%') OR  
           ([Stage] LIKE '%' +@GlobalFilter+'%') OR  
           ([TechName] LIKE '%' +@GlobalFilter+'%') OR  
           ([WorkOrderStatus] LIKE '%'+@GlobalFilter+'%') OR  
           ([CreatedBy] LIKE '%' +@GlobalFilter+'%') OR  
           ([WorkOrderStatusType] LIKE '%'+@GlobalFilter+'%') OR  
           ([UpdatedBy] LIKE '%' +@GlobalFilter+'%') OR  
           ([SerialNumber] LIKE '%' +@GlobalFilter+'%') OR  
		   ([RevisedSerialNumber] LIKE '%' +@GlobalFilter+'%') OR  		   
           ([CustomerReference] LIKE '%' + @GlobalFilter +'%') OR
		   ([MPNQuoteStatus] LIKE '%' +@GlobalFilter+'%') OR
		   ([ApprovedAmount] LIKE '%' +@GlobalFilter+'%') OR
		   ([IsSubWorkOrder] LIKE '%' + @GlobalFilter +'%')
           ))  
           OR     
           (@GlobalFilter='' AND (ISNULL(@WorkOrderNum,'') ='' OR [WorkOrderNum] LIKE '%' + @WorkOrderNum+'%') AND  
           (ISNULL(@PartNumber,'') ='' OR [PartNos] LIKE '%' + @PartNumber+'%') AND  
           (ISNULL(@WorkOrderType,'') ='' OR [WorkOrderType] LIKE '%' + @WorkOrderType+'%') AND  
           (ISNULL(@PartDescription,'') ='' OR [PNDescription] LIKE '%' + @PartDescription+'%') AND
		   (ISNULL(@ManufacturerName,'') ='' OR [ManufacturerName] LIKE '%' + @ManufacturerName+'%') AND  
           (ISNULL(@WorkScope,'') ='' OR [WorkScope] LIKE '%' + @WorkScope+'%') AND  
           (ISNULL(@Priority,'') ='' OR [Priority] LIKE '%' + @Priority+'%') AND  
           (ISNULL(@CustomerName,'') ='' OR [CustomerName] LIKE '%' + @CustomerName+'%') AND  
           (ISNULL(@CustomerAffiliation,'') ='' OR [CustomerType] LIKE '%' + @CustomerAffiliation+'%') AND  
           (ISNULL(@Stage,'') ='' OR [Stage] LIKE '%' + @Stage+'%') AND  
           (ISNULL(@TechName,'') ='' OR [TechName] LIKE '%' + @TechName+'%') AND  
           (ISNULL(@TechStation,'') ='' OR [TechStation] LIKE '%' + @TechStation+'%') AND  
           (ISNULL(@CreatedBy,'') ='' OR [CreatedBy] LIKE '%' + @CreatedBy+'%') AND  
           (ISNULL(@UpdatedBy,'') ='' OR [UpdatedBy] LIKE '%' + @UpdatedBy+'%') AND  
           --(ISNULL(@OpenDate,'') ='' OR Cast(DBO.ConvertUTCtoLocal(OpenDate, @CurrntEmpTimeZoneDesc) as Date)=Cast(@OpenDate as date)) AND 
		   (ISNULL(@OpenDate,'') ='' OR CAST([OpenDate] AS DATE)=CAST(@OpenDate AS DATE)) AND
           (ISNULL(@CustReqDate,'') ='' OR CAST([CustomerRequestDate] AS DATE)=CAST(@CustReqDate AS DATE)) AND  
           (ISNULL(@PromiseDate,'') ='' OR CAST([PromisedDate] AS DATE)=CAST(@PromiseDate AS DATE)) AND  
           (ISNULL(@EstShipDate,'') ='' OR CAST([EstimatedShipDate] AS DATE)=CAST(@EstShipDate AS DATE)) AND  
           (ISNULL(@ShipDate,'') ='' OR CAST([EstimatedCompletionDate] AS DATE)=CAST(@ShipDate AS DATE)) AND       
           (ISNULL(@CreatedDate,'') ='' OR CAST([CreatedDate] AS DATE)=CAST(@CreatedDate AS DATE)) AND  
           (ISNULL(@WorkOrderStatusType,'') ='' OR [WorkOrderStatusType] LIKE '%' + @WorkOrderStatusType+'%') AND  
           (ISNULL(@UpdatedDate,'') ='' OR CAST([UpdatedDate] AS DATE)=CAST(@UpdatedDate AS DATE)) AND  
		   (ISNULL(@SerialNumber,'') ='' OR [SerialNumber] LIKE '%' + @SerialNumber+'%') AND
		   (ISNULL(@RevisedSerialNumber,'') ='' OR [RevisedSerialNumber] LIKE '%' + @RevisedSerialNumber+'%') AND
           (ISNULL(@CustRef,'') ='' OR [CustomerReference] LIKE '%' + @CustRef+'%') AND  
           (ISNULL(@MPNQuoteStatus,'') ='' OR [MPNQuoteStatus] LIKE '%' + @MPNQuoteStatus+'%') AND  
           (ISNULL(@ApprovedAmount,'') ='' OR [ApprovedAmount] LIKE '%' + @ApprovedAmount+'%') AND  
		   (ISNULL(@IsSubWorkOrder,'') ='' OR [IsSubWorkOrder] LIKE '%' + @IsSubWorkOrder + '%') 

           ))  
  
         SELECT @Count = COUNT(CustomerId) from #TempResult1     
  
         SELECT *, @Count As NumberOfItems FROM #TempResult1  
         ORDER BY    
         CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN [CreatedDate] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='PARTNUMBER')  THEN [PartNos] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='partNoType')  THEN [partNoType] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='pnDescriptionType')  THEN [pnDescriptionType] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='workScopeType')  THEN [workScopeType] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='customerRequestDateType')  THEN [customerRequestDateType] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='promisedDateType')  THEN [promisedDateType] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='estimatedShipDateType')  THEN [estimatedShipDateType] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='estimatedCompletionDateType')  THEN [estimatedCompletionDateType] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='stageType')  THEN [stageType] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='workOrderStatusType')  THEN [workOrderStatusType] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='PriorityType')  THEN [PriorityType] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='CustomerType')  THEN [CustomerType] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='WorkOrderType')  THEN [WorkOrderType] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='PARTDESCRIPTION')  THEN [PNDescription] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='WORKORDERNUM')  THEN [WorkOrderNum] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='WORKSCOPE')  THEN [WorkScope] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='PRIORITY')  THEN [Priority] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERNAME')  THEN [CustomerName] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERAFFILICATION')  THEN [CustomerType] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='STAGE')  THEN [Stage] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='TECHNAME')  THEN [TechName] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='TECHSTATION')  THEN [TechStation] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='WORKORDERSTATUS')  THEN [WorkOrderStatus] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='OPENDATE')  THEN [OpenDate] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTREQDATE')  THEN [CustomerRequestDate] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='PROMISEDATE')  THEN [PromisedDate] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='ESTSHIPDATE')  THEN [EstimatedShipDate] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='SHIPDDATE')  THEN [EstimatedCompletionDate] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN [UpdatedDate] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN [CreatedBy] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN [UpdatedBy] END ASC,  
         CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERREFERENCE')  THEN [CustomerReference] END ASC,  
		 CASE WHEN (@SortOrder=1 AND @SortColumn='SERIALNUMBER')  THEN [SerialNumber] END ASC, 
		 CASE WHEN (@SortOrder=1 AND @SortColumn='REVISEDSERIALNUMBER')  THEN [RevisedSerialNumber] END ASC, 
		 CASE WHEN (@SortOrder=1 AND @SortColumn='MPNQUOTESTATUS')  THEN [MPNQuoteStatus] END ASC, 
		 CASE WHEN (@SortOrder=1 AND @SortColumn='APPROVEDAMOUNT')  THEN [ApprovedAmount] END ASC, 
         CASE WHEN (@SortOrder=1 AND @SortColumn='ManufacturerName')  THEN [ManufacturerName] END ASC, 

         CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN [CreatedDate] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTNUMBER')  THEN [PartNos] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='partNoType')  THEN [partNoType] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='pnDescriptionType')  THEN [pnDescriptionType] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='workScopeType')  THEN [workScopeType] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='customerRequestDateType')  THEN [customerRequestDateType] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='promisedDateType')  THEN [promisedDateType] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='estimatedShipDateType')  THEN [estimatedShipDateType] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='estimatedCompletionDateType')  THEN [estimatedCompletionDateType] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='stageType')  THEN [stageType] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='PriorityType')  THEN [PriorityType] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerType')  THEN [CustomerType] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='workOrderStatusType')  THEN [workOrderStatusType] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkOrderType')  THEN [WorkOrderType] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTDESCRIPTION')  THEN [PNDescription] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerName')  THEN [ManufacturerName] END DESC, 
		 CASE WHEN (@SortOrder=-1 AND @SortColumn='WORKORDERNUM')  THEN [WorkOrderNum] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='WORKSCOPE')  THEN [WorkScope] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='PRIORITY')  THEN [Priority] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERNAME')  THEN [CustomerName] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERAFFILICATION')  THEN [CustomerType] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='STAGE')  THEN [Stage] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='TECHNAME')  THEN [TechName] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='TECHSTATION')  THEN [TechStation] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='WORKORDERSTATUS')  THEN [WorkOrderStatus] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='OPENDATE')  THEN [OpenDate] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTREQDATE')  THEN [CustomerRequestDate] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='PROMISEDATE')  THEN [PromisedDate] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='ESTSHIPDATE')  THEN [EstimatedShipDate] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='SHIPDDATE')  THEN [EstimatedCompletionDate] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN [UpdatedDate] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN [CreatedBy] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN [UpdatedBy] END DESC,  
         CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerReference')  THEN [CustomerReference] END DESC,
		 CASE WHEN (@SortOrder=-1 AND @SortColumn='SERIALNUMBER')  THEN [SerialNumber] END DESC,
		 CASE WHEN (@SortOrder=-1 AND @SortColumn='REVISEDSERIALNUMBER')  THEN [RevisedSerialNumber] END DESC, 
		 CASE WHEN (@SortOrder=-1 AND @SortColumn='MPNQUOTESTATUS')  THEN [MPNQuoteStatus] END DESC,
		 CASE WHEN (@SortOrder=-1 AND @SortColumn='APPROVEDAMOUNT')  THEN [ApprovedAmount] END DESC,
		 CASE WHEN (@SortOrder=-1 AND @SortColumn='ISSUBWORKORDER')  THEN [IsSubWorkOrder] END DESC
  
         OFFSET @RecordFrom ROWS   
         FETCH NEXT @PageSize ROWS ONLY  
       END  
  
    IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL  
    BEGIN  
		DROP TABLE #TempResult   
    END  
  
    IF OBJECT_ID(N'tempdb..#TempResult1') IS NOT NULL  
    BEGIN  
		DROP TABLE #TempResult1  
    END  
  
  -- END  
  --COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    --ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''',  
                @Parameter2 = ' + ISNULL(@PageSize,'') + ',   
                @Parameter3 = ' + ISNULL(@SortColumn,'') + ',   
                @Parameter4 = ' + ISNULL(@SortOrder,'') + ',   
                @Parameter5 = ' + ISNULL(@GlobalFilter,'') + ',   
                @Parameter6 = ' + ISNULL(@ViewType,'') + ',    
                @Parameter7 = ' + ISNULL(@WorkOrderNum,'') + ',   
                @Parameter8 = ' + ISNULL(@PartNumber,'') + ',   
                @Parameter9 = ' + ISNULL(@PartDescription,'') + ',   
                @Parameter10 = ' + ISNULL(@WorkScope,'') + ',   
                @Parameter11 = ' + ISNULL(@Priority,'') + ',   
                @Parameter12 = ' + ISNULL(@CustomerName,'') + ',   
                @Parameter13 = ' + ISNULL(@CustomerAffiliation,'') + ',   
                @Parameter14 = ' + ISNULL(@Stage,'') + ',   
                @Parameter15 = ' + ISNULL(@WorkOrderStatus,'') + ',   
                @Parameter16 = ' + ISNULL(CAST(@OpenDate AS VARCHAR(50)) ,'') + ',   
                @Parameter17 = ' + ISNULL(CAST(@CustReqDate AS VARCHAR(50)) ,'') + ',   
                @Parameter18 = ' + ISNULL(CAST(@PromiseDate AS VARCHAR(50)) ,'') + ',   
                @Parameter19 = ' + ISNULL(CAST(@EstShipDate AS VARCHAR(50)) ,'') + ',   
                @Parameter20 = ' + ISNULL(CAST(@ShipDate AS VARCHAR(50)) ,'') + ',   
                @Parameter21 = ' + ISNULL(CAST(@CreatedDate AS VARCHAR(50)) ,'') + ',   
                @Parameter22 = ' + ISNULL(CAST(@UpdatedDate AS VARCHAR(50)) ,'') + ',   
                @Parameter23 = ' + ISNULL(@CreatedBy,'') + ',   
                @Parameter24 = ' + ISNULL(@UpdatedBy,'') + ',   
                @Parameter25 = ' + ISNULL(CAST(@IsDeleted AS VARCHAR(50)) ,'') + ',   
                @Parameter26 = ' + ISNULL(@masterCompanyId,'') + ',   
                @Parameter27 = ' + ISNULL(@EmployeeId,'') + ',   
                @Parameter28 = ' + ISNULL(@WorkOrderStatusType,'') + ',   
                @Parameter29 = ' + ISNULL(@WorkOrderType,'') + ',   
                @Parameter30 = ' + ISNULL(@TechName,'') + ',   
                @Parameter31 = ' + ISNULL(CAST(@TechStation AS VARCHAR(10)) ,'') + ',
				@Parameter32 = ' + ISNULL(CAST(@IsSubWorkOrder AS VARCHAR(50)) ,'') + ''   

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
  END CATCH  
END