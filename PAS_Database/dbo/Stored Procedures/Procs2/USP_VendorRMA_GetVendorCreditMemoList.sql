/*************************************************************             
 ** File:   [USP_VendorRMA_GetVendorCreditMemoList]            
 ** Author:   Shrey Chandegara
 ** Description: This stored procedure is used to listing screen of Vendor Credit Memo.  
 ** Purpose:           
 ** Date:   23/06/2023          
            
 ** PARAMETERS:  
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author             Change Description              
 ** --   --------     -------           --------------------------------            
    1    23/06/2023   Shrey Chandegara  Created  
	2    29/06/2023   Devendra Shekh    Added list filter by vendorRMAId  
	3    18/07/2023   Amit Ghediya		updated filter for status all not working. 
 
**************************************************************/  
CREATE     PROCEDURE [dbo].[USP_VendorRMA_GetVendorCreditMemoList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@VendorCreditMemoNumber varchar(50) = NULL,
@StatusId int = NULL,
@Status varchar(50)=NULL,
@RMANum varchar(50) = NULL,
@Vendor varchar(50) = NULL,
@PN varchar(100) = NULL,
@PNDescription varchar(50) = NULL,
@Currency varchar(50) = NULL,
@OriginalAmt DECIMAL(18,2)=NULL,
@ApplierdAmt DECIMAL(18,2)=NULL,
@RefundAmt DECIMAL(18,2)=NULL,
@RefundDate datetime = NULL,
@IsDeleted BIT = NULL,
@IsActive BIT = NULL,																	
@MasterCompanyId int = NULL,
@CreatedDate DATETIME=NULL,    
@UpdatedDate  datetime=NULL,    
@CreatedBy VARCHAR(50)=NULL,    
@UpdatedBy VARCHAR(50)=NULL,
@VendorRMAId BIGINT = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY

		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		
		DECLARE @CMSID Int;
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
		IF(@StatusId=1)
		BEGIN
			SET @IsActive=1;
		END
		ELSE
		BEGIN
			SET @IsActive=NULL;
		END

		IF(@Status =0)
		BEGIN
			SET @Status = NULL;
		END
		--SET @CMSID = (SELECT ID FROM CreditMemoStatus WHERE Description = 'open')

		IF @VendorRMAId IS NOT NULL
			BEGIN
				;WITH Result AS(
				SELECT DISTINCT
					   vcm.VendorCreditMemoId,
					   vrd.StockLineId,
					   vrd.ItemMasterId,
					   vcm.VendorRMAId,
					   vcm.VendorCreditMemoNumber,
					   vrd.RMANum as 'RMANum',
					   v.VendorName as 'Vendor',
					   im.partnumber as 'PN',
					   im.PartDescription as 'PNDescription',
					   c.Code as 'Currency',
					   vcmd.RefundDate,
                       vcm.IsActive,
                       vcm.IsDeleted,
					   vcm.CreatedDate,
                       vcm.UpdatedDate,
					   cms.[Name] as 'Status',
					   Upper(vcm.CreatedBy) CreatedBy,
                       Upper(vcm.UpdatedBy) UpdatedBy,
					   ISNULL(vcmd.OriginalAmt,0) as 'OriginalAmt',
					   ISNULL(vcmd.ApplierdAmt,0) as 'ApplierdAmt',
					   ISNULL(vcmd.RefundAmt,0) as 'RefundAmt'
			   FROM dbo.VendorCreditMemo vcm WITH (NOLOCK)
				LEFT JOIN dbo.[VendorCreditMemoDetail] vcmd WITH (NOLOCK) ON vcm.VendorCreditMemoId = vcmd.VendorCreditMemoId
				LEFT JOIN dbo.[VendorRMA] vr WITH (NOLOCK) ON vr.VendorRMAId = vcm.VendorRMAId
				LEFT JOIN dbo.[Vendor] v WITH (NOLOCK) ON v.VendorId = vr.VendorId
				--LEFT JOIN dbo.[VendorCreditMemoDetail] vcmdl WITH (NOLOCK) ON vcm.VendorCreditMemoId = vcmd.VendorCreditMemoId
				LEFT JOIN dbo.[VendorRMADetail] vrd WITH (NOLOCK) ON vcmd.VendorRMADetailId = vrd.VendorRMADetailId
				LEFT JOIN dbo.[ItemMaster] im WITH (NOLOCK) ON im.ItemMasterId = vrd.ItemMasterId
				LEFT JOIN dbo.[Currency] c WITH (NOLOCK) ON c.CurrencyId = vcm.CurrencyId									
				LEFT JOIN dbo.[CreditMemoStatus] cms WITH (NOLOCK) ON vcm.VendorCreditMemoStatusId = cms.Id

		 	  WHERE ((vcm.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR vcm.IsActive=@IsActive) AND (@Status IS NULL OR vcm.VendorCreditMemoStatusId=CAST(@Status AS INT)))		     
					AND vcm.MasterCompanyId=@MasterCompanyId	
					AND vcm.VendorRMAId = @VendorRMAId 
			), ResultCount AS(SELECT COUNT(VendorCreditMemoId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND (([VendorCreditMemoNumber] LIKE '%' +@GlobalFilter+'%') OR
			        (RMANum LIKE '%' +@GlobalFilter+'%') OR	
					(Vendor LIKE '%' +@GlobalFilter+'%') OR
					(PN LIKE '%' +@GlobalFilter+'%') OR
					(PNDescription LIKE '%' +@GlobalFilter+'%') OR
					(Currency LIKE '%' +@GlobalFilter+'%') OR
					(OriginalAmt LIKE '%' + @GlobalFilter + '%') OR
					(ApplierdAmt LIKE '%' + @GlobalFilter + '%') OR
					(RefundAmt LIKE '%' + @GlobalFilter + '%') OR
					(RefundDate like '%' + @GlobalFilter + '%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%'))) OR   
					(@GlobalFilter='' AND (ISNULL(@VendorCreditMemoNumber,'') ='' OR [VendorCreditMemoNumber] LIKE '%' + @VendorCreditMemoNumber+'%') AND
					(ISNULL(@RMANum,'') ='' OR RMANum LIKE '%' + @RMANum + '%') AND	
					(ISNULL(@Vendor,'') ='' OR Vendor LIKE '%' + @Vendor + '%') AND	
					(ISNULL(@PN,'') ='' OR PN LIKE '%' + @PN + '%') AND	
					(ISNULL(@PNDescription,'') ='' OR PNDescription LIKE '%' + @PNDescription + '%') AND
					(ISNULL(@Currency,'') ='' OR Currency LIKE '%' + @Currency + '%') AND
					(ISNULL(@OriginalAmt, 0) = 0 OR CAST(OriginalAmt as VARCHAR(50)) LIKE @OriginalAmt) AND
					(ISNULL(@ApplierdAmt, 0) = 0 OR CAST(ApplierdAmt as VARCHAR(50)) LIKE @ApplierdAmt) AND
					(ISNULL(@RefundAmt, 0) = 0 OR CAST(RefundAmt as VARCHAR(50)) LIKE @RefundAmt) AND
					(ISNULL(@RefundDate,'') ='' OR CAST(RefundDate AS Date) = CAST(@RefundDate AS Date)) AND	
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )

			SELECT @Count = COUNT(VendorCreditMemoId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorCreditMemoNumber')  THEN [VendorCreditMemoNumber] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCreditMemoNumber')  THEN [VendorCreditMemoNumber] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RMANum')  THEN RMANum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RMANum')  THEN RMANum END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Vendor')  THEN Vendor END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Vendor')  THEN Vendor END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PN')  THEN PN END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PN')  THEN PN END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PNDescription')  THEN PNDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PNDescription')  THEN PNDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Currency')  THEN Currency END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Currency')  THEN Currency END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='OriginalAmt')  THEN OriginalAmt END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OriginalAmt')  THEN OriginalAmt END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ApplierdAmt')  THEN ApplierdAmt END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ApplierdAmt')  THEN ApplierdAmt END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RefundAmt')  THEN RefundAmt END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RefundAmt')  THEN RefundAmt END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RefundDate')  THEN RefundDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RefundDate')  THEN RefundDate END DESC,
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
			END
		ELSE
			BEGIN
				;WITH Result AS(
				SELECT DISTINCT
					   vcm.VendorCreditMemoId,
					   CASE WHEN vcmd.StockLineId IS NOT NULL THEN vcmd.StockLineId
							ELSE vrd.StockLineId END AS 'StockLineId',
					   --vrd.StockLineId,
					    CASE WHEN vcmd.StockLineId IS NOT NULL THEN imd.ItemMasterId
							ELSE vrd.ItemMasterId END AS 'ItemMasterId',
					   --vrd.ItemMasterId,
					   vcm.VendorRMAId,
					   vcm.VendorCreditMemoNumber,
					   vrd.RMANum as 'RMANum',
					   CASE WHEN vcm.VendorId IS NOT NULL THEN ve.VendorName
							ELSE v.VendorName END AS 'Vendor',
					   --v.VendorName as 'Vendor',
					   CASE WHEN vcmd.StockLineId IS NOT NULL THEN imd.partnumber
							ELSE im.partnumber END AS 'PN',
					   --im.partnumber as 'PN',
					   CASE WHEN vcmd.StockLineId IS NOT NULL THEN imd.PartDescription
							ELSE im.PartDescription END AS 'PNDescription',
					   --im.PartDescription as 'PNDescription',
					   c.Code as 'Currency',
					   vcmd.RefundDate,
                       vcm.IsActive,
                       vcm.IsDeleted,
					   vcm.CreatedDate,
                       vcm.UpdatedDate,
					   cms.[Name] as 'Status',
					   Upper(vcm.CreatedBy) CreatedBy,
                       Upper(vcm.UpdatedBy) UpdatedBy,
					   ISNULL(vcmd.OriginalAmt,0) as 'OriginalAmt',
					   ISNULL(vcmd.ApplierdAmt,0) as 'ApplierdAmt',
					   ISNULL(vcmd.RefundAmt,0) as 'RefundAmt'
			   FROM dbo.VendorCreditMemo vcm WITH (NOLOCK)
				LEFT JOIN dbo.[VendorCreditMemoDetail] vcmd WITH (NOLOCK) ON vcm.VendorCreditMemoId = vcmd.VendorCreditMemoId
				LEFT JOIN dbo.[VendorRMA] vr WITH (NOLOCK) ON vr.VendorRMAId = vcm.VendorRMAId
				LEFT JOIN dbo.[Vendor] v WITH (NOLOCK) ON v.VendorId = vr.VendorId
				LEFT JOIN dbo.[Vendor] ve WITH (NOLOCK) ON vcm.VendorId = ve.VendorId
				LEFT JOIN dbo.[VendorRMADetail] vrd WITH (NOLOCK) ON vcmd.VendorRMADetailId = vrd.VendorRMADetailId
				LEFT JOIN dbo.[ItemMaster] im WITH (NOLOCK) ON im.ItemMasterId = vrd.ItemMasterId
				LEFT JOIN dbo.[Currency] c WITH (NOLOCK) ON c.CurrencyId = vcm.CurrencyId									
				LEFT JOIN dbo.[CreditMemoStatus] cms WITH (NOLOCK) ON vcm.VendorCreditMemoStatusId = cms.Id
				LEFT JOIN dbo.[Stockline] sl WITH (NOLOCK) ON sl.StockLineId = vcmd.StockLineId
				LEFT JOIN dbo.[ItemMaster] imd WITH (NOLOCK) ON sl.ItemMasterId = imd.ItemMasterId

		 	  WHERE ((vcm.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR vcm.IsActive=@IsActive) AND (@Status IS NULL OR vcm.VendorCreditMemoStatusId=CAST(@Status AS INT)))		     
					AND vcm.MasterCompanyId=@MasterCompanyId	
					--AND vcm.VendorRMAId = CASE 
					--		WHEN @VendorRMAId IS NOT NULL THEN  @VendorRMAId 
					--		ELSE vr.VendorRMAId END
			), ResultCount AS(SELECT COUNT(VendorCreditMemoId) AS totalItems FROM Result)
			SELECT * INTO #TempResultn FROM  Result
			 WHERE ((@GlobalFilter <>'' AND (([VendorCreditMemoNumber] LIKE '%' +@GlobalFilter+'%') OR
			        (RMANum LIKE '%' +@GlobalFilter+'%') OR	
					(Vendor LIKE '%' +@GlobalFilter+'%') OR
					(PN LIKE '%' +@GlobalFilter+'%') OR
					(PNDescription LIKE '%' +@GlobalFilter+'%') OR
					(Currency LIKE '%' +@GlobalFilter+'%') OR
					(OriginalAmt LIKE '%' + @GlobalFilter + '%') OR
					(ApplierdAmt LIKE '%' + @GlobalFilter + '%') OR
					(RefundAmt LIKE '%' + @GlobalFilter + '%') OR
					(RefundDate like '%' + @GlobalFilter + '%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%'))) OR   
					(@GlobalFilter='' AND (ISNULL(@VendorCreditMemoNumber,'') ='' OR [VendorCreditMemoNumber] LIKE '%' + @VendorCreditMemoNumber+'%') AND
					(ISNULL(@RMANum,'') ='' OR RMANum LIKE '%' + @RMANum + '%') AND	
					(ISNULL(@Vendor,'') ='' OR Vendor LIKE '%' + @Vendor + '%') AND	
					(ISNULL(@PN,'') ='' OR PN LIKE '%' + @PN + '%') AND	
					(ISNULL(@PNDescription,'') ='' OR PNDescription LIKE '%' + @PNDescription + '%') AND
					(ISNULL(@Currency,'') ='' OR Currency LIKE '%' + @Currency + '%') AND
					(ISNULL(@OriginalAmt, 0) = 0 OR CAST(OriginalAmt as VARCHAR(50)) LIKE @OriginalAmt) AND
					(ISNULL(@ApplierdAmt, 0) = 0 OR CAST(ApplierdAmt as VARCHAR(50)) LIKE @ApplierdAmt) AND
					(ISNULL(@RefundAmt, 0) = 0 OR CAST(RefundAmt as VARCHAR(50)) LIKE @RefundAmt) AND
					(ISNULL(@RefundDate,'') ='' OR CAST(RefundDate AS Date) = CAST(@RefundDate AS Date)) AND	
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )

			SELECT @Count = COUNT(VendorCreditMemoId) FROM #TempResultn			

			SELECT *, @Count AS NumberOfItems FROM #TempResultn ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorCreditMemoNumber')  THEN [VendorCreditMemoNumber] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCreditMemoNumber')  THEN [VendorCreditMemoNumber] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RMANum')  THEN RMANum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RMANum')  THEN RMANum END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Vendor')  THEN Vendor END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Vendor')  THEN Vendor END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PN')  THEN PN END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PN')  THEN PN END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PNDescription')  THEN PNDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PNDescription')  THEN PNDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Currency')  THEN Currency END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Currency')  THEN Currency END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='OriginalAmt')  THEN OriginalAmt END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OriginalAmt')  THEN OriginalAmt END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ApplierdAmt')  THEN ApplierdAmt END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ApplierdAmt')  THEN ApplierdAmt END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RefundAmt')  THEN RefundAmt END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RefundAmt')  THEN RefundAmt END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RefundDate')  THEN RefundDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RefundDate')  THEN RefundDate END DESC,
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
			END
		

	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'VendorCreditMemo'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@VendorCreditMemoNumber, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@RMANum, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@Vendor , '') AS varchar(100))		  
			   + '@Parameter10 = ''' + CAST(ISNULL(@PN , '') AS varchar(100))		  
			  + '@Parameter11 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter12 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@VendorRMAId, '') AS varchar(100))   			                                           
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