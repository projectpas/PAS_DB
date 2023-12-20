
/*************************************************************           
 ** File: [InsertCreditMemoApprovedParts]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to insert approval parts on  fulfilled status  
 ** Purpose:         
 ** Date:   14/05/2022    
          
 ** PARAMETERS: @@CreditMemoHeaderId bigint,@ApprovedById bigint,@ApprovedByName varchar(100),@MasterCompanyId int
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    14/05/2022   Moin Bloch     Created
     
-- EXEC [InsertCreditMemoApprovedParts] 2,15,'moin bloch',2
************************************************************************/

CREATE PROCEDURE InsertCreditMemoApprovedParts
@CreditMemoHeaderId bigint,
@ApprovedById bigint,
@ApprovedByName varchar(100),
@MasterCompanyId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.[CreditMemoApproval] WITH(NOLOCK) WHERE [CreditMemoHeaderId] = @CreditMemoHeaderId)
		BEGIN
		INSERT INTO [dbo].[CreditMemoApproval]([CreditMemoHeaderId],[CreditMemoDetailId],[Memo],[SentDate],[ApprovedDate],[ApprovedById],
											   [ApprovedByName],[InternalSentToId],[InternalSentToName],[InternalSentById],[RejectedDate],
											   [RejectedBy],[RejectedByName],[StatusId],[StatusName],[ActionId],[MasterCompanyId],
											   [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
								        SELECT [CreditMemoHeaderId],[CreditMemoDetailId],'',GETDATE(),GETDATE(),@ApprovedById,
								               @ApprovedByName,NULL,NULL,NULL,NULL,
									           NULL,NULL,2,'Approved',5,@MasterCompanyId,
									           [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],1,0
								          FROM dbo.[CreditMemoDetails] WITH(NOLOCK) WHERE CreditMemoHeaderId=@CreditMemoHeaderId;  
		END
	END
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'InsertCreditMemoApprovedParts' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@CreditMemoHeaderId, '') AS varchar(100))
													+ '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) 
													+ '@Parameter3 = ''' + CAST(ISNULL(@ApprovedByName, '') AS varchar(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW---------------------------------------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END