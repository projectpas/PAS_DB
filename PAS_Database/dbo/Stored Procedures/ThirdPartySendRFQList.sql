
/*************************************************************           
 ** File:   [ThirdPartySendRFQList]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Third Party Send RFQ List
 ** Date:   14/02/2024
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    14/02/2024   Rajesh Gami     Created
**************************************************************
**************************************************************/
CREATE   PROCEDURE [dbo].[ThirdPartySendRFQList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@IntegrationRFQStatusId int = NULL,
@Status varchar(50) = NULL,
@RFQId varchar(50) = NULL,
@PortalRFQId varchar(50) = NULL,
@Name varchar(100) = NULL,
@IntegrationRFQTypeId int =NULL,
@TypeName varchar(50) = NULL,
@IntegrationPortal varchar(50) = NULL,
@Priority varchar(50) = NULL,
@RequestedQty int = NULL,
@QuoteWithinDays int = NULL,
@DeliverByDate datetime2 = NULL,
@PreparedBy varchar(50) = NULL,
@PartNumber varchar(70) = NULL,
@AltPartNumber varchar(70) = NULL,
@Exchange varchar(70) = NULL,
@Description varchar(max) = NULL,
@Qty int = NULL,
@Condition varchar(20) = NULL,
@IsEmail bit = NULL,
@IsFax bit = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = NULL,
@MasterCompanyId bigint = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY

		DECLARE @RecordFrom int;		
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
		--IF(@IntegrationRFQStatusId=0)
		--BEGIN
		--	SET @IsActive=0;
		--END
		--ELSE IF(@IntegrationRFQStatusId=1)
		--BEGIN
		--	SET @IsActive=1;
		--END
		--ELSE
		--BEGIN
		--	SET @IsActive=NULL;
		--END
		SET @IsActive=1
		SET @IsDeleted =0
		IF(@IntegrationRFQStatusId=0)
		BEGIN
			SET @IntegrationRFQStatusId = NULL
		END
		IF(@IntegrationRFQStatusId=0 AND @Status = 'All')
		BEGIN
			SET @Status = NULL
		END
		IF(@IntegrationRFQTypeId = 0)
		BEGIN
			SET @IntegrationRFQTypeId = NULL;
		END
		print @IntegrationRFQTypeId
		print @IntegrationRFQStatusId
		;WITH Result AS(
				SELECT DISTINCT
					   part.ILSRFQPartId ILSRFQPartId,
					   tr.ThirdPartyRFQId,
					   ird.ILSRFQDetailId,
					   tr.RFQId,
					   tr.PortalRFQId,
					   tr.[Name] AS Name,
					   tr.IntegrationRFQTypeId IntegrationRFQTypeId,
					   tr.TypeName,
					   tr.IntegrationPortalId IntegrationPortalId,
					   tr.IntegrationPortal,
					   tr.IntegrationRFQStatusId IntegrationRFQStatusId,
					   tr.Status Status,
					   ISNULL(ird.PriorityId,0) PriorityId,
					   ird.Priority,
					   ISNULL(part.RequestedQty,0) RequestedQty,
					   ird.QuoteWithinDays QuoteWithinDays,
					   ird.DeliverByDate DeliverByDate,
					   ird.PreparedBy,
					   ISNULL(ird.AttachmentId,0) AttachmentId,
					   ird.DeliverToAddress,
					   ird.BuyerComment,					   
					   part.PartNumber,
					   part.AltPartNumber,
					   part.Exchange,
					   part.Description,
					   ISNULL(part.Qty,0) Qty,
					   part.Condition,
					   ISNULL(part.IsEmail,0) IsEmail,
					   ISNULL(part.IsFax,0) IsFax,
                       ISNULL(part.IsActive,0) IsActive,
                       ISNULL(part.IsDeleted,0) IsDeleted,
					   part.CreatedDate,
                       part.UpdatedDate,
					   Upper(part.CreatedBy) CreatedBy,
                       Upper(part.UpdatedBy) UpdatedBy
			   FROM Dbo.ILSRFQPart part WITH(NOLOCK)
					INNER JOIN Dbo.ILSRFQDetail ird WITH(NOLOCK) on part.ILSRFQDetailId = ird.ILSRFQDetailId
					INNER JOIN Dbo.ThirdPartyRFQ tr WITH(NOLOCK)  on ird.ThirdPartyRFQId = tr.ThirdPartyRFQId

		 	  WHERE 
					((ISNULL(part.IsDeleted,0)= 0) ) AND 			     
					part.MasterCompanyId=@MasterCompanyId 
					AND (@IntegrationRFQTypeId IS NULL OR tr.IntegrationRFQTypeId = @IntegrationRFQTypeId)
					AND (@IntegrationRFQStatusId IS NULL OR tr.IntegrationRFQStatusId = @IntegrationRFQStatusId)
			), ResultCount AS(SELECT COUNT(ILSRFQPartId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND (([RFQId] LIKE '%' +@GlobalFilter+'%') OR
			        (PortalRFQId LIKE '%' +@GlobalFilter+'%') OR	
					(Name LIKE '%' +@GlobalFilter+'%') OR
					(TypeName LIKE '%' +@GlobalFilter+'%') OR
					(IntegrationPortal LIKE '%' +@GlobalFilter+'%') OR
					(Status LIKE '%' +@GlobalFilter+'%') OR
					(CAST(QuoteWithinDays AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(DeliverByDate LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR   
					(PartNumber LIKE '%' +@GlobalFilter+'%') OR   
					(AltPartNumber LIKE '%' +@GlobalFilter+'%') OR   
					(Exchange LIKE '%' +@GlobalFilter+'%') OR   
					(Description LIKE '%' +@GlobalFilter+'%') OR   
					(CAST(Qty AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR   
					(Condition LIKE '%' +@GlobalFilter+'%') OR   
					(IsEmail LIKE '%' +@GlobalFilter+'%') OR   
					(IsFax LIKE '%' +@GlobalFilter+'%') OR
					(CreatedDate like '%' + @GlobalFilter + '%') OR
					(UpdatedDate like '%' + @GlobalFilter + '%'))) OR   
					(@GlobalFilter='' AND (ISNULL(@RFQId,'') ='' OR [RFQId] LIKE '%' + @RFQId+'%') AND
					(ISNULL(@PortalRFQId,'') ='' OR PortalRFQId LIKE '%' + @PortalRFQId + '%') AND	
					(ISNULL(@Name,'') ='' OR Name LIKE '%' + @Name + '%') AND	
					(ISNULL(@TypeName,'') ='' OR TypeName LIKE '%' + @TypeName + '%') AND
					(ISNULL(@IntegrationPortal,'') ='' OR IntegrationPortal LIKE '%' + @IntegrationPortal + '%') AND	
					(ISNULL(@Status,'') ='' OR Status LIKE '%' + @Status + '%') AND	
					(ISNULL(@DeliverByDate,'') ='' OR CAST(DeliverByDate AS Date)=CAST(@DeliverByDate AS date)) AND
					(ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber + '%') AND	
					(ISNULL(@AltPartNumber,'') ='' OR AltPartNumber LIKE '%' + @AltPartNumber + '%') AND	
					(ISNULL(@Description,'') ='' OR Description LIKE '%' + @Description + '%') AND	
					(ISNULL(@Exchange,'') ='' OR Exchange LIKE '%' + @Exchange + '%') AND	
					(ISNULL(@Qty, 0) = 0 OR CAST(Qty as VARCHAR(10)) = @Qty) AND
					(ISNULL(@RequestedQty, 0) = 0 OR CAST(RequestedQty as VARCHAR(10)) = @RequestedQty) AND
					(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND	
					(ISNULL(@IsEmail,0) ='' OR CAST(IsEmail as bit) = @IsEmail) AND	
					(ISNULL(@IsFax,0) ='' OR CAST(IsFax as bit) = @IsFax) AND		
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )

			SELECT @Count = COUNT(ILSRFQPartId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='RFQId')  THEN [RFQId] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RFQId')  THEN [RFQId] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PortalRFQId')  THEN PortalRFQId END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PortalRFQId')  THEN PortalRFQId END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Name')  THEN [Name] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Name')  THEN [Name] END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='TypeName')  THEN TypeName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TypeName')  THEN TypeName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='IntegrationPortal')  THEN IntegrationPortal END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IntegrationPortal')  THEN IntegrationPortal END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Status')  THEN [Status] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Status')  THEN [Status] END DESC,

			CASE WHEN (@SortOrder=1  AND @SortColumn='Priority')  THEN [Priority] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Priority')  THEN [Priority] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='DeliverByDate')  THEN DeliverByDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DeliverByDate')  THEN DeliverByDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AltPartNumber')  THEN AltPartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AltPartNumber')  THEN AltPartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Exchange')  THEN Exchange END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Exchange')  THEN Exchange END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN [Description] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Qty')  THEN Qty END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Qty')  THEN Qty END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsEmail')  THEN IsEmail END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsEmail')  THEN IsEmail END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsFax')  THEN IsFax END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsFax')  THEN IsFax END DESC,

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
			,@AdhocComments VARCHAR(150) = 'ThirdPartySendRFQList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@IntegrationRFQStatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@Name, '') AS varchar(100))
			  + '@Parameter12 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
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