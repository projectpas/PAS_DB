/*************************************************************           
 ** File:   [GetPNTileKitPartList]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used get list of kit part
 ** Purpose:         
 ** Date:      08/21/2023 
          
 ** PARAMETERS:           
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
	1    08/21/2023   Devendra Shekh		  Created
	2    08/22/2023   Devendra Shekh		  few changes for filter

**************************************************************/
CREATE   PROCEDURE [dbo].[GetPNTileKitPartList]
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@GlobalFilter varchar(50) = '',	
	@KitNumber varchar(50) = NULL,
	@KitDescription varchar(max) = NULL,
	@Manufacturer varchar(50) = NULL,
	@Customer varchar(50) = NULL,	
	@Qty int = NULL,
	@KitCost varchar(50) = NULL,
	@Memo varchar(max) = NULL,
	@CreatedDate datetime = NULL,
	@CreatedBy varchar(50) = NULL,
	@UpdatedBy varchar(50) = NULL,
	@UpdatedDate  datetime = NULL,
	@IsDeleted bit = 0,
	@MasterCompanyId bigint = NULL,
	@ItemMasterId bigint = NULL,
	@conditionIds VARCHAR(250) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		   
		DECLARE @RecordFrom int;
		DECLARE @Count Int;		
		DECLARE @IsActive bit;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;

		print @RecordFrom

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
		print 1111
		BEGIN TRY		
		BEGIN			
			;WITH Result AS(
				SELECT DISTINCT
					  kitm.KitId,
					  kitm.KitNumber,
					  kitm.KitDescription,
					  kitm.ItemMasterId,
					  kitm.Manufacturer,
					  --kitm.CustomerId,
					  kitm.CustomerName AS Customer,
					  kitm.KitCost,
					  (SELECT ISNULL(COUNT(kimm.KitItemMasterMappingId),0) FROM [dbo].[KitItemMasterMapping] kimm WITH (NOLOCK) WHERE kimm.KitId = kitm.KitId AND kimm.IsDeleted = 0) AS Qty,
					  kitm.IsActive,
					  kitm.Memo,
					  kitm.CreatedDate,
                      kitm.UpdatedDate,
					  kitm.CreatedBy,
                      kitm.UpdatedBy,
					  kitm.IsDeleted,
					  kitm.MasterCompanyId
			   FROM [dbo].[KitMaster] kitm WITH (NOLOCK)
			   LEFT JOIN [dbo].[KitItemMasterMapping] wos WITH (NOLOCK) ON kitm.KitId=wos.KitId
		 	  WHERE ((kitm.IsDeleted = @IsDeleted) AND (kitm.IsActive = 1))			     
					AND kitm.MasterCompanyId = @MasterCompanyId AND (kitm.ItemMasterId = @ItemMasterId)
					AND (@conditionIds IS NULL OR wos.ConditionId IN(SELECT * FROM STRING_SPLIT(@conditionIds , ',')))
			), ResultCount AS(SELECT COUNT(KitId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((ISNULL(@GlobalFilter,'') <>'' AND (
			        (KitDescription LIKE '%' +@GlobalFilter+'%') OR	
					(Manufacturer LIKE '%' +@GlobalFilter+'%') OR
					(KitNumber LIKE '%' +@GlobalFilter+'%') OR
					(Qty LIKE '%' +@GlobalFilter+'%') OR
					(KitCost LIKE '%' +@GlobalFilter+'%') OR
					--(CAST(KitCost AS VARCHAR) LIKE '%' +@GlobalFilter+'%') OR
					(Memo LIKE '%' +@GlobalFilter+'%') OR
					(Customer LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%')))	
					OR   
				(ISNULL(@GlobalFilter,'')='' AND (ISNULL(@KitNumber,'') ='' OR KitNumber LIKE '%' + @KitNumber+'%') AND
					(ISNULL(@KitDescription,'') ='' OR KitDescription LIKE '%' + @KitDescription + '%') AND
					(ISNULL(@Manufacturer,'') ='' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND
					(ISNULL(@Customer,'') ='' OR Customer LIKE '%' + @Customer + '%') AND
					(IsNull(@Qty,'') ='' OR  Qty = @Qty) AND 
					--(IsNull(@KitCost,'') ='' OR  KitCost= @KitCost) AND 
					(ISNULL(@KitCost,'') ='' OR KitCost LIKE '%' + @KitCost + '%') AND
		            (IsNull(@Memo,'') ='' OR Memo LIKE '%' + @Memo + '%') AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE)=CAST(@CreatedDate AS DATE)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE)=CAST(@UpdatedDate AS DATE))
					))

			SELECT @Count = COUNT(ItemMasterId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='KitNumber')  THEN KitNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='KitNumber')  THEN KitNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='KitDescription')  THEN KitDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='KitDescription')  THEN KitDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Customer')  THEN Customer END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Customer')  THEN Customer END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Qty')  THEN Qty END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Qty')  THEN Qty END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='KitCost')  THEN KitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='KitCost')  THEN KitCost END DESC,
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
		END		
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPNTileKitPartList' 
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