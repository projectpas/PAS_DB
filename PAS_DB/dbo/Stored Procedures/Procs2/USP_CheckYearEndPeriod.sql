/*************************************************************             
 ** File:   [USP_CheckYearEndPeriod]             
 ** Author:   
 ** Description: This stored procedure is used to validate year end periods
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    28/08/2023   Satish Gohil   Created
	2    13/09/2023   Hemant Saliya  Updated
 **************************************************************  
 DECLARE @ValidPeriods BIT
 EXEC USP_CheckYearEndPeriod 2023, 1 , '1', @ValidPeriods OUTPUT
**************************************************************/  
CREATE     PROCEDURE [dbo].[USP_CheckYearEndPeriod]
(
	@FiscalYear INT,
	@MasterCompanyId INT,
	@LegalEntityIds VARCHAR(MAX),
	@ValidPeriods INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
	BEGIN	
		DECLARE @CloseAllPeriod INT = 1;
		DECLARE @StartDate DATETIME;
		DECLARE @EndDate DATETIME;
	
		IF OBJECT_ID(N'tempdb..#tmpAccountingPeriod') IS NOT NULL
		BEGIN
			DROP TABLE #tmpAccountingPeriod
		END

		CREATE TABLE #tmpAccountingPeriod
		(
			ID BIGINT NOT NULL IDENTITY, 
			AccountPeriodId BIGINT NULL,
			AccountPeriod VARCHAR(50) NULL,
			LegalEntityId BIGINT NULL,
			isAccStatusName BIT NULL,
			isAPStatusName BIT NULL,
			isARStatusName BIT NULL,
			isAssetStatusName BIT NULL,
			isInventoryStatusName BIT NULL,
		)

		SELECT @StartDate = MIN(FromDate) FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE FiscalYear = @FiscalYear AND LegalEntityId IN (SELECT ITEM FROM dbo.SplitString(@LegalEntityIds,','))
		SELECT @EndDate = MAX(ToDate) FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE FiscalYear = @FiscalYear AND LegalEntityId IN (SELECT ITEM FROM dbo.SplitString(@LegalEntityIds,','))

		INSERT INTO #tmpAccountingPeriod (AccountPeriodId,AccountPeriod,LegalEntityId,isAccStatusName,isAPStatusName,isARStatusName,isAssetStatusName,isInventoryStatusName)
		SELECT AccountingCalendarId,PeriodName,LegalEntityId,ISNULL(isaccStatusName,1),ISNULL(isacpStatusName,1),ISNULL(isacrStatusName,1),ISNULL(isassetStatusName,1),ISNULL(isinventoryStatusName,1)
		FROM dbo.AccountingCalendar WITH(NOLOCK)
		WHERE LegalEntityId IN (SELECT ITEM FROM dbo.SplitString(@LegalEntityIds,',')) AND
			(CAST(FromDate AS date) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE) OR
			CAST(ToDate AS date) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE))
			AND MasterCompanyId = @MasterCompanyId AND IsActive= 1 AND IsDeleted = 0

		IF EXISTS(SELECT 1 FROM #tmpAccountingPeriod WHERE isAccStatusName = 1 OR isAPStatusName = 1 OR isARStatusName = 1 OR isAssetStatusName = 1 OR isInventoryStatusName  =1)
		BEGIN
			SET @CloseAllPeriod = 0;
		END

		IF NOT EXISTS(SELECT TOP 1 acc.* FROM dbo.AccountingCalendar acc WITH(NOLOCK) 
					WHERE acc.MasterCompanyId = @MasterCompanyId AND FiscalYear = (@FiscalYear + 1) 
					AND LegalEntityId IN (SELECT ITEM FROM dbo.SplitString(@LegalEntityIds,',')) AND ISNULL([Period], 0) = 1)
		BEGIN
			SET @CloseAllPeriod = 2;
		END

		SET @ValidPeriods = @CloseAllPeriod;

		SELECT @ValidPeriods

	END
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'USP_CheckYearEndPeriod' 
		, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
		, @ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		exec spLogException 
		@DatabaseName           = @DatabaseName
		, @AdhocComments          = @AdhocComments
		, @ProcedureParameters = @ProcedureParameters
		, @ApplicationName        =  @ApplicationName
		, @ErrorLogID                    = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END