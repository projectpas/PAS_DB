
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
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/28/2023   Vishal Suthar Added history
    2    08/01/2023   Vishal Suthar Converting all the data in Upper case which was creating an issue in download
	3    23 Jul2023   Rajesh Gami   Improve Performance
	4    30/07/2024   HEMANT SALIYA Serial Number Changes
     
**************************************************************/
CREATE   PROCEDURE [dbo].[GetWorkOrderList]
 -- Add the parameters for the stored procedure here  
	 @PageNumber int,  
	 @PageSize int,  
	 @SortColumn varchar(50)=null,  
	 @SortOrder int,  
	 @StatusID int,  
	 @GlobalFilter varchar(50) = '',  
	 @ViewType varchar(50) = null,  
	 @WorkOrderNum varchar(50)=null,  
	 @PartNumber varchar(50)=null,  
	 @PartDescription varchar(50)=null,  
	 @WorkScope varchar(50)=null,  
	 @Priority varchar(50)=null,  
	 @CustomerName varchar(50)=null,  
	 @CustomerAffiliation varchar(50)=null,  
	 @Stage varchar(200)=null,  
	 @WorkOrderStatus varchar(50)=null,      
	 @OpenDate datetime=null,  
	 @CustReqDate datetime=null,  
	 @PromiseDate datetime=null,  
	 @EstShipDate datetime=null,  
	 @ShipDate datetime=null,  
	 @CreatedDate datetime=null,  
	 @UpdatedDate  datetime=null,  
	 @CreatedBy  varchar(50)=null,  
	 @UpdatedBy  varchar(50)=null,  
	 @IsDeleted bit= null,  
	 @MasterCompanyId varchar(200)=null,  
	 @EmployeeId varchar(200)=null,   
	 @WorkOrderStatusType varchar(200)=null,  
	 @WorkOrderType varchar(50)=null,  
	 @TechName  varchar(50)=null,  
	 @TechStation  varchar(50)=null,  
	 @SerialNumber  varchar(50)=null,  
	 @CustRef varchar(50)=null,
	 @MSModuleID INT=12,
	 @ManufacturerName varchar(50)=null
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  --BEGIN TRANSACTION  
  -- BEGIN   
    DECLARE @RecordFrom int;  
    DECLARE @IsActive bit=1  
    DECLARE @Count Int;  
    DECLARE @WorkOrderStatusId int;    
  
    IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL  
    BEGIN  
		DROP TABLE #TempResult   
    END  
  
    IF OBJECT_ID(N'tempdb..#TempResult1') IS NOT NULL  
    BEGIN  
		DROP TABLE #TempResult1  
    END  
  
    SET @RecordFrom = (@PageNumber-1)*@PageSize;  
    IF @IsDeleted is null  
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
		SET @SortColumn = Upper('CreatedDate')
    END
    ELSE
    BEGIN   
		SET @SortColumn=Upper(@SortColumn)  
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
		SET @IsActive = null  
    END   
  
    IF COALESCE(@WorkOrderStatus, '') <> ''    
    BEGIN   
     IF Upper(@WorkOrderStatus) = 'OPEN'   
      BEGIN  
       SET @WorkOrderStatusId = 1  
      END  
     ELSE IF Upper(@WorkOrderStatus) = 'CLOSED'   
      BEGIN  
       SET @WorkOrderStatusId = 2  
      END  
     ELSE IF Upper(@WorkOrderStatus) = 'CANCELED'   
      BEGIN  
       SET @WorkOrderStatusId = 3  
      END  
     ELSE IF Upper(@WorkOrderStatus) = 'ALL'   
      BEGIN  
       SET @WorkOrderStatusId = 0  
       print @WorkOrderStatus  
      END  
    END  
  
	DECLARE @EmpLegalEntiyId BIGINT = 0;
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

	SELECT @EmpLegalEntiyId = LegalEntityId FROM DBO.Employee WHERE EmployeeId = @EmployeeId;
	SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId 
	WHERE LE.LegalEntityId = @EmpLegalEntiyId;

    IF LOWER(@ViewType) = 'mpn'  
     BEGIN  
      ;WITH Result AS(  
       SELECT   
			UPPER(WO.WorkOrderNum) AS WorkOrderNum,
			UPPER(WO.WorkOrderId) AS WorkOrderId,
			UPPER(WO.CustomerId) AS CustomerId,
			CASE WHEN ISNULL(WPN.RevisedPartNumber, '') != '' THEN UPPER(WPN.RevisedPartNumber) ELSE UPPER(IM.partnumber) END AS PartNos,
			CASE WHEN ISNULL(WPN.RevisedPartNumber, '') != '' THEN UPPER(WPN.RevisedPartNumber) ELSE UPPER(IM.partnumber) END AS PartNoType,
			CASE WHEN ISNULL(WPN.RevisedPartDescription, '') != '' THEN UPPER(WPN.RevisedPartDescription) ELSE UPPER(IM.PartDescription) END AS PNDescription,
			CASE WHEN ISNULL(WPN.RevisedPartDescription, '') != '' THEN UPPER(WPN.RevisedPartDescription) ELSE UPPER(IM.PartDescription) END AS PNDescriptionType,
			UPPER(IM.ManufacturerName) AS ManufacturerName,  
			UPPER(IM.ManufacturerName) AS ManufacturerNameType,  
			UPPER(WPN.WorkScope) AS WorkScope,
			UPPER(WPN.WorkScope) AS WorkScopeType,
			UPPER(PR.Description) AS Priority,
			UPPER(PR.Description) As PriorityType,
			UPPER(WO.CustomerName) AS CustomerName,
			UPPER(WO.CustomerType) AS CustomerType,
			UPPER(WOSG.Code + '-' + WOSG.Stage) AS Stage,  
			UPPER(WOSG.Code + '-' + WOSG.Stage) AS StageType,  
			UPPER(WOS.Description) AS WorkOrderStatus,  
			UPPER(WOS.Description) AS WorkOrderStatusType,  
			WO.OpenDate,  
			WPN.CustomerRequestDate,  
			WPN.CustomerRequestDate AS CustomerRequestDateType,  
			WPN.PromisedDate,  
			WPN.PromisedDate AS PromisedDateType,  
			WPN.EstimatedShipDate,  
			WPN.EstimatedShipDate AS EstimatedShipDateType,  
			((SELECT top 1 ShipDate FROM dbo.WorkOrderShipping wosp WITH(NOLOCK) WHERE WorkOrderId = WO.WorkOrderId ORDER BY WorkOrderShippingId desc))as EstimatedCompletionDate,  
			((SELECT top 1 ShipDate FROM dbo.WorkOrderShipping wosp WITH(NOLOCK) WHERE WorkOrderId = WO.WorkOrderId ORDER BY WorkOrderShippingId desc))as EstimatedCompletionDateType,  
			WO.CreatedDate,  
			WO.UpdatedDate,  
			UPPER(WO.CreatedBy) AS CreatedBy,
			UPPER(WO.UpdatedBy) AS UpdatedBy,
			WO.IsActive,  
			WO.IsDeleted,  
			WPN.WorkOrderStatusId,  
			UPPER(WT.Description) AS WorkOrderType,
			UPPER(EMP.FirstName + ' ' + EMP.LastName) AS TechName,
			UPPER(EMPS.StationName) AS TechStation,
			--UPPER(STL.SerialNumber) AS SerialNumber,
			CASE WHEN ISNULL(WPN.RevisedSerialNumber, '') != '' THEN UPPER(WPN.RevisedSerialNumber) ELSE UPPER(STL.SerialNumber) END AS SerialNumber,
			UPPER(WPN.CustomerReference) AS CustomerReference,
			UPPER(WPN.CustomerReference) AS CustomerReferenceType
       FROM WorkOrder WO WITH(NOLOCK)  
			JOIN dbo.WorkOrderPartNumber WPN WITH(NOLOCK) ON WO.WorkOrderId = WPN.WorkOrderId  
			JOIN dbo.WorkOrderType WT WITH(NOLOCK) ON WO.WorkOrderTypeId = WT.Id  
			JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WPN.ID = WOWF.WorkOrderPartNoId  
			JOIN dbo.WorkOrderStatus WOS WITH(NOLOCK) ON WOS.Id = WPN.WorkOrderStatusId  
			JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId         
			JOIN dbo.Priority PR WITH(NOLOCK) ON WPN.WorkOrderPriorityId = PR.PriorityId  
			JOIN dbo.WorkOrderStage WOSG WITH(NOLOCK) ON WPN.WorkOrderStageId = WOSG.WorkOrderStageId  
			LEFT JOIN dbo.Stockline STL WITH(NOLOCK) ON WPN.StockLineId = STL.StockLineId  
			LEFT JOIN dbo.Employee EMP WITH(NOLOCK) ON EMP.EmployeeId = WPN.TechnicianId  
			LEFT JOIN dbo.EmployeeStation EMPS WITH(NOLOCK) ON WPN.TechStationId = EMPS.EmployeeStationId
        --LEFT JOIN dbo.WorkOrderShipping wosp  WITH(NOLOCK) on WO.WorkOrderId = wosp.WorkOrderId  
       WHERE ((WO.MasterCompanyId = @MasterCompanyId) AND (WO.IsDeleted = @IsDeleted) AND (@IsActive is null or WO.IsActive = @IsActive) AND (@WorkOrderStatusId = 0 OR WPN.WorkOrderStatusId = @WorkOrderStatusId))  
        ), ResultCount AS(SELECT COUNT(WorkOrderId) AS totalItems FROM Result)  
        SELECT * INTO #TempResult from  Result  
        WHERE (  
        (@GlobalFilter <>'' AND (  
        (WorkOrderNum like '%' +@GlobalFilter+'%') OR  
        (WorkOrderType like '%' +@GlobalFilter+'%') OR  
        (PartNos like '%' +@GlobalFilter+'%') OR  
        (PNDescription like '%' +@GlobalFilter+'%') OR
		(ManufacturerName like '%' +@GlobalFilter+'%') OR  
        (WorkScope like '%' +@GlobalFilter+'%') OR  
        (Priority like '%' +@GlobalFilter+'%') OR    
        (CustomerName like '%' +@GlobalFilter+'%' ) OR   
        (CustomerType like '%' +@GlobalFilter+'%') OR  
        (Stage like '%' +@GlobalFilter+'%') OR  
        (TechName like '%' +@GlobalFilter+'%') OR  
        (TechStation like '%' +@GlobalFilter+'%') OR  
        (WorkOrderStatus like '%'+@GlobalFilter+'%') OR  
        (WorkOrderStatusType like '%'+@GlobalFilter+'%') OR  
        (CreatedBy like '%' +@GlobalFilter+'%') OR  
        (UpdatedBy like '%' +@GlobalFilter+'%') OR  
        (SerialNumber like '%' +@GlobalFilter+'%') OR  
        (CustomerReference like '%' +@GlobalFilter+'%')  
        ))  
        OR     
        (@GlobalFilter='' AND (IsNull(@WorkOrderNum,'') ='' OR WorkOrderNum like '%' + @WorkOrderNum+'%') AND  
        (IsNull(@PartNumber,'') ='' OR PartNos like '%' + @PartNumber+'%') AND  
        (IsNull(@PartDescription,'') ='' OR PNDescription like '%' + @PartDescription+'%') AND 
		(IsNull(@ManufacturerName,'') ='' OR ManufacturerName like '%' + @ManufacturerName+'%') AND  
        (IsNull(@WorkScope,'') ='' OR WorkScope like '%' + @WorkScope+'%') AND  
        (IsNull(@WorkOrderType,'') ='' OR WorkOrderType like '%' + @WorkOrderType+'%') AND  
        (IsNull(@Priority,'') ='' OR Priority like '%' + @Priority+'%') AND  
        (IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') AND  
        (IsNull(@CustomerAffiliation,'') ='' OR CustomerType like '%' + @CustomerAffiliation+'%') AND  
        (IsNull(@Stage,'') ='' OR Stage like '%' + @Stage+'%') AND  
        (IsNull(@TechName,'') ='' OR TechName like '%' + @TechName+'%') AND  
        (IsNull(@TechStation,'') ='' OR TechStation like '%' + @TechStation+'%') AND  
        (IsNull(@WorkOrderStatusType,'') ='' OR WorkOrderStatusType like '%' + @WorkOrderStatusType+'%') AND  
        (IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND  
        (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND  
        --(IsNull(@OpenDate,'') ='' OR Cast(DBO.ConvertUTCtoLocal(OpenDate, @CurrntEmpTimeZoneDesc) as Date)=Cast(@OpenDate as date)) AND  
		(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS date)=CAST(@OpenDate AS date)) AND 
        (IsNull(@CustReqDate,'') ='' OR Cast(CustomerRequestDate as Date)=Cast(@CustReqDate as date)) AND  
        (IsNull(@PromiseDate,'') ='' OR Cast(PromisedDate as Date)=Cast(@PromiseDate as date)) AND  
        (IsNull(@EstShipDate,'') ='' OR Cast(EstimatedShipDate as Date)=Cast(@EstShipDate as date)) AND  
        (IsNull(@ShipDate,'') ='' OR Cast(EstimatedCompletionDate as Date)=Cast(@ShipDate as date)) AND       
        (IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) AND  
        (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) AND  
        (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND  
        (IsNull(@CustRef,'') ='' OR CustomerReference like '%' + @CustRef+'%')  
        ))  
  
        SELECT @Count = COUNT(CustomerId) from #TempResult     
  
        SELECT *, @Count As NumberOfItems FROM #TempResult  
        ORDER BY    
        CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNos END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='partNoType')  THEN partNoType END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='pnDescriptionType')  THEN pnDescriptionType END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='workScopeType')  THEN workScopeType END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='customerRequestDateType')  THEN customerRequestDateType END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='promisedDateType')  THEN promisedDateType END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='estimatedShipDateType')  THEN estimatedShipDateType END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='estimatedCompletionDateType')  THEN estimatedCompletionDateType END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='stageType')  THEN stageType END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='workOrderStatusType')  THEN workOrderStatusType END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='PriorityType')  THEN PriorityType END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='CustomerType')  THEN CustomerType END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderType')  THEN WorkOrderType END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PNDescription END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC, 
        CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='WORKSCOPE')  THEN WorkScope END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN Priority END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERAFFILICATION')  THEN CustomerType END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='STAGE')  THEN Stage END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='TECHNAME')  THEN TechName END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='TECHSTATION')  THEN TechStation END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERSTATUS')  THEN WorkOrderStatus END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='CUSTREQDATE')  THEN CustomerRequestDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='PROMISEDATE')  THEN PromisedDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='ESTSHIPDATE')  THEN EstimatedShipDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='SHIPDDATE')  THEN EstimatedCompletionDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='SERIALNUMBER') THEN SerialNumber END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERREFERENCE') THEN CustomerReference END ASC,  
  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNos END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='partNoType')  THEN partNoType END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='pnDescriptionType')  THEN pnDescriptionType END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='workScopeType')  THEN workScopeType END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='customerRequestDateType')  THEN customerRequestDateType END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='promisedDateType')  THEN promisedDateType END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='estimatedShipDateType')  THEN estimatedShipDateType END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='estimatedCompletionDateType')  THEN estimatedCompletionDateType END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='stageType')  THEN stageType END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='PriorityType')  THEN PriorityType END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerType')  THEN CustomerType END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='workOrderStatusType')  THEN workOrderStatusType END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderType')  THEN WorkOrderType END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PNDescription END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC, 
        CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='WORKSCOPE')  THEN WorkScope END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITY')  THEN Priority END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERAFFILICATION')  THEN CustomerType END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='STAGE')  THEN Stage END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='TECHNAME')  THEN TechName END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='TECHSTATION')  THEN TechStation END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERSTATUS')  THEN WorkOrderStatus END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTREQDATE')  THEN CustomerRequestDate END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='PROMISEDATE')  THEN PromisedDate END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='ESTSHIPDATE')  THEN EstimatedShipDate END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='SHIPDDATE')  THEN EstimatedCompletionDate END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='SERIALNUMBER')  THEN SerialNumber END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END DESC  
  
        OFFSET @RecordFrom ROWS   
        FETCH NEXT @PageSize ROWS ONLY  
       END  
      ELSE  
       BEGIN     
       print  'Step 2';  
        ;WITH Main AS(  
         SELECT DISTINCT   
			  UPPER(WO.WorkOrderNum) AS WorkOrderNum,
			  WO.WorkOrderId,
			  WO.CustomerId,  
			  UPPER(WO.CustomerName) AS CustomerName,
			  UPPER(WO.CustomerType) AS CustomerType,
			  WO.OpenDate,
			  WO.CreatedDate,
			  WO.UpdatedDate,
			  UPPER(WO.CreatedBy) AS CreatedBy,
			  UPPER(WO.UpdatedBy) AS UpdatedBy,
			  WO.IsActive,
			  WO.IsDeleted,
			  UPPER(WT.Description) AS WorkOrderType,
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse I.PartNumber End)  as 'PartNumberType',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse I.PartNumber End)  as 'PartNumber',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse I.PartDescription End)  as 'PartDescriptionType',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse I.PartDescription End)  as 'PartDescription',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse I.ManufacturerName End)  as 'ManufacturerNameType',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse I.ManufacturerName End)  as 'ManufacturerName',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse SC.WorkScopeCode End)  as 'WorkScopeType',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse SC.WorkScopeCode End)  as 'WorkScopeDescription',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse P.Description End)  as 'PriorityType',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse P.Description End)  as 'PriorityDescription',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse WOS.Code + '-' + WOS.Stage End)  as 'StageType',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse WOS.Code + '-' + WOS.Stage End)  as 'WOStageDescription',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse WOST.Description End)  as 'WorkOrderStatusType',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse WOST.Description End)  as 'WorkOrderStatus',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELSE WPN.CustomerRequestDate End)  as 'CustomerRequestDateType',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELSE WPN.CustomerRequestDate End)  as 'CustomerRequestDate',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse WPN.PromisedDate End)  as 'PromisedDateType',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse WPN.PromisedDate End)  as 'PromisedDate',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse WPN.EstimatedShipDate End)  as 'EstimatedShipDateType',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse WPN.EstimatedShipDate End)  as 'EstimatedShipDate',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse (CONVERT(VARCHAR, (SELECT top 1 ShipDate from dbo.WorkOrderShipping wosp  WITH(NOLOCK) WHERE WorkOrderId = WO.WorkOrderId order by WorkOrderShippingId desc), 110)) End)  as 'EstimatedCompletionDateType',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse (CONVERT(VARCHAR, (SELECT top 1 ShipDate from dbo.WorkOrderShipping wosp  WITH(NOLOCK) WHERE WorkOrderId = WO.WorkOrderId order by WorkOrderShippingId desc), 110)) End)  as 'EstimatedCompletionDate',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse emp.FirstName + ' ' + emp.LastName End)  as 'TechNameType',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse emp.FirstName + ' ' + emp.LastName End)  as 'TechName',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse emps.StationName End)  as 'TechStationType',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse emps.StationName End)  as 'TechStation',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse WPN.CustomerReference End)  as 'CustomerReferenceType',
			  (CASE WHEN Count(WPN.ID) > 1 Then 'Multiple' ELse WPN.CustomerReference End)  as 'CustomerReference'

          FROM dbo.WorkOrder WO WITH (NOLOCK)   
			  JOIN dbo.WorkOrderType WT WITH (NOLOCK) ON WO.WorkOrderTypeId = WT.Id  
			  JOIN dbo.WorkOrderPartNumber WPN WITH (NOLOCK) ON WO.WorkOrderId = WPN.WorkOrderId
			  LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On WPN.ItemMasterId=I.ItemMasterId  
			  LEFT JOIN dbo.WorkScope SC WITH(NOLOCK) On WPN.WorkOrderScopeId  = SC.WorkScopeId
			  LEFT JOIN dbo.Priority P WITH(NOLOCK) On WPN.WorkOrderPriorityId  = P.PriorityId
			  LEFT JOIN dbo.WorkOrderStage WOS WITH(NOLOCK) On WPN.WorkOrderStageId  = WOS.WorkOrderStageId
			  LEFT JOIN dbo.WorkOrderStatus WOST WITH(NOLOCK) On WPN.WorkOrderStatusId  = WOST.Id
			  LEFT JOIN dbo.Employee emp WITH(NOLOCK) On WPN.TechnicianId  = emp.EmployeeId  
			  LEFT JOIN dbo.EmployeeStation emps WITH(NOLOCK) On WPN.TechStationId  = emps.EmployeeStationId  
          WHERE ((WO.MasterCompanyId = @MasterCompanyId) AND (WO.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR WO.IsActive=@IsActive)   
				AND (@WorkOrderStatusId = 0 OR WPN.WorkOrderStatusId = @WorkOrderStatusId))
		  
		  GROUP BY WO.WorkOrderNum,WO.WorkOrderId,WO.CustomerId,WO.CustomerName ,WO.CustomerType, WO.OpenDate, WO.CreatedDate, WO.UpdatedDate,WO.CreatedBy,
			  WO.UpdatedBy,WO.IsActive,WO.IsDeleted,WT.Description,I.PartNumber,I.PartDescription,I.ManufacturerName,SC.WorkScopeCode,P.Description,
			  WOS.Code, WOS.Stage,WOST.Description,WPN.CustomerRequestDate,WPN.PromisedDate,WPN.EstimatedShipDate,emp.FirstName,emp.LastName,
			  emps.StationName, WPN.CustomerReference), 
  																																			  
          Result AS( SELECT DISTINCT M.WorkOrderId, UPPER(WorkOrderNum) AS WorkOrderNum, UPPER(WorkOrderType) AS WorkOrderType, UPPER(PartNumber) AS PartNos, UPPER(PartNumberType) AS PartNoType, UPPER(PartNumberType) AS PartNumberType, UPPER(PartDescription) AS PNDescription, UPPER(PartDescriptionType) AS PNDescriptionType, UPPER(ManufacturerName) AS ManufacturerName, UPPER(ManufacturerNameType) AS ManufacturerNameType,
              CustomerId, UPPER(CustomerName) AS CustomerName, UPPER(CustomerType) AS CustomerType, UPPER(WorkScopeDescription) AS WorkScope, UPPER(WorkScopeType) AS WorkScopeType,
              UPPER(PriorityDescription) AS Priority, UPPER(PriorityType) PriorityType, UPPER(WOStageDescription) AS Stage, UPPER(StageType) StageType, UPPER(WorkOrderStatus) WorkOrderStatus,
              UPPER(WorkOrderStatusType) WorkOrderStatusType, OpenDate, UPPER(CreatedBy) CreatedBy, UPPER(UpdatedBy) UpdatedBy, CreatedDate, UpdatedDate, CustomerRequestDate,   
              CustomerRequestDateType, PromisedDate, PromisedDateType, EstimatedShipDate, EstimatedShipDateType,   
              EstimatedCompletionDate, EstimatedCompletionDateType, UPPER(TechName) TechName, UPPER(TechNameType) TechNameType, UPPER(TechStation) TechStation, UPPER(TechStationType) TechStationType, UPPER(CustomerReference) CustomerReference, UPPER(CustomerReferenceType) CustomerReferenceType
          FROM Main M   
          ),  
         ResultCount AS(SELECT COUNT(WorkOrderId) AS totalItems FROM Result)  
          SELECT * INTO #TempResult1 from  Result  
          WHERE (  
           (@GlobalFilter <>'' AND (  
           (WorkOrderNum like '%' +@GlobalFilter+'%') OR  
           (WorkOrderType like '%' +@GlobalFilter+'%') OR  
           (PartNos like '%' +@GlobalFilter+'%') OR  
           (PNDescription like '%' +@GlobalFilter+'%') OR
		   (ManufacturerName like '%' +@GlobalFilter+'%') OR 
           (WorkScope like '%' +@GlobalFilter+'%') OR  
           (Priority like '%' +@GlobalFilter+'%') OR    
           (CustomerName like '%' +@GlobalFilter+'%' ) OR   
           (CustomerType like '%' +@GlobalFilter+'%') OR  
           (Stage like '%' +@GlobalFilter+'%') OR  
           (TechName like '%' +@GlobalFilter+'%') OR  
           (WorkOrderStatus like '%'+@GlobalFilter+'%') OR  
           (CreatedBy like '%' +@GlobalFilter+'%') OR  
           (WorkOrderStatusType like '%'+@GlobalFilter+'%') OR  
           (UpdatedBy like '%' +@GlobalFilter+'%') OR  
           (CustomerReference like '%' + @GlobalFilter +'%')  
           ))  
           OR     
           (@GlobalFilter='' AND (IsNull(@WorkOrderNum,'') ='' OR WorkOrderNum like '%' + @WorkOrderNum+'%') AND  
           (IsNull(@PartNumber,'') ='' OR PartNos like '%' + @PartNumber+'%') AND  
           (IsNull(@WorkOrderType,'') ='' OR WorkOrderType like '%' + @WorkOrderType+'%') AND  
           (IsNull(@PartDescription,'') ='' OR PNDescription like '%' + @PartDescription+'%') AND
		   (IsNull(@ManufacturerName,'') ='' OR ManufacturerName like '%' + @ManufacturerName+'%') AND  
           (IsNull(@WorkScope,'') ='' OR WorkScope like '%' + @WorkScope+'%') AND  
           (IsNull(@Priority,'') ='' OR Priority like '%' + @Priority+'%') AND  
           (IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') AND  
           (IsNull(@CustomerAffiliation,'') ='' OR CustomerType like '%' + @CustomerAffiliation+'%') AND  
           (IsNull(@Stage,'') ='' OR Stage like '%' + @Stage+'%') AND  
           (IsNull(@TechName,'') ='' OR TechName like '%' + @TechName+'%') AND  
           (IsNull(@TechStation,'') ='' OR TechStation like '%' + @TechStation+'%') AND  
           (IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND  
           (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND  
           --(IsNull(@OpenDate,'') ='' OR Cast(DBO.ConvertUTCtoLocal(OpenDate, @CurrntEmpTimeZoneDesc) as Date)=Cast(@OpenDate as date)) AND 
		   (ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS date)=CAST(@OpenDate AS date)) AND
           (IsNull(@CustReqDate,'') ='' OR Cast(CustomerRequestDate as Date)=Cast(@CustReqDate as date)) AND  
           (IsNull(@PromiseDate,'') ='' OR Cast(PromisedDate as Date)=Cast(@PromiseDate as date)) AND  
           (IsNull(@EstShipDate,'') ='' OR Cast(EstimatedShipDate as Date)=Cast(@EstShipDate as date)) AND  
           (IsNull(@ShipDate,'') ='' OR Cast(EstimatedCompletionDate as Date)=Cast(@ShipDate as date)) AND       
           (IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) AND  
           (IsNull(@WorkOrderStatusType,'') ='' OR WorkOrderStatusType like '%' + @WorkOrderStatusType+'%') AND  
           (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) AND  
           (IsNull(@CustRef,'') ='' OR CustomerReference like '%' + @CustRef+'%')  
           ))  
  
         SELECT @Count = COUNT(CustomerId) from #TempResult1     
  
         SELECT *, @Count As NumberOfItems FROM #TempResult1  
         ORDER BY    
         CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNos END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='partNoType')  THEN partNoType END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='pnDescriptionType')  THEN pnDescriptionType END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='workScopeType')  THEN workScopeType END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='customerRequestDateType')  THEN customerRequestDateType END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='promisedDateType')  THEN promisedDateType END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='estimatedShipDateType')  THEN estimatedShipDateType END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='estimatedCompletionDateType')  THEN estimatedCompletionDateType END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='stageType')  THEN stageType END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='workOrderStatusType')  THEN workOrderStatusType END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='PriorityType')  THEN PriorityType END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='CustomerType')  THEN CustomerType END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderType')  THEN WorkOrderType END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PNDescription END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='WORKSCOPE')  THEN WorkScope END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN Priority END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERAFFILICATION')  THEN CustomerType END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='STAGE')  THEN Stage END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='TECHNAME')  THEN TechName END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='TECHSTATION')  THEN TechStation END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERSTATUS')  THEN WorkOrderStatus END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='CUSTREQDATE')  THEN CustomerRequestDate END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='PROMISEDATE')  THEN PromisedDate END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='ESTSHIPDATE')  THEN EstimatedShipDate END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='SHIPDDATE')  THEN EstimatedCompletionDate END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END ASC,  
         CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC, 
         CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNos END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='partNoType')  THEN partNoType END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='pnDescriptionType')  THEN pnDescriptionType END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='workScopeType')  THEN workScopeType END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='customerRequestDateType')  THEN customerRequestDateType END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='promisedDateType')  THEN promisedDateType END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='estimatedShipDateType')  THEN estimatedShipDateType END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='estimatedCompletionDateType')  THEN estimatedCompletionDateType END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='stageType')  THEN stageType END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='PriorityType')  THEN PriorityType END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerType')  THEN CustomerType END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='workOrderStatusType')  THEN workOrderStatusType END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderType')  THEN WorkOrderType END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PNDescription END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC, 
		 CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='WORKSCOPE')  THEN WorkScope END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITY')  THEN Priority END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERAFFILICATION')  THEN CustomerType END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='STAGE')  THEN Stage END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='TECHNAME')  THEN TechName END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='TECHSTATION')  THEN TechStation END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERSTATUS')  THEN WorkOrderStatus END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTREQDATE')  THEN CustomerRequestDate END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='PROMISEDATE')  THEN PromisedDate END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='ESTSHIPDATE')  THEN EstimatedShipDate END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='SHIPDDATE')  THEN EstimatedCompletionDate END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,  
         CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerReference')  THEN CustomerReference END DESC  
  
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
                @Parameter31 = ' + ISNULL(CAST(@TechStation AS VARCHAR(10)) ,'') +''  
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