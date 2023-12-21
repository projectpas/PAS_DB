/*************************************************************               
** File:   [OEMCrossReferenceList]              
** Author:   Seema Mansuri 
** Description: This procedre is used to display OEMCrossReferenceList
** Purpose:             
** Date:   19/12/2023  
**************************************************************               
** Change History               
**************************************************************               
** PR   Date         Author				Change Description                
** --   --------     -------			--------------------------------              
 1   19/12/2023		Seema Mansuri		Created  
 
**************************************************************/  
/*
exec OEMCrossReferenceList @PageNumber=1,@PageSize=10,@SortColumn=N'CreatedDate',@SortOrder=-1,@GlobalFilter=N'',@ItemMasterId=20372,@PartNumber=NULL,@PartDescription=NULL,@CreatedBy=NULL,@CreatedDate=NULL,@UpdatedBy=NULL,@UpdatedDate=NULL,@IsDeleted=0,@MasterCompanyId=1
*/
CREATE   PROCEDURE [dbo].[OEMCrossReferenceList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,

@IsDeleted bit = NULL,
@MasterCompanyId bigint = NULL,
@listtype varchar(50) = NULL,
@PartNumber varchar(50) = NULL,
@PartDescription varchar(50) = NULL,
@NhaPart varchar(50) = NULL,
@TlaPart varchar(50) = NULL,
@AlternatePart varchar(50) = NULL,
@EquivalentPart varchar(50) = NULL,
@Oemtype int = NULL

AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		DECLARE @AlternateType int =1;
		DECLARE @NHAType int =2;
		DECLARE @TLAType int =4;
		DECLARE @EquilentType int =3;
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;

		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END	
		ELSE
		BEGIN 
			Set @SortColumn=UPPER(@SortColumn)
		END
	

;WITH  ORMLIST_CTE
AS 
(
  SELECT itm.partnumber,itm.PartDescription,itm.ItemMasterId,
		alternate.partnumber as AlternatePart,	
		nha.partnumber as NhaPart,
		nha.PartDescription as NhaPartDescription,
		equivalent.partnumber as EquivalentPart,	
		tla.partnumber as TlaPart,	
	    mapping.MappingType as MappingType

FROM  [dbo].[Nha_Tla_Alt_Equ_ItemMapping]   mapping  WITH (NOLOCK)
LEFT JOIN [dbo].[ItemMaster] itm   WITH (NOLOCK) ON itm.ItemMasterId = mapping.ItemMasterId
LEFT JOIN [dbo].[ItemMaster] alternate  WITH (NOLOCK)  ON alternate.ItemMasterId = mapping.MappingItemMasterId and mapping.MappingType=@AlternateType
LEFT JOIN [dbo].[ItemMaster] nha   WITH (NOLOCK) ON nha.ItemMasterId = mapping.MappingItemMasterId and mapping.MappingType=@NHAType
LEFT JOIN [dbo].[ItemMaster] equivalent  WITH (NOLOCK) ON equivalent.ItemMasterId = mapping.MappingItemMasterId and mapping.MappingType=@EquilentType
LEFT JOIN [dbo].[ItemMaster] tla  WITH (NOLOCK) ON tla.ItemMasterId = mapping.MappingItemMasterId and mapping.MappingType=@TLAType
WHERE  mapping.MasterCompanyId = @MasterCompanyId  AND ((mapping.IsDeleted =0) AND (@IsActive IS NULL OR mapping.IsActive = 1))

AND (@Oemtype = 0 OR mapping.MappingType = @Oemtype) 
)	
SELECT   * INTO #TempResult FROM ORMLIST_CTE			
			 WHERE (	
			 (
			 @GlobalFilter <>'' AND 
			 (
					(PartNumber LIKE '%' +@GlobalFilter+'%') 
					OR
			        (PartDescription LIKE '%' +@GlobalFilter+'%') OR	
					(AlternatePart LIKE '%' +@GlobalFilter+'%') OR
				
					(NhaPart LIKE '%' +@GlobalFilter+'%') OR
					(NhaPartDescription LIKE '%' +@GlobalFilter+'%') OR
					(EquivalentPart LIKE '%' +@GlobalFilter+'%') OR
				
					(TlaPart LIKE '%' +@GlobalFilter+'%') 
					)
					)
					OR   
					(
					@GlobalFilter='' AND 
					(ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@NhaPart,'') ='' OR NhaPart LIKE '%' + @NhaPart + '%') AND
				
					(ISNULL(@TlaPart,'') ='' OR TlaPart LIKE '%' + @TlaPart + '%') AND
					
					(ISNULL(@EquivalentPart,'') ='' OR EquivalentPart LIKE '%' + @EquivalentPart + '%') AND
				
					(ISNULL(@AlternatePart,'') ='' OR AlternatePart LIKE '%' + @AlternatePart + '%') 				
					)			
			)
			SELECT @Count = COUNT(ItemMasterId) FROM #TempResult
			SELECT *, @Count AS NumberOfItems FROM #TempResult 
			ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AlternatePart')  THEN AlternatePart END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AlternatePart')  THEN AlternatePart END DESC,
		
			CASE WHEN (@SortOrder=1  AND @SortColumn='NhaPart')  THEN NhaPart END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NhaPart')  THEN NhaPart END DESC,
		
			CASE WHEN (@SortOrder=1  AND @SortColumn='EquivalentPart')  THEN EquivalentPart END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='EquivalentPart')  THEN EquivalentPart END DESC,
		
			CASE WHEN (@SortOrder=1  AND @SortColumn='TlaPart')  THEN TlaPart END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TlaPart')  THEN TlaPart END DESC
						
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
		END TRY
	BEGIN CATCH	
		     DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-------------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'OEMCrossReferenceList'
			,@ProcedureParameters VARCHAR(3000) = 
			     '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') as Varchar(100))
				 + ' @Parameter2 = ''' +  CAST(ISNULL(@PageSize, '') as Varchar(100))
				 + ' @Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') as Varchar(100))
				 + ' @Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') as Varchar(100))
				 + ' @Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') as Varchar(100))
				 + ' @Parameter8 = ''' + CAST(ISNULL(@PartNumber , '') as Varchar(100))
				 + ' @Parameter9 = ''' + CAST(ISNULL(@PartDescription, '') as Varchar(100))
				 + ' @Parameter21 = ''' + CAST(ISNULL(@IsDeleted, '') as Varchar(100))
				 + ' @Parameter22 = ''' + CAST(ISNULL(@MasterCompanyId, '') as Varchar(100))
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