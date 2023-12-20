-----------------------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [USP_GetTravelerSetupList]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Create Stockline ForCustomer RMA   
 ** Purpose:         
 ** Date:   01/03/2023        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/03/2023   Subhash Saliya		Created
     
-- EXEC [USP_GetTravelerSetupList] 44
**************************************************************/

CREATE       PROCEDURE [dbo].[USP_GetTraveler_Setup_TaskList]
 @Traveler_SetupId bigint,
 @IsDeleted bit=0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				SELECT [Traveler_Setup_TaskId]
                      ,[Traveler_SetupId]
                      ,[TaskId]
                      ,[TaskName]
                      ,[Notes]
                      ,[Sequence]
                      ,[MasterCompanyId]
                      ,[CreatedBy]
                      ,[UpdatedBy]
                      ,[CreatedDate]
                      ,[UpdatedDate]
                      ,[IsActive]
                      ,[IsDeleted]
					  ,TeardownTypeId
					  ,TeardownTypeName
                  FROM [dbo].[Traveler_Setup_Task]  where IsDeleted=@IsDeleted and Traveler_SetupId=@Traveler_SetupId 
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetTraveler_Setup_TaskList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@Traveler_SetupId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END