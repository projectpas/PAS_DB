CREATE         PROCEDURE [dbo].[GetPNTileWorkOrderQuoteList]
@PageNumber int = 1,
@PageSize int = 10,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@StatusID int = 1,
@Status varchar(50) = 'Open',
@GlobalFilter varchar(50) = '',	
@PartNumber varchar(50) = NULL,	
@PartDescription varchar(max) = NULL,
@ManufacturerName varchar(max) = NULL,
@WorkOrderQuoteNumber varchar(50) = NULL,
@WorkOrderNum varchar(50) = NULL,
@WorkScope varchar(50) = NULL,
@CustomerName varchar(50) = NULL,
@CustomerReference varchar(50) = NULL,
@WorkOrderQuoteStatus varchar(50) = NULL,
@OpenDate datetime = NULL,
@IsDeleted bit = 0,
@EmployeeId bigint=0,
@ItemMasterId bigint=0,
@MasterCompanyId bigint=1,
@ConditionId VARCHAR(250) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		   
		DECLARE @RecordFrom int;
		DECLARE @Count Int;				
		SET @RecordFrom = (@PageNumber-1)*@PageSize;

		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=Upper('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=Upper(@SortColumn)
		END
		
		BEGIN TRY		
		BEGIN			
			;WITH Result AS(									
		   	 SELECT DISTINCT WOQ.[WorkOrderQuoteId],	
					WOQ.[WorkOrderId],
					IM.[PartNumber],
					IM.[PartDescription],
					WOQ.[QuoteNumber] AS [WorkOrderQuoteNumber],
					WO.[WorkOrderNum],
					WPN.[WorkScope],  
					CUST.[Name] AS [CustomerName],  		
					WPN.[CustomerReference], 
					WQS.[Description] AS [WorkOrderQuoteStatus],  				
					WOQ.[OpenDate],
					WOQ.[CustomerId],					
					WOQ.[IsDeleted],					
					WOQ.[CreatedDate],
				    WOQ.[CreatedBy],					
				    WOQ.[IsActive],
					ISNULL(IM.ManufacturerName,'')ManufacturerName
			   FROM [dbo].[WorkOrderQuote] WOQ WITH (NOLOCK)	
			   INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOQ.WorkOrderId = wo.WorkOrderId  
               INNER JOIN [dbo].[WorkOrderPartNumber] WPN WITH (NOLOCK) ON WOQ.WorkOrderId = WPN.WorkOrderId
			   INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON WPN.ItemMasterId = IM.ItemMasterId  
               INNER JOIN [dbo].[WorkOrderQuoteStatus] WQS WITH (NOLOCK) ON WOQ.QuoteStatusId = WQS.WorkOrderQuoteStatusId  
               INNER JOIN [dbo].[Customer] CUST WITH (NOLOCK) ON WOQ.CustomerId = CUST.CustomerId 				
			WHERE WOQ.MasterCompanyId = @MasterCompanyId	
			      AND WOQ.IsDeleted = 0
				  AND WOQ.IsActive = 1				  
				  AND WPN.ItemMasterId = @ItemMasterId	
				  AND (@ConditionId IS NULL OR WPN.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionId , ',')))
			), ResultCount AS(SELECT COUNT(WorkOrderQuoteId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartDescription LIKE '%' +@GlobalFilter+'%') OR
					(ManufacturerName LIKE '%' +@GlobalFilter+'%') OR
					(WorkOrderQuoteNumber LIKE '%' +@GlobalFilter+'%') OR	
					(WorkOrderNum LIKE '%' +@GlobalFilter+'%') OR	
					(WorkScope LIKE '%' +@GlobalFilter+'%') OR	
					(CustomerName LIKE '%' +@GlobalFilter+'%') OR						
					(CustomerReference LIKE '%' +@GlobalFilter+'%') OR
					(WorkOrderQuoteStatus LIKE '%' +@GlobalFilter+'%'))									
					OR   
					(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND 
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND
					(ISNULL(@WorkOrderQuoteNumber,'') ='' OR WorkOrderQuoteNumber LIKE '%' + @WorkOrderQuoteNumber + '%') AND
					(ISNULL(@WorkOrderNum,'') ='' OR WorkOrderNum LIKE '%' + @WorkOrderNum + '%') AND
					(ISNULL(@WorkScope,'') ='' OR WorkScope LIKE '%' + @WorkScope + '%') AND
					(ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName + '%') AND					
					(ISNULL(@CustomerReference,'') ='' OR CustomerReference LIKE '%' + @CustomerReference + '%') AND
					(ISNULL(@WorkOrderQuoteStatus,'') ='' OR WorkOrderQuoteStatus LIKE '%' + @WorkOrderQuoteStatus + '%') AND
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS DATE) = CAST(@OpenDate AS DATE)))))	 	
			SELECT @Count = COUNT(WorkOrderQuoteId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY 
			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='WorkOrderQuoteNumber')  THEN WorkOrderQuoteNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkOrderQuoteNumber')  THEN WorkOrderQuoteNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='WorkOrderNum')  THEN WorkOrderNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkOrderNum')  THEN WorkOrderNum END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='WorkScope')  THEN WorkScope END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkScope')  THEN WorkScope END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerReference')  THEN CustomerReference END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerReference')  THEN CustomerReference END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='WorkOrderQuoteStatus')  THEN WorkOrderQuoteStatus END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkOrderQuoteStatus')  THEN WorkOrderQuoteStatus END DESC,		
			CASE WHEN (@SortOrder=1  AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC
			
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
		
		END		
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPNTileWorkOrderQuoteList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
            RETURN(1);
	END CATCH
END