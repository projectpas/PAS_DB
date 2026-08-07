/********************************************************************
 ** File:   [USP_LeaseHeaderList]
 ** Description: Returns the paginated list of Lease Header records.
 **
 ***********************************************************************
 ** Change History
 ***********************************************************************
 ** PR   Date         Author          Change Description
 ** --   --------     -------         ------------------------------------
    1    04/08/2026   Amit Ghediya    Created

exec USP_LeaseHeaderList
@PageNumber=1,@PageSize=10,@SortColumn=NULL,@SortOrder=-1,@GlobalFilter=N'',@LeaseNumber=NULL,@LeaseName=NULL,
@CustomerName=NULL,@LeaseStatusId=NULL,@CreatedBy=NULL,@CreatedDate=NULL,@UpdatedBy=NULL,@UpdatedDate=NULL,
@MasterCompanyId=1,@StatusId=NULL,@IsDeleted=NULL,@EmployeeId=226
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_LeaseHeaderList]
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50) = NULL,
	@SortOrder int = NULL,
	@GlobalFilter varchar(50) = '',
	@LeaseNumber varchar(50) = NULL,
	@LeaseName varchar(200) = NULL,
	@CustomerName varchar(100) = NULL,
	@LeaseStatusId int = NULL,
	@CreatedBy varchar(50) = NULL,
	@CreatedDate datetime = NULL,
	@UpdatedBy varchar(50) = NULL,
	@UpdatedDate datetime = NULL,
	@MasterCompanyId bigint = NULL,
	@StatusId int = NULL,
	@IsDeleted bit = NULL,
	@EmployeeId bigint = NULL,
	@TailNum varchar(50) = NULL,
	@PnDescription varchar(200) = NULL,
	@SerialNum varchar(50) = NULL,
	@AcSection varchar(100) = NULL,
	@StocklineNum varchar(50) = NULL,
	@BillingMethod varchar(50) = NULL,
	@BillingFrequency varchar(50) = NULL,
	@ContractCycle varchar(50) = NULL,
	@ContractTime varchar(50) = NULL,
	@StartDate datetime = NULL,
	@EndDate datetime = NULL,
	@LeaseStatus varchar(50) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
		DECLARE @Count int;
		DECLARE @RecordFrom int;
		DECLARE @IsActive bit;
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

		SELECT
				@CurrntEmpTimeZoneDesc = COALESCE(
					ETZ.[Description],
					LTZ.[Description]
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
				E.EmployeeId = @EmployeeId;

		SET @RecordFrom = (@PageNumber-1)*@PageSize;

		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = Upper('CreatedDate')
			SET @SortOrder = -1
		END
		ELSE
		BEGIN
			SET @SortColumn = Upper(@SortColumn)
		END
		IF(@StatusId=0)
		BEGIN
			SET @IsActive=0;
		END
		ELSE IF(@StatusId=1)
		BEGIN
			SET @IsActive=1;
		END
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END

		;WITH Result AS (
			SELECT DISTINCT
				LH.LeaseHeaderId
			   ,LH.LeaseNumber
			   ,LH.LeaseName
			   ,LH.LeaseTypeId
			   ,LH.LeaseStatusId
			   ,CASE LH.LeaseStatusId WHEN 1 THEN 'Draft' WHEN 2 THEN 'Active' WHEN 3 THEN 'Closed' END as 'LeaseStatusName'
			   ,C.Name as 'CustomerName'
			   ,MS.Name as 'ManagementStructureName'
			   ,LH.[MasterCompanyId]
			   ,LH.[CreatedBy]
			   ,LH.[UpdatedBy]
			   ,CASE WHEN @EmployeeId IS NOT NULL AND @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN
					CASE WHEN CAST(LH.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(LH.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END
				ELSE (CAST(LH.CreatedDate AS DATETIME)) END CreatedDate
			   ,CASE WHEN @EmployeeId IS NOT NULL AND @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN
					CASE WHEN CAST(LH.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(LH.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END
				ELSE (CAST(LH.UpdatedDate AS DATETIME)) END UpdatedDate
			   ,LH.[IsActive]
			   ,LH.[IsDeleted]
			   ,'' AS [TailNum]
			   ,'' AS [PnDescription]
			   ,'' AS [SerialNum]
			   ,'' AS [AcSection]
			   ,'' AS [StocklineNum]
			   ,'' AS [BillingMethod]
			   ,'' AS [BillingFrequency]
			   ,'' AS [ContractCycle]
			   ,'' AS [ContractTime]
			   ,'' AS [StartDate]
			   ,'' AS [EndDate]
				FROM [dbo].[LeaseHeader] LH WITH(NOLOCK)
				LEFT JOIN dbo.Customer C WITH(NOLOCK) ON LH.CustomerId = C.CustomerId
				LEFT JOIN dbo.ManagementStructure MS WITH(NOLOCK) ON LH.ManagementStructureId = MS.ManagementStructureId
			WHERE LH.IsDeleted = @IsDeleted AND (@IsActive IS NULL OR LH.IsActive=@IsActive) AND LH.MasterCompanyId = @MasterCompanyId
		  	)
		SELECT * INTO #TempResult FROM  Result
			 WHERE ((ISNULL(@GlobalFilter,'') <>'' AND ((LeaseNumber LIKE '%' +@GlobalFilter+'%') OR
			        (LeaseName LIKE '%' +@GlobalFilter+'%') OR
					(CustomerName LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR
					(TailNum LIKE '%' +@GlobalFilter+'%') OR
					(PnDescription LIKE '%' +@GlobalFilter+'%') OR
					(SerialNum LIKE '%' +@GlobalFilter+'%') OR
					(AcSection LIKE '%' +@GlobalFilter+'%') OR
					(StocklineNum LIKE '%' +@GlobalFilter+'%') OR
					(BillingMethod LIKE '%' +@GlobalFilter+'%') OR
					(BillingFrequency LIKE '%' +@GlobalFilter+'%') OR
					(ContractCycle LIKE '%' +@GlobalFilter+'%') OR
					(ContractTime LIKE '%' +@GlobalFilter+'%') OR
					(LeaseStatusName LIKE '%' +@GlobalFilter+'%'))) OR
					(ISNULL(@GlobalFilter,'')='' AND (ISNULL(@LeaseNumber,'') ='' OR LeaseNumber LIKE '%' + @LeaseNumber+'%') AND
					(ISNULL(@LeaseName,'') ='' OR LeaseName LIKE '%' + @LeaseName + '%') AND
					(ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName + '%') AND
					(@LeaseStatusId IS NULL OR LeaseStatusId = @LeaseStatusId) AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)) AND
					(ISNULL(@TailNum,'') ='' OR TailNum LIKE '%' + @TailNum + '%') AND
					(ISNULL(@PnDescription,'') ='' OR PnDescription LIKE '%' + @PnDescription + '%') AND
					(ISNULL(@SerialNum,'') ='' OR SerialNum LIKE '%' + @SerialNum + '%') AND
					(ISNULL(@AcSection,'') ='' OR AcSection LIKE '%' + @AcSection + '%') AND
					(ISNULL(@StocklineNum,'') ='' OR StocklineNum LIKE '%' + @StocklineNum + '%') AND
					(ISNULL(@BillingMethod,'') ='' OR BillingMethod LIKE '%' + @BillingMethod + '%') AND
					(ISNULL(@BillingFrequency,'') ='' OR BillingFrequency LIKE '%' + @BillingFrequency + '%') AND
					(ISNULL(@ContractCycle,'') ='' OR ContractCycle LIKE '%' + @ContractCycle + '%') AND
					(ISNULL(@ContractTime,'') ='' OR ContractTime LIKE '%' + @ContractTime + '%') AND
					(ISNULL(@StartDate,'') ='' OR CAST(StartDate AS date)=CAST(@StartDate AS date)) AND
					(ISNULL(@EndDate,'') ='' OR CAST(EndDate AS date)=CAST(@EndDate AS date)) AND
					(ISNULL(@LeaseStatus,'') ='' OR LeaseStatusName LIKE '%' + @LeaseStatus + '%'))
				   )

			SELECT @Count = COUNT(LeaseHeaderId) FROM #TempResult

			SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEASENUMBER')  THEN LeaseNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEASENUMBER')  THEN LeaseNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEASENAME')  THEN LeaseName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEASENAME')  THEN LeaseName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERNAME')  THEN CustomerName END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEASEID')  THEN LeaseNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEASEID')  THEN LeaseNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='TAILNUM')  THEN TailNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TAILNUM')  THEN TailNum END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PNDESCRIPTION')  THEN PnDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PNDESCRIPTION')  THEN PnDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SERIALNUM')  THEN SerialNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SERIALNUM')  THEN SerialNum END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ACSECTION')  THEN AcSection END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ACSECTION')  THEN AcSection END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='STATUS')  THEN LeaseStatusId END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='STATUS')  THEN LeaseStatusId END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='STOCKLINENUM')  THEN StocklineNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='STOCKLINENUM')  THEN StocklineNum END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='BILLINGMETHOD')  THEN BillingMethod END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='BILLINGMETHOD')  THEN BillingMethod END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='BILLINGFREQUENCY')  THEN BillingFrequency END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='BILLINGFREQUENCY')  THEN BillingFrequency END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CONTRACTCYCLE')  THEN ContractCycle END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CONTRACTCYCLE')  THEN ContractCycle END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CONTRACTTIME')  THEN ContractTime END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CONTRACTTIME')  THEN ContractTime END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='STARTDATE')  THEN StartDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='STARTDATE')  THEN StartDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ENDDATE')  THEN EndDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ENDDATE')  THEN EndDate END DESC
			OFFSET @RecordFrom ROWS
			FETCH NEXT @PageSize ROWS ONLY
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_LeaseHeaderList]',
            @ProcedureParameters varchar(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END