/*************************************************************           
 ** File:   [USP_GetRepaireOrderAssemplyDetailsById]           
 ** Author:   BHARGAV SALIYA
 ** Description: This stored procedure is used to Ger Repair Order Sub Assembly Details List
 ** Purpose:         
 ** Date:   28 jul 2025 
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date             Author		         Change Description            
 ** --   --------         -------		     ----------------------------       
    1    28 jul 2025    BHARGAV SALIYA               Created
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetRepaireOrderAssemplyDetailsById]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StatusId int = NULL,
@Partnumber varchar(50) = NULL,
@PartDescription varchar(50) = null,
@VendorName varchar(256) = null,
@UnitCost varchar(256) = null,
@NeedByDate datetime = NULL,
@Quantity varchar(50) = NULL,
@Condition varchar(50) = NULL,
@IsAutoCreateRo varchar(50) = NULL,
@Provision varchar(50) = null,
@Memo nvarchar(MAX) = null,
@MasterCompanyId INT, 
@ItemMasterId  BIGINT, 
@MappingItemMasterId BIGINT,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = NULL,
@EmployeeId bigint
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY

		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description])
		FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId 
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId; 

		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=UPPER(@SortColumn)
		END	
		IF(@StatusId=0)
		BEGIN
			SET @IsActive=0;
		END
		ELSE IF(@StatusId=1)
		BEGIN
			SET @IsActive=1;
		END
		ELSE
		BEGIN
			SET @IsActive=NULL;
		END

			;WITH Result AS(
				SELECT DISTINCT
						RA.RepairOrderAssemblyId,
						IM.ItemMasterId,
						RA.MappingItemMasterId,
						IM.Partnumber,
						IMP.Partnumber AS AltPartNo,
						IMP.PartDescription,
						V.VendorName,
						RA.UnitCost,
						RA.NeedByDate,
						RA.Quantity,
						C.Description AS Condition,
						case when RA.IsAutoCreateRo = 1 then 'yes' else 'no' end as IsAutoCreateRo,
						PS.Description AS Provision,
						RA.Memo,
						(Cast(DBO.ConvertUTCtoLocal(RA.CreatedDate, @CurrntEmpTimeZoneDesc) as Date)) CreatedDate,
						(Cast(DBO.ConvertUTCtoLocal(RA.UpdatedDate, @CurrntEmpTimeZoneDesc) as Date)) UpdatedDate,
						Upper(RA.CreatedBy) AS CreatedBy,
						Upper(RA.UpdatedBy) AS UpdatedBy,
						RA.IsActive,
						RA.IsDeleted
				FROM [dbo].[RepairOrderAssembly] RA WITH (NOLOCK)
				INNER JOIN [dbo].[Vendor] V WITH (NOLOCK) ON RA.VendorId = V.VendorId
				INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = RA.ItemMasterId
				INNER JOIN [dbo].[ItemMaster] IMP WITH (NOLOCK) ON RA.MappingItemMasterId = IMP.ItemMasterId
				LEFT JOIN [dbo].[Condition] C WITH (NOLOCK) ON C.ConditionId = RA.ConditionId
				LEFT JOIN [dbo].[Provision] PS WITH (NOLOCK) ON PS.ProvisionId = RA.ProvisionId

				WHERE ((RA.IsDeleted=@IsDeleted)) AND RA.MasterCompanyId=@MasterCompanyId AND IM.ItemMasterId = @ItemMasterId
				
			), ResultCount AS(SELECT COUNT(RepairOrderAssemblyId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((Partnumber LIKE '%' +@GlobalFilter+'%') OR
			        (PartDescription LIKE '%' +@GlobalFilter+'%') OR	
					(VendorName LIKE '%' +@GlobalFilter+'%') OR
					(CAST(UnitCost AS VARCHAR) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(Quantity AS VARCHAR) LIKE '%' +@GlobalFilter+'%') OR
					(IsAutoCreateRo LIKE '%' +@GlobalFilter+'%') OR
					(Condition LIKE '%' +@GlobalFilter+'%') OR
					(Provision LIKE '%' +@GlobalFilter+'%') OR
					(Memo LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%'))) OR   
					(@GlobalFilter='' AND (ISNULL(@Partnumber,'') ='' OR Partnumber LIKE '%' + @Partnumber+'%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND	
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND	
					(ISNULL(@UnitCost,'') ='' OR UnitCost LIKE '%' + @UnitCost + '%') AND	
					(ISNULL(@NeedByDate,'') ='' OR CAST(NeedByDate AS Date)=CAST(@NeedByDate AS date)) AND
					(ISNULL(@Quantity,'') ='' OR CAST(Quantity AS VARCHAR) LIKE '%' + @Quantity + '%') AND	
					(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND
					(ISNULL(@IsAutoCreateRo,'') ='' OR IsAutoCreateRo LIKE '%' + @IsAutoCreateRo + '%') AND
					(ISNULL(@Provision,'') ='' OR Provision LIKE '%' + @Provision + '%') AND
					(ISNULL(@Memo,'') ='' OR Memo LIKE '%' + @Memo + '%') AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
					)

			SELECT @Count = COUNT(RepairOrderAssemblyId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='Partnumber')  THEN Partnumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Partnumber')  THEN Partnumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
		    CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='NeedByDate')  THEN NeedByDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NeedByDate')  THEN NeedByDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Quantity')  THEN Quantity END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Quantity')  THEN Quantity END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsAutoCreateRo')  THEN IsAutoCreateRo END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsAutoCreateRo')  THEN IsAutoCreateRo END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Provision')  THEN Provision END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Provision')  THEN Provision END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Memo')  THEN Memo END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Memo')  THEN Memo END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC			
			OFFSET @RecordFrom ROWS 
   			FETCH NEXT @PageSize ROWS ONLY
			
	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetRepaireOrderAssemplyDetailsById'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@Partnumber, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@PartDescription, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@VendorName, '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@UnitCost, '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@NeedByDate, '') AS varchar(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@Quantity, '') AS varchar(100))
			   + '@Parameter13 = ''' + CAST(ISNULL(@Condition , '') AS varchar(100))	
			   + '@Parameter14 = ''' + CAST(ISNULL(@IsAutoCreateRo , '') AS varchar(100))		  
			  + '@Parameter15 = ''' + CAST(ISNULL(@Provision, '') AS varchar(100))	                                           
			  + '@Parameter16 = ''' + CAST(ISNULL(@Memo, '') AS varchar(100))	                                           
			  + '@Parameter17 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))	                                           
			  + '@Parameter18 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter19 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter20 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter21 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))
			  + '@Parameter22 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)

		RETURN (1);           
	END CATCH
END