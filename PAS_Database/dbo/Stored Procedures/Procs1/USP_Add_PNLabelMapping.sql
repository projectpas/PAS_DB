﻿/*********************     
** Author:  <Devendra Shekh>    
** Create date: <06/07/2023>    
** Description: <Add update PN Label Settings>    
    
EXEC [USP_GetPNLabelSettingData]   
**********************   
** Change History   
**********************     
** PR   Date        Author          Change Description    
** --   --------    -------         --------------------------------  
** 1    06/07/2023  Devendra Shekh    Add update PN Label Settings
** 2    13/07/2023  Devendra Shekh    added new field 'AllPNLabelSelected'

exec dbo.USP_Add_PNLabelMapping @PnLabelIds=N'2, 25,26',@MasterCompanyId=1,@CreatedBy=N'ADMIN User',@UpdatedBy=N'ADMIN User',@FieldHeight=70,@FieldWidth=90
exec dbo.USP_Add_PNLabelMapping @PnLabelIds=N'25, 26',@MasterCompanyId=1,@CreatedBy=N'ADMIN User',@UpdatedBy=N'ADMIN User',@FieldHeight=70,@FieldWidth=90
**********************/  

Create   PROCEDURE [dbo].[USP_Add_PNLabelMapping]
@PnLabelIds varchar(100) = NULL,
@CreatedBy varchar(50),
@UpdatedBy  varchar(50),
@MasterCompanyId bigint ,
@FieldHeight bigint ,
@FieldWidth bigint,
@AllPNLabelSelected bit 

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

				CREATE TABLE #TmpPNLabel
				(
					Id BIGINT NOT NULL IDENTITY,
					PNLabelId BIGINT NULL,
					PNLabel VARCHAR(200) NULL
				)

				INSERT INTO #TmpPNLabel (PNLabelId,PNLabel) 
				SELECT PNLabelId, Label
				FROM dbo.PNLabel 
				WHERE PNLabelId IN (SELECT Item FROM DBO.SPLITSTRING(@PnLabelIds,',')) --'1,2,3'

				MERGE dbo.[PNLabelMapping] AS TARGET
				USING #TmpPNLabel AS SOURCE ON 
				(TARGET.PNLabelId = SOURCE.PNLabelId AND @MasterCompanyId = TARGET.MasterCompanyId) 
				--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
				WHEN MATCHED 				
					THEN UPDATE 						
					SET	TARGET.PNLabelId = ISNULL(SOURCE.PNLabelId, 0),
						TARGET.Description = ISNULL(SOURCE.PNLabel, ''),
						TARGET.FieldWidth = @FieldWidth,
						TARGET.FieldHeight = @FieldHeight,
						TARGET.UpdatedDate = GETUTCDATE(),
						TARGET.UpdatedBy = @UpdatedBy,
						TARGET.AllPNLabelSelected = @AllPNLabelSelected
				WHEN NOT MATCHED BY TARGET 
					THEN INSERT ([PNLabelId],[Description],[FieldWidth],[FieldHeight], [MasterCompanyId], [CreatedDate], [CreatedBy], [UpdatedDate], [UpdatedBy], [IsActive], [IsDeleted], [AllPNLabelSelected]) 
					VALUES (SOURCE.PNLabelId,SOURCE.PNLabel, @FieldWidth, @FieldHeight, @MasterCompanyId, GETUTCDATE(),@CreatedBy, GETUTCDATE(), @UpdatedBy, 1, 0, @AllPNLabelSelected)
				WHEN NOT MATCHED BY SOURCE 
					THEN DELETE;

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_Add_PNLabelMapping' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PnLabelIds, '') + ''
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