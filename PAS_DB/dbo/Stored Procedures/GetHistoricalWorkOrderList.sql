/*************************************************************           
 ** File:   [GetHistoricalWorkOrderList]           
 ** Author:   Hemant Saliya
 ** Description: Get Search Historical Data for Work Order List    
 ** Purpose:         
 ** Date:   15-MAR-2020        
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/15/2020   Hemant Saliya Created

 EXECUTE [GetHistoricalWorkOrderList] 1, 100, null, -1, 1, '', '','','','','','','','','','2021-02-26','','','','','','','',1
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetHistoricalWorkOrderList]	
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter varchar(50) = null,
	@WorkOrderNumber varchar(50)=null,
	@CustomerName varchar(50)=null,	
	@CustomerCode varchar(50)=null,	
	@WOType varchar(50)=null,		
	@PartNumber varchar(50)=null,
	@PartDescription varchar(50)=null,
	@WorkScope  varchar(50)=null,
	@ItemMasterID varchar(50)=null,
	@OpenDate datetime=null,
	@PromisedDate datetime=null,
	@EstimatedCompletionDate datetime=null,
	@EstimatedShipDate datetime=null,
    @CreatedDate datetime=null,
	@UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,	
    @IsDeleted bit= null,
	@MasterCompanyId int = 1,
	@customerId int = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					DECLARE @RecordFrom int;
					DECLARE @IsActive bit=1
					DECLARE @Count Int;

					SET @RecordFrom = (@PageNumber-1)*@PageSize;
					IF @IsDeleted is null
					Begin
						Set @IsDeleted=0
					End
					IF @SortColumn is null
					Begin
						Set @SortColumn=Upper('CreatedDate')
					End 
					Else
					Begin 
						Set @SortColumn=Upper(@SortColumn)
					End

					If @StatusID=0
					Begin 
						Set @IsActive=0
					End 
					else IF @StatusID=1
					Begin 
						Set @IsActive=1
					End 
					else IF @StatusID=2
					Begin 
						Set @IsActive=null
					End 

					IF(ISNULL(@customerId,0) !=0)
					BEGIN
					;With Result AS(
						SELECT	
								WO.WorkOrderId, 					
								WO.WorkOrderNum,
								CASE	
									WHEN WO.WorkOrderTypeId = 1 THEN 'Customer'
									WHEN WO.WorkOrderTypeId = 2 THEN 'Internal'
									WHEN WO.WorkOrderTypeId = 3 THEN 'Tear Down'
									ELSE 'Shop Services'
								END AS WOType,
								C.Name AS CustomerName,
								C.CustomerCode,
								WO.CustomerId,
								WO.OpenDate,
								WOP.PromisedDate,
								WOP.EstimatedCompletionDate,					
								WOP.EstimatedShipDate,					
								IM.PartNumber AS PartNo,
								IM.PartDescription AS PNDescription,
								WOP.WorkOrderScopeId AS WorkScopeId,
								WOP.ItemMasterId,
								WO.IsActive,
								WO.IsDeleted,
								WO.CreatedDate,
								WO.CreatedBy,
								WO.UpdatedDate,
								WO.UpdatedBy					
						FROM WorkOrder WO WITH (NOLOCK)
								INNER JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) on WO.WorkOrderId = WOP.WorkOrderId
								INNER JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) on WOP.ID = WOWF.WorkOrderPartNoId
								INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) on IM.ItemMasterId =  WOP.ItemMasterId
								INNER JOIN dbo.Customer C WITH (NOLOCK) on C.CustomerId = WO.CustomerId
						WHERE (WO.MasterCompanyId = @MasterCompanyId  and wo.CustomerId=@customerId and WOP.ItemMasterId = @ItemMasterID and WOP.WorkOrderScopeId = @WorkScope AND (ISNULL(WO.IsDeleted, 0) = @IsDeleted) and (@IsActive is null or WO.IsActive = @IsActive))
						), ResultCount AS(Select COUNT(WorkOrderId) AS totalItems FROM Result)
						SELECT * INTO #TempResult from  Result
						WHERE (
						(@GlobalFilter <>'' AND ((WorkOrderNum like '%' +@GlobalFilter+'%' ) OR 
								(WOType like '%' +@GlobalFilter+'%') OR
								(PartNo like '%' +@GlobalFilter+'%') OR					
								(PNDescription like '%' +@GlobalFilter+'%') OR
								(WorkScopeId like '%' +@GlobalFilter+'%') OR
								(CustomerName like '%' +@GlobalFilter+'%') OR
								(CreatedBy like '%' +@GlobalFilter+'%') OR
								(UpdatedBy like '%' +@GlobalFilter+'%') 
								))
								OR   
								(@GlobalFilter='' AND (IsNull(@WorkOrderNumber,'') ='' OR WorkOrderNum like '%' + @WorkOrderNumber+'%') and 
								(IsNull(@WOType,'') ='' OR WOType like '%' + @WOType+'%') and
								(IsNull(@PartNumber,'') ='' OR PartNo like '%' + @PartNumber+'%') and
								(IsNull(@PartDescription,'') ='' OR PNDescription like '%' + @PartDescription+'%') and
								(IsNull(@CustomerCode,'') ='' OR CustomerCode like '%' + @CustomerCode+'%') and
								(IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') and
								(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') and
								(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') and
								(IsNull(@OpenDate,'') ='' OR Cast(OpenDate as Date)=Cast(@OpenDate as date)) and
								(IsNull(@PromisedDate,'') ='' OR Cast(PromisedDate as Date)=Cast(@PromisedDate as date)) and
								(IsNull(@EstimatedCompletionDate,'') ='' OR Cast(EstimatedCompletionDate as Date)=Cast(@EstimatedCompletionDate as date)) and
								(IsNull(@EstimatedShipDate,'') ='' OR Cast(EstimatedShipDate as Date)=Cast(@EstimatedShipDate as date)) and
								(IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) and
								(IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)))
								)
						Select @Count = COUNT(WorkOrderId) from #TempResult			

						SELECT *, @Count As NumberOfItems FROM #TempResult
						ORDER BY  
						CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='WOTYPE')  THEN WOType END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PARTNO')  THEN PartNo END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PNDESCRIPTION')  THEN PNDescription END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERCODE')  THEN CustomerCode END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PROMISEDDATE')  THEN PromisedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='ESTIMATEDCOMPLETIONDATE')  THEN EstimatedCompletionDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='ESTIMATEDSHIPDATE')  THEN EstimatedShipDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='WOTYPE')  THEN WOType END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNO')  THEN PartNo END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PNDESCRIPTION')  THEN PNDescription END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERCODE')  THEN CustomerCode END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PROMISEDDATE')  THEN PromisedDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='ESTIMATEDCOMPLETIONDATE')  THEN EstimatedCompletionDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='ESTIMATEDSHIPDATE')  THEN EstimatedShipDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC
						OFFSET @RecordFrom ROWS
						FETCH NEXT @PageSize ROWS ONLY
					END
				ELSE
					BEGIN
					;With Result AS(
						SELECT	
								WO.WorkOrderId, 					
								WO.WorkOrderNum,
								CASE	
									WHEN WO.WorkOrderTypeId = 1 THEN 'Customer'
									WHEN WO.WorkOrderTypeId = 2 THEN 'Internal'
									WHEN WO.WorkOrderTypeId = 3 THEN 'Tear Down'
									ELSE 'Shop Services'
								END AS WOType,
								C.Name AS CustomerName,
								C.CustomerCode,
								WO.CustomerId,
								WO.OpenDate,
								WOP.PromisedDate,
								WOP.EstimatedCompletionDate,					
								WOP.EstimatedShipDate,					
								IM.PartNumber AS PartNo,
								IM.PartDescription AS PNDescription,
								WOP.WorkOrderScopeId AS WorkScopeId,
								WOP.ItemMasterId,
								WO.IsActive,
								WO.IsDeleted,
								WO.CreatedDate,
								WO.CreatedBy,
								WO.UpdatedDate,
								WO.UpdatedBy					
						FROM WorkOrder WO WITH (NOLOCK)
								INNER JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) on WO.WorkOrderId = WOP.WorkOrderId
								INNER JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) on WOP.ID = WOWF.WorkOrderPartNoId
								INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) on IM.ItemMasterId =  WOP.ItemMasterId
								INNER JOIN dbo.Customer C WITH (NOLOCK) on C.CustomerId = WO.CustomerId
						WHERE (WO.MasterCompanyId = @MasterCompanyId and WOP.ItemMasterId = @ItemMasterID and WOP.WorkOrderScopeId = @WorkScope AND (ISNULL(WO.IsDeleted, 0) = @IsDeleted) and (@IsActive is null or WO.IsActive = @IsActive))
						), ResultCount AS(Select COUNT(WorkOrderId) AS totalItems FROM Result)
						SELECT * INTO #TempResult1 from  Result
						WHERE (
						(@GlobalFilter <>'' AND ((WorkOrderNum like '%' +@GlobalFilter+'%' ) OR 
								(WOType like '%' +@GlobalFilter+'%') OR
								(PartNo like '%' +@GlobalFilter+'%') OR					
								(PNDescription like '%' +@GlobalFilter+'%') OR
								(WorkScopeId like '%' +@GlobalFilter+'%') OR
								(CustomerName like '%' +@GlobalFilter+'%') OR
								(CreatedBy like '%' +@GlobalFilter+'%') OR
								(UpdatedBy like '%' +@GlobalFilter+'%') 
								))
								OR   
								(@GlobalFilter='' AND (IsNull(@WorkOrderNumber,'') ='' OR WorkOrderNum like '%' + @WorkOrderNumber+'%') and 
								(IsNull(@WOType,'') ='' OR WOType like '%' + @WOType+'%') and
								(IsNull(@PartNumber,'') ='' OR PartNo like '%' + @PartNumber+'%') and
								(IsNull(@PartDescription,'') ='' OR PNDescription like '%' + @PartDescription+'%') and
								(IsNull(@CustomerCode,'') ='' OR CustomerCode like '%' + @CustomerCode+'%') and
								(IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') and
								(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') and
								(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') and
								(IsNull(@OpenDate,'') ='' OR Cast(OpenDate as Date)=Cast(@OpenDate as date)) and
								(IsNull(@PromisedDate,'') ='' OR Cast(PromisedDate as Date)=Cast(@PromisedDate as date)) and
								(IsNull(@EstimatedCompletionDate,'') ='' OR Cast(EstimatedCompletionDate as Date)=Cast(@EstimatedCompletionDate as date)) and
								(IsNull(@EstimatedShipDate,'') ='' OR Cast(EstimatedShipDate as Date)=Cast(@EstimatedShipDate as date)) and
								(IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) and
								(IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)))
								)
					
						SELECT @Count = COUNT(WorkOrderId) from #TempResult1			

						SELECT *, @Count As NumberOfItems FROM #TempResult1
						ORDER BY  
						CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='WOTYPE')  THEN WOType END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PARTNO')  THEN PartNo END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PNDESCRIPTION')  THEN PNDescription END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERCODE')  THEN CustomerCode END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PROMISEDDATE')  THEN PromisedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='ESTIMATEDCOMPLETIONDATE')  THEN EstimatedCompletionDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='ESTIMATEDSHIPDATE')  THEN EstimatedShipDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='WOTYPE')  THEN WOType END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNO')  THEN PartNo END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PNDESCRIPTION')  THEN PNDescription END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERCODE')  THEN CustomerCode END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PROMISEDDATE')  THEN PromisedDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='ESTIMATEDCOMPLETIONDATE')  THEN EstimatedCompletionDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='ESTIMATEDSHIPDATE')  THEN EstimatedShipDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC
						OFFSET @RecordFrom ROWS
						FETCH NEXT @PageSize ROWS ONLY
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
              , @AdhocComments     VARCHAR(150)    = 'GetHistoricalWorkOrderList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderNumber, '') + '''
													   @Parameter2 = '''+ ISNULL(@Count, '') + '''
													   @Parameter3 = '''+ ISNULL(@MasterCompanyId, '') + '''
													   @Parameter4 = ' + ISNULL(@CustomerName ,'') +''
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