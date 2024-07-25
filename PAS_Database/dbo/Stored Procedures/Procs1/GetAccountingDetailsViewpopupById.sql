
/***********************************************************************************************           
 ** File:   [GetAccountingDetailsViewpopupById]
 ** Author:   
 ** Description: This stored procedure is used to Get AccountingDetailsViewpopupById
 ** Purpose:         
 ** Date:    
          
 ** PARAMETERS: @WorkOrderId bigint,@WorkOrderPartNumberId bigint
         
 ** RETURN VALUE:           
 ***********************************************************************************************           
 ** Change History           
 ***********************************************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    08/10/2022							Created
    2	 09/12/2023  Devendra Shekh			added case condition for ExpertiseName,EmployeeName
	3    03/10/2023  Bhargav Saliya         Employee duplicate Records issue Resolved
	4    20/10/2023  Bhargav Saliya         Export Data Convert Into Upper Case
	5    30/11/2023  Moin Bloch             Added Lot Number 
	6    10/05/2024  Moin Bloch             Added IsUpdated
	7    16/05/2024  HEMANT SALITA          Updated for Reverse A/C Entry
	8    17/05/2024  Moin Bloch             Added Union For Invoice Entry
	9    15/07/2024  Sahdev Saliya          Added (AccountingPeriod)
	10   25/07/2024  Sahdev Saliya          Set JournalTypeNumber Order by desc

	10   25/07/2024  Moin Bloch             Added IsReversedJE
	
--EXEC [GetAccountingDetailsViewpopupById] 3949,3472

*************************************************************************************************/

