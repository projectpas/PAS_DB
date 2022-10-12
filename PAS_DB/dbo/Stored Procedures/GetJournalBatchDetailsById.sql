
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
     
-- EXEC GetJournalBatchDetailsById 7,0
************************************************************************/
CREATE PROCEDURE [dbo].[GetJournalBatchDetailsById]
@JournalBatchHeaderId bigint,
@IsDeleted bit
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		SELECT   [JournalBatchDetailId]
                 ,JBH.[JournalBatchHeaderId]
				 ,JBH.[BatchName]
                 ,[LineNumber]
                 ,JBD.[GlAccountId]
                 ,[GlAccountNumber]
                 ,[GlAccountName]
                 ,[TransactionDate]
                 ,JBD.[EntryDate]
                 ,[ReferenceId]
                 ,[ReferenceName]
                 ,[MPNPartId]
                 ,[MPNName]
                 ,[PiecePNId]
                 ,[PiecePN]
                 ,JBD.[JournalTypeId]
                 ,JBD.[JournalTypeName]
                 ,[IsDebit]
                 ,[DebitAmount]
                 ,[CreditAmount]
                 ,[CustomerId]
                 ,[CustomerName]
                 ,[InvoiceId]
                 ,[InvoiceName]
                 ,[ARControlNum]
                 ,[CustRefNumber]
                 ,[ManagementStructureId]
                 ,[ModuleName]
                 ,[Qty]
                 ,[UnitPrice]
                 ,[LaborHrs]
                 ,[DirectLaborCost]
                 ,[OverheadCost]
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
      FROM [dbo].[BatchDetails] JBD WITH(NOLOCK)
	  Inner JOIN BatchHeader JBH WITH(NOLOCK) ON JBD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
	  left JOIN GLAccount GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId 
	  left JOIN EntityStructureSetup ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId
	  left JOIN ManagementStructureLevel msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID
	  left JOIN LegalEntity le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
	  where JBD.JournalBatchHeaderId =@JournalBatchHeaderId and JBD.IsDeleted=@IsDeleted


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