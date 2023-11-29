/***************************************************************  
 ** File:   [USP_WorkOrder_GetEmployeeBasedOnExpertise]             
 ** Author:   Hemant Saliya  
 ** Description: This stored procedure is used to get  employee list based on expertise
 ** Date:   09/30/2022  
            
  ** Change History             
 **************************************************************             
 ** PR   Date         Author    Change Description              
 ** --   --------     -------		--------------------------------  
	1    12/27/2022   Hemant Saliya	 Updated for Calulate Labor OH Cal  
	2    03/30/2023   Amit Ghediya	 Remove AverageRate, no need now

USP_Employee_GetEmployeeBasedOnExpertise 0,'7',1, '', '',1	
exec dbo.USP_Employee_GetEmployeeBasedOnExpertise @EmployeeId=N'0',@ExpertiseIds=1,@ManagementStructureId=1,@SearchText=N'',@Idlist=N'0',@IsQuote=0,@IsExpertise=1
***************************************/
CREATE    PROCEDURE [dbo].[USP_Employee_GetEmployeeBasedOnExpertise]
	@ExpertiseIds VARCHAR(500),
	@ManagementStructureId BIGINT,
	@SearchText varchar(100) = null,
	@Idlist VARCHAR(max) = '0',
	@IsQuote BIT = 0,
	@IsExpertise BIT = 0
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
  BEGIN TRY
		DECLARE @LaborRateTypeId INT;
		DECLARE @FlatAmount DECIMAL(18,2);
		DECLARE @MonthDays INT;
		DECLARE @WorkingHours INT = 8;
		DECLARE @MasterCompanyID INT;

		SELECT @MonthDays = day(eomonth(GETUTCDATE()))
		SELECT TOP 1 @MasterCompanyID = MasterCompanyId FroM dbo.EmployeeExpertise WITH(NOLOCK) WHERE EmployeeExpertiseId in (SELECT Item FROM DBO.SPLITSTRING(@ExpertiseIds,','))
		
		SELECT @LaborRateTypeId = LaborRateId FROM dbo.LaborOHSettings WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyID AND ManagementStructureId = @ManagementStructureId AND IsDeleted = 0 AND IsActive = 1

		IF(@IsQuote = 0 AND @IsExpertise = 0)
		BEGIN
			PRINT 'IS WO'
			SELECT DISTINCT 
				E.EmployeeId,
				E.EmployeeCode,
				E.StationId,
				ST.StationName,
				E.FirstName,
				E.LastName,
				E.MiddleName,	
				EEP.IsWorksInShop,
				CASE WHEN @LaborRateTypeId = 1 THEN
					CASE WHEN ISNULL(E.HourlyPay, 0) != 0 THEN 
						CASE WHEN ISNULL(E.IsHourly, 0) = 1 THEN ISNULL(E.HourlyPay, 0) ELSE CAST((ISNULL(E.HourlyPay, 0)/@MonthDays)/@WorkingHours AS DECIMAL(18,2)) END 
					ELSE 0 END 
					WHEN @LaborRateTypeId = 2 THEN EEP.Avglaborrate
				ELSE 0 END HourlyRate,
				CASE WHEN ISNULL(EEP.IsWorksInShop, 0) = 1 AND ISNULL(EEP.OverheadburdenPercentId, 0) != 0  THEN EEP.OverheadburdenPercentId ELSE 0 END AS BurdenRatePercentageId,
				CASE WHEN ISNULL(EEP.IsWorksInShop, 0) = 1 AND ISNULL(EEP.Overheadburden, 0) != 0 THEN EEP.Overheadburden ELSE 0 END AS BurdenRatePercentage,
				CASE WHEN ISNULL(EEP.IsWorksInShop, 0) = 1 AND ISNULL(EEP.FlatAmount, 0) != 0 THEN EEP.FlatAmount ELSE 0 END AS FlatAmount,
				E.HourlyPay
			INTO #TempLaborOHSettings
			FROM DBO.Employee E  WITH (NOLOCK)
				LEFT JOIN DBO.EmployeeExpertiseMapping EEM WITH (NOLOCK) on EEM.EmployeeId = E.EmployeeId
				LEFT JOIN DBO.EmployeeStation ST WITH (NOLOCK) on ST.EmployeeStationId = E.StationId
				LEFT JOIN dbo.EmployeeExpertise EEP ON EEM.EmployeeExpertiseIds =  EEP.EmployeeExpertiseId 
			WHERE E.MasterCompanyId = @MasterCompanyId AND EEP.IsWorksInShop = 1
				AND ((E.IsDeleted = 0 AND e.IsActive = 1) OR E.EmployeeId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,',')))
				AND EEM.EmployeeExpertiseIds in (SELECT Item FROM DBO.SPLITSTRING(@ExpertiseIds,','))
				AND (E.LastName LIKE '%' + @SearchText + '%' OR E.FirstName LIKE '%' + @SearchText + '%')
		
			;WITH CTE AS
			(SELECT EmployeeId, EmployeeCode, StationName, StationId, FirstName,LastName,MiddleName, IsWorksInShop, HourlyRate, BurdenRatePercentageId, BurdenRatePercentage, FlatAmount,
				CASE WHEN ISNULL(BurdenRatePercentage, 0) != 0 THEN CAST((ISNULL(HourlyRate,0) * ISNULL(BurdenRatePercentage, 0)) / 100 AS DECIMAL(18,2)) 
					 WHEN ISNULL(BurdenRatePercentageId, 0) != 0 THEN CAST((ISNULL(HourlyRate,0) * ISNULL(P.PercentValue, 0)) / 100 AS DECIMAL(18,2))
					 ELSE FlatAmount
					 END AS BurdenRateAmount
			FROM #TempLaborOHSettings tmpOH
			LEFT JOIN dbo.[Percent] P WITH(NOLOCK) ON P.PercentId = tmpOH.BurdenRatePercentageId)
			SELECT EmployeeId, EmployeeCode, StationId, StationName, FirstName,LastName,MiddleName, FirstName + ' ' + LastName AS [Name] , IsWorksInShop, HourlyRate, BurdenRatePercentageId, BurdenRatePercentage, FlatAmount, 
				   BurdenRateAmount, ISNULL(HourlyRate,0) + ISNULL(BurdenRateAmount, 0) AS TotalCostPerHour 
			FROM CTE
		END

		IF(@IsQuote = 1 OR @IsExpertise = 1)
		BEGIN
			PRINT 'IS Quote'
			SELECT DISTINCT 
				0 AS EmployeeId,
				'' AS EmployeeCode,
				0 AS StationId,
				'' AS StationName,
				'' AS FirstName,
				'' AS LastName,
				'' AS MiddleName,
				'' AS [Name],
				EEP.IsWorksInShop,
				Avglaborrate AS HourlyRate,
				CASE WHEN ISNULL(EEP.IsWorksInShop, 0) = 1 AND ISNULL(EEP.OverheadburdenPercentId, 0) != 0  THEN EEP.OverheadburdenPercentId ELSE 0 END AS BurdenRatePercentageId,
				CASE WHEN ISNULL(EEP.IsWorksInShop, 0) = 1 AND ISNULL(EEP.Overheadburden, 0) != 0 THEN EEP.Overheadburden ELSE 0 END AS BurdenRatePercentage,
				CASE WHEN ISNULL(EEP.IsWorksInShop, 0) = 1 AND ISNULL(EEP.FlatAmount, 0) != 0 THEN EEP.FlatAmount ELSE 0 END AS FlatAmount
			INTO #LaborOHSettings
			FROM DBO.EmployeeExpertise EEP  WITH (NOLOCK) 
			WHERE EEP.IsWorksInShop = 1 AND EEP.EmployeeExpertiseId in (SELECT Item FROM DBO.SPLITSTRING(@ExpertiseIds,','))

			;WITH CTE AS
			(SELECT EmployeeId, EmployeeCode, StationName, StationId, FirstName,LastName,MiddleName, IsWorksInShop, HourlyRate, BurdenRatePercentageId, BurdenRatePercentage, FlatAmount,
				CASE WHEN ISNULL(BurdenRatePercentage, 0) != 0 THEN CAST((ISNULL(HourlyRate,0) * ISNULL(BurdenRatePercentage, 0)) / 100 AS DECIMAL(18,2)) 
					 WHEN ISNULL(BurdenRatePercentageId, 0) != 0 THEN CAST((ISNULL(HourlyRate,0) * ISNULL(P.PercentValue, 0)) / 100 AS DECIMAL(18,2))
					 ELSE FlatAmount
					 END AS BurdenRateAmount
			FROM #LaborOHSettings tmpOH
			LEFT JOIN dbo.[Percent] P WITH(NOLOCK) ON P.PercentId = tmpOH.BurdenRatePercentageId)
			SELECT EmployeeId, EmployeeCode, StationId, StationName, FirstName,LastName,MiddleName, FirstName + ' ' + LastName AS [Name] , IsWorksInShop, HourlyRate, BurdenRatePercentageId, BurdenRatePercentage, FlatAmount, 
				   BurdenRateAmount, ISNULL(HourlyRate,0) + ISNULL(BurdenRateAmount, 0) AS TotalCostPerHour 
			FROM CTE
		END
			
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_WorkOrder_GetEmployeeBasedOnExpertise]',
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