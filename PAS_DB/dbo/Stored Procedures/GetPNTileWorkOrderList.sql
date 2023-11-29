CREATE         PROCEDURE [dbo].[GetPNTileWorkOrderList]
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
@WorkOrderNum varchar(50) = NULL,
@WorkScope varchar(50) = NULL,
@CustomerName varchar(50) = NULL,
@SerialNumber varchar(50) = NULL,
@CustomerReference varchar(50) = NULL,
@WorkOrderStatus varchar(50) = NULL,
@ShipDate datetime = NULL,
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
		   	 SELECT DISTINCT WO.[WorkOrderId],					
					IM.[PartNumber],
					IM.[PartDescription],
					WO.[WorkOrderNum],
					WPN.[WorkScope],  
					WO.[CustomerName],  
					STL.[SerialNumber],  
					WPN.[CustomerReference], 
					WOS.[Description] AS [WorkOrderStatus],  				
					WOP.[ShipDate],
					WO.[CustomerId],					
					WO.[IsDeleted],					
					WO.[CreatedDate],
				    WO.[CreatedBy],					
				    WO.[IsActive],
					ISNULL(IM.ManufacturerName,'')ManufacturerName
			   FROM [dbo].[WorkOrder] WO WITH (NOLOCK)	
			   INNER JOIN [dbo].[WorkOrderPartNumber] WPN WITH(NOLOCK) ON WO.WorkOrderId = WPN.WorkOrderId  
			   INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId 
			   INNER JOIN [dbo].[WorkOrderStatus] WOS WITH(NOLOCK) ON WOS.Id = WPN.WorkOrderStatusId
			    LEFT JOIN [dbo].[Stockline] STL WITH(NOLOCK) ON WPN.StockLineId = STL.StockLineId
				LEFT JOIN [dbo].[WorkOrderShippingitem] WSI WITH(NOLOCK) ON WSI.WorkOrderPartNumId = WPN.ID
				LEFT JOIN [dbo].[WorkOrderShipping] WOP WITH(NOLOCK) ON WOP.WorkOrderShippingId = WSI.WorkOrderShippingId
				
			WHERE WO.MasterCompanyId = @MasterCompanyId	
			      AND WO.IsDeleted = 0
				  AND WO.IsActive = 1				  
				  AND WPN.ItemMasterId = @ItemMasterId	
				  AND (@ConditionId IS NULL OR WPN.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionId , ',')))
			), ResultCount AS(SELECT COUNT(WorkOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartDescription LIKE '%' +@GlobalFilter+'%') OR
					(ManufacturerName LIKE '%' +@GlobalFilter+'%') OR
					(WorkOrderNum LIKE '%' +@GlobalFilter+'%') OR	
					(WorkScope LIKE '%' +@GlobalFilter+'%') OR	
					(CustomerName LIKE '%' +@GlobalFilter+'%') OR	
					(SerialNumber LIKE '%' +@GlobalFilter+'%') OR	
					(CustomerReference LIKE '%' +@GlobalFilter+'%') OR
					(WorkOrderStatus LIKE '%' +@GlobalFilter+'%'))									
					OR   
					(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND 
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND
					(ISNULL(@WorkOrderNum,'') ='' OR WorkOrderNum LIKE '%' + @WorkOrderNum + '%') AND
					(ISNULL(@WorkScope,'') ='' OR WorkScope LIKE '%' + @WorkScope + '%') AND
					(ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName + '%') AND
					(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND
					(ISNULL(@CustomerReference,'') ='' OR CustomerReference LIKE '%' + @CustomerReference + '%') AND
					(ISNULL(@WorkOrderStatus,'') ='' OR WorkOrderStatus LIKE '%' + @WorkOrderStatus + '%') AND
					(ISNULL(@ShipDate,'') ='' OR CAST(ShipDate AS DATE) = CAST(@ShipDate AS DATE)))))	 	
			SELECT @Count = COUNT(WorkOrderId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY 
			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='WorkOrderNum')  THEN WorkOrderNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkOrderNum')  THEN WorkOrderNum END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='WorkScope')  THEN WorkScope END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkScope')  THEN WorkScope END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerReference')  THEN CustomerReference END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerReference')  THEN CustomerReference END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='WorkOrderStatus')  THEN WorkOrderStatus END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkOrderStatus')  THEN WorkOrderStatus END DESC,		
			CASE WHEN (@SortOrder=1  AND @SortColumn='ShipDate')  THEN ShipDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ShipDate')  THEN ShipDate END DESC,
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
            , @AdhocComments     VARCHAR(150)    = 'GetPNTileWorkOrderList' 
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