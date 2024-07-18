/*************************************************************           
 ** File:   [USP_Lot_GetConsignmentLis]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Get LotConsignment Listing 
 ** Date:   27/07/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    27/07/2023   Rajesh Gami     Created
	2    18 July 2024   Shrey Chandegara       Modified( use this function @CurrntEmpTimeZoneDesc for date issue.)
**************************************************************
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_Lot_GetConsignmentList] 
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@GlobalFilter varchar(50) = '',	
	@LotNumber varchar(50) = NULL,
	@ConsignmentNumber varchar(200) = NULL,
	@ConsigneeName varchar(100) = NULL,
	@ConsignmentName varchar(100) = NULL,
	@HowCalculate varchar(200) = NULL,
	@CalculateValue decimal(18,2) = NULL,
	@CreatedBy  varchar(50) = NULL,
	@CreatedDate datetime = NULL,
	@MasterCompanyId bigint = NULL	
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
		DECLARE @Count Int;
		DECLARE @RecordFrom int;
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	    SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId 
		SET @RecordFrom = (@PageNumber-1)*@PageSize;

		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = Upper('CreatedDate')
			SET @SortOrder = -1
		END 
		ELSE
		BEGIN 
			Set @SortColumn = Upper(@SortColumn)
		END

		;WITH Result AS (	
			SELECT DISTINCT
				LT.[LotId] LotId
			   ,LC.ConsignmentId
			   ,UPPER(LT.LotNumber) LotNumber
			   ,UPPER(LT.LotName) LotName
			   ,LC.[CreatedDate] CreatedDate
			   , (CASE WHEN ISNULL(lc.IsRevenue,0) = 1 THEN 'REVENUE' WHEN ISNULL(lc.IsMargin,0) = 1 THEN 'MARGIN' WHEN ISNULL(lc.IsFixedAmount,0) = 1 THEN 'FIXED AMOUNT' WHEN ISNULL(lc.IsRevenueSplit,0) = 1 THEN 'REVENUE SPLIT' ELSE '' END) HowCalculate
			   --,ISNULL(LC.PerAmount,0.00)CalculateValue
			   ,(CASE WHEN ISNULL(LC.IsFixedAmount,0) = 1 THEN ISNULL(LC.PerAmount,0.00) ELSE (SELECT ISNULL(PercentValue,0) FROM DBO.[Percent] P WITH(NOLOCK) WHERE P.PercentId = ISNULL(LC.PercentId,0)) END) AS CalculateValue
			   ,UPPER(LC.ConsignmentNumber)ConsignmentNumber
			   ,UPPER(LC.ConsigneeName)ConsigneeName
			   	,UPPER(LC.ConsignmentName)ConsignmentName
			   ,LC.[MasterCompanyId]
			   ,LC.[CreatedBy]
			   ,ISNULL(lc.IsFixedAmount,0)AS IsFixedAmount
				FROM 
				dbo.LotConsignment LC
				INNER JOIN [dbo].[Lot] LT WITH(NOLOCK) ON LC.LotId = LT.LotId
 			WHERE ISNULL(LC.IsDeleted,0) = 0 AND ISNULL(LC.IsActive,1) = 1 And LC.MasterCompanyId = @MasterCompanyId
		  	) , ResultCount AS(Select COUNT(LotId) AS totalItems FROM Result) 
			SELECT * INTO #TempTblLot FROM  Result 
		SELECT * INTO #TempResult FROM  #TempTblLot 
			WHERE 
			 ((@GlobalFilter <>'' AND (
				(LotNumber LIKE '%' + @GlobalFilter + '%') OR
					(LotName LIKE '%' + @GlobalFilter + '%') OR
					(HowCalculate LIKE '%' + @GlobalFilter + '%') OR
					(CAST(CalculateValue AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(ConsignmentNumber LIKE '%' + @GlobalFilter + '%') OR
					(ConsigneeName LIKE '%' + @GlobalFilter + '%') OR
					(ConsignmentName LIKE '%' + @GlobalFilter + '%') OR
					(CreatedBy like '%' + @GlobalFilter + '%') ))
					--(CreatedDate like '%' + @GlobalFilter + '%')))
					OR
					(@GlobalFilter = '' AND (ISNULL(@LotNumber, '') = '' OR LotNumber LIKE '%' + @LotNumber + '%') AND
					(ISNULL(@ConsignmentNumber, '') = '' OR ConsignmentNumber LIKE '%' + @ConsignmentNumber + '%') AND
					(ISNULL(@ConsignmentName, '') = '' OR ConsignmentName LIKE '%' + @ConsignmentName + '%') AND
					(ISNULL(@ConsigneeName, '') = '' OR ConsigneeName LIKE '%' + @ConsigneeName + '%') AND
					(ISNULL(@CreatedBy, '') = '' OR CreatedBy  like '%'+ @CreatedBy + '%') AND
					(ISNULL(@HowCalculate, '') = '' OR HowCalculate  like '%'+ @HowCalculate + '%') AND
					(IsNull(@CalculateValue, 0) = 0 OR CAST(CalculateValue as VARCHAR(10)) like @CalculateValue) AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal(CreatedDate, @CurrntEmpTimeZoneDesc )AS date) = CAST(@CreatedDate AS date))
					)
				  )

			SELECT @Count = COUNT(LotId) FROM #TempResult			
			
			SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='LotNumber')  THEN LotNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LotNumber')  THEN LotNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LotName')  THEN LotName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LotName')  THEN LotName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ConsignmentNumber')  THEN ConsignmentNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ConsignmentNumber')  THEN ConsignmentNumber END DESC,           
			CASE WHEN (@SortOrder=1  AND @SortColumn='ConsigneeName')  THEN ConsigneeName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ConsigneeName')  THEN ConsigneeName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ConsignmentName')  THEN ConsignmentName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ConsignmentName')  THEN ConsignmentName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='HowCalculate')  THEN HowCalculate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='HowCalculate')  THEN HowCalculate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CalculateValue')  THEN CalculateValue END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CalculateValue')  THEN CalculateValue END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedDate')  THEN CreatedDate END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_Lot_GetLotList]',
            @ProcedureParameters varchar(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END