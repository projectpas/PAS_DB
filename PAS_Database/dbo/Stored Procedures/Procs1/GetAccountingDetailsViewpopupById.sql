﻿/*************************************************************           
 ** File:   [GetAccountingDetailsViewpopupById]
 ** Author:   
 ** Description: This stored procedure is used to Get AccountingDetailsViewpopupById
 ** Purpose:         
 ** Date:    
          
 ** PARAMETERS: @WorkOrderId bigint,@WorkOrderPartNumberId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    08/10/2022							Created
    2	 09/12/2023  Devendra Shekh			added case condition for ExpertiseName,EmployeeName
	3    03/10/2023  Bhargav Saliya         Employee duplicate Records issue Resolved
	4    20/10/2023  Bhargav Saliya         Export Data Convert Into Upper Case
	5    30/11/2023  Moin Bloch             Added Lot Number 

--EXEC [GetAccountingDetailsViewpopupById] 3577,3047

************************************************************************/

CREATE   PROCEDURE [dbo].[GetAccountingDetailsViewpopupById]    
@WorkOrderId bigint,    
@WorkOrderPartNumberId bigint    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY          

	DECLARE @WopJounralTypeid bigint=0;
	SELECT @WopJounralTypeid = ID FROM [dbo].[JournalType] WITH(NOLOCK)  WHERE JournalTypeCode = 'WIP' AND JournalTypeName = 'WIP-Parts Issued'

   BEGIN         
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
                 ,UPPER(JBD.[JournalTypeName]) AS [JournalTypeName]   
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
				 ,SL.StockLineNumber as StocklineNumber
				 ,CASE WHEN @WopJounralTypeid = JBD.[JournalTypeId] THEN '' ELSE EMPEX.Description END AS ExpertiseName
				 --,EMPEX.Description  as ExpertiseName  
				 --,EMPE.FirstName +' '+ EMPE.LastName as EmployeeName
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
				 JBD.[LotNumber]  
     FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)    
     INNER JOIN  [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId      
     INNER JOIN  [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId      
      LEFT JOIN  [dbo].[WorkOrderBatchDetails] WBD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId=WBD.CommonJournalBatchDetailId       
      LEFT JOIN  [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON  MSD.ReferenceID = WBD.MPNPartId
	  LEFT JOIN  [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId=WBD.StocklineId 
	  LEFT JOIN  [dbo].[WorkOrderWorkFlow] WF WITH(NOLOCK) ON WF.WorkOrderId=WBD.ReferenceId AND WF.WorkOrderPartNoId = WBD.MPNPartId
	  --LEFT JOIN  [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.WorkFlowWorkOrderId = WF.WorkFlowWorkOrderId 
	  --LEFT JOIN  [dbo].[WorkOrderMaterialStockLine] MSTL WITH(NOLOCK) ON MSTL.StockLineId=WBD.StocklineId AND WOM.WorkOrderMaterialsId = MSTL.WorkOrderMaterialsId
	  LEFT JOIN  [dbo].[WorkOrderLabor] WOL WITH(NOLOCK) ON WOL.WorkOrderLaborId=WBD.PiecePNId  
      LEFT JOIN  [dbo].[EmployeeExpertise] EMPEX WITH(NOLOCK) ON EMPEX.EmployeeExpertiseId=WOL.ExpertiseId   
      LEFT JOIN  [dbo].[Employee] EMPE WITH(NOLOCK) ON EMPE.EmployeeId=WOL.EmployeeId
      LEFT JOIN  [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId  
      LEFT JOIN  [dbo].[EntityStructureSetup] ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId    
      LEFT JOIN  [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID    
      LEFT JOIN  [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
	  LEFT JOIN  [dbo].[CustomerFinancial] CF WITH(NOLOCK) ON CF.CustomerId = WBD.CustomerId
	  LEFT JOIN  [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId
     WHERE WBD.ReferenceId=@WorkOrderId AND WBD.MPNPartId = @WorkOrderPartNumberId    
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