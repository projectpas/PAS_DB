/***************************************************************
 ** File:   [USP_SaveVendorAuditInfo]
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to add update Vendor Audit Info
 ** Date:  12-03-2025
            
  ** Change History
 **************************************************************             
 ** PR   Date				Author  		Change Description              
 ** --   --------			-------			--------------------------------            
    1    12-03-2025			Amit Ghediya		Created

**************************************************************/
CREATE    PROCEDURE [dbo].[USP_SaveVendorAuditInfo]
	@VendorAuditInfoId BIGINT,
	@VendorId BIGINT,
	@VendorOrderTypeId BIGINT,
	@VendorAuditTypeId BIGINT,
	@FrequencyDays INT,
	@LastAuditDate DATETIME2 = NULL,
	@NextAuditDate DATETIME2 = NULL,
	@Expired VARCHAR(50) = NULL,
	@AuditFindings VARCHAR(256) = NULL,
	@ActionsTaken VARCHAR(256) = NULL,
	@CreatedBy VARCHAR(256),  
	@CreatedDate DATETIME2,
	@MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
	
		IF(@VendorAuditInfoId = 0)
		BEGIN 
			INSERT INTO [dbo].[VendorAuditInfo]
			(
				[VendorId],[VendorOrderTypeId],[VendorAuditTypeId],[FrequencyDays],[LastAuditDate],[NextAuditDate],[Expired],[AuditFindings],[ActionsTaken],
				[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[MasterCompanyId]
			)
			VALUES( 
				@VendorId,@VendorOrderTypeId,@VendorAuditTypeId,@FrequencyDays,@LastAuditDate,@NextAuditDate,@Expired,@AuditFindings,@ActionsTaken,
				@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@MasterCompanyId)
		END
		ELSE
		BEGIN
			UPDATE [dbo].[VendorAuditInfo]
			SET FrequencyDays = @FrequencyDays,
				LastAuditDate = @LastAuditDate
			WHERE VendorAuditInfoId = @VendorAuditInfoId;
		END
		

	END TRY   
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_SaveVendorAuditInfo'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '', '
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);           
	END CATCH
END;