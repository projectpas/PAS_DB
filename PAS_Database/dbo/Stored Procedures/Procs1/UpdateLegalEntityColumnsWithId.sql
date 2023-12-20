
/*************************************************************           
 ** File:   [UpdateLegalEntityColumnsWithId]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Add Level 1 Values to Mamagment Structure.    
 ** Purpose:         
 ** Date:   02/17/2022        
          
 ** PARAMETERS:           
 @LegalEntityId BIGINT   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/17/2022   Hemant Saliya Created
     
-- EXEC [UpdateLegalEntityColumnsWithId] 1
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateLegalEntityColumnsWithId]
@LegalEntityId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @TypeID BIGINT;
				DECLARE @MasterCompanyId INT;

				SELECT @MasterCompanyId = MasterCompanyId FROM [dbo].[LegalEntity] LE WITH(NOLOCK) WHERE LE.LegalEntityId = @LegalEntityId
				SELECT @TypeID = TypeID FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 1

				IF((SELECT COUNT(1) FROM [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) WHERE MSL.LegalEntityId = @LegalEntityId) > 0)
				BEGIN
					UPDATE MSL SET 
						MSL.Code = LE.CompanyCode,
						MSL.[Description] = LE.CompanyName,
						MSL.LegalEntityId = LE.LegalEntityId
					FROM [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK)
						JOIN dbo.LegalEntity LE WITH(NOLOCK) ON LE.LegalEntityId = MSL.LegalEntityId
					WHERE LE.LegalEntityId = @LegalEntityId AND MSL.TypeID = @TypeID
				END
				ELSE
				BEGIN
					INSERT INTO [dbo].[ManagementStructureLevel] ([Code], [Description], [TypeID], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [LegalEntityId])
						SELECT CompanyCode, CompanyName, @TypeID, MasterCompanyId, 'Auto Script', 'Auto Script', GETDATE(), GETDATE(), 1, 0, LegalEntityId 
					FROM dbo.LegalEntity WHERE LegalEntityId = @LegalEntityId
				END
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateLegalEntityColumnsWithId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@LegalEntityId, '') + ''
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