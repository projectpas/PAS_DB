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
    2    19/08/2026   Amit Ghediya    Added @IsDetailView - Detail View now fans out one row per LeasePart/LeaseStockline;
                                      Summary View's TailNum shows the single Part Number or 'Multiple' when more than one part exists
    3    19/08/2026   Amit Ghediya    Summary View's StartDate/EndDate now bind too - single part shows its own dates,
                                      multiple parts show the overall MIN(StartDate)/MAX(EndDate) range across them

exec USP_LeaseHeaderList
@PageNumber=1,@PageSize=10,@SortColumn=NULL,@SortOrder=-1,@GlobalFilter=N'',@LeaseNumber=NULL,@LeaseName=NULL,
@CustomerName=NULL,@LeaseStatusId=NULL,@CreatedBy=NULL,@CreatedDate=NULL,@UpdatedBy=NULL,@UpdatedDate=NULL,
@MasterCompanyId=1,@StatusId=NULL,@IsDeleted=NULL,@EmployeeId=226,@IsDetailView=0
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
	@LeaseStatus varchar(50) = NULL,
	@IsDetailView bit = 0
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

		IF OBJECT_ID(N'tempdb..#RawResult') IS NOT NULL
		BEGIN
			DROP TABLE #RawResult
		END
		IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL
		BEGIN
			DROP TABLE #TempResult
		END

		IF (@IsDetailView = 1)
		BEGIN
			-- Detail View: one row per LeasePart, further fanned out per LeaseStockline (mirrors USP_GetLeasePartsByLeaseHeaderId's join shape)
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
			   ,ISNULL(LP.PN,'') AS [TailNum]
			   ,ISNULL(LP.PNDescription,'') AS [PnDescription]
			   ,ISNULL(LSL.SN,'') AS [SerialNum]
			   ,ISNULL(ACS.Section,'') AS [AcSection]
			   ,ISNULL(LSL.StocklineNumber,'') AS [StocklineNum]
			   ,ISNULL(LSL.BillingMethod,'') AS [BillingMethod]
			   ,ISNULL(LSL.BillingInterval,'') AS [BillingFrequency]
			   ,CASE WHEN LSL.MinimumCycles IS NULL AND LSL.MaximumCycles IS NULL THEN ''
					 ELSE CAST(ISNULL(LSL.MinimumCycles,0) AS VARCHAR(20)) + ' - ' + CAST(ISNULL(LSL.MaximumCycles,0) AS VARCHAR(20)) END AS [ContractCycle]
			   ,CASE WHEN LSL.MinimumTimes IS NULL AND LSL.MaximumTimes IS NULL THEN ''
					 ELSE CAST(ISNULL(LSL.MinimumTimes,0) AS VARCHAR(20)) + ' - ' + CAST(ISNULL(LSL.MaximumTimes,0) AS VARCHAR(20)) END AS [ContractTime]
			   ,ISNULL(CONVERT(VARCHAR(20), LP.StartDate, 101),'') AS [StartDate]
			   ,ISNULL(CONVERT(VARCHAR(20), LP.EndDate, 101),'') AS [EndDate]
			INTO #RawResult
				FROM [dbo].[LeaseHeader] LH WITH(NOLOCK)
				LEFT JOIN dbo.Customer C WITH(NOLOCK) ON LH.CustomerId = C.CustomerId
				LEFT JOIN dbo.ManagementStructure MS WITH(NOLOCK) ON LH.ManagementStructureId = MS.ManagementStructureId
				LEFT JOIN dbo.LeasePart LP WITH(NOLOCK) ON LP.LeaseHeaderId = LH.LeaseHeaderId AND LP.IsDeleted = 0
				LEFT JOIN dbo.LeaseStockline LSL WITH(NOLOCK) ON LSL.LeasePartId = LP.LeasePartId AND LSL.IsDeleted = 0
				LEFT JOIN dbo.AircraftSection ACS WITH(NOLOCK) ON ACS.AircraftSectionId = LP.AircraftSectionId
			WHERE LH.IsDeleted = @IsDeleted AND (@IsActive IS NULL OR LH.IsActive=@IsActive) AND LH.MasterCompanyId = @MasterCompanyId
		END
		ELSE
		BEGIN
			-- Summary View: one row per LeaseHeader; TailNum shows the single Part Number, or 'Multiple' when more than one part exists
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
			   ,CASE WHEN PartAgg.PartCount > 1 THEN 'Multiple' ELSE ISNULL(PartAgg.AnyPN,'') END AS [TailNum]
			   ,'' AS [PnDescription]
			   ,'' AS [SerialNum]
			   ,'' AS [AcSection]
			   ,'' AS [StocklineNum]
			   ,'' AS [BillingMethod]
			   ,'' AS [BillingFrequency]
			   ,'' AS [ContractCycle]
			   ,'' AS [ContractTime]
			   ,ISNULL(CONVERT(VARCHAR(20), CASE WHEN PartAgg.PartCount > 1 THEN PartAgg.MinStartDate ELSE PartAgg.AnyStartDate END, 101),'') AS [StartDate]
			   ,ISNULL(CONVERT(VARCHAR(20), CASE WHEN PartAgg.PartCount > 1 THEN PartAgg.MaxEndDate ELSE PartAgg.AnyEndDate END, 101),'') AS [EndDate]
			INTO #RawResult
				FROM [dbo].[LeaseHeader] LH WITH(NOLOCK)
				LEFT JOIN dbo.Customer C WITH(NOLOCK) ON LH.CustomerId = C.CustomerId
				LEFT JOIN dbo.ManagementStructure MS WITH(NOLOCK) ON LH.ManagementStructureId = MS.ManagementStructureId
				OUTER APPLY (
					SELECT COUNT(1) AS PartCount, MIN(LP2.StartDate) AS MinStartDate, MAX(LP2.EndDate) AS MaxEndDate,
						   MAX(LP2.PN) AS AnyPN, MAX(LP2.StartDate) AS AnyStartDate, MAX(LP2.EndDate) AS AnyEndDate
					FROM dbo.LeasePart LP2 WITH(NOLOCK)
					WHERE LP2.LeaseHeaderId = LH.LeaseHeaderId AND LP2.IsDeleted = 0
				) AS PartAgg
			WHERE LH.IsDeleted = @IsDeleted AND (@IsActive IS NULL OR LH.IsActive=@IsActive) AND LH.MasterCompanyId = @MasterCompanyId
		END

		SELECT * INTO #TempResult FROM  #RawResult
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
