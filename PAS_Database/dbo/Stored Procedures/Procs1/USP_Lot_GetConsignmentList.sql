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
	3    20/02/2025   Ayushi Patel      converted the date into utc (created) , Added a case to get timeZone
	4    11/08/2026   Nakul           Replaced HowCalculate/CalculateValue with per-method columns (IsRevenue/RevenuePercentage, IsMargin/MarginPercentage, IsFixedAmount/Amount) so each consignment is a single row showing all configured methods
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
	@CreatedBy  varchar(50) = NULL,
	@CreatedDate datetime = NULL,
	@MasterCompanyId bigint = NULL,
	@EmployeeId bigint
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
		DECLARE @CurrntEeTimeZoneDesc VARCHAR(100) = '';
		
				SELECT 
						@CurrntEeTimeZoneDesc = COALESCE(
							ETZ.[Description],  -- Prefer Employee's TimeZone description if available
							LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
						)
					FROM 
						dbo.Employee E WITH (NOLOCK) 
					LEFT JOIN 
						dbo.TimeZone ETZ WITH (NOLOCK) 
						ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN 
						dbo.LegalEntity LE WITH (NOLOCK) 
						ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN 
						dbo.TimeZone LTZ WITH (NOLOCK) 
						ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE 
						E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

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
			   --,LC.[CreatedDate] CreatedDate
			   ,case when CAST(LC.[CreatedDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(LC.[CreatedDate], @CurrntEeTimeZoneDesc) as Date))end CreatedDate
			   ,ISNULL(LC.IsMargin,0) AS IsMargin
			   ,(CASE WHEN ISNULL(LC.IsMargin,0) = 1 THEN (SELECT ISNULL(PercentValue,0) FROM DBO.[Percent] P WITH(NOLOCK) WHERE P.PercentId = ISNULL(LC.MarginPercentId,0)) ELSE NULL END) AS MarginPercentage
			   ,ISNULL(LC.IsRevenue,0) AS IsRevenue
			   ,(CASE WHEN ISNULL(LC.IsRevenue,0) = 1 THEN (SELECT ISNULL(PercentValue,0) FROM DBO.[Percent] P WITH(NOLOCK) WHERE P.PercentId = ISNULL(LC.PercentId,0)) ELSE NULL END) AS RevenuePercentage
			   ,ISNULL(LC.IsFixedAmount,0) AS IsFixedAmount
			   ,(CASE WHEN ISNULL(LC.IsFixedAmount,0) = 1 THEN ISNULL(LC.PerAmount,0.00) ELSE NULL END) AS Amount
			   ,UPPER(LC.ConsignmentNumber)ConsignmentNumber
			   ,UPPER(LC.ConsigneeName)ConsigneeName
			   	,UPPER(LC.ConsignmentName)ConsignmentName
			   ,LC.[MasterCompanyId]
			   ,LC.[CreatedBy]
			   ,LC.[UpdatedBy]
			   ,case when LC.[UpdatedDate] IS NULL OR CAST(LC.[UpdatedDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(LC.[UpdatedDate], @CurrntEeTimeZoneDesc) as Date))end UpdatedDate
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
					(CAST(MarginPercentage AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(RevenuePercentage AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(Amount AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
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
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date) = CAST(@CreatedDate AS date))
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
			CASE WHEN (@SortOrder=1  AND @SortColumn='MARGINPERCENTAGE')  THEN MarginPercentage END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='MARGINPERCENTAGE')  THEN MarginPercentage END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='REVENUEPERCENTAGE')  THEN RevenuePercentage END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='REVENUEPERCENTAGE')  THEN RevenuePercentage END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNT')  THEN Amount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNT')  THEN Amount END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC
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