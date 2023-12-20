/*************************************************************           
 ** File:   [USP_DeleteRestoireLegalEntityBanking]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Add Level 1 Values to Mamagment Structure.    
 ** Purpose:         
 ** Date:   10/17/2022       
          
 ** PARAMETERS:           
 @LegalEntityId BIGINT   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    10/17/2022   Subhash Saliya Created
     
-- EXEC [[USP_DeleteRestoireLegalEntityBanking]] 1
**************************************************************/

CReate   PROCEDURE [dbo].[USP_DeleteRestoireLegalEntityBanking]
@ReferenceId BIGINT,
@UpdatedBy varchar(100),
@TableName varchar(100),
@IsDeleted bit
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

				if(UPPER(@TableName) ='LEGALENTITYINTERNATIONALWIREBANKING')
				begin

				update LegalEntityInternationalWireBanking set IsDeleted=@IsDeleted  where LegalEntityInternationalWireBankingId =@ReferenceId
				End

				if(UPPER(@TableName) ='ACH')
				begin

				update ACH set IsDeleted=@IsDeleted  where ACHId =@ReferenceId
				End

				if(UPPER(@TableName) ='LEGALENTITYBANKINGLOCKBOX')
				begin

				update LegalEntityBankingLockBox set IsDeleted=@IsDeleted  where LegalEntityBankingLockBoxId =@ReferenceId
				End


				
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_DeleteRestoireLegalEntityBanking' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReferenceId, '') + ''
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