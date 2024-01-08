/*************************************************************             
 ** File:   [GetJournalBatchHeaderById]             
 ** Author:  Subhash Saliya  
 ** Description: This stored procedure is used to GetJournalBatchHeaderById  
 ** Purpose:           
 ** Date:   08/10/2022        
            
 ** PARAMETERS: @JournalBatchHeaderId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    08/10/2022  Subhash Saliya     Created  
	2	 18/10/2023	 Nainshi Joshi		Add [PostedBy] field
	3	 04/01/2024	 Moin Bloch		    Added [AccountingPeriodId] field
	4    08/01/2024  Moin Bloch         Added [isaccStatusName],[isacrStatusName],[isassetStatusName],[isinventoryStatusName] Field
       
-- EXEC GetJournalBatchHeaderById 1520  
************************************************************************/  
CREATE     PROCEDURE [dbo].[GetJournalBatchHeaderById]  
@JournalBatchHeaderId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
		DECLARE @BatchType VARCHAR(50) = ''
		DECLARE @isaccStatusName BIT = 0,@isacrStatusName BIT = 0,@isacpStatusName BIT = 0,@isassetStatusName BIT = 0,@isinventoryStatusName BIT = 0;
		
		SELECT TOP 1 @BatchType = JT.[BatchType]
		   FROM [dbo].[CommonBatchDetails] CB WITH(NOLOCK) 
		   JOIN [dbo].[journaltype] JT WITH(NOLOCK) ON CB.JournalTypeId = JT.ID   
		   WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId

		IF(UPPER(@BatchType) = 'AR')
		BEGIN
			SET @isacrStatusName = 1;
		END
		ELSE IF(UPPER(@BatchType) = 'AP')
		BEGIN
			SET @isacpStatusName = 1;
		END
		ELSE IF(UPPER(@BatchType) = 'ASSET')
		BEGIN
			SET @isassetStatusName = 1;
		END
		ELSE IF(UPPER(@BatchType) = 'INV')
		BEGIN
			SET @isinventoryStatusName = 1;
		END
		ELSE IF(UPPER(@BatchType) = 'GEN')
		BEGIN
			SET @isaccStatusName = 1;
		END
			
		SELECT [JournalBatchHeaderId]  
              ,[BatchName]  
              ,[CurrentNumber]  
              ,[EntryDate]  
              ,[PostDate]  
              ,[AccountingPeriod]  
              ,[StatusId]  
              ,[StatusName]  
              ,[JournalTypeId]  
              ,[JournalTypeName]  
              ,[TotalDebit]  
              ,[TotalCredit]  
              ,[TotalBalance]  
              ,[MasterCompanyId]  
              ,[CreatedBy]  
              ,[UpdatedBy]  
              ,[CreatedDate]  
              ,[UpdatedDate]  
              ,[IsActive]  
              ,[IsDeleted]  
			  ,[Module] 
			  ,[PostedBy]
			  ,[AccountingPeriodId]
			  ,@isaccStatusName  AS isaccStatusName
			  ,@isacrStatusName AS isacrStatusName
			  ,@isacpStatusName AS isacpStatusName 
			  ,@isassetStatusName AS isassetStatusName
			  ,@isinventoryStatusName AS isinventoryStatusName			 
          FROM [dbo].[BatchHeader] WITH(NOLOCK) 
		 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;    
  
    END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetJournalBatchHeaderById'   
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