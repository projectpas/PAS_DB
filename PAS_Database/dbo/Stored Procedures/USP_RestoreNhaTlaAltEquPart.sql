/*************************************************************           
 ** File:   [USP_RestoreNhaTlaAltEquPart]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to RestoreNhaTlaAltEquPart List
 ** Purpose:         
 ** Date:   04-11-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    04-11-2025    Sahdev Saliya       Created  

	exec [dbo].[USP_RestoreNhaTlaAltEquPart]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_RestoreNhaTlaAltEquPart]
    @MappingId BIGINT = NULL,
    @UpdatedBy VARCHAR(256) = NULL,
    @IsFromNew BIT = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

		BEGIN TRY
		DECLARE 
			@CountAudit INT,
			@IsAlreadyActivePart INT = 0,
			@MappingItemMasterId BIGINT,
			@ItemMasterId BIGINT;

		IF (@IsFromNew = 1)
		BEGIN
			SELECT TOP 1
				@MappingItemMasterId = MappingItemMasterId,
				@ItemMasterId = ItemMasterId
			FROM Nha_Tla_Alt_Equ_ItemMapping WITH (NOLOCK)
			WHERE ItemMappingId = @MappingId;

			SELECT @IsAlreadyActivePart = COUNT(*) FROM dbo.Nha_Tla_Alt_Equ_ItemMapping WITH (NOLOCK)
			WHERE MappingItemMasterId = @MappingItemMasterId 
				AND ItemMasterId = @ItemMasterId
				AND IsActive = 1
				AND IsDeleted = 0;

			IF (@IsAlreadyActivePart > 0)
			BEGIN
				SELECT 0 AS Result;  				
			END
			ELSE
			BEGIN
				SELECT @CountAudit = COUNT(*) FROM dbo.NhaTlaAltEquAudit WITH (NOLOCK) WHERE ItemMappingId = @MappingId;

				IF (@CountAudit > 0)
				BEGIN
					UPDATE dbo.Nha_Tla_Alt_Equ_ItemMapping
						SET IsDeleted = 0,
							UpdatedDate = GETUTCDATE(),
							UpdatedBy = @UpdatedBy
						WHERE ItemMappingId = @MappingId;
				END
				SELECT 1 AS Result;  				
			END
		END
		ELSE
		BEGIN
			SELECT @CountAudit = COUNT(*) FROM dbo.NhaTlaAltEquAudit WITH (NOLOCK) WHERE ItemMappingId = @MappingId;
			IF (@CountAudit > 0)
			BEGIN
				UPDATE dbo.Nha_Tla_Alt_Equ_ItemMapping
					SET IsDeleted = 0,
						UpdatedDate = GETUTCDATE(),
						UpdatedBy = @UpdatedBy
					WHERE ItemMappingId = @MappingId;
			END
			SELECT 1 AS Result;  
		END	

	 END TRY 
     BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_RestoreNhaTlaAltEquPart'
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
	 END CATCH

END