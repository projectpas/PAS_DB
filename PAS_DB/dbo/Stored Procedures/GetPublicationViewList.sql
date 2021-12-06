/*************************************************************           
 ** File:   [GetPublicationViewList]           
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
	2    09/24/2021   Deep Patel    Add multiple part view changes.....
     
EXECUTE [GetPublicationViewList] 1,100, null, -1, '', null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,0,null,null,4,4
**************************************************************/ 
CREATE PROCEDURE [dbo].[GetPublicationViewList]
	-- Add the parameters for the stored procedure here
	@PageNumber int=null,
	@PageSize int=null,
	@SortColumn varchar(50)=null,
	@SortOrder int=null,	
	@GlobalFilter varchar(50) = null,	
	@PublicationId varchar(50)=null,
	@Description varchar(50)=null,
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
	@AtaChapterName varchar(50)=null,
	@StatusID int=null,	
	@IsDeleted bit = null,	
	@CreatedBy varchar(50)=null,
	@UpdatedBy varchar(50)=null,
	@EmployeeId bigint=null,
    @MasterCompanyId bigint=null
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
			Set @IsDeleted = 0
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

		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN	

		;With Result AS(
				SELECT  pu.PublicationRecordId,
					    pu.PublicationId,
						pu.[Description],
						pt.[Name] AS PublicationType,
						pemp.ModuleName  AS PublishedBy,
						ISNULL(pu.RevisionDate,'')AS RevisionDate,
						pu.RevisionNum,
						ISNULL(pu.NextReviewDate,'') AS NextReviewDate,
					    ISNULL(pu.ExpirationDate,'') AS ExpirationDate,
						loc.[Name] AS [Location],
						e.FirstName AS VerifiedBy,
						ISNULL(pu.VerifiedDate,'') AS VerifiedDate,
						pu.CreatedDate,
					    pu.UpdatedDate,
					    pu.CreatedBy,
					    pu.UpdatedBy,
						pu.IsActive,
					    pu.IsDeleted
						--IsNull(A.PartNumber,'') AS PartNos,						
					    --IsNull(B.PartDescription,'') AS PnDescription						 				   
					   FROM Publication pu WITH (NOLOCK)
					   INNER JOIN  PublicationType pt WITH (NOLOCK) ON pU.PublicationTypeId = pt.PublicationTypeId
                        LEFT JOIN Employee e WITH (NOLOCK) ON pu.VerifiedBy = e.EmployeeId    
                        LEFT JOIN [Location] loc WITH (NOLOCK) ON pu.LocationId = loc.LocationId              
                        LEFT JOIN Module pemp WITH (NOLOCK) ON pu.PublishedById = pemp.ModuleId  
				 
				  WHERE pu.IsDeleted = 0 AND (@IsActive is null or pu.IsActive = @IsActive) AND pu.MasterCompanyId = @MasterCompanyId),
				  PartCTE AS(
						Select PC.PublicationRecordId,(Case When Count(PCI.PublicationRecordId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumberType',
						A.PartNumber from Publication PC WITH (NOLOCK)
						Left Join PublicationItemMasterMapping PCI WITH (NOLOCK) On PC.PublicationRecordId = PCI.PublicationRecordId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ',' + I.partnumber
									  FROM PublicationItemMasterMapping S WITH (NOLOCK)
									  Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
									  Where S.PublicationRecordId = PC.PublicationRecordId
									  AND S.IsActive = 1 AND S.IsDeleted = 0
									  FOR XML PATH('')), 1, 1, '') PartNumber
						) A
						Where ((PC.IsDeleted = @IsDeleted))
						AND PCI.IsActive = 1 AND PCI.IsDeleted = 0
						Group By PC.PublicationRecordId, A.PartNumber
						),
				
				  PartDescCTE AS(
						Select PC.PublicationRecordId, (Case When Count(PCI.PublicationRecordId) > 1 Then 'Multiple' ELse A.PartDescription End)  as 'PartDescriptionType',
						A.PartDescription from Publication PC WITH (NOLOCK)
						Left Join PublicationItemMasterMapping PCI WITH (NOLOCK) On PC.PublicationRecordId = PCI.PublicationRecordId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ', ' + I.PartDescription
									  FROM PublicationItemMasterMapping S WITH (NOLOCK)
									  Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
									  Where S.PublicationRecordId = PC.PublicationRecordId
									  AND S.IsActive = 1 AND S.IsDeleted = 0
									  FOR XML PATH('')), 1, 1, '') PartDescription
						) A
						Where ((PC.IsDeleted = @IsDeleted))
						AND PCI.IsActive = 1 AND PCI.IsDeleted = 0
						Group By PC.PublicationRecordId,A.PartDescription
						),Results AS(
						Select M.PublicationRecordId, PublicationId,M.[Description] as 'Description',
							   M.[PublicationType] as 'PublicationType', M.PublishedBy as 'PublishedBy',ISNULL(M.RevisionDate,'')AS RevisionDate,
							   M.RevisionNum as 'RevisionNum',ISNULL(M.NextReviewDate,'') AS NextReviewDate,
									ISNULL(M.ExpirationDate,'') AS ExpirationDate,[Location] as 'Location', VerifiedBy AS 'VerifiedBy', ISNULL(M.VerifiedDate,'') AS VerifiedDate,
									M.CreatedDate,M.UpdatedDate,M.CreatedBy,M.UpdatedBy,M.IsActive,M.IsDeleted, PT.PartNumber, PT.PartNumberType as 'PartNos',
									PD.PartDescription,PD.PartDescriptionType  as 'PnDescription'
									from Result M 
						Left Join PartCTE PT On M.PublicationRecordId = PT.PublicationRecordId
						Left Join PartDescCTE PD on PD.PublicationRecordId = M.PublicationRecordId),
				  ResultCount AS(Select COUNT(PublicationRecordId) AS totalItems FROM Results)
				  SELECT * INTO #TempResult FROM Results				  
				  WHERE ((@GlobalFilter <>'' AND  
				    ((PartNos LIKE '%' +@GlobalFilter+'%') OR
				    (PnDescription LIKE '%' +@GlobalFilter+'%') OR
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
					(@GlobalFilter='' AND
					(ISNULL(@PartNos,'') ='' OR PartNos LIKE '%' + @PartNos + '%') AND
					(ISNULL(@PnDescription,'') ='' OR PnDescription LIKE '%' + @PnDescription + '%') AND
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
              , @AdhocComments     VARCHAR(150)    = 'GetPublicationViewList' 
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