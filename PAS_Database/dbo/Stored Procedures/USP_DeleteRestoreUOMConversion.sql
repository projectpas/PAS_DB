/*************************************************************           
 ** File:		 [[USP_DeleteRestoreUOMConversion]]         
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To Delete Or Restore UOMConversion
 ** Purpose:         
 ** Date:   19-02-2026
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	09-03-2026           Nakul Chandigra     Created (PN-15597)

exec dbo.USP_DeleteRestoreUOMConversion @UOMConversionId=154,@masterCompanyId=1,@updatedBy=N'ADMIN User'
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_DeleteRestoreUOMConversion]
@UOMConversionId BIGINT,
@MasterCompanyId BIGINT,		
@updatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @IsDELETE BIT;

	SELECT @IsDELETE = ISNULL(IsDeleted, 0)
	FROM [dbo].[UOMConversion] WITH (NOLOCK)
	WHERE UOMConversionId = @UOMConversionId AND MasterCompanyId = @MasterCompanyId
	print @IsDELETE
	IF (@IsDELETE = 0)
	BEGIN
		UPDATE [dbo].[UOMConversion]	
		SET [IsDeleted] = 1 ,
			[UpdatedDate] = GETUTCDATE(),
			[UpdatedBy] = @updatedBy
		WHERE UOMConversionId = @UOMConversionId AND MasterCompanyId = @MasterCompanyId
	END
	ELSE
	BEGIN
		UPDATE [dbo].[UOMConversion]	
		SET [IsDeleted] = 0 ,
			[UpdatedDate] = GETUTCDATE(),
			[UpdatedBy] = @updatedBy
		WHERE UOMConversionId = @UOMConversionId AND MasterCompanyId = @MasterCompanyId
	END
	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_DeleteRestoreUOMConversion]'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END