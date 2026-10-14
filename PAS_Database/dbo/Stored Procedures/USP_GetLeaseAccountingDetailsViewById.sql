/*************************************************************
 ** File:   [USP_GetLeaseAccountingDetailsViewById]
 ** Description: Lease -> Accounting tab (Journal Details grid). Returns one row per journal line
 **              (CommonBatchDetails) generated for the lease's invoices, linked through LeaseBatchDetails.
 **              Lease equivalent of GetAccountingDetailsViewById (Sales Order); output columns are kept
 **              the same so the grid / export can be shared.
 **
 **              Management-structure level names come from the journal line itself
 **              (AccountingBatchManagementStructureDetails, written by PROCAddUpdateAccountingBatchMSData),
 **              because Lease has no per-lease management-structure detail table.
 ** PARAMETERS: @LeaseHeaderId BIGINT, @EmployeeId BIGINT (time zone used for the dates shown)
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    07/10/2026     Kishor Makwana          [Lease Accounting] Created

EXEC USP_GetLeaseAccountingDetailsViewById @LeaseHeaderId = 1, @EmployeeId = 1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeaseAccountingDetailsViewById]
	@LeaseHeaderId BIGINT,
	@EmployeeId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @AccountMSModuleId INT = 0;
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Accounting';

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description])
		FROM [dbo].[Employee] E WITH(NOLOCK)
		LEFT JOIN [dbo].[TimeZone] ETZ WITH(NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN [dbo].[LegalEntity] LEN WITH(NOLOCK) ON E.LegalEntityId = LEN.LegalEntityId
		LEFT JOIN [dbo].[TimeZone] LTZ WITH(NOLOCK) ON LEN.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId;

		SELECT JBH.[BatchName]
			,JBD.[LineNumber]
			,JBD.[GlAccountId]
			,JBD.[GlAccountNumber]
			,UPPER(JBD.[GlAccountName]) AS [GlAccountName]
			,CASE WHEN CAST(JBD.[TransactionDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(dbo.ConvertUTCtoLocal(JBD.[TransactionDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END AS TransactionDate
			,CASE WHEN CAST(JBD.[EntryDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(dbo.ConvertUTCtoLocal(JBD.[EntryDate], @CurrntEmpTimeZoneDesc) AS DATE)) END AS EntryDate
			,LBD.[LeaseHeaderId]
			,LBD.[LeaseNumber]
			,LBD.[LeaseStocklineId]
			,LBD.[DocumentId]
			,LBD.[DocumentNumber]
			,LBD.[LineType]
			,LBD.[PartId]
			,LBD.[PartNumber]
			,JBD.[JournalTypeId]
			,UPPER(JBD.[JournalTypeName]) AS [JournalTypeName]
			,JBD.[IsDebit]
			,JBD.[DebitAmount]
			,JBD.[CreditAmount]
			,LBD.[CustomerId]
			,UPPER(LBD.[CustomerName]) AS [CustomerName]
			,LBD.[ARControlNumber]
			,LBD.[StocklineId]
			,LBD.[StocklineNumber]
			,LBD.[CustomerRef]
			,LBD.[CommonJournalBatchDetailId]
			,JBD.[ManagementStructureId]
			,JBD.[ModuleName]
			,LBD.[LeaseBatchDetailId]
			,LBD.[JournalBatchDetailId]
			,LBD.[JournalBatchHeaderId]
			,LBD.[CustomerTypeId]
			,LBD.[CustomerType]
			,LBD.[ItemMasterId]
			,JBD.[MasterCompanyId]
			,JBD.[CreatedBy]
			,JBD.[UpdatedBy]
			,JBD.[CreatedDate]
			,JBD.[UpdatedDate]
			,JBD.[IsActive]
			,JBD.[IsDeleted]
			,GL.[AllowManualJE]
			,JBD.[LastMSLevel]
			,JBD.[AllMSlevels]
			,JBD.[IsManualEntry]
			,JBD.[DistributionSetupId]
			,JBD.[DistributionName]
			,LE.[CompanyName] AS LegalEntityName
			,BD.[JournalTypeNumber]
			,UPPER(BS.[Name]) AS JEStatus
			,BD.[CurrentNumber]
			,BD.[AccountingPeriod] AS AccountingPeriod
			,ISNULL(BD.[IsReversedJE], 0) AS [IsReversedJE]
			,CR.[Code] AS Currency
			,CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description] AS level1
			,CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description] AS level2
			,CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description] AS level3
			,CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description] AS level4
			,CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description] AS level5
			,CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description] AS level6
			,CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description] AS level7
			,CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description] AS level8
			,CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description] AS level9
			,CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] AS level10
			,JBD.[LotNumber]
			,CASE WHEN JBD.[IsUpdated] = 1 THEN 1 ELSE 0 END AS IsUpdated
		FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)
		INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId = BD.JournalBatchDetailId
		INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId = JBH.JournalBatchHeaderId
		INNER JOIN [dbo].[LeaseBatchDetails] LBD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = LBD.CommonJournalBatchDetailId
		LEFT JOIN [dbo].[LeaseHeader] LH WITH(NOLOCK) ON LH.LeaseHeaderId = LBD.LeaseHeaderId
		LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = LH.LocalCurrencyId
		LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId = JBD.GLAccountId
		LEFT JOIN [dbo].[EntityStructureSetup] ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON ESP.Level1Id = MSL.ID
		LEFT JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON MSL.LegalEntityId = LE.LegalEntityId
		LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BS.Id = BD.StatusId
		LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = MSD.ReferenceId
			AND JBD.ManagementStructureId = MSD.EntityMSID AND MSD.ModuleId = @AccountMSModuleId
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL1 WITH(NOLOCK) ON MSD.Level1Id = MSL1.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL2 WITH(NOLOCK) ON MSD.Level2Id = MSL2.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL3 WITH(NOLOCK) ON MSD.Level3Id = MSL3.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL4 WITH(NOLOCK) ON MSD.Level4Id = MSL4.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL5 WITH(NOLOCK) ON MSD.Level5Id = MSL5.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL6 WITH(NOLOCK) ON MSD.Level6Id = MSL6.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL7 WITH(NOLOCK) ON MSD.Level7Id = MSL7.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL8 WITH(NOLOCK) ON MSD.Level8Id = MSL8.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL9 WITH(NOLOCK) ON MSD.Level9Id = MSL9.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL10 WITH(NOLOCK) ON MSD.Level10Id = MSL10.ID
		WHERE LBD.LeaseHeaderId = @LeaseHeaderId
		ORDER BY BD.JournalTypeNumber DESC, JBD.CommonJournalBatchDetailId ASC;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseAccountingDetailsViewById'
			, @ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100)) + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			@DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END