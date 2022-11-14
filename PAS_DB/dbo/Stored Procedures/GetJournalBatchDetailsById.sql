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
     
--EXEC GetJournalBatchDetailsById 27,0,'RPO'
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
				 FROM [dbo].[BatchDetails] JBD WITH(NOLOCK)
				 Inner JOIN BatchHeader JBH WITH(NOLOCK) ON JBD.JournalBatchHeaderId=JBH.JournalBatchHeaderId
				 left JOIN WorkOrderBatchDetails WBD WITH(NOLOCK) ON JBD.JournalBatchDetailId=WBD.JournalBatchDetailId  
				 left JOIN GLAccount GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId 
				 left JOIN EntityStructureSetup ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId
				 left JOIN ManagementStructureLevel msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID
				 left JOIN LegalEntity le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
				 where JBD.JournalBatchHeaderId =@JournalBatchHeaderId and JBD.IsDeleted=@IsDeleted
		END
		ELSE IF(UPPER(@Module) = UPPER('RPO') OR UPPER(@Module) = UPPER('RRO'))
			BEGIN
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
				 FROM [dbo].[BatchDetails] JBD WITH(NOLOCK)
				 Inner JOIN BatchHeader JBH WITH(NOLOCK) ON JBD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
				 left join StocklineBatchDetails stbd WITH(NOLOCK) ON JBD.JournalBatchDetailId = stbd.JournalBatchDetailId
				 left JOIN GLAccount GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId 
				 left JOIN EntityStructureSetup ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId
				 left JOIN ManagementStructureLevel msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID
				 left JOIN LegalEntity le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
				 where JBD.JournalBatchHeaderId =@JournalBatchHeaderId and JBD.IsDeleted=@IsDeleted
		END
		ELSE IF(UPPER(@Module) = UPPER('SOI'))
			BEGIN
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
				 FROM [dbo].[BatchDetails] JBD WITH(NOLOCK)
				 Inner JOIN BatchHeader JBH WITH(NOLOCK) ON JBD.JournalBatchHeaderId=JBH.JournalBatchHeaderId
				 left JOIN SalesOrderBatchDetails SBD WITH(NOLOCK) ON JBD.JournalBatchDetailId=SBD.JournalBatchDetailId  
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