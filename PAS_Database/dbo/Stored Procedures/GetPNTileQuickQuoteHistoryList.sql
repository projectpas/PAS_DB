-- ==================================================
-- Author:		Ekta Chandegra
-- Create date: 08-AUG-2024
-- Description:	Get Search Data for Quick Quote History List
-- ==================================================
CREATE   PROCEDURE [DBO].[GetPNTileQuickQuoteHistoryList]
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@GlobalFilter varchar(50) = '',	
	@PartNumber varchar(100) = NULL,	
	@PartDescription varchar(max) = NULL,
	@ManufacturerName varchar(250) = NULL,
	@WorkScope varchar(50) = NULL,
	@Condition varchar(100) = NULL,
	@CreatedDate datetime = NULL,
	@TAT int = NULL,
	@UnitSalePrice decimal(18, 4) = NULL,
	@CurrencyName varchar(100) = NULL,
	@CustomerReference varchar(100)= NULL,
	@SalesPersonName varchar(200) = NULL,
	@IsDeleted bit = 0,
	@ItemMasterId bigint=0,
	@MasterCompanyId int = 1,
	@SpeedQuoteNumber varchar(50) = NULL,
	@ConditionIds varchar(max) = NULL

AS 
BEGIN 
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		   
	DECLARE @RecordFrom int;
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
		ELSE
		BEGIN 
			SET @SortColumn=UPPER(@SortColumn)
		END

		IF @TAT=0
		BEGIN
			SET @TAT=NULL
		END

		BEGIN TRY		
		BEGIN			
			;WITH Result AS(
			SELECT DISTINCT
			SOQ.SpeedQuoteId,
			SOQP.SpeedQuotePartId,
			SOQP.PartNumber,
			SOQP.PartDescription,
			ISNULL(IM.ManufacturerName,'')ManufacturerName,
			WPN.WorkScope,
			SOQ.SpeedQuoteNumber,
			Cond.ConditionId,
			Cond.Code AS [Condition],
			SOQ.CreatedDate,
			SOQP.TAT,
			SOQP.UnitSalePrice,
			SOQP.CurrencyId,
			SOQP.CurrencyName,
			SOQ.CustomerReference,
			SOQ.SalesPersonId,
			SOQ.SalesPersonName,
			IM.ItemMasterId,
			IM.MasterCompanyId,
			SOQ.IsActive,
			SOQ.IsDeleted
			FROM [DBO].[SpeedQuote] SOQ WITH (NOLOCK)
			LEFT JOIN [DBO].[SpeedQuotePart] SOQP WITH (NOLOCK) ON SOQP.SpeedQuoteId = SOQ.SpeedQuoteId
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = SOQP.ItemMasterId
			LEFT JOIN [DBO].WorkOrderPartNumber WPN WITH (NOLOCK) ON WPN.ItemMasterId = IM.ItemMasterId
			LEFT JOIN [DBO].[Condition] Cond WITH (NOLOCK) ON Cond.ConditionId = SOQP.ConditionId
			LEFT JOIN [DBO].[Status] St WITH (NOLOCK) ON St.SatusId = SOQP.StatusId 
			WHERE SOQ.MasterCompanyId = @MasterCompanyId 
			AND SOQ.IsDeleted = 0 
			AND SOQ.IsActive = 1 
			AND SOQP.ItemMasterId = @ItemMasterId 
			AND (@ConditionIds IS NULL OR SOQP.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionIds , ',')))
			),ResultCount AS (SELECT COUNT(SpeedQuoteId) AS totalItems FROM Result) 
			SELECT * INTO #TempResult FROM Result
			WHERE ((@GlobalFilter <> '' AND ((PartNumber LIKE '%' + @GlobalFilter + '%') OR
					(PartDescription LIKE '%' +@GlobalFilter + '%') OR
					(ManufacturerName LIKE '%' +@GlobalFilter + '%') OR
					(WorkScope LIKE '%' +@GlobalFilter + '%') OR
					(SpeedQuoteNumber LIKE '%' +@GlobalFilter + '%') OR
					(Condition LIKE '%' +@GlobalFilter + '%') OR
					(CreatedDate LIKE '%' +@GlobalFilter + '%') OR
					(TAT LIKE '%' +@GlobalFilter + '%') OR
					(UnitSalePrice LIKE '%' +@GlobalFilter + '%') OR
					(CurrencyName LIKE '%' +@GlobalFilter + '%') OR
					(CustomerReference LIKE '%' +@GlobalFilter + '%') OR
					(SalesPersonName LIKE '%' +@GlobalFilter + '%'))
					OR
					(@GlobalFilter='' AND (ISNULL(@PartNumber,'') = '' OR PartNumber LIKE '%' + @PartNumber + '%')AND
					(ISNULL(@PartDescription,'') = '' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@ManufacturerName,'') = '' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND
					(ISNULL(@WorkScope,'') = '' OR WorkScope LIKE '%' + @WorkScope + '%') AND
					(ISNULL(@SpeedQuoteNumber,'') = '' OR SpeedQuoteNumber LIKE '%' + @SpeedQuoteNumber + '%') AND
					(ISNULL(@Condition,'') = '' OR Condition LIKE '%' + @Condition + '%') AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE) = CAST(@CreatedDate AS DATE)) and
					(@TAT IS NULL OR TAT = @TAT ) AND
					(@UnitSalePrice IS NULL OR UnitSalePrice = @UnitSalePrice) AND
					(ISNULL(@CurrencyName,'') = '' OR CurrencyName LIKE '%' + @CurrencyName + '%') AND
					(ISNULL(@CustomerReference,'') = '' OR CustomerReference LIKE '%' + @CustomerReference + '%') AND
					(ISNULL(@SalesPersonName,'') = '' OR SalesPersonName LIKE '%' + @SalesPersonName + '%'))))
					SELECT @Count = COUNT(SpeedQuoteId) FROM #TempResult

					SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY
					CASE WHEN (@SortOrder=1 AND @SortColumn='PartNumber') THEN PartNumber END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='PartDescription') THEN PartDescription END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='ManufacturerName') THEN PartDescription END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='WorkScope') THEN WorkScope END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='SpeedQuoteNumber') THEN SpeedQuoteNumber END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedDate') THEN CreatedDate END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='Condition') THEN Condition END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='TAT') THEN TAT END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='UnitSalePrice') THEN UnitSalePrice END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='CurrencyName') THEN CurrencyName END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='CustomerReference') THEN CustomerReference END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='SalesPersonName') THEN SalesPersonName END ASC,


					CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber') THEN PartNumber END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription') THEN PartDescription END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerName') THEN PartDescription END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkScope') THEN WorkScope END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='SpeedQuoteNumber') THEN SpeedQuoteNumber END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate') THEN CreatedDate END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition') THEN Condition END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='TAT') THEN TAT END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitSalePrice') THEN UnitSalePrice END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='CurrencyName') THEN CurrencyName END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerReference') THEN CustomerReference END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='SalesPersonName') THEN SalesPersonName END DESC

					OFFSET @RecordFrom ROWS
					FETCH NEXT @PageSize ROWS ONLY
			END
			END TRY
			BEGIN CATCH
				IF @@TRANCOUNT > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetPNTileQuickQuoteHistoryList' 
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