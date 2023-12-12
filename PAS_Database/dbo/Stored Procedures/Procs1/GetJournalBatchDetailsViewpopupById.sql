/*************************************************************             
 ** File:   [GetJournalBatchDetailsViewpopupById]             
 ** Author:  Subhash Saliya  
 ** Description: This stored procedure is used GetJournalBatchDetailsById  
 ** Purpose:           
 ** Date:   08/10/2022        
            
 ** PARAMETERS: @JournalBatchHeaderId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------		--------------------------------            
 1    08/10/2022  Subhash Saliya		 Created  
 2    14/07/2023  Devendra Shekh		 added new OR for module 'MSTK'  
 3    25/07/2023  AMIT GHEDIYA			 added new OR for module 'VRMA' (Vendor RMA Accounting)  
 4    07/08/2023  Moin Bloch			 added new module 'EXPS' (Exchange Parts Shipped)  
 5    08/08/2023  Moin Bloch			 added new module 'EXFB' (Fee Billing on Sales Order Exchanges)  
 6    09/08/2023  Moin Bloch			 added new module 'EXCR' (Sales Order Exchange - Core Returned)  
 7    10/08/2023  AMIT GHEDIYA			 added new OR for module 'CMDA' (Credit Memo Accounting)  
 8    14/08/2023  Moin Bloch			 added new module 'WRT,ACHT,CCP' VENDOR PAYMENTS
 9	  16/08/2023  Satish Gohil			 added new module RECRO and RECPO entry condition
 10   21/08/2023  Moin Bloch			 ADDED MS TABLE TO GET MS DETAILS DIRECT FROM NEWLY CREATED TABLE
 11   23/08/2023  Moin Bloch			 ADDED MS TABLE TO GET MS DETAILS DIRECT FROM NEWLY CREATED TABLE fOR CREDIT MEMO
 12   28/08/2023  Devendra Shekh		 added BatchStatus Join for JE Status
 13   30/08/2023  Moin Bloch			 ADDED MS TABLE TO GET MS DETAILS DIRECT FROM NEWLY CREATED TABLE fOR CREDIT MEMO
 14   15/09/2023  AMIT GHEDIYA			 Get SACM ms details for batch.
 15   25/09/2023  Nainshi Joshi			 Added GLAccountClassName.
 16   10/10/2023  Devendra Shekh		 Added new Module 'NPO'
 17   12/10/2023  AMIT GHEDIYA			 added new SADJ-QTY (Bulk Stockline Adj Accounting) 
 18   16/10/2023  AMIT GHEDIYA			 added new SADJ-UnitCost (Bulk Stockline Adj Accounting) 
 19   19/10/2023  Devendra Shekh		 Added new Module 'RFD'
 20   16/10/2023  AMIT GHEDIYA			 added new Bulk StockLine Adjustment INTERCOTRANS LE (Bulk Stockline Adj Accounting) 
 21   30/10/2023  Devendra Shekh	     added currency for NPO and RFD
 22   28/11/2023  Moin Bloch	         added Lot Number in WO , WOP-PartsIssued,SOI
 22   30/11/2023  Moin Bloch	         added Lot Number SOI
 23   01/12/2023  Moin Bloch	         added Lot Number EXPS
 24   06/12/2023  Moin Bloch	         added Lot Number in RPO,RRO 
   
 EXEC GetJournalBatchDetailsViewpopupById 1085,0,'EXPS'  

 EXEC GetJournalBatchDetailsViewpopupById 2534,0,'WOP-DirectLabor'  
  
************************************************************************/  
CREATE    PROCEDURE [dbo].[GetJournalBatchDetailsViewpopupById]  
@JournalBatchDetailId BIGINT,  
@IsDeleted bit,  
@Module varchar(50) 
AS  
BEGIN  
	 --SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	 --SET NOCOUNT ON;  
		 BEGIN TRY  
			IF(UPPER(@Module) = UPPER('WO') OR UPPER(@Module) = UPPER('WOP-PARTSISSUED') OR UPPER(@Module) = UPPER('SWOP-PARTSISSUED'))     
			BEGIN  
				DECLARE @WOModuleID INT = 12;
				DECLARE @STKLModuleID INT = 2; 
			  
				SELECT JBD.CommonJournalBatchDetailId
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName]  
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]  
					  ,WBD.[ReferenceId]  
					  ,WBD.[ReferenceName]  
					  ,WBD.[MPNPartId]  
				    --,WBD.[MPNName]  
					  ,WBD.[PiecePN] AS [MPNName] -- client Requirement change MPNName to PiecePN
					  ,WBD.[PiecePNId]  
					  ,WBD.[PiecePN]  					 
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]  
					  ,WBD.[CustomerId]  
					  ,WBD.[CustomerName]  
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
					  ,le.CompanyName AS LegalEntityName  
					  ,BD.JournalTypeNumber,BD.CurrentNumber  
					  ,WBD.StocklineId  
					  ,SL.StockLineNumber AS StocklineNumber  
					  ,'' AS ExpertiseName  
					  ,'' AS EmployeeName
					  ,BS.Name AS 'Status'
					  ,CASE WHEN UPPER(MSD.Level1Name) IS NOT NULL THEN UPPER(MSD.Level1Name) ELSE UPPER(SMSD.Level1Name) END AS level1    
					  ,CASE WHEN UPPER(MSD.Level2Name) IS NOT NULL THEN UPPER(MSD.Level2Name) ELSE UPPER(SMSD.Level2Name) END AS level2   
					  ,CASE WHEN UPPER(MSD.Level3Name) IS NOT NULL THEN UPPER(MSD.Level3Name) ELSE UPPER(SMSD.Level3Name) END AS level3   
					  ,CASE WHEN UPPER(MSD.Level4Name) IS NOT NULL THEN UPPER(MSD.Level4Name) ELSE UPPER(SMSD.Level4Name) END AS level4   
					  ,CASE WHEN UPPER(MSD.Level5Name) IS NOT NULL THEN UPPER(MSD.Level5Name) ELSE UPPER(SMSD.Level5Name) END AS level5   
					  ,CASE WHEN UPPER(MSD.Level6Name) IS NOT NULL THEN UPPER(MSD.Level6Name) ELSE UPPER(SMSD.Level6Name) END AS level6   
					  ,CASE WHEN UPPER(MSD.Level7Name) IS NOT NULL THEN UPPER(MSD.Level7Name) ELSE UPPER(SMSD.Level7Name) END AS level7   
					  ,CASE WHEN UPPER(MSD.Level8Name) IS NOT NULL THEN UPPER(MSD.Level8Name) ELSE UPPER(SMSD.Level8Name) END AS level8   
					  ,CASE WHEN UPPER(MSD.Level9Name) IS NOT NULL THEN UPPER(MSD.Level9Name) ELSE UPPER(SMSD.Level9Name) END AS level9   
					  ,CASE WHEN UPPER(MSD.Level10Name) IS NOT NULL THEN UPPER(MSD.Level10Name) ELSE UPPER(SMSD.Level10Name) END AS level10   
				      ,JBD.[LotNumber]
			   FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
					INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId    
					INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId    
					LEFT JOIN [dbo].[WorkOrderBatchDetails] WBD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId=WBD.CommonJournalBatchDetailId     
					LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOModuleID AND MSD.ReferenceID = WBD.MPNPartId AND WBD.IsWorkOrder = 1 	 
					LEFT JOIN [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @STKLModuleID AND SMSD.ReferenceID = WBD.StockLineId AND WBD.IsWorkOrder = 0 	       
					LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId  
					LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
					LEFT JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId=WBD.StocklineId   
					LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND JBD.[ManagementStructureId] = ESP.[EntityMSID]  
					LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID  
					LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
					LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
			   WHERE JBD.JournalBatchDetailId =@JournalBatchDetailId and JBD.IsDeleted=@IsDeleted  
			END  
			IF(UPPER(@Module) = UPPER('WOP-DIRECTLABOR'))  
			BEGIN  
				DECLARE @WOModuleIDM INT = 12;  
				DECLARE @WOPSTKLModuleID INT = 2; 
				  
				SELECT JBD.CommonJournalBatchDetailId
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName]  
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]  
					  ,WBD.[ReferenceId]  
					  ,WBD.[ReferenceName]  
					  ,WBD.[MPNPartId]  
					  ,WBD.[MPNName]  
					  ,WBD.[PiecePNId]  
					  ,WBD.[PiecePN]  
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]  
					  ,WBD.[CustomerId]  
					  ,WBD.[CustomerName]  
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
					  ,le.CompanyName AS LegalEntityName  
					  ,BD.JournalTypeNumber,BD.CurrentNumber  
					  ,WBD.StocklineId  
					  ,WBD.StocklineNumber  
					  ,CASE WHEN WBD.IsWorkOrder = 1 THEN EMPEX.[Description] ELSE EMPEL.[Description] END AS ExpertiseName  
					  ,CASE WHEN WBD.IsWorkOrder = 1 THEN EMPE.FirstName +' '+ EMPE.LastName ELSE EMPL.FirstName +' '+ EMPL.LastName END AS EmployeeName  
					  ,BS.Name AS 'Status' 
					  ,CASE WHEN UPPER(MSD.Level1Name) IS NOT NULL THEN UPPER(MSD.Level1Name) ELSE UPPER(SMSD.Level1Name) END AS level1    
					  ,CASE WHEN UPPER(MSD.Level2Name) IS NOT NULL THEN UPPER(MSD.Level2Name) ELSE UPPER(SMSD.Level2Name) END AS level2   
					  ,CASE WHEN UPPER(MSD.Level3Name) IS NOT NULL THEN UPPER(MSD.Level3Name) ELSE UPPER(SMSD.Level3Name) END AS level3   
					  ,CASE WHEN UPPER(MSD.Level4Name) IS NOT NULL THEN UPPER(MSD.Level4Name) ELSE UPPER(SMSD.Level4Name) END AS level4   
					  ,CASE WHEN UPPER(MSD.Level5Name) IS NOT NULL THEN UPPER(MSD.Level5Name) ELSE UPPER(SMSD.Level5Name) END AS level5   
					  ,CASE WHEN UPPER(MSD.Level6Name) IS NOT NULL THEN UPPER(MSD.Level6Name) ELSE UPPER(SMSD.Level6Name) END AS level6   
					  ,CASE WHEN UPPER(MSD.Level7Name) IS NOT NULL THEN UPPER(MSD.Level7Name) ELSE UPPER(SMSD.Level7Name) END AS level7   
					  ,CASE WHEN UPPER(MSD.Level8Name) IS NOT NULL THEN UPPER(MSD.Level8Name) ELSE UPPER(SMSD.Level8Name) END AS level8   
					  ,CASE WHEN UPPER(MSD.Level9Name) IS NOT NULL THEN UPPER(MSD.Level9Name) ELSE UPPER(SMSD.Level9Name) END AS level9   
					  ,CASE WHEN UPPER(MSD.Level10Name) IS NOT NULL THEN UPPER(MSD.Level10Name) ELSE UPPER(SMSD.Level10Name) END AS level10   
				      ,JBD.[LotNumber]
				 FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
						INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId    
						INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId    
						LEFT JOIN [dbo].[WorkOrderBatchDetails] WBD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId=WBD.CommonJournalBatchDetailId
						LEFT JOIN [dbo].[WorkOrderLabor] WOL WITH(NOLOCK) ON WOL.WorkOrderLaborId = WBD.PiecePNId AND  WBD.IsWorkOrder = 1
						LEFT JOIN [dbo].[SubWorkOrderLabor] SWOL WITH(NOLOCK) ON SWOL.SubWorkOrderLaborId = WBD.PiecePNId AND WBD.IsWorkOrder = 0	  
						LEFT JOIN [dbo].[EmployeeExpertise] EMPEX WITH(NOLOCK) ON EMPEX.EmployeeExpertiseId = WOL.ExpertiseId AND WBD.IsWorkOrder = 1 
						LEFT JOIN [dbo].[EmployeeExpertise] EMPEL WITH(NOLOCK) ON EMPEL.EmployeeExpertiseId = SWOL.ExpertiseId AND WBD.IsWorkOrder = 0   
						LEFT JOIN [dbo].[Employee] EMPE WITH(NOLOCK) ON EMPE.EmployeeId = WOL.EmployeeId AND WBD.IsWorkOrder = 1 	  
						LEFT JOIN [dbo].[Employee] EMPL WITH(NOLOCK) ON EMPL.EmployeeId = SWOL.EmployeeId AND WBD.IsWorkOrder = 0
						LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOModuleIDM AND MSD.ReferenceID = WBD.MPNPartId  AND WBD.IsWorkOrder = 1
						LEFT JOIN [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @WOPSTKLModuleID AND SMSD.ReferenceID = WBD.StockLineId AND WBD.IsWorkOrder = 0 	 
						LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
						LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
						LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND JBD.[ManagementStructureId] = ESP.[EntityMSID]
						LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID  
						LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
						LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
				WHERE JBD.JournalBatchDetailId =@JournalBatchDetailId AND JBD.IsDeleted = @IsDeleted  
			END  
			IF(UPPER(@Module) = UPPER('RPO') OR UPPER(@Module) = UPPER('RRO') OR UPPER(@Module) = UPPER('RECPO') OR UPPER(@Module) = UPPER('RECRO') OR UPPER(@Module) = UPPER('AST'))        
			BEGIN  
				DECLARE @NONStockModuleID INT = 11;  
				DECLARE @ModuleID INT = 2;  
				DECLARE @AssetModuleID varchar(500) ='42,43'  
				  
				SELECT JBD.CommonJournalBatchDetailId
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName] 
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]  
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]  
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]  
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
					  ,le.CompanyName AS LegalEntityName  
					  ,stbd.VendorName  
					  ,stbd.PONum  
					  ,stbd.RONum  
					  ,stbd.StocklineNumber  
					  ,stbd.[Description]  
					  ,stbd.Consignment  
					  ,JBH.[Module]  
					  ,MPNPartId = stbd.PartId  
					  ,MPNName = stbd.PartNumber  
					  ,'' AS [DocumentNumber]  
					  ,stbd.[SIte]  
					  ,stbd.[Warehouse]  
					  ,stbd.[Location]  
					  ,stbd.[Bin]  
					  ,stbd.[Shelf]  
					  ,BD.JournalTypeNumber
					  ,BD.CurrentNumber  
					  ,0 AS [CustomerId],'' AS [CustomerName],0 AS [InvoiceId],'' AS [InvoiceName],'' AS [ARControlNum],'' AS [CustRefNumber],0 AS [ReferenceId],'' AS [ReferenceName]  
					  ,BS.Name AS 'Status'
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level1Name)   
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level1Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level1Name) ELSE '' END AS level1  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level2Name)   	
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level2Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level2Name) ELSE '' END  AS level2  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level3Name)   	 
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level3Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level3Name) ELSE '' END  AS level3  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level4Name)   	 
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level4Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level4Name) ELSE '' END  AS level4  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level5Name)   	 
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level5Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level5Name) ELSE '' END  AS level5  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level6Name)   	 
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level6Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level6Name) ELSE '' END  AS level6  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level7Name)   	 
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level7Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level7Name) ELSE '' END  AS level7  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level8Name)   
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level8Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level8Name) ELSE '' END  AS level8  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level9Name)   
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level9Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level9Name) ELSE'' END  AS level9  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level10Name)   
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level10Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level10Name) ELSE '' END  AS level10  
					  ,JBD.[LotNumber]
				 FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
						INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
						INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId  
						INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
						LEFT JOIN [dbo].[StocklineBatchDetails] stbd WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = stbd.CommonJournalBatchDetailId  
						LEFT JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stbd.StockLineId AND UPPER(stbd.StockType)= 'STOCK'  
						--LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId=MSD.EntityMSID  
						LEFT JOIN [dbo].[NonStocklineManagementStructureDetails] NMSD WITH (NOLOCK) ON NMSD.ModuleID = @NONStockModuleID AND NMSD.ReferenceID = stbd.StockLineId and UPPER(stbd.StockType)= 'NONSTOCK'  
						--LEFT JOIN [dbo].[EntityStructureSetup] NES ON NES.EntityStructureId=NMSD.EntityMSID  
						LEFT JOIN [dbo].[AssetManagementStructureDetails] AMSD WITH (NOLOCK) ON AMSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AssetModuleID,',')) AND AMSD.ReferenceID = stbd.StockLineId and UPPER(stbd.StockType)= 'ASSET'  
						--LEFT JOIN [dbo].[EntityStructureSetup] AES ON AES.EntityStructureId=AMSD.EntityMSID  
						LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
						LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
						LEFT JOIN [dbo].[EntityStructureSetup] ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId  
						LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID  
						LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
						LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
				 WHERE JBD.JournalBatchDetailId = @JournalBatchDetailId and JBD.IsDeleted = @IsDeleted  
				 ORDER BY DS.DisplayNumber ASC;  
			END  			
			IF(UPPER(@Module) = UPPER('MSTK'))        
			BEGIN  
				DECLARE @NONStockModuleIDs INT = 11;  
				DECLARE @ModuleIDs INT = 2;  
				DECLARE @AssetModuleIDs varchar(500) ='42,43'  
				  
				SELECT JBD.CommonJournalBatchDetailId
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName] 
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]  
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]  
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]  
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
					  ,le.CompanyName AS LegalEntityName  
					  ,stbd.VendorName  
					  ,stbd.PONum  
					  ,stbd.RONum  
					  ,stbd.StocklineNumber  
					  ,stbd.[Description]  
					  ,stbd.Consignment  
					  ,JBH.[Module]  
					  ,MPNPartId = stbd.PartId  
					  ,MPNName = stbd.PartNumber  
					  ,'' AS [DocumentNumber]  
					  ,stbd.[SIte]  
					  ,stbd.[Warehouse]  
					  ,stbd.[Location]  
					  ,stbd.[Bin]  
					  ,stbd.[Shelf]  
					  ,BD.JournalTypeNumber
					  ,BD.CurrentNumber  
					  ,0 AS [CustomerId],'' AS [CustomerName],0 AS [InvoiceId],'' AS [InvoiceName],'' AS [ARControlNum],'' AS [CustRefNumber],0 AS [ReferenceId],'' AS [ReferenceName]  
					  ,BS.Name AS 'Status'
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level1Name)   
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level1Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level1Name) ELSE '' END AS level1  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level2Name)   	
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level2Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level2Name) ELSE '' END  AS level2  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level3Name)   	 
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level3Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level3Name) ELSE '' END  AS level3  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level4Name)   	 
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level4Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level4Name) ELSE '' END  AS level4  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level5Name)   	 
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level5Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level5Name) ELSE '' END  AS level5  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level6Name)   	 
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level6Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level6Name) ELSE '' END  AS level6  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level7Name)   	 
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level7Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level7Name) ELSE '' END  AS level7  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level8Name)   
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level8Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level8Name) ELSE '' END  AS level8  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level9Name)   
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level9Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level9Name) ELSE'' END  AS level9  
					  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' THEN UPPER(MSD.Level10Name)   
							WHEN UPPER(stbd.StockType)= 'NONSTOCK' THEN UPPER(NMSD.Level10Name)   
							WHEN UPPER(stbd.StockType)= 'ASSET' THEN UPPER(AMSD.Level10Name) ELSE '' END  AS level10  
					  
				 FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
						INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
						INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId  
						INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
						LEFT JOIN [dbo].[StocklineBatchDetails] stbd WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = stbd.CommonJournalBatchDetailId  
						LEFT JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleIDs AND MSD.ReferenceID = stbd.StockLineId AND UPPER(stbd.StockType)= 'STOCK'  
						LEFT JOIN [dbo].[NonStocklineManagementStructureDetails] NMSD WITH (NOLOCK) ON NMSD.ModuleID = @NONStockModuleIDs AND NMSD.ReferenceID = stbd.StockLineId and UPPER(stbd.StockType)= 'NONSTOCK'  
						LEFT JOIN [dbo].[AssetManagementStructureDetails] AMSD WITH (NOLOCK) ON AMSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AssetModuleIDs,',')) AND AMSD.ReferenceID = stbd.StockLineId and UPPER(stbd.StockType)= 'ASSET'  
						LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
						LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
						LEFT JOIN [dbo].[EntityStructureSetup] ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId  
						LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID  
						LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
						LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
				 WHERE JBD.JournalBatchDetailId = @JournalBatchDetailId and JBD.IsDeleted = @IsDeleted  
				 ORDER BY DS.DisplayNumber ASC;  
			END  
			IF((UPPER(@Module) = UPPER('VRMACS')) OR (UPPER(@Module) = UPPER('VRMAPR')) OR (UPPER(@Module) = UPPER('VRMACA')))  
			BEGIN  
				DECLARE @STKModuleID INT = 2;  
			  
				SELECT JBD.CommonJournalBatchDetailId
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName]  
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]           
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]           
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]           
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
					  ,le.CompanyName AS LegalEntityName          
					  ,VDR.VendorName AS [VendorName]  
					  ,'' AS PONum  
					  ,'' AS RONum  
					  ,'' AS StocklineNumber  
					  ,'' AS [Description]  
					  ,'' AS Consignment  
					  ,JBH.[Module]  
					  ,0 AS PartId               --,MPNPartId = stbd.PartId  
					  ,'' AS PartNumber          --,MPNName = stbd.PartNumber  
					  ,'' AS [DocumentNumber]  
					  ,'' AS [SIte]  
					  ,'' AS [Warehouse]  
					  ,'' AS [Location]  
					  ,'' AS [Bin]  
					  ,'' AS [Shelf]  
					  ,BD.JournalTypeNumber
					  ,BD.CurrentNumber  
					  ,0 AS [CustomerId],'' AS [CustomerName],0 AS [InvoiceId],'' AS [InvoiceName],'' AS [ARControlNum],'' AS [CustRefNumber],0 AS [ReferenceId],'' AS [ReferenceName]  
					  ,BS.Name AS 'Status'
					  ,UPPER(SMSD.Level1Name) AS level1,    
					   UPPER(SMSD.Level2Name) AS level2,   
					   UPPER(SMSD.Level3Name) AS level3,   
					   UPPER(SMSD.Level4Name) AS level4,   
					   UPPER(SMSD.Level5Name) AS level5,   
					   UPPER(SMSD.Level6Name) AS level6,   
					   UPPER(SMSD.Level7Name) AS level7,   
					   UPPER(SMSD.Level8Name) AS level8,   
					   UPPER(SMSD.Level9Name) AS level9,   
					   UPPER(SMSD.Level10Name) AS level10 
				 FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
						INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
						INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId  
						INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
						LEFT JOIN [dbo].[VendorRMAPaymentBatchDetails] stbd WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = stbd.CommonJournalBatchDetailId  
						LEFT JOIN [dbo].[Vendor] VDR WITH(NOLOCK) ON VDR.VendorId = stbd.VendorId  	 	 
						LEFT JOIN [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @STKModuleID AND SMSD.ReferenceID = stbd.StockLineId 
						--LEFT JOIN [dbo].[EntityStructureSetup] SES ON SES.EntityStructureId = SMSD.EntityMSID  	  
						LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
						LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
						--LEFT JOIN [dbo].[EntityStructureSetup] ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId  
						LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND JBD.[ManagementStructureId] = ESP.[EntityMSID]
						LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID  
						LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
						LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
				 WHERE JBD.JournalBatchDetailId = @JournalBatchDetailId AND JBD.IsDeleted = @IsDeleted  
				 ORDER BY DS.DisplayNumber ASC;  
			END      
			IF(UPPER(@Module) = UPPER('SOI'))  
			BEGIN  
				DECLARE @SOModuleID INT = 17;  
			  
				SELECT JBD.CommonJournalBatchDetailId
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName]
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]  
					  ,SBD.SalesOrderID AS [ReferenceId]  
					  ,SBD.SalesOrderNumber AS [ReferenceName]  
					  ,SBD.PartId AS [MPNPartId]  
					  ,SBD.PartNumber AS [MPNName]  
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]  
					  ,SBD.[CustomerId]  
					  ,SBD.[CustomerName]  
					  ,SBD.DocumentId AS [InvoiceId]  
					  ,SBD.DocumentNumber AS [InvoiceName]  
					  ,SBD.ARControlNumber AS [ARControlNum]  
					  ,SBD.CustomerRef AS [CustRefNumber]  
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]  
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
					  ,le.CompanyName AS LegalEntityName  
					  ,BD.JournalTypeNumber,BD.CurrentNumber  
					  ,BS.Name AS 'Status'
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
					INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
					INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId    
					INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId    
					LEFT JOIN [dbo].[SalesOrderBatchDetails] SBD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId=SBD.CommonJournalBatchDetailId    
					LEFT JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOModuleID AND MSD.ReferenceID = SBD.SalesOrderId  
					LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
					LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
					LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND JBD.[ManagementStructureId] = ESP.[EntityMSID]
					LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID  
					LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
					LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
				WHERE JBD.JournalBatchDetailId = @JournalBatchDetailId AND JBD.IsDeleted = @IsDeleted  
				ORDER BY DS.DisplayNumber ASC;  
			END  
			IF(UPPER(@Module) = UPPER('CRS'))  
			BEGIN  
				DECLARE @CPModuleID INT = 59;  
				  
				SELECT JBD.CommonJournalBatchDetailId
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName]  
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]  
					  ,SBD.ReferenceId AS [ReferenceId]  
					  ,SBD.ReferenceNumber AS [ReferenceName]  
					  ,SBD.ReferenceInvId AS [ReferenceInvId]  
					  ,SBD.ReferenceInvNumber AS [ReferenceInvNumber]  
					  ,SBD.PaymentId AS [PaymentId]  
					  ,JBD.[JournalTypeId]  
					  ,(JBD.[JournalTypeName] +' - '+ UPPER(SBD.[ReferenceNumber])) as JournalTypeName  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]  
					  ,SBD.[CustomerId]  
					  ,SBD.CustomerName AS [CustomerName]  
					  ,SBD.DocumentId AS [InvoiceId]  
					  ,SBD.DocumentNumber AS [InvoiceName]  
					  ,SBD.ARControlNumber AS [ARControlNum]  
					  ,SBD.CustomerRef AS [CustRefNumber]  
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]  
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
					  ,le.CompanyName AS LegalEntityName  
					  ,BD.JournalTypeNumber,BD.CurrentNumber  
					  ,BS.Name AS 'Status'
					  ,UPPER(MSD.Level1Name) AS level1,    
					   UPPER(MSD.Level2Name) AS level2,   
					   UPPER(MSD.Level3Name) AS level3,   
					   UPPER(MSD.Level4Name) AS level4,   
					   UPPER(MSD.Level5Name) AS level5,   
					   UPPER(MSD.Level6Name) AS level6,   
					   UPPER(MSD.Level7Name) AS level7,   
					   UPPER(MSD.Level8Name) AS level8,   
					   UPPER(MSD.Level9Name) AS level9,   
					   UPPER(MSD.Level10Name) AS level10   
			   FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
					INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
					INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId    
					INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId    
					LEFT JOIN [dbo].[CustomerReceiptBatchDetails] SBD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId=SBD.CommonJournalBatchDetailId  
					LEFT JOIN [dbo].[CustomerManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CPModuleID AND MSD.ReferenceID = SBD.ReferenceId  
					LEFT JOIN [dbo].[Customer] C WITH(NOLOCK) ON SBD.CustomerId=C.CustomerId  
					LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId  
					LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
					LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND JBD.[ManagementStructureId] = ESP.[EntityMSID]
					LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID  
					LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
					LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
				WHERE JBD.JournalBatchDetailId =@JournalBatchDetailId AND JBD.IsDeleted = @IsDeleted  
			END  
			IF(UPPER(@Module) = UPPER('CKS')  OR UPPER(@Module) = UPPER('WRT') OR UPPER(@Module) = UPPER('ACHT') OR UPPER(@Module) = UPPER('CCP'))  
			BEGIN  
				SET @CPModuleID = 63 
			  
				SELECT JBD.CommonJournalBatchDetailId
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName]  
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]  
					  ,SBD.ReferenceId AS [ReferenceId]  
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName] AS JournalTypeName  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]  
					  ,SBD.[VendorId]  
					  ,V.VendorName AS [VendorName]  
					  ,SBD.DocumentNo AS [DocumentNumber]  
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]  
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
					  ,le.CompanyName AS LegalEntityName  
					  ,BD.JournalTypeNumber,BD.CurrentNumber  
					  ,BS.Name AS 'Status'
					  ,UPPER(MSD.Level1Name) AS level1,    
					   UPPER(MSD.Level2Name) AS level2,   
					   UPPER(MSD.Level3Name) AS level3,   
					   UPPER(MSD.Level4Name) AS level4,   
					   UPPER(MSD.Level5Name) AS level5,   
					   UPPER(MSD.Level6Name) AS level6,   
					   UPPER(MSD.Level7Name) AS level7,   
					   UPPER(MSD.Level8Name) AS level8,   
					   UPPER(MSD.Level9Name) AS level9,   
					   UPPER(MSD.Level10Name) AS level10   
			   FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
					INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId    
					INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId    
					LEFT JOIN [dbo].[VendorPaymentBatchDetails] SBD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId=SBD.CommonJournalBatchDetailId  
					LEFT JOIN [dbo].[AccountingManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CPModuleID AND MSD.ReferenceID = SBD.ReferenceId  
					LEFT JOIN [dbo].[Vendor] V WITH(NOLOCK) ON SBD.VendorId=V.VendorId  
					LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
					LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
					LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND JBD.[ManagementStructureId] = ESP.[EntityMSID]
					LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID  
					LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
					LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
				WHERE JBD.JournalBatchDetailId =@JournalBatchDetailId AND JBD.IsDeleted = @IsDeleted  
			END  
			IF(UPPER(@Module) = UPPER('EXPS') OR UPPER(@Module) = UPPER('EXFB') OR UPPER(@Module) = UPPER('EXCR'))  
			BEGIN  
				DECLARE @EXSOHeaderMSModuleId BIGINT;  
				SELECT @EXSOHeaderMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WHERE [ModuleName] = 'ExchangeSOHeader';  
			      
				SELECT JBD.CommonJournalBatchDetailId  
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName]  
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]  
					  ,SBD.[ExchangeSalesOrderId] AS [ReferenceId]  
					  ,SBD.[ExchangeSalesOrderNumber] AS [ReferenceName]  
					  ,SBD.[ItemMasterId] AS [MPNPartId]  
					  ,ITM.[partnumber] AS [MPNName]                  
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]  
					  ,SBD.[CustomerId]  
					  ,CST.[Name] AS CustomerName  
					  ,SBD.[InvoiceId] AS [InvoiceId]  
					  ,SBD.[InvoiceNo] AS [InvoiceName]  
					  ,'' AS [ARControlNum]  
					  ,SBD.CustomerReference AS [CustRefNumber]  
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]                 
					  ,JBD.[MasterCompanyId]  
					  ,JBD.[CreatedBy]  
					  ,JBD.[UpdatedBy]  
					  ,JBD.[CreatedDate]  
					  ,JBD.[UpdatedDate]  
					  ,JBD.[IsActive]  
					  ,JBD.[IsDeleted]  
					  ,GLA.[AllowManualJE]  
					  ,JBD.[LastMSLevel]  
					  ,JBD.[AllMSlevels]  
					  ,JBD.[IsManualEntry]  
					  ,JBD.[DistributionSetupId]  
					  ,JBD.[DistributionName]  
					  ,LET.[CompanyName] AS LegalEntityName  
					  ,BTD.[JournalTypeNumber]  
					  ,BTD.[CurrentNumber]  
					  ,BS.Name AS 'Status'
					  ,UPPER(MSD.[Level1Name]) AS level1    
					  ,UPPER(MSD.[Level2Name]) AS level2   
					  ,UPPER(MSD.[Level3Name]) AS level3   
					  ,UPPER(MSD.[Level4Name]) AS level4   
					  ,UPPER(MSD.[Level5Name]) AS level5   
					  ,UPPER(MSD.[Level6Name]) AS level6   
					  ,UPPER(MSD.[Level7Name]) AS level7   
					  ,UPPER(MSD.[Level8Name]) AS level8   
					  ,UPPER(MSD.[Level9Name]) AS level9   
					  ,UPPER(MSD.[Level10Name]) AS level10 
					  ,JBD.[LotNumber]
				FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
					 INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.[DistributionSetupId] = DS.[ID]  
					 INNER JOIN [dbo].[BatchDetails] BTD WITH(NOLOCK) ON JBD.[JournalBatchDetailId] = BTD.[JournalBatchDetailId]    
					 INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BTD.[JournalBatchHeaderId] = JBH.[JournalBatchHeaderId]       
					 LEFT JOIN [dbo].[ExchangeBatchDetails] SBD WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = SBD.[CommonJournalBatchDetailId]  
					 LEFT JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON SBD.[ItemMasterId] = ITM.[ItemMasterId]  
					 LEFT JOIN [dbo].[Customer] CST WITH(NOLOCK) ON SBD.[CustomerId] = CST.[CustomerId]  
					 LEFT JOIN [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.[ModuleID] = @EXSOHeaderMSModuleId AND MSD.[ReferenceID] = SBD.ExchangeSalesOrderId        
					 LEFT JOIN [dbo].[GLAccount] GLA WITH(NOLOCK) ON GLA.[GLAccountId] = JBD.[GLAccountId]	
					 LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GLA.GLAccountTypeId 
					 LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] --AND JBD.[ManagementStructureId] = ESP.[EntityMSID]  
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.[Level1Id] = msl.[ID]  
					 LEFT JOIN [dbo].[LegalEntity] LET WITH(NOLOCK) ON msl.[LegalEntityId] = LET.[LegalEntityId]  
					 LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BTD.StatusId = BS.Id
				WHERE JBD.[JournalBatchDetailId] = @JournalBatchDetailId AND JBD.[IsDeleted] = @IsDeleted ORDER BY DS.[DisplayNumber] ASC;  
			END  
			IF(UPPER(@Module) = UPPER('CMDA'))  
			BEGIN  
				DECLARE @SOBModuleId BIGINT;  
				DECLARE @WOBModuleId BIGINT;  
				DECLARE @IsStandAloneCM BIGINT; 
				DECLARE @SACMModuleId BIGINT;
				--PRINT 'CMDA'

				SELECT @WOBModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName ='WorkOrderMPN';
				SELECT @SOBModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName ='SalesOrder';
				SELECT @SACMModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName ='StandAloneCreditMemoDetails';

				--Check is from Stand alone CM.
				SELECT TOP 1  @IsStandAloneCM = CM.StandAloneCreditMemoDetailId FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)
				LEFT JOIN [dbo].[CreditMemoPaymentBatchDetails] SBD WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = SBD.[CommonJournalBatchDetailId] 
				LEFT JOIN [dbo].[StandAloneCreditMemoDetails] CM WITH (NOLOCK) ON SBD.[ReferenceId] = CM.[StandAloneCreditMemoDetailId]
				WHERE JBD.[JournalBatchDetailId] = @JournalBatchDetailId AND JBD.[IsDeleted] = 0;

				IF(@IsStandAloneCM IS NOT NULL)
				BEGIN
					SELECT JBD.CommonJournalBatchDetailId  
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName] 
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]  
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]  
					  ,'' AS [ARControlNum]  
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]                 
					  ,JBD.[MasterCompanyId]  
					  ,JBD.[CreatedBy]  
					  ,JBD.[UpdatedBy]  
					  ,JBD.[CreatedDate]  
					  ,JBD.[UpdatedDate]  
					  ,JBD.[IsActive]  
					  ,JBD.[IsDeleted]  
					  ,GLA.[AllowManualJE]  
					  ,JBD.[LastMSLevel]  
					  ,JBD.[AllMSlevels]  
					  ,JBD.[IsManualEntry]  
					  ,JBD.[DistributionSetupId]  
					  ,JBD.[DistributionName]  
					  ,LET.[CompanyName] AS LegalEntityName  
					  ,BTD.[JournalTypeNumber]  
					  ,BTD.[CurrentNumber]  
					  ,BS.Name AS 'Status',
					  UPPER(MSD.Level1Name) AS level1, 
					  UPPER(MSD.Level2Name) AS level2,
					  UPPER(MSD.Level3Name) AS level3,
					  UPPER(MSD.Level4Name) AS level4,
					  UPPER(MSD.Level5Name) AS level5,
					  UPPER(MSD.Level6Name) AS level6,
					  UPPER(MSD.Level7Name) AS level7,
					  UPPER(MSD.Level8Name) AS level8,
					  UPPER(MSD.Level9Name) AS level9,
					  UPPER(MSD.Level10Name) AS level10
					FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
						 INNER JOIN [dbo].[BatchDetails] BTD WITH(NOLOCK) ON JBD.[JournalBatchDetailId] = BTD.[JournalBatchDetailId]    
						 INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BTD.[JournalBatchHeaderId] = JBH.[JournalBatchHeaderId]       
						 LEFT JOIN [dbo].[CreditMemoPaymentBatchDetails] SBD WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = SBD.[CommonJournalBatchDetailId] 
						 LEFT JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.[ModuleID] = @SACMModuleId AND SBD.[ReferenceId] = MSD.[ReferenceID]
						 LEFT JOIN [dbo].[GLAccount] GLA WITH(NOLOCK) ON GLA.[GLAccountId] = JBD.[GLAccountId]  
						 LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GLA.GLAccountTypeId 
						 LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND JBD.[ManagementStructureId] = ESP.[EntityMSID]
						 LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.[Level1Id] = msl.[ID]  
						 LEFT JOIN [dbo].[LegalEntity] LET WITH(NOLOCK) ON msl.[LegalEntityId] = LET.[LegalEntityId] 
						 LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BTD.StatusId = BS.Id
					WHERE JBD.[JournalBatchDetailId] = @JournalBatchDetailId AND JBD.[IsDeleted] = 0;
				END
				ELSE
				BEGIN
					SELECT JBD.CommonJournalBatchDetailId  
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName]  
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]  
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]  
					  ,'' AS [ARControlNum]  
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]                 
					  ,JBD.[MasterCompanyId]  
					  ,JBD.[CreatedBy]  
					  ,JBD.[UpdatedBy]  
					  ,JBD.[CreatedDate]  
					  ,JBD.[UpdatedDate]  
					  ,JBD.[IsActive]  
					  ,JBD.[IsDeleted]  
					  ,GLA.[AllowManualJE]  
					  ,JBD.[LastMSLevel]  
					  ,JBD.[AllMSlevels]  
					  ,JBD.[IsManualEntry]  
					  ,JBD.[DistributionSetupId]  
					  ,JBD.[DistributionName]  
					  ,LET.[CompanyName] AS LegalEntityName  
					  ,BTD.[JournalTypeNumber]  
					  ,BTD.[CurrentNumber]  
					  ,BS.Name AS 'Status'
					  ,CASE WHEN UPPER(SMSD.Level1Name) IS NOT NULL THEN UPPER(SMSD.Level1Name) ELSE UPPER(WMSD.Level1Name) END AS level1    
					  ,CASE WHEN UPPER(SMSD.Level2Name) IS NOT NULL THEN UPPER(SMSD.Level2Name) ELSE UPPER(WMSD.Level2Name) END AS level2   
					  ,CASE WHEN UPPER(SMSD.Level3Name) IS NOT NULL THEN UPPER(SMSD.Level3Name) ELSE UPPER(WMSD.Level3Name) END AS level3   
					  ,CASE WHEN UPPER(SMSD.Level4Name) IS NOT NULL THEN UPPER(SMSD.Level4Name) ELSE UPPER(WMSD.Level4Name) END AS level4   
					  ,CASE WHEN UPPER(SMSD.Level5Name) IS NOT NULL THEN UPPER(SMSD.Level5Name) ELSE UPPER(WMSD.Level5Name) END AS level5   
					  ,CASE WHEN UPPER(SMSD.Level6Name) IS NOT NULL THEN UPPER(SMSD.Level6Name) ELSE UPPER(WMSD.Level6Name) END AS level6   
					  ,CASE WHEN UPPER(SMSD.Level7Name) IS NOT NULL THEN UPPER(SMSD.Level7Name) ELSE UPPER(WMSD.Level7Name) END AS level7   
					  ,CASE WHEN UPPER(SMSD.Level8Name) IS NOT NULL THEN UPPER(SMSD.Level8Name) ELSE UPPER(WMSD.Level8Name) END AS level8   
					  ,CASE WHEN UPPER(SMSD.Level9Name) IS NOT NULL THEN UPPER(SMSD.Level9Name) ELSE UPPER(WMSD.Level9Name) END AS level9   
					  ,CASE WHEN UPPER(SMSD.Level10Name) IS NOT NULL THEN UPPER(SMSD.Level10Name) ELSE UPPER(WMSD.Level10Name) END AS level10   
				 FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
				 INNER JOIN [dbo].[BatchDetails] BTD WITH(NOLOCK) ON JBD.[JournalBatchDetailId] = BTD.[JournalBatchDetailId]    
				 INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BTD.[JournalBatchHeaderId] = JBH.[JournalBatchHeaderId]       
				  LEFT JOIN [dbo].[CreditMemoPaymentBatchDetails] SBD WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = SBD.[CommonJournalBatchDetailId] 
				  LEFT JOIN [dbo].[SalesOrderManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.[ModuleID] = @SOBModuleId AND  SMSD.[ReferenceID] = SBD.[InvoiceReferenceId]
				  LEFT JOIN [dbo].[workOrderManagementStructureDetails] WMSD WITH (NOLOCK) ON  WMSD.[ModuleID] = @WOBModuleId AND WMSD.[ReferenceID] = SBD.[InvoiceReferenceId]     
				  LEFT JOIN [dbo].[GLAccount] GLA WITH(NOLOCK) ON GLA.[GLAccountId] = JBD.[GLAccountId]  
				  LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GLA.GLAccountTypeId 
				  --LEFT JOIN [dbo].[EntityStructureSetup] ESP WITH(NOLOCK) ON JBD.[ManagementStructureId] = ESP.[EntityStructureId]  
				  LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND JBD.[ManagementStructureId] = ESP.[EntityMSID]
				  LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.[Level1Id] = msl.[ID]  
				  LEFT JOIN [dbo].[LegalEntity] LET WITH(NOLOCK) ON msl.[LegalEntityId] = LET.[LegalEntityId] 
				  LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BTD.StatusId = BS.Id
				  WHERE JBD.[JournalBatchDetailId] = @JournalBatchDetailId AND JBD.[IsDeleted] = @IsDeleted;  
				END
			END  
			IF(UPPER(@Module) = UPPER('YEP'))
			BEGIN
				--PRINT 'YEP'
				SELECT JBD.CommonJournalBatchDetailId
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName]  
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]  
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]  
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]  
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
					  ,BD.[JournalTypeNumber]  
					  ,BD.[CurrentNumber] 
					  ,le.CompanyName AS LegalEntityName  
					  ,BS.Name AS 'Status'
					  ,UPPER(msl1.[Description]) AS level1    
					  ,UPPER(msl2.[Description]) AS level2   
					  ,UPPER(msl3.[Description]) AS level3   
					  ,UPPER(msl4.[Description]) AS level4   
					  ,UPPER(msl5.[Description]) AS level5   
					  ,UPPER(msl6.[Description]) AS level6   
					  ,UPPER(msl7.[Description]) AS level7   
					  ,UPPER(msl8.[Description]) AS level8   
					  ,UPPER(msl9.[Description]) AS level9   
					  ,UPPER(msl10.[Description]) AS level10  
				 FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
					 INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
					 INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId  
					 INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
					 LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
					 LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
					 LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] AMS WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = AMS.[ReferenceId] AND
						JBD.[ManagementStructureId] = JBD.ManagementStructureId
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl1 WITH(NOLOCK) ON AMS.Level1Id = msl1.ID
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl2 WITH(NOLOCK) ON AMS.Level2Id = msl2.ID 
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl3 WITH(NOLOCK) ON AMS.Level3Id = msl3.ID 
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl4 WITH(NOLOCK) ON AMS.Level4Id = msl4.ID 
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl5 WITH(NOLOCK) ON AMS.Level5Id = msl5.ID 
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl6 WITH(NOLOCK) ON AMS.Level6Id = msl6.ID 
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl7 WITH(NOLOCK) ON AMS.Level7Id = msl7.ID 
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl8 WITH(NOLOCK) ON AMS.Level8Id = msl8.ID 
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl9 WITH(NOLOCK) ON AMS.Level9Id = msl9.ID 
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl10 WITH(NOLOCK) ON AMS.Level10Id = msl10.ID 
					 LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl1.LegalEntityId = le.LegalEntityId 
					 LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
				 WHERE JBD.JournalBatchDetailId = @JournalBatchDetailId and JBD.IsDeleted = @IsDeleted  
				 ORDER BY DS.DisplayNumber ASC;  
			END
			IF(UPPER(@Module) = UPPER('NPO'))
			BEGIN
				DECLARE @NPOModuleId BIGINT = 0, @NonPOInvoiceId BIGINT = 0, @CurrencyId BIGINT = 0 ;
				SELECT @NPOModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName ='NonPOInvoiceHeader';
				SET @NonPOInvoiceId = (SELECT TOP 1 NonPOInvoiceId FROM [dbo].[NonPOInvoiceBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId = @JournalBatchDetailId)

				SELECT JBD.CommonJournalBatchDetailId
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName]  
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]  
					  ,NPD.[NonPOInvoiceId] AS 'ReferenceId'
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]  
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]  
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
					  ,BD.[JournalTypeNumber]  
					  ,BD.[CurrentNumber] 
					  ,le.CompanyName AS LegalEntityName  
					  ,BS.Name AS 'Status'
					  ,UPPER(NPOMSD.Level1Name) AS level1    
					  ,UPPER(NPOMSD.Level2Name) AS level2   
					  ,UPPER(NPOMSD.Level3Name) AS level3   
					  ,UPPER(NPOMSD.Level4Name) AS level4   
					  ,UPPER(NPOMSD.Level5Name) AS level5   
					  ,UPPER(NPOMSD.Level6Name) AS level6   
					  ,UPPER(NPOMSD.Level7Name) AS level7   
					  ,UPPER(NPOMSD.Level8Name) AS level8   
					  ,UPPER(NPOMSD.Level9Name) AS level9   
					  ,UPPER(NPOMSD.Level10Name) AS level10   
					  ,CU.[Code] AS 'Currency'
				 FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
					INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
					INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId  
					INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
					LEFT JOIN [dbo].[NonPOInvoiceBatchDetails] NPD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = NPD.CommonJournalBatchDetailId  
					LEFT JOIN [dbo].[NonPOInvoiceManagementStructureDetails] NPOMSD WITH (NOLOCK) ON NPOMSD.[ModuleID] = @NPOModuleId AND  NPOMSD.[ReferenceID] = NPD.[NonPOInvoiceId]
					LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
					LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
					LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] AMS WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = AMS.[ReferenceId] AND JBD.[ManagementStructureId] = JBD.ManagementStructureId
					LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON AMS.[Level1Id] = msl.[ID]
					LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId 
					LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
					LEFT JOIN [dbo].[Currency] CU WITH(NOLOCK) ON CU.CurrencyId = @CurrencyId
				WHERE JBD.JournalBatchDetailId = @JournalBatchDetailId and JBD.IsDeleted = @IsDeleted  
				ORDER BY DS.DisplayNumber ASC;  
			END
			IF(UPPER(@Module) = UPPER('SADJ-QTY') OR UPPER(@Module) = UPPER('SADJ-UNITCOST'))  
			BEGIN  
				DECLARE @blkSTKModuleID INT = 2; 
				DECLARE @ManagementStructureModuleId BIGINT = 0;   
				--PRINT 'SADJ-QTY'

				SELECT @ManagementStructureModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName='EmployeeGeneralInfo';
  
				SELECT JBD.CommonJournalBatchDetailId
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName]  
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]           
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]           
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]           
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
					  ,le.CompanyName AS LegalEntityName          
					  ,STKL.PartNumber
					  ,STKL.StockLineNumber
					  ,'' AS PONum  
					  ,'' AS RONum  
					  ,'' AS StocklineNumber  
					  ,'' AS [Description]  
					  ,'' AS Consignment  
					  ,JBH.[Module]  
					  ,0 AS PartId               
					  ,'' AS PartNumber         
					  ,'' AS [DocumentNumber]  
					  ,'' AS [SIte]  
					  ,'' AS [Warehouse]  
					  ,'' AS [Location]  
					  ,'' AS [Bin]  
					  ,'' AS [Shelf]  
					  ,BD.JournalTypeNumber
					  ,BD.CurrentNumber  
					  ,0 AS [CustomerId],'' AS [CustomerName],0 AS [InvoiceId],'' AS [InvoiceName],'' AS [ARControlNum],'' AS [CustRefNumber],0 AS [ReferenceId],'' AS [ReferenceName]  
					  ,BS.Name AS 'Status'
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level1Name) ELSE UPPER(EMSD.Level1Name) END AS level1  
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level2Name) ELSE UPPER(EMSD.Level2Name) END AS level2   
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level3Name) ELSE UPPER(EMSD.Level3Name) END AS level3  
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level4Name) ELSE UPPER(EMSD.Level4Name) END AS level4 
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level5Name) ELSE UPPER(EMSD.Level5Name) END AS level5 
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level6Name) ELSE UPPER(EMSD.Level6Name) END AS level6 
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level7Name) ELSE UPPER(EMSD.Level7Name) END AS level7 
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level8Name) ELSE UPPER(EMSD.Level8Name) END AS level8 
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level9Name) ELSE UPPER(EMSD.Level9Name) END AS level9 
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level10Name) ELSE UPPER(EMSD.Level10Name) END AS level10 
				 FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
					 INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
					 INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId  
					 INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
					 LEFT JOIN [dbo].[BulkStocklineAdjPaymentBatchDetails] stbd WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = stbd.CommonJournalBatchDetailId 
					 LEFT JOIN [dbo].[Stockline] STKL WITH(NOLOCK) ON STKL.StockLineId = stbd.StockLineId  	 	 
					 LEFT JOIN [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @blkSTKModuleID AND SMSD.ReferenceID = stbd.StockLineId 
					 LEFT JOIN [dbo].[EmployeeManagementStructureDetails] EMSD WITH (NOLOCK) ON EMSD.ReferenceID = stbd.EmployeeId AND EMSD.EntityMSID = stbd.ManagementStructureId AND EMSD.ModuleID = @ManagementStructureModuleId
					 LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
					 LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
					 LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND JBD.[ManagementStructureId] = ESP.[EntityMSID]
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID  
					 LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
					 LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
				 WHERE JBD.JournalBatchDetailId = @JournalBatchDetailId AND JBD.IsDeleted = @IsDeleted  
				 ORDER BY DS.DisplayNumber ASC;  
			END 
			IF(UPPER(@Module) = UPPER('SADJ-INTERCOTRANS-LE') OR UPPER(@Module) = UPPER('SADJ-INTRACOTRANS-DIV'))  
			BEGIN  
				DECLARE @blkSTKLEModuleID INT = 2; 
				DECLARE @ManagementStructureModuleLEId BIGINT = 0;   
				--PRINT 'SADJ-QTY'

				SELECT @ManagementStructureModuleLEId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName='EmployeeGeneralInfo';
  
				SELECT JBD.CommonJournalBatchDetailId
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName]  
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]           
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]           
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]           
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
					  ,le.CompanyName AS LegalEntityName          
					  ,STKL.PartNumber
					  ,STKL.StockLineNumber
					  ,'' AS PONum  
					  ,'' AS RONum  
					  ,'' AS StocklineNumber  
					  ,'' AS [Description]  
					  ,'' AS Consignment  
					  ,JBH.[Module]  
					  ,0 AS PartId               
					  ,'' AS PartNumber         
					  ,'' AS [DocumentNumber]  
					  ,'' AS [SIte]  
					  ,'' AS [Warehouse]  
					  ,'' AS [Location]  
					  ,'' AS [Bin]  
					  ,'' AS [Shelf]  
					  ,BD.JournalTypeNumber
					  ,BD.CurrentNumber  
					  ,0 AS [CustomerId],'' AS [CustomerName],0 AS [InvoiceId],'' AS [InvoiceName],'' AS [ARControlNum],'' AS [CustRefNumber],0 AS [ReferenceId],'' AS [ReferenceName]  
					  ,BS.Name AS 'Status'
					  ,ESS.Level1Id,UPPER(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description]) AS Level1,
					ESS.Level2Id,UPPER(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description]) AS Level2,
					ESS.Level3Id,UPPER(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description]) AS Level3,
					ESS.Level4Id,UPPER(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description]) AS Level4,
					ESS.Level5Id,UPPER(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description]) AS Level5,
					ESS.Level6Id,UPPER(CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description]) AS Level6,
					ESS.Level7Id,UPPER(CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description]) AS Level7,
					ESS.Level8Id,UPPER(CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description]) AS Level8,
					ESS.Level9Id,UPPER(CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description]) AS Level9,
					ESS.Level10Id,UPPER(CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description]) AS Level10
				 FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
					 INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
					 INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId  
					 INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
					 LEFT JOIN [dbo].[BulkStocklineAdjPaymentBatchDetails] stbd WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = stbd.CommonJournalBatchDetailId 
					 LEFT JOIN [dbo].[Stockline] STKL WITH(NOLOCK) ON STKL.StockLineId = stbd.StockLineId  	 	 
					 --LEFT JOIN [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @blkSTKLEModuleID AND SMSD.ReferenceID = stbd.StockLineId 
					 --LEFT JOIN [dbo].[EmployeeManagementStructureDetails] EMSD WITH (NOLOCK) ON EMSD.ReferenceID = stbd.EmployeeId AND EMSD.EntityMSID = stbd.ManagementStructureId AND EMSD.ModuleID = @ManagementStructureModuleLEId
					-- LEFT JOIN [dbo].[ManagementStructureDetails] EMSD WITH (NOLOCK) ON stbd.ManagementStructureId = EMSD.[MSDetailsId]
					LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON stbd.ManagementStructureId = ESS.[EntityStructureId]
					 LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
					LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON ESS.Level2Id = MSL2.ID
					LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON ESS.Level3Id = MSL3.ID
					LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON ESS.Level4Id = MSL4.ID
					LEFT JOIN dbo.ManagementStructureLevel MSL5 WITH (NOLOCK) ON ESS.Level5Id = MSL5.ID
					LEFT JOIN dbo.ManagementStructureLevel MSL6 WITH (NOLOCK) ON ESS.Level6Id = MSL6.ID
					LEFT JOIN dbo.ManagementStructureLevel MSL7 WITH (NOLOCK) ON ESS.Level7Id = MSL7.ID
					LEFT JOIN dbo.ManagementStructureLevel MSL8 WITH (NOLOCK) ON ESS.Level8Id = MSL8.ID
					LEFT JOIN dbo.ManagementStructureLevel MSL9 WITH (NOLOCK) ON ESS.Level9Id = MSL9.ID
					LEFT JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON ESS.Level10Id = MSL10.ID
					 LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
					 LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
					 LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND JBD.[ManagementStructureId] = ESP.[EntityMSID]
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID  
					 LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
					 LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
				 WHERE JBD.JournalBatchDetailId = @JournalBatchDetailId AND JBD.IsDeleted = @IsDeleted  
				 ORDER BY DS.DisplayNumber ASC;  
			END 
			IF(UPPER(@Module) = UPPER('RFD'))
			BEGIN

				DECLARE @RfdModuleId BIGINT = (SELECT ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'CustomerRefund')
				DECLARE @RfdMsModuleId BIGINT = (SELECT ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'CustomerRefund')
				--PRINT 'RFD'

				SELECT JBD.CommonJournalBatchDetailId
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName]  
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]  
					  ,CMBD.[ReferenceId]
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]  
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]  
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
					  ,BD.[JournalTypeNumber]  
					  ,BD.[CurrentNumber] 
					  ,le.CompanyName AS LegalEntityName  
					  ,BS.Name AS 'Status'
					  ,'' AS [Currency]
					  ,UPPER(MSD.Level1Name) AS level1    
					  ,UPPER(MSD.Level2Name) AS level2   
					  ,UPPER(MSD.Level3Name) AS level3   
					  ,UPPER(MSD.Level4Name) AS level4   
					  ,UPPER(MSD.Level5Name) AS level5   
					  ,UPPER(MSD.Level6Name) AS level6   
					  ,UPPER(MSD.Level7Name) AS level7   
					  ,UPPER(MSD.Level8Name) AS level8   
					  ,UPPER(MSD.Level9Name) AS level9   
					  ,UPPER(MSD.Level10Name) AS level10   
				 FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
					INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
					INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId  
					INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
					LEFT JOIN [dbo].[CreditMemoPaymentBatchDetails] CMBD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = CMBD.CommonJournalBatchDetailId AND CMBD.ModuleId = @RfdModuleId
					LEFT JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.[ModuleID] = @RfdMsModuleId AND CMBD.[ReferenceId] = MSD.[ReferenceID]
					LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
					LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
					LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] AMS WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = AMS.[ReferenceId] AND JBD.[ManagementStructureId] = JBD.ManagementStructureId
					LEFT JOIN [dbo].[ManagementStructureLevel] msl1 WITH(NOLOCK) ON AMS.Level1Id = msl1.ID
					LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl1.LegalEntityId = le.LegalEntityId 
					LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
					WHERE JBD.JournalBatchDetailId = @JournalBatchDetailId and JBD.IsDeleted = @IsDeleted  
					ORDER BY DS.DisplayNumber ASC;  
		  END

    END TRY  
 BEGIN CATCH        
  --IF @@trancount > 0  
   --PRINT 'ROLLBACK'  
   --ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetJournalBatchDetailsViewpopupById'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@JournalBatchDetailId, '') + ''  
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