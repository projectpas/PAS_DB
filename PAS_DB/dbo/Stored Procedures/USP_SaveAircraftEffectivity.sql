
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
   2    15/05/2026  Amit Ghediya		Added ToSerialNumber,FromSerialNumber (PN-16446)
   3    20/05/2026  Amit Ghediya		Remove validation for part due to non mandatory
   4    27/05/2026  Code Review		Removed READ UNCOMMITTED isolation

**************************************************************/
CREATE     PROCEDURE [dbo].[USP_SaveAircraftEffectivity]
    @tbl_AircraftEffectivityType dbo.AircraftEffectivityTableType READONLY
AS
BEGIN
    SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION  
    BEGIN 
		
		DECLARE @Id BIGINT;

        IF EXISTS ( SELECT 1 FROM dbo.AircraftEffectivity AE WITH (NOLOCK) INNER JOIN @tbl_AircraftEffectivityType T ON AE.MakeTypeId = T.MakeTypeId
               -- AND ISNULL(AE.ItemMasterId,0) = ISNULL(T.ItemMasterId,0)
                AND AE.SerialNum = T.FromSerialNumber
                AND AE.MasterCompanyId = T.MasterCompanyId
                AND AE.IsDeleted = 0
                AND AE.AircraftEffectivityId <> ISNULL(T.AircraftEffectivityId,0)
        )
        BEGIN
			ROLLBACK TRANSACTION;

            SELECT 0 AS Status, 'Duplicate Serial Number for same Aircraft Type' AS Message;
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
					AE.SerialNum = T.FromSerialNumber,
					AE.ItemMasterId = T.ItemMasterId,
					AE.PartNumber = T.PartNumber,
					AE.Notes = T.Notes,
					AE.UpdatedBy = T.UpdatedBy,
					AE.UpdatedDate = GETUTCDATE()
				FROM dbo.AircraftEffectivity AE WITH (NOLOCK)
				INNER JOIN @tbl_AircraftEffectivityType T
					ON AE.AircraftEffectivityId = T.AircraftEffectivityId
				WHERE T.AircraftEffectivityId > 0;

				-- ======================================================
				-- INSERT
				-- ======================================================
				--INSERT INTO dbo.AircraftEffectivity
				--(
				--	AircraftPublicationId,
				--	MakeTypeId,
				--	AircraftModelId,
				--	AircraftSubModel,
				--	FromSerialNumber,
				--	ToSerialNumber,
				--	ItemMasterId,
				--	PartNumber,
				--	PartDescription,  
				--	Notes,
				--	MasterCompanyId,
				--	CreatedBy,
				--	UpdatedBy,
				--	CreatedDate,
				--	UpdatedDate,
				--	IsActive,
				--	IsDeleted
				--)
				--SELECT
				--	T.AircraftPublicationsId,
				--	T.MakeTypeId,
				--	T.AircraftModelId,
				--	T.AircraftSubModel,
				--	T.FromSerialNumber,
				--	T.ToSerialNumber,
				--	T.ItemMasterId,
				--	T.PartNumber,
				--	T.PartDescription, 
				--	T.Notes,
				--	T.MasterCompanyId,
				--	T.CreatedBy,
				--	T.UpdatedBy,
				--	GETUTCDATE(),
				--	GETUTCDATE(),
				--	1,
				--	0
				--FROM @tbl_AircraftEffectivityType T
				--WHERE ISNULL(T.AircraftEffectivityId,0) = 0;

				DECLARE @FromSerial VARCHAR(100),
						@ToSerial VARCHAR(100),
						@Prefix VARCHAR(100),
						@FromNo INT,
						@ToNo INT,
						@CurrentNo INT;

				SELECT TOP 1
					@FromSerial = T.FromSerialNumber,
					@ToSerial = T.ToSerialNumber
				FROM @tbl_AircraftEffectivityType T;

				-- =====================================================
				-- SINGLE INSERT
				-- =====================================================
				IF ISNULL(@ToSerial, '') = ''
				BEGIN

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
						@FromSerial,
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
					FROM @tbl_AircraftEffectivityType T;

					SET @Id = SCOPE_IDENTITY();
				END
				ELSE
				BEGIN

					-- =====================================================
					-- MULTIPLE INSERT
					-- =====================================================

					-- Extract Prefix
					SET @Prefix = LEFT(@FromSerial, PATINDEX('%[0-9]%', @FromSerial) - 1);

					-- Extract Numbers
					SET @FromNo = CAST(SUBSTRING(@FromSerial, PATINDEX('%[0-9]%', @FromSerial), LEN(@FromSerial)) AS INT);

					SET @ToNo = CAST(SUBSTRING(@ToSerial, PATINDEX('%[0-9]%', @ToSerial), LEN(@ToSerial)) AS INT);

					IF @FromNo > @ToNo
					BEGIN
						SELECT 0 AS Status, 'From Serial cannot be greater than To Serial' AS Message;
						RETURN;
					END

					SET @CurrentNo = @FromNo;

					WHILE @CurrentNo <= @ToNo
					BEGIN

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
							@Prefix + CAST(@CurrentNo AS VARCHAR),
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
						FROM @tbl_AircraftEffectivityType T;

						SET @Id = SCOPE_IDENTITY();

						SET @CurrentNo = @CurrentNo + 1;
					END

				END

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