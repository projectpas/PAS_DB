CREATE PROCEDURE [dbo].[GetVendorCapesList]
	-- Add the parameters for the stored procedure here
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter varchar(50) = null,
	@VendorCode varchar(50)=null,
	@VendorName varchar(50)=null,
	@CapabilityType varchar(50)=null,
	@PN varchar(50)=null,
	@PNDescription varchar(50)=null,
	@Ranking varchar(50)=null,
	@TAT varchar(50)=null,
	@Price varchar(50)=null,
	@Memo varchar(50)=null,
	@ItemMasterIds varchar(1000)=null,
	@CapabilityTypeIds varchar(1000)=null,
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
    @IsDeleted bit= null,	
	@MasterCompanyId bigint=NULL,
	@ConditionId int=null,
	@CostDate datetime=null
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @RecordFrom int;
		DECLARE @IsActive bit=1
		DECLARE @Count Int;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		Else
		BEGIN 
			SET @SortColumn=UPPER(@SortColumn)
		END
		IF @StatusID=0
		BEGIN 
			SET @IsActive=0
		END 
		ELSE IF @StatusID=1
		BEGIN 
			SET @IsActive=1
		END 
		ELSE IF @StatusID=2
		BEGIN 
			SET @IsActive=NULL
		END 

		IF(@Ranking=0 OR @Ranking='0')
		BEGIN 
			SET @Ranking = ''
		END 
		IF(@TAT=0 OR @TAT='0')
		BEGIN 
			SET @TAT=NULL
		END 
		IF(@Price=0 OR @Price='0')
		BEGIN 
			SET @Price=NULL
		END
		
		;WITH Result AS(
			SELECT	DISTINCT
					vc.VendorId, 
					vc.VendorCapabilityId,
					vc.CapabilityTypeId,
					v.VendorName,
					v.VendorCode,
					im.PartNumber,
					im.ItemMasterId,
					im.PartDescription,
					m.name AS ManufacturerName,
					vc.VendorRanking,
					ct.CapabilityTypeDesc AS CapabilityTypeName,
					vc.TAT,
					vc.Cost,
					vc.CostDate,
					vc.Memo,
					vc.IsActive,
					vc.IsDeleted,
					vc.CreatedDate,
					vc.CreatedBy,
					vc.UpdatedDate,
					vc.UpdatedBy
					,ct.ConditionId
					FROM dbo.VendorCapability vc  WITH (NOLOCK)
					INNER JOIN dbo.Vendor v  WITH (NOLOCK) ON v.VendorId = vc.VendorId
					LEFT JOIN dbo.ItemMaster im  WITH (NOLOCK) ON vc.ItemMasterId = im.ItemMasterId
					LEFT JOIN dbo.Manufacturer m  WITH (NOLOCK) ON im.ManufacturerId = m.ManufacturerId
					LEFT JOIN dbo.capabilityType ct  WITH (NOLOCK) ON vc.CapabilityTypeId = ct.CapabilityTypeId
					WHERE ((vc.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR vc.IsActive=@IsActive))
					    AND vc.MasterCompanyId = @MasterCompanyId
			), ResultCount AS(SELECT COUNT(VendorId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			WHERE (
			(@GlobalFilter <>'' AND ((VendorName LIKE '%' +@GlobalFilter+'%' ) OR 
					(VendorCode LIKE '%' +@GlobalFilter+'%') OR
					(CapabilityTypeName LIKE '%' +@GlobalFilter+'%') OR
					(PartNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartDescription LIKE '%' +@GlobalFilter+'%') OR
					(VendorRanking LIKE '%' +@GlobalFilter+'%') OR
					(TAT LIKE '%' +@GlobalFilter+'%') OR
					(Cost LIKE '%' +@GlobalFilter+'%') OR
					(Memo LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') 
					))
					OR   
					(@GlobalFilter='' AND (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName+'%') AND 
					(ISNULL(@VendorCode,'') ='' OR VendorCode LIKE '%' + @VendorCode+'%') AND
					(ISNULL(@CapabilityType,'') ='' OR CapabilityTypeName LIKE '%' + @CapabilityType+'%') AND
					(ISNULL(@PN,'') ='' OR partnumber LIKE '%' + @PN+'%') AND
					(ISNULL(@PNDescription,'') ='' OR PartDescription LIKE '%' + @PNDescription+'%') AND
					(ISNULL(@Ranking,'') ='' OR VendorRanking LIKE '%' + @Ranking+'%') AND
					(ISNULL(@TAT,'') ='' OR TAT LIKE '%' + @TAT+'%') AND
					(ISNULL(@Price,'') ='' OR Cost LIKE '%' + @Price+'%') AND
					(ISNULL(@Memo,'') ='' OR Memo LIKE '%' + @Memo+'%') AND
					(ISNULL(@ItemMasterIds,'') ='' OR ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@ItemMasterIds,','))) AND
					(ISNULL(@CapabilityTypeIds,'') ='' OR CapabilityTypeId IN (SELECT Item FROM DBO.SPLITSTRING(@CapabilityTypeIds,','))) and
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy+'%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy+'%') AND 
					--(ISNULL(@ConditionId,'') ='' OR CAST(ISNULL(ConditionId,'') as varchar) LIKE '%' + @ConditionId+'%') AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate as Date)=CAST(@CreatedDate as date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate as date)=CAST(@UpdatedDate as date)) AND
					(ISNULL(@CostDate,'') ='' OR CAST(CostDate as date)=CAST(@CostDate as date)))
					)

		SELECT @Count = COUNT(VendorId) from #TempResult			

		SELECT *, @Count AS NumberOfItems FROM #TempResult
		ORDER BY  
		CASE WHEN (@SortOrder=1 AND @SortColumn='VENDORCODE')  THEN VendorCode END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORCODE')  THEN VendorCode END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='VENDORNAME')  THEN VendorName END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORNAME')  THEN VendorName END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='PARTNUMBER')  THEN partnumber END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTNUMBER')  THEN partnumber END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='capabilityTypeName')  THEN CapabilityTypeName END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='capabilityTypeName')  THEN CapabilityTypeName END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='VENDORRANKING')  THEN VendorRanking END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORRANKING')  THEN VendorRanking END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='TAT')  THEN TAT END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='TAT')  THEN TAT END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='COST')  THEN Cost END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='COST')  THEN Cost END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='MEMO')  THEN Memo END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='MEMO')  THEN Memo END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
        CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='COSTDATE')  THEN CostDate END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='COSTDATE')  THEN CostDate END DESC
		OFFSET @RecordFrom ROWS 
		FETCH NEXT @PageSize ROWS ONLY		

		END TRY    
		BEGIN CATCH      
             DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetVendorCapesList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@StatusID, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))			  
			   + '@Parameter7 = ''' + CAST(ISNULL(@VendorCode, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@VendorName, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@CapabilityType, '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@PN, '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@PNDescription, '') AS varchar(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@Ranking, '') AS varchar(100))
			   + '@Parameter13 = ''' + CAST(ISNULL(@TAT, '') AS varchar(100))
			   + '@Parameter14 = ''' + CAST(ISNULL(@Price, '') AS varchar(100))
			   + '@Parameter15 = ''' + CAST(ISNULL(@Memo, '') AS varchar(100))
			   + '@Parameter16 = ''' + CAST(ISNULL(@ItemMasterIds, '') AS varchar(100))
			   + '@Parameter17 = ''' + CAST(ISNULL(@CapabilityTypeIds, '') AS varchar(100))
			  + '@Parameter18 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter19 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))
			  + '@Parameter20 = ''' + CAST(ISNULL(@CreatedBy  , '') AS varchar(100))
			  + '@Parameter21 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter22 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter23 = ''' + CAST(ISNULL(@masterCompanyID, '') AS varchar(100))  
			  + '@Parameter24 = ''' + CAST(ISNULL(@CostDate, '') AS varchar(100)) 
			  
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