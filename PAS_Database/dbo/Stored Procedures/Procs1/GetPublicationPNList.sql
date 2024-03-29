﻿/*************************************************************           
 ** File:   [GetPublicationPNList]           
 ** Author:   Hemant Saliya
 ** Description: Get Search Data for Publication List    
 ** Purpose:         
 ** Date:   29-Dec-2020        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/29/2020   Hemant Saliya Created
     
 EXECUTE [GetPublicationPNList] 1,100, null, -1, 'testitem', null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,2,0,null,null,1,1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetPublicationPNList]	
@PageNumber int=NULL,
@PageSize int=NULL,
@SortColumn varchar(50)=null,
@SortOrder int=NULL,	
@GlobalFilter varchar(50) = NULL,	
@PublicationId  varchar(50)=null,
@Description  varchar(50)=null,
@PublicationType varchar(50)=null,
@PublishedBy varchar(50)=null,
@VerifiedBy varchar(50)=null,
@RevisionDate datetime=null,
@CreatedDate datetime=null,
@UpdatedDate  datetime=null,
@RevisionNum varchar(50)=null,
@NextReviewDate datetime=null,
@ExpirationDate datetime=null,
@Location varchar(50)=null,
@VerifiedDate datetime=null,
@PartNos varchar(50)=null,
@PnDescription varchar(50)=null,
@Manufacturers varchar(50)=null,
@AtaChapterName varchar(50)=null,
@StatusID int=NULL,	
@IsDeleted bit = NULL,	
@CreatedBy  varchar(50)=null,
@UpdatedBy  varchar(50)=null,
@EmployeeId bigint=NULL,
@MasterCompanyId bigint=NULL,
@ModuleID bigint=NULL
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		DECLARE @RecordFrom int;
		Declare @IsActive bit = 1
		DECLARE @Count Int;
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;
		IF @IsDeleted is null
		Begin
			Set @IsDeleted=0
		End	
		IF @SortColumn is null
		Begin
			Set @SortColumn = Upper('CreatedDate')
		End 
		Else
		Begin 
			Set @SortColumn = Upper(@SortColumn)
		End
		If @StatusID=0
		Begin 
			Set @IsActive = 0
		End 
		else IF @StatusID = 1
		Begin 
			Set @IsActive = 1
		End 
		else IF @StatusID = 2
		Begin 
			Set @IsActive = null
		End 

		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
	
		;With Result AS(
				SELECT distinct p.PublicationRecordId,
				       im.PartNumber AS PartNos,
					   im.PartDescription AS PnDescription,
					   MF.[Name] AS Manufacturers,
					   p.RevisionNum,
					   p.PublicationId,
					   p.[Description],
					   pt.[Name] AS PublicationType,
					   pemp.ModuleName AS PublishedBy,					   
					   p.RevisionDate AS RevisionDate,					   
					   p.NextReviewDate AS NextReviewDate,
					   p.ExpirationDate AS ExpirationDate,					   
					   loc.[Name] AS [Location],
					   e.FirstName AS VerifiedBy,
					   p.VerifiedDate AS VerifiedDate,					  
					   p.CreatedDate,
					   p.UpdatedDate,
					   p.CreatedBy,
					   p.UpdatedBy,
					   p.IsActive,
					   p.IsDeleted,
					   REPLACE(REPLACE(STUFF(
						(SELECT DISTINCT ', ' + t1.AllMSlevels
						 FROM [dbo].[PublicationManagementStructureDetails] t1 WITH (NOLOCK)
						 INNER JOIN [dbo].[Publication] t WITH (NOLOCK)
						    on t1.PublicationRecordId = t.PublicationRecordId 
						 where p.PublicationRecordId = t.PublicationRecordId 
						 FOR XML PATH ('')), 1, 1, ''),'&lt;p&gt;','<p>'),'&lt;/p&gt;','</p>') AllMSlevels,
						 STUFF(
						(SELECT DISTINCT ', ' + t1.LastMSLevel
						 FROM [dbo].[PublicationManagementStructureDetails] t1 WITH (NOLOCK)
						 INNER JOIN [dbo].[Publication] t WITH (NOLOCK)
						     ON t1.PublicationRecordId = t.PublicationRecordId 
						 WHERE p.PublicationRecordId = t.PublicationRecordId 
						 FOR XML PATH ('')), 1, 1, '') LastMSLevel
				  FROM [dbo].[Publication] p WITH (NOLOCK)
				  LEFT JOIN [dbo].[PublicationType] pt WITH (NOLOCK) ON p.PublicationTypeId = pt.PublicationTypeId
				  LEFT JOIN [dbo].[PublicationItemMasterMapping] pum WITH (NOLOCK) ON p.PublicationRecordId = pum.PublicationRecordId and isnull(pum.IsDeleted,0)=0
				  LEFT JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON pum.ItemMasterId = im.ItemMasterId
				  LEFT JOIN [dbo].[ItemMasterATAMapping] ima WITH (NOLOCK) ON pum.ItemMasterId = ima.ItemMasterId
				  LEFT JOIN [dbo].[Employee] e WITH (NOLOCK) ON p.VerifiedBy = e.EmployeeId
				  LEFT JOIN [dbo].[Location] loc WITH (NOLOCK) ON p.LocationId = loc.LocationId
				  LEFT JOIN [dbo].[Module] pemp WITH (NOLOCK) ON p.PublishedById = pemp.ModuleId 
				  LEFT JOIN [dbo].[Manufacturer] MF WITH (NOLOCK) ON im.ManufacturerId = MF.ManufacturerId
				  WHERE p.IsDeleted = @IsDeleted AND
				        (@IsActive is null or p.IsActive = @IsActive)  
						AND p.MasterCompanyId = @MasterCompanyId
				  ), ResultCount AS(Select COUNT(PublicationRecordId) AS totalItems FROM Result)
				  SELECT * INTO #TempResult FROM Result
				  
				  WHERE ((@GlobalFilter <>''
				     AND ((PartNos LIKE '%' +@GlobalFilter+'%') OR
				    (PnDescription LIKE '%' +@GlobalFilter+'%') OR
					(Manufacturers LIKE '%' +@GlobalFilter+'%') OR					
					(RevisionNum LIKE '%' +@GlobalFilter+'%') OR
				    (PublicationId LIKE '%' +@GlobalFilter+'%') OR
					([Description] LIKE '%' +@GlobalFilter+'%') OR	
					(PublicationType LIKE '%' +@GlobalFilter+'%') OR
					(PublishedBy LIKE '%' +@GlobalFilter+'%') OR
					([Location] LIKE '%' +@GlobalFilter+'%') OR					
					(VerifiedBy LIKE '%' +@GlobalFilter+'%') OR
			        (CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') 
					))
					OR 
					(@GlobalFilter=''  AND 			
					(ISNULL(@PartNos,'') ='' OR PartNos LIKE '%' + @PartNos + '%') AND
					(ISNULL(@PnDescription,'') ='' OR PnDescription LIKE '%' + @PnDescription + '%') AND
					(ISNULL(@Manufacturers,'') ='' OR Manufacturers LIKE '%' + @Manufacturers + '%') AND
					(ISNULL(@RevisionNum,'') ='' OR RevisionNum LIKE '%' + @RevisionNum + '%') AND
					(ISNULL(@PublicationId,'') ='' OR PublicationId LIKE '%' + @PublicationId+'%') AND 					
					(ISNULL(@Description,'') ='' OR [Description] LIKE '%' + @Description + '%') AND
					(ISNULL(@PublicationType,'') ='' OR PublicationType LIKE '%' + @PublicationType + '%') AND
					(ISNULL(@PublishedBy,'') ='' OR PublishedBy LIKE '%' + @PublishedBy + '%') AND
					(ISNULL(@RevisionDate,'') ='' OR CAST(RevisionDate AS Date) = CAST(@RevisionDate AS date)) AND					
					(ISNULL(@NextReviewDate,'') ='' OR CAST(NextReviewDate AS Date) = CAST(@NextReviewDate AS date)) AND
					(ISNULL(@ExpirationDate,'') ='' OR CAST(ExpirationDate AS Date) = CAST(@ExpirationDate AS date)) AND
					(ISNULL(@Location,'') ='' OR [Location] LIKE '%' + @Location + '%') AND					
					(ISNULL(@VerifiedBy,'') ='' OR VerifiedBy LIKE '%' + @VerifiedBy + '%') AND					
					(ISNULL(@VerifiedDate,'') ='' OR CAST(VerifiedDate AS Date) = CAST(@VerifiedDate AS date)) AND					
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))					
				   )
				   SELECT @Count = COUNT(PublicationRecordId) FROM #TempResult;		
			       SELECT *, @Count AS NumberOfItems FROM #TempResult
			       ORDER BY  
			       CASE WHEN (@SortOrder=1  AND @SortColumn='PartNos')  THEN PartNos END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNos')  THEN PartNos END DESC,
			       CASE WHEN (@SortOrder=1  AND @SortColumn='PnDescription')  THEN PnDescription END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='PnDescription')  THEN PnDescription END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturers')  THEN Manufacturers END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturers')  THEN Manufacturers END DESC,
			       CASE WHEN (@SortOrder=1  AND @SortColumn='RevisionNum')  THEN RevisionNum END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='RevisionNum')  THEN RevisionNum END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='PublicationId')  THEN PublicationId END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='PublicationId')  THEN PublicationId END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN [Description] END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='PublicationType')  THEN PublicationType END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='PublicationType')  THEN PublicationType END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='PublishedBy')  THEN PublishedBy END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='PublishedBy')  THEN PublishedBy END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='RevisionDate')  THEN RevisionDate END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='RevisionDate')  THEN RevisionDate END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='NextReviewDate')  THEN NextReviewDate END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='NextReviewDate')  THEN NextReviewDate END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='ExpirationDate')  THEN ExpirationDate END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate')  THEN ExpirationDate END DESC,				   
				   CASE WHEN (@SortOrder=1  AND @SortColumn='Location')  THEN [Location] END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='Location')  THEN [Location] END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='VerifiedBy')  THEN VerifiedBy END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='VerifiedBy')  THEN VerifiedBy END DESC,
				   CASE WHEN (@SortOrder=1  AND @SortColumn='VerifiedDate')  THEN VerifiedDate END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='VerifiedDate')  THEN VerifiedDate END DESC,
			       CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			       CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			       CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			       CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			       CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC
			       OFFSET @RecordFrom ROWS 
			       FETCH NEXT @PageSize ROWS ONLY

				   END

				  COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetPublicationPNList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PublicationId, '') + ''
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