CREATE   PROCEDURE [dbo].[GetAccountingDetailsViewpopupById]    
@WorkOrderId bigint,    
@WorkOrderPartNumberId bigint    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY          

	DECLARE @WopJounralTypeid BIGINT = 0;
	DECLARE @WOIJounralTypeid BIGINT = 0;
	SELECT @WopJounralTypeid = ID FROM [dbo].[JournalType] WITH(NOLOCK)  WHERE JournalTypeCode = 'WIP' AND JournalTypeName = 'WIP-Parts Issued'
	SELECT @WOIJounralTypeid = ID FROM [dbo].[JournalType] WITH(NOLOCK)  WHERE JournalTypeCode = 'WOI'

   BEGIN    
   SELECT * INTO #MyTempTableWO FROM
		(SELECT DISTINCT   
		          JBH.[BatchName]    
                 ,JBD.[LineNumber]    
                 ,JBD.[GlAccountId]    
                 ,JBD.[GlAccountNumber]    
                 ,UPPER(JBD.[GlAccountName]) AS [GlAccountName]
                 ,JBD.[TransactionDate]    
                 ,JBD.[EntryDate]    
                 ,WBD.[ReferenceId]    
                 ,WBD.[ReferenceName]    
                 ,WBD.[MPNPartId]    
                 ,WBD.[MPNName]    
                 ,WBD.[PiecePNId]    
                 ,WBD.[PiecePN]    
                 ,JBD.[JournalTypeId]    
				 ,CASE WHEN ISNULL(BD.IsReversedJE, 0) = 1 THEN UPPER(JBD.[JournalTypeName]) + ' (REVERSED)' ELSE UPPER(JBD.[JournalTypeName]) END  AS [JournalTypeName]   
                 ,JBD.[IsDebit]    
                 ,JBD.[DebitAmount]    
                 ,JBD.[CreditAmount]    
                 ,WBD.[CustomerId]    
                 ,UPPER(WBD.[CustomerName]) AS [CustomerName] 
                 ,WBD.[InvoiceId]    
                 ,WBD.[InvoiceName]    
                 ,WBD.[ARControlNum]    
                 ,WBD.[CustRefNumber]    
                 ,JBD.[ManagementStructureId]    
                 ,JBD.[ModuleName]    
                 ,WBD.[Qty]    
                 ,WBD.[UnitPrice]    
                 ,WBD.[LaborHrs]    
                 ,WBD.[DirectLaborCost]    
                 ,WBD.[OverheadCost]    
                 ,JBD.[MasterCompanyId]    
                 ,JBD.[CreatedBy]    
                 ,JBD.[UpdatedBy]    
                 ,JBD.[CreatedDate]    
                 ,JBD.[UpdatedDate]    
                 ,JBD.[IsActive]    
                 ,JBD.[IsDeleted]    
				 ,GL.AllowManualJE    
				 ,JBD.LastMSLevel    
				 ,JBD.AllMSlevels    
				 ,JBD.IsManualEntry    
				 ,jbd.DistributionSetupId    
				 ,jbd.DistributionName    
				 ,le.CompanyName as LegalEntityName    
				 ,BD.JournalTypeNumber,BD.CurrentNumber
				 ,WBD.StocklineId
				 ,BD.AccountingPeriod AS 'AcctingPeriod'
				 ,SL.StockLineNumber as StocklineNumber
				 ,CASE WHEN @WopJounralTypeid = JBD.[JournalTypeId] THEN '' ELSE EMPEX.Description END AS ExpertiseName
				 ,CASE WHEN @WopJounralTypeid = JBD.[JournalTypeId] THEN 
						  (SELECT TOP 1 UPPER(MSTL.[UpdatedBy]) AS [UpdatedBy] FROM [dbo].[WorkOrderMaterialStockLine] MSTL WITH(NOLOCK) 
								JOIN [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = MSTL.WorkOrderMaterialsId 
							WHERE MSTL.StockLineId = WBD.StocklineId AND WOM.WorkOrderId = WBD.ReferenceId)
				 ELSE (UPPER(EMPE.FirstName) +' '+ UPPER(EMPE.LastName)) END AS EmployeeName
				 ,CR.Code AS Currency 
				 ,UPPER(MSD.Level1Name) AS level1,      
			     UPPER(MSD.Level2Name) AS level2,     
			     UPPER(MSD.Level3Name) AS level3,     
			     UPPER(MSD.Level4Name) AS level4,     
			     UPPER(MSD.Level5Name) AS level5,     
			     UPPER(MSD.Level6Name) AS level6,     
			     UPPER(MSD.Level7Name) AS level7,     
			     UPPER(MSD.Level8Name) AS level8,     
			     UPPER(MSD.Level9Name) AS level9,     
			     UPPER(MSD.Level10Name) AS level10,     
				 JBD.[LotNumber],
				 CASE WHEN JBD.IsUpdated = 1 THEN 1 ELSE 0 END AS IsUpdated,
				 CASE WHEN BD.IsReversedJE = 1 THEN 1 ELSE 0 END AS IsReversedJE
     FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)    
		INNER JOIN  [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId      
		INNER JOIN  [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId      
		INNER JOIN  [dbo].[WorkOrderBatchDetails] WBD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId=WBD.CommonJournalBatchDetailId       
		LEFT JOIN  [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON  MSD.ReferenceID = WBD.MPNPartId
		LEFT JOIN  [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId=WBD.StocklineId 
		LEFT JOIN  [dbo].[WorkOrderWorkFlow] WF WITH(NOLOCK) ON WF.WorkOrderId=WBD.ReferenceId AND WF.WorkOrderPartNoId = WBD.MPNPartId
		LEFT JOIN  [dbo].[WorkOrderLabor] WOL WITH(NOLOCK) ON WOL.WorkOrderLaborId=WBD.PiecePNId  
		LEFT JOIN  [dbo].[EmployeeExpertise] EMPEX WITH(NOLOCK) ON EMPEX.EmployeeExpertiseId=WOL.ExpertiseId   
		LEFT JOIN  [dbo].[Employee] EMPE WITH(NOLOCK) ON EMPE.EmployeeId=WOL.EmployeeId
		LEFT JOIN  [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId  
		LEFT JOIN  [dbo].[EntityStructureSetup] ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId    
		LEFT JOIN  [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID    
		LEFT JOIN  [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
		LEFT JOIN  [dbo].[CustomerFinancial] CF WITH(NOLOCK) ON CF.CustomerId = WBD.CustomerId
		LEFT JOIN  [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId
      --WHERE WBD.ReferenceId = @WorkOrderId AND WBD.MPNPartId = @WorkOrderPartNumberId  
	    WHERE WBD.ReferenceId=@WorkOrderId AND WBD.MPNPartId = @WorkOrderPartNumberId AND ISNULL(WBD.InvoiceId ,0) = 0

	 UNION

	 SELECT    JBH.[BatchName]    
                 ,JBD.[LineNumber]    
                 ,JBD.[GlAccountId]    
                 ,JBD.[GlAccountNumber]    
                 ,UPPER(JBD.[GlAccountName]) AS [GlAccountName]
                 ,JBD.[TransactionDate]    
                 ,JBD.[EntryDate]    
                 ,WBD.[ReferenceId]    
                 ,WBD.[ReferenceName]    
                 ,WBD.[MPNPartId]    
                 ,WBD.[MPNName]    
                 ,WBD.[PiecePNId]    
                 ,WBD.[PiecePN]    
                 ,JBD.[JournalTypeId]    
				 ,CASE WHEN ISNULL(BD.IsReversedJE, 0) = 1 THEN UPPER(JBD.[JournalTypeName]) + ' (REVERSED)' ELSE UPPER(JBD.[JournalTypeName]) END  AS [JournalTypeName]   
                 ,JBD.[IsDebit]    
                 ,JBD.[DebitAmount]    
                 ,JBD.[CreditAmount]    
                 ,WBD.[CustomerId]    
                 ,UPPER(WBD.[CustomerName]) AS [CustomerName] 
                 ,WBD.[InvoiceId]    
                 ,WBD.[InvoiceName]    
                 ,WBD.[ARControlNum]    
                 ,WBD.[CustRefNumber]    
                 ,JBD.[ManagementStructureId]    
                 ,JBD.[ModuleName]    
                 ,WBD.[Qty]    
                 ,WBD.[UnitPrice]    
                 ,WBD.[LaborHrs]    
                 ,WBD.[DirectLaborCost]    
                 ,WBD.[OverheadCost]    
                 ,JBD.[MasterCompanyId]    
                 ,JBD.[CreatedBy]    
                 ,JBD.[UpdatedBy]    
                 ,JBD.[CreatedDate]    
                 ,JBD.[UpdatedDate]    
                 ,JBD.[IsActive]    
                 ,JBD.[IsDeleted]    
				 ,GL.AllowManualJE    
				 ,JBD.LastMSLevel    
				 ,JBD.AllMSlevels    
				 ,JBD.IsManualEntry    
				 ,jbd.DistributionSetupId    
				 ,jbd.DistributionName    
				 ,le.CompanyName as LegalEntityName    
				 ,BD.JournalTypeNumber,BD.CurrentNumber
				 ,WBD.StocklineId  
				 ,BD.AccountingPeriod AS 'AcctingPeriod'
				 ,SL.StockLineNumber as StocklineNumber
				 ,CASE WHEN @WopJounralTypeid = JBD.[JournalTypeId] THEN '' ELSE EMPEX.Description END AS ExpertiseName
				 ,CASE WHEN @WopJounralTypeid = JBD.[JournalTypeId] THEN 
						  (SELECT TOP 1 UPPER(MSTL.[UpdatedBy]) AS [UpdatedBy] FROM [dbo].[WorkOrderMaterialStockLine] MSTL WITH(NOLOCK) 
								JOIN [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = MSTL.WorkOrderMaterialsId 
							WHERE MSTL.StockLineId = WBD.StocklineId AND WOM.WorkOrderId = WBD.ReferenceId)
				 ELSE (UPPER(EMPE.FirstName) +' '+ UPPER(EMPE.LastName)) END AS EmployeeName
				 ,CR.Code AS Currency 
				 ,UPPER(MSD.Level1Name) AS level1,      
			     UPPER(MSD.Level2Name) AS level2,     
			     UPPER(MSD.Level3Name) AS level3,     
			     UPPER(MSD.Level4Name) AS level4,     
			     UPPER(MSD.Level5Name) AS level5,     
			     UPPER(MSD.Level6Name) AS level6,     
			     UPPER(MSD.Level7Name) AS level7,     
			     UPPER(MSD.Level8Name) AS level8,     
			     UPPER(MSD.Level9Name) AS level9,     
			     UPPER(MSD.Level10Name) AS level10,     
				 JBD.[LotNumber],
				 CASE WHEN JBD.IsUpdated = 1 THEN 1 ELSE 0 END AS IsUpdated,
				 CASE WHEN BD.IsReversedJE = 1 THEN 1 ELSE 0 END AS IsReversedJE
     FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)    
		INNER JOIN  [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId      
		INNER JOIN  [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId      
		INNER JOIN  [dbo].[WorkOrderBatchDetails] WBD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId=WBD.CommonJournalBatchDetailId       
		LEFT JOIN  [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON  MSD.ReferenceID = WBD.MPNPartId
		LEFT JOIN  [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId=WBD.StocklineId 
		LEFT JOIN  [dbo].[WorkOrderWorkFlow] WF WITH(NOLOCK) ON WF.WorkOrderId=WBD.ReferenceId AND WF.WorkOrderPartNoId = WBD.MPNPartId
		LEFT JOIN  [dbo].[WorkOrderLabor] WOL WITH(NOLOCK) ON WOL.WorkOrderLaborId=WBD.PiecePNId  
		LEFT JOIN  [dbo].[EmployeeExpertise] EMPEX WITH(NOLOCK) ON EMPEX.EmployeeExpertiseId=WOL.ExpertiseId   
		LEFT JOIN  [dbo].[Employee] EMPE WITH(NOLOCK) ON EMPE.EmployeeId=WOL.EmployeeId
		LEFT JOIN  [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId  
		LEFT JOIN  [dbo].[EntityStructureSetup] ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId    
		LEFT JOIN  [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID    
		LEFT JOIN  [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
		LEFT JOIN  [dbo].[CustomerFinancial] CF WITH(NOLOCK) ON CF.CustomerId = WBD.CustomerId
		LEFT JOIN  [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId
      --WHERE WBD.ReferenceId = @WorkOrderId AND WBD.MPNPartId = @WorkOrderPartNumberId    
	    WHERE WBD.[ReferenceId] = @WorkOrderId AND ISNULL(WBD.InvoiceId ,0) > 0) A

		SELECT   [BatchName],    
                 [LineNumber],    
                 [GlAccountId],    
                 [GlAccountNumber],    
                 [GlAccountName],
                 [TransactionDate],    
                 [EntryDate],    
                 [ReferenceId],    
                 [ReferenceName],    
                 [MPNPartId],    
                 [MPNName],    
                 [PiecePNId],    
                 [PiecePN],    
                 [JournalTypeId],    
				 [JournalTypeName],
                 [IsDebit],    
                 [DebitAmount],    
                 [CreditAmount],    
                 [CustomerId],    
                 [CustomerName], 
                 [InvoiceId],    
                 [InvoiceName],    
                 [ARControlNum],    
                 [CustRefNumber],    
                 [ManagementStructureId],    
                 [ModuleName],    
                 [Qty],    
                 [UnitPrice],    
                 [LaborHrs],    
                 [DirectLaborCost],    
                 [OverheadCost],    
                 [MasterCompanyId],    
                 [CreatedBy],    
                 [UpdatedBy],    
                 [CreatedDate],    
                 [UpdatedDate],    
                 [IsActive],    
                 [IsDeleted],    
				 AllowManualJE,    
				 LastMSLevel,    
				 AllMSlevels,    
				 IsManualEntry,    
				 DistributionSetupId,   
				 DistributionName,    
				 LegalEntityName,    
				 JournalTypeNumber,
				 CurrentNumber,
				 StocklineId, 
				 AcctingPeriod,
				 StockLineNumber, 
				 [JournalTypeId], 
				 ExpertiseName,
				 EmployeeName,
			     level1,      
			     level2,     
			     level3,     
			     level4,     
			     level5,     
			     level6,     
			     level7,     
			     level8,     
			     level9,     
			     level10,  
				 Currency,
				 [LotNumber],
				 IsUpdated
		FROM #MyTempTableWO
		order by JournalTypeNumber desc
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetAccountingDetailsViewpopupById'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''    
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