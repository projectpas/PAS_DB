
/*********************     
** Author:  <Sumit Kumar>    
** Create date: <10/06/2026>    
** Description: <Add update Location Label Settings>    
    
EXEC [USP_GetLocationLabelSettingData]   
**********************   
** Change History   
**********************     
** PR   Date        Author          Change Description    
** --   --------    -------         --------------------------------  
** 1    10/06/2026  Sumit Kumar    Craete Add update Location Label Settings

**********************/  

CREATE   PROCEDURE [dbo].[USP_Add_LocationLabelMapping]
@LocationLabelIds varchar(100) = NULL,
@CreatedBy varchar(50),
@UpdatedBy  varchar(50),
@MasterCompanyId bigint ,
@FieldHeight decimal(18,2),
@FieldWidth decimal(18,2),
@FieldDPI decimal(18,2) ,
@MarginLeft decimal(18,2),
@MarginRight decimal(18,2) ,
@MarginTop decimal(18,2),
@MarginBottom decimal(18,2),
@AllLocationLabelSelected bit 

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

				CREATE TABLE #TmpLocationLabel
				(
					Id BIGINT NOT NULL IDENTITY,
					LocationLabelId BIGINT NULL,
					LocationLabel VARCHAR(200) NULL
				)

				INSERT INTO #TmpLocationLabel (LocationLabelId,LocationLabel) 
				SELECT LocationLabelId, Label
				FROM dbo.LocationLabel 
				WHERE LocationLabelId IN (SELECT Item FROM DBO.SPLITSTRING(@LocationLabelIds,',')) --'1,2,3'

				MERGE dbo.[LocationLabelMapping] AS TARGET
				USING #TmpLocationLabel AS SOURCE ON 
				(TARGET.LocationLabelId = SOURCE.LocationLabelId AND @MasterCompanyId = TARGET.MasterCompanyId) 
				WHEN MATCHED 				
					THEN UPDATE 						
					SET	TARGET.LocationLabelId = ISNULL(SOURCE.LocationLabelId, 0),
						TARGET.Description = ISNULL(SOURCE.LocationLabel, ''),
						TARGET.FieldWidth = @FieldWidth,
						TARGET.FieldHeight = @FieldHeight,
						TARGET.FieldDPI = @FieldDPI,
						TARGET.MarginLeft = @MarginLeft,
						TARGET.MarginRight = @MarginRight,
						TARGET.MarginTop = @MarginTop,
						TARGET.MarginBottom = @MarginBottom,
						TARGET.UpdatedDate = GETUTCDATE(),
						TARGET.UpdatedBy = @UpdatedBy,
						TARGET.AllLocationLabelSelected = @AllLocationLabelSelected
				WHEN NOT MATCHED BY TARGET 
					THEN INSERT ([LocationLabelId],[Description],[FieldWidth],[FieldHeight], [MasterCompanyId], [CreatedDate], [CreatedBy], [UpdatedDate], [UpdatedBy], [IsActive], [IsDeleted], [AllLocationLabelSelected],[FieldDPI],[MarginLeft],[MarginRight],[MarginTop],[MarginBottom]) 
					VALUES (SOURCE.LocationLabelId,SOURCE.LocationLabel, @FieldWidth, @FieldHeight, @MasterCompanyId, GETUTCDATE(),@CreatedBy, GETUTCDATE(), @UpdatedBy, 1, 0, @AllLocationLabelSelected,@FieldDPI,@MarginLeft,@MarginRight,@MarginTop,@MarginBottom);
				--WHEN NOT MATCHED BY SOURCE 
				--THEN DELETE;

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_Add_LocationLabelMapping' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@LocationLabelIds, '') + ''
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