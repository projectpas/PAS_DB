/*************************************************************           
 ** File:   [GetJournalBatchDetailsById]           
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used GetJournalBatchDetailsById
 ** Purpose:         
 ** Date:   08/10/2022      
          
 ** PARAMETERS: @JournalBatchHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/10/2022  Subhash Saliya     Created
     
--EXEC GetJournalBatchDetailsById 27,0,'SOI'
************************************************************************/
CREATE PROCEDURE [dbo].[GetJournalBatchDetailsById]
@JournalBatchHeaderId bigint,
@IsDeleted bit,
@Module varchar(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		IF(UPPER(@Module) = UPPER('WO'))
			BEGIN
				DECLARE @WOModuleID INT = 12;

				SELECT   JBD.[JournalBatchDetailId]
                 ,JBH.[JournalBatchHeaderId]
				 ,JBH.[BatchName]
                 ,[LineNumber]
                 ,JBD.[GlAccountId]
                 ,[GlAccountNumber]
                 ,[GlAccountName]
                 ,[TransactionDate]
                 ,JBD.[EntryDate]
                 ,WBD.[ReferenceId]
                 ,WBD.[ReferenceName]
                 ,WBD.[MPNPartId]
                 ,WBD.[MPNName]
                 ,WBD.[PiecePNId]
                 ,WBD.[PiecePN]
                 ,JBD.[JournalTypeId]
                 ,JBD.[JournalTypeName]
                 ,[IsDebit]
                 ,[DebitAmount]
                 ,[CreditAmount]
                 ,WBD.[CustomerId]
                 ,WBD.[CustomerName]
                 ,WBD.[InvoiceId]
                 ,WBD.[InvoiceName]
                 ,WBD.[ARControlNum]
                 ,WBD.[CustRefNumber]
                 ,[ManagementStructureId]
                 ,[ModuleName]
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
				 ,JBD.JournalTypeNumber,JBD.CurrentNumber
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
				 FROM [dbo].[BatchDetails] JBD WITH(NOLOCK)
				 Inner JOIN BatchHeader JBH WITH(NOLOCK) ON JBD.JournalBatchHeaderId=JBH.JournalBatchHeaderId
				 left JOIN WorkOrderBatchDetails WBD WITH(NOLOCK) ON JBD.JournalBatchDetailId=WBD.JournalBatchDetailId  
				 LEFT JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @WOModuleID AND MSD.ReferenceID = WBD.ReferenceId
				 left JOIN GLAccount GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId 
				 left JOIN EntityStructureSetup ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId
				 left JOIN ManagementStructureLevel msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID
				 left JOIN LegalEntity le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
				 where JBD.JournalBatchHeaderId =@JournalBatchHeaderId and JBD.IsDeleted=@IsDeleted
		END
		ELSE IF(UPPER(@Module) = UPPER('RPO') OR UPPER(@Module) = UPPER('RRO') OR UPPER(@Module) = UPPER('AST'))
			BEGIN
				--DECLARE @STKModuleID INT = 2;
				DECLARE @NONStockModuleID INT = 11;
	            DECLARE @ModuleID INT = 2;
				DECLARE @AssetModuleID varchar(500) ='42,43'

				SELECT   JBD.[JournalBatchDetailId]
                 ,JBH.[JournalBatchHeaderId]
				 ,JBH.[BatchName]
                 ,[LineNumber]
                 ,JBD.[GlAccountId]
                 ,[GlAccountNumber]
                 ,[GlAccountName]
                 ,[TransactionDate]
                 ,JBD.[EntryDate]
                 --,[ReferenceId]
                 --,[ReferenceName]
                 --,[MPNPartId]
                 --,[MPNName]
                 --,[PiecePNId]
                 --,[PiecePN]
                 ,JBD.[JournalTypeId]
                 ,JBD.[JournalTypeName]
                 ,[IsDebit]
                 ,[DebitAmount]
                 ,[CreditAmount]
                 --,[CustomerId]
                 --,[CustomerName]
                 --,[InvoiceId]
                 --,[InvoiceName]
                 --,[ARControlNum]
                 --,[CustRefNumber]
                 ,[ManagementStructureId]
                 ,[ModuleName]
                 --,[Qty]
                 --,[UnitPrice]
                 --,[LaborHrs]
                 --,[DirectLaborCost]
                 --,[OverheadCost]
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
				 ,stbd.VendorName
				 ,stbd.PONum
				 ,stbd.RONum
				 ,stbd.StocklineNumber
				 ,stbd.[Description]
				 ,stbd.Consignment
				 ,JBH.[Module]
				 ,MPNPartId = stbd.PartId
				 ,MPNName = stbd.PartNumber
				 ,'' as [DocumentNumber]
				 ,stbd.[SIte]
				 ,stbd.[Warehouse]
				 ,stbd.[Location]
				 ,stbd.[Bin]
				 ,stbd.[Shelf]
				 ,JBD.JournalTypeNumber,JBD.CurrentNumber
				 ,0 as [CustomerId],'' as [CustomerName],0 as [InvoiceId],'' as [InvoiceName],'' as [ARControlNum],'' as [CustRefNumber],0 as [ReferenceId],'' as [ReferenceName]
				  ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' then UPPER(MSD.Level1Name) 
				       WHEN UPPER(stbd.StockType)= 'NONSTOCK' then UPPER(NMSD.Level1Name) 
					   WHEN UPPER(stbd.StockType)= 'ASSET' then UPPER(AMSD.Level1Name) Else '' END  AS level1
				 ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' then UPPER(MSD.Level2Name) 
				       WHEN UPPER(stbd.StockType)= 'NONSTOCK' then UPPER(NMSD.Level2Name) 
					   WHEN UPPER(stbd.StockType)= 'ASSET' then UPPER(AMSD.Level2Name) Else '' END  AS level2
				 ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' then UPPER(MSD.Level3Name) 
				       WHEN UPPER(stbd.StockType)= 'NONSTOCK' then UPPER(NMSD.Level3Name) 
					   WHEN UPPER(stbd.StockType)= 'ASSET' then UPPER(AMSD.Level3Name) Else '' END  AS level3
				 ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' then UPPER(MSD.Level4Name) 
				       WHEN UPPER(stbd.StockType)= 'NONSTOCK' then UPPER(NMSD.Level4Name) 
					   WHEN UPPER(stbd.StockType)= 'ASSET' then UPPER(AMSD.Level4Name) Else '' END  AS level4
				,CASE WHEN UPPER(stbd.StockType)= 'STOCK' then UPPER(MSD.Level5Name) 
				       WHEN UPPER(stbd.StockType)= 'NONSTOCK' then UPPER(NMSD.Level5Name) 
					   WHEN UPPER(stbd.StockType)= 'ASSET' then UPPER(AMSD.Level5Name) Else '' END  AS level5
				 ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' then UPPER(MSD.Level6Name) 
				       WHEN UPPER(stbd.StockType)= 'NONSTOCK' then UPPER(NMSD.Level6Name) 
					   WHEN UPPER(stbd.StockType)= 'ASSET' then UPPER(AMSD.Level6Name) Else '' END  AS level6
				,CASE WHEN UPPER(stbd.StockType)= 'STOCK' then UPPER(MSD.Level7Name) 
				       WHEN UPPER(stbd.StockType)= 'NONSTOCK' then UPPER(NMSD.Level7Name) 
					   WHEN UPPER(stbd.StockType)= 'ASSET' then UPPER(AMSD.Level7Name) Else '' END  AS level7
				 ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' then UPPER(MSD.Level8Name) 
				       WHEN UPPER(stbd.StockType)= 'NONSTOCK' then UPPER(NMSD.Level8Name) 
					   WHEN UPPER(stbd.StockType)= 'ASSET' then UPPER(AMSD.Level8Name) Else '' END  AS level8
				,CASE WHEN UPPER(stbd.StockType)= 'STOCK' then UPPER(MSD.Level9Name) 
				       WHEN UPPER(stbd.StockType)= 'NONSTOCK' then UPPER(NMSD.Level9Name) 
					   WHEN UPPER(stbd.StockType)= 'ASSET' then UPPER(AMSD.Level9Name) Else '' END  AS level9
				 ,CASE WHEN UPPER(stbd.StockType)= 'STOCK' then UPPER(MSD.Level10Name) 
				       WHEN UPPER(stbd.StockType)= 'NONSTOCK' then UPPER(NMSD.Level10Name) 
					   WHEN UPPER(stbd.StockType)= 'ASSET' then UPPER(AMSD.Level10Name) Else '' END  AS level10

				 FROM [dbo].[BatchDetails] JBD WITH(NOLOCK)
				 Inner JOIN BatchHeader JBH WITH(NOLOCK) ON JBD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
				 left join StocklineBatchDetails stbd WITH(NOLOCK) ON JBD.JournalBatchDetailId = stbd.JournalBatchDetailId
				 LEFT JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stbd.StockLineId and UPPER(stbd.StockType)= 'STOCK'
				 LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
				 LEFT JOIN dbo.NonStocklineManagementStructureDetails NMSD WITH (NOLOCK) ON NMSD.ModuleID = @NONStockModuleID AND NMSD.ReferenceID = stbd.StockLineId and UPPER(stbd.StockType)= 'NONSTOCK'
				 LEFT JOIN dbo.EntityStructureSetup NES ON NES.EntityStructureId=NMSD.EntityMSID
				 LEFT JOIN dbo.AssetManagementStructureDetails AMSD WITH (NOLOCK) ON AMSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AssetModuleID,',')) AND AMSD.ReferenceID = stbd.StockLineId and UPPER(stbd.StockType)= 'ASSET'
				 LEFT JOIN dbo.EntityStructureSetup AES ON AES.EntityStructureId=AMSD.EntityMSID

				 left JOIN GLAccount GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId 
				 left JOIN EntityStructureSetup ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId
				 left JOIN ManagementStructureLevel msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID
				 left JOIN LegalEntity le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
				 where JBD.JournalBatchHeaderId =@JournalBatchHeaderId and JBD.IsDeleted=@IsDeleted
		END
		ELSE IF(UPPER(@Module) = UPPER('SOI'))
			BEGIN
				DECLARE @SOModuleID INT = 17;

				SELECT   JBD.[JournalBatchDetailId]
                 ,JBH.[JournalBatchHeaderId]
				 ,JBH.[BatchName]
                 ,[LineNumber]
                 ,JBD.[GlAccountId]
                 ,[GlAccountNumber]
                 ,[GlAccountName]
                 ,[TransactionDate]
                 ,JBD.[EntryDate]
                 ,SBD.SalesOrderID as [ReferenceId]
                 ,SBD.SalesOrderNumber as [ReferenceName]
                 ,SBD.PartId as [MPNPartId]
                 ,SBD.PartNumber as [MPNName]
                 --,SBD.[PiecePNId]
                 --,SBD.[PiecePN]
                 ,JBD.[JournalTypeId]
                 ,JBD.[JournalTypeName]
                 ,[IsDebit]
                 ,[DebitAmount]
                 ,[CreditAmount]
                 ,SBD.[CustomerId]
                 ,SBD.[CustomerName]
                 ,SBD.DocumentId as [InvoiceId]
                 ,SBD.DocumentNumber as [InvoiceName]
                 ,SBD.ARControlNumber as [ARControlNum]
                 ,SBD.CustomerRef as [CustRefNumber]
                 ,[ManagementStructureId]
                 ,[ModuleName]
                 --,WBD.[Qty]
                 --,WBD.[UnitPrice]
                 --,WBD.[LaborHrs]
                 --,WBD.[DirectLaborCost]
                 --,WBD.[OverheadCost]
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
				 ,JBD.JournalTypeNumber,JBD.CurrentNumber
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
				 FROM [dbo].[BatchDetails] JBD WITH(NOLOCK)
				 Inner JOIN BatchHeader JBH WITH(NOLOCK) ON JBD.JournalBatchHeaderId=JBH.JournalBatchHeaderId
				 left JOIN SalesOrderBatchDetails SBD WITH(NOLOCK) ON JBD.JournalBatchDetailId=SBD.JournalBatchDetailId  
				 LEFT JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOModuleID AND MSD.ReferenceID = SBD.SalesOrderId
				 left JOIN GLAccount GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId 
				 left JOIN EntityStructureSetup ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId
				 left JOIN ManagementStructureLevel msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID
				 left JOIN LegalEntity le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
				 where JBD.JournalBatchHeaderId =@JournalBatchHeaderId and JBD.IsDeleted=@IsDeleted
		END
		ELSE IF(UPPER(@Module) = UPPER('CRS'))
			BEGIN
				DECLARE @CPModuleID INT = 59;

				SELECT   JBD.[JournalBatchDetailId]
                 ,JBH.[JournalBatchHeaderId]
				 ,JBH.[BatchName]
                 ,[LineNumber]
                 ,JBD.[GlAccountId]
                 ,[GlAccountNumber]
                 ,[GlAccountName]
                 ,[TransactionDate]
                 ,JBD.[EntryDate]
                 ,SBD.ReferenceId as [ReferenceId]
                 ,SBD.ReferenceNumber as [ReferenceName]
				 ,SBD.ReferenceInvId as [ReferenceInvId]
                 ,SBD.ReferenceInvNumber as [ReferenceInvNumber]
				 ,SBD.PaymentId as [PaymentId]
                 --,SBD.PartId as [MPNPartId]
                 --,SBD.PartNumber as [MPNName]
                 --,SBD.[PiecePNId]
                 --,SBD.[PiecePN]
                 ,JBD.[JournalTypeId]
                 ,JBD.[JournalTypeName]
                 ,[IsDebit]
                 ,[DebitAmount]
                 ,[CreditAmount]
                 ,SBD.[CustomerId]
                 ,C.[Name] as [CustomerName]
                 ,SBD.DocumentId as [InvoiceId]
                 ,SBD.DocumentNumber as [InvoiceName]
                 ,SBD.ARControlNumber as [ARControlNum]
                 ,SBD.CustomerRef as [CustRefNumber]
                 ,JBD.[ManagementStructureId]
                 ,[ModuleName]
                 --,WBD.[Qty]
                 --,WBD.[UnitPrice]
                 --,WBD.[LaborHrs]
                 --,WBD.[DirectLaborCost]
                 --,WBD.[OverheadCost]
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
				 ,JBD.JournalTypeNumber,JBD.CurrentNumber
				 FROM [dbo].[BatchDetails] JBD WITH(NOLOCK)
				 Inner JOIN BatchHeader JBH WITH(NOLOCK) ON JBD.JournalBatchHeaderId=JBH.JournalBatchHeaderId
				 left JOIN CustomerReceiptBatchDetails SBD WITH(NOLOCK) ON JBD.JournalBatchDetailId=SBD.JournalBatchDetailId
				 LEFT JOIN dbo.CustomerManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @CPModuleID AND MSD.ReferenceID = SBD.ReferenceId
				 left JOIN Customer C WITH(NOLOCK) ON SBD.CustomerId=C.CustomerId
				 left JOIN GLAccount GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId 
				 left JOIN EntityStructureSetup ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId
				 left JOIN ManagementStructureLevel msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID
				 left JOIN LegalEntity le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
				 where JBD.JournalBatchHeaderId =@JournalBatchHeaderId and JBD.IsDeleted=@IsDeleted
		END
    END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetJournalBatchDetailsById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@JournalBatchHeaderId, '') + ''
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