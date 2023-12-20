
/*************************************************************           
 ** File:   [USP_GetMSEntityStructureDetailsById]           
 ** Author:   Hemant Saliya
 ** Description: This SP is Used to Retruve Entity Structure Details By ID
 ** Purpose:         
 ** Date:   03/23/2021        
          
 ** PARAMETERS:           
 @EntityStructureId BIGINT   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/23/2021   Hemant Saliya Created
     
 EXECUTE USP_GetMSEntityStructureDetailsById 49

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetMSEntityStructureDetailsById]    
(    
@EntityStructureId BIGINT = NULL  
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  

					SELECT DISTINCT 
						ES.EntityStructureId,
						ES.Level1Id,
						ES.Level2Id,
						ES.Level3Id,
						ES.Level4Id,
						ES.Level5d,
						ES.Level6Id,
						ES.Level7Id,
						ES.Level8Id,
						ES.Level9Id,
						ES.Level10Id						
					FROM dbo.EntityStructureId ES WITH (NOLOCK)  
					WHERE ES.EntityStructureId = @EntityStructureId
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetMSEntityStructureDetailsById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EntityStructureId, '') + ''
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