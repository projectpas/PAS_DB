/***************************************************************************
 ** File:   [SP_ValidatePDFAddress_New]
 ** Author:   Rajesh Gami
 ** Description: Merge Address
 ** Purpose:
 ** Date:    11/Feb/2025
 **********************
  ** Change History
 **********************
 ** PR   Date			Author				Change Description            
 ** --   --------	    -------				--------------------------------          
    1    11/Feb/2025	RAJESH GAMI			Created

***************************************************************************/ 
CREATE   PROCEDURE [dbo].[SP_ValidatePDFAddress_New]
(
    @Address1 NVARCHAR(MAX),
    @Address2 NVARCHAR(MAX),
    @Address3 NVARCHAR(MAX),
    @City NVARCHAR(255),
    @StateOrProvince NVARCHAR(255),
    @PostalCode NVARCHAR(50),
    @Country NVARCHAR(255),
    @PhoneNumber NVARCHAR(50),
    @PhoneExt NVARCHAR(50),
    @Email NVARCHAR(255),
    @AddressOutput NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
	 BEGIN TRY  
			DECLARE @address NVARCHAR(MAX) = '';

			-- Helper variables for formatting
			DECLARE @lineBreak NVARCHAR(10) = ', <br/>';
			DECLARE @newLine NVARCHAR(10) = '<br/>';

			-- Assign Address1 (handling NULL values)
			IF (COALESCE(NULLIF(LTRIM(RTRIM(@Address1)), '-'), '') <> '')
				SET @address = COALESCE(@Address1, '');

			-- Append Address2
			IF (COALESCE(NULLIF(LTRIM(RTRIM(@Address2)), '-'), '') <> '')
				SET @address = @address + CASE WHEN LEN(@address) > 0 THEN @lineBreak ELSE '' END + COALESCE(@Address2, '');

			-- Append Address3
			IF (COALESCE(NULLIF(LTRIM(RTRIM(@Address3)), '-'), '') <> '')
				SET @address = @address + CASE WHEN LEN(@address) > 0 THEN @lineBreak ELSE '' END + COALESCE(@Address3, '');

			-- Append City, State, PostalCode
			IF (COALESCE(NULLIF(LTRIM(RTRIM(@City)), '-'), '') <> '')
				SET @address = @address + CASE WHEN LEN(@address) > 0 THEN @lineBreak ELSE '' END + COALESCE(@City, '');

			IF (COALESCE(NULLIF(LTRIM(RTRIM(@StateOrProvince)), '-'), '') <> '')
				SET @address = @address + ', ' + COALESCE(@StateOrProvince, '');

			IF (COALESCE(NULLIF(LTRIM(RTRIM(@PostalCode)), '-'), '') <> '')
				SET @address = @address + ', ' + COALESCE(@PostalCode, '');

			-- Append Country
			IF (COALESCE(NULLIF(LTRIM(RTRIM(@Country)), '-'), '') <> '')
				SET @address = @address + CASE WHEN LEN(@address) > 0 THEN @lineBreak ELSE '' END + COALESCE(@Country, '');

			-- Append PhoneNumber
			IF (COALESCE(NULLIF(LTRIM(RTRIM(@PhoneNumber)), '-'), '') <> '')
				SET @address = @address + CASE WHEN LEN(@address) > 0 THEN @newLine ELSE '' END + COALESCE(@PhoneNumber, '');

			-- Append PhoneExt
			IF (COALESCE(NULLIF(LTRIM(RTRIM(@PhoneExt)), '-'), '') <> '' AND COALESCE(@PhoneNumber, '') <> '')
				SET @address = @address + ' ' + COALESCE(@PhoneExt, '');

			-- Append Email
			IF (COALESCE(NULLIF(LTRIM(RTRIM(@Email)), '-'), '') <> '')
				SET @address = @address + @newLine + COALESCE(@Email, '');

			-- Assign final address to output parameter
			SET @AddressOutput = UPPER(@address);
END TRY                  
  BEGIN CATCH                    
   IF @@trancount > 0              
    PRINT 'ROLLBACK'              
    --ROLLBACK TRAN;              
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()              
             
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------              
              , @AdhocComments     VARCHAR(150)    = 'SP_ValidatePDFAddress_New'              
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@Address1, '') + '''              
                @Parameter2 = ' + ISNULL(@Address1 ,'') +''              
              , @ApplicationName VARCHAR(100) = 'PAS'              
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------              
             
              exec spLogException              
                       @DatabaseName           = @DatabaseName              
                     , @AdhocComments          = @AdhocComments              
                     , @ProcedureParameters    = @ProcedureParameters              
                     , @ApplicationName        = @ApplicationName              
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;              
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)              
              RETURN(1);              
  END CATCH              
  END