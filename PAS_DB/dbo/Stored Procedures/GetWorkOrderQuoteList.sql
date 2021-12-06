/*************************************************************           
 ** File:   [GetWorkOrderQuoteList]           
 ** Author:   SUBHASH  Saliya
 ** Description: Get Search Data for WorkOrderQuoteList 
 ** Purpose:         
 ** Date:   15-march-2021        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    15/03/2021   SUBHASH Saliya Created
	2	 06/28/2021	  Hemant Saliya  Added Transation & Content Managment
	3	 07/27/2021	  Hemant Saliya  Added Master Company Id Filter
	4	 08/08/2021	  Hemant Saliya  Update Setting Table 
     
 EXECUTE [GetWorkOrderQuoteList] 1, 50, null, -1, 1, '', 'mpn', '','','','','','','','','all'
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetWorkOrderQuoteList]
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
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
	@MasterCompanyId varchar(200)=null,
	@quoteStatus varchar(200)=null,
	@VersionNo varchar(20)=null
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

				SET @RecordFrom = (@PageNumber-1)*@PageSize;

				IF (@GlobalFilter IS NULL OR @GlobalFilter = '')
				BEGIN
					SET @GlobalFilter= ''
				END 

				IF @SortColumn is null
				BEGIN
					Set @SortColumn=Upper('CreatedDate')
				END 
				Else
				BEGIN 
					Set @SortColumn=Upper(@SortColumn)
				END
				;WITH Result AS(
					    SELECT	
						     woq.WorkOrderQuoteId as WorkOrderQuoteId,
                             wo.WorkOrderId as WorkOrderId,
                             woq.QuoteNumber as quoteNumber,
                             wo.WorkOrderNum,
                             cust.Name as customerName,
                             cust.CustomerCode,
                             woq.OpenDate,
                             (SELECT TOP 1 wop.PromisedDate FROM dbo.WorkOrderPartNumber wop WITH(NOLOCK) WHERE  wo.WorkOrderId=wop.WorkOrderId ) as  promisedDate,
                             (SELECT TOP 1 wop.EstimatedShipDate FROM dbo.WorkOrderPartNumber wop WITH(NOLOCK) WHERE  wo.WorkOrderId=wop.WorkOrderId ) as estShipDate,
                             (SELECT TOP 1 wop.EstimatedCompletionDate FROM dbo.WorkOrderPartNumber wop WITH(NOLOCK) WHERE  wo.WorkOrderId=wop.WorkOrderId ) as estCompletionDate,
                             wqs.Description as quoteStatus,
                             woq.QuoteStatusId as quoteStatusId,
                             woq.IsActive,
                             woq.CreatedBy,
                             woq.CreatedDate,
                             woq.UpdatedBy,
                             woq.UpdatedDate,
							 woq.IsVersionIncrease,
							 woq.VersionNo
					FROM dbo.WorkOrderQuote woq WITH (NOLOCK)
                           JOIN dbo.WorkOrder wo WITH (NOLOCK) on woq.WorkOrderId = wo.WorkOrderId
                           JOIN dbo.WorkOrderQuoteStatus wqs WITH (NOLOCK) on woq.QuoteStatusId = wqs.WorkOrderQuoteStatusId
                           JOIN dbo.Customer cust WITH (NOLOCK) on woq.CustomerId = cust.CustomerId
                    WHERE woq.MasterCompanyId = @MasterCompanyId AND isnull(woq.IsDeleted,0) = 0 AND (@StatusId = 0 OR woq.QuoteStatusId = @StatusId)
					), ResultCount AS(SELECT COUNT(WorkOrderQuoteId) AS totalItems FROM Result)
						SELECT * INTO #TempResult FROM  Result
						WHERE (
						(@GlobalFilter <>'' AND (
						(quoteNumber like '%' +@GlobalFilter+'%') OR						
						(WorkOrderNum like '%' +@GlobalFilter+'%') OR
						(customerName like '%' +@GlobalFilter+'%') OR
						(CustomerCode like '%' +@GlobalFilter+'%') OR
						(VersionNo like '%' +@GlobalFilter+'%') OR
						(OpenDate like '%' +@GlobalFilter+'%') OR
						(promisedDate like '%' +@GlobalFilter+'%') OR
						(estShipDate like '%'+@GlobalFilter+'%') OR
					    (estCompletionDate like '%' +@GlobalFilter+'%' ) OR 
						(quoteStatus like '%' +@GlobalFilter+'%') OR
						(quoteStatusId like '%' +@GlobalFilter+'%') OR
						(CreatedBy like '%' +@GlobalFilter+'%') OR
							(quoteStatus like '%' +@GlobalFilter+'%') OR
						(UpdatedBy like '%' +@GlobalFilter+'%') 
						))
						OR   
						(@GlobalFilter='' AND (IsNull(@workOrderNum,'') ='' OR WorkOrderNum like '%' + @workOrderNum+'%') AND
						(IsNull(@quoteNumber,'') ='' OR quoteNumber like '%' + @quoteNumber+'%') AND
						(IsNull(@customerName,'') ='' OR customerName like '%' + @customerName+'%') AND
						(IsNull(@customerCode,'') ='' OR customerCode like '%' + @customerCode+'%') AND
						(IsNull(@VersionNo,'') ='' OR VersionNo like '%' + @VersionNo+'%') AND
						(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
						(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND
						(IsNull(@quoteStatus,'') ='' OR quoteStatus like '%' + @quoteStatus+'%') AND
						(IsNull(@StatusId,0) = 0 OR quoteStatusId = @StatusId) AND
						(IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) AND
						(IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) and
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
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERCODE')  THEN CustomerCode END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='VERSIONNO')  THEN VersionNo END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PROMISEDATE')  THEN PromisedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='ESTSHIPDATE')  THEN estShipDate END ASC,
				        CASE WHEN (@SortOrder=1 and @SortColumn='QUOTESTATUSID')  THEN quoteStatusId END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='QUOTESTATUS')  THEN quoteStatus END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='ESTCOMPLETIONDATE')  THEN estCompletionDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,

						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTENUMBER')  THEN quoteNumber END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERCODE')  THEN CustomerCode END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='VERSIONNO')  THEN VersionNo END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PROMISEDATE')  THEN PromisedDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='ESTSHIPDATE')  THEN estShipDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='ESTCOMPLETIONDATE')  THEN estCompletionDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTESTATUSID')  THEN quoteStatusId END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTESTATUS')  THEN quoteStatus END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC

						OFFSET @RecordFrom ROWS 
						FETCH NEXT @PageSize ROWS ONLY

						IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL
						BEGIN
						DROP TABLE #TempResult 
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
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderQuoteList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@quoteNumber, '') + ''
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