
CREATE     PROCEDURE [dbo].[GetItemMasterCapesList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@capabilityType varchar(50) = NULL,
@partNo varchar(50) = NULL,
@pnDiscription varchar(250) = NULL,
@ManufacturerName varchar(250) = NULL,
@level1 varchar(250) = NULL,
@level2 varchar(250) = NULL,
@level3 varchar(250) = NULL,
@level4 varchar(250) = NULL,
@addedDate datetime = NULL,
@isVerified varchar(50) = NULL,
@verifiedBy varchar(50) = NULL,
@verifiedDate datetime = NULL,
@memo varchar(250) = NULL,
@ItemMasterId bigint = NULL, 
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@isDeleted bit = NULL,
@MasterCompanyId bigint = NULL,
@EmployeeId BIGINT=NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		DECLARE @RecordFrom int;
		DECLARE @ModuleId int =8;
		DECLARE @Count Int;
		DECLARE @IsActive bit;
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
		IF @ItemMasterId=0
		BEGIN
			SET @ItemMasterId=NULL
		END

		;WITH Result AS(		
			SELECT DISTINCT imc.ItemMasterCapesId,
				(ISNULL(UPPER(imc.[PartNumber]),'')) 'partNo',
				(ISNULL(UPPER(imc.[PartDescription]),'')) 'pnDiscription',
				(ISNULL(UPPER(im.[ManufacturerName]),'')) 'ManufacturerName',
				(ISNULL(UPPER(imc.[CapabilityType]),'')) 'capabilityType',
				imc.CapabilityTypeId AS capabilityTypeId,
				--imc.IsVerified AS isVerified,
				CASE WHEN imc.IsVerified = 1 THEN 'Yes' ELSE 'No' END AS isVerified,
				(ISNULL(UPPER(imc.[VerifiedBy]),'')) 'verifiedBy',
				imc.VerifiedById AS 'verifiedById',
				imc.VerifiedDate AS 'verifiedDate',
				imc.[Memo] AS 'memo',
				imc.AddedDate AS 'addedDate',
				imc.CreatedDate AS 'createdDate',
				imc.UpdatedDate AS 'updatedDate',
				UPPER(imc.CreatedBy) AS 'createdBy',
				UPPER(imc.UpdatedBy) AS 'updatedBy',                               
				imc.IsActive AS  'isActive',
				imc.IsDeleted AS 'isDeleted',
				imc.ManagementStructureId AS 'ManagementStrId',
				imc.ItemMasterId AS 'ItemMasterId',                                
				--TotalRecords = totalRecords,                              
				(ISNULL(imc.[Level1],'')) 'level1',   
				(ISNULL(imc.[Level2],'')) 'level2', 
				(ISNULL(imc.[Level3],'')) 'level3', 
				(ISNULL(imc.[Level4],'')) 'level4'  ,
				MSD.LastMSLevel LastMSLevel,
				MSD.AllMSlevels AllMSlevels
			FROM dbo.ItemMasterCapes imc WITH (NOLOCK)
					INNER JOIN dbo.ItemMaster im WITH (NOLOCK) on imc.ItemMasterId = im.ItemMasterId
					INNER JOIN dbo.ItemMasterManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleId AND MSD.ReferenceID = imc.ItemMasterCapesId
	                INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON imc.ManagementStructureId = RMS.EntityStructureId
	                INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	

			WHERE ((imc.IsDeleted=@isDeleted) AND (@ItemMasterId IS NULL OR imc.ItemMasterId = @ItemMasterId))
				--AND (@VerifiedBy IS NULL OR imc.VerifiedBy IN (@VerifiedBy)))
				  AND imc.MasterCompanyId=@MasterCompanyId	AND EUR.EmployeeId = @EmployeeId
				
				), ResultCount AS(SELECT COUNT(ItemMasterCapesId) AS totalItems FROM Result)

				SELECT * INTO #TempResult FROM  Result
				WHERE ((@GlobalFilter <>'' AND ((capabilityType LIKE '%' +@GlobalFilter+'%') OR
			        (partNo LIKE '%' +@GlobalFilter+'%') OR	
					(pnDiscription LIKE '%' +@GlobalFilter+'%') OR	
					(ManufacturerName LIKE '%' +@GlobalFilter+'%') OR			
					(verifiedBy LIKE '%' +@GlobalFilter+'%') OR						
					(memo LIKE '%' +@GlobalFilter+'%') OR	
					(level1 LIKE '%' +@GlobalFilter+'%') OR	
					(level2 LIKE '%' +@GlobalFilter+'%') OR	
					(level3 LIKE '%' +@GlobalFilter+'%') OR	
					(level4 LIKE '%' +@GlobalFilter+'%') OR	
					(isVerified LIKE '%' +@GlobalFilter+'%') OR						
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%')))	
					OR
					(@GlobalFilter='' AND (ISNULL(@capabilityType,'') ='' OR capabilityType LIKE '%' + @capabilityType+'%') AND
					(ISNULL(@partNo,'') ='' OR partNo LIKE '%' + @partNo + '%') AND
					(ISNULL(@pnDiscription,'') ='' OR pnDiscription LIKE '%' + @pnDiscription + '%') AND
					(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND
					(ISNULL(@verifiedBy,'') ='' OR verifiedBy LIKE '%' + @verifiedBy + '%') AND
					(ISNULL(@memo,'') ='' OR memo LIKE '%' + @memo + '%') AND						
					(ISNULL(@level1,'') ='' OR level1 LIKE '%' + @level1 + '%') AND
					(ISNULL(@level2,'') ='' OR level2 LIKE '%' + @level2 + '%') AND
					(ISNULL(@level3,'') ='' OR level3 LIKE '%' + @level3 + '%') AND
					(ISNULL(@level4,'') ='' OR level4 LIKE '%' + @level4 + '%') AND	
					(ISNULL(@isVerified,'') ='' OR isVerified LIKE '%' + @isVerified + '%') AND	
					(ISNULL(@verifiedDate,'') ='' OR CAST(verifiedDate AS Date)=CAST(@verifiedDate AS date)) AND					
					(ISNULL(@addedDate,'') ='' OR CAST(addedDate AS Date)=CAST(@addedDate AS date)) AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )
				   SELECT @Count = COUNT(ItemMasterCapesId) FROM #TempResult			

				   SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY 				   
				   CASE WHEN (@SortOrder=1  AND @SortColumn='capabilityType')  THEN capabilityType END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='capabilityType')  THEN capabilityType END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='partNo')  THEN partNo END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='partNo')  THEN partNo END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='pnDiscription')  THEN pnDiscription END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='pnDiscription')  THEN pnDiscription END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='level1')  THEN level1 END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='level1')  THEN level1 END DESC,			
				   CASE WHEN (@SortOrder=1  AND @SortColumn='level2')  THEN level2 END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='level2')  THEN level2 END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='level3')  THEN level3 END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='level3')  THEN level3 END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='level4')  THEN level4 END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='level4')  THEN level4 END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='addedDate')  THEN addedDate END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='addedDate')  THEN addedDate END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='isVerified')  THEN isVerified END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='isVerified')  THEN isVerified END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='verifiedBy')  THEN verifiedBy END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='verifiedBy')  THEN verifiedBy END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='verifiedDate')  THEN verifiedDate END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='verifiedDate')  THEN verifiedDate END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='memo')  THEN memo END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='memo')  THEN memo END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='lastMSLevel')  THEN lastMSLevel END ASC,
				   CASE WHEN (@SortOrder=-1 AND @SortColumn='lastMSLevel')  THEN lastMSLevel END DESC

				   OFFSET @RecordFrom ROWS 
				   FETCH NEXT @PageSize ROWS ONLY

END TRY    
	BEGIN CATCH      
		--IF @@trancount > 0
			--PRINT 'ROLLBACK'
            --ROLLBACK TRANSACTION;
            -- temp table drop
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetItemMasterCapesList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@capabilityType, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@partNo, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@pnDiscription, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@level1 , '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@level2 , '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@level3, '') AS varchar(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@level4, '') AS varchar(100))	
			   + '@Parameter13 = ''' + CAST(ISNULL(@addedDate , '') AS varchar(100))	
			  + '@Parameter14 = ''' + CAST(ISNULL(@isVerified, '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@verifiedBy , '') AS varchar(100))	
			  + '@Parameter16 = ''' + CAST(ISNULL(@verifiedDate , '') AS varchar(100))	
			  + '@Parameter17 = ''' + CAST(ISNULL(@memo , '') AS varchar(100))
			  + '@Parameter18 = ''' + CAST(ISNULL(@ItemMasterId , '') AS varchar(100))
			  + '@Parameter19 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter20 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter21 = ''' + CAST(ISNULL(@UpdatedBy , '') AS varchar(100))
			  + '@Parameter22 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))			
			  + '@Parameter23 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))			 
			  + '@Parameter24 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END