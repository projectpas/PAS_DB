/*************************************************************     
** Author:  <Amit Ghediya>    
** Create date: <05/04/2026>    
** Description: <This Proc Is used to Save Aircraft AircraftEffectivity>    
    
Exec [USP_SaveAircraftEffectivity]   
**************************************************************   
** Change History   
**************************************************************     
** PR   Date        Author          Change Description    
** --   --------    -------         --------------------------------  
   1    05/05/2026  Amit Ghediya		Created  
     
**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_SaveAircraftEffectivity]
    @tbl_AircraftEffectivityType dbo.AircraftEffectivityTableType READONLY
AS
BEGIN
    SET NOCOUNT ON;  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY 
	BEGIN TRANSACTION  
    BEGIN 
		
		DECLARE @Id BIGINT;

        IF EXISTS ( SELECT 1 FROM dbo.AircraftEffectivity AE INNER JOIN @tbl_AircraftEffectivityType T ON AE.MakeTypeId = T.MakeTypeId
                AND ISNULL(AE.AircraftModelId,0) = ISNULL(T.AircraftModelId,0)
                AND AE.SerialNum = T.SerialNum
                AND AE.MasterCompanyId = T.MasterCompanyId
                AND AE.IsDeleted = 0
                AND AE.AircraftEffectivityId <> ISNULL(T.AircraftEffectivityId,0)
        )
        BEGIN
			ROLLBACK TRANSACTION;

            SELECT 0 AS Status, 'Duplicate Serial Number for same Aircraft Type & Model' AS Message;
            RETURN;
        END
		ELSE
		BEGIN
			    -- ======================================================
				-- UPDATE
				-- ======================================================
				UPDATE AE
				SET
					AE.AircraftPublicationId = T.AircraftPublicationsId,
					AE.MakeTypeId = T.MakeTypeId,
					AE.AircraftModelId = T.AircraftModelId,
					AE.AircraftSubModel = T.AircraftSubModel,
					AE.SerialNum = T.SerialNum,
					AE.ItemMasterId = T.ItemMasterId,
					AE.PartNumber = T.PartNumber,
					AE.Notes = T.Notes,
					AE.UpdatedBy = T.UpdatedBy,
					AE.UpdatedDate = GETUTCDATE()
				FROM dbo.AircraftEffectivity AE
				INNER JOIN @tbl_AircraftEffectivityType T
					ON AE.AircraftEffectivityId = T.AircraftEffectivityId
				WHERE T.AircraftEffectivityId > 0;

				-- ======================================================
				-- INSERT
				-- ======================================================
				INSERT INTO dbo.AircraftEffectivity
				(
					AircraftPublicationId,
					MakeTypeId,
					AircraftModelId,
					AircraftSubModel,
					SerialNum,
					ItemMasterId,
					PartNumber,
					PartDescription,  
					Notes,
					MasterCompanyId,
					CreatedBy,
					UpdatedBy,
					CreatedDate,
					UpdatedDate,
					IsActive,
					IsDeleted
				)
				SELECT
					T.AircraftPublicationsId,
					T.MakeTypeId,
					T.AircraftModelId,
					T.AircraftSubModel,
					T.SerialNum,
					T.ItemMasterId,
					T.PartNumber,
					T.PartDescription, 
					T.Notes,
					T.MasterCompanyId,
					T.CreatedBy,
					T.UpdatedBy,
					GETUTCDATE(),
					GETUTCDATE(),
					1,
					0
				FROM @tbl_AircraftEffectivityType T
				WHERE ISNULL(T.AircraftEffectivityId,0) = 0;

				-- Return last inserted id
				SET @Id = SCOPE_IDENTITY();

				SELECT 1 AS Status, 'Saved successfully' AS Message, @Id AS Id;
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
            , @AdhocComments     VARCHAR(150)    = 'USP_SaveAircraftEffectivity'     
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);    
	END CATCH   
 END