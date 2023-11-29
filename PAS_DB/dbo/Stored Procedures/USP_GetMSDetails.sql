

/*************************************************************           
 ** File:   [USP_GetMSDetails]           
 ** Author:   Hemant Saliya
 ** Description: This SP is Used to Retrive Managment Structure Level Details By Master Company
 ** Purpose:         
 ** Date:   02/17/2022        
          
 ** PARAMETERS:           
 @MasterCompanyId BIGINT   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/17/2022   Hemant Saliya Created
     
 EXECUTE USP_GetMSDetails 2

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetMSDetails]    
(    
@MasterCompanyId INT
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  

					SELECT DISTINCT 
						MST.SequenceNo LevelId,
						MSL.ID [Value],
						CAST(MSL.Code AS VARCHAR(50)) + ' - ' + MSL.[Description] [Label]	
					FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK)  
					JOIN dbo.ManagementStructureType MST WITH (NOLOCK) ON MSL.TypeID = MST.TypeID
					WHERE MSL.MasterCompanyId = @MasterCompanyId AND MST.MasterCompanyId = @MasterCompanyId AND MSL.IsActive = 1 AND MSL.IsDeleted = 0
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetMSDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END