CREATE PROCEDURE [dbo].[ProcGetVendorRFQRoList]
	-- Add the parameters for the stored procedure here
	@PageNumber int=null,
	@PageSize int=null,
	@SortColumn varchar(50)=null,
	@SortOrder int=null,
	@StatusID int=null,
	@GlobalFilter varchar(50) = null,
	@VendorRFQRepairOrderNumber  varchar(50)=null,	
	@OpenDate datetime=null,
	@ClosedDate datetime=null,
	@VendorName varchar(50)=null,
	@VendorCode varchar(50)=null,
	@Status varchar(50)=null,	
	@RequestedBy varchar(50)=null,	
	@CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
    @IsDeleted bit = null,
	@EmployeeId bigint=null,
    @MasterCompanyId bigint=null,
	@VendorId bigint= null,
	@ViewType	varchar(10)=null
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		DECLARE @RecordFrom int;
		Declare @IsActive bit=1
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
		IF (@StatusID=6 AND @Status='All')
		BEGIN			
			SET @Status = ''
		END
		IF (@StatusID=6 OR @StatusID=0)
		BEGIN
			SET @StatusID = null			
		END	
	if @ViewType='pnview'
	BEGIN
	;With Result AS(
			SELECT DISTINCT 
			       RO.VendorRFQRepairOrderId,
			       RO.VendorRFQRepairOrderNumber,				  				   
			       RO.OpenDate,
				   RO.ClosedDate,
				   RO.CreatedDate,
				   RO.CreatedBy,
				   RO.UpdatedDate,
				   RO.UpdatedBy,
				   RO.IsActive,
				   RO.IsDeleted,
				   RO.VendorId,
				   RO.VendorName,
				   RO.VendorCode,
				   RO.StatusId,
				   RO.[Status],
				   RO.Requisitioner AS RequestedBy				  			   
			FROM  dbo.VendorRFQRepairOrder RO WITH (NOLOCK)
			 INNER JOIN  dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = RO.ManagementStructureId		              			  
			WHERE ((RO.IsDeleted=@IsDeleted) AND (@StatusID IS NULL OR RO.StatusId=@StatusID)) AND
			        EMS.EmployeeId = @EmployeeId AND RO.MasterCompanyId=@MasterCompanyId 
					 AND 
					 (@VendorId  IS NULL OR RO.VendorId=@VendorId)
					), ResultCount AS(Select COUNT(VendorRFQRepairOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			WHERE ((@GlobalFilter <>'' AND ((VendorRFQRepairOrderNumber LIKE '%' +@GlobalFilter+'%') OR	
			        (CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR	
					(VendorName LIKE '%' +@GlobalFilter+'%') OR	
					(VendorCode LIKE '%' +@GlobalFilter+'%') OR					
					(RequestedBy LIKE '%' +@GlobalFilter+'%') OR					
					([Status] LIKE '%' +@GlobalFilter+'%') ))
					OR 
					(@GlobalFilter='' AND IsDeleted=@IsDeleted AND
					(ISNULL(@VendorRFQRepairOrderNumber,'') ='' OR VendorRFQRepairOrderNumber LIKE '%' + @VendorRFQRepairOrderNumber +'%') AND 
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND					
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@VendorCode,'') ='' OR VendorCode LIKE '%' + @VendorCode + '%') AND
					(ISNULL(@RequestedBy,'') ='' OR RequestedBy LIKE '%' + @RequestedBy + '%') AND
					(ISNULL(@Status,'') ='' OR Status LIKE '%' + @Status + '%') AND									
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS Date) = CAST(@OpenDate AS date)) AND									
					(ISNULL(@ClosedDate,'') ='' OR CAST(ClosedDate AS Date) = CAST(@ClosedDate AS date)) AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )
				   SELECT @Count = COUNT(VendorRFQRepairOrderId) FROM #TempResult
				   SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
            CASE WHEN (@SortOrder=1 AND @SortColumn='VendorRFQRepairOrderNumber')  THEN VendorRFQRepairOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorRFQRepairOrderNumber')  THEN VendorRFQRepairOrderNumber END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='ClosedDate')  THEN ClosedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ClosedDate')  THEN ClosedDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='VendorCode')  THEN VendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCode')  THEN VendorCode END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='RequestedBy')  THEN RequestedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RequestedBy')  THEN RequestedBy END DESC,			          
			CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC

			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
	END
	END TRY    
	BEGIN CATCH      
		DECLARE @ErrorLogID INT
		,@DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'ProcGetVendorRFQRoList'
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			+ '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			+ '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			+ '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			+ '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			+ '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			+ '@Parameter7 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			+ '@Parameter8 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			+ '@Parameter9 = ''' + CAST(ISNULL(@UpdatedBy , '') AS varchar(100))
			+ '@Parameter10 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))			
			+ '@Parameter11 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			+ '@Parameter12 = ''' + CAST(ISNULL(@EmployeeId , '') AS varchar(100))
			+ '@Parameter13 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
		,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END