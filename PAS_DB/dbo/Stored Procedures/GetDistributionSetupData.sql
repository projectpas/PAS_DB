
/*************************************************************           
 ** File:   [GetDistributionSetupData]           
 ** Author:   Subhash Saliya
 ** Description: Get Data for GetDistributionSetupData
 ** Purpose:         
 ** Date:   09/08/2022    
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/08/2022   Subhash Saliya Created

     
 EXECUTE [GetDistributionSetupData] 1,1
**************************************************************/ 

create     PROCEDURE [dbo].[GetDistributionSetupData]
	@masterCompanyId bigint = null,
	@JournalTypeID bigint = null
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				Select	
					 [ID]
                    ,[Name]
                    ,[GlAccountId]
                    ,[GlAccountName]
                    ,[JournalTypeId]
                    ,[DistributionMasterId]
                    ,[IsDebit]
                    ,[DisplayNumber]
                    ,[MasterCompanyId]
                    ,[CreatedBy]
                    ,[UpdatedBy]
                    ,[IsActive]
                    ,[IsDeleted]
                    ,isnull(UpdatedDate,GETUTCDATE()) as UpdatedDate
                    ,isnull(CreatedDate,GETUTCDATE()) as CreatedDate
				FROM dbo.DistributionSetup  WITH(NOLOCK)
				WHERE  IsDeleted = 0 and MasterCompanyId = @masterCompanyId and JournalTypeId= @JournalTypeID  order by DisplayNumber ASC
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetDistributionSetupData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@masterCompanyId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
			            
END