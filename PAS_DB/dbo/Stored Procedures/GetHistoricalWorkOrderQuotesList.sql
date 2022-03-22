/*************************************************************           
 ** File:   [GetHistoricalWorkOrderQuotesList]           
 ** Author:   Subhash  Saliya
 ** Description: Get Search Data for istoricalWorkOrderQuotesList 
 ** Purpose:         
 ** Date:   15-march-2021        
          
 ** PARAMETERS: @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    15/03/2021   SUBHASH Saliya Created

     
 EXECUTE [GetHistoricalWorkOrderQuotesList] 1, 50, null, -1, 1, '', 'mpn', '','','','','','','','','all'
 EXECUTE [GetHistoricalWorkOrderQuotesList] 1, 50, null, -1, 1, '', 'wp', '','','','','','','','','open'
 EXECUTE [GetHistoricalWorkOrderQuotesList] 1, 50, '', -1, 1, '', 'mpn', '','','','','','','','','open','','','','','','','','admin','admin',0,1,1
 EXECUTE [GetHistoricalWorkOrderQuotesList] 1, 50, null, -1, 1, null, 'wp', null,null,null,null,null,null,null,null,'open',null,null,null,null,null,null,null,'admin','admin',0,1,1
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetHistoricalWorkOrderQuotesList]
	-- Add the parameters for the stored procedure here
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@GlobalFilter varchar(50) = '',
	@quoteNumber varchar(50) = null,
	@workOrderNum varchar(50)=null,
	@customerName varchar(50)=null,
	@customerCode varchar(50)=null,
	@openDate datetime=null,
    @promiseDate datetime=null,
    @estCompletionDate datetime=null,
    @estShipDate datetime=null,
    @StatusId int=null,
    @ItemMasterId bigint =null,    
	@WorkScopeId bigint=null,
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
	@MasterCompanyId varchar(200)=null,
	@IsDeleted bit= null,
	@customerId int = null
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

				SET @RecordFrom = (@PageNumber - 1) * @PageSize;

				IF (@GlobalFilter IS NULL OR @GlobalFilter = '')
				BEGIN
					Set @GlobalFilter = ''
				END 

				IF @SortColumn is null
				BEGIN
					Set @SortColumn = Upper('CreatedDate')
				END 
				ELSE
				BEGIN 
					Set @SortColumn = Upper(@SortColumn)
				END

				IF(ISNULL(@customerId, 0) != 0)
					BEGIN
					;WITH Result AS(
					    SELECT	
						     woq.WorkOrderQuoteId as WorkOrderQuoteId,
                             wo.WorkOrderId as WorkOrderId,
                             woq.QuoteNumber as quoteNumber,
                             wo.WorkOrderNum,
                             cust.Name as customerName,
                             cust.CustomerCode,
                             woq.OpenDate,
                             wop.PromisedDate as  promisedDate,
                             wop.PromisedDate as estShipDate,
                             wop.EstimatedCompletionDate as estCompletionDate,
                             wqs.Description as quoteStatus,
                             woq.QuoteStatusId as quoteStatusId,
                             woq.IsActive,
                             woq.CreatedBy,
                             woq.CreatedDate,
                             woq.UpdatedBy,
                             woq.UpdatedDate,
                             wop.ItemMasterId,
                             wop.WorkOrderScopeId as WorkScopeId,
							 CASE WHEN wo.WorkOrderTypeId = 1 THEN 'Customer'  ELSE CASE WHEN wo.WorkOrderTypeId = 2 THEN 'Internal'  ELSE CASE WHEN  wo.WorkOrderTypeId = 3 THEN 'Tear Down'  ELSE 'Shop Services' END END END as woType
						FROM WorkOrderQuote woq
                           JOIN WorkOrder wo WITH(NOLOCK) on woq.WorkOrderId = wo.WorkOrderId
                           JOIN WorkOrderPartNumber wop WITH(NOLOCK) on woq.WorkOrderId = wop.WorkOrderId
                           JOIN WorkOrderStatus wqs WITH(NOLOCK) on woq.QuoteStatusId = wqs.Id
                           JOIN Customer cust WITH(NOLOCK) on woq.CustomerId = cust.CustomerId
						WHERE (WO.MasterCompanyId = @MasterCompanyId  and wo.CustomerId=@customerId and WOP.ItemMasterId = @ItemMasterID and WOP.WorkOrderScopeId = @WorkScopeId AND (ISNULL(WO.IsDeleted, 0) = @IsDeleted) and (@IsActive is null or WO.IsActive = @IsActive))
					), ResultCount AS(Select COUNT(WorkOrderQuoteId) AS totalItems FROM Result)
						SELECT * INTO #TempResult from  Result
						WHERE (
						(@GlobalFilter <>'' AND (
						(quoteNumber like '%' +@GlobalFilter+'%') OR
						(quoteNumber like '%' +@GlobalFilter+'%') OR
						(WorkOrderNum like '%' +@GlobalFilter+'%') OR
						(customerName like '%' +@GlobalFilter+'%') OR
						(CustomerCode like '%' +@GlobalFilter+'%') OR		
						(CustomerName like '%' +@GlobalFilter+'%' ) OR 
						(OpenDate like '%' +@GlobalFilter+'%') OR
						(promisedDate like '%' +@GlobalFilter+'%') OR
						(estShipDate like '%'+@GlobalFilter+'%') OR
					    (estCompletionDate like '%' +@GlobalFilter+'%' ) OR 
						(quoteStatus like '%' +@GlobalFilter+'%') OR
						(quoteStatusId like '%' +@GlobalFilter+'%') OR
						(woType like '%'+@GlobalFilter+'%') OR
						(CreatedBy like '%' +@GlobalFilter+'%') OR
						(UpdatedBy like '%' +@GlobalFilter+'%') 
						))
						OR   
						(@GlobalFilter='' AND (IsNull(@workOrderNum,'') ='' OR WorkOrderNum like '%' + @workOrderNum+'%') AND
						(IsNull(@quoteNumber,'') ='' OR quoteNumber like '%' + @quoteNumber+'%') AND
						(IsNull(@customerName,'') ='' OR customerName like '%' + @customerName+'%') AND
						(IsNull(@customerCode,'') ='' OR customerCode like '%' + @customerCode+'%') AND
						(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
						(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND
						(IsNull(@StatusId,0) =0  OR quoteStatusId = @StatusId) AND
						(IsNull(@OpenDate,'') ='' OR Cast(OpenDate as Date)=Cast(@OpenDate as date)) AND
						(IsNull(@estCompletionDate,'') ='' OR Cast(estCompletionDate as Date)=Cast(@estCompletionDate as date)) AND
						(IsNull(@promiseDate,'') ='' OR Cast(promisedDate as Date)=Cast(@promiseDate as date)) AND
						(IsNull(@EstShipDate,'') ='' OR Cast(estShipDate as Date)=Cast(@EstShipDate as date))
						))

						SELECT @Count = COUNT(WorkOrderQuoteId) from #TempResult			

						SELECT *, @Count As NumberOfItems FROM #TempResult
						ORDER BY  
						CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='QUOTENUMBER')  THEN quoteNumber END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERcODE')  THEN CustomerCode END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PROMISEDATE')  THEN PromisedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='ESTSHIPDATE')  THEN estShipDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='ESTCOMPLETIONDATE')  THEN estCompletionDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTENUMBER')  THEN quoteNumber END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERcODE')  THEN CustomerCode END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PROMISEDATE')  THEN PromisedDate END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='ESTSHIPDATE')  THEN estShipDate END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='ESTCOMPLETIONDATE')  THEN estCompletionDate END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC

						OFFSET @RecordFrom ROWS 
						FETCH NEXT @PageSize ROWS ONLY
						END
					ELSE
				BEGIN 
					;WITH Result AS(
					    SELECT	
						     woq.WorkOrderQuoteId as WorkOrderQuoteId,
                             wo.WorkOrderId as WorkOrderId,
                             woq.QuoteNumber as quoteNumber,
                             wo.WorkOrderNum,
                             cust.Name as customerName,
                             cust.CustomerCode,
                             woq.OpenDate,
                             wop.PromisedDate as  promisedDate,
                             wop.PromisedDate as estShipDate,
                             wop.EstimatedCompletionDate as estCompletionDate,
                             wqs.Description as quoteStatus,
                             woq.QuoteStatusId as quoteStatusId,
                             woq.IsActive,
                             woq.CreatedBy,
                             woq.CreatedDate,
                             woq.UpdatedBy,
                             woq.UpdatedDate,
                             wop.ItemMasterId,
                             wop.WorkOrderScopeId as WorkScopeId,
							 case when wo.WorkOrderTypeId = 1 then 'Customer'  else case when    wo.WorkOrderTypeId = 2 then 'Internal'  else case when  wo.WorkOrderTypeId = 3 then 'Tear Down'  else 'Shop Services' end end end as woType
					FROM   WorkOrderQuote woq
                           join WorkOrder wo on woq.WorkOrderId = wo.WorkOrderId
                           join WorkOrderPartNumber wop on woq.WorkOrderId = wop.WorkOrderId
                           join WorkOrderStatus wqs on woq.QuoteStatusId = wqs.Id
                           join Customer cust on woq.CustomerId = cust.CustomerId
                           Where (WO.MasterCompanyId = @MasterCompanyId and WOP.ItemMasterId = @ItemMasterID and WOP.WorkOrderScopeId = @WorkScopeId AND (ISNULL(WO.IsDeleted, 0) = @IsDeleted) and (@IsActive is null or WO.IsActive = @IsActive))
					), ResultCount AS(Select COUNT(WorkOrderQuoteId) AS totalItems FROM Result)
						Select * INTO #TempResult1 from  Result
						WHERE (
						(@GlobalFilter <> '' AND (
						(quoteNumber like '%' +@GlobalFilter+'%') OR
						(quoteNumber like '%' +@GlobalFilter+'%') OR
						(WorkOrderNum like '%' +@GlobalFilter+'%') OR
						(customerName like '%' +@GlobalFilter+'%') OR
						(CustomerCode like '%' +@GlobalFilter+'%') OR		
						(CustomerName like '%' +@GlobalFilter+'%' ) OR 
						(OpenDate like '%' +@GlobalFilter+'%') OR
						(promisedDate like '%' +@GlobalFilter+'%') OR
						(estShipDate like '%'+@GlobalFilter+'%') OR
					    (estCompletionDate like '%' +@GlobalFilter+'%' ) OR 
						(quoteStatus like '%' +@GlobalFilter+'%') OR
						(quoteStatusId like '%' +@GlobalFilter+'%') OR
						(woType like '%'+@GlobalFilter+'%') OR
						(CreatedBy like '%' +@GlobalFilter+'%') OR
						(UpdatedBy like '%' +@GlobalFilter+'%') 
						))
						OR   
						(@GlobalFilter='' AND (IsNull(@workOrderNum,'') ='' OR WorkOrderNum like '%' + @workOrderNum+'%') AND
						(IsNull(@quoteNumber,'') ='' OR quoteNumber like '%' + @quoteNumber+'%') AND
						(IsNull(@customerName,'') ='' OR customerName like '%' + @customerName+'%') AND
						(IsNull(@customerCode,'') ='' OR customerCode like '%' + @customerCode+'%') AND
						(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
						(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND
						(IsNull(@StatusId,0) =0  OR quoteStatusId = @StatusId) AND
						(IsNull(@OpenDate,'') ='' OR Cast(OpenDate as Date)=Cast(@OpenDate as date)) AND
						(IsNull(@estCompletionDate,'') ='' OR Cast(estCompletionDate as Date)=Cast(@estCompletionDate as date)) AND
						(IsNull(@promiseDate,'') ='' OR Cast(promisedDate as Date)=Cast(@promiseDate as date)) AND
						(IsNull(@EstShipDate,'') ='' OR Cast(estShipDate as Date)=Cast(@EstShipDate as date))
						))

						SELECT @Count = COUNT(WorkOrderQuoteId) from #TempResult1			

						SELECT *, @Count As NumberOfItems FROM #TempResult1
						ORDER BY  
						CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='QUOTENUMBER')  THEN quoteNumber END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERcODE')  THEN CustomerCode END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PROMISEDATE')  THEN PromisedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='ESTSHIPDATE')  THEN estShipDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='ESTCOMPLETIONDATE')  THEN estCompletionDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTENUMBER')  THEN quoteNumber END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERcODE')  THEN CustomerCode END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PROMISEDATE')  THEN PromisedDate END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='ESTSHIPDATE')  THEN estShipDate END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='ESTCOMPLETIONDATE')  THEN estCompletionDate END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC

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

-------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
          , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderQuoteVersion' 
          , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@quoteNumber, '') + '''
												   @Parameter2 = '''+ ISNULL(@customerName, '') + '''
												   @Parameter3 = '''+ ISNULL(@MasterCompanyId, '') + '''
												   @Parameter4 = ' + ISNULL(@customerCode ,'') +''
          , @ApplicationName VARCHAR(100) = 'PAS'
-------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

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