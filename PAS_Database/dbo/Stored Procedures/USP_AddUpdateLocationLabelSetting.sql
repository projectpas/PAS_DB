/*********************
** Author:  Sumit Kumar
** Create date: 10/06/2026
** Description: Add/Update Location Label Settings
**********************
** Change History
**********************
** PR   Date        Author          Change Description
** --   --------    -------         --------------------------------
** 1    10/06/2026  Sumit Kumar     Created Add/Update Location Label Settings
** 2    16/06/2026  Sumit Kumar     Changed Field Precision to (18,6) 
**********************/

CREATE PROCEDURE [dbo].[USP_AddUpdateLocationLabelSetting]
(
	@CreatedBy VARCHAR(50),
	@UpdatedBy VARCHAR(50),
	@MasterCompanyId BIGINT,
	@FieldHeight DECIMAL(18,6),
	@FieldWidth DECIMAL(18,6),
	@FieldDPI DECIMAL(18,6),
	@MarginLeft DECIMAL(18,6),
	@MarginRight DECIMAL(18,6),
	@MarginTop DECIMAL(18,6),
	@MarginBottom DECIMAL(18,6)
)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION;

		MERGE dbo.LocationLabelSetting AS TARGET
		USING
		(
			SELECT @MasterCompanyId AS MasterCompanyId
		) AS SOURCE
		ON TARGET.MasterCompanyId = SOURCE.MasterCompanyId
			AND TARGET.IsDeleted = 0

		WHEN MATCHED THEN
			UPDATE
			SET
				TARGET.FieldWidth = @FieldWidth,
				TARGET.FieldHeight = @FieldHeight,
				TARGET.FieldDPI = @FieldDPI,
				TARGET.MarginLeft = @MarginLeft,
				TARGET.MarginRight = @MarginRight,
				TARGET.MarginTop = @MarginTop,
				TARGET.MarginBottom = @MarginBottom,
				TARGET.UpdatedDate = GETUTCDATE(),
				TARGET.UpdatedBy = @UpdatedBy

		WHEN NOT MATCHED THEN
			INSERT
			(
				FieldWidth,
				FieldHeight,
				FieldDPI,
				MarginLeft,
				MarginRight,
				MarginTop,
				MarginBottom,
				MasterCompanyId,
				CreatedDate,
				CreatedBy,
				UpdatedDate,
				UpdatedBy,
				IsActive,
				IsDeleted
			)
			VALUES
			(
				@FieldWidth,
				@FieldHeight,
				@FieldDPI,
				@MarginLeft,
				@MarginRight,
				@MarginTop,
				@MarginBottom,
				@MasterCompanyId,
				GETUTCDATE(),
				@CreatedBy,
				GETUTCDATE(),
				@UpdatedBy,
				1,
				0
			);

		COMMIT TRANSACTION;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE
			@ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = 'USP_AddUpdateLocationLabelSetting',
			@ProcedureParameters VARCHAR(3000) =
				'@MasterCompanyId = ' + CAST(ISNULL(@MasterCompanyId,0) AS VARCHAR(20)),
			@ApplicationName VARCHAR(100) = 'PAS';

		EXEC spLogException
			 @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
			'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
			16,
			1,
			@ErrorLogID
		);

		RETURN (1);
	END CATCH
END