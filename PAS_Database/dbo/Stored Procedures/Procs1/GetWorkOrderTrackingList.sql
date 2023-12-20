/*************************************************************           
 ** File:   [USP_AddEdit_WorkOrderTurnArroundTime]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Create Stockline ForCustomer RMA   
 ** Purpose:         
 ** Date:   02/05/2022        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/05/20221   Subhash Saliya		Created
 ** 1    05/26/2023    HEMANT SALIYA    Updated For WorkOrder Settings
 
-- EXEC [USP_AddEdit_WorkOrderTurnArroundTime] 44
**************************************************************/
CREATE   PROCEDURE [dbo].[GetWorkOrderTrackingList]  
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
 @TotalDaysinStage varchar(50)=null,
 @ManagerName varchar(50)= null,
 @ItemGroup varchar(50)= null,
 @SalespersonName varchar(50)= null,
 @CSRName varchar(50)= null,
 @TATDaysStandard varchar(50)=null,
 @Quoteamount varchar(50)=null
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN   
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
     Set @IsDeleted=0  
    END    
  
    IF (@ViewType IS NULL OR @ViewType = '')  
    BEGIN  
     Set @ViewType= 'mpn'  
    END   
  
    IF (@GlobalFilter IS NULL OR @GlobalFilter = '')  
    BEGIN  
     Set @GlobalFilter= ''  
    END   
  
    IF @SortColumn is null  
    BEGIN  
     Set @SortColumn=Upper('CreatedDate')  
    END   
    Else  
    BEGIN   
     Set @SortColumn=Upper(@SortColumn)  
    END  
  
    If @StatusID = 0  
    BEGIN   
     Set @IsActive = 0  
    END   
    ELSE IF @StatusID = 1  
    BEGIN   
     Set @IsActive = 1  
    END   
    ELSE IF @StatusID = 2  
    BEGIN   
     Set @IsActive=null  
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
  
    IF LOWER(@ViewType) = 'mpn'  
     BEGIN  
      ;WITH Result AS(  
       SELECT   
			MAX(WO.WorkOrderNum) AS WorkOrderNum,   
			MAX(WO.WorkOrderId) AS WorkOrderId,
			MAX(WPN.ID) AS WorkorderPartId,
			MAX(WO.CustomerId) AS CustomerId, 
			MAX(IM.ItemMasterId) AS ItemMasterId, 
			MAX(IM.partnumber) AS PartNos,  
			MAX(IM.partnumber) AS PartNoType,  
			MAX(IM.PartDescription) AS PNDescription,  
			MAX(IM.PartDescription) AS PNDescriptionType,  
			MAX(WPN.WorkScope) AS WorkScope,  
			MAX(WPN.WorkScope) AS WorkScopeType,  
			MAX(PR.Description) As Priority,    
			MAX(PR.Description) As PriorityType,   
			MAX(WO.CustomerName) AS CustomerName,  
			MAX(WO.CustomerType) AS CustomerType,       
			MAX(WOSG.Code + '-' + WOSG.Stage) AS  Stage,  
			MAX(WOSG.Code + '-' + WOSG.Stage) AS  StageType,  
			MAX(WOS.Description) AS WorkOrderStatus,  
			MAX(WOS.Description) AS WorkOrderStatusType,  
			MAX(WO.OpenDate) AS OpenDate,  
			MAX(WPN.CustomerRequestDate) AS CustomerRequestDate,  
			MAX(WPN.CustomerRequestDate) AS CustomerRequestDateType,  
			MAX(WPN.PromisedDate) AS PromisedDate,  
			MAX(WPN.PromisedDate) AS PromisedDateType,  
			MAX(WPN.EstimatedShipDate) AS EstimatedShipDate,  
			MAX(WPN.EstimatedShipDate) AS EstimatedShipDateType,  
			((Select top 1 ShipDate from dbo.WorkOrderShipping wosp  WITH(NOLOCK) where WorkOrderId = WO.WorkOrderId order by WorkOrderShippingId desc))as EstimatedCompletionDate,  
			((Select top 1 ShipDate from dbo.WorkOrderShipping wosp  WITH(NOLOCK) where WorkOrderId = WO.WorkOrderId order by WorkOrderShippingId desc))as EstimatedCompletionDateType,  
			(isnull((sum(WTT.[Days])+ (sum(WTT.[Hours])/24)+ (sum(WTT.[Mins])/1440)),0)) as TotalDaysinStage,
			MAX(EMPStage.FirstName) + ' ' + MAX(EMPStage.LastName) AS ManagerName,
			MAX(IM.ItemGroup) as ItemGroup,
			MAX(EMPsales.FirstName) + ' ' + MAX(EMPsales.LastName) AS SalespersonName,
			MAX(EMPcsr.FirstName) + ' ' + MAX(EMPcsr.LastName) AS CSRName,
			MAX(WPN.TATDaysStandard) AS TATDaysStandard,
			MAX(WO.CreatedDate) AS CreatedDate,  
			MAX(WO.UpdatedDate) AS UpdatedDate,  
			MAX(WO.CreatedBy) AS CreatedBy,  
			MAX(WO.UpdatedBy) AS UpdatedBy,  
			MAX(CASE WHEN wo.IsActive=1 THEN 1 ELSE 0 END) AS IsActive,  
			MAX(CASE WHEN WO.IsDeleted=1 THEN 1 ELSE 0 END) AS IsDeleted,  
			MAX(WPN.WorkOrderStatusId) AS WorkOrderStatusId,  
			MAX(WT.Description) AS WorkOrderType,  
			MAX(EMP.FirstName) + ' ' + MAX(EMP.LastName) AS TechName,  
			MAX(EMPS.StationName) AS TechStation,  
			MAX(STL.SerialNumber) AS SerialNumber,  
			MAX(WPN.CustomerReference) AS CustomerReference,  
			MAX(WPN.CustomerReference) AS CustomerReferenceType,
			(case when Max(WPN.TATDaysCurrent) > Max(WPN.TATDaysStandard) then 'red' when (isnull((sum(WTT.[Days])+ (sum(WTT.[Hours])/24)+ (sum(WTT.[Mins])/1440)),0)) >= Max(Isnull(wost.StandardTurntimeDays,0)) then (Case when  MAX(CASE WHEN wost.StandardTurntimecolour=1 THEN 1 ELSE 0 END) =1 then 'green' Else 'yellow' End) else (Case when MAX(CASE WHEN wost.StandardTurntimecolour=1 THEN 1 ELSE 0 END) =1 then 'yellow' Else 'green' End)  end) as colourcode , 
			MAX(case when woq.QuoteMethod =1 then isnull(CommonFlatRate,0) else isnull((woq.FreightFlatBillingAmount+woq.ChargesFlatBillingAmount+woq.LaborFlatBillingAmount+woq.MaterialFlatBillingAmount),0) end) as Quoteamount
       FROM WorkOrder WO WITH(NOLOCK)  
			JOIN dbo.WorkOrderPartNumber WPN WITH(NOLOCK) ON WO.WorkOrderId = WPN.WorkOrderId
			left JOIN dbo.WorkOrderTurnArroundTime WTT WITH(NOLOCK) ON WTT.WorkOrderPartNoId = WPN.ID
			left JOIN dbo.WorkOrderQuoteDetails woq WITH(NOLOCK) ON woq.WOPartNoId = WPN.ID  
			JOIN dbo.WorkOrderType WT WITH(NOLOCK) ON WO.WorkOrderTypeId = WT.Id  
			JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WPN.ID = WOWF.WorkOrderPartNoId  
			JOIN dbo.WorkOrderStatus WOS WITH(NOLOCK) ON WOS.Id = WPN.WorkOrderStatusId  
			JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId  
			LEFT JOIN dbo.Stockline STL WITH(NOLOCK) ON WPN.StockLineId = STL.StockLineId
			LEFT JOIN dbo.WorkOrderSettings wost WITH(NOLOCK) ON wost.MasterCompanyId = WO.MasterCompanyId  AND wost.WorkOrderTypeId = WO.WorkOrderTypeId
			JOIN dbo.Priority PR WITH(NOLOCK) ON WPN.WorkOrderPriorityId = PR.PriorityId  
			JOIN dbo.WorkOrderStage WOSG WITH(NOLOCK) ON WTT.OldStageId = WOSG.WorkOrderStageId and wosg.IncludeInDashboard=1   
			LEFT JOIN dbo.Employee EMP WITH(NOLOCK) ON EMP.EmployeeId = WPN.TechnicianId
			LEFT JOIN dbo.Employee EMPStage WITH(NOLOCK) ON EMPStage.EmployeeId = WOSG.ManagerId
			LEFT JOIN dbo.Employee EMPsales WITH(NOLOCK) ON EMPsales.EmployeeId = WO.SalesPersonId
			LEFT JOIN dbo.Employee EMPcsr WITH(NOLOCK) ON EMPcsr.EmployeeId = WO.CSRId 
			LEFT JOIN dbo.EmployeeStation EMPS WITH(NOLOCK) ON WPN.TechStationId = EMPS.EmployeeStationId
       WHERE ((WO.MasterCompanyId = @MasterCompanyId) AND (WO.IsDeleted = @IsDeleted) AND (@IsActive is null or WO.IsActive = @IsActive)   AND (@WorkOrderStatusId = 0 OR WPN.WorkOrderStatusId = @WorkOrderStatusId))    GROUP BY WPN.ID, WTT.OldStageId,WO.WorkOrderId HAVING isnull((sum(WTT.[Days])+ (sum(WTT.[Hours])/24)+ (sum(WTT.[Mins])/1440)),0) >=1
        ), ResultCount AS(Select COUNT(WorkOrderId) AS totalItems FROM Result)  
        Select * INTO #TempResult from  Result  
        WHERE (  
        (@GlobalFilter <>'' AND (  
        (WorkOrderNum like '%' +@GlobalFilter+'%') OR  
        (WorkOrderType like '%' +@GlobalFilter+'%') OR  
        (PartNos like '%' +@GlobalFilter+'%') OR  
        (PNDescription like '%' +@GlobalFilter+'%') OR  
        (WorkScope like '%' +@GlobalFilter+'%') OR  
        (Priority like '%' +@GlobalFilter+'%') OR    
        (CustomerName like '%' +@GlobalFilter+'%' ) OR   
        (CustomerType like '%' +@GlobalFilter+'%') OR  
        (Stage like '%' +@GlobalFilter+'%') OR  
        (TechName like '%' +@GlobalFilter+'%') OR  
        (TechStation like '%' +@GlobalFilter+'%') OR  
        (WorkOrderStatus like '%'+@GlobalFilter+'%') OR  
        (WorkOrderStatusType like '%'+@GlobalFilter+'%') OR 
		
		(TotalDaysinStage like '%' +@GlobalFilter+'%') OR  
        (ManagerName like '%' +@GlobalFilter+'%') OR  
        (ItemGroup like '%'+@GlobalFilter+'%') OR  
        (SalespersonName like '%'+@GlobalFilter+'%') OR 
		(CSRName like '%'+@GlobalFilter+'%') OR  
        (TATDaysStandard like '%'+@GlobalFilter+'%') OR 
		(Quoteamount like '%'+@GlobalFilter+'%') OR 

        (CreatedBy like '%' +@GlobalFilter+'%') OR  
        (UpdatedBy like '%' +@GlobalFilter+'%') OR  
        (SerialNumber like '%' +@GlobalFilter+'%') OR  
        (CustomerReference like '%' +@GlobalFilter+'%')  
        ))  
        OR     
        (@GlobalFilter='' AND (IsNull(@WorkOrderNum,'') ='' OR WorkOrderNum like '%' + @WorkOrderNum+'%') AND  
        (IsNull(@PartNumber,'') ='' OR PartNos like '%' + @PartNumber+'%') AND  
        (IsNull(@PartDescription,'') ='' OR PNDescription like '%' + @PartDescription+'%') AND  
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
        (IsNull(@OpenDate,'') ='' OR Cast(OpenDate as Date)=Cast(@OpenDate as date)) AND  
        (IsNull(@CustReqDate,'') ='' OR Cast(CustomerRequestDate as Date)=Cast(@CustReqDate as date)) AND  
        (IsNull(@PromiseDate,'') ='' OR Cast(PromisedDate as Date)=Cast(@PromiseDate as date)) AND  
        (IsNull(@EstShipDate,'') ='' OR Cast(EstimatedShipDate as Date)=Cast(@EstShipDate as date)) AND  
        (IsNull(@ShipDate,'') ='' OR Cast(EstimatedCompletionDate as Date)=Cast(@ShipDate as date)) AND       
        (IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) AND  
        (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) AND  
        (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND 
		
		(IsNull(@ManagerName,'') ='' OR ManagerName like '%' + @ManagerName+'%') AND
		(IsNull(@ItemGroup,'') ='' OR ItemGroup like '%' + @ItemGroup+'%') AND  
		(IsNull(@SalespersonName,'') ='' OR SalespersonName like '%' + @SalespersonName+'%') AND  
	    (IsNull(@CSRName,'') ='' OR CSRName like '%' + @CSRName+'%') AND  
		(IsNull(@TATDaysStandard,'') ='' OR TATDaysStandard like '%' + @TATDaysStandard+'%') AND  
		(IsNull(@TotalDaysinStage,'') ='' OR TotalDaysinStage like '%' + @TotalDaysinStage+'%') AND 
		(IsNull(@Quoteamount,'') ='' OR Quoteamount= @Quoteamount) AND 
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
  
        CASE WHEN (@SortOrder=1 and @SortColumn='TotalDaysinStage') THEN TotalDaysinStage END ASC,
		CASE WHEN (@SortOrder=1 and @SortColumn='ManagerName') THEN ManagerName END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='ItemGroup') THEN ItemGroup END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='SalespersonName') THEN SalespersonName END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='CSRName') THEN CSRName END ASC,  
		CASE WHEN (@SortOrder=1 and @SortColumn='TATDaysStandard') THEN TATDaysStandard END ASC, 
		CASE WHEN (@SortOrder=1 and @SortColumn='Quoteamount') THEN Quoteamount END ASC, 
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
		
		CASE WHEN (@SortOrder=-1 and @SortColumn='TotalDaysinStage') THEN TotalDaysinStage END DESC,
		CASE WHEN (@SortOrder=-1 and @SortColumn='ManagerName') THEN ManagerName END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='ItemGroup') THEN ItemGroup END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='SalespersonName') THEN SalespersonName END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='CSRName') THEN CSRName END DESC,  
		CASE WHEN (@SortOrder=-1 and @SortColumn='TATDaysStandard') THEN TATDaysStandard END DESC,
		CASE WHEN (@SortOrder=-1 and @SortColumn='Quoteamount') THEN Quoteamount END DESC, 
        CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END DESC  
  
        OFFSET @RecordFrom ROWS   
        FETCH NEXT @PageSize ROWS ONLY  
       END  
      ELSE  
       BEGIN     
       print  'Step 2';  
        ;WITH Main AS(  
         SELECT DISTINCT   
          WO.WorkOrderNum,   
          WO.WorkOrderId,  
          WO.CustomerId,  
          WO.CustomerName,  
          WO.CustomerType,  
          WO.OpenDate,  
          WO.CreatedDate,  
          WO.UpdatedDate,  
          WO.CreatedBy,  
          WO.UpdatedBy,  
          WO.IsActive,  
          WO.IsDeleted,  
          WT.Description AS WorkOrderType,
		  EMPsales.FirstName + ' ' + EMPsales.LastName AS SalespersonName,
		  EMPcsr.FirstName + ' ' + EMPcsr.LastName AS CSRName
         FROM dbo.WorkOrder WO WITH(NOLOCK)   
          JOIN dbo.WorkOrderType WT WITH(NOLOCK)  ON WO.WorkOrderTypeId = WT.Id  
          JOIN dbo.WorkOrderPartNumber WPN WITH(NOLOCK)  ON WO.WorkOrderId = WPN.WorkOrderId
		  LEFT JOIN dbo.Employee EMPsales WITH(NOLOCK) ON EMPsales.EmployeeId = WO.SalesPersonId
          LEFT JOIN dbo.Employee EMPcsr WITH(NOLOCK) ON EMPcsr.EmployeeId = WO.CSRId 
          WHERE ((WO.MasterCompanyId = @MasterCompanyId) AND (WO.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR WO.IsActive=@IsActive)   
          AND (@WorkOrderStatusId = 0 OR WPN.WorkOrderStatusId = @WorkOrderStatusId)  
          )),  
          PartCTE AS(  
          SELECT WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumberType', A.PartNumber from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(  
           SELECT   
            STUFF((SELECT ',' + I.partnumber  
              FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)  
              LEFT JOIN dbo.ItemMaster I WITH(NOLOCK) On WOPN.ItemMasterId  = I.ItemMasterId  
              Where WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
              FOR XML PATH('')), 1, 1, '') PartNumber  
          ) A   
          WHERE (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted=@IsDeleted )  
          GROUP BY WO.WorkOrderId, A.PartNumber),  
  
          PartDescCTE AS(  
          Select WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.PartDescription End)  as 'PartDescriptionType', A.PartDescription from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(  
           SELECT   
            STUFF((SELECT ',' + im.PartDescription  
              FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)  
              LEFT JOIN dbo.ItemMaster im WITH(NOLOCK) On WOPN.ItemMasterId  = im.ItemMasterId  
              Where WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
              FOR XML PATH('')), 1, 1, '') PartDescription  
          ) A  
          WHERE (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted=@IsDeleted)  
          GROUP BY WO.WorkOrderId, A.PartDescription),  
  
          WorkScopeCTE AS(  
          SELECT WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.WorkScopeDescription End)  as 'WorkScopeType', A.WorkScopeDescription from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(  
           SELECT   
            STUFF((SELECT ',' + SC.WorkScopeCode  
              FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)  
              LEFT JOIN dbo.WorkScope SC WITH(NOLOCK) On WOPN.WorkOrderScopeId  = SC.WorkScopeId  
              Where WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
              FOR XML PATH('')), 1, 1, '') WorkScopeDescription  
          ) A  
          Where WO.MasterCompanyId = @MasterCompanyId AND (WO.IsDeleted=@IsDeleted)  
          Group By WO.WorkOrderId, A.WorkScopeDescription),  
  
          PriorityCTE AS(  
          SELECT WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.PriorityDescription End)  as 'PriorityType', A.PriorityDescription from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(  
           SELECT   
            STUFF((SELECT ',' + P.Description  
              FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)  
              LEFT JOIN dbo.Priority P WITH(NOLOCK) On WOPN.WorkOrderPriorityId  = P.PriorityId  
              Where WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
              FOR XML PATH('')), 1, 1, '') PriorityDescription  
          ) A  
          Where (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted=@IsDeleted)  
          Group By WO.WorkOrderId, A.PriorityDescription),  
  
          StageCTE AS(  
          SELECT WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.WOStageDescription End)  as 'StageType', A.WOStageDescription from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(  
           SELECT   
            STUFF((SELECT ',' + WOS.Code + '-' + WOS.Stage   
              FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)  
              LEFT JOIN dbo.WorkOrderStage WOS WITH(NOLOCK) On WOPN.WorkOrderStageId  = WOS.WorkOrderStageId  
              Where WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
              FOR XML PATH('')), 1, 1, '') WOStageDescription  
          ) A  
          Where (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted=@IsDeleted)   
          Group By WO.WorkOrderId, A.WOStageDescription),  
  
          WOStatusCTE AS(  
          SELECT WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.WorkOrderStatus End)  as 'WorkOrderStatusType', A.WorkOrderStatus from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(  
           SELECT   
            STUFF((SELECT ',' + WOST.Description  
              FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)  
              LEFT JOIN dbo.WorkOrderStatus WOST WITH(NOLOCK) On WOPN.WorkOrderStatusId  = WOST.Id  
              Where WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
              FOR XML PATH('')), 1, 1, '') WorkOrderStatus  
          ) A  
          Where (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted=@IsDeleted)  
          Group By WO.WorkOrderId, A.WorkOrderStatus),  
  
          CRDateCTE AS(  
          SELECT WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELSE A.CustomerRequestDate End)  as 'CustomerRequestDateType', A.CustomerRequestDate from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(SELECT STUFF((SELECT ',' + CONVERT(VARCHAR, WOPN.CustomerRequestDate, 110)   
             FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)            
             WHERE WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsDeleted = 0  
             FOR XML PATH('')), 1, 1, '') CustomerRequestDate) A  
          WHERE (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted=@IsDeleted)  
          GROUP BY WO.WorkOrderId, A.CustomerRequestDate),  
  
          PromisedDateCTE AS(  
          SELECT WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.PromisedDate End)  as 'PromisedDateType', A.PromisedDate from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(SELECT STUFF((SELECT ',' + CONVERT(VARCHAR, WOPN.PromisedDate, 110)  
             FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)          
             WHERE WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsDeleted = 0  
             FOR XML PATH('')), 1, 1, '') PromisedDate) A  
          WHERE (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted=@IsDeleted)  
          GROUP BY WO.WorkOrderId, A.PromisedDate),  
  
          ESShipDateCTE AS(  
          SELECT WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.EstimatedShipDate End)  as 'EstimatedShipDateType', A.EstimatedShipDate from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(SELECT STUFF((SELECT ',' + CONVERT(VARCHAR, WOPN.EstimatedShipDate, 110)    
             FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)           
             WHERE WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsDeleted = 0  
             FOR XML PATH('')), 1, 1, '') EstimatedShipDate) A  
          WHERE (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted=@IsDeleted)  
          GROUP BY WO.WorkOrderId, A.EstimatedShipDate),  
           
          ESCompDateCTE AS(  
          SELECT WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.EstimatedCompletionDate End)  as 'EstimatedCompletionDateType', A.EstimatedCompletionDate from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(SELECT STUFF((SELECT ',' + CONVERT(VARCHAR, (Select top 1 ShipDate from dbo.WorkOrderShipping wosp  WITH(NOLOCK) where WorkOrderId = WO.WorkOrderId order by WorkOrderShippingId desc), 110)    
             FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)          
             WHERE WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsDeleted = 0  
             FOR XML PATH('')), 1, 1, '') EstimatedCompletionDate) A  
          WHERE (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted=@IsDeleted)  
          GROUP BY WO.WorkOrderId, A.EstimatedCompletionDate),  
  
          TechNameCTE AS(  
          Select WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.TechName End)  as 'TechNameType', A.TechName from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(  
           SELECT   
            STUFF((SELECT ',' + emp.FirstName + ' ' + emp.LastName  
              FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)  
              JOIN dbo.Employee emp WITH(NOLOCK) On WOPN.TechnicianId  = emp.EmployeeId  
              Where WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
              FOR XML PATH('')), 1, 1, '') TechName  
          ) A  
          WHERE (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted=@IsDeleted)  
          GROUP BY WO.WorkOrderId, A.TechName),  
  
          TechStationCTE AS(  
          Select WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.TechStation End)  as 'TechStationType', A.TechStation from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(  
           SELECT   
            STUFF((SELECT ',' + emp.StationName  
              FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)  
              LEFT JOIN dbo.EmployeeStation emp WITH(NOLOCK) On WOPN.TechStationId  = emp.EmployeeStationId  
              Where WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
              FOR XML PATH('')), 1, 1, '') TechStation  
          ) A  
          WHERE (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted=@IsDeleted)  
          GROUP BY WO.WorkOrderId, A.TechStation),  
  
          CustRefCTE AS(  
          Select WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.CustomerReference End)  as 'CustomerReferenceType', A.CustomerReference from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(  
           SELECT   
            STUFF((SELECT ',' + WOPN.CustomerReference  
              FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)          
              WHERE WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsDeleted = 0  
              FOR XML PATH('')), 1, 1, '') CustomerReference  
          ) A  
          WHERE (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted = @IsDeleted)  
          GROUP BY WO.WorkOrderId, A.CustomerReference), 
		  
		  ManagerCTE AS(  
          Select WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.ManagerName End)  as 'ManagerNameType', A.ManagerName from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(  
           SELECT   
            STUFF((SELECT ',' + EMPStage.FirstName + ' ' + EMPStage.LastName  
              FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)
			  LEFT JOIN dbo.WorkOrderStage wos WITH(NOLOCK) ON wos.WorkOrderStageId = WOPN.WorkOrderStageId
			  LEFT JOIN dbo.Employee EMPStage WITH(NOLOCK) ON EMPStage.EmployeeId = wos.ManagerId
              WHERE WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsDeleted = 0  
              FOR XML PATH('')), 1, 1, '') ManagerName  
          ) A   
          WHERE (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted = @IsDeleted)  
          GROUP BY WO.WorkOrderId, A.ManagerName),
		  
		  TotalDaysinStageCTE AS(  
          Select WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.TotalDaysinStage End)  as 'TotalDaysinStageType', A.TotalDaysinStage from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(  
           SELECT   
            STUFF((SELECT ',' + cast(isnull((sum(wott.[Days])+ (sum(wott.[Hours])/24)+ (sum(wott.[Mins])/1440)),0) as varchar(100))  
              FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)
			  LEFT JOIN dbo.WorkOrderTurnArroundTime wott WITH(NOLOCK) ON wott.WorkOrderPartNoId = WOPN.ID
              WHERE WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsDeleted = 0 GROUP BY wott.WorkOrderPartNoId  
              FOR XML PATH('')), 1, 1, '') TotalDaysinStage  
          ) A  
          WHERE (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted = @IsDeleted)  
          GROUP BY WO.WorkOrderId, A.TotalDaysinStage),
		  
		  ItemGroupCTE AS(  
          Select WO.WorkOrderId,(CASE WHEN Count(WOPN.ID) > 1 Then 'Multiple' ELse A.ItemGroup End)  as 'ItemGroupType', A.ItemGroup from WorkOrder WO WITH(NOLOCK)  
          LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) On WO.WorkOrderId = WOPN.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
          OUTER APPLY(  
           SELECT   
            STUFF((SELECT ',' + im.ItemGroup  
              FROM dbo.WorkOrderPartNumber WOPN WITH(NOLOCK)  
              LEFT JOIN dbo.ItemMaster im WITH(NOLOCK) On WOPN.ItemMasterId  = im.ItemMasterId  
              Where WOPN.WorkOrderId = WO.WorkOrderId AND WOPN.IsActive = 1 AND WOPN.IsDeleted = 0  
              FOR XML PATH('')), 1, 1, '') ItemGroup  
          ) A  
          WHERE (WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted=@IsDeleted)  
          GROUP BY WO.WorkOrderId, A.ItemGroup), 
  
          Result AS( SELECT DISTINCT M.WorkOrderId, WorkOrderNum, WorkOrderType, PT.PartNumber AS PartNos, PT.PartNumberType AS PartNoType, PT.PartNumberType, PD.PartDescription AS PNDescription, PD.PartDescriptionType AS PNDescriptionType,   
              CustomerId, CustomerName, CustomerType,  WS.WorkScopeDescription AS WorkScope, WS.WorkScopeType,   
              PC.PriorityDescription AS Priority, PC.PriorityType, SC.WOStageDescription AS Stage, SC.StageType,  WOSC.WorkOrderStatus,             
              WOSC.WorkOrderStatusType, OpenDate, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, CRC.CustomerRequestDate,   
              CRC.CustomerRequestDateType, PMC.PromisedDate, PMC.PromisedDateType, ESC.EstimatedShipDate, ESC.EstimatedShipDateType,   
              EC.EstimatedCompletionDate, EC.EstimatedCompletionDateType, TN.TechName, TN.TechNameType, TS.TechStation, TS.TechStationType, CR.CustomerReference, CR.CustomerReferenceType ,SalespersonName,CSRName,MN.ManagerName,MN.ManagerNameType,
			  TD.TotalDaysinStage,td.TotalDaysinStageType,IG.ItemGroup,ig.ItemGroupType
          FROM Main M   
          LEFT JOIN PartCTE PT On M.WorkOrderId = PT.WorkOrderId  
          LEFT JOIN PartDescCTE PD On M.WorkOrderId = PD.WorkOrderId  
          LEFT JOIN WorkScopeCTE WS On M.WorkOrderId = WS.WorkOrderId  
          LEFT JOIN PriorityCTE PC On M.WorkOrderId = PC.WorkOrderId  
          LEFT JOIN StageCTE SC On M.WorkOrderId = SC.WorkOrderId  
          LEFT JOIN WOStatusCTE WOSC On M.WorkOrderId = WOSC.WorkOrderId  
          LEFT JOIN CRDateCTE CRC On M.WorkOrderId = CRC.WorkOrderId  
          LEFT JOIN PromisedDateCTE PMC On M.WorkOrderId = PMC.WorkOrderId  
          LEFT JOIN ESShipDateCTE ESC On M.WorkOrderId = ESC.WorkOrderId  
          LEFT JOIN ESCompDateCTE EC On M.WorkOrderId = EC.WorkOrderId  
          LEFT JOIN TechNameCTE TN On M.WorkOrderId = TN.WorkOrderId  
          LEFT JOIN TechStationCTE TS On M.WorkOrderId = TS.WorkOrderId  
          LEFT JOIN CustRefCTE CR On M.WorkOrderId = CR.WorkOrderId 
		  LEFT JOIN ManagerCTE MN On M.WorkOrderId = MN.WorkOrderId  
          LEFT JOIN TotalDaysinStageCTE TD On M.WorkOrderId = TD.WorkOrderId  
          LEFT JOIN ItemGroupCTE IG On M.WorkOrderId = IG.WorkOrderId 
          ),  
         ResultCount AS(Select COUNT(WorkOrderId) AS totalItems FROM Result)  
          SELECT * INTO #TempResult1 from  Result  
          WHERE (  
           (@GlobalFilter <>'' AND (  
           (WorkOrderNum like '%' +@GlobalFilter+'%') OR  
           (WorkOrderType like '%' +@GlobalFilter+'%') OR  
           (PartNos like '%' +@GlobalFilter+'%') OR  
           (PNDescription like '%' +@GlobalFilter+'%') OR  
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
           (IsNull(@WorkScope,'') ='' OR WorkScope like '%' + @WorkScope+'%') AND  
           (IsNull(@Priority,'') ='' OR Priority like '%' + @Priority+'%') AND  
           (IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') AND  
           (IsNull(@CustomerAffiliation,'') ='' OR CustomerType like '%' + @CustomerAffiliation+'%') AND  
           (IsNull(@Stage,'') ='' OR Stage like '%' + @Stage+'%') AND  
           (IsNull(@TechName,'') ='' OR TechName like '%' + @TechName+'%') AND  
           (IsNull(@TechStation,'') ='' OR TechStation like '%' + @TechStation+'%') AND  
           (IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND  
           (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND  
           (IsNull(@OpenDate,'') ='' OR Cast(OpenDate as Date)=Cast(@OpenDate as date)) AND  
           (IsNull(@CustReqDate,'') ='' OR Cast(CustomerRequestDate as Date)=Cast(@CustReqDate as date)) AND  
           (IsNull(@PromiseDate,'') ='' OR Cast(PromisedDate as Date)=Cast(@PromiseDate as date)) AND  
           (IsNull(@EstShipDate,'') ='' OR Cast(EstimatedShipDate as Date)=Cast(@EstShipDate as date)) AND  
           (IsNull(@ShipDate,'') ='' OR Cast(EstimatedCompletionDate as Date)=Cast(@ShipDate as date)) AND       
           (IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) AND  
           (IsNull(@WorkOrderStatusType,'') ='' OR WorkOrderStatusType like '%' + @WorkOrderStatusType+'%') AND  
           (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) AND  
           (IsNull(@CustRef,'') ='' OR CustomerReference like '%' + @CustRef+'%')  
           ))  
  
         Select @Count = COUNT(CustomerId) from #TempResult1     
  
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
  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
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