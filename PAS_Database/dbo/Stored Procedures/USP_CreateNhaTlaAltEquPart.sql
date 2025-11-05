/*************************************************************           
 ** File:   [USP_CreateNhaTlaAltEquPart]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to CreateNhaTlaAltEquPart List
 ** Purpose:         
 ** Date:   04-11-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    04-11-2025    Sahdev Saliya       Created  

    exec [dbo].[USP_CreateNhaTlaAltEquPart]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateNhaTlaAltEquPart]
    @ItemMappingId BIGINT = NULL,  
    @ItemMasterId BIGINT = NULL,
    @MappingItemMasterId BIGINT = NULL,
    @Memo VARCHAR(256) = NULL,
    @MappingType VARCHAR(256) = NULL,
    @CustomerId BIGINT = NULL,
	@IsActive BIT = NULL,
    @CreatedBy VARCHAR(256) = NULL,
    @UpdatedBy VARCHAR(256) = NULL,
    @IsDeleted BIT = NULL,
    @MasterCompanyId BIGINT = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
    BEGIN TRY

        INSERT INTO [dbo].[Nha_Tla_Alt_Equ_ItemMapping]
           (ItemMasterId,
            MappingItemMasterId,
            Memo,
			MappingType,
			CustomerId,
			IsActive,
            CreatedBy,
            CreatedDate,
            UpdatedBy,
            UpdatedDate,
			IsDeleted,
            MasterCompanyId)
        VALUES
           (@ItemMasterId,
            @MappingItemMasterId,
			@Memo,
			@MappingType,
			@CustomerId,
            @IsActive,
            @CreatedBy,
			GETUTCDATE(),
            @UpdatedBy,
			GETUTCDATE(),
			@IsDeleted,
            @MasterCompanyId);
		
        SET @ItemMappingId = SCOPE_IDENTITY();

		SELECT @ItemMappingId ItemMappingId
    END TRY
  BEGIN CATCH
			DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_CreateNhaTlaAltEquPart'
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